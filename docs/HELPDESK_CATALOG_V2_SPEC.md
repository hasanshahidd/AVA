# Help Desk — catalog/template v2 + form overhaul (build spec)

Owner feedback after live testing the New-Ticket form. Fix ALL of these. Build on
the existing engine + template system (reuse). Worktree `C:/Users/HP/hd-itsm-wt`
(branch feat/helpdesk-itsm @ da43c93), ABSOLUTE paths, local; I deploy after.

Owner's words → requirements:
1. "requests are too low" → the template library is too small; make it MUCH bigger.
2. "not categorized as departments" → the picker must be ORGANIZED BY DEPARTMENT
   (and category within), not a flat "all departments" grid.
3. "categories are literally so low, has to be too much" → expand the service
   catalog (many more categories + subcategories).
4. "when I select, it is not telling it's from incident / problem / request" →
   every template card must show its PROCESS as a badge, and selecting one must
   make the active process obvious.
5. "its parameters not autofilling, which are standard" → clicking a template must
   autofill ALL standard params (subject, description, process, category,
   subcategory, impact, urgency → priority). AND fix the state bug where changing
   Department desyncs the fields (subject said "My PC is slow" while description
   said "office equipment is broken", impact/urgency reset).
6. "where is SLA" → SLA must be prominent on the form AND visible on tickets;
   existing tickets show "—" (created pre-fix) → BACKFILL their SLA.
7. "where is the button to assign" → add an Assignee (+ Team) field to the
   New-Ticket form so a ticket can be assigned at creation.

---

## Agent 1 — backend (owns: itsm_seed.py, request_templates.py, tickets.py, sla.py; may add ONE include line to router.py if a new endpoint needs it)

### 1a. Expand the service catalog (itsm_seed.SERVICE_CATALOG) — a LOT
Replace the small map with a rich one: at least **10 categories**, each with
**5–10 subcategories**. Cover IT (Hardware, Software, Network, Access & Accounts,
Email & Collaboration, Security, Mobile Devices, Printing), Facilities, HR,
Finance/Procurement, Sales/CRM, Operations, Legal, Marketing, Onboarding/Offboarding,
Telephony. Keep it a `category → [subcategory]` map. This feeds the Service-Request
category pickers AND can seed template grouping.

### 1b. Expand the template library — a LOT (itsm_seed.seed_request_templates)
Go from 24 to a BROAD library: **~10–18 templates per department** across these
departments (ensure each exists via _ensure_departments): **IT, Sales, Finance,
HR, Facilities, Operations, Legal, Marketing, Security**. Each template row:
`template_name` (short title), `department_id`, `process` (incident | service_request
| problem | change — choose the right ITIL process per item), `default_subject`
(usually = title), `default_description` (a realistic 1–2 sentence default),
`default_category`/`default_subcategory` (from the catalog where it fits),
`default_impact`/`default_urgency` (sensible defaults so priority derives — e.g. an
outage = high/high, a routine request = low/low), a fitting lucide `icon`,
`enabled=True`. Idempotent (skip existing name+dept). Aim for **100+ templates total**.
Use realistic IT-service-desk items (access requests, outages, how-to, new-hire
provisioning, procurement, expense, facilities tickets, CRM issues, legal review
requests, marketing asset requests, security incidents, change requests like
"firewall rule change" / "production deploy", etc.). Return the count.

### 1c. create_ticket accepts an assignee (tickets.py)
Accept `assigned_agent` (agent email) in the create payload and set it on the
ticket (in addition to the existing department→team routing). If given, it should
survive auto_assign (an explicit assignee wins — don't let auto_assign overwrite a
provided assigned_agent). Keep backward-compat.

### 1d. SLA backfill (itsm_seed.py)
Add `recompute_all_slas(db, tid) -> dict` that runs `sla.recompute(db, t,
prev_status_category=t.status_category)` over every ticket in the tenant and
commits, so existing tickets (created before SLA-on-create) get response_by/
resolution_by/agreement_status. Call it from `seed_itsm` (after templates). Return
count recomputed. (This makes SLA show on the 69 existing tickets.)

### 1e. request-templates response — confirm it already returns `process`,
`default_*`, `icon`, `department` (it does per prior build). No shape change needed
unless you add a `category` display field (optional).

Verify: py_compile; itsm_seed + change self-checks; full router import. Report the
new catalog size (cats×subs), total templates seeded per department, the create
assignee key, and recompute_all_slas name.

## Agent 2 — frontend (owns: _newticket.tsx ONLY)

Overhaul the New-Ticket form. Keep the existing submit contract; ADD:

### 2a. Department- (and category-) organized template picker
- When NO department is selected: show templates GROUPED BY DEPARTMENT with a
  section header per department (IT, Sales, …), each listing its cards. (Fetch all
  via `GET /grc/helpdesk/request-templates` and group client-side by `department`.)
- When a department IS selected: show only that department's cards, optionally
  sub-grouped by the card's category.
- Make it scrollable and clearly sectioned (this list is now large — 100+).

### 2b. Process badge on every card + clear active process
- Each card shows a small badge with its PROCESS (Incident / Service Request /
  Problem / Change) — colour-coded — so the user sees what kind it is BEFORE
  picking. On click, switch the active process AND visibly reflect it (the process
  buttons already highlight; also show a line like "Creating: Incident").

### 2c. Full autofill + FIX the desync bug
- Clicking a card fills subject, description, process, category, subcategory,
  impact, urgency (→ derived priority) — ALL of them, atomically.
- FIX: changing Department must NOT corrupt already-filled fields or apply a stale
  template. Re-filtering the card list must not mutate the form values. (Root-cause
  the current effect that resets subject/impact/urgency and leaves a mismatched
  description — likely a useEffect keyed on department/process re-applying or
  clearing. Make template application happen ONLY on an explicit card click.)

### 2d. Prominent SLA
- Replace the easy-to-miss "SLA: respond 4h · resolve 1d" line with a clear SLA
  badge/callout (e.g. a highlighted row or chip near the top: "SLA — First response
  4h · Resolution 1d", from `GET /grc/helpdesk/sla-preview?process=&priority=`),
  updating live as process/priority change.

### 2e. Assignee (+ Team) field
- Add an **Assignee** select (agents from `GET /grc/helpdesk/agents`) and optional
  **Team** select (`GET /grc/helpdesk/teams`). Send `assigned_agent` (+ existing
  department routing) in the create payload. Make clear assignment is optional
  (unassigned routes by department).

Reuse `./_admin` controls + `./_ui` (Chip/PRIORITY_CHIP/useHd/hdCall) + #005B96
styling. Native controls. Verify with `node node_modules/typescript/bin/tsc
--noEmit` (junction node_modules from the main checkout, then delete it). Zero new
TS errors in _newticket.tsx. No deploy/commit. Report the new form layout + how you
fixed the desync + fields consumed.

## Ownership
- Agent 1: itsm_seed.py, request_templates.py, tickets.py, sla.py, (maybe 1 router.py line).
- Agent 2: _newticket.tsx only.
API base `/grc/helpdesk/...`. Deploy will re-run the seeder (bigger catalog +
templates + SLA backfill) + restart.
