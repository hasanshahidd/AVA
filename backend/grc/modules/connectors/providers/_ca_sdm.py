"""Shared CA Service Desk Manager (Broadcom) REST client — used by the
Broadcom Service Desk and Broadcom CMDB adapters.

Wire contract (CA SDM REST Web Services, r12.9 / 17.x):
  * Login: ``POST /caisd-rest/rest_access`` with HTTP Basic → JSON
    ``{"rest_access": {"@id": ..., "access_key": 1534147117, ...}}``. The key is
    NUMERIC in the response; it is sent back as the ``X-AccessKey`` header string.
  * Reads return only ``@id`` / ``@REL_ATTR`` / ``@COMMON_NAME`` unless the
    ``X-Obj-Attrs`` header lists the attributes wanted.
  * Collections: ``GET /caisd-rest/<obj>?WC=<where>&start=<1-based>&size=<n>`` →
    ``{"collection_<obj>": {"@COUNT", "@START", "@TOTAL_COUNT", "<obj>": [...]}}``
    (a single row comes back as an object, not a list).
  * Create ``POST /<obj>``; update ``PUT /<obj>/<id>`` or ``/<obj>/COMMON_NAME-<cn>``.
  * SREL (reference) attributes are written as ``{"@COMMON_NAME": "..."}`` or
    ``{"@id": "..."}`` and read back as objects carrying ``@COMMON_NAME``.

Refs: techdocs.broadcom.com (CA SDM Tech Ref → REST), KB 212880 (create
incident), KB 10574 (create CI), KB 370088 (read CIs).
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional, Tuple
from urllib.parse import quote

import requests

logger = logging.getLogger(__name__)

HTTP_TIMEOUT = 30
REST = "/caisd-rest"
JSON_HEADERS = {"Accept": "application/json", "Content-Type": "application/json; charset=UTF-8"}


class CaSdmRestMixin:
    """Access-key auth + request helpers. Host class provides ``console_url``,
    ``credentials``, ``oauth_tokens``, ``verify_ssl`` (BaseConnectorAdapter)."""

    product_label = "Broadcom CA SDM"

    def _login(self) -> str:
        token = self.oauth_tokens.get("access_key")
        if token:
            return str(token)
        if not self.console_url:
            raise RuntimeError(f"{self.product_label}: REST base URL is not configured")
        user = self.credentials.get("username")
        pwd = self.credentials.get("password")
        if not (user and pwd):
            raise RuntimeError(f"{self.product_label}: credentials missing username/password")
        try:
            resp = requests.post(
                f"{self.console_url}{REST}/rest_access", auth=(user, pwd), headers=JSON_HEADERS,
                json={"rest_access": {}}, verify=self.verify_ssl, timeout=HTTP_TIMEOUT,
            )
        except requests.RequestException as exc:
            raise RuntimeError(f"{self.product_label}: cannot reach {self.console_url} ({type(exc).__name__})") from exc
        if resp.status_code in (401, 403):
            raise RuntimeError(f"{self.product_label}: login rejected ({resp.status_code}) — check the service account")
        if resp.status_code not in (200, 201):
            # Server reply only — never the credentials.
            raise RuntimeError(f"{self.product_label}: login failed ({resp.status_code}): {resp.text[:200]}")
        try:
            body = resp.json()
        except ValueError as exc:
            raise RuntimeError(f"{self.product_label}: login reply was not JSON — is this the /caisd-rest host?") from exc
        key = (body.get("rest_access") or {}).get("access_key") if isinstance(body, dict) else None
        if key in (None, ""):
            raise RuntimeError(f"{self.product_label}: login returned no access_key")
        self.oauth_tokens["access_key"] = str(key)
        return str(key)

    def _request(self, method: str, path: str, *, attrs: Optional[List[str]] = None,
                 **kwargs) -> requests.Response:
        """Access-key'd request; on 401 (expired key) re-login and retry once."""
        url = f"{self.console_url}{REST}{path}"
        headers = dict(JSON_HEADERS)
        if attrs:
            headers["X-Obj-Attrs"] = ",".join(attrs)
        kwargs.setdefault("timeout", HTTP_TIMEOUT)
        kwargs.setdefault("verify", self.verify_ssl)
        resp: Optional[requests.Response] = None
        for attempt in (1, 2):
            headers["X-AccessKey"] = self._login()
            try:
                resp = requests.request(method, url, headers=headers, **kwargs)
            except requests.RequestException as exc:
                raise RuntimeError(f"{self.product_label}: {method} {path} failed ({type(exc).__name__})") from exc
            if resp.status_code == 401 and attempt == 1:
                self.oauth_tokens.pop("access_key", None)
                continue
            return resp
        return resp  # type: ignore[return-value]

    def _collection(self, obj: str, *, attrs: List[str], wc: Optional[str] = None,
                    start: int = 1, size: int = 100) -> Tuple[List[Dict[str, Any]], Optional[int]]:
        """One page of a collection → (rows, total_count or None)."""
        params: Dict[str, str] = {"start": str(start), "size": str(size)}
        if wc:
            params["WC"] = wc
        resp = self._request("GET", f"/{obj}", attrs=attrs, params=params)
        if resp.status_code == 404:
            return [], 0
        if resp.status_code != 200:
            raise RuntimeError(f"{self.product_label}: read {obj} failed ({resp.status_code}): {resp.text[:300]}")
        return parse_collection(resp.json() if resp.text else {}, obj)

    def _test_read(self, obj: str) -> Dict[str, Any]:
        """Prove auth AND read permission on ``obj`` (a 1-row collection read)."""
        self._login()
        _rows, total = self._collection(obj, attrs=[], size=1)
        return {"object": obj, "readable": True, "total_records": total}


def parse_collection(body: Dict[str, Any], obj: str) -> Tuple[List[Dict[str, Any]], Optional[int]]:
    coll = body.get(f"collection_{obj}") if isinstance(body, dict) else None
    if not isinstance(coll, dict):
        coll = body.get("collection") if isinstance(body.get("collection"), dict) else body
    rows = as_list((coll or {}).get(obj))
    total = coll.get("@TOTAL_COUNT") if isinstance(coll, dict) else None
    try:
        total = int(total) if total is not None else None
    except (TypeError, ValueError):
        total = None
    return rows, total


def as_list(value: Any) -> List[Dict[str, Any]]:
    if value is None:
        return []
    return [v for v in (value if isinstance(value, list) else [value]) if isinstance(v, dict)]


def sym(value: Any) -> str:
    """Flatten an SREL object to its display name; scalars pass through."""
    if isinstance(value, dict):
        return str(value.get("@COMMON_NAME") or value.get("name") or value.get("sym") or "").strip()
    return str(value if value is not None else "").strip()


def srel(common_name: str) -> Dict[str, str]:
    return {"@COMMON_NAME": common_name}


def wc_quote(value: str) -> str:
    """Escape a value for a single-quoted WC (where-clause) literal."""
    return str(value).replace("'", "''")


def cn_path(obj: str, common_name: str) -> str:
    return f"/{obj}/COMMON_NAME-{quote(str(common_name), safe='')}"
