"""Broadcom Service Desk (CA Service Desk Manager / Clarity SM) adapter —
two-way vulnerability ticketing.

Pushes:   vulnerabilities / exceptions → an Incident (REST object ``in``).
Pulls:    status (+ optional resolution text) for known ticket numbers,
          normalised into our status taxonomy.
Resolves: closing writes the resolved status and logs the resolution note as an
          activity-log comment (``alg``, type LOG) on the ticket.

Wire contract and auth live in ``_ca_sdm`` (shared with Broadcom CMDB).
Object name, status values, group/category names and the affected end user
vary per instance, so they are operator-configurable (see META).
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional

from ..base import ConnectionTestResult, TicketingAdapter, TicketRequest, TicketStatus
from ..registry import ProviderField, ProviderMeta
from ._ca_sdm import CaSdmRestMixin, as_list, cn_path, srel, sym, wc_quote

logger = logging.getLogger(__name__)

# Our severity → CA SDM out-of-the-box priority (COMMON_NAME "1" highest … "5").
_OUR_SEV_TO_CA_PRIORITY = {"critical": "1", "high": "2", "medium": "3", "low": "4", "info": "5"}

# Out-of-the-box CA SDM status COMMON_NAMEs → our taxonomy. Operator-configured
# open/resolved/closed values are layered on top in `_normalise_status`.
_DEFAULT_STATUS_NORMALISED = {
    "open": "new", "new": "new",
    "acknowledged": "in_progress", "work in progress": "in_progress", "in progress": "in_progress",
    "researching": "in_progress", "wip": "in_progress",
    "hold": "on_hold", "pending": "on_hold", "awaiting end user response": "on_hold",
    "resolved": "resolved", "problem-fixed": "resolved", "avoided": "resolved",
    "closed": "closed", "closed-unresolved": "closed",
    "cancelled": "cancelled", "canceled": "cancelled",
}

_DEFAULT_OBJECT = "in"
_STATUS_BATCH = 25


class BroadcomServiceDeskAdapter(CaSdmRestMixin, TicketingAdapter):
    provider = "broadcom_service_desk"
    product_label = "Broadcom Service Desk"

    # ─── Config ─────────────────────────────────────────────────────

    def _object(self) -> str:
        return (self.config.get("incident_object") or _DEFAULT_OBJECT).strip()

    def _status_field(self) -> str:
        return (self.config.get("status_field") or "status").strip()

    def _ref_field(self) -> str:
        return (self.config.get("ref_field") or "ref_num").strip()

    def _resolution_field(self) -> Optional[str]:
        return (self.config.get("resolution_field") or "").strip() or None

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
        return overrides.get(s) or _DEFAULT_STATUS_NORMALISED.get(s, "in_progress")

    def _customer_ref(self) -> Dict[str, str]:
        """Affected end user (mandatory on CA SDM incidents) as an SREL by
        contact id. Defaults to the integration service account's own contact."""
        cached = self.oauth_tokens.get("customer_id")
        if cached:
            return {"@id": cached}
        userid = (self.config.get("customer_userid") or self.credentials.get("username") or "").strip()
        rows, _ = self._collection("cnt", attrs=["userid"], wc=f"userid='{wc_quote(userid)}'", size=1)
        if not rows or not rows[0].get("@id"):
            raise RuntimeError(
                f"Broadcom Service Desk: no contact with userid '{userid}' — set 'Affected end user' to a valid userid")
        self.oauth_tokens["customer_id"] = str(rows[0]["@id"])
        return {"@id": self.oauth_tokens["customer_id"]}

    # ─── Connection test: auth + read tickets + resolve the end user ─

    def test_connection(self) -> ConnectionTestResult:
        try:
            read = self._test_read(self._object())
            self._customer_ref()
            return ConnectionTestResult(
                success=True,
                message=(f"Connected to Broadcom Service Desk: authenticated, read access to "
                         f"'{read['object']}' ({read['total_records'] if read['total_records'] is not None else '?'} records), "
                         f"affected end user resolved."),
                details=read,
            )
        except Exception as exc:  # noqa: BLE001 — surface the reason to the operator
            logger.warning("Broadcom Service Desk test_connection failed: %s", exc)
            return ConnectionTestResult(success=False, message=str(exc))

    # ─── TicketingAdapter ───────────────────────────────────────────

    def create_ticket(self, request: TicketRequest) -> str:
        obj = self._object()
        values: Dict[str, Any] = {
            "summary": (request.summary or "")[:240],
            "description": request.description or "",
            "priority": srel(_OUR_SEV_TO_CA_PRIORITY.get((request.severity or "").lower(), "3")),
            "customer": self._customer_ref(),
        }
        if self.config.get("status_open"):
            values[self._status_field()] = srel(self.config["status_open"])
        if self.config.get("default_category"):
            values["category"] = srel(self.config["default_category"])
        group = request.assignment_group or self.config.get("default_group")
        if group:
            values["group"] = srel(group)
        values.update(request.extra_fields or {})   # operator overrides win

        resp = self._request("POST", f"/{obj}", attrs=[self._ref_field()], json={obj: values})
        if resp.status_code not in (200, 201):
            raise RuntimeError(f"Broadcom Service Desk create_ticket failed ({resp.status_code}): {resp.text[:300]}")
        rec = (resp.json() if resp.text else {}).get(obj) or {}
        number = rec.get(self._ref_field()) or rec.get("@COMMON_NAME")
        if not number:
            raise RuntimeError("Broadcom Service Desk returned no ticket number")
        return str(number)

    def update_ticket(self, external_id: str, fields: Dict[str, Any]) -> bool:
        return self._put(external_id, fields) is not None

    def _put(self, external_id: str, fields: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        obj = self._object()
        resp = self._request("PUT", cn_path(obj, external_id), json={obj: fields})
        if resp.status_code in (200, 204):
            return (resp.json() if resp.text else {}).get(obj) or {}
        if resp.status_code == 404:
            logger.warning("Broadcom Service Desk: ticket %s not found", external_id)
            return None
        raise RuntimeError(f"Broadcom Service Desk update_ticket failed ({resp.status_code}): {resp.text[:300]}")

    def close_ticket(self, external_id: str, resolution_note: str) -> bool:
        fields: Dict[str, Any] = {self._status_field(): srel(self.config.get("status_resolved") or "Resolved")}
        if self._resolution_field():
            fields[self._resolution_field()] = resolution_note
        rec = self._put(external_id, fields)
        if rec is None:
            return False
        if resolution_note and rec.get("@id"):
            self._log_comment(rec["@id"], resolution_note)
        return True

    def _log_comment(self, ticket_id: str, text: str) -> None:
        """Best-effort activity-log comment; the status change already landed."""
        try:
            resp = self._request("POST", "/alg", json={"alg": {
                "call_req_id": {"@id": str(ticket_id)}, "type": {"@REL_ATTR": "LOG"},
                "description": text[:4000]}})
            if resp.status_code not in (200, 201):
                logger.warning("Broadcom Service Desk: resolution comment not logged (%s)", resp.status_code)
        except Exception:  # noqa: BLE001
            logger.warning("Broadcom Service Desk: resolution comment not logged", exc_info=True)

    def fetch_statuses(self, external_ids: List[str]) -> List[TicketStatus]:
        ids = [str(x) for x in external_ids if x]
        if not ids:
            return []
        obj, ref_f, st_f, res_f = self._object(), self._ref_field(), self._status_field(), self._resolution_field()
        attrs = [ref_f, st_f] + ([res_f] if res_f else [])
        out: List[TicketStatus] = []
        for i in range(0, len(ids), _STATUS_BATCH):
            chunk = ids[i:i + _STATUS_BATCH]
            wc = " OR ".join(f"{ref_f}='{wc_quote(x)}'" for x in chunk)
            rows, _ = self._collection(obj, attrs=attrs, wc=wc, size=len(chunk))
            for rec in as_list(rows):
                raw = sym(rec.get(st_f))
                out.append(TicketStatus(
                    external_id=str(rec.get(ref_f) or rec.get("@COMMON_NAME") or ""),
                    status=raw, normalised_status=self._normalise_status(raw),
                    resolution_note=(sym(rec.get(res_f)) or None) if res_f else None,
                    extra={st_f: raw},
                ))
        return out


def _f(key, label, **kw) -> ProviderField:
    kw.setdefault("is_credential", False)
    kw.setdefault("required", False)
    kw.setdefault("kind", "text")
    return ProviderField(key=key, label=label, **kw)


META = ProviderMeta(
    provider="broadcom_service_desk",
    label="Broadcom Service Desk",
    category="ticketing",
    description="Two-way ticket sync with Broadcom Service Desk (CA SDM / Clarity SM). Push vulnerabilities as Incidents; status and resolutions sync back.",
    auth_method="basic",
    fields=[
        _f("console_url", "CA SDM REST base URL", kind="url", required=True,
           placeholder="https://servicedesk.example.com:8050",
           help_text="Host and port serving /caisd-rest (CA SDM REST Web Services, default port 8050)."),
        ProviderField(key="username", label="Service account username", kind="text", required=True),
        ProviderField(key="password", label="Service account password", kind="password", required=True),
        _f("customer_userid", "Affected end user (userid)",
           help_text="Contact set as the incident's affected end user (mandatory in CA SDM). Defaults to the service account."),
        _f("incident_object", "Ticket object", placeholder=_DEFAULT_OBJECT,
           help_text="REST object for tickets: in (Incident, default), cr (Request), pr (Problem)."),
        _f("default_group", "Default assignment group", help_text="Group name (as shown in CA SDM) for new tickets."),
        _f("default_category", "Default category", help_text="Incident area / category name, e.g. Security.Vulnerability."),
        _f("status_open", "Open status", placeholder="Open", help_text="Status name set on new tickets. Blank = CA SDM default."),
        _f("status_resolved", "Resolved status", placeholder="Resolved", help_text="Status name written when CAIVA resolves a ticket."),
        _f("status_closed", "Closed status", placeholder="Closed", help_text="Status name read back as closed."),
        _f("status_field", "Status attribute", placeholder="status"),
        _f("ref_field", "Ticket number attribute", placeholder="ref_num"),
        _f("resolution_field", "Resolution text attribute",
           help_text="Optional custom attribute that holds resolution text. The note is always logged as an activity comment."),
    ],
    adapter_cls=BroadcomServiceDeskAdapter,
    docs_url="https://techdocs.broadcom.com/us/en/ca-enterprise-software/business-management/ca-service-management/17-3.html",
)
