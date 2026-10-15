# Help Desk — bank-grade hardening spec

Fix EVERY finding in `docs/HELPDESK_BANK_READINESS_AUDIT.md` to make the Help Desk
production/bank-ready. Worktree `C:/Users/HP/hd-itsm-wt` @ b570add, ABSOLUTE paths,
LOCAL (I deploy after + re-audit). Security-critical — the exploit fixes must be
VERIFIED ADVERSARIALLY (prove the exploit is blocked), not just compiled.

## Permission names (already in PERMISSION_MATRIX; ENFORCE them now)
helpdesk: requests:create, requests:view_own, tickets:view, tickets:create,
tickets:edit, tickets:delete, tickets:assign, processes:view, processes:manage,
kb:view, kb:author, settings:view, settings:manage.

## Segregation-of-duties map — the required permission PER endpoint group
(H1: today only tickets:view/edit/delete are enforced; wire these finer gates.)
- Core ticket read → `tickets:view`; create/edit/reply/update → `tickets:edit`;
  assign → `tickets:assign`; delete/merge → `tickets:delete`.
- Requester portal → requests:create / requests:view_own (already correct — keep).
- SLA config + holiday lists (sla.config_router) → `settings:manage` (read: settings:view).
- HD Settings + the /config endpoint + mailbox/email-account (mail.py) → `settings:manage` (read: settings:view). /config must REQUIRE auth+settings:view (today it's write-on-read + weak — gate it).
- Masters (status/type/template/priority/feedback-option) WRITE → `settings:manage`; read → settings:view (or tickets:view).
- KB article/category/feedback WRITE → `kb:author`; read → `kb:view`.
- Agent/customer/membership write + HD role grant/revoke (people.py people_write_router, agent_status) → `settings:manage`.
- Change/Problem/Incident/Service-Request process ACTIONS (approve/reject/schedule/link/known-error/etc.) → `processes:manage`; their list/read → `processes:view` (or tickets:view).
- tags/views write → `tickets:edit`; read → tickets:view.
Admin + tenant primary_contact still bypass (intentional) — but see H2.

---

## Agent 1 — Foundation: gate helpers + offboarding fix + central audit (owns: common.py, auth_router.py, NEW audit.py)
- **common.py**: define gate helpers (keep require_view=tickets:view, require_edit=tickets:edit, require_requester, require_request_create). ADD, via `require_tenant_permission`:
  `require_settings_manage` ("helpdesk:settings:manage"), `require_settings_view`,
  `require_kb_author`, `require_kb_view`, `require_processes_manage`,
  `require_processes_view`, `require_tickets_assign`, `require_tickets_delete`,
  `require_tickets_create`. Keep `current_user_email`.
- **H2 offboarding/idle (auth_router.py)**: `require_tenant_permission`'s inner dependency MUST perform the SAME `is_active` recheck + idle-timeout enforcement that `require_auth` does (read require_auth, mirror it) BEFORE the permission check, so a deactivated user or an idle/expired session is rejected on permission-gated endpoints too. Admin/primary-contact bypass still applies only AFTER the active/idle check passes.
- **NEW helpdesk_native/audit.py — `hd_audit(db, *, tenant_id, actor_email, action, entity, entity_id=None, before=None, after=None, request=None)`** (H3): writes a row to the CENTRAL audit log (reuse `backend/grc/audit_logger.py` / its model — read it; if it has a helper, call it). Requirements: NOT silently fail-open (on write failure, log at ERROR with the full event; never lose it quietly); capture before→after dicts for mutations; store actor, action, entity, ids, timestamp, source ip if request given. Do NOT dump full PII blobs — store changed field names + ids, truncate free-text. (Tamper-evidence / hash-chain: out of scope here — leave a `# TODO bank-phase2: append-only/hash-chain at DB/infra` note.)
Report the exact helper names + hd_audit signature (contract for others).

## Agent 2 — Injection: SLA eval (B1) + Jinja SSTI (B2) (owns: sla.py, replies.py)
- **B1 (sla.py:213,470,608)**: REMOVE `eval(...)`. Implement `safe_condition_eval(condition: str, context: dict) -> bool` using `ast.parse(condition, mode="eval")` + a strict NodeVisitor allowlist: allow ONLY BoolOp(and/or), UnaryOp(Not), Compare (==,!=,<,<=,>,>=,In,NotIn), Name (only `doc`), Attribute (only `doc.<field>` where field ∈ the _ctx doc keys), Constant/Str/Num, and List/Tuple of constants (for `in`). REJECT (raise) Call, Subscript, Lambda, comprehensions, dunder names, anything else. Evaluate the allow-listed tree against {"doc": ...} WITHOUT eval/exec. Use it at all 3 sites (runtime selection + validation). Gate sla.config_router writes with `require_settings_manage`.
  **ADVERSARIAL SELF-CHECK (__main__):** assert `safe_condition_eval("().__class__.__bases__[0].__subclasses__()", {...})` RAISES (blocked); assert `safe_condition_eval("doc.priority == 'High'", {"doc": {"priority":"High"}})` is True; assert a few legit conditions work and that `__import__`, attribute walks, and calls are rejected.
- **B2 (replies.py:467-475,507)**: replace `jinja2.Template(body).render(ctx)` with `jinja2.sandbox.ImmutableSandboxedEnvironment(autoescape=False)`'s `from_string(body).render(ctx)` (sandbox blocks unsafe attr/global access). Keep legit `{{ var }}` substitution. Gate saved-reply WRITE endpoints with `require_kb_author` (or tickets:edit if that fits the UX better — pick one, note it). **SELF-CHECK:** assert rendering `"{{ ''.__class__ }}"` or `"{{ cycler.__init__.__globals__ }}"` raises jinja2 SecurityError (blocked), and a normal `"Hi {{ name }}"` renders.

## Agent 3 — Core + process gating + audit + self-approval + PII (owns: tickets.py, portal.py, change.py, problem.py, incident.py, service_request.py)
- Apply gates: ticket assign → `require_tickets_assign`; delete/merge → `require_tickets_delete`; process actions (change approve/reject/schedule/start/review/complete/cancel; problem link/known-error/put; etc.) → `require_processes_manage`; process list/read → `require_processes_view` (or tickets:view). Keep create/edit on tickets:edit.
- **Change self-approval (MEDIUM)**: in change.py approve, reject the action if the approver's email == the ticket's raised_by/submitter (no self-approval). 
- **Audit (H3)**: call `hd_audit` (Agent 1) at every mutation here (create, status change, assign, reply, delete, merge, change approve/reject/schedule/complete) with before→after. **PII (MEDIUM)**: pass ids + changed fields, not full ticket bodies.
- Import gate helpers + hd_audit from Agent 1 by the spec names (they resolve at runtime).

## Agent 4 — Support-surface gating + mediums (owns: kb.py, settings.py, mail.py, people.py, masters.py, tags.py, views.py, agent_status.py, contacts.py, department.py)
- Apply the SoD map: KB write → require_kb_author, read → require_kb_view; masters write → require_settings_manage; settings + /config + mailbox(mail.py) → require_settings_manage (read: settings:view); people write + role grant/revoke + agent_status → require_settings_manage; tags/views → tickets:edit/view; contacts/department write → settings:manage (read: tickets:view).
- **/config gate (MEDIUM)**: ensure /config requires auth + settings:view and performs NO writes on a GET.
- **KB draft leak (MEDIUM)**: kb.list_articles (and the portal kb path) must NOT return non-published/draft articles to requesters — filter to published server-side (add a published-only param; portal + requester callers use it).
- Audit mailbox-cred changes + role grants via hd_audit.

## Agent 5 — Frontend XSS (B3) (owns: FE render files + package.json)
- Add a sanitizer dependency (`dompurify` + `@types/dompurify`, or `isomorphic-dompurify`) to grc-frontend/package.json. Create a `sanitizeHtml(html: string): string` util (grc-frontend/src/.../helpdesk or lib) and use it to sanitize ALL HTML passed to `dangerouslySetInnerHTML` in the Help Desk UI: `_ui.tsx:193`, `helpdesk/tickets/[name]/page.tsx:121,128`, the requester portal detail, and any ingested-email HTML render. Config DOMPurify to strip scripts/event-handlers/iframes. Keep legitimate formatting (b/i/p/ul/a with safe href).
- NOTE for deploy: this adds an npm dependency → the droplet needs `npm install` before `npm run build`. Flag it in the report.

## Agent 6 — Attachments persistence (functional gap) (owns: NEW attachment model + module + FE upload)
- Persist ticket/reply attachments: a `grc_hd_attachment` model (tenant_id, ticket_id, reply_id?, filename, content_type, size, storage path/key, uploaded_by, created_at), an upload endpoint (gated tickets:edit or requests:create for own tickets) with file-type allowlist + size limit + safe storage (NO path traversal — store under a tenant-scoped dir / random key, never the client filename as a path), a download endpoint (auth + ownership/tenant gated), and FE wiring in the reply composer + ticket detail to upload + list + download. Column migration via itsm_seed ADD-COLUMN/CREATE-TABLE pattern. Keep it minimal but SAFE (bank: validate type+size, no traversal, auth every read).

---

## Verification (every agent)
- Backend: `python -m py_compile` touched files; run any `__main__` self-check. Security agents (2) MUST include + pass the adversarial self-checks above.
- Frontend: `node node_modules/typescript/bin/tsc --noEmit` (junction node_modules from main checkout, delete after); zero new errors in your files.
- Report: what changed, the exact gate/helper names used, and (agents 2) the adversarial self-check output proving the exploit is blocked. No deploy, no commit.

## Email config (NOT an agent task)
Outbound/inbound email needs REAL SMTP/IMAP credentials from the owner — the
capability is built + Fernet-encrypted; it stays a no-op until a mailbox is
configured. Flag to owner; do not fake it.
