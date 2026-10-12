# Help Desk — Full Frappe Audit & Conversion Inventory

Read-only audit of the **owned** Frappe Helpdesk fork (`helpdesk-app/`) for a faithful **1:1 code conversion** to AVA's FastAPI/SQLAlchemy stack (one server). Rule: **convert as-is where the stack allows; convert code where it differs; logic and flow stay identical to Frappe — never rebuilt from scratch.** For features Frappe does **not** have (Departments, our own dashboard), we build them ourselves — owner-authorized, and only those.

Per-unit detail (every DB field + controller flow) lives in the four section files under the session scratchpad: `audit_A_ticket_domain.md`, `audit_B_sla_people.md`, `audit_C_kb_search_settings.md`, `audit_D_analytics_portal_subsystems.md`. This file is the executive layer + the conversion backlog + the net-new design.

---

## 1. Headline findings

**Frappe Helpdesk is a single-object support-ticket desk — NOT an ITSM suite.** Grounded in the full 38-doctype list + `setup/` fixtures:

| ITSM concept owner asked about | Exists in Frappe? |
|---|---|
| Service Catalog | ❌ No doctype, no fulfillment flow |
| Service Requests | ❌ No — everything is one `HD Ticket`; "Service" only ever means SLA |
| **Departments** | ❌ No `HD Department`, no `department` field anywhere. Only `HD Team` (an assignment group, surfaced as `agent_group`) |
| Incident / Problem / Change modules | ❌ No — "Incident" is merely a seeded *Ticket Type* label, zero lifecycle |

**What Frappe actually gives us:** `HD Ticket` + `HD Ticket Type` (free text categorization) + `HD Ticket Priority` + `HD Ticket Status` (Open/Paused/Resolved categories) + `HD Team` + `HD Customer`/member + `HD Agent` + `HD Article` (KB) + SLA (priorities/service-days/holidays) + `HD Saved Reply` + feedback. ERPNext integration = **customer-record mirroring only**.

➡️ **Consequence:** the owner's requirement — a general multi-**department** service desk where Sales raises "PC slow", Finance raises its own categories, and IT/Security gets vulns — is **net-new build**, not a conversion. Departments + routed multi-department intake do not exist in Frappe. Everything plugs onto the converted engine (see §4).

---

## 2. Overall tally (83 units audited)

| Verdict | Count | Meaning |
|---|---|---|
| ✅ **Converted** | 12 (+1 partial) | Already live in `helpdesk_native/` |
| 🟢 **Take as-is** | 2 | Pure data table, no logic |
| 🟡 **Needs conversion** | 37 | Real Frappe logic to port 1:1 |
| ⚪ **N/A to AVA** | 32 | Frappe-framework-only (portal SPA, Redis/NLTK/SQLite search, Email Account/IMAP, Notification Log, Assignment-Rule doctype, ERPNext, i18n, migration notices) |

The ⚪ bucket is large because Frappe couples heavily to its own framework (its own search engines, email ingestion via core Email Account + IMAP poller, realtime, permission framework, the Vue portal SPA). AVA already has its own equivalents (auth, RBAC, tenant, frontend), so those are correctly **not** ported.

---

## 3. Conversion backlog — what's left to port (🟡), prioritized

### Tier 1 — core ticket parity (makes the engine behave like Frappe)
- **Master-CRUD + guards** for Status / Type / Template / Feedback Option (last-of-category guards, system-type delete-guard, rating bounds). *(A)* — M
- **Ticket controller tails**: bulk-reply + attachment fan-out, agent-only assign helper, admin delete, merge-chain redirect, auto-close-after-N-days, row-level `permission_query`/`has_permission`. *(A, hooks)* — M/L
- **SLA write-side**: config validation (`validate_*`, single-default toggle, default_priority), and **Holiday-List edit → live-ticket SLA recompute** (`on_update` re-flow). *(B)* — M
- **Default-data seed** must match `setup/` exactly: statuses, priorities, SLA timings (Mon–Fri 10–18 + holiday list), feedback options, General KB category. *(D)* — M
- **consts.py field-visibility sets** (permlevel 7/8 → customer-vs-agent field gating) — load-bearing for ticket serialization. *(D)* — S

### Tier 2 — people / masters
- **HD Agent Status** table (no native table yet) + agent availability write/validate/default-cascade + role sync. *(B)* — M
- **HD Customer Member + Contact store** (both unmapped) → unblocks customer create/delete, contact CRUD, membership + manager-role, invites. *(B)* — L
- **HD Settings** native per-tenant subset (branding, feedback-mandatory, comment-reactions, team-restriction flags, auto-update/auto-close) + `config.py` public read. *(C)* — M

### Tier 3 — features
- **Saved-reply actions engine** (set field / assign / tag / comment applied after send) + scope/team permission query + `teams` child. *(C)* — L
- **KB CRUD**: category create/merge/move (≥1-article invariant, General reserved), publish-stamping, view-increment, **article feedback table** for real like/dislike. *(C)* — M
- **Tags**: native tag store + join table → ticket tagging + tag dashboard charts. *(A)* — M
- **Saved views** (`HD View`): persisted list/kanban/group-by views. *(A)* — M
- **Analytics to full parity**: period **deltas/% change**, manager permission gate, agent/team scoping, SLA-on-trend line, channel breakdown; `ticket_stats.py` (feedback distribution, SLA-violation adaptive buckets); `ticket_analytics.py` per-ticket SLA timeline (heaviest — needs SLA calendar + Version/audit-diff + conversation feed). *(D)* — M/L
- **Comment handlers** (`extends/comment`): internal ticket comments + permissions — confirm vs existing tickets port. *(D)* — M
- **Notifications** (reaction/reopen) onto AVA's own notification channel (optional). *(C/D)* — M

### Explicitly ⚪ (not porting unless owner asks)
Both search engines (Redis+NLTK, SQLite FTS), stopwords/synonyms, inbound email→ticket (Email Account + IMAP), outbound email templates + CRUD, field-dependency JS generator, ERPNext mirror, Notification Log substrate, i18n, migration banners, the Vue portal SPA, Frappe auth/session/permission framework.

---

## 4. NET-NEW (build ourselves — Frappe has none)

### 4a. Departments + multi-department intake  ← the owner's core new requirement
Frappe has only `HD Team`. We add a thin **Department** layer that plugs onto the *already-converted* SLA + assignment engines — **no new routing algorithm needed**:

- **`grc_hd_department`** (new): `id, tenant_id, name, description, default_team_id → grc_hd_team, enabled`.
- **`grc_hd_ticket.department_id`** (new column → `grc_hd_department`).
- **`grc_hd_ticket_type.department_id`** (new, nullable → department): null = global type; set = department-scoped category. This is how "Finance has its own request kinds, Sales has IT ones" without new machinery.
- **Routing (reuses existing engine):** New-Ticket create resolves department → sets `ticket.agent_group = department.default_team_id` → the **existing `assignment.py`** round-robin/load-balance picks the agent in that team, and the **existing `sla.py`** applies the SLA. Departments are just the front door onto the converted pipeline.
- **Vuln feed = one source** that maps to the IT/Security department automatically; Sales/Finance/HR requesters never see vuln framing.
- **Open question (blocks the data model):** is a requester's department **derived from their AVA identity/profile**, **chosen in the New-Ticket form**, or **both**? (asked separately.)

### 4b. New-Ticket create flow (fully wired, not a stub)
`department → category/type valid for that department → auto-route & assign to that department's team`. Backend: extend `tickets.create_ticket` to accept `department_id`, validate the type is allowed for the department, stamp `agent_group` from the department, then the existing create→SLA→assign path runs unchanged.

### 4c. Our own Dashboard + Home (AVA-styled, phenomenal)
Redraw Frappe's Home/Dashboard as a native AVA UI like other AVA features. **Runs on the FINAL schema, after Departments exist** (own agent later) — so it isn't redrawn twice.

---

## 5. Sequence (locked with owner)
1. ✅ Audit (this doc).
2. Lock Department design (answer §4a open question) → extend native model (`grc_hd_department` + 2 columns).
3. Finish Tier-1 conversion + wire native live locally (mount router, create `grc_hd_*` tenant tables, frontend → native).
4. New-Ticket create flow (department→type→route/assign) end-to-end.
5. Own Dashboard + Home redesign (own agent) on final schema.
6. Verify from UI locally → **then** retire Frappe fork + `helpdesk-app/docker/`.

Constraints throughout: **local only, no deploy, no push to server, don't delete the Frappe fork until native is proven from the UI.**
