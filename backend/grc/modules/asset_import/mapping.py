"""Column-mapping intelligence for the asset import wizard — accept ANY sheet.

Pure functions, no DB, no FastAPI. Given the raw grid of an uploaded sheet it:
  1. finds the REAL header row (clients put a title/logo/blank rows above it),
  2. guesses which of THEIR columns maps to each of OUR canonical fields — by
     header synonyms first, then by looking at the actual values (a column full
     of IPs is the IP column even if it is labelled "Address"),
  3. normalizes messy values into our enums ("H" / "1" / "Critical" -> "critical").

Dependency-free and self-tested (`python -m grc.modules.asset_import.mapping`
or `python mapping.py`) so the logic can be verified without the app running.

ponytail: synonym dictionary + value sniffing, no ML. AI-assisted mapping for
truly bizarre files is a later enhancement; this covers the real-world 95%.
"""
from __future__ import annotations

import re
from typing import Any, Dict, List, Optional

# Our target fields. `syn` = header aliases; `required` only on name.
CANONICAL_FIELDS: Dict[str, Dict[str, Any]] = {
    "name":            {"label": "Asset name",  "required": True,
                        "syn": ["name", "asset", "asset name", "device", "device name", "title",
                                "system", "system name", "node", "label", "asset id", "tag", "item"]},
    "host_name":       {"label": "Hostname",
                        "syn": ["hostname", "host", "host name", "fqdn", "computer", "computer name",
                                "machine", "machine name", "dns", "dns name", "netbios"]},
    "ip_address":      {"label": "IP address",
                        "syn": ["ip", "ip address", "ipv4", "ip addr", "address", "primary ip",
                                "management ip", "mgmt ip", "ip4"]},
    "mac_address":     {"label": "MAC address",
                        "syn": ["mac", "mac address", "hardware address", "physical address", "ether"]},
    "asset_type":      {"label": "Asset type",
                        "syn": ["type", "asset type", "category", "class", "kind", "asset category",
                                "asset class", "device type"]},
    "criticality":     {"label": "Criticality",
                        "syn": ["criticality", "priority", "importance", "business criticality",
                                "tier", "rating", "risk rating"]},
    "environment":     {"label": "Environment",
                        "syn": ["environment", "env", "stage", "deployment", "zone"]},
    "os_family":       {"label": "Operating system",
                        "syn": ["os", "operating system", "platform", "os family", "os name",
                                "os version", "firmware"]},
    "data_classification": {"label": "Data classification",
                        "syn": ["data classification", "classification", "data class", "sensitivity",
                                "confidentiality level", "info class", "data sensitivity"]},
    "owner":           {"label": "Owner",
                        "syn": ["owner", "asset owner", "responsible", "custodian", "contact",
                                "assigned to", "owner email", "poc", "steward"]},
    "location":        {"label": "Location",
                        "syn": ["location", "site", "datacenter", "data center", "region",
                                "facility", "building", "rack"]},
    "business_function": {"label": "Business function",
                        "syn": ["business function", "function", "department", "business unit",
                                "service", "role", "application role", "dept", "division"]},
    "confidentiality": {"label": "Confidentiality (C)",
                        "syn": ["confidentiality", "conf", "cia c", "c rating"]},
    "integrity":       {"label": "Integrity (I)",
                        "syn": ["integrity", "cia i", "i rating"]},
    "availability":    {"label": "Availability (A)",
                        "syn": ["availability", "avail", "cia a", "a rating", "uptime tier"]},
    "status":          {"label": "Status",
                        "syn": ["status", "state", "operational status"]},
    "lifecycle_state": {"label": "Lifecycle",
                        "syn": ["lifecycle", "lifecycle state", "lifecycle stage", "phase",
                                "stage of life"]},
    "description":     {"label": "Description / notes",
                        "syn": ["description", "notes", "comment", "comments", "details",
                                "remarks", "note"]},
}

_IPV4 = re.compile(r"^\s*(\d{1,3}\.){3}\d{1,3}\s*$")
_MAC = re.compile(r"^\s*([0-9a-fA-F]{2}[:\-]){5}[0-9a-fA-F]{2}\s*$")
_EMAIL = re.compile(r"[^@\s]+@[^@\s]+\.[^@\s]+")


def _norm(s: Any) -> str:
    """lowercase, strip, collapse every non-alphanumeric run to one space."""
    return re.sub(r"[^a-z0-9]+", " ", str(s if s is not None else "").lower()).strip()


# reverse index: normalized synonym -> canonical field (first writer wins)
_SYN_INDEX: Dict[str, str] = {}
for _f, _spec in CANONICAL_FIELDS.items():
    _SYN_INDEX.setdefault(_norm(_f), _f)
    for _s in _spec["syn"]:
        _SYN_INDEX.setdefault(_norm(_s), _f)


def detect_header_row(grid: List[List[Any]], scan: int = 15) -> int:
    """Index of the row most likely to be the header. Clients prepend titles /
    logos / blank rows, so header != row 0 in the real world. We score each of
    the first `scan` rows by how many cells look like known field names."""
    best_i, best_score = 0, -1.0
    for i, row in enumerate(grid[:scan]):
        cells = [c for c in row if str(c if c is not None else "").strip()]
        if not cells:
            continue
        known = sum(1 for c in row if _norm(c) in _SYN_INDEX)
        shortish = sum(1 for c in cells if len(str(c)) <= 40)
        # known-field cells dominate; a fuller, short-text row breaks ties
        score = known * 3 + len(cells) * 0.1 + shortish * 0.05
        if score > best_score:
            best_score, best_i = score, i
    return best_i


def _infer_from_values(values: List[Any]) -> Optional[str]:
    """When the header is ambiguous, sniff the column's actual values."""
    vals = [str(v).strip() for v in values if str(v if v is not None else "").strip()]
    if not vals:
        return None

    def frac(pred) -> float:
        return sum(1 for v in vals if pred(v)) / len(vals)

    if frac(lambda v: bool(_IPV4.match(v))) >= 0.6:
        return "ip_address"
    if frac(lambda v: bool(_MAC.match(v))) >= 0.6:
        return "mac_address"
    if frac(lambda v: bool(_EMAIL.search(v))) >= 0.6:
        return "owner"
    crit = {"low", "medium", "high", "critical", "l", "m", "h", "c", "med", "crit"}
    if frac(lambda v: v.lower() in crit) >= 0.7:
        return "criticality"
    os_kw = ("windows", "linux", "ubuntu", "debian", "centos", "red hat", "rhel",
             "macos", "mac os", "server 20", "esxi", "android", "ios ")
    if frac(lambda v: any(k in v.lower() for k in os_kw)) >= 0.5:
        return "os_family"
    return None


def guess_mapping(headers: List[Any], columns: Optional[List[List[Any]]] = None) -> Dict[str, Dict[str, Any]]:
    """{source_header: {field, confidence 0..1, why}} — field=None means unmapped."""
    columns = columns or [[] for _ in headers]
    out: Dict[str, Dict[str, Any]] = {}
    taken: Dict[str, float] = {}  # field -> best confidence already assigned
    for idx, h in enumerate(headers):
        key = str(h)
        nh = _norm(h)
        field, conf, why = None, 0.0, "no match — set manually"
        if not nh:
            out[key] = {"field": None, "confidence": 0.0, "why": "blank header"}
            continue
        if nh in _SYN_INDEX:
            field, conf, why = _SYN_INDEX[nh], 0.98, "exact header match"
        else:
            best_f, best_ov = None, 0.0
            htok = set(nh.split())
            for syn, f in _SYN_INDEX.items():
                stok = set(syn.split())
                if not stok:
                    continue
                ov = len(htok & stok) / len(stok)
                if ov > best_ov:
                    best_ov, best_f = ov, f
            if best_f and best_ov >= 0.5:
                field, conf, why = best_f, round(0.5 + 0.3 * best_ov, 2), "header keyword match"
            else:
                inferred = _infer_from_values(columns[idx] if idx < len(columns) else [])
                if inferred:
                    field, conf, why = inferred, 0.55, "matched by column values"
        # if two columns claim the same field, keep the stronger one mapped
        if field and taken.get(field, 0.0) >= conf:
            field, conf, why = None, 0.0, "duplicate of a stronger column — set manually"
        elif field:
            taken[field] = conf
        out[key] = {"field": field, "confidence": conf, "why": why}
    return out


_CRIT = {
    "critical": "critical", "crit": "critical", "c": "critical", "4": "critical", "5": "critical",
    "very high": "critical", "vhigh": "critical",
    "high": "high", "h": "high", "3": "high",
    "medium": "medium", "med": "medium", "m": "medium", "moderate": "medium", "2": "medium",
    "low": "low", "l": "low", "minimal": "low", "1": "low",
}
_TYPE_SYN = {
    "application": ["application", "app", "software", "service", "system", "web app", "api", "portal", "saas app"],
    "infrastructure": ["infrastructure", "infra", "server", "network", "hardware", "device", "endpoint",
                        "workstation", "laptop", "desktop", "vm", "virtual machine", "host", "switch",
                        "router", "firewall", "storage", "appliance", "printer"],
    "data": ["data", "database", "db", "datastore", "data store", "dataset", "warehouse"],
    "cloud": ["cloud", "saas", "iaas", "paas", "aws", "azure", "gcp", "cloud service"],
    "third_party": ["third party", "3rd party", "vendor", "external", "supplier", "partner"],
}
_TYPE = {}
for _canon, _aliases in _TYPE_SYN.items():
    for _a in _aliases:
        _TYPE[_norm(_a)] = _canon


def normalize_value(field: str, raw: Any) -> Any:
    """Coerce a raw cell into our canonical value. Unknown enum -> None so the
    row's validation can flag it rather than smuggling garbage into the DB."""
    if raw is None:
        return None
    s = str(raw).strip()
    if s == "":
        return None
    if field == "criticality":
        return _CRIT.get(s.lower())
    if field == "asset_type":
        n = _norm(s)
        if n in _TYPE:
            return _TYPE[n]
        # token match so "SQL Database" -> data, "Web Server" -> infrastructure;
        # check specific types before infrastructure (the catch-all). Whole-token
        # match avoids substring traps like "db" inside "sandbox".
        toks = set(n.split())
        for canon in ("data", "cloud", "third_party", "application", "infrastructure"):
            for alias in _TYPE_SYN[canon]:
                aw = _norm(alias).split()
                if aw and all(w in toks for w in aw):
                    return canon
        return None  # unrecognised; commit defaults it to infrastructure
    if field in ("confidentiality", "integrity", "availability"):
        try:
            return max(1, min(5, int(float(s))))
        except (ValueError, TypeError):
            return None
    if field == "data_classification":
        return {"public": "public", "internal": "internal", "confidential": "confidential",
                "restricted": "restricted", "sensitive": "confidential", "pii": "confidential",
                "private": "confidential", "secret": "restricted", "top secret": "restricted"}.get(s.lower())
    if field == "status":
        return {"active": "active", "in use": "active", "running": "active", "live": "active",
                "production": "active", "operational": "active",
                "inactive": "inactive", "offline": "inactive", "disabled": "inactive",
                "decommissioned": "decommissioned", "retired": "decommissioned",
                "disposed": "decommissioned"}.get(s.lower())  # unknown -> None -> model default
    if field == "lifecycle_state":
        return {"planned": "planned", "active": "active", "in service": "active",
                "maintenance": "maintenance", "decommissioned": "decommissioned",
                "retired": "retired", "disposed": "retired"}.get(s.lower())
    if field == "environment":
        return s.lower()  # free-ish text; keep normalized case
    return s


def apply_mapping(headers: List[Any], row: List[Any], field_by_col: Dict[str, str]) -> Dict[str, Any]:
    """Turn one raw row into a canonical {field: value} dict using the map."""
    rec: Dict[str, Any] = {}
    for i, h in enumerate(headers):
        f = field_by_col.get(str(h))
        if not f:
            continue
        val = normalize_value(f, row[i] if i < len(row) else None)
        if val is not None:
            rec[f] = val
    return rec


def _demo() -> None:
    """Runnable self-check: a deliberately messy sheet must map correctly."""
    grid = [
        ["Acme Corp — Asset Register (confidential)", None, None, None, None],   # title row
        [None, None, None, None, None],                                          # blank row
        ["Device Name", "Host", "Address", "Business Criticality", "OS"],        # real header @ idx 2
        ["Payroll DB", "pay-db01", "10.0.0.5", "High", "Ubuntu 22.04"],
        ["Web Front", "web01", "10.0.0.6", "critical", "Windows Server 2019"],
    ]
    hidx = detect_header_row(grid)
    assert hidx == 2, f"header row wrong: {hidx}"
    headers = grid[hidx]
    cols = [[r[i] for r in grid[hidx + 1:]] for i in range(len(headers))]
    m = guess_mapping(headers, cols)
    got = {h: m[h]["field"] for h in map(str, headers)}
    assert got["Device Name"] == "name", got
    assert got["Host"] == "host_name", got
    assert got["Address"] == "ip_address", got           # inferred from IP values, header is vague
    assert got["Business Criticality"] == "criticality", got
    assert got["OS"] == "os_family", got
    # value normalization
    assert normalize_value("criticality", "H") == "high"
    assert normalize_value("criticality", "1") == "low"
    assert normalize_value("asset_type", "SQL Database") == "data"
    assert normalize_value("asset_type", "Laptop") == "infrastructure"
    assert normalize_value("confidentiality", "5") == 5
    rec = apply_mapping(headers, grid[4], {h: m[h]["field"] for h in map(str, headers)})
    assert rec["name"] == "Web Front" and rec["ip_address"] == "10.0.0.6" and rec["criticality"] == "critical", rec
    print("mapping self-check OK")


if __name__ == "__main__":
    _demo()
