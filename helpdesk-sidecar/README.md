# helpdesk-sidecar — Frappe Helpdesk next to AVA

Frappe Helpdesk runs here as an **isolated, unmodified** service. AVA talks to it
**only over REST**, so AVA stays outside AGPL and owns all finding/asset data.
Nothing here is in AVA's Python process or database.

```
AVA backend ──REST (token auth)──▶ Frappe Helpdesk (:8000)
  providers/frappe_helpdesk.py        MariaDB + Redis (Docker named volumes)
```

## Prereq
Docker + Docker Compose (not installed on this machine yet). DB data lives in
Docker **named volumes**, never in this OneDrive folder.

## 1. Run Frappe
```bash
cd helpdesk-sidecar
docker compose up -d        # first boot builds the bench — several minutes
docker compose logs -f frappe   # wait for "helpdesk.localhost" to be serving
```
Open http://helpdesk.localhost:8000 (Administrator / admin).

> Version note: `init.sh` defaults to `frappe/helpdesk` **version-15**. If a branch
> is missing for your pull, set `FRAPPE_BRANCH`/`HELPDESK_BRANCH` in `.env`, or use
> Frappe's official `easy-install.py` which pins a matching set automatically.

## 2. Wire it for AVA (service user, API key, custom fields, teams)
```bash
bash setup/configure_ava.sh ava demo acme   # one HD Team per tenant slug
```
Copy the printed **api_key** / **api_secret**.

## 3. Connect AVA
AVA already ships the provider: `backend/grc/modules/connectors/providers/frappe_helpdesk.py`
(registered in `registry.py`). In AVA, per tenant, add a **Frappe Helpdesk** connector:

| Field | Value |
|---|---|
| Base URL | `http://host.docker.internal:8000` (or the sidecar host:8000) |
| API Key / Secret | from step 2 |
| Team (agent_group) | the tenant's HD Team |
| AVA tenant | tenant slug |

Then **Push to ITSM** on a finding → a `HD Ticket` is created; **Sync statuses**
pulls status back. Re-pushing the same finding is a no-op (unique `ava_finding_id`).

## Before enabling (AVA-side fixes — see FRAPPE_INTEGRATION_PLAN.md §7)
- Neutralise the hourly Flow-B auto-push (`push_cvss_threshold` or drop its branch).
- Fix `sync_runner.py:189` `e.metadata_info` → `metadata_` crash.

## Teardown
```bash
docker compose down         # keep data
docker compose down -v      # wipe the MariaDB + bench volumes
```
