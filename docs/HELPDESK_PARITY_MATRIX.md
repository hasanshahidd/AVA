# AVA Help Desk ⇄ Frappe Helpdesk — Parity Alignment Audit

**Branch:** `feat/helpdesk-parity` (off `21b92f7`) · **Engine:** Frappe Helpdesk, hidden, `ava_helpdesk` compose project on `143.198.176.10`, internal `localhost:8080`.
**Governing rule (owner amendment):** do NOT blindly replicate Frappe. Every feature gets a verdict — **BUILD / SKIP-irrelevant / SKIP-duplicates-AVA / SKIP-conflicts-with-AVA** — and every BUILD item maps explicitly onto AVA (server-derived `ava_tenant` partition filtered on every read, RBAC `vulnerabilities:vulnerability_register:view`/`:edit`, and AVA's existing concepts: findings, assets, departments, agents=AVA users, remediation plans).

## Ground truth verified live (not assumed)
- **Custom fields present on `HD Ticket`:** `ava_tenant`, `ava_finding_id`, `cve_id`, `cvss_score`, `asset_host` (confirmed via `frappe.get_meta`). 64 tickets exist (demo data under partition `ava`).
- **SLA already fires** on REST-created tickets: `sla="Standard"` (the single `default_sla`, `enabled`), `response_by`/`resolution_by`/`agreement_status` all populate automatically via `HD Ticket.before_save → apply_sla()`. **No SLA linkage fix needed.**
- **Assignment is BROKEN for AVA tickets — ROOT CAUSE FOUND.** Assignment Rule `ava - Support Rotation` (enabled, doctype `HD Ticket`) has `assign_condition = "status == 'Open' and agent_group == 'ava'"`. Every AVA-created ticket has `agent_group = None` (the push path never sets a team), so the rule never matches and `_assign` stays empty. **Team name == tenant partition slug** (team `ava` ↔ partition `ava`). Fix = set `agent_group` to the partition on create when a team of that name exists.
- **Isolation carriers:** `ava_tenant` custom field confirmed present on `HD Ticket`, `HD Team`, `HD Agent`, `HD Customer`, `Contact`, `HD Article` (the proxy already filters all of these). Child/related records (`HD Ticket Comment`, `HD Ticket Activity`, `Communication`, feedback) have **no** `ava_tenant` field and must never be queried globally — they are reachable ONLY via a parent `HD Ticket` already confirmed in-partition (`_ticket_in_tenant`). Global config doctypes (`HD Ticket Priority`/`Type`/`Status`) are enums shared by all tenants — exposing them as option lists leaks no tenant data.

## Two existing ticket surfaces (both kept, additive)
1. **Finding-centric** (`/vuln-management/helpdesk/tickets`, `itsm.py`) — joins `VulnTicketLink`+`Vulnerability`; powers `helpdesk/page.tsx` + `helpdesk/[id]/page.tsx`. AVA source-of-truth view.
2. **Engine proxy** (`/helpdesk/*`, `helpdesk/router.py`) — reads `HD Ticket` live; powers the agent-desk pages (`tickets/`, `tickets/[name]/`, `dashboard/`, `agents/`, `teams/`, `kb/`, `canned/`, `customers/`, `contacts/`). This is the parity surface; all new work lands here.

---

## Verdict matrix

| # | Frappe feature | Engine doctype / endpoint | Proxy today | UI today | Verdict | AVA alignment + isolation | Priority |
|---|----------------|---------------------------|:-----------:|:--------:|---------|---------------------------|:--------:|
| 1 | Ticket list + detail | `HD Ticket` | ✅ | ✅ | **done** | Partition-filtered reads; `_ticket_in_tenant` guard on detail. | — |
| 2 | Replies (public conversation) | `Communication` | ✅ read+write | ✅ | **done** | Reached only via in-partition ticket. | — |
| 3 | Internal comments | `HD Ticket Comment` | write only | partial | **BUILD** | Read comments into the timeline; keyed by `reference_ticket` of an in-partition ticket. | **P1** |
| 4 | Activity timeline | `HD Ticket Activity` | ❌ | ❌ | **BUILD** | Read `action` events for an in-partition ticket; merge into timeline. | **P1** |
| 5 | SLA state on ticket (targets/due/breach/remaining) | `HD Ticket.response_by/resolution_by/agreement_status/*_failed_by/on_hold_since` | fields fetched | partial | **BUILD** | Structure the SLA block from existing fields (no new doctype). Already tenant-safe. | **P1** |
| 6 | Auto-assignment (fire the rule) | Assignment Rule + `HD Ticket.agent_group`/`_assign` | ❌ (broken) | ❌ | **BUILD** | Set `agent_group = partition` on create when that team exists → rule fires. Team is itself `ava_tenant`-tagged. | **P1** |
| 7 | Manual assignment (agent + team) | `frappe.desk.form.assign_to` / `_assign`, `agent_group` | ❌ | stub | **BUILD** | Agents=AVA users already in the tenant's team (partition-filtered); assign only to in-partition agents, guard ticket in-partition. | **P1** |
| 8 | Status transitions | `HD Ticket.status` + `HD Ticket Status` list | set only | ✅ resolve/close | **BUILD** | Expose status option list (global enum); keep in-partition write guard. | **P1** |
| 9 | Priorities | `HD Ticket Priority` | ❌ | hardcoded | **BUILD** | Expose as global option list; allow change on in-partition ticket. | **P2** |
| 10 | Ticket types | `HD Ticket Type` | ❌ | ❌ | **BUILD** | Global option list; allow change on in-partition ticket. | **P2** |
| 11 | Feedback / CSAT | `HD Ticket.feedback/feedback_rating/feedback_extra`, `HD Ticket Feedback Option` | ❌ | ❌ | **BUILD** | Read CSAT off the in-partition ticket; option list is global enum. (Leaving feedback is a portal action — agent-side we only surface it.) | **P2** |
| 12 | KB article categories | `HD Article Category` | ❌ | ❌ | **BUILD** | Articles already partition-filtered; categories are per-tenant too (`ava_tenant` on `HD Article`; group by `category`). | **P2** |
| 13 | KB article feedback | `HD Article Feedback` | ❌ | ❌ | **BUILD (read)** | Surface helpful/not counts per in-partition article. | **P3** |
| 14 | Canned replies — use in composer | `HD Saved Reply` | ✅ list | list page | **BUILD** | Inject saved-reply body into the reply composer; list already partition-filtered. | **P2** |
| 15 | Agent status / availability | `HD Agent.availability` (`HD Agent Status`) | ❌ | ❌ | **BUILD (read)** | Surface availability on the partition-filtered agents list. | **P3** |
| 16 | Customer members | `HD Customer Member` / `HD Customer.contacts` | count=0 | ❌ | **BUILD (read)** | Resolve members per in-partition customer. | **P3** |
| 17 | Teams + members | `HD Team` / `HD Team Member` | ✅ | ✅ | **done** | Partition-filtered. | — |
| 18 | Customers / Contacts | `HD Customer` / `Contact` | ✅ | ✅ | **done** | Partition-filtered. | — |
| 19 | Notifications (agent bell) | `HD Notification` | ❌ | ❌ | **SKIP-duplicates-AVA** | AVA has its own notification/alerting surface; a second Frappe bell would be a parallel, confusing channel and `HD Notification` has no `ava_tenant` carrier (would need per-user scoping that AVA already owns). | — |
| 20 | Ticket templates + fields | `HD Ticket Template` / `...Template Field` | ❌ | ❌ | **SKIP-irrelevant** | Templates shape Frappe's **customer-portal new-ticket form**. AVA tickets originate from findings, not a portal form — no form to template. | — |
| 21 | Saved views / field layouts / form scripts | `HD View`, `HD Field Layout`, `HD Form Script` | ❌ | ❌ | **SKIP-irrelevant** | These customize **Frappe's own agent-desk UI**, which is hidden. AVA renders its own screens; the configs have no meaning here. | — |
| 22 | Customer portal | `HD Ticket.via_customer_portal`, Vue `customer/` pages | ❌ | ❌ | **SKIP-conflicts-with-AVA** | Exposing Frappe's portal would reveal the hidden engine to the client — violates the invisible-engine hard rule. AVA IS the front door. | — |
| 23 | Inbound email intake | `Email Account`, `Communication` (Received) | ❌ | ❌ | **SKIP-irrelevant** | Tickets come from findings; the engine is not exposed to receive customer email. | — |
| 24 | Telephony / call logs | (call-logs Vue page) | ❌ | ❌ | **SKIP-irrelevant** | Explicitly out of scope; AVA has no telephony. | — |
| 25 | SLA policy / holidays / service days mgmt | `HD Service Level Agreement`, `HD Holiday`, `HD Service Day`, `HD Service Holiday List` | ❌ | ❌ | **SKIP-duplicates-AVA (reuse)** | Read-and-reuse the existing `Standard` SLA (already firing). A management UI would be operator config, risks mutating shared demo SLA → do not build; note as operator step if ever needed. | — |
| 26 | KB stopwords / synonyms | `HD Stopword`, `HD Synonym(s)` | ❌ | ❌ | **SKIP-irrelevant** | Frappe full-text-search tuning internals; invisible to AVA. | — |
| 27 | Comment reactions | `HD Comment Reaction` | ❌ | ❌ | **SKIP-irrelevant** | Emoji reactions; non-essential, no AVA concept. | — |
| 28 | ERPNext bridge | `ERPNext HD Settings` | ❌ | ❌ | **SKIP-irrelevant** | ERPNext integration; AVA supplies CMDB/customers itself. | — |

## BUILD subset, in priority order
- **P1 (core incident loop — owner's named pain):** #6 auto-assignment fix, #7 manual assignment, #3 internal comments read, #4 activity timeline, #5 SLA state block, #8 status transitions + status list.
- **P2:** #9 priorities, #10 ticket types, #14 canned-reply-in-composer, #11 feedback/CSAT read, #12 KB categories.
- **P3 (cheap reads, defer if time-boxed):** #13 article feedback, #15 agent availability, #16 customer members.

Everything else is a documented SKIP above.

## Isolation contract for all BUILD work
1. Every direct doctype read appends the tenant partition filter (`_tenant_filters`), exactly as the existing proxy does.
2. Child/related records with no `ava_tenant` (comments, activity, communications, feedback) are fetched **only** by the key of a parent `HD Ticket` first confirmed in-partition — never by a global query.
3. Global enums (priority/type/status/feedback-option) are exposed as option lists only; they contain no tenant data.
4. Writes stay behind `_ticket_in_tenant` + RBAC `:edit`. No new unscoped doctype is introduced.
