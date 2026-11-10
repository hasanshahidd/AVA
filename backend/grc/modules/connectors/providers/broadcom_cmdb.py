"""Broadcom CMDB (CA Service Desk Manager / CA CMDB) adapter — asset import.

Pulls:
  * Configuration Items (CIs) from the CA CMDB REST object (default `nr`),
    normalised into `ConfigurationItem` records that the connector sync maps
    onto CAIVA assets (match on serial / MAC / FQDN / hostname / IP / name).

Pushes (optional, gated by provider_config `push_assets`):
  * CAIVA assets back to the CMDB as CIs. Off by default — enabling it writes
    to the customer's CMDB, so it is a deliberate opt-in.

Auth is CA SDM's REST access-key flow, identical to the Broadcom Service Desk
adapter:
  * `POST /caisd-rest/rest_access` (HTTP Basic) → `{"rest_access":{"access_key":...}}`.
  * Every call carries header `X-AccessKey: <access_key>`; a 401 re-logs-in once.

CI attribute names and the CI object/area vary per instance, so they are
operator-configurable (see META). All network calls stay behind `_request`.

API reference: https://techdocs.broadcom.com/us/en/ca-enterprise-software/business-management/ca-service-management/17-3.html
"""
from __future__ import annotations

import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

import requests

from ..base import CmdbAdapter, ConfigurationItem, ConnectionTestResult
from ..registry import ProviderField, ProviderMeta

logger = logging.getLogger(__name__)

_HTTP_TIMEOUT = 30
_REST = "/caisd-rest"
_DEFAULT_CI_OBJECT = "nr"          # CA CMDB REST area for Configuration Items
_PAGE_SIZE = 100

# CI attributes we read, by our ConfigurationItem field → CA SDM `nr` attribute.
# Operators can override any of these via provider_config (same keys, suffixed
# `_attr`) when their CMDB extension renames an attribute.
_DEFAULT_ATTR_MAP = {
    "name": "name",
    "host_name": "dns_name",
    "ip_address": "ip_address",
    "mac_address": "mac_address",
    "serial_number": "serial_number",
    "manufacturer": "manufacturer_name",
    "model": "model_name",
    "os_name": "os_type",
    "location": "location",
    "ci_type": "class",
    "status": "ci_status",
}


class BroadcomCmdbAdapter(CmdbAdapter):
    provider = "broadcom_cmdb"

    # ─── Config accessors ───────────────────────────────────────────

    def _ci_object(self) -> str:
        return self.config.get("ci_object") or _DEFAULT_CI_OBJECT

    def _attr(self, field: str) -> str:
        return self.config.get(f"{field}_attr") or _DEFAULT_ATTR_MAP[field]

    # ─── Auth (CA SDM REST access key) ──────────────────────────────

    def _login(self) -> str:
        token = self.oauth_tokens.get("access_key")
        if token:
            return token
        user = self.credentials.get("username")
        pwd = self.credentials.get("password")
        if not (user and pwd):
            raise RuntimeError("Broadcom CMDB credentials missing username/password")
        resp = requests.post(
            f"{self.console_url}{_REST}/rest_access",
            auth=(user, pwd),
            headers={"Accept": "application/json", "Content-Type": "application/json"},
            json={"rest_access": {}},
            verify=self.verify_ssl,
            timeout=_HTTP_TIMEOUT,
        )
        if resp.status_code not in (200, 201):
            raise RuntimeError(
                f"Broadcom CMDB login failed ({resp.status_code}): {resp.text[:200]}"
            )
        body = resp.json() if resp.text else {}
        key = (body.get("rest_access") or {}).get("access_key")
        if not key:
            raise RuntimeError("Broadcom CMDB login returned no access_key")
        self.oauth_tokens["access_key"] = key
        return key

    def _request(self, method: str, path: str, **kwargs) -> requests.Response:
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
                self.oauth_tokens.pop("access_key", None)
                continue
            return resp
        return resp  # type: ignore[return-value]

    # ─── BaseConnectorAdapter ───────────────────────────────────────

    def test_connection(self) -> ConnectionTestResult:
        try:
            key = self._login()
            return ConnectionTestResult(
                success=True,
                message="Authenticated to Broadcom CMDB successfully.",
                details={"access_key_acquired": bool(key)},
            )
        except Exception as exc:
            logger.exception("Broadcom CMDB test_connection failed")
            return ConnectionTestResult(success=False, message=str(exc))

    # ─── CmdbAdapter ────────────────────────────────────────────────

    def fetch_cis(self, *, since: Optional[datetime] = None, limit: int = 5000) -> List[ConfigurationItem]:
        obj = self._ci_object()
        attrs = [self._attr(f) for f in _DEFAULT_ATTR_MAP]
        cis: List[ConfigurationItem] = []
        start = 1
        while len(cis) < limit:
            resp = self._request(
                "GET",
                f"/{obj}",
                headers={"X-Obj-Attrs": ",".join(attrs)},
                params={"start": str(start), "count": str(_PAGE_SIZE)},
            )
            if resp.status_code != 200:
                raise RuntimeError(
                    f"Broadcom CMDB fetch_cis failed ({resp.status_code}): {resp.text[:300]}"
                )
            body = resp.json() if resp.text else {}
            coll = body.get("collection") if isinstance(body.get("collection"), dict) else body
            rows = _as_list((coll or {}).get(obj))
            if not rows:
                break
            for rec in rows:
                cis.append(self._to_ci(rec))
            if len(rows) < _PAGE_SIZE:
                break
            start += _PAGE_SIZE
        return cis

    def _to_ci(self, rec: Dict[str, Any]) -> ConfigurationItem:
        def g(field: str) -> Optional[str]:
            val = rec.get(self._attr(field))
            flat = _sym(val)
            return flat or None
        name = g("name") or g("host_name") or g("serial_number") or ""
        return ConfigurationItem(
            source_id=str(rec.get("id") or rec.get("persistent_id") or g("name") or ""),
            name=name,
            ci_type=g("ci_type"),
            host_name=g("host_name"),
            ip_address=g("ip_address"),
            mac_address=g("mac_address"),
            serial_number=g("serial_number"),
            manufacturer=g("manufacturer"),
            model=g("model"),
            os_name=g("os_name"),
            location=g("location"),
            status=g("status"),
            raw=rec,
        )

    def push_ci(self, asset: Any) -> Optional[str]:
        """Push one CAIVA asset to the CMDB as a CI. Returns the created CI's id.
        Only called by the sync when `push_assets` is enabled."""
        obj = self._ci_object()
        values: Dict[str, Any] = {self._attr("name"): getattr(asset, "name", None)}
        for field, col in (("host_name", "host_name"), ("ip_address", "ip_address"),
                           ("mac_address", "primary_mac"), ("serial_number", "serial_number"),
                           ("manufacturer", "manufacturer"), ("model", "model")):
            v = getattr(asset, col, None)
            if v:
                values[self._attr(field)] = v
        resp = self._request("POST", f"/{obj}", json={obj: values})
        if resp.status_code not in (200, 201):
            raise RuntimeError(
                f"Broadcom CMDB push_ci failed ({resp.status_code}): {resp.text[:300]}"
            )
        body = resp.json() if resp.text else {}
        rec = body.get(obj) or body
        return str(rec.get("id") or rec.get("persistent_id") or rec.get(self._attr("name")) or "") or None


def _as_list(value: Any) -> List[Dict[str, Any]]:
    if value is None:
        return []
    return value if isinstance(value, list) else [value]


def _sym(value: Any) -> str:
    """CA SDM SREL attributes serialise as a nested object carrying a symbol.
    Flatten to the display string; plain scalars pass through."""
    if isinstance(value, dict):
        return str(value.get("@COMMON_NAME") or value.get("name") or value.get("sym") or "").strip()
    return str(value or "").strip()


META = ProviderMeta(
    provider="broadcom_cmdb",
    label="Broadcom CMDB",
    category="cmdb",
    description="Import Configuration Items from Broadcom CMDB (CA SDM / CA CMDB) into your asset inventory. Matches on serial / MAC / hostname / IP. Optional push-back.",
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
        ProviderField(key="ci_object", label="CI object/area",
                      kind="text", required=False, placeholder=_DEFAULT_CI_OBJECT,
                      help_text="CA CMDB REST object for Configuration Items. Default: nr.",
                      is_credential=False),
        ProviderField(key="ip_address_attr", label="IP address attribute",
                      kind="text", required=False, placeholder="ip_address",
                      help_text="CI attribute holding the IP address, if your CMDB extension renames it.",
                      is_credential=False),
        ProviderField(key="push_assets", label="Push CAIVA assets back as CIs",
                      kind="toggle", required=False,
                      help_text="Off by default. When on, assets not yet in the CMDB are created as CIs on each sync. Writes to your CMDB.",
                      is_credential=False),
    ],
    adapter_cls=BroadcomCmdbAdapter,
    docs_url="https://techdocs.broadcom.com/us/en/ca-enterprise-software/business-management/ca-service-management/17-3.html",
)
