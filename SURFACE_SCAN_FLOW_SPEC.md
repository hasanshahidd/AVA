# TASK: Add a credential-free ("Surface") scanning flow to Ava

You are working on **Ava**, a standalone cyber-only GRC product, at
`C:\Users\HP\OneDrive\Desktop\CyberAssurance`. Implement a **second, parallel
scanning flow** that needs **no credentials**, for clients who refuse to share
logins. Work **locally only** — do NOT touch the production droplet.

Read this whole spec, then explore the referenced files before writing code.
A codebase survey was already done for you — the file:line references below are
accurate as of this writing; confirm them, don't assume.

---

## 0. Context — what Ava is and how to run it locally

- **Backend:** FastAPI under `backend/grc/`. Two entrypoints: `backend/main.py`
  (prod — calls `load_dotenv()`, mounts `grc.main:app` at `/grc`) and
  `backend/grc_dev_server.py` (dev — `application` mounts the app at `/grc`).
  Local dev runs uvicorn on **:4100** serving under `/grc`
  (`python -m uvicorn grc_dev_server:application --host 127.0.0.1 --port 4100`
  from `backend/`, using the venv). Confirm the exact launch from the repo's run
  scripts, or ask the user.
- **Frontend:** Next.js under `grc-frontend/`. `grc-frontend/.env.local` has
  `BACKEND_URL=http://127.0.0.1:4100/grc`; `next.config.js` rewrites `/api/*` →
  `${BACKEND_URL}/*`. Dev: `npm run dev` (Ava uses port **3100**;
  `ava.localhost:3100`).
- **DB:** Postgres on **port 5433**, role `grc_app`. Tenant DB **`cyber_ava`**,
  catalog `cyber_master`.
- **Login:** `admin@ava.io` / `AvaDemo@123`.
- **CRITICAL DEV GOTCHA:** the project lives in **OneDrive**, which breaks Next
  HMR and uvicorn reload. After editing, **RESTART BOTH dev servers** — a
  passing typecheck does NOT mean the change is visible in the browser.
- **SCHEMA GOTCHA:** the app uses `Base.metadata.create_all` at startup, which
  only *creates missing tables* — it does NOT add new columns to an existing
  table. Any new column you add to a model needs a **manual `ALTER TABLE` run
  against `cyber_ava` (port 5433)**. Ship the ALTER statement alongside the model
  change.

---

## 1. The goal — two parallel flows

Ava today is **credential-based**:
`discovery → credentialed connect (WinRM/WMI/SSH) → adopt with deep detail →
authenticated Nessus scan (SMB + creds)`.

Add a **credential-free ("Surface") flow** for clients who won't share creds:
1. **Discovery already runs without credentials** (a network sweep: finds a
   device exists, its open ports, a rough type/fingerprint — no login).
2. **Adopt those surface devices directly into inventory** — no credentialed
   connect, self-service, at scale. The operator/client picks which discovered
   devices to bring in.
3. **Vulnerability scan on the surface only** — an **unauthenticated** Nessus
   scan (no creds) that finds externally-visible issues (exposed service
   versions, default creds, missing TLS, etc.).

Both flows must coexist. The Surface flow is **additive** — do NOT break or
regress the credential-based flow.

---

## 2. CRITICAL — what ALREADY EXISTS (do NOT rebuild)

The survey found the credential-free plumbing is already there end-to-end. Reuse
it; do not reinvent.

**(a) Unauthenticated Nessus scan already works.**
- `backend/grc/modules/integrations/router.py:537` `trigger_hosted_scan`
  (`POST /connections/{connection_id}/scan-and-sync`). Body
  `HostedScanRequest.credential_profile_ids: Optional[List[int]] = None`
  (`router.py:458`, comment **"Empty = unauthenticated"**). With no cred ids the
  scan is still created (`:597`) and launched (`:615`).
- `hosted_scan.py:117` `_resolve_credentials` returns `None` when nothing usable
  "so the scan stays unauthenticated".
- `adapters/nessus_adapter.py:799` `_nessus_credentials` returns `None` when
  empty; `_scan_body` (`:853`) only adds `body["credentials"]` when non-empty;
  `create_scan` (`:970`): *"when absent it behaves as an unauthenticated network
  scan."*
- **So the Surface scan is a UI toggle over existing backend**, not new scanning
  code. Findings sync + per-asset link via `SyncService.run_full_sync`
  (`hosted_scan.py:338`, scoped to the run's hosts) and
  `services/finding_asset_linker.py:273` `backfill_host_links`.

**(b) Adopt-without-credentials already creates an inventory asset.**
- Frontend `grc-frontend/src/lib/api.ts:949` `discoveryApi.resolve(obsId,
  'adopt')` → `POST /discovery/observations/{id}/resolve`.
- `asset_discovery/router.py:1991` → `resolver.manual_adopt`
  (`services/resolver.py:448`) → `_create_from` (`:276`) creates a full
  `ITAsset` with **no credentials, no deep-collect**, sets
  `discovery_state="unmanaged"` (evidence-only). Stamps `ip_address`,
  `host_name`, `fqdn`, `primary_mac`, plus `vendor`/`manufacturer`/`os_family`/
  `asset_role`/`platform_properties.discovery_classification` via
  `_apply_classification` (`:243`). `origin_source` = `easm`|`network_sweep`.
- **So surface-asset onboarding largely exists** — you mostly need to make it a
  first-class, bulk, self-service UI action.

---

## 3. What is ACTUALLY new (the real work)

### A. Persist surface facts onto the asset  *(backend, small)*
Adopt does NOT currently store `open_ports` or a top-level `device_type` on the
asset — `device_type` only lives inside `platform_properties.discovery_
classification`, and `open_ports` stays on the discovery observation's `raw`. For
a **surface** asset, ports + type are the primary value, so make them
first-class:
- Model `backend/grc/models/_14_it_asset_inventory.py` (`class ITAsset` →
  `grc_it_assets`). Add `open_ports` (JSON / int array) and, if you want it
  queryable, a `device_type` column (else read it from
  `platform_properties.discovery_classification.device_type`).
- In `resolver._create_from` / `manual_adopt`, copy the observation's
  `raw.open_ports` and `device_type` onto the asset.
- **Ship the `ALTER TABLE grc_it_assets ADD COLUMN ...` for `cyber_ava`** (schema
  gotcha above).

### B. Mark surface vs credentialed on findings  *(backend, small — a real gap)*
There is **no persisted authenticated/unauthenticated flag on findings**. The
live signal exists only during polling (`integrations/router.py:516`
`"authenticated": bool(h.get("credential"))`) and is never stored.
- Add a flag to persist it — e.g. `scan_mode` ('surface' | 'credentialed') or
  `authenticated: bool` on `Vulnerability`
  (`backend/grc/models/_22_vulnerability_management_module.py:53` →
  `grc_vulnerabilities`) and/or on the `HostedScanRun`. Set it from whether the
  scan ran with credentials (empty `credential_profile_ids` → surface). Populate
  at sync time. Ship the ALTER.

### C. Surface flow in the UI  *(frontend — the bulk of the work)*
- **Asset discovery** (`grc-frontend/src/app/(dashboard)/asset-discovery/
  page.tsx`): a clear, promoted **"Adopt as surface asset (no credentials)"**
  action — **bulk-adopt** the real discovered devices (exclude
  `device_type === 'firewall_echo'`) straight into inventory. (Adopt exists via
  `discoveryApi.resolve(id,'adopt')`; a bulk loop already exists as `runAdopt` in
  the connect queue — promote it to a first-class, self-service surface path.)
- **Scan flow** (`grc-frontend/src/app/(dashboard)/scan-flows/hosted/page.tsx`):
  add a **"Surface scan (no credentials)"** mode that triggers the hosted scan
  with `credential_profile_ids = null`/empty. Present it clearly next to the
  credentialed scan.
- **IT Asset Inventory** (`grc-frontend/src/app/(dashboard)/assets/page.tsx` +
  `assets/[id]/page.tsx`; API `backend/grc/routers/assets_router.py`):
  - Badge each asset **"Surface / Agentless"** vs **"Managed / Credentialed"**.
    Derive it from `discovery_state` (`'unmanaged'` = surface) + whether
    `os_family` is populated (`assets_router.py:1090` already computes
    `"profiled": bool(asset.os_family)`).
  - Show surface fields (IP / MAC / open ports / type / vendor); mark deep fields
    (installed software, patches) as **"requires credentials — not collected."**
  - Add a filter: **Managed vs Surface**.
  - On the asset detail, distinguish **surface** findings from **authenticated**
    findings (using the new flag from B).
- **Vulnerabilities** (`grc-frontend/src/app/(dashboard)/vulnerabilities/
  page.tsx` + `[id]/page.tsx`): show a **"Surface / Unauthenticated"** badge on
  surface findings; optionally a filter.

### D. Make the two flows legible  *(product / UX)*
Present the two paths clearly so an operator/client understands the choice:
**"Credential-based (deep)"** vs **"Surface (no credentials)"** — e.g. a
top-level choice on the scan-flows hub (`scan-flows/page.tsx`).

---

## 4. File / folder map (verified survey)

**Discovery / adopt**
- `backend/grc/modules/asset_discovery/router.py` — `resolve_observation_endpoint`
  (`:1991`), `ResolveIn` (`:700`, action `^(adopt|merge|ignore)$`).
- `backend/grc/modules/asset_discovery/services/resolver.py` — `manual_adopt`
  (`:448`), `_create_from` (`:276`), `_apply_classification` (`:243`),
  `manual_ignore` (`:472`), auto-resolver `resolve_observation` (`:358`).
- Discovery sweep/classify (for reference): `services/executor.py`,
  `services/fingerprint.py` (`classify`), `services/deep_collect.py`.

**Inventory**
- Model `backend/grc/models/_14_it_asset_inventory.py` (`ITAsset` →
  `grc_it_assets`): `origin_source` (`:113`), `discovery_state` (`:232`:
  discovered|managed|unmanaged|NULL), `source_system` (`:228`), `primary_mac`
  (`:226`), `fqdn` (`:225`), `known_ips` (`:26`), `serial_number` (`:212`),
  `os_family` (`:127`), `platform_kind`/`platform_properties` (`:249`),
  `detected_software_json` (`:140`), `status` (`:38`), `lifecycle_state` (`:85`).
  NO `is_managed`/`agentless`/`has_credentials`/`open_ports` column exists.
- Inventory API: `backend/grc/routers/assets_router.py` (note: a router, not
  under `modules/`). `"profiled": bool(asset.os_family)` at `:1090`.
- Frontend: `grc-frontend/src/app/(dashboard)/assets/page.tsx` (+ `[id]/page.tsx`).

**Nessus hosted scan**
- `backend/grc/modules/integrations/router.py` — `trigger_hosted_scan` (`:537`),
  `HostedScanRequest` (`:451`), `_nessus_live_detail` (`:487`, `authenticated`
  at `:516`).
- `backend/grc/modules/integrations/services/hosted_scan.py` —
  `_resolve_credentials` (`:117`), `run_hosted_scan` (`:165`), sync call (`:338`).
- `backend/grc/modules/integrations/adapters/nessus_adapter.py` —
  `_nessus_credentials` (`:799`), `_scan_body` (`:853`), `create_scan` (`:970`).
- Frontend: `grc-frontend/src/app/(dashboard)/scan-flows/hosted/page.tsx`
  (+ hub `scan-flows/page.tsx`, credentialed `scan-flows/connect/page.tsx`).

**Vulnerabilities**
- Model `backend/grc/models/_22_vulnerability_management_module.py` (`Vulnerability`
  → `grc_vulnerabilities`): `host_identity` JSON (`:98`, what the linker matches),
  `affected_host` (`:90`), `affected_port` (`:99`), `connection_id` (`:248`),
  `source` (`:249`), `scanner_status` (`:255`).
- Link table `backend/grc/models/_23_track_a_phase_7_cloud_connector_framework_
  foundation.py` (`VulnerabilityAssetLink` → `grc_vulnerability_asset_links`):
  `link_source` (`:125`), `auto_linked` (`:129`).
- Linker: `backend/grc/services/finding_asset_linker.py` — `backfill_host_links`
  (`:273`), `_match` (`:164`), `_match_by_identity` (`:186`).
- Frontend: `grc-frontend/src/app/(dashboard)/vulnerabilities/page.tsx`
  (+ `[id]/page.tsx`).

---

## 5. Constraints
- **LOCAL ONLY.** Do not touch the DigitalOcean droplet / prod.
- Do NOT break the credential-based flow — the Surface flow is additive.
- **Reuse** the existing unauthenticated-scan path and adopt path; don't rebuild.
- New columns → **manual `ALTER TABLE` on `cyber_ava` (:5433)** (create_all won't
  add them). Provide the SQL.
- Keep per-asset finding linking intact — surface findings must attach to the
  right surface asset.
- **Restart both dev servers after edits** (OneDrive breaks HMR); verify in the
  browser, not just via typecheck.
- Match the surrounding code's style; the discovery frontend recently gained a
  `firewall_echo` device_type — exclude those from surface adoption.

---

## 6. Acceptance criteria
1. Discover a subnet with **no credentials** → **bulk-adopt** the real devices
   (excluding `firewall_echo`) into inventory in one action → they appear as
   **Surface** assets with IP / MAC / open ports / type / vendor.
2. Run a **Surface (unauthenticated) Nessus scan** against those assets →
   findings appear, **linked per-asset**, badged **"Surface / Unauthenticated."**
3. Inventory clearly distinguishes **Surface** vs **Managed/Credentialed** assets
   and findings, and can filter by it.
4. The existing **credential-based** flow still works unchanged.
5. Each non-trivial backend change leaves one runnable check (an assert-based
   `__main__` self-check or a small `test_*.py`).

---

## 7. Suggested order of work
1. Backend A + B (columns + adopt persistence + finding flag + ALTERs) — small,
   unblocks the UI.
2. Frontend C: inventory badges + filter + surface fields (the asset screen).
3. Frontend C: bulk "Adopt as surface" on discovery.
4. Frontend C: "Surface scan" mode on scan-flows/hosted.
5. Frontend D: the two-flow choice on the scan-flows hub.
6. Verify all 6 acceptance criteria in the browser (restart servers first).
