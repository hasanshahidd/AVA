# PRESERVED — Old (pre-automation) Control Library surface

**Archived 2026-09-13.** These are **copies** kept for safekeeping when Ava adopted GRC's
updated (automation) control library. The **originals are still in place and still mounted**
in the live app — nothing here was removed from the running product. This folder is a preserved
snapshot only; it is outside the `grc` package, so it is NOT imported or served.

## What this "old library" was
Definitions + framework mappings only — **nothing ran**, no control ever carried a live
pass/fail. The AI-normalization authoring surface (compare / auto-group / normalize) over the
`_08`/`_09_1` models. Its catalog tables were **empty (0 rows)** in `cyber_ava` — it was inert.

## What replaced it (live now)
GRC's `modules/automation` control library (SOC 2 quantitative + framework-aware libraries over
the SCF catalog): each control is bound to runnable checks (10 AWS quantitative + 66 live-API SaaS
connectors) and carries a real status. Imported into `cyber_ava`: 1,534 controls / 5,956 objectives
/ 80,645 mappings / 249 sources (SCF release 2026.2), served at `/automation/*` (19 routes).

## Files preserved here (still live in `backend/grc/`)
- `routers/controls_router.py`  — old `/controls` CRUD + AI-recommendations (backs empty tables)
- `routers/frameworks_router.py` — old `/frameworks` library CRUD (backs empty tables)
- `tasks/control_library.py`    — celery jobs: ai_compare_frameworks / ai_auto_group /
  ai_normalize_controls / build_master_baseline (+ registered in `grc/celery_app.py`)

## If you later decide to unmount the old surface (owner said "removing not dropping")
Do NOT drop tables — the new automation library REUSES `grc_scf_*`, `grc_normalized_controls`,
`grc_framework_controls`, `grc_control_work_items`. Removing means: unmount `controls_router` +
`frameworks_router` in `main.py` and drop the `tasks/control_library.py` celery registration.
**First trace frontend callers** — `grc-frontend/src/lib/api.ts` still has leftover clone client
functions for `/controls` and `/frameworks`; a defined client fn is harmless unless a live page
invokes it. KEEP the CTEM stage-4 seam: `vuln_management/routers/control_links.py`,
`services/control_assurance.py`, and tables `grc_vulnerability_control_links`,
`grc_control_effectiveness_evidence`, `grc_asset_control_links`.
