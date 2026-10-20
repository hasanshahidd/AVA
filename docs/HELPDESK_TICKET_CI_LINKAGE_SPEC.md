# Help Desk tickets ↔ CMDB CIs (phase 2 of the inventory linkage)

Chain being completed: **AVA inventory → CMDB CI → ticket (incident / problem / change / service
request)**. Phase 1 (`HELPDESK_CMDB_INVENTORY_SYNC_SPEC.md`) mirrors inventory into CIs. Today
`HDTicket.ci_id` and `HDTicket.business_service_id` exist (models/_60) but nothing sets or reads
them. This phase makes tickets point at the CI they affect and lets the CI's real exposure drive
governance.

Worktree `C:/Users/HP/hd-itsm-wt` only; don't restart the shared :4101 (use a temp port);
don't commit; leave other uncommitted work intact.

## Backend

1. **Set the affected CI** on tickets:
   - Agent create (`router.py` `TicketCreate`) and update (`/tickets/{name}/update`) accept
     `ci_id` (and `business_service_id`). Add both to `tickets._EXT_FIELDS`-style handling so
     create/update persist them.
   - Validation: CI must exist in this tenant and not be `retired` (400 otherwise). If the CI has a
     `business_service_id` and the ticket has none, inherit it.
   - Portal (requesters) does NOT pick CIs — agents set it at triage (requesters don't know CIs).
2. **Expose it**: ticket list rows + detail carry `ci: {id, code, name, ci_type, ci_kind,
   exposure, pci, internet_facing, managed_by_inventory, ava_asset_id}` (null when unset) and
   `business_service: {id, name}`. Batch-load for lists (no N+1).
3. **CI → tickets**: `GET /helpdesk/admin/cmdb/cis/{id}/tickets` (settings_view) → tickets whose
   `ci_id` is this CI **or any CI contained in it** (domain → its endpoints, host → its software),
   newest first, with process/status/priority/subject. This is the impact view.
4. **Exposure-aware change governance** (`approvals.requirements_for_change`): if the change's CI
   (or, for a domain CI, any endpoint under it) is `pci` or `internet_facing`, a change type that
   would auto-approve (Standard) is **escalated to CAB** and the decision records why
   (e.g. approval `reason`/note "CAB required: CI is internet-facing + PCI"). Normal/Major/Emergency
   unchanged. Read these flags from the CI's `attributes.ava` (phase 1 fields) — a manual CI with
   no `ava` never escalates.
5. Tests: create/update with ci_id (valid, cross-tenant 400, retired 400), business service
   inheritance, list/detail payload, CI→tickets incl. children, standard change on an
   internet-facing/PCI CI → CAB with reason, standard change on a plain CI → still auto-approves.
   Live check on a temp port against tenant `ava` (read-only checks + create/delete one test
   ticket tagged `[E2E]`, cleaned up after).

## Frontend

1. `_newticket.tsx` (agent new-ticket form) + ticket detail (`tickets/[name]/page.tsx`):
   an **Affected CI** picker — searchable (name/code), tree-aware (domain → endpoint, host →
   software), each option showing type + badges (External/Internal, PCI, Internet-facing).
   Detail page shows a CI card (name, type, badges, "Open in CMDB", "Open in inventory"
   `/assets/{ava_asset_id}` when linked) and lets agents change/clear it.
2. Change pages (`changes/page.tsx`, `changes/_actions.tsx`): when a Standard change was
   escalated, show the reason ("CAB required: CI is internet-facing").
3. CMDB CI modal (`helpdesk/admin/cmdb/page.tsx`): **Related tickets** section from
   `GET /cis/{id}/tickets` (process badge, status, subject, link to the ticket).
4. tsc + eslint clean on touched files; null-safe when `ci` is null.
