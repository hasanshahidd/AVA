# Help Desk CMDB ← AVA Inventory sync (production spec)

Owner goal: the Help Desk CMDB mirrors **only the real AVA inventory** (never mock data, never
pentest ad-hoc noise), carrying the inventory's rich signals (EASM / credentialed /
uncredentialed category, PCI/regulated scope, exposure, OS, hardware, security posture,
installed software) so ITSM (incidents, changes, CAB) can use them.

Worktree: `C:/Users/HP/hd-itsm-wt` (branch `feat/helpdesk-itsm`). Never touch the main
CyberAssurance checkout. The shared dev backend on :4101 is used by another session — do
NOT restart it; use a temp port (e.g. 4199) for live checks.

## 1. Source of truth = the real inventory

- Read-only on `grc_it_assets` (`ITAsset`). No schema change to asset tables. Do not edit
  `grc/routers/assets_router.py` (owned by another session) — import its helpers lazily.
- **Inventory scope = the shared helper `inventory_assets_only()`** from
  `grc/modules/vuln_management/_adhoc_filter.py` (already in this worktree) — the SAME predicate
  `GET /assets`, estate_overview and license_management use (drops only the transient
  AI-pentest ad-hoc rows: `status='adhoc'` / `last_seen_source='pentest-adhoc'`). Import it;
  never re-implement it. Confirmed with the inventory/discovery session (2026-10-19):
  tenant `ava` = 249 rows − 4 ad-hoc = **245 inventory rows**; the 243 EASM externals ARE real
  inventory (the earlier "243 is wrong" was a dashboard flat-subdomain counting bug).
- **Exposure** (EASM vs Internal, what the register shows): external =
  `internet_facing OR is_internet_facing`; internal = the rest. `ava`: 243 external, 2 internal
  (`DESKTOP-EQ55Q8H`, `DESKTOP-CE3EFJB`). `origin_source` is provenance only.
- **Scan category** = `assets_router._scan_mode(asset)` (lazy import; single source of truth):
  `easm | credential | uncredential`, `None` → `"manual"`. Never re-derive it.
- **Apex roll-up** = the inventory session's pure module
  `C:/Users/HP/ava-main-wt/backend/grc/modules/it_assets/asset_rollup.py` (unmerged there).
  Vendor it **byte-for-byte** to the same path in this worktree
  (`backend/grc/modules/it_assets/asset_rollup.py`) and import `registrable_domain` /
  `external_unit_key` from it, so CMDB grouping matches the register by construction and the
  branches merge without conflict. Do not modify the vendored file.

## 2. CI type mapping (single dict/function, unit-tested; first match wins)

1. `platform_kind`: server→CIT-SERVER, database→CIT-DBINST, network→CIT-NETDEV,
   cloud→CIT-CLOUDSVC, cluster→CIT-K8S, identity→CIT-APP
2. `asset_role == 'application'` → CIT-APP
3. `asset_type`: web→CIT-WEBSVC, cloud→CIT-CLOUDSVC, application→CIT-APP, data→CIT-DBINST
4. `os_family` set: Windows client editions (10/11, Pro/Home/Enterprise client) → CIT-WORKSTATION,
   macos → CIT-WORKSTATION, otherwise → CIT-SERVER
5. category `easm` with no other signal → CIT-WEBSVC
6. fallback → CIT-SERVER
Resolve codes to ids per tenant; a missing CI type is a reported skip, never a crash.

## 2b. Granularity (owner-delegated decision: logically correct + best for users)

- **Internal** assets → one CI each (flat).
- **External** assets → grouped by `external_unit_key(name, asset_id)`:
  - Each apex group gets ONE **domain CI** (type CIT-WEBSVC). If an inventory row whose name
    equals the apex exists, that row's CI IS the domain CI (`ava_asset_id` = that row). Otherwise
    create a synthetic domain CI: `code = f"AVA-DOM-{apex}"`, `ava_asset_id = NULL`,
    `attributes.ava.kind = "domain"`.
  - Every other row in the group → its own **endpoint CI** (per §2/§3, one per row), linked
    **domain —REL-CONTAINS→ endpoint** ("Contains" / "Part of"). Rationale: each subdomain is
    a distinct internet-facing endpoint (aliases are already collapsed in inventory) so tickets
    must be able to target it, while the domain CI gives the same grouping the register shows.
  - Non-groupable externals (bare IP / single-label → key `id:<n>`) → standalone CI.
  - Domain CI `attributes.ava.domain = {apex, endpoint_count, member_asset_ids}`.
  - A synthetic domain CI with zero members after a run → retired.
- Expected for `ava`: 3 domain CIs (superior.edu.pk, liztek.ca, testfire.net), ~240 endpoint
  CIs, 2 internal host CIs, + installed-software CIs for the 2 internal hosts.

## 3. Host / endpoint CI (one per inventory asset, keyed by `ava_asset_id`)

- `code = f"AVA-{asset.id}"`, `name = asset.name`, `ci_type_id` per §2, `ava_asset_id = asset.id`.
- `status`: inventory `status`/`lifecycle_state` decommissioned/retired → `retired`, else `in_use`.
- `criticality = asset.criticality` (may be None — never fabricate; the model deliberately has
  no default). `environment = asset.environment` (None if unset; do not infer).
- `owner`: owning team name (owning_team_obj / owning_team) → primary owner display → owner_name.
- `attributes`: preserve any user-entered top-level keys; fill the CI type's defined attribute
  names where an inventory value maps (hostname←host_name/fqdn, ip_address, serial_number,
  os/os_version, manufacturer, model, environment…); put the full mirror under the reserved
  `"ava"` key (sync owns it, overwrites it each run):
  ```
  ava: { asset_id, asset_url:"/assets/{id}", synced_at,
         source:{category, origin_source, last_seen_source, last_seen_at, first_seen_at,
                 discovery_state, credentialed:bool},
         network:{fqdn, ip_address, known_ips, dns_aliases, primary_mac, network_segment,
                  internet_facing:bool},
         os:{family, version, normalized, build, edition},
         hardware:{cpu_cores, memory_gb, storage_gb, manufacturer, model, serial_number},
         compliance:{pci:bool, regulated_data_type, cde_environment, ephi_environment,
                     compliance_scope, data_classification},
         security_posture:{…as stored…},
         platform:{kind, properties} }
  ```
  `credentialed = category == 'credential'`; `internet_facing = is_internet_facing or internet_facing`;
  `pci = regulated_data_type in ('pci','multiple') or cde_environment or 'PCI-DSS' in compliance_scope`.
- Inventory is source of truth for: name, ci_type, status, criticality, environment, owner,
  `attributes.ava`. User-owned and preserved: `business_service_id`, other attribute keys.

## 4. Installed software (child CIs + edges)

- Ensure CI type `CIT-SOFTWARE` "Installed Software" exists (idempotent ensure; standard
  scaffolding, not mock data).
- Each `detected_software_json` entry without `promoted_asset_id` → CI
  `code = f"AVA-SW-{asset.id}-{software_key}"` (truncate safely), name = software name,
  type CIT-SOFTWARE, attributes `{version, publisher, source, software_key,
  benchmark_available, ava:{host_asset_id, synced_at}}`, plus edge
  **software —REL-INSTALLED→ host** ("Installed on").
- Promoted software (`promoted_asset_id` set) is itself an inventory asset → its own host-style
  CI; add edge **app —REL-RUNSON→ parent host** (via `parent_asset_id`). No duplicate software CI.
- Software no longer detected on re-sync → software CI `retired`, its REL-INSTALLED edge removed.

## 5. Retire, idempotency, safety

- Linked CIs whose asset left inventory scope → `status='retired'` (never hard-delete; tickets
  may reference them); their software children retired too. Asset reappears → restored.
- Upsert by `ava_asset_id` (host) / `code` (software). Second run with no inventory change →
  0 created, 0 updated (compare before writing; touch `synced_at` only when something changed).
- One transaction per tenant run; any exception rolls back the whole run.
- Edges via the existing unique (source, target, rel_type) constraint — check before insert.
- Tenant-scoped everywhere (`tenant_id(db)`); never read/write another tenant.
- Audit via `hd_audit(..., action="cmdb.inventory_sync")`; record the run in
  `grc_hd_import_batch` (kind/source = inventory_sync) with the summary for sync-status.

## 6. API (router prefix `/helpdesk/admin/cmdb`)

- `POST /sync-from-inventory?dry_run=true|false` (require_settings_manage) →
  ```
  { dry_run, inventory_count, created, updated, unchanged, retired, restored,
    software_created, software_updated, software_retired,
    relationships_created, relationships_removed,
    by_category:{easm, credential, uncredential, manual},
    by_ci_type:{ "<CI type name>": n },
    skipped:[{asset_id, name, reason}],
    sample:[{action:"create|update|retire", asset_id, name, ci_type, category}] (≤50),
    finished_at }
  ```
  Dry run = identical computation, no writes.
- `GET /sync-status` (require_settings_view) →
  `{ last_run_at, last_summary, inventory_count, linked_ci_count, retired_ci_count }`
- `GET /cis` rows additionally carry derived `source_category`, `exposure`
  (`external|internal|null`), `credentialed`, `pci`, `internet_facing`, `managed_by_inventory`
  (bool = `attributes.ava` present), `ci_kind` (`domain|endpoint|host|software|null`),
  `parent_ci_id` (the REL-CONTAINS / REL-INSTALLED parent, if any) and `child_count`.
- `GET /cis` filters: `source_category=easm|credential|uncredential|manual|none`,
  `exposure=external|internal`, `top_level=true` (only CIs with no containing parent —
  the default view the UI uses to show domains + internal hosts, expandable).
- Summary also carries `by_exposure: {external_domains, external_endpoints, internal}`.
- `GET /cis/{id}/software` → installed-software children (via REL-INSTALLED) for a host CI.

## 7. Auto-sync

Celery beat task (e.g. `helpdesk.cmdb_inventory_sync`, every 6h) iterating tenants the same way
existing per-tenant beat tasks do. Non-fatal per tenant; skip tenants without ITSM tables.

## 8. Frontend (CMDB → Configuration Items tab)

- "Linked to AVA inventory" card: last sync time, inventory count, linked CIs, retired; buttons
  **Preview sync** (dry run → modal with counts by action / category / CI type + skipped) and
  **Sync now** (confirm inside the modal → run → success banner → reload list).
- Table is a **tree**: default `top_level=true` shows domain CIs + internal hosts (+ manual CIs);
  a domain row expands to its endpoint CIs (lazy-load `GET /cis?parent...` or filter client-side
  by `parent_ci_id`), showing "N endpoints". Badges: exposure (External / Internal), category
  (EASM / Credentialed / Uncredentialed / Manual), PCI, Internet-facing; "open in inventory"
  link to the AVA asset page for linked CIs.
- Filters: exposure (All / External / Internal), category (All / EASM / Credentialed /
  Uncredentialed / Manual / Not from inventory), plus the existing CI-type filter + search.
- CI modal for a linked CI: read-only "From AVA inventory" panel (source, OS, IP, posture,
  compliance) + installed software list; inventory-owned fields shown read-only with
  "Managed by inventory sync — edit it in AVA inventory". Keep the AI-enrich feature working
  for non-linked CIs.

## 9. Verification (mandatory)

- pytest: mapping waterfall; scope excludes adhoc / pentest-adhoc; idempotent 2nd run; retire +
  restore; software child + edge + removal; PCI derivation; dry run writes nothing.
- Live: dry run against tenant `ava` on a temp port — report counts by category/type.
  Do NOT run a non-dry sync on `ava`; the orchestrator runs it after the inventory fix lands.
