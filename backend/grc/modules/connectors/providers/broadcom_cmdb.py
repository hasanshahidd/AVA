"""Broadcom CMDB (CA Service Desk Manager / CA CMDB) adapter — asset import.

Pulls Configuration Items from the CA CMDB REST object ``nr``, normalised into
``ConfigurationItem`` records that the connector sync matches onto CAIVA assets
(serial → MAC → FQDN → hostname → IP → name). Optionally (``push_assets``)
creates CAIVA assets missing from the CMDB as CIs — off by default because it
writes to the customer's CMDB.

Attribute names are the CA CMDB common attributes (CMDB Tech Ref "Common
Attributes"): hostname is ``system_name``, the hardware IP address is
``alarm_id``, and ``class`` / ``family`` / ``manufacturer`` / ``model`` /
``location`` / ``status`` are SRELs read through ``@COMMON_NAME``. Each mapping
can be overridden per instance (``<field>_attr`` in provider_config).
"""
from __future__ import annotations

import logging
from datetime import datetime
from typing import Any, Dict, List, Optional

from ..base import CmdbAdapter, ConfigurationItem, ConnectionTestResult
from ..registry import ProviderField, ProviderMeta
from ._ca_sdm import CaSdmRestMixin, sym, srel

logger = logging.getLogger(__name__)

_DEFAULT_CI_OBJECT = "nr"
_DEFAULT_FILTER = "delete_flag=0"     # active records only
_DEFAULT_PUSH_CLASS = "Discovered Hardware"
_PAGE_SIZE = 100

# ConfigurationItem field → CA CMDB attribute.
_DEFAULT_ATTR_MAP = {
    "name": "name",
    "host_name": "system_name",
    "fqdn": "dns_name",
    "ip_address": "alarm_id",
    "mac_address": "mac_address",
    "serial_number": "serial_number",
    "manufacturer": "manufacturer",
    "model": "model",
    "location": "location",
    "ci_type": "class",
    "status": "status",
}
_OPTIONAL_FIELDS = ("os_name",)  # no common attribute; read only when mapped


class BroadcomCmdbAdapter(CaSdmRestMixin, CmdbAdapter):
    provider = "broadcom_cmdb"
    product_label = "Broadcom CMDB"

    def _ci_object(self) -> str:
        return (self.config.get("ci_object") or _DEFAULT_CI_OBJECT).strip()

    def _attr(self, field: str) -> Optional[str]:
        override = (self.config.get(f"{field}_attr") or "").strip()
        return override or _DEFAULT_ATTR_MAP.get(field)

    def _attr_map(self) -> Dict[str, str]:
        fields = list(_DEFAULT_ATTR_MAP) + [f for f in _OPTIONAL_FIELDS if self._attr(f)]
        return {f: self._attr(f) for f in fields}  # type: ignore[misc]

    def _filter(self) -> Optional[str]:
        raw = self.config.get("ci_filter")
        return _DEFAULT_FILTER if raw is None else (raw.strip() or None)

    def test_connection(self) -> ConnectionTestResult:
        try:
            read = self._test_read(self._ci_object())
            return ConnectionTestResult(
                success=True,
                message=(f"Connected to Broadcom CMDB: authenticated, read access to "
                         f"'{read['object']}' ({read['total_records'] if read['total_records'] is not None else '?'} CIs)."),
                details=read,
            )
        except Exception as exc:  # noqa: BLE001
            logger.warning("Broadcom CMDB test_connection failed: %s", exc)
            return ConnectionTestResult(success=False, message=str(exc))

    def fetch_cis(self, *, since: Optional[datetime] = None, limit: int = 5000) -> List[ConfigurationItem]:
        obj, amap, wc = self._ci_object(), self._attr_map(), self._filter()
        attrs = sorted(set(amap.values()))
        cis: List[ConfigurationItem] = []
        start = 1
        while True:
            rows, total = self._collection(obj, attrs=attrs, wc=wc, start=start, size=_PAGE_SIZE)
            cis.extend(self._to_ci(r, amap) for r in rows)
            start += len(rows)
            # Stop on an empty page or once past @TOTAL_COUNT. A short page alone is not
            # the end: servers may cap `size` below what we asked for.
            if not rows or (total is not None and start > total) or (total is None and len(rows) < _PAGE_SIZE):
                break
            if len(cis) >= limit:
                logger.warning("Broadcom CMDB: import capped at %d CIs (CMDB reports %s)", limit, total)
                break
        return cis[:limit]

    @staticmethod
    def _to_ci(rec: Dict[str, Any], amap: Dict[str, str]) -> ConfigurationItem:
        def g(field: str) -> Optional[str]:
            col = amap.get(field)
            return (sym(rec.get(col)) or None) if col else None
        name = g("name") or sym(rec.get("@COMMON_NAME")) or g("host_name") or g("serial_number") or ""
        return ConfigurationItem(
            source_id=str(rec.get("@id") or rec.get("id") or name),
            name=name, ci_type=g("ci_type"), host_name=g("host_name"), fqdn=g("fqdn"),
            ip_address=g("ip_address"), mac_address=g("mac_address"), serial_number=g("serial_number"),
            manufacturer=g("manufacturer"), model=g("model"), os_name=g("os_name"),
            location=g("location"), status=g("status"), raw=rec,
        )

    def push_ci(self, asset: Any) -> Optional[str]:
        """Create one CAIVA asset as a CI; returns the new CI's @id. Only plain
        attributes are written (SREL manufacturer/model are not guessed)."""
        obj = self._ci_object()
        values: Dict[str, Any] = {
            self._attr("name"): getattr(asset, "name", None),
            self._attr("ci_type"): srel((self.config.get("push_class") or _DEFAULT_PUSH_CLASS).strip()),
        }
        for field, col in (("host_name", "host_name"), ("fqdn", "fqdn"), ("ip_address", "ip_address"),
                           ("mac_address", "primary_mac"), ("serial_number", "serial_number")):
            v = getattr(asset, col, None)
            if v:
                values[self._attr(field)] = v
        resp = self._request("POST", f"/{obj}", attrs=["name"], json={obj: values})
        if resp.status_code not in (200, 201):
            raise RuntimeError(f"Broadcom CMDB push_ci failed ({resp.status_code}): {resp.text[:300]}")
        rec = (resp.json() if resp.text else {}).get(obj) or {}
        return str(rec.get("@id") or "") or None


def _f(key, label, **kw) -> ProviderField:
    kw.setdefault("is_credential", False)
    kw.setdefault("required", False)
    kw.setdefault("kind", "text")
    return ProviderField(key=key, label=label, **kw)


META = ProviderMeta(
    provider="broadcom_cmdb",
    label="Broadcom CMDB",
    category="cmdb",
    description="Import Configuration Items from Broadcom CMDB (CA SDM / CA CMDB) into your asset inventory. Matches on serial, MAC, hostname and IP. Optional push-back of assets missing from the CMDB.",
    auth_method="basic",
    fields=[
        _f("console_url", "CA SDM REST base URL", kind="url", required=True,
           placeholder="https://servicedesk.example.com:8050",
           help_text="Host and port serving /caisd-rest (CA SDM REST Web Services, default port 8050)."),
        ProviderField(key="username", label="Service account username", kind="text", required=True),
        ProviderField(key="password", label="Service account password", kind="password", required=True),
        _f("ci_object", "CI object", placeholder=_DEFAULT_CI_OBJECT, help_text="REST object for Configuration Items. Default: nr."),
        _f("ci_filter", "CI filter (where clause)", placeholder=_DEFAULT_FILTER,
           help_text="CA SDM where clause limiting which CIs are imported, e.g. delete_flag=0 AND is_ci=1. Default: active records."),
        _f("host_name_attr", "Hostname attribute", placeholder="system_name"),
        _f("ip_address_attr", "IP address attribute", placeholder="alarm_id",
           help_text="CA CMDB stores the hardware IP in alarm_id. Override if your extension uses another attribute."),
        _f("os_name_attr", "Operating system attribute", help_text="Optional attribute (e.g. from a family extension) holding the OS."),
        _f("push_assets", "Push CAIVA assets back as CIs", kind="toggle",
           help_text="Off by default. When on, assets not yet in the CMDB are created as CIs on each sync. Writes to your CMDB."),
        _f("push_class", "Class for pushed CIs", placeholder=_DEFAULT_PUSH_CLASS,
           help_text="CI class name used when pushing assets. Default: Discovered Hardware."),
    ],
    adapter_cls=BroadcomCmdbAdapter,
    docs_url="https://techdocs.broadcom.com/us/en/ca-enterprise-software/business-management/ca-service-management/17-3.html",
)
