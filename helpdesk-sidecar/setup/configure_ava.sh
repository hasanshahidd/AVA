#!/bin/bash
# One-shot: prepare the running Helpdesk sidecar for AVA.
#   - a scoped service user + API key/secret (printed once)
#   - the AVA Custom Fields on HD Ticket (ava_finding_id UNIQUE, cve_id, ...)
#   - one HD Team per AVA tenant (pass tenant slugs as args)
#
# Runs bench inside the container (reliable; no auth dance). Run from this folder:
#   bash setup/configure_ava.sh ava demo acme
set -e
SITE="helpdesk.localhost"
SVC_EMAIL="ava-integration@local"
DC="docker compose"

run() { $DC exec -T frappe bench --site "$SITE" "$@"; }
pyexec() { $DC exec -T frappe bench --site "$SITE" execute "$@"; }

echo ">> Custom Fields on HD Ticket"
pyexec frappe.custom.doctype.custom_field.custom_field.create_custom_fields --kwargs "{'custom_fields': {'HD Ticket': [
  {'fieldname':'ava_finding_id','label':'AVA Finding ID','fieldtype':'Data','unique':1,'no_copy':1,'read_only':1},
  {'fieldname':'ava_tenant','label':'AVA Tenant','fieldtype':'Data'},
  {'fieldname':'cve_id','label':'CVE','fieldtype':'Data'},
  {'fieldname':'cvss_score','label':'CVSS','fieldtype':'Float'},
  {'fieldname':'asset_host','label':'Affected Host','fieldtype':'Data'}
]}}"

echo ">> Service user + role"
pyexec frappe.client.insert --kwargs "{'doc': {'doctype':'User','email':'$SVC_EMAIL','first_name':'AVA','send_welcome_email':0,'roles':[{'role':'Agent Manager'}]}}" || echo "   (user may already exist)"

echo ">> API key/secret"
pyexec frappe.core.doctype.user.user.generate_keys --args "['$SVC_EMAIL']"
echo "   ^ api_secret is shown above ONCE. api_key = User.api_key:"
run get-value User "$SVC_EMAIL" api_key || true

echo ">> HD Team per tenant: $*"
for t in "$@"; do
  pyexec frappe.client.insert --kwargs "{'doc': {'doctype':'HD Team','team_name':'$t'}}" || echo "   (team $t may already exist)"
done

cat <<EOF

Done. In AVA, add a 'Frappe Helpdesk' connector per tenant with:
  Base URL   : http://host.docker.internal:8000   (or the sidecar host:8000)
  API Key    : (printed above)
  API Secret : (printed above, once)
  Team       : the tenant's HD Team name
  AVA tenant : the tenant slug
EOF
