"""Broadcom Service Desk (CA Service Desk Manager / Clarity SM) adapter —
two-way vulnerability ticketing.

Pushes:
  * Vulnerabilities / exceptions → an Incident on the configured object
    (default the Incident area `in`).

Pulls back:
  * The configured status field + resolution for known request numbers
    (`ref_num`), normalised into our status taxonomy.

Auth is CA SDM's REST access-key flow:
  * `POST /caisd-rest/rest_access` (HTTP Basic: username + password) → a JSON
    body `{"rest_access": {"access_key": "...", "@id": N}}`.
  * Every subsequent call carries header `X-AccessKey: <access_key>`.
  * A 401 triggers one re-login + retry. Access keys time out server-side on
    their own, so there is no explicit logout.

CA SDM object/area names, the status field and its values, and the SREL
handles (priority, group, category) vary per instance, so they are
operator-configurable (see META) rather than hardcoded — mirroring the
BMC Helix adapter.

API reference: https://techdocs.broadcom.com/us/en/ca-enterprise-software/business-management/ca-service-management/17-3.html
"""
from __future__ import annotations

import logging
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

_HTTP_TIMEOUT = 30
_REST = "/caisd-rest"

# Our severity → CA SDM priority common name. CA SDM out-of-the-box priorities
# are 1 (highest) … 5 (lowest); the `priority` attribute is an SREL, so we send
# the common-name string and the operator can override the whole field via
# `extra_fields` when their instance names priorities differently.
_OUR_SEV_TO_CA_PRIORITY = {
    "critical": "1",
    "high": "2",
    "medium": "3",
    "low": "4",
}

# Default out-of-the-box CA SDM status symbols → our taxonomy. The
# operator-configured open/resolved/closed values are layered on top of this
# in `_normalise_status`, so a customised instance still maps correctly.
_DEFAULT_STATUS_NORMALISED = {
    "open": "new",
    "new": "new",
    "work in progress": "in_progress",
    "in progress": "in_progress",
    "wip": "in_progress",
    "hold": "on_hold",
    "pending": "on_hold",
    "awaiting": "on_hold",
    "resolved": "resolved",
    "closed": "closed",
    "cancelled": "cancelled",
    "canceled": "cancelled",
}

_DEFAULT_INCIDENT_OBJECT = "in"   # CA SDM REST area for Incidents
_DEFAULT_STATUS_FIELD = "status"
_DEFAULT_REF_FIELD = "ref_num"
_DEFAULT_RESOLUTION_FIELD = "resolution"


class BroadcomServiceDeskAdapter(TicketingAdapter):
    provider = "broadcom_service_desk"

    # ─── Config accessors ───────────────────────────────────────────

    def _object(self) -> str:
        return self.config.get("incident_object") or _DEFAULT_INCIDENT_OBJECT

    def _status_field(self) -> str:
        return self.config.get("status_field") or _DEFAULT_STATUS_FIELD

    def _ref_field(self) -> str:
        return self.config.get("ref_field") or _DEFAULT_REF_FIELD

    def _resolution_field(self) -> str:
        return self.config.get("resolution_field") or _DEFAULT_RESOLUTION_FIELD

    def _assignment_group(self, override: Optional[str]) -> Optional[str]:
        return override or self.config.get("assignment_group") or self.config.get("default_group")

    def _normalise_status(self, raw: Optional[str]) -> str:
        s = (raw or "").strip().lower()
        if not s:
            return "new"
        overrides = {
            (self.config.get("status_open") or "").strip().lower(): "new",
            (self.config.get("status_resolved") or "").strip().lower(): "resolved",
            (self.config.get("status_closed") or "").strip().lower(): "closed",
        }
        overrides.pop("", None)
        return overrides.get(s) or _DEFAULT_STATUS_NORMALISED.get(s, "new")

    # ─── Auth ───────────────────────────────────────────────────────

    def _login(self) -> str:
        token = self.oauth_tokens.get("access_key")
        if token:
            return token
        user = self.credentials.get("username")
        pwd = self.credentials.get("password")
        if not (user and pwd):
            raise RuntimeError("Broadcom Service Desk credentials missing username/password")
        resp = requests.post(
            f"{self.console_url}{_REST}/rest_access",
            auth=(user, pwd),
            headers={"Accept": "application/json", "Content-Type": "application/json"},
            json={"rest_access": {}},
            verify=self.verify_ssl,
            timeout=_HTTP_TIMEOUT,
        )
        if resp.status_code not in (200, 201):
            # Never echo the credentials; only the server's own reply.
            raise RuntimeError(
                f"Broadcom Service Desk login failed ({resp.status_code}): {resp.text[:200]}"
            )
        body = resp.json() if resp.text else {}
        key = (body.get("rest_access") or {}).get("access_key")
        if not key:
            raise RuntimeError("Broadcom Service Desk login returned no access_key")
        self.oauth_tokens["access_key"] = key
        return key

    def _request(self, method: str, path: str, **kwargs) -> requests.Response:
        """Issue an access-key'd request, re-logging-in + retrying once on 401."""
        url = f"{self.console_url}{_REST}{path}"
        headers = {"Accept": "application/json", "Content-Type": "application/json"}
        headers.update(kwargs.pop("headers", None) or {})
        kwargs.setdefault("timeout", _HTTP_TIMEOUT)
        kwargs.setdefault("verify", self.verify_ssl)

        resp: Optional[requests.Response] = None
        for attempt in (1, 2):
            headers["X-AccessKey"] = self._login()
            resp = requests.request(method, url, headers=headers, **kwargs)
            if resp.status_code == 401 and attempt == 1:
                self.oauth_tokens.pop("access_key", None)  # force re-login + retry
                continue
            return resp
        return resp  # type: ignore[return-value]

    # ─── BaseConnectorAdapter ───────────────────────────────────────

    def test_connection(self) -> ConnectionTestResult:
        try:
            key = self._login()
            return ConnectionTestResult(
                success=True,
                message="Authenticated to Broadcom Service Desk successfully.",
                details={"access_key_acquired": bool(key)},
            )
        except Exception as exc:
            logger.exception("Broadcom Service Desk test_connection failed")
            return ConnectionTestResult(success=False, message=str(exc))

    # ─── TicketingAdapter ───────────────────────────────────────────

    def create_ticket(self, request: TicketRequest) -> str:
        obj = self._object()
        ref_field = self._ref_field()
        values: Dict[str, Any] = {
            "summary": (request.summary or "")[:240],
            "description": request.description,
            "priority": _OUR_SEV_TO_CA_PRIORITY.get((request.severity or "").lower(), "3"),
        }
        status_open = self.config.get("status_open")
        if status_open:
            values["status"] = status_open
        category = self.config.get("default_category")
        if category:
            values["category"] = category
        ag = self._assignment_group(request.assignment_group)
        if ag:
            values["group"] = ag
        # Operator-supplied field overrides win (required fields + SREL handle
        # formats differ per instance).
        values.update(request.extra_fields or {})

        resp = self._request("POST", f"/{obj}", json={obj: values})
        if resp.status_code not in (200, 201):
            raise RuntimeError(
                f"Broadcom Service Desk create_ticket failed ({resp.status_code}): {resp.text[:300]}"
            )
        body = resp.json() if resp.text else {}
        rec = body.get(obj) or body
        number = rec.get(ref_field) or rec.get("id") or rec.get("persistent_id")
        if not number:
            raise RuntimeError("Broadcom Service Desk returned no ref_num / id")
        return str(number)

    def update_ticket(self, external_id: str, fields: Dict[str, Any]) -> bool:
        obj = self._object()
        # CA SDM REST updates an object by POSTing the changed attributes to its
        # ref_num-scoped URL.
        resp = self._request(
            "POST",
            f"/{obj}/{external_id}",
            json={obj: fields},
        )
        if resp.status_code in (200, 204):
            return True
        if resp.status_code == 404:
            logger.warning("Broadcom Service Desk update_ticket: %s not found", external_id)
            return False
        raise RuntimeError(
            f"Broadcom Service Desk update_ticket failed ({resp.status_code}): {resp.text[:300]}"
        )

    def close_ticket(self, external_id: str, resolution_note: str) -> bool:
        resolved = self.config.get("status_resolved") or "Resolved"
        return self.update_ticket(external_id, {
            self._status_field(): resolved,
            self._resolution_field(): resolution_note,
        })

    def fetch_statuses(self, external_ids: List[str]) -> List[TicketStatus]:
        if not external_ids:
            return []
        obj = self._object()
        ref_field = self._ref_field()
        status_field = self._status_field()
        resolution_field = self._resolution_field()
        results: List[TicketStatus] = []

        # One WHERE per ref_num keeps the query simple and instance-portable
        # (CA SDM WHERE clauses don't take an IN list of strings reliably).
        for ext in external_ids:
            resp = self._request(
                "GET",
                f"/{obj}",
                params={"WHERE": f"{ref_field} = '{_escape(ext)}'"},
            )
            if resp.status_code == 404:
                continue
            if resp.status_code != 200:
                raise RuntimeError(
                    f"Broadcom Service Desk fetch_statuses failed ({resp.status_code}): "
                    f"{resp.text[:300]}"
                )
            body = resp.json() if resp.text else {}
            # A collection comes back under the pluralised object key; be lenient.
            rows = body.get("collection", {}).get(obj) if isinstance(body.get("collection"), dict) else None
            if rows is None:
                rows = body.get(obj)
            for rec in _as_list(rows):
                raw_status = _sym(rec.get(status_field))
                results.append(TicketStatus(
                    external_id=str(rec.get(ref_field) or ext),
                    status=raw_status,
                    normalised_status=self._normalise_status(raw_status),
                    resolution_note=rec.get(resolution_field),
                    extra={status_field: raw_status},
                ))
        return results


def _escape(value: str) -> str:
    """Escape a value for a CA SDM WHERE clause (single-quote delimited)."""
    return str(value).replace("'", "''")


def _as_list(value: Any) -> List[Dict[str, Any]]:
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def _sym(value: Any) -> str:
    """CA SDM SREL attributes serialise as a nested object carrying a symbol
    (`@COMMON_NAME` / `name` / `sym`). Flatten to the display string."""
    if isinstance(value, dict):
        return str(value.get("@COMMON_NAME") or value.get("name") or value.get("sym") or "")
    return str(value or "")


META = ProviderMeta(
    provider="broadcom_service_desk",
    label="Broadcom Service Desk",
    category="ticketing",
    description="Two-way ticket sync with Broadcom Service Desk (CA SDM / Clarity SM). Push vulnerabilities as Incidents; resolutions sync back.",
    auth_method="basic",
    fields=[
        ProviderField(key="console_url", label="CA SDM REST base URL",
                      kind="url", placeholder="https://servicedesk.example.com:8050",
                      help_text="Base URL of your CA SDM REST endpoint (the host serving /caisd-rest).",
                      is_credential=False),
        ProviderField(key="username", label="Service account username",
                      kind="text", required=True),
        ProviderField(key="password", label="Service account password",
                      kind="password", required=True),
        ProviderField(key="incident_object", label="Incident object/area",
                      kind="text", required=False, placeholder=_DEFAULT_INCIDENT_OBJECT,
                      help_text="CA SDM REST object used for tickets. Default: in (Incident). Use cr for Requests.",
                      is_credential=False),
        ProviderField(key="default_group", label="Default assignment group",
                      kind="text", required=False,
                      help_text="Tickets without a per-request group fall back to this group's name.",
                      is_credential=False),
        ProviderField(key="default_category", label="Default category",
                      kind="text", required=False,
                      help_text="Category (area) name applied to created tickets, if your instance requires one.",
                      is_credential=False),
        ProviderField(key="status_open", label="Open status value",
                      kind="text", required=False, placeholder="Open",
                      help_text="Status symbol set on new tickets / treated as open. Default: Open.",
                      is_credential=False),
        ProviderField(key="status_resolved", label="Resolved status value",
                      kind="text", required=False, placeholder="Resolved",
                      help_text="Status symbol written when closing a ticket, mapped to 'resolved'. Default: Resolved.",
                      is_credential=False),
        ProviderField(key="status_closed", label="Closed status value",
                      kind="text", required=False, placeholder="Closed",
                      help_text="Status symbol mapped to 'closed' when syncing back. Default: Closed.",
                      is_credential=False),
        ProviderField(key="status_field", label="Status field name",
                      kind="text", required=False, placeholder=_DEFAULT_STATUS_FIELD,
                      help_text="Name of the status attribute on your instance. Default: status.",
                      is_credential=False),
        ProviderField(key="ref_field", label="Ticket number field name",
                      kind="text", required=False, placeholder=_DEFAULT_REF_FIELD,
                      help_text="Attribute holding the human ticket number used for sync-back queries. Default: ref_num.",
                      is_credential=False),
        ProviderField(key="resolution_field", label="Resolution field name",
                      kind="text", required=False, placeholder=_DEFAULT_RESOLUTION_FIELD,
                      help_text="Attribute holding the resolution note. Default: resolution.",
                      is_credential=False),
    ],
    adapter_cls=BroadcomServiceDeskAdapter,
    docs_url="https://techdocs.broadcom.com/us/en/ca-enterprise-software/business-management/ca-service-management/17-3.html",
)
