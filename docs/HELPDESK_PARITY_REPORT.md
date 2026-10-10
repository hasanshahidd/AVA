# AVA Help Desk ⇄ Frappe Helpdesk — Parity Report & Handoff

**Branch:** `feat/helpdesk-parity` (off `21b92f7`, never merged/pushed).
**Scope governed by:** `docs/HELPDESK_PARITY_MATRIX.md` (the alignment audit — BUILD/SKIP verdicts + isolation contract). This report records what was built and the live-test evidence.

## Commits
| SHA | What |
|-----|------|
| `2e1b347` | docs: parity alignment audit (BUILD/SKIP verdicts + AVA isolation contract) — the Phase-0 gate |
| `b007277` | P1 core incident loop: auto-assign root-cause fix, SLA state, full conversation, lifecycle, `/meta`, `/update`, `/assign` + FE detail editor |
| `8e6b734` | P2/P3 reads: KB categories + feedback + views, agent availability |
| `17cd9d3` | fix: KB feedback uses engine's `1`=helpful/`2`=dislike codes |
| `c50df98` | test: guard the `agent_group=partition` auto-assign fix |

## Parity before → after
Counting the **BUILD** subset from the matrix (SKIP items excluded by design — they are irrelevant to / conflict with / duplicate AVA).

| Capability | Before | After |
|-----------|:------:|:-----:|
| Ticket list/detail, replies | ✅ | ✅ |
| **SLA state surfaced** (targets, breach, on-hold, failed-by) | partial fields | ✅ structured block |
| **Auto-assignment fires** | ❌ (broken: agent_group never set) | ✅ (fix verified live) |
| **Manual assignment** (agent + team) | stub | ✅ via assign_to engine |
| **Internal comments in timeline** | write-only | ✅ read + merged |
| **Activity timeline** | ❌ | ✅ read + merged (no data in this instance) |
| **Status transitions** (full status list) | resolve/close only | ✅ status list + inline change |
| **Priorities / ticket types** editable | hardcoded / none | ✅ via `/meta` |
| **Canned reply in composer** | list page only | ✅ insert into draft |
| **CSAT / feedback** on ticket | ❌ | ✅ read |
| **KB categories + article feedback + views** | flat list | ✅ grouped + counts |
| **Agent availability** (Available/Away/Busy) | active flag only | ✅ |

**BUILD items delivered: 12/12.** SKIP items (telephony, customer portal, inbound email, templates, saved-views/field-layouts, notifications-bell, SLA-policy mgmt, stopwords/synonyms, reactions, ERPNext bridge) left unbuilt per the audit, with reasons in the matrix.

## What was wired (all additive; existing rich code untouched)
**Backend** (`modules/helpdesk/router.py`, `connectors/providers/frappe_helpdesk.py`):
- Adapter `create_ticket` defaults `agent_group` to the tenant partition when that team exists (root-cause fix) — guarded by `_team_exists`.
- `GET /helpdesk/tickets/{name}`: structured `sla` block; `agent` (from `_assign`); merged conversation = `Communication` + `HD Ticket Comment` + `HD Ticket Activity`, sorted; feedback fields.
- `GET /helpdesk/meta`: global priority/type/status/feedback-option lists.
- `POST /helpdesk/tickets/{name}/update`: priority/type/status/team.
- `POST /helpdesk/tickets/{name}/assign`: agent (via `frappe.desk.form.assign_to.add`) + team; agent must be in-partition.
- `GET /helpdesk/tickets` list: now returns `type`, `agent`, `agreement_status`, `resolution_by`.
- `GET /helpdesk/articles`: category summary, per-article `helpful`/`not_helpful` (codes 1/2), `views`.
- `GET /helpdesk/agents`: richer `availability`.

**Frontend** (`helpdesk/_ui.tsx`, `tickets/[name]/page.tsx`, `kb/page.tsx`):
- Ticket detail: inline editable status/priority/type (from `/meta`), assign popover (agent+team), SLA agreement-status + breach badge, CSAT, canned-reply insertion.
- Timeline renders activity events as compact system lines.
- KB cards show views + helpful/not-helpful.

## AVA alignment & isolation (how each BUILD item stays tenant-safe)
- Every direct doctype read appends the server-derived `ava_tenant` partition filter (same `_tenant_filters` pattern as before).
- Child/related records with **no** `ava_tenant` (comments, activity, communications, article feedback) are read **only** by the key of a parent (`HD Ticket`/`HD Article`) first confirmed in-partition — never a global query. Proven by the isolation checks below.
- Global enums (priority/type/status/feedback-option) are exposed as option lists only — no tenant data.
- All writes stay behind `_ticket_in_tenant` + RBAC `vulnerabilities:vulnerability_register:edit`; assignment only to in-partition agents. No new unscoped doctype introduced.
- AVA concepts: agents = AVA users in the tenant's team; findings/CVE/host ride existing custom fields; remediation-plan mobilisation path unchanged.

## Tests
- **Backend unit:** `test_connector_registry`, `test_sync_auto_ticket_cfg`, `test_itsm_mobilisation` (18) + new `test_frappe_helpdesk_adapter` (3) — **all pass**. The registry contract (frappe_helpdesk registered-but-internal) still holds.
- **FE typecheck:** `tsc --noEmit` — my changed files add **zero** new errors. One pre-existing error remains in `helpdesk/_ui.tsx:52` (the `Avatar` `[...n]` spread — identical at `21b92f7`, untouched); the repo also has unrelated pre-existing errors in `pentest/*`, `vulnerabilities/*`, `components/*`. The project builds via Next's SWC; baseline `tsc` was not clean before this work.

### Live round-trips (real engine, `ava_tenant="__hd_selftest__"`, every record deleted after)
**P1 core loop** — one ticket created with `agent_group=<selftest team>` + a matching assignment rule:
```
sla_applied: true · agreement_status: "First Response Due"
assign_fired(auto): true · assignee: [selftest agent]      ← THE FIX
comments_readback: 1 · comms_readback: 2 · activity_readback: 0
manual_assign_ok: true
status_after: Resolved · status_category: Resolved
feedback_set: true · feedback_rating: 1.0
isolation_other_partition_sees_it: 0                       ← tenant isolation holds
CLEANUP leftovers: []
```
**P2 KB** — one article + category + 3 feedback (1,1,2):
```
articles_found: 1 · categories: [{count:1}] · helpful: 2 · not_helpful: 1
isolation_ava_sees_it: 0                                   ← isolation holds
CLEANUP leftovers: []
```
**Agent availability** verified read-only against the real `ava` partition (4 agents, `availability="Active"`).

**Evidence notes:** the engine has **0** `HD Ticket Activity` and **0** `HD Ticket Comment` rows across all 64 demo tickets (bulk-seeded, never through the UI flow that emits them), and **0** KB articles under `ava` — so the activity/comment/article read paths were proven against self-test data, run cleanly against real data, and return `[]` gracefully when empty. The KB feedback code mapping (`1`=helpful, `2`=dislike) was taken from the engine's own `helpdesk/api/article.py`.

## Deferred (noted, not blocking)
- #16 customer members: left as count=0; resolving needs a per-customer doc fetch (N calls) — low value, defer.
- `HD Ticket Activity` / internal-comment data: present in code, no data to display in this engine instance until tickets flow through the agent desk.

## MORNING DEPLOY CHECKLIST (owner — coordinate with the pentest peer first)
The box is shared (2GB, prod complyverse + pentest peer). Nothing in this work was deployed.
1. **Coordinate with peer** ("Pen test GPT research") before any `ava-*` restart — they have a live-fire sweep running.
2. Merge `feat/helpdesk-parity` → `main` via PR (deploys are `git reset --hard origin/main`; no hand-edits on the box).
3. On the box, pull main into `/root/AVA` (owner's normal deploy, peer-aware).
4. **Backend** (`modules/helpdesk`, `connectors/providers/frappe_helpdesk`): `systemctl restart ava-backend ava-worker` (boot ~12s). Backend is `:4000`.
5. **Frontend** (3 changed files): rebuild — `cd /root/AVA/grc-frontend && NODE_OPTIONS=--max-old-space-size=2048 npm run build` (~10 min, heavy on 4GB; build when the box is quiet), then `systemctl restart ava-frontend` (runs `next start`).
6. No Frappe engine change required — all custom fields, the `Standard` SLA, the `ava - Support Rotation` assignment rule, and the `ava` team already exist live. New tenants only need their team named == their partition slug for auto-assignment to fire (document this in tenant onboarding).
7. Smoke-test after deploy: open a finding → "Create Help Desk ticket" → confirm the ticket shows an assignee and SLA targets in the Help Desk detail view.

## Cleanliness
- Worktree `git status`: clean except the 5 intended commits above.
- Box: no `__hd_selftest__` records remain (every live test verified `leftovers=[]`); no `ava-*` service touched; no `/root/AVA` working-tree change; only `ava_helpdesk` containers were read + minimal self-test writes (deleted).
