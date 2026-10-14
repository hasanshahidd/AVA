# AVA RBAC matrix cleanup + Help Desk requester-nav fix: investigation and plan

Status: READ-ONLY investigation, nothing was changed. Worktree `C:/Users/HP/hd-itsm-wt`, branch `feat/helpdesk-itsm`.
Everything below is from code reading of that worktree. The one thing I could NOT verify is live data in `cyber_ava` on the droplet (see "Unverified" at the end).

---------------------------------------------------------------------------------------------------

## 0. Headline findings

1. **"CTM" is almost certainly CTEM** (Continuous Threat Exposure Management). The CTEM loop in AVA is Scope, Discover, Prioritise, **Validate (4th)**, Mobilise. `backend/grc/services/ctem_scopes.py:266` states the order, and the `_STAGE_LADDER` at line 274 puts `validate` 4th. There is no string "CTM" anywhere in the repo (grep over .py/.ts/.tsx/.md/.yaml/.json = 0 hits).
2. **The control library to KEEP = the SCF control plane** (Secure Controls Framework release 2026.2). It is stored in the shared tables `grc_scf_*` plus `grc_normalized_controls` (rows with `source='scf'`, grouped by `grc_common_control_groups`, all hanging off one `NormalizationRun` labelled "SCF 2026.2" with `is_baseline=True`). The CTEM Validate AI mapper reads exactly that baseline run. The "old" library is the AI-normalization "locked Unified Control Library" (2,332 controls over uploaded frameworks); it is superseded, and its router/task surface was already deleted (commit 45fe209).
3. **The model files `_07/_08/_09_1` are NOT old-vs-new libraries. They are shared plumbing used by BOTH.** `_08.NormalizedControl` is the bridge table the new SCF library writes into (`scf_id` column). **Do not delete or "deprecate" those model files** (details in section 1).
4. **`risks` is in the matrix as a "GRC" module but it is load-bearing for CTEM.** Every write on the CTEM Scopes/Cycles/Mobilise router is gated on `risks:risk_register:edit` (`modules/erm/routers/ctem_scopes.py:34`), and the CTEM Scopes UI computes `canEdit` from it (`CtemScopesRedesign.tsx:153`). Removing `risks` from the matrix makes CTEM admin-only for custom roles. KEEP `risks:risk_register` or re-point the gate (decision needed, section 3).
5. **Requester-nav duplication is real and has a second bug behind it:** the requester "Help / Knowledge Base" item points to `/helpdesk/kb`, which calls the AGENT endpoint `/helpdesk/articles` (gated `helpdesk:tickets:view`), so a requester-only user will get a 403 there (by code reading; not live-tested).

---------------------------------------------------------------------------------------------------

## 1. Control library: which to keep, which is old

### 1.1 The three model files (what they actually are)

| File | Tables | Role | Verdict |
|---|---|---|---|
| `models/_07_framework_normalization_models.py` | `grc_frameworks`, `grc_framework_domains`, `grc_control_objectives`, `grc_framework_controls`, `grc_framework_sub_controls` | **Legacy hand-seeded framework hierarchy.** `seed_frameworks()` is a documented DEPRECATED no-op (`seed_frameworks.py:167`: "Pre-seeded frameworks have been removed"). Still referenced: FKs from `ControlMapping`, `NormalizedControlLink`, `CommonControlGroupMapping`, `AIEvidenceRecommendation`; `control_links.py`, `asset_control_recommender.py`, `dashboard_router.py` import it. Archive README says the automation library "REUSES grc_framework_controls". | **Legacy hierarchy, keep the tables/models (FK targets). Empty/near-empty in AVA.** |
| `models/_08_normalized_control_model.py` | `grc_normalization_runs`, `grc_normalized_controls`, `grc_control_mappings`, `grc_normalized_control_links`, `grc_required_evidence` | **The bridge.** `NormalizedControl.scf_id` (line 51) is "the whole bridge between the SCF catalog and the rest of the platform". Every FK from evidence, exceptions, work items, `VulnerabilityControlLink`, `AiControlProposal` points here. `NormalizationRun.is_baseline` selects the active library. | **KEEP. Core of the current library.** |
| `models/_09_1_unified_common_control_library_models.py` | `grc_common_control_groups` (+ `_mappings`), `grc_control_similarity_mappings`, `grc_control_comparison_runs/_mappings`, `grc_control_inheritance`, `grc_ai_evidence_recommendations`, `grc_control_mapping_analysis` | "Unified common control library" = **domain groups** over normalized controls. In the SCF import, the 34 SCF domains become `CommonControlGroup` rows so the library renders (`tools/scf_import.py:246-267`, `startup_seed.py` comments). The `ControlComparison*`, `ControlSimilarity*`, `ControlInheritance`, `ControlMappingAnalysis` tables were only for the old AI compare/auto-group authoring surface (celery `ai_compare_frameworks`, `ai_auto_group`, ... in the deleted `tasks/control_library.py`). | **Keep `CommonControlGroup(+Mapping)`; the other 5 tables are dead-with-no-writers but harmless. Do not drop (table-drop is a separate, owner-approved step; the archive README says "Do NOT drop tables").** |

Note the model files are a **linear import chain** (`_09_1` does `from ._08... import *`, `_08` imports `_07`, ...). Deleting any one file breaks every later model. Do not delete model files.

### 1.2 The two libraries, side by side

**OLD (superseded): "locked Unified Control Library"**
- AI-normalized: 2,332 `NormalizedControl` rows (426 group leads + 1,906 standalone) wrapping 3,419 `ParsedFrameworkControl` rows from uploaded frameworks. Source of truth was the AI pipeline (`ai_compare_frameworks`, `ai_auto_group`, `ai_normalize_controls`, `build_master_baseline`) plus a static fallback seed.
- Router/task surface: `/controls` router, `/frameworks` router, `tasks/control_library.py` were **fully removed** in commits `45fe209` ("Fully remove old control-library routers (files + package imports)") and `5ebd920` (dead backend code). Copies are preserved in `C:/Users/HP/hd-itsm-wt/_archive_old_control_library/` (README there is STALE: it still says the originals are mounted; commit 45fe209 postdates it).
- Residual code still in tree: `startup_seed.ensure_static_control_library_baseline` (`startup_seed.py:279`) + `seed_data/normalization_baseline.json` (re-seeds the 2,332-row baseline if no baseline exists; explicitly guarded against SCF by a `label LIKE 'SCF %'` check at lines 281-289, which the comment says exists because it would otherwise "silently swap the library out"), ~40 one-off root scripts in `backend/` (`regen_*.py`, `assign_*.py`, `merge_consolidate.py`, `_reseed_ndmo.py`, ...), and the stale docstring of `services/ai_control_mapping.py` (still says "2,332 controls").

**NEW (keep): SCF control plane, automation library**
- Catalog: `models/_56_scf_catalog_models.py` (`grc_scf_release/source/control/mapping/objective/erl/...`, plus the per-tenant overlay `grc_scf_scope/control_state/check_result/audit_period`). The header comment says "The Secure Controls Framework becomes the one control library; every framework we support is a VIEW over it through grc_scf_mapping".
- Loader: `tools/scf_import.py` (out-of-band, idempotent on version+checksum). At lines 237-282 it (a) clears every prior `is_baseline`, (b) creates `NormalizationRun(label="SCF <version>", is_baseline=True)`, (c) writes one `NormalizedControl` per SCF control with `source='scf'`, `scf_id`, `common_group_id`, and (d) writes the 34 `CommonControlGroup` domain groups. The commit `64180bd` ("SCF import must mark its run as the control-library baseline", 2026-09-13) is exactly the fix that makes CTEM read it.
- Runtime router: `modules/automation/router.py` mounted at `main.py:262-264` (`/automation/soc2`, `/automation/common`, `/automation/{framework}`). Backed by `seed_data/scf/`, `seed_data/automation/`. Per the archive README (not re-verified live): cyber_ava holds SCF release 2026.2, 1,534 controls, 5,956 objectives, 80,645 mappings, 249 sources; 10 AWS quantitative + 66 live-API SaaS connector checks.
- Frontend: only `lib/api.ts:4380-4435` (`automationApi`) and `components/soc2/ui.tsx` types. **No page in AVA consumes `automationApi`** (grep: only api.ts mentions it). So the library's UI surface in AVA today is the CTEM Validate stage plus the asset page text, not a standalone Control Library page.

### 1.3 What the CTEM Validate (stage 4) consumes

Trace (all in the live mounted app):
1. UI: `app/(dashboard)/vulnerabilities/ctem-scopes/CtemScopesRedesign.tsx:871` ("The AI reads each vulnerability against your locked control library"), `_components/AiControlProposalsPanel.tsx`, `_components/MobiliseControlCell.tsx` (the "live link to the Validate stage").
2. API: `modules/vuln_management/routers/ai_control_proposals.py` (prefix `/ai-control-proposals`, gated `vulnerabilities:vulnerability_register:edit/view`) -> `services/ai_control_proposals.py` -> `services/ai_control_mapping.py`.
3. **Corpus = `ai_control_mapping.load_corpus` (lines 77-147):** `NormalizedControl` rows filtered to `baseline_run_id()` (the newest `is_baseline=True` run). After the SCF import that is the SCF run, so the corpus is the SCF controls. (If no baseline run exists it falls back to ALL NormalizedControl rows, line 95.)
4. Accepted proposals write `VulnerabilityControlLink` rows (`normalized_control_id` or `parsed_framework_control_id`) and `AiControlProposal` rows; `services/control_assurance.py` derives the tiers; `services/ctem_scopes.py::_cc_validate` (line 646) lists the controls (framework label literally "Unified Control Library", line 722).
5. Mobilise then consumes the validated set (`services/ctem_mobilise.py`, workflow engine).

**Caveat to verify:** `load_corpus` also appends "standalone leftovers" = every active, tenant-visible `ParsedFrameworkControl` NOT absorbed by the baseline (lines 121-142). With the SCF run nothing is "absorbed" (no `NormalizedControlLink` rows for SCF), so if cyber_ava ever contains uploaded-framework rows, ALL of them join the corpus alongside SCF. The archive README says those tables are 0 rows in cyber_ava, so this is currently inert, but it is a latent corpus-pollution path.

### 1.4 Concrete answer

- **KEEP: the SCF control plane** = `_56_scf_catalog_models`, `_08.NormalizationRun` + `_08.NormalizedControl(+Link, +Mapping)`, `_09_1.CommonControlGroup(+Mapping)`, `modules/automation/`, `tools/scf_import.py`, `seed_data/scf|automation`, `services/ai_control_mapping.py`, `ai_control_proposals.py`, `control_assurance.py`, `vuln_management/routers/control_links.py` (the CTEM stage-4 seam the archive README also says to keep), `_55_ai_control_proposal_models`, tables `grc_vulnerability_control_links`, `grc_control_effectiveness_evidence`, `grc_asset_control_links`, `grc_control_work_items`.
- **Old / dead (do not touch for the matrix task, candidates for a later cleanup):** the AI-normalization authoring surface and its residue listed in 1.2; `modules/integrations/services/control_mapping_service.py` + endpoints `POST /integrations/control-mapping/auto-map/{id}` and `/batch-map` (`integrations/router.py:1128-1155`) — a keyword-rule + gpt mapper that writes `VulnerabilityControlLink` against the legacy `FrameworkControl` table, **bypassing the review/confidence-gate flow**, with no UI caller (`api.ts:4098-4101` defined, no component calls `autoMapControls/batchMapControls`); `api.ts:174-188` `/frameworks` and `/controls` clients that now hit non-existent routes; unimported FE cards `components/dashboard/{MainModuleCards,ControlSurfaceTabs,ControlAssuranceOverviewCards,ComplianceOverviewCards}.tsx`; `Header.tsx:51` / `Breadcrumb.tsx:13` `/control-library` title entries for a route that does not exist.

---------------------------------------------------------------------------------------------------

## 2. "Fix the deprecation": candidates (I could not find a literal marker, so ranked by likelihood)

No Next build output exists in the worktree (`.next` absent) and `package.json` is Next 14.2 (so the Next 16 "middleware -> proxy" deprecation does not apply). The old logs in the main checkout (`grc-frontend/_fe*.log`, `backend/_*.log`) only show Node `util._extend` DEP0060, FastAPI `on_event` and `Query(regex=...)` warnings, all from the GRC product's old path (`...\GRC 1\complywerse_ai\...`), not AVA.

Most likely, in this area:
1. **The old/superseded Control Library (the "first imported" one) is "the deprecation".** The archive README, `seed_frameworks.py:167` ("DEPRECATED"), and the stale mount claim all describe it. "Fix the deprecation" most plausibly = finish retiring it: delete the residue in 1.2/1.4 (startup baseline seeder + `normalization_baseline.json`, root scripts, `control_mapping_service` + its 2 endpoints, dead `api.ts` clients, unimported FE cards, stale README/docstring) and prune the old modules from the matrix. This is the interpretation consistent with the owner's matrix-cleanup sentence. **Recommended reading.**
2. **Legacy `Framework` hierarchy (`_07`)**: `seed_frameworks()` is a deprecated no-op that `tenant_manager.py:61-65` still calls on every new tenant. Safe to stop calling; do not drop tables (FK targets).
3. **Python/library deprecations (build-warning class), if the owner means those:** `datetime.utcnow()` x1169 (Python 3.12 DeprecationWarning), pydantic v2 `class Config` x119 (`PydanticDeprecatedSince20`), SQLAlchemy 2.0 `Query.get()` x14 (e.g. `tools/scf_import.py:296` `db.query(SCFRelease).get(rid)`), FastAPI `@app.on_event` x2 (`main.py:272,319`). Pins: SQLAlchemy 2.0.46, pydantic 2.10.3, fastapi 0.131.0. Mechanical but large; do NOT bundle with the matrix work.
4. Help Desk meaning: the Frappe sidecar (`helpdesk-sidecar/`, `FRAPPE_INTEGRATION_PLAN.md`) is superseded by the native engine; not control-library related.

**Please confirm with the owner which of 1/3 is meant before touching code.** I recommend doing (1) as a separate, reviewed change after the matrix cleanup, not inside it.

---------------------------------------------------------------------------------------------------

## 3. PERMISSION_MATRIX keep / remove

Mechanics (confirmed): the matrix is only (a) the Role Management UI catalogue (`admin_router.py:1092,1100` -> `adminApi.getPermissionMatrix`, data-driven, no hardcoded module list in `admin/roles/page.tsx`) and (b) a self-check in `helpdesk_native/itsm_seed.py:726-738` plus `tests/test_pentest_run_lifecycle_fixes.py:267`. Permission rows are created on demand by `_get_or_create_permission` (`admin_router.py:305`), and role save does **no** validation against the matrix. So:
- Removing a module only removes its checkboxes from the UI. Existing `grc_permissions` / `RolePermission` rows stay in DB and keep working for any endpoint that still checks them.
- Re-saving an existing role in the UI will silently DROP any granted perm whose checkbox no longer renders (the PUT replaces `permission_names` with the checked set, `admin_router.py:1043-1051`). Warn the owner / run an audit of existing roles first.
- Administrator + tenant primary contact get `*:*:*` and bypass everything (`auth_router.py:630-640`).

### 3.1 Evidence per module (what enforces it in AVA)

| Module | Live backend gate | AVA frontend use | Decision |
|---|---|---|---|
| `dashboard` | `dashboard_router.py:32` gates the whole `/dashboard/*` router on `dashboard:overview:view` | Performance nav is ungated | **KEEP** (`overview`; `ai_insights` unused, optional drop) |
| `assets` | reporting datasets, criticality assessments router (`assets:criticality_assessments:*`) | Sidebar: Discovery, Inventory, Reports gate on `assets:asset_inventory:*` | **KEEP** (all 3 submodules) |
| `vulnerabilities` | 50+ endpoints (`vulnerability_register:view/edit/...`), AI control proposals | Sidebar, CTEM, SLA page | **KEEP** (all 4) |
| `pentest` | `pentest:scan/exploit:execute`, `workspace:view` | AI Pentest | **KEEP** |
| `helpdesk` | all HD routers | Help Desk nav | **KEEP** |
| `admin` | users/roles/org/audit_logs/permissions + `admin:integrations:*` | Admin popover | **KEEP** (see gap note below) |
| `compliance` | `compliance:scan:execute` (compliance_plugins + automation routers), `compliance:discover:execute` (asset_discovery, onboarding), `compliance:agents:manage` (onboarding) | CIS scanning, discovery, agents | **KEEP, trim to `scan`, `agents`, `discover`**. `assessments`, `statements`, `frameworks`: no endpoint, no live UI (only unimported `MainModuleCards.tsx` and `metric_catalog._P_COMPLIANCE`) -> remove |
| `controls` | **no endpoint gated on `controls:*`**; only `services/metric_catalog.py:24` (Trends "controls" module, no FE consumer in this checkout) and the unimported FE cards | none live | **KEEP only `control_library` [view, create, edit, delete]** as the single grantable name for the owner's one Control Library. Drop `control_testing`, `control_mapping`, `gap_analysis` (CTEM mapping is gated by `vulnerabilities:*`, not these). Note nothing enforces `controls:control_library:*` today; if the owner wants the library locked down, wire a gate (e.g. on `/automation/common/*` write paths) in a follow-up. |
| `erm` | `advanced_erm_router` (`erm:risks:view`, mounted), reporting dataset `risks` (`erm:risks:*`) | Sidebar "Assets Risk Posture" (`erm:risks:*`), assets pages | **KEEP, trim to `risks`**. `incidents`, `internal_controls`, `rcsa`, `kris`, `mitigation_actions`: no gate / only unimported FE cards -> remove |
| `risks` | `ctem_scopes.py:34` gates ALL CTEM scope/cycle/mobilise writes on `risks:risk_register:edit`; `risks_router.py` view/create/edit/delete/assess/treatment | `CtemScopesRedesign.tsx:153` `canEdit` | **NOT in the owner's keep list but MUST be kept (or re-pointed).** Recommend KEEP `risks` trimmed to `risk_register` [view, create, edit, delete]; this is how CTEM write access is granted to non-admins. (`risk_assessment` / `risk_treatment` back two mounted endpoints `risks_router.py:443,487` with no AVA UI caller found; `risk_appetite` unused -> remove those three.) Alternative: re-point `_edit` in `ctem_scopes.py` + the FE `canEdit` to `vulnerabilities:vulnerability_register:edit`, then `risks` can go. Needs an owner decision. |
| `integrations` | Backend scanner connection endpoints check **`admin:integrations:*`** (13+ sites in `modules/integrations/router.py`), NOT `integrations:*` | FE pages `/integrations/connections` (`integrations:connections:create/delete`) and `/integrations/exceptions` (`integrations:exceptions:edit`); Admin popover "Vulnerability Scanners" | **KEEP, trim to `connections` and `exceptions`**; `sync` and `analytics` have zero references. **Gap:** the matrix has no `admin:integrations` submodule (only `admin:integrations_sso`), so non-admin roles can never be granted what the live scanner endpoints check. Recommend adding `admin` submodule `integrations` [view, create, edit, delete] to the keep list. |
| `reports` | **No code anywhere checks `reports:*`.** Reporting datasets gate on the *dataset's* module perms (`reporting_router.py` `AVA_DATASET_ALLOWLIST`); Sidebar Reports gate is `assets:asset_inventory:*` | Reports nav | **KEEP per owner, trim to `reports` [view, create, export]; but note it is currently decorative.** Safe way to make it real without locking anyone out: Sidebar gate `['reports:reports:view','assets:asset_inventory:*']` (OR gate keeps existing access). Drop `dashboards`, `analytics` (unused; `vulnerabilities:reports` is a separate submodule and stays). |
| `workflow_engine` | Router mounted (`main.py:234`), gated on `workflow_engine:*` (executions approve, definitions, ai, analytics, templates, integrations) | Header notification bell (`/workflow-engine/notifications/in-app`); CTEM Mobilise creates `WorkflowDefinition/Instance` and approvals call `apply_approval_decision` (`services/ctem_mobilise.py`, `workflow_engine/routers/executions.py:285`) | **KEEP (whole module).** It is the Mobilise approval engine; trimming risks breaking approvals. (No workflow UI page in AVA, so it is a backend-only dependency.) |
| `bcm` | no router mounted | none (only unimported card) | **REMOVE** |
| `evidence` | routers mounted but **no permission gate at all**; only report/metric catalogs | none; dataset not in AVA allowlist | **REMOVE** |
| `governance` | routers mounted, **no permission gate** | none | **REMOVE** |
| `frameworks` | no router (frameworks router deleted) | none | **REMOVE** |
| `is_projects` | `is_projects_router` mounted, gated `is_projects:projects:view` | none (Header title only) | **REMOVE** (its mounted router then becomes admin-only; recommend unmounting separately) |
| `critical_tasks` | router not mounted | none | **REMOVE** |
| `issue_management` | router not mounted | none | **REMOVE** |
| `vendor_risk` | router not mounted | none | **REMOVE** |

### 3.2 The exact lists

The matrix currently has 21 modules.

**KEEP (13 modules, with the submodule trims above):**
`dashboard`, `assets`, `vulnerabilities`, `pentest`, `helpdesk`, `admin` (+ new `integrations` submodule), `compliance` (scan, agents, discover), `controls` (control_library), `erm` (risks), `risks` (risk_register, **pending owner decision**), `integrations` (connections, exceptions), `reports` (reports), `workflow_engine`.
12 if the owner opts to re-point the CTEM gate off `risks`.

**REMOVE (8 whole modules):**
`bcm`, `evidence`, `governance`, `frameworks`, `is_projects`, `critical_tasks`, `issue_management`, `vendor_risk`, plus the trimmed submodules listed per row. (`risks` becomes a conditional 9th if the CTEM gate is re-pointed.)

Ambiguous six, as the owner asked:
- `controls` = **KEEP** (control_library only)
- `compliance` = **KEEP** (scan, agents, discover only; CIS scanning/discovery/agents are live)
- `erm` = **KEEP** (risks only; nav "Assets Risk Posture" + `advanced_erm_router` gate)
- `integrations` = **KEEP** (connections, exceptions; plus add the missing `admin:integrations` submodule)
- `reports` = **KEEP** (decorative today; wire it with the OR-gate)
- `workflow_engine` = **KEEP** (Mobilise approval engine)

### 3.3 Dependencies confirmed safe for removal
For every REMOVE module I grepped `backend/grc` and `grc-frontend/src` for its permission strings: only these remain after removal and all are harmless: report datasets not in `AVA_DATASET_ALLOWLIST` (`evidence`, `issues`, `tasks`, `vendors`, `gov_documents`, `internal_controls` stay registered in `SERVER_DATASETS` but are filtered out of `/reporting/datasets`, though the query endpoints still check `spec.permissions`, so they become admin-only if called by id); `services/metric_catalog.py` (Trends, no FE consumer here); unimported FE dashboard cards. **No AVA nav gate and no live AVA endpoint depends on a removed module.** The one exception is `risks` (section 3.1).

### 3.4 Files to change when implementing (for the implementer)
1. `backend/grc/permissions.py`: delete removed modules/submodules; add `admin:integrations`.
2. `backend/grc/routers/auth_router.py:638-644` hardcoded admin `allowed_modules`: replace with the kept module keys **plus `pentest` and `helpdesk`** (both currently missing from the list; harmless today because admins bypass and `allowed_modules` is consumed only by `Sidebar.tsx:520`, whose AVA nav uses `requiredModules` on one item only).
3. `grc-frontend/src/components/layout/Sidebar.tsx:81-87` `ADMIN_DEFAULT_MODULES` / `AUTHENTICATED_DEFAULT_MODULES`: drop `erm` only if `erm` goes; otherwise leave. Optionally widen the Reports gate (3.1).
4. `backend/tests/test_pentest_run_lifecycle_fixes.py:267` and `itsm_seed.py:726-738` self-check still pass (they only need `pentest` / `helpdesk` modules).
5. Pre-flight: dump existing roles' permission names per tenant (ava) and list any that reference removed modules, so the owner knows what the next role save will strip. Do NOT delete `grc_permissions` rows.
6. FE bug found in passing: `vulnerabilities/sla/page.tsx:54-55` checks `vulnerabilities:vulnerability_management:create/edit`, a name that is **not in the matrix** (the submodule is `sla_management`), so SLA create/edit buttons only appear for admins. Fix to `vulnerabilities:sla_management:*` (or leave and log).
7. Security aside (out of scope, flag to owner): `governance_router`, `evidence_router`, `documents_router`, `tasks_router`, `dcc_router`, `audit_plan_router`, `nca_*_router`, `artifacts_router`, `policy_exception_router` are mounted with **zero permission gates** (`require_auth` only), so removing their matrix modules does not change their exposure, and any authenticated tenant user can reach them. Worth unmounting these dead GRC routers as a separate hardening step.

---------------------------------------------------------------------------------------------------

## 4. Requester-UX fix (Sidebar)

### 4.1 Current behaviour (from `Sidebar.tsx`)
- The three requester items (lines 131-133): `Report an issue` (`helpdesk:requests:create`), `My Requests` (`requests:view_own`), `Help / Knowledge Base` (`requests:view_own`, href `/helpdesk/kb`).
- Gate: `canAccessItem` -> `hasModuleAccess` then `hasPermission` (line 597-601). `hasPermission` is an OR (`required.some(matchesPermission)`) with an early `if (isAdmin) return true` (line 587). `is_admin` comes from `/auth/me` (`auth_router.py:630`: primary contact or role "Administrator") and is set at `Sidebar.tsx:535`.
- Consequences: admins always pass every item, so they see the 3 requester items plus the whole console. The seeded **Help Desk Agent** role includes `helpdesk:requests:view_own` (`itsm_seed.py:419`), so agents see "My Requests" and "Help / Knowledge Base" too. The agent also has `/helpdesk/kb` twice (requester "Help / Knowledge Base" and console "Knowledge Base" share href `/helpdesk/kb`, which also produces a duplicate React `key={item.href}` at lines 350-352).
- The Agent preset has no `requests:create`, so agents do not currently see "Report an issue".

### 4.2 Recommended approach (touches only these 3 items)
Add an opt-in flag on `NavItem` and handle it first in `canAccessItem`; the shared `hasPermission` OR-gate and its admin bypass stay exactly as they are for every other item and group.

```ts
interface NavItem { ...; /** Visible only to requester-only users: not admin, no agent perm. */ requesterOnly?: boolean; }

// agent = anyone who can use the console
const HD_AGENT_PERMS = ['helpdesk:tickets:view'];

const canAccessItem = (item) => {
  if (item.adminOnly && !isAdmin) return false;
  if (!hasModuleAccess(item.requiredModules)) return false;
  if (item.requesterOnly) {
    if (isAdmin) return false;                              // admins never see the portal items
    if (HD_AGENT_PERMS.some((p) => matchesPermission(p))) return false;   // agents neither
    return (item.requiredPermissions ?? []).some((p) => matchesPermission(p)); // requester perms, NO admin shortcut
  }
  return hasPermission(item.requiredPermissions);           // unchanged for everything else
};
```
Mark the three requester items `requesterOnly: true`. `matchesPermission` already honours `helpdesk:tickets:*`, `helpdesk:*:*` and `*:*:*`, so custom roles built from the matrix behave correctly, not just the two presets. Group-level filtering (`filterEntries`) is untouched: the Help Desk group renders when any child survives, so a requester-only user sees exactly 3 items and an agent/admin sees only the console.

Why this over alternatives:
- Dropping `view_own` from the Agent preset alone does NOT fix admins, and does NOT fix custom roles that combine `tickets:view` + `view_own`. The Sidebar rule fixes all of them in one place.
- A negative-permission field on the generic gate (`hideIfHasPermissions`) would be reusable but adds surface to every group; a boolean scoped to this feature is smaller and cannot affect the OR-gating of the other groups.

### 4.3 Companion fix required for the requester KB item
`/helpdesk/kb` (`helpdesk/kb/page.tsx`) calls `useHd("/helpdesk/articles")`, which is `require_view` (`helpdesk_native/router.py:179`, `helpdesk:tickets:view`), so a requester-only user gets 403. The requester-safe endpoint already exists: `GET /helpdesk/portal/kb` (`portal.py:127-132`, gated `requests:view_own`). Options (pick one):
- (a) point the requester item to a new `/helpdesk/portal/kb` page that reuses the same list UI with `useHd("/helpdesk/portal/kb")` (cleanest; also removes the duplicate `/helpdesk/kb` href), or
- (b) make `kb/page.tsx` choose the endpoint via `usePermissions().hasPermission('helpdesk:tickets:view')`.
Recommend (a). Verify live as a requester before/after; I only confirmed this by reading code.

### 4.4 Should `helpdesk:requests:view_own` be dropped from the Help Desk Agent preset?
- **Not required** once 4.2 is in. The spec (`docs/HELPDESK_RBAC_SPEC.md:72`) gave it to agents on purpose (so an agent can use the portal for requests they personally raised), and no agent endpoint depends on it.
- If the owner wants a clean "agent is not a requester" role anyway, remove it from `_HD_ROLES["Help Desk Agent"]` (`itsm_seed.py:419`), **but** `seed_hd_roles` only ADDS missing links and never removes (`itsm_seed.py:624-628`), so existing tenants (ava) would keep it. A drop therefore needs either a one-off DELETE of that `RolePermission` row for role "Help Desk Agent", or making `seed_hd_roles` prune links not in the spec (changes semantics for admin-edited presets, so I recommend the one-off DELETE).
- Recommendation: do 4.2 + 4.3 now; leave the preset unchanged (optional later).

---------------------------------------------------------------------------------------------------

## 5. Suggested implementation order (when approved)
1. Owner decisions: (a) `risks` keep vs re-point CTEM gate; (b) what "the deprecation" means (section 2); (c) trim sub-modules or only whole modules; (d) adopt Reports OR-gate.
2. Pre-flight on ava DB: roles and their perms referencing removed modules; confirm `grc_normalization_runs` baseline = "SCF 2026.2", `grc_normalized_controls` source counts, `grc_uploaded_frameworks` / `grc_parsed_framework_controls` row counts (corpus-pollution caveat in 1.3).
3. Matrix edit (`permissions.py`, `auth_router.py` allowed_modules), then run the two matrix-dependent checks.
4. Sidebar `requesterOnly` + requester KB page (4.2/4.3). `npx tsc --noEmit` / `next build`.
5. Verify as 3 users on a local run (`ava.localhost:3000`): admin (no requester items), Help Desk Agent (console only), Help Desk Requester (3 items, KB loads).
6. Separate PRs: old-control-library residue cleanup; dead GRC router unmounting; Python/library deprecation sweep.

## 6. Unverified / uncertain (flagged)
- Live `cyber_ava` contents (which run is baseline, row counts, whether `grc_uploaded_frameworks` is empty). All "1,534 controls / 80,645 mappings / empty old tables" figures come from `_archive_old_control_library/README.md`, not from a DB query.
- Whether the owner's "CTM" is CTEM (strong inference: the 4th stage is Validate and it consumes the control library; no literal "CTM" in the repo).
- What "fix the deprecation" refers to (section 2 ranks candidates; no literal deprecation marker ties to the control library besides `seed_frameworks.py` and the archive README).
- `risks` keep-vs-repoint is a product decision, not a code fact.
- Requester KB 403 is from reading the gates, not a live request.
- The worktree is `feat/helpdesk-itsm`; the main checkout has many uncommitted modifications (e.g. pentest, vuln_management files) that I did not inspect, so line numbers may shift there.
