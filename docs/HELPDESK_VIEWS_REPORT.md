# Help Desk — Saved Views, Configurable Queue, Rich Dashboard

Branch `feat/helpdesk-views` off `origin/main` (8a64e29). Three features that
match Frappe Helpdesk's visibility/workflow layer, built additively behind AVA's
invisible-engine rule (no engine names in any UI text or API response), tenant
partition-filtered on every read, RBAC-gated (VIEW to read, EDIT to write).

## Feature 1 — Saved / public views
A row of view pills above the Tickets list, each a preset client-side filter over
the already-loaded tenant rows, with a live count in the label:
- **All** — no filter.
- **Pending** — status in (Open, Replied).
- **Recently assigned** — has an assignee, sorted by `modified` desc, top 25.
- **SLA at risk** — `agreement_status == "Failed"` OR `response_by`/`resolution_by`
  in the past or within 24h (and not already resolved/closed).
- **With feedback** — `feedback_rating > 0`.

Backend: `/helpdesk/tickets` now also returns `feedback_rating` and `modified`
(needed by With-feedback and Recently-assigned). Still partition-filtered + VIEW-gated.

## Feature 2 — Configurable tickets queue
All client-side over the loaded rows, additive to the existing list/board toggle
and row-click → detail:
- **Filter** — status, priority, team, assignee dropdowns (options derived from the
  loaded rows), with a Clear button.
- **Sort** — created / priority / SLA due / status, asc or desc toggle.
- **Group by** — none / status / priority / team; grouped sections with counts.
- **Columns** — show/hide ID, Subject, Status, Priority, Team, Assignee, Customer,
  SLA due, Created, CVE. Default set is the 8 Frappe-equivalent columns; choice
  persisted in `localStorage` (`hd.tickets.cols`, try/catch-wrapped). Subject is
  always on.
- **Bulk actions** — row checkboxes + select-all; a bulk bar with **Resolve**
  (POST `/tickets/{name}/status` per ticket) and **Assign to agent** (POST
  `/tickets/{name}/assign` per ticket), both EDIT-gated server-side, with a
  progress/result toast and an ok/total count.

## Feature 3 — Rich dashboard
Backend: new **GET `/helpdesk/dashboard-analytics`** (VIEW-gated, partition-filtered)
fetches the tenant's HD Tickets and computes, in a pure unit-tested
`compute_analytics()`:
- KPIs: total, % SLA fulfilled (Fulfilled / tickets-with-a-verdict), avg first
  response (hours), avg resolution (days), avg feedback (0–5), feedback count.
- 30-day daily trend: created vs resolved per day.
- Breakdowns (counts): by team, priority, type, and status category.
Returns clean, de-branded JSON.

Frontend: KPI tiles + a 30-day created/resolved **area chart** + priority / status /
team / type **donuts** via `recharts`, AC `#005B96` accent, AVA's light-card style.
The existing recent-tickets table (from `/helpdesk/dashboard`) is kept.

## Files changed
- `backend/grc/modules/helpdesk/router.py` — `_parse_dt`, `_mean`,
  `compute_analytics`, `GET /dashboard-analytics`; `feedback_rating` + `modified`
  added to `/tickets`.
- `backend/tests/test_helpdesk_analytics.py` — new unit tests for the aggregation math.
- `grc-frontend/src/app/(dashboard)/helpdesk/tickets/page.tsx` — Features 1 + 2.
- `grc-frontend/src/app/(dashboard)/helpdesk/dashboard/page.tsx` — Feature 3.

## Verification
- `python -m pytest tests/test_helpdesk_analytics.py tests/test_frappe_helpdesk_adapter.py` — 8 passed.
- `tsc --noEmit` — 0 new errors (15 pre-existing errors remain, all in unrelated
  files + the known `_ui.tsx:52` baseline; none in the files changed here).
- Invisible-engine scan: no engine/provider names in the new API responses or UI text.

## Morning deploy note (peer-coordinated — do NOT deploy from this session)
Both a backend and a frontend change ship, so this needs the full build window
on the shared live box (143.198.176.10), coordinated with the pentest peer:
1. Merge `feat/helpdesk-views` → `main`.
2. On the box: `cd /root/AVA && git reset --hard origin/main`.
3. Backend: `systemctl restart ava-backend` (~12s).
4. Frontend (memory-heavy, ~10 min): `cd grc-frontend && NODE_OPTIONS=--max-old-space-size=2048 npm run build`, then restart the `next start` frontend service.
5. Smoke-test as an authenticated tenant: Tickets view pills + counts, filter/sort/
   group/columns/bulk, and the dashboard KPIs/charts render from live tenant data.
