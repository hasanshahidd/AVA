# Help Desk — request-template library + SLA visibility (build spec)

Two things, both on top of the existing native engine (reuse, don't rebuild):

1. **A rich, department-wise library of predefined request/problem templates** so a
   first-time user (e.g. a salesperson) picks their department and sees common
   problems as cards that PRE-FILL the New-Ticket form — instead of a blank form.
2. **Make the SLA visible + actually computed on create** (today SLA deadlines
   are only set when a ticket's status changes, so a brand-new incident shows no
   SLA — that's the "no SLA visible" bug).

Worktree root: `C:/Users/HP/hd-itsm-wt` (branch feat/helpdesk-itsm, rebased on
main 5e0eb70). All work ABSOLUTE-pathed in that worktree. Local; I deploy after.
The existing template concept is `HDTicketTemplate` (grc_hd_ticket_template) in
`_60_helpdesk_native_models.py` + CRUD in `helpdesk_native/masters.py` — EXTEND it.

---

## Agent A — backend (owns: _60 models, itsm_seed.py, tickets.py, sla.py, new request_templates.py)

### A1. Extend HDTicketTemplate (`_60_helpdesk_native_models.py`)
Add nullable columns (match the file's column style; NO index on PKs):
- `department_id` Integer FK `grc_hd_department.id`
- `process` String(20) server_default `'incident'`
- `default_subject` String(255)
- `default_description` Text
- `default_category` String(100), `default_subcategory` String(100)
- `default_impact` String(10), `default_urgency` String(10)
- `icon` String(40)   — a lucide icon name for the card (optional)
- `enabled` Boolean server_default true

### A2. Seeder additions (`itsm_seed.py`)
- Ensure the 5 standard departments exist (create if absent, enabled): **IT,
  Sales, Finance, HR, Facilities** (HDDepartment).
- `seed_request_templates(db, tid)` — idempotent (skip if a template with the
  same template_name+department exists). Seed THIS library (title → template_name;
  set department_id by resolving the dept name, process, default_subject (=title),
  default_description, category/subcategory where noted, impact/urgency where
  noted, a fitting lucide `icon`):

  **IT**: "My PC is slow" (incident, impact medium/urgency medium), "Password
  reset / can't log in" (service_request, Access/Account), "Email not working"
  (incident), "VPN won't connect" (incident), "Request a new laptop"
  (service_request, Hardware), "Install software" (service_request, Software),
  "Printer not working" (incident), "Request system access" (service_request,
  Access/Account).
  **Sales**: "CRM is down / slow" (incident, impact high/urgency high), "Can't
  access CRM" (incident, Access/Account), "New rep needs CRM access"
  (service_request), "Laptop issue" (incident).
  **Finance**: "Expense reimbursement" (service_request, Expense), "Procurement
  request" (service_request, Procurement), "Accounting software error"
  (incident), "Invoice / payment issue" (incident).
  **HR**: "New employee onboarding" (service_request, Onboarding), "Payroll issue"
  (incident, Payroll), "Leave-system access" (service_request), "Update personal
  info" (service_request).
  **Facilities**: "Office AC / heating issue" (incident), "Broken equipment"
  (incident, Equipment), "Desk / office move" (service_request, Office), "Meeting
  room booking issue" (service_request).

- Call `seed_request_templates` from `seed_itsm` (after departments + catalog).

### A3. request_templates.py (NEW) — the read API the form uses
`router = APIRouter(prefix="/helpdesk")`, included in router.py by... — you may
edit router.py to include it (coordinate: it's the one shared file; add one
import + one include_router line, nothing else).
- `GET /helpdesk/request-templates?department_id=&process=` → `{"templates":[{id,
  template_name, department_id, department, process, default_subject,
  default_description, default_category, default_subcategory, default_impact,
  default_urgency, icon}]}`. Filters by department_id and/or process when given;
  only `enabled`; tenant-scoped.

### A4. SLA computed ON CREATE (`tickets.py`)
In `create_ticket`, after the ticket is flushed + priority/status set and
auto_assign has run, call `sla.recompute(db, ticket, prev_status_category=None)`
BEFORE the final commit, so every new ticket gets `sla_id`/`response_by`/
`resolution_by`/`agreement_status` immediately. Guard it in try/except (a ticket
must still be created if no SLA policy matches). Confirm `list_tickets` rows and
`get_detail` already expose `response_by`, `resolution_by`, `agreement_status`
(the tickets list + home page render SlaBadge off `response_by`) — if the process
list rows don't include them, add them to the row serialization.

### A5. SLA preview endpoint (`sla.py` config_router or request_templates.py)
- `GET /helpdesk/sla-preview?process=&priority=` → the SLA that WOULD apply to a
  ticket of this process (match the seeded per-process SLA by its condition
  `doc.process == '<process>'`; fall back to default), returning
  `{"policy": <name>, "response": "<human e.g. 4h>", "resolution": "<e.g. 24h>"}`
  for the given priority (default Medium). Reuse `sla._fmt_duration`. 200-safe
  (nulls when nothing matches).

Verify: py_compile; run itsm_seed + change self-checks; import the full
helpdesk_native_router and confirm the new routes register. Report exact field
names + endpoint shapes + any router.py line you added.

---

## Agent B — frontend (owns: _newticket.tsx, the 4 process pages)

Backend built in parallel — code against §A3/§A5 and the existing row shape.

### B1. New-Ticket form `_newticket.tsx` — template picker + real SLA
- After Process + Department are chosen, fetch
  `GET /grc/helpdesk/request-templates?department_id=&process=` and render the
  matching templates as a grid of clickable **cards** (icon + title) above the
  fields — "Common requests". Clicking a card PRE-FILLS the form: subject =
  default_subject, description = default_description, category/subcategory,
  impact/urgency (and switches process if the card's process differs). The user
  can still edit everything. Keep a "Start from scratch" option.
- If no department chosen yet, show cards for the chosen process across all
  departments (or a hint to pick a department). Tolerate an empty list.
- Replace the static `SLA: Incident SLA` label with the REAL target from
  `GET /grc/helpdesk/sla-preview?process=&priority=<derived or Medium>` — show
  e.g. "SLA: respond 4h · resolve 24h". Update when process/priority changes.
- Keep the existing process-specific fields + submit payload exactly as-is.

### B2. Surface SLA on the process pages (incidents/problems/changes/service-requests)
Add an **SLA column** to each list using the existing `SlaBadge` from `../_ui`
(it takes `due={t.response_by}` + a done flag), matching how `tickets/page.tsx` /
`home/page.tsx` render it. So opening Incidents shows each ticket's SLA state at a
glance. (Rows now carry response_by once A4 lands.)

Verify: typecheck via `node node_modules/typescript/bin/tsc --noEmit` (junction
node_modules from the main checkout if absent, then remove it). No new TS errors
in your files. No dev server / deploy / commit. Report the card UX + the exact
endpoints/fields you consumed.

---

## File ownership (no collisions)
- A: `_60_helpdesk_native_models.py`, `itsm_seed.py`, `tickets.py`, `sla.py`,
  NEW `request_templates.py`, + ONE include line in `router.py`.
- B: `_newticket.tsx`, `incidents/page.tsx`, `problems/page.tsx`,
  `changes/page.tsx`, `service-requests/page.tsx`.
Only A touches router.py. Backend API base is `/grc/helpdesk/...` from the FE.
