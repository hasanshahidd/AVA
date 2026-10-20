# Overnight Help Desk completion — worklog

Owner is asleep. Goal: make the Help Desk **functionally complete + demo-ready** (NOT deploy/commit).
Work area: `C:/Users/HP/hd-itsm-wt` worktree ONLY. Backend :4102, frontend :3001, tenant `ava`
(login admin@ava.io / AvaAdmin2026!, approver bob@ava.io / Bob2026!).

Rules I'm holding to:
- Only the hd-itsm-wt worktree. Never touch main CyberAssurance tree, peer's :4101, or the
  grc_it_assets model / assets_router (read-only on assets).
- Never delete STANDARD seeded data. Only drop genuinely mock/demo data.
- No commit, no push, no deploy. Leave it demo-ready.
- Every fix is TESTED — backend pytest (in-memory) AND the frontend driven in the browser.
  No "done" without a live check.

## Method (sequential, step by step, one area at a time)
For each area: audit (find issues) → fix → backend test → **frontend browser test** → log. The
single shared backend (:4102) + DB (cyber_ava) are owned by ME (orchestrator): subagents only edit
code + run in-memory pytest, they do NOT restart the server or write the shared DB. I restart/verify.

## Owner's explicit concerns (must address)
1. **CMDB is using "demo data that flows inside the system", not the fixed standard data given from
   their side.** Find every place non-standard / computed / sample / demo data leaks into CMDB (CIs,
   relationships, CI types, business services, catalogue) and ensure CMDB = REAL inventory + the FIXED
   standard seed ONLY. Remove genuine demo/mock; keep all standard.
2. **CMDB linkage gaps** — wherever a linkage is missing, CREATE it (CI↔ticket, CI↔business-service,
   software↔host, domain↔endpoint, OS/network/app CIs, etc.).

## Findings log (updated as I go)
### Confirmed working (verified live earlier)
- CMDB sync/tree/CI modal/graph; Affected-CI picker; ticket CI card; exposure-aware CAB escalation;
  portal 5-step wizard + SR approval OPEN; agent dashboard analytics; incident state machine enforced
  (illegal jumps rejected); approval loop CLOSES (bob approves → approved, SoD blocks self-approval);
  AI-enrich New CI.

### Fixes already made this session
- cmdb_sync.py: dropped platform.properties bloat from CI mirror.
- _ci.tsx: AffectedCiPicker effect-deps bug (stuck "Loading…").
- changes/page.tsx + _actions.tsx: doubled "CAB required:" prefix.
- tickets.py + test_default_open_status.py: process-aware entry status (SR→Submitted not Draft).

### OPEN issues found (to fix overnight)
- [FE] Ticket actions (`act()` in tickets/[name]/page.tsx): backend set_status/assign/etc return
  HTTP 200 with `{ok:false, error}` on a rejected transition; `act()` only catches thrown errors, so
  a REJECTED action shows the SUCCESS toast and nothing changed. Fix: surface `res.data.ok===false`
  (or make the backend raise 4xx). Applies to all `act()` callers.
- [API] portal request_detail does not surface `approval_state` (list does) — approved SR reads null
  via GET /helpdesk/portal/requests/{name}. Add it to the detail serializer.
- [BE] priority matrix: incident created with impact=high/urgency=high → priority_id None (matrix
  lookup didn't resolve). Verify priority_from_matrix + seeded matrix; fix.
- [DATA] No SLA policy seeded for service_request (and maybe others) → SRs get no response/resolution
  due dates (portal shows "As soon as we can"). Seed standard SLA targets per process.
- [UX?] Approved SR stays in "Submitted" status (approval_state=approved but status unchanged) —
  decide if it should auto-advance to Approved/In Fulfilment. Confirm against ITIL intent.

## Area checklist
- [~] A. CMDB — audited (Agent A done): **data already clean, 0 demo** (sample_cis/sample_ci_rel leak
      already guarded by SEED_SAMPLE_CIS=False; A verified + fixed 4 stale tests + added regression lock).
      All structural linkages complete (245/245 assets, 241 CONTAINS, 50 INSTALLED, RUNSON correctly 0).
      REMAINING: CI↔business-service = 0/296 — DECISION (below). Then re-verify live + browser.
- [~] B. Governance/SLA — audited+fixed (Agent B done): all surfaces round-trip; most feed runtime.
      SLA root cause fixed (match was priority_code-only; non-incident rows have null code → no SLA) +
      NULL-resolution backfill in seed_itsm. Priority matrix + transitions verified complete.
      HANDOFF ITEMS: CAB config + KPIs are admin-editable but NOT read at runtime (quorum hard-coded
      DEFAULT_CAB_QUORUM); live-DB NULL SLA resolutions need the seed re-run to apply backfill.
      REMAINING: restart + run seed_itsm to apply backfill; browser-verify governance + SR due dates.
- [ ] C. Agent console + approvals — IN PROGRESS (Agent C, editing tickets.py).
- [ ] D. End-user portal — re-verify full wizard + my-requests/my-approvals after fixes.
- [ ] E. Full end-to-end re-test (all four areas, browser).

### DECISION — CI↔business-service linkage (owner wants missing linkages created)
Catalogue has 87 standard business services across 16 categories (all real standard seed, not demo).
Clean deterministic CI-type→service map exists for: CIT-WORKSTATION→SVC-0001 (Managed Workstation),
CIT-SOFTWARE→SVC-0002 (Desktop Software & Patching). The 243 external EASM web endpoints have NO clean
internal-service match (closest is "Server & Compute Hosting" — a stretch for discovered external
attack-surface sites); forcing them = the guessed/computed data the owner objects to.
PLAN: add an idempotent default CI-type→business-service assignment in cmdb_sync (fills business_service_id
ONLY when empty, so admin edits + spec's user-owned rule are preserved), covering the unambiguous types
only; leave web/other types for admin assignment. Tested + documented. (Deferred until C lands + base is
verified stable.)

## FINAL STATUS — functionally complete, demo-ready (not committed/deployed, per instructions)

All four areas audited A–Z, issues fixed, 183 backend tests green, key flows verified live in the browser.
Backend :4102 + frontend :3001 are running; login admin@ava.io / AvaAdmin2026! at http://ava.localhost:3001.

### Fixes shipped (this session, all on disk in hd-itsm-wt)
1. SLA engine: every process now gets response+resolution due dates (match was priority_code-only; non-
   incident rows had null code → no SLA). sla.py matching + NULL backfill in seed. Verified: portal SR now
   shows "in 21h", not "As soon as we can".
2. Agent console: rejected ticket actions now surface the real error (were showing a false success toast).
3. Assign auto-transition New→Assigned; approval park/release (SR Submitted→Pending Approval→Approved/Rejected).
4. Portal request detail now carries the approval summary (can_vote, quorum, state).
5. Process-aware entry status (SR→Submitted, incident→New, change→Draft — was all "Draft").
6. CMDB: confirmed 0 demo data (sample-CI leak already guarded; verified + regression-locked). 245/245 assets
   linked, 241 CONTAINS, 50 INSTALLED.
7. CI↔business-service linkage CREATED: 50 software→Desktop Software & Patching, 2 workstations→Managed
   Workstation (52/296; web EASM endpoints intentionally left for admin assignment — no honest 1:1 service).
8. Agents registered from the Help Desk Agent role (bob); sample/IGA .sample admins deliberately excluded.
9. Grammar + CAB double-prefix + picker stall + payload bloat (earlier).
Verified live in browser: illegal-transition error surfacing, assign→Assigned, priority matrix→Urgent+SLA,
portal wizard + SR due dates, CMDB tree/graph/CI modal/AI-enrich, all console list pages filter by process,
KB 57 articles, approval loop closes (bob approves).

### Known limitations (documented, NOT blockers for the demo)
- Change full-close (complete→Closed) needs status-stage sync (change has two tracks: approval_state vs
  ticket status; the status track isn't driven through Assess/Authorise/Scheduled/Implement/Review). The
  demo-critical change path — raise → CAB escalation → approve/reject — works. Left as a deliberate
  follow-up (fixing it blind risked regressions).
- CAB config + KPIs are admin-editable but not read at runtime (CAB uses DEFAULT_CAB_QUORUM). CAB still works.
- No HDAgentStatus availability catalog seeded (agents default to "Active").
- SLA resolution backfill uses uniform per-process defaults until tiered via Governance → SLA targets.

### To bring up for the demo
backend: cd hd-itsm-wt/backend && python -m uvicorn grc.main:app --host 127.0.0.1 --port 4102 --env-file .env
frontend: cd hd-itsm-wt/grc-frontend && next dev -p 3001   (then http://ava.localhost:3001)
If SLA/agents ever look unseeded after a DB reset: POST /helpdesk/itsm/seed (idempotent — seeds SLA backfill + agents).

## Governance wiring + dept cleanup (2026-10-20, follow-up)
- Department duplicates: root-caused (_ensure_departments seeded short names that didn't match the standard
  full names → 5 uncoded dupes) + the latent uq_hd_ticket_template_name 500. Fixed: _DEPT_STD maps short→
  standard(name,code); seed_request_templates resolves via it; template idempotency keyed on name only.
  Live: 52 templates re-pointed, Security coded SEC, strays deleted → 16 clean coded departments, seed idempotent.
- Change close-out: complete/cancel now sync the ticket status to Closed/Cancelled + stamp resolution + close
  SLA (change.py _sync_terminal_status). Live full lifecycle raise→…→complete → status Closed, resolved.
- CAB config WIRED: approvals._cab_quorum reads the "Quorum" CAB-config detail (first integer) → requirements_
  for_change uses it. Live: change read quorum 3 from config; editing config to "Minimum 1" → next change read 1.
- Role map WIRED: approvals._user_role_codes resolves a voter's AVA RBAC roles → ROLE-* via HDRoleMap.rbac_preset;
  _evaluate satisfies a required CAB role by an approver who declared it OR truly holds it (map augments, not
  replaces); cast_vote auto-stamps the resolved role for role-gated approvals. Live: mapped ROLE-CHGMGR+ROLE-SVCOWN
  → "Help Desk Agent", bob approved alone (quorum 1) and resolved both roles → approved. All helpers tolerant of
  missing tables (unit DBs). 183 tests green.
- Support-group → team map: NOW WIRED. Added HDTicket.support_group_code (+ idempotent ALTER in the seed),
  tickets.create_ticket/update resolve the group's mapped team (HDSupportGroupMap.team_id) into agent_group_id
  when no team is set explicitly (mirrors department→team routing), a light GET /helpdesk/support-groups list,
  and a Support-group picker on the New-Ticket form (shows "(unmapped)" for groups with no team yet). Proven
  live: a ticket tagged GRP-SERVICEDESK (mapped to a test team) auto-routed to that team; transient team+mapping
  reverted after. NOTE: the tenant currently has NO AVA teams and all groups are unmapped, so routing is inert
  until the owner creates a team and maps a group → team in Governance → Support groups (same prerequisite as
  the existing department→team routing). 183 tests green.

## Progress
(appended each cycle)

### Cycle 1 — Wave 1 launched (3 parallel agents, disjoint files, in-memory pytest, no shared-backend/DB writes)
- Agent A → CMDB: demo-data-vs-standard provenance audit + remove demo leaks + create missing linkages
  (owns cmdb_sync.py, cmdb_admin.py, sample-CI guards in itsm_import.py/itsm_seed.py).
- Agent B → Governance/SLA: per-surface round-trip + runtime wiring; FIX SLA matching so every process
  gets response+resolution due dates (SR currently has only a 'Standard' row w/ null resolution → no SLA);
  transition completeness (owns governance_admin.py, sla.py, SLA region of itsm_seed.py).
- Agent C → Agent console/approvals: FE act() shows success on rejected actions (HTTP200 {ok:false});
  portal detail missing approval_state; assign auto-transition New→Assigned; approved SR/change advancement;
  action-surface audit (owns tickets.py, approvals.py, change.py, portal.py, router.py, FE ticket detail +
  list pages).
- Pre-brief evidence gathered (read-only): priority matrix seeded correctly (high/high→1), priority_from_matrix
  looks correct — the earlier "None" is likely just response serialization; SLA gap confirmed (SR 'Standard'
  row, null resolution); governance admin UI renders all 10 surfaces with inline edit.
- On each agent's completion: I restart :4102, re-run its pytest + live API checks, drive the browser to
  verify its area, fix any FE gaps myself, update this log, then advance to the next area / wave.
- Chain stays alive via agent-completion re-invocation; I own the single :4102 restart + live DB + browser.
