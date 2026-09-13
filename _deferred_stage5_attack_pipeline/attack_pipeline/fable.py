"""Fable — the autonomous attack-pipeline orchestrator (the diagram, in code).

Continues from the IT Asset Inventory (NOT discovery): a canonical ITAsset feeds
Fable, which:

  STAGE 1 (find)   classify the asset  ->  pick the MCP for its class + credential
                   need  ->  run it (creds pulled from the vault when required)  ->
                   return the vulnerabilities.
  STAGE 2 (exploit, later)  the vuln  ->  the MCP exploits it, or Fable writes the
                   exploit and drives the MCP's tools to pen-test  ->  evidence.

Each MCP is a Capability: a uniform seam with DECLARATIVE metadata (fits_classes /
needs_creds / can_exploit / kind) Fable selects among. Today two are real:
NessusCapability (deep, authenticated, reuses the integrations adapter + credential
vault) and HexStrikeCapability (surface, no target creds, HTTP to the local
HexStrike engine). Shodan / VirusTotal / Metasploit slot in as more subclasses.
"""
from __future__ import annotations

import logging
import os
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)


# ── device-shape helpers (read the REAL ITAsset fields) ──────────────────────
def _first(o: Any, *names: str) -> Optional[Any]:
    for n in names:
        v = getattr(o, n, None)
        if v not in (None, ""):
            return v
    return None


def device_host(a: Any) -> str:
    return str(_first(a, "host_name", "fqdn", "name") or "")


def device_ip(a: Any) -> str:
    v = _first(a, "ip_address", "ip")
    if v:
        return str(v)
    ips = getattr(a, "known_ips", None)
    if ips:
        try:
            return str(list(ips)[0])
        except Exception:
            pass
    return ""


def _lower(v: Any) -> str:
    return str(v).lower() if v not in (None, "") else ""


# ── classification (the brain) ───────────────────────────────────────────────
@dataclass
class Classification:
    asset_id: Optional[int]
    device_class: str            # host|database|cloud|network|identity|cluster|web|external-surface|unknown
    platform_kind: Optional[str]
    os_family: Optional[str]
    internet_facing: bool
    origin_source: Optional[str]
    needs_creds: bool            # does scanning THIS asset need target credentials?
    credential_kind: Optional[str]
    prior_collect: bool          # a working credential already proven (security_posture/platform_properties set)
    host: str
    ip: str
    rationale: List[str]
    signals: Dict[str, Any]

    def as_dict(self) -> Dict[str, Any]:
        return {
            "asset_id": self.asset_id,
            "device_class": self.device_class,
            "platform_kind": self.platform_kind,
            "os_family": self.os_family,
            "internet_facing": self.internet_facing,
            "origin_source": self.origin_source,
            "needs_creds": self.needs_creds,
            "credential_kind": self.credential_kind,
            "prior_collect": self.prior_collect,
            "host": self.host,
            "ip": self.ip,
            "rationale": self.rationale,
            "signals": self.signals,
        }


# platform_kind -> device_class (PLATFORM_KINDS is authoritative once a collect ran)
_PK_CLASS = {
    "server": "host", "database": "database", "network": "network",
    "cloud": "cloud", "identity": "identity", "cluster": "cluster",
}
_DB_TOKENS = ("postgres", "postgresql", "mysql", "mariadb", "mssql", "sql server",
              "sqlserver", "oracle", "mongodb", "redis")
# device_class -> target credential kind for a DEEP scan
_CRED_KIND = {
    "host_windows": "winrm", "host_linux": "ssh", "database": "db",
    "cloud": "cloud_api", "identity": "ldap", "network": "ssh", "cluster": "k8s",
}


def classify(asset: Any) -> Classification:
    """Read the real ITAsset fields and decide device_class + whether a scan of
    this asset needs TARGET credentials. platform_kind wins when present; else we
    derive from asset_type / cloud id / software / os / exposure."""
    pk = _first(asset, "platform_kind")
    asset_type = _lower(_first(asset, "asset_type"))
    asset_role = _lower(_first(asset, "asset_role"))
    os_family = _lower(_first(asset, "os_family")) or None
    os_norm = _lower(_first(asset, "os_normalized"))
    origin = _lower(_first(asset, "origin_source")) or None
    discovery_state = _lower(_first(asset, "discovery_state"))
    cloud_id = _first(asset, "cloud_resource_id")
    software = getattr(asset, "detected_software_json", None) or []
    posture = getattr(asset, "security_posture", None)
    plat_props = getattr(asset, "platform_properties", None)
    internet = bool(getattr(asset, "internet_facing", None) or getattr(asset, "is_internet_facing", None))
    host, ip = device_host(asset), device_ip(asset)

    rationale: List[str] = []
    device_class: Optional[str] = None

    if pk and str(pk) in _PK_CLASS:
        device_class = _PK_CLASS[str(pk)]
        rationale.append(f"platform_kind='{pk}' → {device_class} (authoritative, a collect already typed it)")
    elif cloud_id or asset_type == "cloud":
        device_class = "cloud"
        rationale.append("cloud_resource_id / asset_type=cloud → cloud")
    elif asset_type == "third_party":
        device_class = "external-surface"
        rationale.append("asset_type=third_party → external-surface (outside-in only)")
    elif asset_type == "application" or asset_role == "application":
        device_class = "web"
        rationale.append("asset_type/role=application → web/app surface")

    # DB derivation ONLY when platform_kind is absent — platform_kind='server' is
    # authoritative (a plain OS host), and a DB client/tool in the software list must
    # not flip a typed server into a database.
    if not pk and device_class in (None, "host"):
        blob = " ".join([os_norm, host.lower(), " ".join(
            (s.get("name") or "") if isinstance(s, dict) else str(s) for s in software
        ).lower()])
        for tok in _DB_TOKENS:
            if tok in blob:
                device_class = "database"
                rationale.append(f"software/os token '{tok}' → database")
                break

    if device_class is None:
        if asset_type in ("infrastructure", "data"):
            device_class = "host"
            rationale.append(f"asset_type={asset_type} → host")
        elif os_family or ip or host:
            device_class = "host"
            rationale.append("os/ip/host present → host")
        else:
            device_class = "unknown"
            rationale.append("no strong signal → unknown")

    # Credential need: external/surface classes are unauthenticated (no target creds).
    # Deep classes need target creds — UNLESS the asset is external (easm/internet) in
    # which case we treat it as a surface target for the no-cred path.
    surface = device_class in ("web", "external-surface") or origin == "easm"
    deep = device_class in ("host", "database", "cloud", "identity", "network", "cluster")
    needs_creds = deep and not surface
    if surface:
        rationale.append("external/surface (origin=easm or web) → no target credentials needed (HexStrike surface path)")
    elif deep:
        rationale.append(f"deep {device_class} scan → target credentials required (authenticated Nessus/collector path)")

    cred_kind = None
    if needs_creds:
        if device_class == "host":
            cred_kind = _CRED_KIND["host_windows"] if os_family == "windows" else _CRED_KIND["host_linux"]
        else:
            cred_kind = _CRED_KIND.get(device_class)

    prior_collect = bool(posture or plat_props)
    if prior_collect:
        rationale.append("security_posture/platform_properties set → a working credential already exists for this asset")

    signals = {
        "platform_kind": pk, "asset_type": asset_type, "asset_role": asset_role,
        "os_family": os_family, "os_normalized": os_norm or None, "origin_source": origin,
        "discovery_state": discovery_state or None, "internet_facing": internet,
        "cloud_resource": bool(cloud_id),
        "software_count": len(software) if hasattr(software, "__len__") else 0,
        "prior_collect": prior_collect, "host": host, "ip": ip,
    }
    return Classification(
        asset_id=getattr(asset, "id", None), device_class=device_class, platform_kind=(str(pk) if pk else None),
        os_family=os_family, internet_facing=internet, origin_source=origin, needs_creds=needs_creds,
        credential_kind=cred_kind, prior_collect=prior_collect, host=host, ip=ip,
        rationale=rationale, signals=signals,
    )


# ── capabilities (the MCP layers) ────────────────────────────────────────────
class Capability(ABC):
    """One MCP/scanner layer, with declarative metadata Fable + a UI can read."""
    name: str = "capability"
    kind: str = "scanner"            # scanner | exploit
    needs_creds: bool = False        # does this MCP need TARGET credentials to find?
    can_exploit: bool = False
    fits_classes: Tuple[str, ...] = ()

    def fits(self, c: Classification) -> bool:
        return c.device_class in self.fits_classes

    def describe(self) -> Dict[str, Any]:
        return {"name": self.name, "kind": self.kind, "needs_creds": self.needs_creds,
                "can_exploit": self.can_exploit, "fits_classes": list(self.fits_classes)}

    @abstractmethod
    def available(self, db: Session, asset: Any, c: Classification) -> Tuple[bool, str]:
        """Usable for this tenant/asset right now? (connection/creds/engine present.)"""

    @abstractmethod
    def run(self, db: Session, asset: Any, c: Classification) -> List[Dict[str, Any]]:
        """Find against the asset and return normalized findings."""


class NessusCapability(Capability):
    """Deep, authenticated finder. Reuses the integrations Nessus adapter (which
    absorbs the credential vault) + get_asset_vulnerabilities. Pull-only today."""
    name = "nessus"
    kind = "scanner"
    needs_creds = True
    can_exploit = False
    fits_classes = ("host", "database", "network", "identity", "cluster", "unknown")

    def _connection(self, db: Session, asset: Any):
        from grc.models import IntegrationConnection
        q = db.query(IntegrationConnection).filter(
            IntegrationConnection.integration_type.in_(["nessus", "tenable"]))
        tid = getattr(asset, "tenant_id", None)
        if tid is not None and hasattr(IntegrationConnection, "tenant_id"):
            q = q.filter(IntegrationConnection.tenant_id == tid)
        if hasattr(IntegrationConnection, "is_active"):
            q = q.filter(IntegrationConnection.is_active.is_(True))
        return q.order_by(IntegrationConnection.id.desc()).first()

    def available(self, db: Session, asset: Any, c: Classification) -> Tuple[bool, str]:
        try:
            conn = self._connection(db, asset)
        except Exception as e:  # noqa: BLE001
            return False, f"Could not read the Nessus connection ({e.__class__.__name__})."
        if not conn:
            return False, "No active Nessus/Tenable connection is configured for this tenant — connect Nessus to scan this asset."
        return True, "Nessus connection present."

    def run(self, db: Session, asset: Any, c: Classification) -> List[Dict[str, Any]]:
        from grc.modules.integrations.adapters.adapter_factory import build_adapter
        conn = self._connection(db, asset)
        if not conn:
            return []
        adapter = build_adapter(conn)  # decrypts the tenant's stored creds from the vault
        raw = adapter.get_asset_vulnerabilities(asset_id="", hostname=c.host, ip_address=c.ip) or []
        out: List[Dict[str, Any]] = []
        for v in raw:
            sev = v.get("severity")
            out.append({
                "source": "nessus",
                "id": v.get("plugin_id"),
                "title": v.get("plugin_name") or v.get("pluginName") or "",
                "severity": sev,
                "count": v.get("count", 1),
                "host": v.get("_host_ip") or c.host or c.ip,
                "scan_id": v.get("_scan_id"),
            })
        return out


class HexStrikeCapability(Capability):
    """Surface finder — NO target credentials. Talks HTTP to the local HexStrike
    engine (Flask :8888) and runs find-only tools (nuclei for web, nmap for host
    surface). HexStrike can also EXPLOIT (can_exploit=True) — that power is reserved
    for Stage 2; Stage 1 uses only its find/recon tools. The engine is unauthenticated
    RCE, so it is bound to localhost and never exposed."""
    name = "hexstrike"
    kind = "scanner"
    needs_creds = False
    can_exploit = True
    fits_classes = ("web", "external-surface", "host")

    BASE = os.environ.get("HEXSTRIKE_URL", "http://127.0.0.1:8888")

    def _get(self, path: str, timeout: int = 5):
        import requests
        return requests.get(f"{self.BASE}{path}", timeout=timeout)

    def _post(self, path: str, body: dict, timeout: int = 120):
        import requests
        return requests.post(f"{self.BASE}{path}", json=body, timeout=timeout)

    def available(self, db: Session, asset: Any, c: Classification) -> Tuple[bool, str]:
        if not (c.host or c.ip):
            return False, "Asset has no hostname/IP to target."
        try:
            r = self._get("/health", timeout=4)
            if r.status_code == 200:
                return True, "HexStrike engine reachable."
            return False, f"HexStrike engine returned HTTP {r.status_code}."
        except Exception:
            return False, "HexStrike engine not running on 127.0.0.1:8888 — start it (Stage 0)."

    def run(self, db: Session, asset: Any, c: Classification) -> List[Dict[str, Any]]:
        target = c.host or c.ip
        # Find-only: web/external → nuclei (template vuln detection); host → nmap surface.
        tool = "nuclei" if c.device_class in ("web", "external-surface") else "nmap"
        arg = f"https://{target}" if (tool == "nuclei" and not str(target).startswith("http")) else target
        try:
            r = self._post(f"/api/tools/{tool}", {"target": arg}, timeout=180)
            data = r.json() if r.headers.get("content-type", "").startswith("application/json") else {"raw": r.text}
        except Exception as e:  # noqa: BLE001
            return [{"source": "hexstrike", "error": f"{tool} call failed: {e.__class__.__name__}"}]
        # HexStrike shapes vary per tool; keep the raw + a normalized summary line.
        findings = data.get("findings") or data.get("vulnerabilities") or data.get("results") or []
        norm: List[Dict[str, Any]] = []
        if isinstance(findings, list) and findings:
            for f in findings:
                if isinstance(f, dict):
                    norm.append({"source": "hexstrike", "tool": tool,
                                 "title": f.get("name") or f.get("template") or f.get("info") or str(f)[:120],
                                 "severity": f.get("severity"), "host": target})
        else:
            norm.append({"source": "hexstrike", "tool": tool, "host": target,
                         "title": f"{tool} completed", "raw": (data.get("stdout") or data.get("raw") or "")[:2000]})
        return norm


# Fable's roster — order = preference within a class; new MCPs slot in here.
_ROSTER: List[Capability] = [NessusCapability(), HexStrikeCapability()]


class Fable:
    """The orchestrator. Stage 1: classify → pick MCP by class + credential need → run."""

    def __init__(self, roster: Optional[List[Capability]] = None):
        self.roster = roster if roster is not None else _ROSTER

    def capabilities(self) -> List[Dict[str, Any]]:
        return [cap.describe() for cap in self.roster]

    def select(self, c: Classification) -> List[Capability]:
        """MCPs that fit this class. When the asset needs creds we prefer the
        authenticated finder; when it's surface we prefer the no-cred one."""
        fits = [cap for cap in self.roster if cap.kind == "scanner" and cap.fits(c)]
        fits.sort(key=lambda cap: (cap.needs_creds != c.needs_creds))  # matching creds-posture first
        return fits

    def run_stage1(self, db: Session, asset: Any) -> Dict[str, Any]:
        c = classify(asset)
        candidates = self.select(c)
        considered: List[Dict[str, Any]] = []
        for cap in candidates:
            ok, why = cap.available(db, asset, c)
            considered.append({"mcp": cap.name, "needs_creds": cap.needs_creds, "available": ok, "reason": why})
            if ok:
                findings = cap.run(db, asset, c)
                return {
                    "stage": 1, "classification": c.as_dict(), "considered": considered,
                    "chosen": cap.name, "needs_action": None,
                    "findings": findings, "count": len(findings),
                }
        # Nothing runnable — say WHY in an actionable way (the credential gap is the usual one).
        needs_action = None
        if candidates and c.needs_creds:
            needs_action = f"Connect a credential/scanner for a {c.device_class} asset (e.g. Nessus) — then re-run."
        elif candidates:
            needs_action = considered[0]["reason"] if considered else None
        elif not candidates:
            needs_action = f"No MCP capability covers a '{c.device_class}' asset yet."
        return {
            "stage": 1, "classification": c.as_dict(), "considered": considered,
            "chosen": None, "needs_action": needs_action, "findings": [], "count": 0,
        }
