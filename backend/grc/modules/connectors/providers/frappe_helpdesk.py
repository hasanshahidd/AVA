"""Frappe Helpdesk adapter — vuln ticketing over the generic DocType REST API.

Push:  vulnerability -> HD Ticket (/api/resource/HD Ticket)
Pull:  status by ticket name -> normalised taxonomy
Auth:  Authorization: token <api_key>:<api_secret>

AVA stays source of truth. Frappe Helpdesk runs as an isolated, UNMODIFIED
sidecar (its own MariaDB/Redis) reached only over REST — see helpdesk-sidecar/.
No asset sync: the affected host rides along as a custom field, not a CMDB row.
"""
from __future__ import annotations

import json
import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

import requests

from ..base import (
    ConnectionTestResult,
    TicketingAdapter,
    TicketRequest,
    TicketStatus,
)
from ..registry import ProviderField, ProviderMeta

logger = logging.getLogger(__name__)

# severity -> HD Ticket Priority (seeded names). Confirm names at connect time
# with GET /api/resource/HD Ticket Priority if an instance renames them.
_SEV_TO_PRIORITY = {
    "critical": "Urgent",
    "high": "High",
    "medium": "Medium",
    "low": "Low",
    "info": "Low",
}

# HD Ticket Status *name* -> AVA normalised taxonomy (seeded names).
_STATUS_NORMALISED = {
    "open": "new",
    "replied": "on_hold",
    "resolved": "resolved",
    "closed": "closed",
}
# Fallback by HD Ticket Status *category* (stable: Open | Paused | Resolved).
_CATEGORY_NORMALISED = {"Open": "new", "Paused": "on_hold", "Resolved": "resolved"}


class FrappeHelpdeskAdapter(TicketingAdapter):
    provider = "frappe_helpdesk"

    # ─── helpers ─────────────────────────────────────────────────────
    def _hdrs(self) -> Dict[str, str]:
        key = self.credentials.get("api_key")
        secret = self.credentials.get("api_secret")
        if not key or not secret:
            raise RuntimeError("Frappe credentials missing api_key/api_secret")
        return {
            "Authorization": f"token {key}:{secret}",
            "Accept": "application/json",
            "Content-Type": "application/json",
        }

    def _verify(self) -> bool:
        # build_adapter() does not pass verify_ssl through, so read it from
        # provider_config (default True).
        return bool(self.config.get("verify_ssl", self.verify_ssl))

    def _req(self, method: str, path: str, **kw) -> requests.Response:
        return requests.request(
            method, f"{self.console_url}{path}",
            headers=self._hdrs(), verify=self._verify(), timeout=30, **kw,
        )

    def _team(self, override: Optional[str]) -> Optional[str]:
        return override or self.config.get("agent_group")

    def _team_exists(self, name: str) -> bool:
        """Does an HD Team with this name exist? Guards the partition-default
        below: linking a ticket to a non-existent team makes Frappe reject the
        whole create (Link validation), which would break the push."""
        try:
            r = self._req("GET", f"/api/resource/HD Team/{name}")
            return r.status_code == 200
        except Exception:
            return False

    def _find_by_finding_id(self, ext: str) -> Optional[str]:
        f = json.dumps([["ava_finding_id", "=", ext]])
        r = self._req(
            "GET",
            f'/api/resource/HD Ticket?filters={f}&fields=["name"]&limit_page_length=1',
        )
        if r.status_code == 200 and r.json().get("data"):
            return r.json()["data"][0]["name"]
        return None

    # ─── BaseConnectorAdapter ────────────────────────────────────────
    def test_connection(self) -> ConnectionTestResult:
        try:
            r = self._req("GET", "/api/method/frappe.auth.get_logged_user")
            if r.status_code == 200:
                return ConnectionTestResult(
                    success=True,
                    message="Authenticated to Frappe Helpdesk.",
                    details={"user": r.json().get("message")},
                )
            return ConnectionTestResult(
                success=False,
                message=f"Frappe returned {r.status_code}: {r.text[:200]}",
            )
        except Exception as exc:
            logger.exception("frappe_helpdesk test_connection failed")
            return ConnectionTestResult(success=False, message=str(exc))

    # ─── TicketingAdapter ────────────────────────────────────────────
    def create_ticket(self, request: TicketRequest) -> str:
        existing = self._find_by_finding_id(request.external_id)  # idempotency
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
        team = self._team(request.assignment_group)
        # ROOT-CAUSE FIX for assignment never firing: Frappe's assignment rule
        # keys on agent_group (e.g. "status=='Open' and agent_group=='ava'"), but
        # the platform-env push path sets no team, so agent_group stayed NULL and
        # the rule never matched -> tickets were never auto-assigned. By AVA
        # convention the tenant's team name IS its partition slug, so default
        # agent_group to the partition when a team of that name exists.
        if not team:
            part = self.config.get("ava_tenant")
            if part and self._team_exists(part):
                team = part
        if team:
            payload["agent_group"] = team
        if self.config.get("ticket_type"):
            payload["ticket_type"] = self.config["ticket_type"]
        r = self._req("POST", "/api/resource/HD Ticket", json=payload)
        if r.status_code not in (200, 201):
            raise RuntimeError(f"create_ticket failed {r.status_code}: {r.text[:300]}")
        return r.json()["data"]["name"]  # stored as VulnTicketLink.external_ticket_id

    def update_ticket(self, external_id: str, fields: Dict[str, Any]) -> bool:
        r = self._req("PUT", f"/api/resource/HD Ticket/{external_id}", json=fields)
        return r.status_code == 200

    def close_ticket(self, external_id: str, resolution_note: str) -> bool:
        r = self._req(
            "PUT",
            f"/api/resource/HD Ticket/{external_id}",
            json={"status": "Closed", "resolution_details": resolution_note},
        )
        return r.status_code == 200

    def fetch_statuses(self, external_ids: List[str]) -> List[TicketStatus]:
        if not external_ids:
            return []
        f = json.dumps([["name", "in", external_ids]])
        fields = json.dumps(
            ["name", "status", "status_category", "modified", "resolution_date"]
        )
        r = self._req(
            "GET",
            f"/api/resource/HD Ticket?filters={f}&fields={fields}&limit_page_length=0",
        )
        out: List[TicketStatus] = []
        rows = r.json().get("data", []) if r.status_code == 200 else []
        for t in rows:
            raw = t.get("status") or ""
            norm = _STATUS_NORMALISED.get(raw.lower()) or _CATEGORY_NORMALISED.get(
                t.get("status_category") or "", "in_progress"
            )
            resolved = None
            if norm in ("resolved", "closed") and t.get("resolution_date"):
                try:
                    resolved = datetime.fromisoformat(
                        str(t["resolution_date"]).replace(" ", "T")
                    )
                except ValueError:
                    resolved = None
            out.append(
                TicketStatus(
                    external_id=t["name"],
                    status=raw,
                    normalised_status=norm,
                    resolved_at=resolved,
                )
            )
        return out


META = ProviderMeta(
    provider="frappe_helpdesk",
    label="Frappe Helpdesk",
    category="ticketing",
    description="Internal AVA Help Desk engine (platform-managed, not customer-configurable).",
    auth_method="token",
    adapter_cls=FrappeHelpdeskAdapter,
    # AVA's own infrastructure — registered so the adapter resolves, but hidden
    # from the customer-facing connectors UI. Clients never see it or supply keys.
    internal=True,
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
