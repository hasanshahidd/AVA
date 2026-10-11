# Help Desk Parity 2 — Home, richer ticket detail, tenant-safe Settings

Branch: `feat/helpdesk-parity2` off `origin/main` (b91d8ba). Branch only — NOT deployed.

Commits:
- `f93ca62` backend: Cc/Bcc reply, saved-reply CRUD, read-only `/config`
- `9000d00` harden: isolation on the saved-reply write surface + adversarial test
- `eef52e4` frontend: Home, ticket-detail tabs + rich Cc/Bcc composer, Settings, sidebar

Verification:
- `tsc --noEmit`: **zero new errors**. The 15 errors reported are all pre-existing baseline in unrelated files (`_ui.tsx:52`, `pentest/_batch.tsx`, `vulnerabilities/*`, `components/*`). None are in any file this branch touches.
- Backend `pytest`: 16/16 pass across `test_helpdesk_config.py` (new), `test_helpdesk_analytics.py`, `test_frappe_helpdesk_adapter.py`, `test_sync_auto_ticket_cfg.py`.

---

## Feature A — Home (personal agent landing)

`grc-frontend/src/app/(dashboard)/helpdesk/home/page.tsx`, added as the FIRST Help Desk sidebar item.

- Greeting "Hey, {name}" from `/auth/me` (`display_name` → `username` → email local-part).
- "My work" stats computed client-side over `GET /helpdesk/tickets`, filtered to `agent == current-user email` (case-insensitive): **my open**, **SLA at risk**, **resolved by me**.
- List of my open tickets, newest first, each linking to the detail page (priority/status chips, SLA badge, age).
- Honest empty states: one when the current user can't be identified, one when nothing is assigned ("Nothing assigned to you yet").

No new endpoint — reuses the already-tenant-scoped `/tickets` and the existing `/auth/me`.

## Feature B — richer ticket detail

`grc-frontend/src/app/(dashboard)/helpdesk/tickets/[name]/page.tsx` + new `grc-frontend/src/app/(dashboard)/helpdesk/RichText.tsx`.

- Conversation split into **tabs: Replies / Comments / Activity**, each with a count, **default Replies**. Grouped client-side from the already-typed `conversation[]` (`received|sent` → Replies, `comment|note` → Comments, `activity` → Activity). The ticket description is folded in as the first Reply.
- **Rich-text reply composer** using **TipTap** (`@tiptap/react` + `starter-kit` + `extension-link` — all already in `package.json`, no new dependency). Toolbar: bold, italic, bullet list, numbered list, link. Produces HTML.
- Collapsible **Cc / Bcc** inputs (reply mode only).
- Internal-note mode stays a plain textarea. Switching composer mode or inserting a canned reply remounts the editor via a `key` bump to re-seed content (TipTap is otherwise uncontrolled after init); typing never remounts.
- The existing field rail (status / priority / type / team / assignee / SLA / CSAT / related finding) is unchanged and still works.

Backend: `POST /tickets/{name}/reply` now accepts optional `cc` / `bcc`, passed through to the logged Communication (public replies only; internal comments ignore them). HTML `content` already flowed through unchanged.

## Feature C — Settings (tenant-safe)

`grc-frontend/src/app/(dashboard)/helpdesk/settings/page.tsx`, added as the LAST Help Desk sidebar item.

- **EDITABLE — Saved replies**: list / create / edit / delete, backed by new CRUD endpoints. Title + TipTap rich-text body. New replies are tagged with the server-derived `ava_tenant` partition.
- **READ-ONLY — "How your Help Desk is configured"**, labeled **"Managed by your administrator"** with a lock icon: SLA targets (per-priority response/resolution), business hours, holiday calendar, and an auto-assignment status pill. No edit controls. Data from `GET /helpdesk/config`.
- Links out to the existing Agents and Teams pages (not duplicated).

---

## Isolation (per every new endpoint)

Partition is ALWAYS server-derived (`_ctx` → `_tenant_partition`, from the tenant row), never from request body/query/header.

| Endpoint | Method | Gate | Isolation |
|---|---|---|---|
| `/helpdesk/saved-replies` | GET | VIEW | read filtered by `_tenant_filters(ctx)` (appends `ava_tenant == partition`) |
| `/helpdesk/saved-replies` | POST | EDIT | new doc tagged `ava_tenant = partition` (server-derived) |
| `/helpdesk/saved-replies/{name}` | PUT | EDIT | `_saved_reply_in_tenant(ctx, name)` guard first; **404** if not in-partition |
| `/helpdesk/saved-replies/{name}` | DELETE | EDIT | same guard; **404** if not in-partition |
| `/helpdesk/config` | GET | VIEW | teams read filtered by `_tenant_filters`; SLA is global read-only (see note) |
| `/tickets/{name}/reply` (cc/bcc) | POST | EDIT | existing `_ticket_in_tenant` guard unchanged |

- `_saved_reply_in_tenant(ctx, name)` queries the target **with** the `ava_tenant` filter, so a crafted id belonging to another tenant returns no rows and is rejected. Returns **404 (not 403)** so cross-tenant existence is never confirmed. Dev / per-tenant engine (no partition) → allow, matching `_ticket_in_tenant`.
- The saved-reply **doctype existence probe** (`_canned_spec`) is itself partition-filtered, so it cannot surface another tenant's reply names.
- **Intentional global read** (`/config` SLA): HD Service Level Agreement, its priority targets, and service days are GLOBAL engine config with no `ava_tenant` field, so they can't be partition-filtered. They are shown **read-only** and never written — same category as the pre-existing `/meta` enum read. This is deliberate per the task's "display only, Managed by your administrator" requirement.
- Adversarial unit test: `test_saved_reply_guard_rejects_out_of_partition` proves the edit/delete guard accepts the owning partition, rejects a crafted cross-tenant id, rejects a nonexistent id, and allows the dev no-partition case.

## Invisible engine

Scanned the full branch diff for `frappe` / `itsm` / `servicenow` / provider / connection names in client-visible strings and API responses: **none**. The only matches are two backend developer comments/docstrings in `router.py` (not sent to the client), consistent with the existing file. Saved-reply and config API responses expose only neutral fields (title, message, owner email, policy name, priority names, times). Subjects continue to use `_subj` (HTML-unescape).

## Caveats / what was NOT built (and why)

- **Email delivery not guaranteed.** The Cc/Bcc reply only **records** the reply and its addressees on the logged Communication. Actual outbound email depends on the engine having SMTP configured, which it currently does not. Creating the Communication never fails for lack of SMTP, so the reply always logs; the Cc/Bcc fields are stored and will be used if/when SMTP is set up. Surfaced to the user as "Reply logged." rather than "Reply sent."
- **No global-config write forms.** SLA policies, business holidays, assignment rules, and email accounts are shared across tenants and are NOT `ava_tenant`-tagged. Building editable forms for them from a tenant UI would mutate shared state and break isolation, so they are display-only. Saved replies are the one genuinely per-tenant, safe-to-edit config and are the only writable Settings area.
- **`ava_tenant` on the saved-reply doctype** is assumed to exist (the existing `/canned-responses` read already filters by it and is live). If it does not exist on a given engine, create returns `ok:false` gracefully rather than crashing.

## Peer-coordinated deploy note

- Shared live prod box `143.198.176.10` runs the pentest peer's work. Do NOT deploy from here.
- **Guard rail hit + fixed:** `pentest/_batch.tsx` was reverted in this worktree by something outside this task and got swept into a commit by a broad `git add`; it was restored to `origin/main` and amended out. The branch now contains ONLY the 7 intended files — verify with `git diff --name-only origin/main..HEAD` before merging so the peer's pentest-UI fix is not clobbered.
- Deploy is backend + frontend. Backend-only changes are cheap (`git reset --hard origin/main && systemctl restart ava-backend`, ~12s). This branch includes frontend, so a merged deploy needs `NODE_OPTIONS=2048 npm run build` (~10 min, memory-heavy) in a window coordinated with the pentest peer. Main session verifies live (incl. the owner's adversarial isolation test on the new endpoints) and deploys with the owner.
