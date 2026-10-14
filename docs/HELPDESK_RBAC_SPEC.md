# Help Desk RBAC + end-user (requester) access — build spec

Make Help Desk a first-class citizen of AVA's role/permission system, with a
real **requester** (end-user) scope — so tenants can create roles that scope
Help Desk and give normal employees a simple "raise + track my own + KB" view,
NOT the full agent console. Today Help Desk is MISSING from PERMISSION_MATRIX, so
only Administrators (who bypass) can use it.

Architecture facts (verified — honor them):
- `backend/grc/permissions.py::PERMISSION_MATRIX` drives the Role Management UI
  (served via admin_router `get_permissions_matrix` → `get_permission_matrix_for_ui`).
  Adding a module is ADDITIVE; it appears in the UI with no migration.
- Permissions are created on-demand when granted (`admin_router._get_or_create_permission`);
  `grc_permissions.name` is the `module:submodule:action` string. No bulk seeding needed.
- Roles/user-roles are per-tenant (`grc_roles.tenant_id`, `grc_user_roles.tenant_id`).
- `auth_router.require_tenant_permission(name)` gates endpoints; **Administrator role +
  tenant primary_contact_email bypass ALL checks** — preserve that (don't break admins).
- HD is tenant-isolated already (open_tenant_session + tenant_id filters everywhere).
Worktree `C:/Users/HP/hd-itsm-wt` @ 2dd51cd. Local; I deploy after + coordinate shared files with the GRC-UI session.

## Permission names — THE CONTRACT (both agents use these exactly)
Add to PERMISSION_MATRIX a module `helpdesk` / display "Help Desk":
- submodule `requests` "My Requests (end user)" actions `["create","view_own"]`
- submodule `tickets` "Tickets (agent queue)" actions `["view","create","edit","delete","assign"]`
- submodule `processes` "Incidents / Problems / Changes / Service Requests" actions `["view","manage"]`
- submodule `kb` "Knowledge Base" actions `["view","author"]`
- submodule `settings` "Help Desk Settings & SLA" actions `["view","manage"]`

Resulting permission strings (what code checks): `helpdesk:requests:create`,
`helpdesk:requests:view_own`, `helpdesk:tickets:view`, `helpdesk:tickets:edit`,
`helpdesk:tickets:assign`, `helpdesk:processes:view`, `helpdesk:processes:manage`,
`helpdesk:kb:view`, `helpdesk:kb:author`, `helpdesk:settings:manage`.
(The existing `helpdesk:tickets:view` / `:edit` stay as the agent gates — already wired in common.py.)

---

## Agent 1 — backend RBAC + requester portal API
Owns: `permissions.py` (ADD the module only — additive, append one dict),
`helpdesk_native/common.py` (gate helpers), `helpdesk_native/portal.py` (NEW),
`helpdesk_native/itsm_seed.py` (preset roles), `helpdesk_native/router.py` (wire portal),
and the HD process routers ONLY to add/confirm gates. Do NOT edit admin_router or the RBAC models.

1. **permissions.py**: append the `helpdesk` module dict (above). Additive, nothing else.
2. **common.py**: keep `require_view`/`require_edit` (agent gates). ADD:
   - `require_requester = require_tenant_permission("helpdesk:requests:view_own")`
   - `require_request_create = require_tenant_permission("helpdesk:requests:create")`
   - a small `current_user_email(...)` dependency/helper (reuse auth) for the own-filter.
3. **portal.py** (NEW) — the end-user surface, prefix `/helpdesk/portal`, tenant+USER isolated:
   - `POST /helpdesk/portal/requests` (gate requests:create) → create a ticket via
     `tickets.create_ticket` with `raised_by = current_user.email`, process from body
     (default incident/service_request), department/template fields allowed. Returns id.
   - `GET /helpdesk/portal/my-requests` (gate requests:view_own) → `tickets.list_tickets`
     filtered to `raised_by == current_user.email` (add a user filter param to list_tickets
     or filter after) AND tenant. NEVER returns other users' tickets — enforce server-side.
   - `GET /helpdesk/portal/requests/{id}` (gate requests:view_own) → detail ONLY if that
     ticket's raised_by == current_user.email (else 404), tenant-scoped.
   - `POST /helpdesk/portal/requests/{id}/reply` (gate requests:create) → the requester can
     reply on their OWN ticket (guard ownership).
   - `GET /helpdesk/portal/catalog`, `GET /helpdesk/portal/templates` → reuse the service
     catalog + request-templates (so the requester form works); `GET /helpdesk/portal/kb`
     reuse kb list (gate kb:view, or open to any authenticated tenant user).
   Admins bypass (as everywhere) — fine.
4. **Gate the agent endpoints** (confirm/strengthen): the full agent lists + process
   actions + settings should require the agent/process/settings perms (view/manage), not just
   be admin-only. Keep backward-compat (admins bypass). Where a route is agent-only, use the
   existing require_view/require_edit.
5. **itsm_seed.py**: `seed_hd_roles(db, tid)` — create two per-tenant preset roles (idempotent,
   mirror admin_router.create_role's Role + RolePermission + _get_or_create_permission pattern;
   import those helpers or replicate minimally, tenant-scoped):
   - **"Help Desk Requester"**: helpdesk:requests:create, helpdesk:requests:view_own, helpdesk:kb:view.
   - **"Help Desk Agent"**: helpdesk:tickets:view/edit/assign, helpdesk:processes:view/manage,
     helpdesk:kb:view/author, helpdesk:requests:view_own, helpdesk:settings:view.
   Call from seed_itsm. Return the role ids/names.

Verify: py_compile; itsm_seed + change self-checks; full router import shows the new
`/helpdesk/portal/*` routes. Report the portal endpoints, the exact own-ticket filter, how
list_tickets got the user filter, and the preset role perms.

## Agent 2 — frontend: role-aware Help Desk + requester view
Owns: `components/layout/Sidebar.tsx` (HD group region ONLY — re-read it first, the peer just
changed it), new requester pages under `helpdesk/portal/` (or `helpdesk/my-requests/`).

1. **Sidebar HD group** — make it role-aware via the existing `requiredPermissions` mechanism
   (see how `Reports` uses it): the agent items (Dashboard/Tickets/Incidents/Problems/Changes/
   Service Requests/Agents/Customers/Contacts/KB/Canned/Settings) get `requiredPermissions:
   ['helpdesk:tickets:view']`. ADD requester items visible with `['helpdesk:requests:view_own']`
   or `['helpdesk:requests:create']`: **"Report an issue"** → the request form, **"My Requests"**
   → the requester list, **"Help / Knowledge Base"**. So a requester-only user sees just those
   three; an agent sees the full console. (Confirm the sidebar's permission-filtering supports
   OR semantics; if it's "has any", good.)
2. **Requester pages** (simple, friendly, no ITIL jargon):
   - `helpdesk/portal/report/page.tsx` (or reuse the New-Ticket form component in a simplified
     mode) → POST /grc/helpdesk/portal/requests.
   - `helpdesk/portal/my-requests/page.tsx` → GET /grc/helpdesk/portal/my-requests, show status +
     SLA ("we'll respond by…"), click into own detail + reply.
   - KB browse can reuse the existing KB page (gate kb:view).
   Reuse `_ui`/`_admin` + #005B96 styling. Keep it minimal.

Verify: `node node_modules/typescript/bin/tsc --noEmit` (junction node_modules from the main
checkout, then delete). Zero new TS errors in your files. No deploy/commit. Report the nav
changes + requester pages + endpoints consumed.

## Ownership summary
- A: permissions.py (append), common.py, portal.py (new), itsm_seed.py, router.py, process routers (gates).
- B: Sidebar.tsx (HD region), helpdesk/portal/* pages.
Shared-file heads-up: permissions.py + Sidebar.tsx are admin-adjacent — I coordinate the merge
with the GRC-UI session before deploy.
