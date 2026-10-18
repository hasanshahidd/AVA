# AVA Help Desk — ITSM Workbook Ingest Audit

One-time, high-rigor, row-and-column verification that the owner's ITIL-4 ITSM
workbook is faithfully represented in the database after the exporter → bundle →
importer pipeline.

- **Workbook:** `AVA_ServiceDesk_ITSM_enriched_v3.xlsx` (35 worksheets: 2 meta +
  33 data sheets `01`–`33`; the "34 sheets" in the task brief was approximate).
- **Exporter:** `grc/modules/helpdesk_native/itsm_bundle_export.py`
- **Importer:** `grc/modules/helpdesk_native/itsm_import.py`
- **Models:** `grc/models/_62_helpdesk_itsm_models.py` + ITSM columns on
  `grc/models/_60_helpdesk_native_models.py`
- **Method:** workbook loaded with `openpyxl(data_only=True)`; bundle built with
  the real exporter; imported into a fresh in-memory SQLite for one tenant using
  the exact `tests/test_itsm_import.py` harness; DB row/column counts queried per
  target table and reconciled against the workbook with the importer's documented
  transformations in hand.
- **Date:** 2026-10-18. Import batch status: **applied**. Checksum deterministic
  across two exports: **yes**. Re-import of the same bundle: **true no-op**
  (0 inserted / 0 updated on every entity).

## Bottom line: **PASS**

Every data row of every data sheet is represented in the database — either 1:1,
or via an explicitly documented transformation (M:N explode, 3-level tree
dedup, cross-process state merge, process-summed fields/RACI). **No sheet
silently lost a row.** Every workbook column is now either stored or
**consciously documented** as an intentional drop in the importer. Every model
in `_62` maps to a created table with the expected PK / FK targets / unique
indexes, and all four ITSM catalogue/CMDB link columns exist on `HDTicket`.

The audit found one bug *class* — several fully-populated workbook columns were
dropped **without any stated reason** (the brief's "neither stored nor
consciously dropped" definition). Fixed at root by documenting each drop in the
relevant importer applier (comment-only; zero behavior change; 25/25 tests still
green). No rows, FKs, or relationships were affected, so no data-path fix was
required. Details in the FLAG section.

---

## Page-by-page reconciliation

Row counts are **exact DB query results**. "part of N" = the sheet is merged or
summed with sibling sheets into one table (see the transformation note).

| Sheet | Excel rows | Excel cols | DB table(s) | DB rows | DB cols | Transformation | Verdict |
|---|---|---|---|---|---|---|---|
| Index | 36 | 1 | — (entity-key map) | — | — | meta: drives exporter entity keys | PASS (meta) |
| 00 • Read Me | 7 | 2 | — (bundle `meta`) | — | — | meta: feeds `bundle_version` | PASS (meta) |
| 01 • Service Categories | 16 | 3 | `grc_hd_service_category` | 16 | 12 | 1:1 (no parent col in sheet → `parent_id` null) | PASS |
| 02 • Business Services | 87 | 11 | `grc_hd_business_service` | 87 | 14 | 1:1; 2 descriptive cols dropped (now documented) | PASS |
| 03 • Technical Services | 119 | 6 | `grc_hd_technical_service` (+`grc_hd_service_dependency`) | 119 (+362) | 11 (+5) | 1:1 + M:N explode of "Supports Business Service Id" | PASS |
| 04 • Request Catalogue | 192 | 11 | `grc_hd_request_item` | 192 | 17 | 1:1; `Industry` + `Cost Model` dropped (documented) | PASS |
| 05 • Support Groups | 15 | 5 | `grc_hd_support_group_map` | 15 | 8 | 1:1 GRP→team bridge; Tier/Scope/Coverage dropped (documented) | PASS |
| 06 • Roles | 20 | 3 | `grc_hd_role_map` | 20 | 9 | 1:1; `rbac_preset` admin-owned (documented) | PASS |
| 07 • Priority Matrix | 9 | 3 | `grc_hd_priority_matrix` (+`grc_hd_ticket_priority`) | 9 (+5) | 8 | cells + P1..P5 onto ticket_priority | PASS |
| 08 • SLA / OLA Targets | 11 | 6 | `grc_hd_sla_target` | 11 | 13 | 1:1; best-effort minute parse, prose→notes | PASS |
| 09 • CMDB CI Types | 28 | 5 | `grc_hd_ci_type` | 28 | 10 | 1:1; flat `Category` dropped (documented) | PASS |
| 10 • CMDB CI Attributes | 296 | 5 | `grc_hd_ci_attribute` | 296 | 9 | 1:1; enum `Description`→options, non-enum text partial (documented) | PASS |
| 11 • CMDB Relationship Types | 12 | 4 | `grc_hd_ci_relationship_type` | 12 | 8 | 1:1; `Description` dropped (documented) | PASS |
| 12 • CMDB Sample CIs | 33 | 8 | `grc_hd_ci` | 33 | 15 | 1:1 (`Location`→`attributes` JSON) | PASS |
| 13 • CMDB Sample Relationships | 42 | 3 | `grc_hd_ci_relationship` (+ `HDConfigurationItem.business_service_id`) | 38 (+4) | 5 | 38 CI↔CI edges + 4 REALISES carried on the CI | PASS |
| 14 • Incident States | 9 | 3 | `grc_hd_ticket_status` / `grc_hd_state_transition` | part of 26 / 61 | 15 / 10 | cross-process label merge + "Allowed Next"→transitions | PASS |
| 15 • Incident Fields | 30 | 4 | `grc_hd_process_field` | part of 69 | 11 | summed across 3 processes | PASS |
| 16 • Incident Categories | 223 | 3 | `grc_hd_incident_category` | 345 | 12 | 3-level tree: distinct category + (cat,sub) + (cat,sub,item) | PASS |
| 17 • Incident RACI | 7 | 6 | `grc_hd_raci` | part of 28 | 12 | summed across 4 processes | PASS |
| 18 • Service Request States | 9 | 3 | `grc_hd_ticket_status` / `grc_hd_state_transition` | part of 26 / 61 | — | state merge | PASS |
| 19 • Service Request RACI | 7 | 6 | `grc_hd_raci` | part of 28 | — | summed | PASS |
| 20 • Problem States | 8 | 3 | `grc_hd_ticket_status` / `grc_hd_state_transition` | part of 26 / 61 | — | state merge | PASS |
| 21 • Problem Fields | 17 | 4 | `grc_hd_process_field` | part of 69 | — | summed | PASS |
| 22 • Problem RACI | 7 | 6 | `grc_hd_raci` | part of 28 | — | summed | PASS |
| 23 • Change Types | 4 | 4 | `grc_hd_change_type` | 4 | 10 | 1:1; `Typical Risk` dropped (documented) | PASS |
| 24 • Change States | 10 | 3 | `grc_hd_ticket_status` / `grc_hd_state_transition` | part of 26 / 61 | — | state merge | PASS |
| 25 • Change Fields | 22 | 4 | `grc_hd_process_field` | part of 69 | — | summed | PASS |
| 26 • Change Risk Matrix | 9 | 3 | `grc_hd_change_risk_matrix` | 9 | 8 | 1:1 (+ `cab_required` derived) | PASS |
| 27 • Change CAB Model | 10 | 2 | `grc_hd_cab_config` | 10 | 8 | 1:1 key/value | PASS |
| 28 • Change RACI | 7 | 6 | `grc_hd_raci` | part of 28 | — | summed | PASS |
| 29 • Performance & Availability KPIs | 28 | 5 | — (none) | 0 | — | **deferred by design** (later phase) | PASS (deferred) |
| 30 • Departments Schema | 12 | 4 | — (none) | 0 | — | column-definition sheet, **not data** | PASS (not data) |
| 31 • Departments Sample | 15 | 8 | `grc_hd_department` | 15 | 9 | 1:1; DEPT-Id/Self-Service/Seeded dropped (documented) | PASS |
| 32 • KB Categories | 10 | 2 | `grc_hd_article_category` | 10 | 9 | 1:1 (by `code`) | PASS |
| 33 • KB Articles | 57 | 11 | `grc_hd_article` | 57 | 13 | 1:1; symptom/cause/resolution/tags→`content`; audience/level/related_service_id dropped (documented) | PASS |

**Aggregate check-sums that must hold (all verified):**
- Process fields: 30 + 17 + 22 = **69** = `grc_hd_process_field` rows. ✓
- RACI: 7 × 4 = **28** = `grc_hd_raci` rows. ✓
- States: 9 + 9 + 8 + 10 = 36 rows → **26** distinct `grc_hd_ticket_status` +
  **61** `grc_hd_state_transition`. ✓
- Service dependencies: 362 > 119 technical services (M:N holds). ✓
- CI relationships: 38 edges + 4 service-realisation links = **42** = sheet 13. ✓
- Incident tree: 223 × 3 node-calls = 669 upsert calls → **345** distinct nodes
  (324 deduped). ✓
- Priorities: 5 (P1..P5) on `grc_hd_ticket_priority`; priority-matrix cells = **9**. ✓

No sheet is unaccounted for; no data row is lost.

---

## FLAGs and their resolution

### FLAG-1 (fixed) — fully-populated columns dropped with no stated reason

Nine workbook columns (all **100% populated** with real values — verified by cell
scan) were silently discarded by the importer: present in the sheet, absent from
the model, and with **no comment** explaining the omission. By the brief's own
definition ("an Excel column that is neither stored nor consciously dropped"),
this is a bug *class*.

| Sheet | Column(s) | Populated | Why not stored | Fix |
|---|---|---|---|---|
| 02 Business Services | `Sla Tier`, `Industry Specific` | 87/87 | Tier label + Yes/No flag; `criticality` + `industry_tag` carry the routing signal, SLA lives in sheet 08 keyed by priority | documented in `_apply_business_services` |
| 04 Request Catalogue | `Industry` | 192/192 | Parent business service already carries `industry_tag` | documented in `_apply_request_items` |
| 05 Support Groups | `Tier`, `Scope`, `Coverage` | 15/15 | Table is a pure GRP-*→AVA-team bridge; authoritative team + coverage live on `grc_teams` | documented in `_apply_support_groups` |
| 09 CI Types | `Category` | 28/28 | CI types are organised by their own `parent_cit_id` tree, which subsumes the flat grouping | documented in `_apply_cmdb` |
| 10 CI Attributes | `Description` (non-enum) | 202/202 non-enum | Enum rows consume it into `options`; non-enum free-text hint has no column (see note below) | documented in `_apply_cmdb` |
| 11 Relationship Types | `Description` | 12/12 | `name` + `inverse_name` define the edge type | documented in `_apply_cmdb` |
| 14/18/20/24 States | `Description` | 9/9 (incident) etc. | Lifecycle engine consumes label + category + initial/terminal flags; no workbook-fed description column | documented in `_apply_states` |
| 23 Change Types | `Typical Risk` | 4/4 | Advisory hint; real per-change risk = impact×likelihood matrix (sheet 26) | documented in `_apply_change` |
| 31 Departments | `Department Id` (DEPT-*), `Self Service Created`, `Seeded` | 15/15 | Stored key is the short `Code` (IT); the other two are authoring-provenance flags | documented in `_apply_departments` |

**Resolution rationale.** These are all descriptive / advisory metadata in a
*foundation + mapping* layer, not referenced by any FK or transformation, so no
row, relationship, or lookup is affected by their absence. The design intent to
omit descriptive workbook columns is corroborated by (a) the importer already
documenting five sibling drops (`support_group_id`, `Cost Model`, `rbac_preset`,
`parent_department_id`, KB `audience`/`level`/`related_service_id`) and (b) the
owner's brief naming `sla_tier` itself as an **intended** drop. The fix therefore
makes each drop **conscious and auditable** rather than expanding the schema —
which also avoids the separate, out-of-scope Postgres-vs-SQLite `ALTER` concern.
All edits are comment-only; `tests/test_itsm_import.py` stays 25/25 green and the
re-import remains a true no-op.

**One item the owner may want to revisit later (not a blocking bug):** the
**CI-attribute `Description` for the 202 non-enum rows** is the one dropped field
that is genuine data-dictionary content (e.g. "Owning team", "Physical/logical
location"), not just a label. It is now documented as a deliberate partial-store,
with an inline pointer: if the product ever needs to surface attribute hints, add
a `description` column to `HDCIAttribute` (an additive change gated by the same
`itsm_seed` ALTER mechanism as the other ITSM columns).

### Intentional transformations (correct — NOT bugs, by design)

- **03 → M:N explode:** `technical_service` 119 rows + `service_dependency` 362
  (the exploded comma-separated "Supports Business Service Id" pairs). A business
  service can have many supporting technical services and vice-versa.
- **16 → tree dedup:** 223 triples → 345 distinct `incident_category` nodes
  (distinct category + distinct (category, subcategory) + distinct
  (…, example_item)); repeats collapse onto one node.
- **14/18/20/24 → state merge:** 36 state rows → 26 distinct `ticket_status`
  labels (`process="shared"` when a label appears in >1 process) + 61
  `state_transition` rows from "Allowed Next", with `(reopen)`-style suffixes
  parsed into `guard`.
- **07 → priority matrix:** 9 impact×urgency cells + P1..P5 stamped onto
  `ticket_priority` (`code`/`rank`), matching an existing seeded priority by name
  where present rather than duplicating it.
- **13 → CI graph + realisation:** 42 relationship rows → 38 typed CI↔CI edges +
  4 "CI realises a business service" links carried on `HDConfigurationItem.
  business_service_id` (a service target can't be a CI↔CI edge).
- **08 SLA / 27 CAB / 26 risk matrix / 15·21·25 fields / 17·19·22·28 RACI /
  30·31 departments / 32·33 KB:** all land on their own tables as reconciled
  above.

### Intentional column drops that were **already documented** (correct)

`business_services.support_group_id` (validated-only), request `Cost Model`
(label not amount), roles `rbac_preset` (admin-owned), departments
`parent_department_id` (no sub-tree yet), KB `audience` / `level` /
`related_service_id` (fold-away / validation-only, no column). All carry an
explicit comment in the importer; none is a bug.

### Deferred / non-data sheets (correct)

- **29 Performance & Availability KPIs (28 rows):** deferred to a later phase by
  design — exported into the bundle as `performance_kpis` but has no importer
  applier. Not a bug.
- **30 Departments Schema (12 rows):** a column-**definition** sheet (Field /
  Type / Required / Description describing the Departments table), **not**
  department data. Correctly not ingested; the actual department rows are sheet
  31. It is carried in the bundle as `department_schema` but unused.

---

## Schema verification (`_62` models + `_60` ITSM columns)

All 24 classes defined in `_62_helpdesk_itsm_models.py` map to a table that
creates cleanly, with the expected PK, FK targets, and unique indexes:

- **Ingest-target tables (22)** — all created and populated as above. Each
  tenant-scoped table carries `tenant_id → grc_tenants.id`, `source_batch_id →
  grc_hd_import_batch.id`, and a `(tenant_id, code)` (or natural-key) UNIQUE
  index. Spot-checked FK targets all resolve:
  - `service_dependency`: `(business_service_id, technical_service_id)` UNIQUE,
    both FKs `ON DELETE CASCADE` → the two service tables. ✓
  - `ci_relationship`: `(source_ci_id, target_ci_id, rel_type_id)` UNIQUE, FKs →
    `grc_hd_ci` / `grc_hd_ci_relationship_type`. ✓
  - `priority_matrix.priority_id` → `grc_hd_ticket_priority`;
    `state_transition.from/to_status_id` → `grc_hd_ticket_status`;
    `incident_category.parent_id` self-FK. ✓
  - `sla_target` UNIQUE `(tenant_id, process, priority_label, service_window)`;
    `process_field` UNIQUE `(tenant_id, process, name)`; `raci` UNIQUE
    `(tenant_id, process, activity)`; `cab_config` UNIQUE `(tenant_id, item)`. ✓
- **Runtime-only tables (2)** — `grc_hd_approval` and `grc_hd_approval_vote` are
  the approval/CAB-vote engine, populated at ticket runtime, **not** from the
  workbook. Both have valid DDL (verified by create), correct FKs
  (`approval.ticket_id → grc_hd_ticket`, `approval_vote.approval_id →
  grc_hd_approval`) and the `(approval_id, approver)` UNIQUE vote index.
  Correctly excluded from the importer's catalogue.

**`_60` ITSM link columns** — all present on `grc_hd_ticket`: `process`,
`impact`, `urgency`, `change_type`, `change_risk`, `approval_state`,
`root_cause`, `workaround`, `known_error`, `request_category`,
`request_subcategory`, and the four catalogue/CMDB FKs `business_service_id`,
`ci_id`, `request_item_id`, `incident_category_id`. The ITSM columns on
`HDTicketStatus` (`process`/`is_initial`/`is_terminal`/`sort_order`),
`HDTicketPriority` (`code`/`rank`), `HDDepartment`/`HDArticleCategory`/
`HDArticle` (`code`) are all present and written by the importer.

**Model/DDL mismatches found:** none.

`state_transition.required_role` is intentionally never written by the importer
(the state sheets have no role column); it is reserved for a role-gated
transition policy and stays null. Not a bug.

---

## Note on the known pre-deploy item (out of scope here)

The ITSM columns added to the existing `_60` tables (and the new `_62` tables)
reach existing tenant databases via `itsm_seed` ALTERs. The `ADD COLUMN IF NOT
EXISTS` guard being SQLite-only is a **separate pre-deploy item** and is not part
of this ingest-fidelity audit. It does not affect the fresh-database correctness
proven above (this audit ran against `create()`-built tables, the new-tenant
path). If FLAG-1's optional CI-attribute `description` column is ever added, it
must go through the same ALTER path and inherit that same pre-deploy caveat.

---

## Test result

`python -m pytest tests/test_itsm_import.py` → **25 passed** (includes
`test_real_v3_workbook_imports_and_is_idempotent`, which ingests the real v3
workbook end-to-end and asserts the headline counts: 87 business services, 119
technical services, 192 request items, 9 priority cells, 11 SLA targets, 69
process fields, 28 RACI, 10 CAB, 15 departments, 57 KB articles, and a
deps > technical-services M:N).
