# Frappe Helpdesk → AVA integration plan

**Goal:** add Frappe Helpdesk as a ticketing provider behind AVA's existing `TicketingAdapter` seam, with AVA as source of truth and no conflicts.
**Shape:** Frappe runs as an **isolated, unmodified** sidecar (own MariaDB + Redis); AVA talks to it only over REST. This keeps AVA outside AGPL. Effort ≈ **one adapter file + one registry line + custom-field setup + a small Flow-B fix.**

---

## 0. What NOT to do
- **Don't fork/modify Frappe or Helpdesk source.** Modifying AGPL code you then expose over a network triggers source-disclosure duties. Config-only changes (Custom Fields, Webhook, service user) are data, not modified source — safe.
- **Don't sync assets.** AVA owns assets (`grc_it_assets`). Frappe has no asset module — keep it that way; the affected host goes into the ticket as text/custom field.
- **Don't use both ticket stores.** Use Flow A (`VulnTicketLink`) only; neutralise Flow B (`template_fields["connector_tickets"]`).

---

## 1. Stand up Frappe Helpdesk (sidecar, unmodified)
- Deploy the official image `ghcr.io/frappe/helpdesk` (or `easy-install.py deploy`) in its own container/droplet with its own MariaDB + Redis. Reachable over HTTPS from the AVA backend/worker host (mind the droplet VPN routes).
- **One site, teams per tenant** (not site-per-tenant). Each AVA tenant → one `HD Team` (`agent_group`). Tenant isolation stays AVA's job: always send the tenant's `agent_group` on create and always filter by it on fetch.

## 2. One-time Frappe config (all via REST or UI — no source edits)
Create a **service user** (role *Agent Manager*, not System Manager), generate `api_key` + `api_secret`.

Add **Custom Fields** on `HD Ticket` (via Customize Form, or `POST /api/resource/Custom Field`):

| fieldname | type | notes |
|---|---|---|
| `ava_finding_id` | Data | **unique**, indexed — idempotency key = `str(Vulnerability.id)` |
| `ava_tenant` | Data | tenant slug — defence-in-depth filter |
| `cve_id` | Data | |
| `cvss_score` | Float | |
| `asset_host` | Data | host/IP as text (no CMDB) |

```bash
# example: create the unique idempotency field
curl -X POST "$FRAPPE/api/resource/Custom Field" \
  -H "Authorization: token $KEY:$SECRET" -H "Content-Type: application/json" \
  -d '{"dt":"HD Ticket","fieldname":"ava_finding_id","label":"AVA Finding ID","fieldtype":"Data","unique":1,"no_copy":1}'
```

(If you prefer it version-controlled: ship these as a `fixtures/custom_field.json` in a **separate** tiny Frappe app with its own license — but the UI/REST route is simpler and clearly AGPL-safe.)

## 3. The adapter — `backend/grc/modules/connectors/providers/frappe_helpdesk.py`
Mirrors `servicenow.py` against AVA's contract (`connectors/base.py`). Plain `requests`, token auth, lookup-before-create idempotency, `verify_ssl` read from config (since `build_adapter` doesn't pass it).

```python
"""Frappe Helpdesk adapter — vuln ticketing over the generic DocType REST API.

Push:  vulnerability -> HD Ticket (/api/resource/HD Ticket)
Pull:  status by ticket name -> normalised taxonomy
Auth:  Authorization: token <api_key>:<api_secret>
"""
from __future__ import annotations
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional
import json, requests

from ..base import ConnectionTestResult, TicketingAdapter, TicketRequest, TicketStatus
from ..registry import ProviderField, ProviderMeta

logger = logging.getLogger(__name__)

# severity -> HD Ticket Priority (seeded names). Confirm names at connect time.
_SEV_TO_PRIORITY = {"critical": "Urgent", "high": "High", "medium": "Medium",
                    "low": "Low", "info": "Low"}

# HD Ticket Status name -> AVA normalised taxonomy. Category fallback below.
_STATUS_NORMALISED = {"open": "new", "replied": "on_hold",
                      "resolved": "resolved", "closed": "closed"}
_CATEGORY_NORMALISED = {"Open": "new", "Paused": "on_hold", "Resolved": "resolved"}


class FrappeHelpdeskAdapter(TicketingAdapter):
    provider = "frappe_helpdesk"

    # ── helpers ──────────────────────────────────────────────
    def _hdrs(self) -> Dict[str, str]:
        key = self.credentials.get("api_key"); secret = self.credentials.get("api_secret")
        if not key or not secret:
            raise RuntimeError("Frappe credentials missing api_key/api_secret")
        return {"Authorization": f"token {key}:{secret}",
                "Accept": "application/json", "Content-Type": "application/json"}

    def _verify(self) -> bool:
        return bool(self.config.get("verify_ssl", self.verify_ssl))

    def _req(self, method: str, path: str, **kw) -> requests.Response:
        return requests.request(method, f"{self.console_url}{path}",
                                headers=self._hdrs(), verify=self._verify(), timeout=30, **kw)

    def _team(self, override: Optional[str]) -> Optional[str]:
        return override or self.config.get("agent_group")

    def _find_by_finding_id(self, ext: str) -> Optional[str]:
        f = json.dumps([["ava_finding_id", "=", ext]])
        r = self._req("GET", f'/api/resource/HD Ticket?filters={f}&fields=["name"]&limit_page_length=1')
        if r.status_code == 200 and r.json().get("data"):
            return r.json()["data"][0]["name"]
        return None

    # ── BaseConnectorAdapter ─────────────────────────────────
    def test_connection(self) -> ConnectionTestResult:
        try:
            r = self._req("GET", "/api/method/frappe.auth.get_logged_user")
            if r.status_code == 200:
                return ConnectionTestResult(True, "Authenticated to Frappe Helpdesk.",
                                            details={"user": r.json().get("message")})
            return ConnectionTestResult(False, f"Frappe returned {r.status_code}: {r.text[:200]}")
        except Exception as exc:
            logger.exception("frappe test_connection failed")
            return ConnectionTestResult(False, str(exc))

    # ── TicketingAdapter ─────────────────────────────────────
    def create_ticket(self, request: TicketRequest) -> str:
        existing = self._find_by_finding_id(request.external_id)   # idempotency
        if existing:
            return existing
        payload: Dict[str, Any] = {
            "subject": request.summary[:140],
            "description": request.description,
            "priority": _SEV_TO_PRIORITY.get(request.severity, "Medium"),
            "ava_finding_id": request.external_id,
            "ava_tenant": self.config.get("ava_tenant", ""),
            "cve_id": request.extra_fields.get("cve_id", ""),
            "cvss_score": request.extra_fields.get("cvss_score"),
            "asset_host": request.extra_fields.get("affected_host", ""),
        }
        if request.extra_fields.get("raised_by"):
            payload["raised_by"] = request.extra_fields["raised_by"]
        if self._team(request.assignment_group):
            payload["agent_group"] = self._team(request.assignment_group)
        if self.config.get("ticket_type"):
            payload["ticket_type"] = self.config["ticket_type"]
        r = self._req("POST", "/api/resource/HD Ticket", json=payload)
        if r.status_code not in (200, 201):
            raise RuntimeError(f"create_ticket failed {r.status_code}: {r.text[:300]}")
        return r.json()["data"]["name"]   # store as VulnTicketLink.external_ticket_id

    def update_ticket(self, external_id: str, fields: Dict[str, Any]) -> bool:
        r = self._req("PUT", f"/api/resource/HD Ticket/{external_id}", json=fields)
        return r.status_code == 200

    def close_ticket(self, external_id: str, resolution_note: str) -> bool:
        r = self._req("PUT", f"/api/resource/HD Ticket/{external_id}",
                      json={"status": "Closed", "resolution_details": resolution_note})
        return r.status_code == 200

    def fetch_statuses(self, external_ids: List[str]) -> List[TicketStatus]:
        if not external_ids:
            return []
        f = json.dumps([["name", "in", external_ids]])
        fields = json.dumps(["name", "status", "status_category", "modified", "resolution_date"])
        r = self._req("GET", f"/api/resource/HD Ticket?filters={f}&fields={fields}&limit_page_length=0")
        out: List[TicketStatus] = []
        for t in (r.json().get("data", []) if r.status_code == 200 else []):
            raw = t.get("status") or ""
            norm = _STATUS_NORMALISED.get(raw.lower()) \
                   or _CATEGORY_NORMALISED.get(t.get("status_category") or "", "in_progress")
            resolved = None
            if norm in ("resolved", "closed") and t.get("resolution_date"):
                resolved = datetime.fromisoformat(t["resolution_date"].replace(" ", "T"))
            out.append(TicketStatus(external_id=t["name"], status=raw, normalised_status=norm,
                                    resolved_at=resolved))
        return out


META = ProviderMeta(
    provider="frappe_helpdesk",
    label="Frappe Helpdesk",
    category="ticketing",
    description="Push vulnerabilities to Frappe Helpdesk tickets and sync status back.",
    auth_method="token",
    adapter_cls=FrappeHelpdeskAdapter,
    fields=[
        ProviderField("console_url", "Base URL", "url", required=True,
                      placeholder="https://helpdesk.example.com", is_credential=False),
        ProviderField("api_key", "API Key", "password", required=True, is_credential=True),
        ProviderField("api_secret", "API Secret", "password", required=True, is_credential=True),
        ProviderField("agent_group", "Team (agent_group) for this tenant", "text",
                      required=False, is_credential=False),
        ProviderField("ava_tenant", "AVA tenant slug", "text", required=False, is_credential=False),
        ProviderField("ticket_type", "Default ticket type", "text", required=False, is_credential=False),
        ProviderField("verify_ssl", "Verify TLS certificate", "toggle", required=False, is_credential=False),
    ],
)
```

## 4. Register it (one line)
In `backend/grc/modules/connectors/registry.py::_bootstrap`, add to `provider_modules`:
```python
"grc.modules.connectors.providers.frappe_helpdesk",
```

## 5. Enrich what AVA sends (optional but recommended)
In `services/itsm_service.py::_ticket_request` (~line 52), add to `extra_fields`:
`cve_id`, `cvss_score` (→ `vuln.cvss_score`), `affected_host`, and the top `recommendation` line. This is the one place to enrich; the adapter already reads these keys.

## 6. Status sync-back
- **Baseline (reliable):** the existing `POST /vuln-management/itsm/connections/{id}/sync-statuses` → `fetch_statuses`. Only `resolved` advances the `VulnRemediationPlan` to `applied`; verification stays with scanner/retest (unchanged behaviour).
- **Optional push:** a Frappe `Webhook` on `HD Ticket` `on_update`, HMAC-SHA256 (base64) `X-Frappe-Webhook-Signature`, POSTing `{name, status, status_category, ava_finding_id, modified}` to an AVA receiver. Make the receiver idempotent on `ava_finding_id`; keep the poll as the safety net (the hourly SLA job writes status via `db.set_value`, which **bypasses webhooks**).

## 7. Fix AVA-side issues before enabling the connection
1. **Neutralise Flow B** (`sync_runner._sync_ticketing`): set `provider_config["push_cvss_threshold"]` very high for this connection, **or** remove its finding-push branch so only Flow A (the Push-to-ITSM button) creates tickets.
2. **Fix the exception-branch crash:** `sync_runner.py:189` reads `e.metadata_info` but `PolicyException`'s attribute is `metadata_` — correct it (or exclude exceptions) so a pending `PolicyException` doesn't fail the whole sync.
3. Confirm `verify_ssl` reaches the adapter — handled here by reading `self.config["verify_ssl"]`; no `build_adapter` change needed.

## 8. Verify live (per AVA's live-fire standard)
Against a throwaway Frappe instance seeded with the custom fields:
1. `POST /connectors` with the Frappe provider → `test_connection` green.
2. Push one real finding (`push-to-itsm`) → assert an `HD Ticket` exists with the right `ava_finding_id`, priority, `agent_group`; re-push the same finding → **no duplicate** (unique field + lookup).
3. Move the ticket to Resolved in Frappe → `sync-statuses` → assert `VulnTicketLink.normalised_status="resolved"` and the plan advanced to `applied`.
4. Wrong-tenant fetch returns nothing (tickets scoped by `agent_group`/`ava_tenant`).

---

### Mapping summary
| AVA | Frappe HD Ticket |
|---|---|
| `Vulnerability.title` (+`vuln_id`) | `subject` |
| `description` | `description` |
| `severity` | `priority` (Urgent/High/Medium/Low) |
| `str(Vulnerability.id)` | `ava_finding_id` (unique) → stored back as `VulnTicketLink.external_ticket_id` = ticket `name` |
| tenant | `agent_group` + `ava_tenant` |
| `cve_id`/`cvss_score`/host | `cve_id`/`cvss_score`/`asset_host` custom fields |
| status (`fetch_statuses`) | HD Ticket `status`/`status_category` → new/in_progress/on_hold/resolved/closed |
