# Help Desk ITSM — build spec (authoritative contract)

ITIL-lite: make **Incident / Problem / Change / Service Request** first-class HD
modules on top of the existing native engine. This is a **build-only-the-gap**
job: the HDTicket engine (SLA business-hours, assignment, replies, statuses,
departments/teams, dashboard) is DONE and REUSED as-is. We add a process
discriminator, a few process-specific fields, per-process pages, per-process
seeded SLAs, and a rich process-aware New-Ticket form.

**Everything in this doc is the contract. Implement these names EXACTLY — other
agents code against them in parallel. Do not rename, do not invent alternates.**
Worktree root: `C:/Users/HP/hd-itsm-wt`. All local, no deploy.

---

## 0. The discriminator

`HDTicket.process` — `String(20)`, NOT NULL, server_default `'incident'`.
Allowed values (exact strings): `incident` | `problem` | `change` |
`service_request` | `question`.

A ticket's `process` is set at create and never auto-changes. Findings→tickets
and the default New-Ticket path both create `incident`.

---

## 1. HDTicket extension columns (ALL nullable unless noted)

Add to `backend/grc/models/_60_helpdesk_native_models.py`, HDTicket:

Shared (incident + service_request use these for the priority matrix):
- `impact`   String(10)   — `low` | `medium` | `high`
- `urgency`  String(10)   — `low` | `medium` | `high`

Change:
- `change_type`          String(20)  — `standard` | `normal` | `emergency`
- `change_risk`          String(10)  — `low` | `medium` | `high`
- `planned_start`        DateTime
- `planned_end`          DateTime
- `implementation_plan`  Text
- `backout_plan`         Text
- `approval_state`       String(20)  — `draft` | `pending_approval` | `approved` | `rejected` | `scheduled` | `in_progress` | `review` | `closed` | `cancelled`
- `approved_by`          String(255) — agent email
- `approved_at`          DateTime

Problem:
- `root_cause`           Text
- `workaround`           Text
- `known_error`          Boolean, server_default false
- `problem_resolution`   Text
- `linked_incident_ids`  Text  — JSON array of HDTicket ids, e.g. `"[12,15]"`

Service Request:
- `request_category`     String(100)
- `request_subcategory`  String(100)

No new tables. Linked incidents are a JSON list on the problem ticket.
`# ponytail: JSON list of incident ids; add a link table only if reverse-lookup/perf ever matters.`

Tables are created per-tenant via `Base.metadata.create_all` (no Alembic). A
column add on an existing table does NOT auto-apply via create_all — the seeder
(section 3) runs an idempotent `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` for
each new column so existing tenant DBs get them. (Postgres supports
`ADD COLUMN IF NOT EXISTS`.)

---

## 2. Write path — tickets.py (owned by Agent A)

Extend, keeping signatures backward-compatible:

### `create_ticket(db, tid, payload: dict, raised_by=None) -> dict`
Recognize these payload keys (all optional): `process`, `impact`, `urgency`,
and every extension field in §1. Rules:
- `process` defaults to `'incident'` when absent/blank; reject unknown values (400).
- If `priority_id` is absent AND `impact`+`urgency` are present, derive priority
  via `priority_from_matrix(db, tid, impact, urgency)` (§4).
- `known_error` coerces to bool; `linked_incident_ids` accepts a list → store as
  JSON string.
- Persist all provided extension fields; ignore ones irrelevant to the process
  (store what's sent — no hard per-process field gating, keep it lazy).
- `change` tickets default `approval_state='draft'` when not supplied.
- Everything else (status default, SLA recompute, assignment) runs unchanged.

### `list_tickets(db, tid, process: Optional[str]=None, **filters) -> dict`
Existing list, PLUS an optional `process` filter. When `process` is given,
return only tickets with that `process`. Each serialized ticket MUST include
`process` and the process-relevant extension fields (include them all; FE picks).

### `update_ticket(db, tid, id, payload) -> dict`
Accept the same extension keys so detail panels can edit them.

### `priority_from_matrix(db, tid, impact, urgency) -> Optional[int]` (§4)
Lives here (or common.py), returns the HDTicketPriority.id.

Also: add `process=ticket.process` to `sla.py::_ctx()`'s doc dict (one line) so
SLA conditions can key on `doc.process`. (Agent A owns this one line in sla.py.)

---

## 3. Seeder — NEW `backend/grc/modules/helpdesk_native/itsm_seed.py` (Agent A)

`seed_itsm(db, tid) -> dict` — idempotent; safe to re-run. Does:

1. **Columns**: `ALTER TABLE grc_hd_ticket ADD COLUMN IF NOT EXISTS ...` for every §1 column (raw SQL, wrapped per-column in try/except so a pre-existing column is a no-op).
2. **Priorities**: ensure Urgent/High/Medium/Low exist (HDTicketPriority).
3. **Statuses**: ensure Open(Open)/Replied(Open)/Resolved(Resolved)/Closed(Resolved) exist.
4. **Ticket types**: ensure one type per process label exists for the dropdown: Incident, Problem, Change, Service Request, Question — each with `name` matching and a sensible default priority.
5. **Service catalog**: seed a small `request_category`→subcategories map the New-Ticket form reads. Expose via GET endpoint (§5, service_request.py). Minimal default set:
   - IT: Hardware, Software, Network, Access/Account, Email
   - Facilities: Office, Equipment
   - HR: Onboarding, Payroll
   - Finance: Expense, Procurement
   Store as an `HDSettings`-style JSON or a tiny constant the endpoint returns; no new table needed (constant default + optional HDSettings override is fine).
6. **Per-process SLAs** — create via the existing `sla.create_sla(...)` (so validation + default-priority resolution run), one per process, each with Mon–Fri 09:00–17:00 service days and per-priority targets (seconds). Only create if a SLA with that `service_level` name doesn't already exist. Targets (response / resolution, business-hours seconds):

   | SLA (service_level) | condition | Urgent | High | Medium | Low |
   |---|---|---|---|---|---|
   | `Incident SLA` | `doc.process == 'incident'` | 1h/4h | 2h/8h | 4h/24h | 8h/48h |
   | `Service Request SLA` | `doc.process == 'service_request'` | 4h/8h | 4h/16h | 8h/40h | 8h/80h |
   | `Change SLA` | `doc.process == 'change'` | 4h/24h | 8h/72h | 8h/120h | 8h/240h |
   | `Problem SLA` | `doc.process == 'problem'` | 8h/72h | 8h/120h | 8h/240h | 8h/480h |

   (Hours are business hours; resolution ≥ response. Durations in seconds:
   1h=3600, 4h=14400, 8h=28800, 24h=86400, 48h=172800, 72h=259200,
   120h=432000, 240h=864000, 480h=1728000.) Mark the Default priority per SLA =
   Medium. `enabled=True`, `default_sla=False` (they select by condition), `apply_sla_for_resolution=True`.

Also expose `POST /helpdesk/itsm/seed` (require_edit) that calls `seed_itsm`, and
a `backfill_process(db, tid)` that sets `process` on existing tickets from their
ticket_type.name (Change→change, Problem→problem, Service Request→service_request,
else incident). Run backfill inside seed.

Leave a `if __name__ == "__main__"` self-check asserting the matrix + that the
seed dict reports the 4 SLAs.

---

## 4. Priority matrix (ITIL 4-level)

`priority_from_matrix(db, tid, impact, urgency)` returns HDTicketPriority.id for:

| impact \ urgency | high | medium | low |
|---|---|---|---|
| **high**   | Urgent | High | Medium |
| **medium** | High | Medium | Low |
| **low**    | Medium | Low | Low |

Look the name up in HDTicketPriority (tenant-scoped). Missing/none → return None.
Pure helper → cover with an assert in tickets.py or itsm_seed self-check.

---

## 5. Process backends — Agent B (NEW files + router.py)

Each new module exposes its own `APIRouter`; Agent B wires them into
`helpdesk_native/router.py`. All reuse `tickets.list_tickets` / `create_ticket` /
`update_ticket` (Agent A's write path) for data — B adds process actions +
process-scoped list endpoints. Auth: require_view reads, require_edit writes.
Tenant-scoped via `common.tenant_id`.

- `incident.py` → `GET /helpdesk/incidents` = `list_tickets(process='incident')`. Thin.
- `problem.py`:
  - `GET /helpdesk/problems` = list_tickets(process='problem').
  - `POST /helpdesk/problems/{id}/link-incident` body `{incident_id:int}` → append to `linked_incident_ids`.
  - `POST /helpdesk/problems/{id}/unlink-incident` body `{incident_id:int}`.
  - `POST /helpdesk/problems/{id}/known-error` body `{known_error:bool}`.
  - `PUT /helpdesk/problems/{id}` → update_ticket with root_cause/workaround/problem_resolution.
- `change.py` — approval workflow is `approval_state`:
  - `GET /helpdesk/changes` = list_tickets(process='change').
  - `POST /helpdesk/changes/{id}/submit`   draft → pending_approval.
  - `POST /helpdesk/changes/{id}/approve`   pending_approval → approved (stamp approved_by from current_user email + approved_at).
  - `POST /helpdesk/changes/{id}/reject`    pending_approval → rejected.
  - `POST /helpdesk/changes/{id}/schedule`  body `{planned_start,planned_end}` approved → scheduled.
  - `POST /helpdesk/changes/{id}/start`     scheduled → in_progress.
  - `POST /helpdesk/changes/{id}/review`    in_progress → review.
  - `POST /helpdesk/changes/{id}/complete`  review → closed (also set ticket status Closed).
  - `POST /helpdesk/changes/{id}/cancel`    any → cancelled.
  - Guard illegal transitions with a 400 (allowed-map, like tickets.is_valid_status_transition). Leave a self-check asserting the transition map.
- `service_request.py`:
  - `GET /helpdesk/service-requests` = list_tickets(process='service_request').
  - `GET /helpdesk/service-catalog` → the categories/subcategories map from the seed (§3.5).

router.py: include incident/problem/change/service_request routers alongside the
existing ones. Don't touch tickets.py (Agent A owns it) — import from it.

---

## 6. Frontend process pages — Agent C

New pages under `grc-frontend/src/app/(dashboard)/helpdesk/`:
`incidents/page.tsx`, `problems/page.tsx`, `changes/page.tsx`,
`service-requests/page.tsx` (+ any `_*.tsx` helpers co-located). Reuse the
existing HD UI kit: import from `../_ui` (Chip, PRIORITY_CHIP, SlaBadge, useHd,
ErrorBanner, timeAgo) and `../../dashboard/_components/kit` (Card, Empty,
Loading, T, nfmt). Match the existing tickets/dashboard visual language.

- Each page: a process-filtered list (call the §5 GET endpoint), same columns as
  the tickets list, PLUS process-specific columns:
  - Changes: approval_state badge, change_type, planned window; row actions for
    the §5 transitions (submit/approve/reject/schedule/...) via a small action menu.
  - Problems: known_error badge, linked-incident count, root_cause presence.
  - Service Requests: category/subcategory.
  - Incidents: impact/urgency.
- Detail: reuse the existing ticket detail route (`tickets/[name]`) for the
  conversation/reply side; the process pages own the process-specific panel
  (Change approval/CAB panel, Problem root-cause/known-error panel). Simplest:
  a detail drawer/panel on each process page is fine — don't rebuild the reply
  thread, link to the ticket detail for that.
- `Sidebar.tsx` (`src/components/layout/Sidebar.tsx`): add nav entries under the
  Help Desk group, after Tickets: **Incidents, Problems, Changes, Service
  Requests** (pick lucide icons: AlertCircle, Search/Bug, GitPullRequest/Repeat,
  ShoppingCart/ClipboardList). Rebase-safe: the group is the `children` array
  around line 129–136. Leave Tickets as the all-process view.

---

## 7. Frontend New-Ticket form — Agent D

Owns `grc-frontend/src/app/(dashboard)/helpdesk/tickets/page.tsx` (the current
New-Ticket trigger lives here) + a NEW `helpdesk/_newticket.tsx` component.

Rich, process-aware create flow (modal or slide-over):
1. Step 1: pick **Process** (Incident / Service Request / Problem / Change) +
   **Department** (GET /grc/helpdesk/departments). Subject always.
2. Process-specific fields:
   - Incident: Impact + Urgency selects → show the derived Priority live
     (compute client-side via the §4 matrix so the user sees it; backend
     re-derives authoritatively). Description.
   - Service Request: Category → Subcategory (from GET /grc/helpdesk/service-catalog),
     Impact/Urgency optional, Description.
   - Problem: Description, optional Root cause, link-incidents (multiselect of
     open incidents) — can be left for the detail page; keep create minimal.
   - Change: Change type (standard/normal/emergency), Risk, Planned start/end,
     Implementation plan, Backout plan, Description. Created in `draft`.
3. Show the SLA that will apply (optional: resolve from the process → the seeded
   SLA name; a static label per process is acceptable for v1).
4. Submit → `POST /grc/helpdesk/tickets` with `process` + the collected fields.

Reuse the existing UI kit + form controls already used elsewhere in HD. Don't
touch the process pages (Agent C) or the backend.

---

## 8. Integration contract summary (so agents don't collide)

File ownership — DO NOT edit files you don't own:
- **A**: `_60_helpdesk_native_models.py`, `helpdesk_native/tickets.py`,
  `helpdesk_native/itsm_seed.py` (new), one line in `helpdesk_native/sla.py` (_ctx).
- **B**: `helpdesk_native/incident.py|problem.py|change.py|service_request.py`
  (new), `helpdesk_native/router.py`. Imports A's tickets.py functions.
- **C**: `helpdesk/{incidents,problems,changes,service-requests}/*` (new),
  `components/layout/Sidebar.tsx`.
- **D**: `helpdesk/tickets/page.tsx`, `helpdesk/_newticket.tsx` (new).

API base: backend grc_app is mounted under `/grc`, so FE calls `/grc/helpdesk/...`.
`useHd` already prefixes correctly (match existing usage).

Each agent: `py_compile` (backend) / `tsc`-clean against the repo's config
(frontend) before reporting done. Backend self-checks via `python -m` where a
`__main__` exists. Report: files changed + exact new field/endpoint names + any
deviation from this spec.
