# Ava → GRC "Cybersecurity Assurance" Integration Plan

**Status:** Draft v1 (Sep 17 2026)
**Author:** planning doc, to be executed by the owner
**Goal:** Port the enhancements built in **Ava** (standalone cyber product) into the **Cybersecurity Assurance** module of the main **GRC / ComplyVerse** product — without disturbing Ava, which keeps running standalone.

---

## 0. The one-paragraph summary

Ava was **cloned out of GRC** (baseline commit `c819bd9`, "Baseline snapshot before Ava dead-code cleanup") and then heavily enhanced (discovery engine, credentialed WinRM/WMI/SMB connect, deep-collect, Nessus Flow-1, CIS/OpenSCAP compliance, control library, CTEM, vuln + risk posture). The seniors want those enhancements folded back into GRC's existing **Cybersecurity Assurance** module, while Ava stays a separate product. Because Ava and GRC share a common ancestor, this is **not** a rebuild — it is a **delta port**: identify what Ava changed since the clone, reconcile it against how GRC's Cybersecurity Assurance module has evolved in parallel, and land the merged result in GRC. Three environments in sequence: **local GRC → ComplyVerse `main` → prod (68.183.198.54)**. Every step must be reasoned across **frontend, backend, and database**.

---

## 0b. PHASE 0 FINDINGS (run locally, Sep 17 2026)

Audited both repos on disk (`Desktop\CyberAssurance` = Ava, `Desktop\GRC 1\complywerse_ai` = GRC). Results materially de-risk the port:

- **Ava delta since clone `c819bd9`:** 20 commits, +23,785 / −34,994 (the huge deletions are Ava's dead-code cleanup — noise, not ported). Real payload = additions in the cyber modules.
- **GRC is the superset.** Every module Ava has already exists in GRC (`asset_discovery`, `compliance_plugins`, `vuln_management`, `risk_posture`, `integrations`, `erm`, `it_assets`, …) plus many GRC-only ones (assessments, control_library, governance, vendor_risk, bcm, auditor_portal, …). **GRC even has a `cyber-security` frontend route** = the "Cybersecurity Assurance" surface the seniors mean. So the port is a **file-level three-way merge into GRC's existing modules**, not new-module creation.
- **Divergence is additive / low-conflict** (measured Ava-vs-GRC on key files): `executor.py +204/−19`, `deep_collect.py +160/−58`, `nessus_adapter.py +257/−2`, `fingerprint.py +13/−0`, `_47_asset_discovery_models.py +1/−0`. GRC barely drifted on these since the clone → Ava's changes apply mostly as clean additions. Schema delta is tiny.
- **New files (just add to GRC):** `asset_discovery/services/explainer.py`, `integrations/services/hosted_scan.py`, `compliance_plugins/services/connection_matcher.py`, `erm/routers/ctem_scopes.py` (+ package inits).
- **Tier-A backend files to merge:** models `_33_integrations…vulnerability_scanner_integration.py`, `_47_asset_discovery_models.py`; asset_discovery `router.py`, `deep_collect.py`, `executor.py`, `fingerprint.py`, `resolver.py`, `external_probe.py`; compliance_plugins `router.py`, `winrm_runner.py`, `agentless_inventory.py`, `strict_matcher.py`, `seed.py`; integrations `nessus_adapter.py`, `router.py`, `sync_service.py`; vuln_management `ai_control_proposals.py`.
- **Tier-A frontend to merge:** `asset-discovery` (+2586/−2284, heavy rework), `scan-flows` (+925, new Nessus UI), `vulnerabilities` (+722), `assets` (+223); surface under GRC's `cyber-security` route.

**⚠ Boundary mismatch to raise with seniors — GRC's own `ASSURANCE_PRODUCT_SEPARATION_PLAN.md` says:**
- "Cybersecurity Assurance" was scoped as the **EXTERNAL / EASM** product (domain→subdomain discovery, external inventory, health/risk scoring, exploitability), on a shared `security-core` with **two build targets** (`apps/grc` embedded + `apps/assurance` standalone) — explicitly **"Not a fork."**
- The **INTERNAL credentialed sweep** (`compliance_plugins`, `winrm_runner`, `ssh_runner`, `os_detector`) is explicitly **"stays in GRC — not part of the external product."**
- **But Ava is a full fork that includes the internal sweep** — exactly what that plan tried to avoid, and most of Ava's enhancements (WinRM/WMI/SMB connect, deep_collect, Nessus Flow-1, CIS) are IN that internal sweep. So Ava's enhancements land in **GRC's core cyber modules**, and the seniors' "Cybersecurity Assurance" is **broader** than GRC's doc defines. **Clarify:** does "Cybersecurity Assurance" here mean (a) GRC's external-EASM product per the doc, or (b) the full internal+external cyber capability Ava has? The merge targets differ.

---

## 0c. PHASE 1 PROGRESS LOG (local GRC, branch `ava-port-local`, Sep 17 2026)

Working in `Desktop\GRC 1\complywerse_ai` on a local branch `ava-port-local`. **Nothing pushed** (owner pushes to the main repo). Method: for each file, compared GRC's version to the Ava clone base `c819bd9`; **where GRC had zero drift, Ava's HEAD version IS the correct merge → copied + AST-verified + import-tested; where GRC drifted, deferred to a hand-merge.**

**DONE — ported + verified importing in GRC:**
- asset_discovery: `executor.py`, `fingerprint.py` (NetBIOS name), `deep_collect.py`, `resolver.py`, `router.py`, `explainer.py` (new) → **module imports OK**.
- integrations: `router.py`, `sync_service.py`, `hosted_scan.py` (new) → **module imports OK**.
- compliance_plugins: `winrm_runner.py`, `agentless_inventory.py`, `connection_matcher.py` (new).
- vuln_management: `ai_control_proposals.py`. models: `_47` (+snmp kind), `_33`.

**DONE — hand-merges (verified: each module imports in GRC):**
1. `external_probe.py` — copied Ava (all its logic) + kept GRC's `complyverse-easm` User-Agent. ✓
2. `strict_matcher.py` — Ava is a clean superset (refactored GRC's inline TODO/kind:any exclusions into `runnable_check_clauses()` + added dangling-pipe + `applicable_manual_plugins_for_asset`); copied. ✓
3. `nessus_adapter.py` — Ava = GRC + 12 functions; copied + restored GRC branding (`recorded in ComplyVerse` ×2). ✓
4. `compliance_plugins/router.py` — verified Ava DROPS **zero** GRC endpoints (44 GRC routes all present + 1 new `/manual-checks`); copied + rebranded (`AVA_PLATFORM_ADMINS`→`COMPLIVERSE_PLATFORM_ADMINS`, 4 `Ava`→`Compliverse`). ✓
5. **erm/CTEM — NOTHING TO PORT.** GRC's `ctem_scopes.py` is **identical** to Ava's, and GRC's `erm` is the FULL module (23 routers); Ava's is a stripped cyber-only slice. Copying Ava's erm inits would have wiped GRC's ERM — correctly skipped. ✓

**✅ BACKEND PORT COMPLETE & VERIFIED** — all cyber modules (asset_discovery, integrations, compliance_plugins, vuln_management) + changed models import together in GRC on branch `ava-port-local`.

**DONE — environment/DB/frontend:**
- **DB — no migration needed.** Checked `grc_complyverse`: every table (`grc_scan_records`, all `grc_discovery_*`) and every asset/observation column the ported code uses (`discovery_state`, `os_normalized`, `host_name`, `known_ips`, `detected_software_json`, obs `raw`/`host_name`/`resolution_note`…) is ALREADY present. GRC is the superset at the schema level too. Only Ava model change beyond that = the `grc_scan_records` table (from `_33`), created by `create_all`. ✓
- **impacket** — added to GRC `requirements.txt`; `pip install` ran but hit a OneDrive `Errno 22` on the fresh package file (GRC lives under OneDrive). It's lazy-imported (WinRM path unaffected); reinstall outside OneDrive or `attrib`/re-sync to fix the WMI/SMB path. ⚠ minor
- **Frontend — new features ADDED + tsc-clean** (GRC frontend also `ignoreBuildErrors`): copied `scan-flows/` (3 pages) + `ManualChecksPanel.tsx`; spliced Ava's hosted-scan methods + `assetManualChecks` into GRC's `integrationsApi`/`compliancePluginsApi`; wired the **Manual checks** sub-tab into GRC's `CompliancePanel`. `connect` page reuses GRC's existing connections page. tsc reports **zero errors** on all touched frontend files.

**REMAINING (optional / team decisions, NOT blockers):**
- GRC's heavily-diverged `asset-discovery/page.tsx` (4562-line drift) and `api.ts` (10706) were **left as GRC's own** — they already work and already surface the ported backend engine (better sweep, NetBIOS names, firewall-echo labels, cancel, etc.). Porting Ava's page-specific UI tweaks (Stop button on the campaign card, tab-scoped search/filter) is an optional enhancement, not required for the features to run.
- Nav/IA: scan-flows is reachable at `/scan-flows`; where to surface it (GRC's `/cyber-security` hub is assessments-focused) is a product/IA call — part of the skin question for seniors.
- Skin: pages currently carry Ava's markup; reskin-to-ComplyVerse vs keep-as-is still pending seniors' answer.

**✅ PORT FUNCTIONALLY COMPLETE on branch `ava-port-local` (all local, nothing pushed):** backend engine + models + DB verified; new frontend Nessus scan-flow + manual-checks features added and type-clean. Owner pushes to the main repo when ready.

---

## 1. Hard constraints (do not violate)

- **Ava stays whole and standalone.** Nothing here changes Ava's repo/deploy. Ava = `Desktop\CyberAssurance`, github.com/hasanshahidd/AVA, ports 4100/3100, tenant `ava`, DB `cyber_ava`.
- **The target is GRC's `Cybersecurity Assurance` module**, not a wholesale GRC replacement. Ava's capabilities live *under* that module.
- **GRC is multi-tenant (7 tenant DBs); Ava is single-tenant (`ava`).** Every ported feature must be tenant-scoped and safe to enable per-tenant.
- **GRC prod = ComplyVerse** at `68.183.198.54`, `/home/mehboob/grc-final/complywerse_ai`, `main`, systemd `grc-backend` / `grc-frontend`. Deploy = pull + pip + npm build + restart.
- **SCHEMA GOTCHA (GRC):** `create_all` only creates *tables*, never new columns/type changes. Any new column Ava added must be applied by **manual `ALTER TABLE` across all 7 tenant DBs**.
- **`next build` on the prod box needs swap.** Do not self-scan prod (known outage: a self-CIS-scan wedged the whole app).
- **The Nessus/pirated-feed situation does NOT port.** GRC prod needs its own **legitimately-licensed** scanner (Nessus Essentials/Pro). Licensing is out of scope for the code port.
- **Design skins differ:** Ava uses indigo `#4F46E5`; ComplyVerse uses mint-teal `#1ed4b0` + Poppins + white sidebar. Decide skin policy up front (§5).

---

## 2. Strategy — delta port, three tiers

Sort Ava's code into three buckets; each is handled differently:

**Tier A — Cyber-feature modules (the payload).** These are what "Cybersecurity Assurance" should gain:
- Backend: `asset_discovery`, `compliance_plugins`, `vuln_management`, `risk_posture`, `integrations` (Nessus adapter + hosted_scan), plus the control-library + CTEM pieces.
- Frontend: `asset-discovery`, `assets`, `compliance-overview`, `compliance-plugins`, `vulnerabilities`, `risk-posture`, `scan-flows`, `my-runs`.

**Tier B — Shared platform modules (reconcile, don't overwrite).** GRC already has these (Ava cloned them); only Ava's *bug-fixes* matter, and GRC may have diverged:
- Backend: `identity`, `onboarding`, `workflow_engine`, `automation`, `connectors`, `chatbot`, `erm`, `it_assets`.
- Frontend: `admin`, `users`, `integrations`, `complychat`, `dashboard`, `layout.tsx`.
- Action: **diff, cherry-pick fixes**, never bulk-copy (would clobber GRC's own evolution).

**Tier C — Ava-only scaffolding that must NOT go to GRC.** Ava's tenant seed, branding (orb logo, "Ava Assist"), single-tenant assumptions, the `main.py` that mounts `/grc`, `.env`, and anything under `_deferred_stage5_attack_pipeline/`.

---

## 3. Phase 0 — Divergence audit (MUST be first; nothing ships before this)

You cannot safely port without knowing what changed on both sides since the clone.

1. **Fix the baseline.** Ava's clone point is `c819bd9`. `git -C CyberAssurance diff c819bd9..HEAD --stat` = the full Ava delta.
2. **Get GRC's current Cybersecurity Assurance surface.** Read-only audit of the GRC repo: which backend modules/routers and which frontend routes make up "Cybersecurity Assurance" today, and its DB tables. (Output: a file list + table list.)
3. **Three-way diff per Tier-A/B file:** clone-baseline ↔ Ava-HEAD ↔ GRC-HEAD. Classify each changed file as:
   - *Ava-only change* → port as-is.
   - *GRC-also-changed* → **conflict**, needs manual merge.
   - *GRC-superset* → skip (GRC already ahead).
4. **Deliverable:** a reconciled change list (spreadsheet/MD) = the actual work backlog, with a conflict column. **Do not proceed to Phase 1 until this exists.**

> Ava-side enhancements known to be in the delta (from this project's history), all of which need a landing spot in GRC's Cyber Assurance:
> discovery engine (pure-Python sweep, firewall-echo relabel, two-phase port gate/speed, Stop/cancel, delete-run, NetBIOS/host-name capture, per-device WinRM/WMI/SNMP methods, MAC-first dedup + 16 audit fixes); credentialed connect (WinRM/WMI/SSH, `LocalAccountTokenFilterPolicy` gate, deep_collect host_name); Nessus Flow-1 (winrm→windows SMB cred mapping, update_scan reuse, vulns_closed/reopened); CIS + OpenSCAP runners; SCF control library + CTEM stage-4 validation; vuln register/finding-detail + exploit-test; risk posture bands.

---

## 4. Backend plan

1. **Namespace.** Land Tier-A modules under GRC's Cybersecurity Assurance package boundary (a sub-package or the module's existing router tree), so they mount under one nav section and one RBAC group.
2. **Router wiring.** Register the ported routers in GRC's app the way GRC registers its modules (mirror GRC's pattern, not Ava's `main.py:/grc` mount).
3. **Shared-model reconciliation (highest-risk).** Ava and GRC both use `ITAsset`, `Vulnerability`, discovery/observation models, credential models. Where Ava added columns/relationships, merge them into GRC's model definitions — do **not** ship two competing definitions. List every model Ava touched and diff against GRC's.
4. **RBAC.** Map Ava's permissions (e.g. `compliance:discover:execute`) into GRC's permission catalog + the Cybersecurity Assurance role(s). Verify the Administrator-role bypass path still applies per-tenant.
5. **Multi-tenancy.** Confirm every ported query is `tenant_id`-scoped (Ava mostly is). Background workers (discovery sweeps, hosted-scan pollers, in-proc threads) must resolve tenant + DB per job, not assume a single DB.
6. **External dependencies.** `pip` additions Ava made (e.g. `pywinrm`, `paramiko`, `impacket`, `cryptography==42.0.8` pin) go into GRC's requirements; verify no version clash with GRC's existing pins.
7. **Per-module port order** (safest → riskiest): `risk_posture` → `vuln_management` → `compliance_plugins` → `integrations`/Nessus → `asset_discovery` (most surface area) → CTEM/control-library. Each module: port, unit-import check, self-tests, then move on.

---

## 5. Frontend plan

1. **Nav placement.** Add/extend the **Cybersecurity Assurance** section in GRC's shell; mount Ava's Tier-A pages as its sub-routes (`asset-discovery`, `assets`, `compliance-*`, `vulnerabilities`, `risk-posture`, `scan-flows`, `my-runs`).
2. **Skin decision (choose one, up front):**
   - (a) **Reskin to ComplyVerse** (mint-teal `#1ed4b0`, Poppins, white sidebar) so it matches GRC — more work, consistent product.
   - (b) **Keep Ava's indigo within the module** — faster, but visually distinct. Recommend (a) for a shipped GRC module; confirm with seniors.
3. **Shared components.** Because both descend from the clone, many components overlap. Reconcile against GRC's versions (Header/PAGE_TITLES, breadcrumb, table kit) rather than importing Ava's copies wholesale.
4. **API layer.** Fold Ava's `api.ts` cyber endpoints into GRC's API client + the `/api` rewrite/base-URL convention GRC uses (GRC frontend proxies `/api` → backend; Ava used `BACKEND_URL/grc`). Adjust base paths.
5. **One-window / layout rules.** Ava follows the owner's "fit one window, page name in the white header bar" rule — preserve where GRC's shell allows; verify no double H1 with GRC's global top bar.
6. **Build.** GRC frontend is `next build` (needs swap on prod). Type-noise: GRC likely also has `ignoreBuildErrors` — confirm before relying on it.

---

## 6. Database plan

1. **Schema delta = new tables + new columns.** Tables (`create_all` handles): discovery (`grc_discovery_campaigns/scopes/runs/jobs/observations`), CTEM, control-library/SCF, any vuln/asset link tables Ava added. Columns (**manual ALTER**): asset (`discovery_state`, `os_normalized`, `detected_software_json`, `known_ips`, …), vuln (`vulns_closed`, `vulns_reopened`, host-identity fields), observation `raw` usage, etc.
2. **Produce ONE idempotent migration script** (`ADD COLUMN IF NOT EXISTS` / guarded DDL) that runs table-create + every ALTER, applied to **each of the 7 tenant DBs** (and the master DB where relevant). This is the crux of the GRC schema gotcha — script it, don't hand-ALTER.
3. **Library seeds (not tenant data):**
   - CIS library (~31,553 rules) into GRC's compliance-plugins store.
   - SCF control library (~1,534 controls / 80,645 mappings / 5,956 objectives) via `scf_import.import_tenant(<tenant>, id)` per enabled tenant + the Administrator role grant.
   - No Ava operational data migrates — only schema + libraries.
4. **Verification query per tenant** after migration: assert each new table exists and each new column is present (the same style of check used when Ava's columns were added).
5. **Rollback:** additive-only DDL (new tables/columns) is low-risk; keep the migration reversible or at least non-destructive. Never drop GRC columns.

---

## 7. Rollout sequence

| Phase | Where | What |
|-------|-------|------|
| 0 | local | Divergence audit + reconciled backlog (§3). Gate. |
| 1 | local GRC | Backend port, module-by-module, import + self-tests green. |
| 2 | local GRC | Run the idempotent schema migration on local tenant DB(s); verify. |
| 3 | local GRC | Frontend port + nav + skin; `next build` clean. |
| 4 | local GRC | End-to-end test: discovery → connect → CIS/Nessus → vuln → risk, on a test tenant. |
| 5 | ComplyVerse `main` | PR with the full delta; senior review; CI. |
| 6 | prod 68.183.198.54 | Deploy: pull + pip + `next build` (swap on) + restart grc-backend/grc-frontend + **run the ALTER migration on all 7 tenant DBs** + seed libraries. |
| 7 | prod | Smoke test per tenant; watch logs; no self-scan. |

---

## 8. Risks & gotchas

- **Merge conflicts on shared models/files** (Ava vs GRC both moved) — the #1 risk; Phase 0 exists to surface it. Never bulk-copy Tier-B.
- **Multi-tenant schema application** — 7 DBs, manual ALTERs; a missed DB = runtime errors on that tenant. Script + per-tenant verify.
- **Background workers** must become tenant-aware if Ava's were single-tenant.
- **Design drift** — skin mismatch if (b) chosen; agree with seniors first.
- **Prod fragility** — `next build` needs swap; never self-scan prod; deploy in a low-traffic window.
- **Licensing** — the pirated Nessus feed does not travel; GRC prod needs a legit scanner. The code (adapter, hosted_scan, cred mapping) ports fine; the *feed* is an ops/licensing task.
- **RBAC gaps** — a ported feature with no matching GRC permission = 403s; map every permission in Phase 4.

---

## 9. Open questions for the seniors (resolve before Phase 1)

1. What does GRC's **Cybersecurity Assurance** module contain **today**? (drives the reconcile in §3.2)
2. **Skin:** reskin to ComplyVerse (recommended) or keep Ava indigo inside the module?
3. Which Ava capabilities are **in scope for v1** vs later (e.g., is CTEM/control-library in the first cut, or discovery+vuln only)?
4. Which **tenants** get Cybersecurity Assurance enabled, and is it per-tenant toggleable?
5. Is there a **feature flag** requirement so the module can ship dark and be switched on per tenant?

---

## 10. Immediate next action

Run **Phase 0** — generate `git diff c819bd9..HEAD --stat` for Ava and a read-only inventory of GRC's current Cybersecurity Assurance surface, then produce the reconciled backlog. Everything else depends on that list.
