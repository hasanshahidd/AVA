# Help Desk for AVA — GLPI vs Frappe Helpdesk (code-level, side by side)

**Date:** 2026-10-10 · **Author:** code-level review (3 parallel deep-dives: GLPI 12.0.1-dev, Frappe Helpdesk, AVA local repo)
**Question:** Which open-source service desk to integrate as AVA's remediation-ticketing backend, with no conflicts afterward.

---

## TL;DR — Recommendation: **Frappe Helpdesk** (primary), GLPI as the LAMP-ops fallback

The single biggest decision fact came from reading **AVA's own code**: the ticketing seam is **already built and working** for ServiceNow. Adding a help desk is **one adapter file + one registry line** against the existing `TicketingAdapter` contract — not a framework adoption, for either candidate.

Given that, the choice is decided by *fit to AVA's existing REST adapter* and *"no conflicts afterward"*:

- **Frappe Helpdesk wins on "no conflicts by design":** it is a *pure help desk* — it has **no asset/CMDB module**, so nothing competes with AVA's own asset discovery (`grc_it_assets`). GLPI ships a full CMDB that *will* duplicate AVA's assets unless you deliberately keep it empty.
- **Frappe wins on integration cleanliness:** direct `priority`/`status` fields (GLPI silently recomputes priority from an urgency×impact matrix unless the profile has `CHANGEPRIORITY`), token auth (GLPI needs OAuth2 password-grant or legacy session + `App-Token`), and a **DB-unique** `ava_finding_id` custom field for true idempotency (GLPI's `external_id` column is **not** `UNIQUE`).
- **Price of Frappe:** heavier runtime (full Bench: MariaDB + Redis + RQ workers + scheduler + socketio + gunicorn, on **Python 3.14 / Frappe 16**) and **AGPL-3.0** discipline (run it **unmodified**, as an isolated REST service).

**Pick GLPI instead only if** boring LAMP ops (PHP-FPM + MariaDB + cron) and GPL matter more than integration cleanliness, and you will consciously **leave GLPI's CMDB empty** and run `glpi:cron` reliably.

Both force a MariaDB/MySQL sidecar (neither does production PostgreSQL) — unavoidable; isolate it in its own container and talk only over REST.

---

## The decisive context: AVA's seam is already wired

From `backend/grc/modules/connectors/` and `backend/grc/modules/vuln_management/`:

- **Contract** (`connectors/base.py:118`): `TicketingAdapter` = 4 abstract methods + a default `run_sync`:
  `create_ticket(TicketRequest)→str`, `update_ticket(id, fields)→bool`, `close_ticket(id, note)→bool`, `fetch_statuses(ids)→[TicketStatus]`, plus `test_connection()`.
- **Reference impl:** `providers/servicenow.py` (228 lines, plain `requests`). A new provider mirrors it.
- **Registration:** add the module path to the `provider_modules` list in `registry.py::_bootstrap` (one line). `build_adapter()` wires credentials/console_url in.
- **Working flow (Flow A):** `services/itsm_service.py::push_finding` + `sync_ticket_statuses`, exposed at `POST /vuln-management/vulnerabilities/{id}/push-to-itsm` and `POST /vuln-management/itsm/connections/{id}/sync-statuses`, with UI in `grc-frontend/.../vulnerabilities/[id]/_components/ItsmPanel.tsx`. Stores one `VulnTicketLink` per (tenant, finding, connection); idempotency key = `str(Vulnerability.id)`; on a `resolved` ticket it advances the finding's `VulnRemediationPlan` to `applied` — it never rewrites `Vulnerability.status`.

**Three AVA-side gotchas to fix/avoid before enabling any new provider** (see §Integration plan):
1. **Flow B (`sync_runner._sync_ticketing`, hourly)** auto-pushes every open finding with CVSS≥7 via a *different* store (`template_fields["connector_tickets"]`), never writes status back, and **crashes on the exception branch** (`PolicyException` has no `metadata_info`; the column is `metadata_`).
2. `verify_ssl` is **never passed** to adapters (`build_adapter` call sites omit it) → a self-hosted help desk with a private-CA cert can't disable verification unless the adapter reads it from `provider_config`.
3. ServiceNow's `update_ticket`/`close_ticket` use the ticket `number` where ServiceNow needs `sys_id` — latent, unused. Don't copy that mistake.

---

## Side-by-side: the 12 dimensions (GLPI | Frappe | AVA)

### 1. Overview & purpose
| GLPI | Frappe Helpdesk | AVA |
|---|---|---|
| ITSM **+ ITAM** suite; one `CommonITILObject` base serves Ticket/Problem/Change; ships CMDB, inventory agent, KB, projects, forms. | **Standalone help desk** shipped as a Frappe *app* (not ERPNext); customer-service focused; no asset module. | AI cyber-assurance / offensive-validation platform; findings (scanner + AI-pentest + manual) all land in one `Vulnerability` table. Needs only the *ticket* slice of a help desk. |

### 2. Tech stack & architecture
| GLPI | Frappe | AVA |
|---|---|---|
| PHP ≥8.3, Symfony kernel; `src/Ticket.php`, `src/CommonITILObject.php`; **MySQL/MariaDB only** (`DBmysql.php`). Legacy `/apirest.php` + v12 OAuth2 HL API `/api.php`. | Python/Werkzeug + Vue 3 SPA; DocType = table `tab<Name>` + controller `.py`; **MariaDB** (Postgres backend exists but raw backticked SQL ⇒ not prod-validated); Redis + RQ workers + scheduler + socketio. **Python 3.14 / Frappe 16.** | FastAPI (`main.py`, app on :4000); **Postgres, one DB per tenant** (`grc_{slug}`); **no Alembic dir** — tables via `create_all` + hand-written self-heal migrations; Celery beat for hourly connector sync (prod use UNVERIFIED). |

### 3. Core domain model
| GLPI | Frappe | AVA |
|---|---|---|
| `glpi_tickets`: `status`(int), `urgency`/`impact`/`priority`, `itilcategories_id`, `type`(1 incident/2 request), **`externalid varchar(255)`**. Actors in junction tables (`REQUESTER=1/ASSIGN=2/OBSERVER=3`). Assets via `glpi_items_tickets` (`Item_Ticket`, UNIQUE). Timeline: `ITILFollowup/ITILSolution/TicketTask/TicketValidation`. SLA: `SLM/SLA/SlaLevel`. | `HD Ticket` (42 fields, no child tables): `subject`, `description`, `status`(Link), `priority`(Link), `ticket_type`, `agent_group`(Link HD Team), `sla`, `response_by`/`resolution_by`, `agreement_status`. **No agent field** — assignee in framework `ToDo`/`_assign`. Conversation in core `Communication`. | `Vulnerability` (`_22_...py:53`): `vuln_id`(unique/tenant), `severity`, `cvss_score`, `cve_id`, `status`(default open), `due_date`, `assigned_to`, `template_fields`(JSON). `VulnTicketLink` (`_54_...py`) holds `external_ticket_id` + status + partial-unique live index. `VulnRemediationPlan` (recommended→approved→applied→verified). Assets = `ITAsset`/`grc_it_assets` + `VulnerabilityAssetLink`. |

### 4. Ticket lifecycle & state machine
| GLPI | Frappe | AVA |
|---|---|---|
| Status ints (`CommonITILObject.php:121`): **INCOMING=1, ASSIGNED=2, PLANNED=3, WAITING=4, SOLVED=5, CLOSED=6, APPROVAL=10**; **no "cancelled"**. Add assignee ⇒ auto INCOMING→ASSIGNED. Close via adding an `ITILSolution` (→SOLVED, or CLOSED if `autoclose_delay=0`); requester reject reopens. Priority derived from urgency×impact matrix. | Statuses **admin-defined**, categorised **Open / Paused / Resolved**. Seeds: Open(Open), Replied(Paused), Resolved, Closed. Logic in `HDTicket` controller (`before_validate`/`before_save`/`on_update`). Customer reply ⇒ reopen; agent reply ⇒ auto "Replied". `agreement_status` ∈ First Response Due/Resolution Due/Failed/Fulfilled/Paused. | `Vulnerability.status`: open, in_progress, resolved, accepted, false_positive, remediated, closed, verified, auto_closed_fixed. Plan status is a *separate* axis. Only `/verify` (human) or scanner sets `verified`. Ticket close must **not** flip the finding to verified (deliberate). |

### 5. Events & triggers
| GLPI | Frappe | AVA |
|---|---|---|
| Rich notification events (`new/update/solved/closed/validation/satisfaction…`); `RuleTicket` ONADD/ONUPDATE; CronTask (`closeticket` 12h, `slaticket` 5m, `queuedwebhook`, `mailgate`). **Webhooks: only `new`/`update`/`delete`** (no status-specific), HMAC-SHA256 over `body+timestamp`, header `X-GLPI-signature`; cron-delivered + retried. | `doc_events` in `hooks.py` (none on HD Ticket itself — logic in controller); schedulers `daily` (auto-close) + `hourly_long` (SLA refresh — **bypasses hooks**, so no webhook). Framework `Webhook` DocType: doc-event + condition + field map, **HMAC-SHA256 base64** `X-Frappe-Webhook-Signature`, retries if `max_retries≥1`. | `run_sync` triggered on-demand (`POST /connectors/{id}/sync`) or hourly `connectors.sync_all_active` (Celery beat). `SyncHistory` rows written by `run_inline_sync`. Flow A's push/sync run **only** from the manual itsm routes — no auto-push on finding creation. |

### 6. Feature inventory
| GLPI | Frappe | AVA |
|---|---|---|
| SLA/OLA + calendars + escalation levels, assignment (groups/techs/auto by entity), categories+templates, followups/tasks/solutions, multi-step approvals, KB/FAQ, email collector, self-service portal + Form builder, satisfaction survey, dashboards, Problem/Change, contracts, GraphQL. | SLA engine (per-priority response/resolution, business hours, holidays, pause-on-Paused), assignment rules + HD Team + agent availability tiers, ticket types/templates, canned responses, KB (HD Article), email ingestion (bounce-loop guarded), customer portal, agent desk, CSAT, dashboards, merge/split. | Remediation plans, exceptions (`PolicyException`), SLA (`routers/sla.py`), retests/escalations, CTEM `mobilise_finding` (in-platform owner+approval+notify, **does not use connectors**), scanner write-back. |

### 7. End-to-end business flow
| GLPI | Frappe | AVA |
|---|---|---|
| Create (portal/email/API/HL) → `prepareInputForAdd` fills defaults + runs `RuleTicket ONADD` → entity auto-assign → SLA applied → `post_addItem` raises `new` → work (followups/tasks) → `ITILSolution`→SOLVED → cron `closeticket` after delay → satisfaction. | Create (portal/email/REST) → controller sets priority/status/SLA/contact → framework wildcard `on_update` runs Assignment Rule → SLA clock + `agreement_status` → agent replies (Communication) → Resolved → daily auto-close → customer reply reopens → CSAT. | Finding exists → user clicks **Push to ITSM** (`ItsmPanel.tsx`) → `push_finding` builds `TicketRequest` → `create_ticket` → store `VulnTicketLink` → `sync-statuses` → on `resolved` advance plan to `applied`. **No status write-back to the finding; verification stays with scanner/retest.** |

### 8. Extensibility (add CVE/CVSS/asset/finding-id)
| GLPI | Frappe | AVA |
|---|---|---|
| No native CVE/CVSS columns. Options: embed in `content`+`externalid`, map CVE→category/tag, or **Fields plugin** (writing PHP ⇒ GPL/maintenance). Webhook payload is Twig-templatable. | **Custom Field / Customize Form = config, not source** → add `ava_finding_id`(Data, **unique**), `cve_id`, `cvss_score`, `asset` via `POST /api/resource/Custom Field`. Appears in REST automatically. **AGPL-safe** (config/data, not modified source). | New provider = `providers/<name>.py` (adapter + `META`) + one line in `registry._bootstrap`. `ProviderField(is_credential=…)` drives the admin modal; secrets Fernet-encrypted (`CONNECTOR_MASTER_KEY`). |

### 9. API surface
| GLPI | Frappe | AVA |
|---|---|---|
| Legacy `/apirest.php`: session token + `App-Token`, `{"input":{…}}`, **search by numeric searchOption ids** (status=12, external not listed), `range=` pagination, 206 partial. v12 HL `/api.php/v2.x/Assistance/Ticket`: **OAuth2 password grant** (client_credentials can't create tickets — no user), RSQL filter incl. `external_id`, `GLPI-Entity` header. **Gotcha: 200 ≠ applied** (re-GET to verify). | Generic DocType REST: `POST/GET/PUT/DELETE /api/resource/HD Ticket` (+ v2 `/api/v2/document/...`), token auth `Authorization: token <key>:<secret>`, `filters`/`or_filters`/`order_by`/`limit_start`/`limit_page_length`, `expand_links`. Custom fields auto-included. | `/connectors` CRUD + `/connectors/{id}/test|sync`; `/vuln-management/.../push-to-itsm`, `/itsm/connections/{id}/sync-statuses`, `/itsm-tickets`. Adapter calls external over `requests`, timeout 30. |

### 10. Multi-tenancy & permissions
| GLPI | Frappe | AVA |
|---|---|---|
| **Entities tree** (one DB); every ticket has `entities_id`; rights per-profile bitmask + `Profile_User`. Map **1 entity per AVA tenant**, non-recursive scoped service account, send `GLPI-Entity` every call. One instance serves all tenants. | **Site = DB-per-tenant** (mismatch with AVA). Either site-per-tenant (heavy: per-site migrate/backup/upgrade) **or** single site + **HD Team per tenant** + AVA-side filtering (weaker isolation; AVA must always pass the tenant filter). Dedicated service user, role Agent/Agent Manager — not System Manager. | Each tenant = its own Postgres DB; connection row lives in that DB. **No partition key for one shared external instance** — carry the external org/team/queue in `provider_config`, send on every call. |

### 11. Deployment & ops
| GLPI | Frappe | AVA |
|---|---|---|
| PHP-FPM + nginx/Apache + MariaDB; **cron `glpi:cron` mandatory** (SLA/mail/notifications/auto-close/webhooks all depend on it). Docker compose (php 8.4 + mariadb 11.8). Backup = DB + `files/` + `config/`. **Lighter, boring LAMP.** | **Full Bench stack** (MariaDB + Redis + RQ + scheduler + socketio + gunicorn), **Python 3.14 / Frappe 16**; `ghcr.io/frappe/helpdesk` / easy-install; `bench update/migrate` is **bench-wide**. **Heaviest option.** | `backend/Dockerfile` → `uvicorn main:app :4000`; prod `ava-backend` + `ava-worker` via systemd (from notes); `CONNECTOR_MASTER_KEY` must be set by hand. |

### 12. Integration into AVA (adapter mapping)
| | GLPI | Frappe |
|---|---|---|
| `test_connection` | `POST /api.php/token` → `GET .../Assistance/Ticket?limit=1` (+`GLPI-Entity`) | `GET /api/method/frappe.auth.get_logged_user` + read one `HD Ticket Status` |
| `create_ticket` | HL `POST /Assistance/Ticket` (name/content/urgency/impact/type/category/`external_id`) + `TeamMember` | `POST /api/v2/document/HD Ticket` (subject/description/priority/raised_by/agent_group + custom fields) |
| `update_ticket` | `PATCH /Assistance/Ticket/{id}`; comment via `Timeline/Followup` | `PUT /api/v2/document/HD Ticket/{name}` |
| `close_ticket` | `POST .../Timeline/Solution` (→SOLVED; avoid raw `status=6` PATCH) | `PUT` `status="Closed"` |
| `fetch_statuses` | `GET /Assistance/Ticket?filter=external_id==…` → read `status.id` | `GET /api/resource/HD Ticket?filters=[["ava_finding_id","in",[…]]]` |
| **severity→priority** | write urgency+impact (matrix derives priority); need `CHANGEPRIORITY` to set directly | map to HD Ticket Priority Link (Urgent/High/Medium/Low) — direct |
| **idempotency** | `external_id` filter — but column **not UNIQUE** (enforce client-side) | `ava_finding_id` custom field marked **unique** (DB-enforced) |
| **status→taxonomy** | 1→new, 2/3→in_progress, 4/10→on_hold, 5→resolved, 6→closed, (no cancelled) | category Open→new/in_progress, Paused→on_hold, Resolved→resolved, name "Closed"→closed, (add a status for cancelled) |
| **sync-back** | webhook `new/update/delete` only (read status.id) + poll fallback | webhook `on_update` (HMAC) + poll fallback (SLA job bypasses hooks) |

---

## Conflict map — "will we have conflicts afterwards?"

| Conflict surface | GLPI | Frappe | Mitigation |
|---|---|---|---|
| **Asset / CMDB vs AVA's `grc_it_assets`** | **Real** — GLPI owns a CMDB that duplicates AVA assets | **None** — no asset module | AVA stays source of truth; **never sync assets**; put host/IP as text in ticket body or a custom field. For GLPI: leave `Item_Ticket` unused + don't run the inventory agent. |
| **Second DB engine (MariaDB vs Postgres)** | Yes | Yes | Unavoidable; run the help desk as an **isolated container with its own DB**, reach it only via REST. |
| **License** | GPL-3.0 (HTTP client ⇒ AVA unaffected) | **AGPL-3.0** (safe only if run **unmodified** as a separate service; config-only custom fields are fine; forking/extending with code triggers source-offer) | Keep it unmodified; do all vuln logic AVA-side before POST; legal sign-off before SaaS GA. |
| **Tenancy** | Entities (one instance, per-tenant entity) — good fit | Site-per-tenant (heavy) or single-site+team (weaker) | Carry tenant partition in `provider_config`; one connection row per tenant DB. |
| **AVA Flow B auto-push** | Fires for both | Fires for both | Set `provider_config["push_cvss_threshold"]` very high **or** remove Flow B's finding branch; fix the `metadata_info`→`metadata_` crash first. |
| **Status write-back collision** | Both: ticket-close must not mark finding `verified` | same | Use **Flow A only**; only `resolved` advances the plan to `applied`; verification stays with scanner/retest. |

---

## Integration plan (whichever you pick — lazy path)

1. **Run the help desk as an isolated, unmodified sidecar** (own container + own MariaDB), reachable over HTTPS from the AVA backend/worker host.
2. **One adapter file** `backend/grc/modules/connectors/providers/<helpdesk>.py` subclassing `TicketingAdapter` + a module-level `META`, mirroring `servicenow.py`. Read `verify_ssl` from `self.config` (since `build_adapter` won't pass it).
3. **One registry line** — add the module path to `provider_modules` in `registry.py::_bootstrap`; `category="ticketing"`.
4. **Idempotency:** send `external_id = str(Vulnerability.id)`; **look up before create** (the base contract has no find-by-external-id). Frappe: mark `ava_finding_id` unique. GLPI: enforce client-side.
5. **Enrich** `_ticket_request` (`itsm_service.py:52`) to also send `cvss_score`, `cve_id`, `affected_host`, `recommendation` via `extra_fields`.
6. **Sync-back:** use Flow A's `sync-statuses` (reliable) + optional signed webhook as an optimization; map only `resolved` to plan-`applied`.
7. **Neutralise Flow B** before enabling: raise `push_cvss_threshold` or delete its finding branch, and fix the `PolicyException.metadata_` crash.
8. **No asset sync.** Host/IP goes in the ticket text or a custom field.

**Effort:** ~1 adapter (≈200 lines) + 1 registry line + custom-field setup on the help-desk side + the Flow-B fix. Same order of magnitude for both; Frappe's adapter is slightly simpler (direct fields, token auth, unique idempotency field).
