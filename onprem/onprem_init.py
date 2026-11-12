"""Turn the restored seed tenant into the customer's own single tenant.

Run by install.sh from /opt/caiva/backend with the backend venv and .env loaded:
    venv/bin/python /opt/caiva/onprem/onprem_init.py --slug jsbl --org "JS Bank" \
        --admin-email admin@jsbl.com --password-file /root/.caiva-admin-pw

The seed (a clean CAIVA tenant: CIS + SCF libraries, helpdesk config, RBAC, no
customer data) keeps its tenant id — every tenant_id column already points at it —
so only the identity rows change: the master registry row, the tenant-local copy
of that row, and the one admin user. Run ONCE per install (install.sh guards it with a
marker file) — it resets the admin and clears the seed's audit rows.
"""
import argparse
import json
import os
import sys

import psycopg2
from dotenv import load_dotenv

load_dotenv(".env")
sys.path.insert(0, os.getcwd())
from grc.tenant_manager import hash_password  # noqa: E402  (same bcrypt the app verifies with)

COPY_COLS = ["id", "name", "slug", "subdomain", "schema_name", "is_active", "created_at", "settings",
             "legal_entity", "industry", "regulatory_scope", "company_size", "geography",
             "primary_contact_name", "primary_contact_email", "primary_contact_phone"]
RUNTIME_TABLES = ["grc_audit_logs"]  # seed's own login probes — not the customer's history


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--slug", required=True)
    ap.add_argument("--org", required=True)
    ap.add_argument("--subdomain", default="")  # first host label on 3+-label hosts, else ''
    ap.add_argument("--admin-email", required=True)
    ap.add_argument("--password-file", required=True)
    a = ap.parse_args()
    pw = open(a.password_file, encoding="utf-8").read().strip()
    assert len(pw) >= 12, "admin password too short"
    domain = a.admin_email.split("@", 1)[1].lower()

    tenant = psycopg2.connect(os.environ["TENANT_DB_URL_TEMPLATE"].replace("{slug}", a.slug))
    master = psycopg2.connect(os.environ["MASTER_DATABASE_URL"])
    tc, mc = tenant.cursor(), master.cursor()

    tc.execute("select count(*) from grc_tenants")
    assert tc.fetchone()[0] == 1, "seed must hold exactly one tenant row"
    tc.execute("select settings from grc_tenants")
    settings = tc.fetchone()[0] or {}
    if isinstance(settings, str):
        settings = json.loads(settings or "{}")
    settings["email_domain"] = domain
    # subdomain '' = tenant on the bare host / IP; otherwise the host's first label, which is
    # what the login page sends as X-Tenant-Slug (DEFAULT_TENANT_SLUG covers anonymous calls)
    tc.execute("update grc_tenants set name=%s, slug=%s, subdomain=%s, legal_entity=%s, settings=%s, "
               "primary_contact_name=%s, primary_contact_email=%s",
               (a.org, a.slug, a.subdomain, a.org, json.dumps(settings), f"{a.org} Administrator", a.admin_email))

    tc.execute("select count(*) from grc_users")
    assert tc.fetchone()[0] == 1, "seed must hold exactly one user (the admin)"
    tc.execute("update grc_users set username='admin', email=%s, password_hash=%s, display_name=%s, is_active=true, "
               "failed_login_attempts=0, locked_until=NULL",
               (a.admin_email, hash_password(pw), f"{a.org} Administrator"))
    # CIS library / OS registry query these with jsonb operators; the seed stores plain json
    for col in ("os_keys", "target_builds"):
        tc.execute("select data_type from information_schema.columns "
                   "where table_name='grc_compliance_plugins' and column_name=%s", (col,))
        r = tc.fetchone()
        if r and r[0] == "json":
            tc.execute(f"alter table grc_compliance_plugins alter column {col} type jsonb using {col}::jsonb")
    for t in RUNTIME_TABLES:
        tc.execute(f"truncate {t}")

    # master registry row = the tenant-local row (same id), upserted
    tc.execute(f"select {', '.join(COPY_COLS)} from grc_tenants")
    row = tc.fetchone()
    row = [json.dumps(v) if isinstance(v, dict) else v for v in row]
    mc.execute("delete from grc_tenants where id=%s or slug=%s", (row[0], a.slug))
    mc.execute(f"insert into grc_tenants ({', '.join(COPY_COLS)}) values ({', '.join(['%s'] * len(COPY_COLS))})", row)
    mc.execute("select setval(pg_get_serial_sequence('grc_tenants','id'), greatest((select max(id) from grc_tenants), 1))")

    tenant.commit()
    master.commit()
    print(f"[init] tenant '{a.slug}' ({a.org}) id={row[0]} ready; admin={a.admin_email}")


if __name__ == "__main__":
    main()
