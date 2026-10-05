"""IT Asset Inventory — Overview: estate composition (read-only, pure).

Buckets every in-inventory asset  External | Internal  ->  class  ->  subtype  from
the real signals it already carries, and rolls up per-class coverage (seen <=30d,
owner, CIS, criticality mix, end-of-life). Fixed buckets and counts only — never a
per-asset list — so the payload is the same size at 5 or 5,000 assets.

Signals, strongest first:
  provenance       internet_facing / origin_source='easm' / last_seen_source='external'
                   (the register's own External rule, so both views agree)
  typed collector  platform_kind database|network|cluster|cloud|identity  ('server' is
                   only the placeholder for ANY agentless OS host — never a role)
  OS               os_family, then os_version / os_normalized (Windows Server vs client)
  hardware         manufacturer / model (notebook, PowerEdge, FortiGate, Synology, ...)
  discovery        fingerprint / discovery_classification device_type + open ports
  role evidence    installed database-server products (sbp_inventory._is_db)
  outside-in probe platform_properties.external_probe (live HTTP, title, content type,
                   CDN/WAF, ASN, DNS resolution, TLS)
No signal -> 'Unidentified'. Nothing is guessed, sampled or invented.

Self-check (no DB):  python -m grc.modules.estate_overview.service   (run from backend/)
"""
from __future__ import annotations

import html
import ipaddress
import re
from collections import Counter
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Iterable, List, Optional, Set, Tuple

from grc.modules.sbp_inventory import service as sbp
from grc.modules.sbp_inventory.vendor_feeds import db_label

EXTERNAL = ("Web application", "API", "Remote / admin service", "Domain / subdomain", "Unidentified")
INTERNAL = ("Server", "Workstation / endpoint", "Database", "Network device",
            "Virtualization", "Storage", "Printer / IoT", "Other", "Unidentified")
# Windows is split by edition: a Server and a 10/11 client are different risk classes.
OS_FAMILIES = ("Windows Server", "Windows client", "Windows (edition unknown)", "Linux", "macOS",
               "Network OS", "Other OS", "OS not visible")
HOSTING = ("CDN / WAF-fronted", "Cloud-hosted", "Hosting provider / ISP", "Hosting unknown", "Not yet probed")
VERIFICATION = ("Live web service", "Open non-web ports", "No web response", "Doesn't resolve", "Not yet probed")
CRITS = ("critical", "high", "medium", "low", "unrated")
# Buckets that mean "we don't know yet" — the UI greys them instead of colouring them.
GAPS = {"Unidentified", "OS not visible", "Not yet probed", "Hosting unknown",
        "No identifying signal", "No outside-in evidence"}
SUBTYPE_CAP = 6  # longer tails fold into one "Other …" bucket

# ---------- OS ----------
_NETOS = ((r"nx-?os", "Cisco NX-OS"), (r"ios[ -]?xe", "Cisco IOS XE"), (r"ios[ -]?xr", "Cisco IOS XR"),
          (r"cisco ios|cisco internetwork", "Cisco IOS"), (r"\basa\b|firepower|\bftd\b", "Cisco ASA / FTD"),
          (r"junos", "Junos"), (r"fortios|fortigate", "FortiOS"), (r"pan-?os", "PAN-OS"),
          (r"routeros|mikrotik", "RouterOS"), (r"arista", "Arista EOS"), (r"aruba ?os|arubaos", "ArubaOS"),
          (r"comware", "Comware"), (r"sonicos", "SonicOS"), (r"gaia|check ?point", "Check Point Gaia"),
          (r"vyos|edgeos", "VyOS / EdgeOS"), (r"pfsense|opnsense", "pfSense / OPNsense"))
_LINUX_RX = re.compile(r"linux|ubuntu|debian|red ?hat|rhel|centos|rocky|alma|suse|sles|fedora|alpine|kali")
_DISTROS = (("ubuntu", "Ubuntu"), ("red hat", "RHEL"), ("rhel", "RHEL"), ("centos", "CentOS"),
            ("debian", "Debian"), ("rocky", "Rocky Linux"), ("alma", "AlmaLinux"), ("sles", "SUSE"),
            ("suse", "SUSE"), ("amazon linux", "Amazon Linux"), ("oracle linux", "Oracle Linux"),
            ("fedora", "Fedora"), ("alpine", "Alpine"), ("kali", "Kali"))


def _os_text(a) -> str:
    return " ".join(str(getattr(a, k, None) or "") for k in ("os_family", "os_version", "os_normalized")).lower().strip()


def _netos(s: str) -> Optional[str]:
    return next((label for rx, label in _NETOS if re.search(rx, s)), None)


def os_of(a, fp: Dict[str, Any]) -> Tuple[str, str]:
    """(family, line) from the profiled OS; a discovery os_guess counts only for the
    family (version not profiled). No OS at all -> 'OS not visible'."""
    s = _os_text(a)
    if not s:
        g = str(fp.get("os_guess") or "").lower()
        fam = {"windows": "Windows", "linux": "Linux", "macos": "macOS"}.get(g)
        return (fam, f"{fam} (version not profiled)") if fam else ("OS not visible", "OS not visible")
    if re.search(r"windows|win32|win64|microsoft", s):
        m = re.search(r"windows[ -]?server\D*(\d{4})(\s*r2)?", s)
        if m:
            return "Windows", f"Windows Server {m.group(1)}{' R2' if m.group(2) else ''}"
        if "server" in s:
            return "Windows", "Windows Server"
        m = re.search(r"windows[ -]?(11|10|8\.1|8|7|vista|xp)\b", s)
        return "Windows", (f"Windows {m.group(1).upper() if m.group(1) == 'xp' else m.group(1).title()}"
                           if m else "Windows (version unknown)")
    if re.search(r"mac ?os|darwin|os ?x\b|\bosx\b", s):
        m = re.search(r"(?:mac ?os|os ?x)\D*(10\.\d+|\d{2})", s)
        return "macOS", f"macOS {m.group(1)}" if m else "macOS"
    net = _netos(s)
    if net:
        return "Network OS", net
    if _LINUX_RX.search(s):
        for key, name in _DISTROS:
            i = s.find(key)
            if i >= 0:
                rest = s[i + len(key):]
                m = re.search(r"(\d{2}\.\d{2})" if key == "ubuntu" else r"(\d+)", rest[:40])
                return "Linux", f"{name} {m.group(1)}" if m else name
        return "Linux", "Linux (other distribution)"
    return "Other OS", "Other OS"


def is_win_server(line: str) -> bool:
    return line.startswith("Windows Server")


def os_bucket(fam: str, line: str) -> str:
    """The OS row an asset counts under (OS_FAMILIES): Windows split by edition."""
    if fam != "Windows":
        return fam
    if is_win_server(line):
        return "Windows Server"
    return "Windows client" if re.fullmatch(r"Windows (11|10|8\.1|8|7|Vista|XP)", line) else "Windows (edition unknown)"


# ---------- hardware / vendor evidence ----------
_ENDPOINT_HW = re.compile(r"notebook|laptop|elitebook|probook|zbook|thinkpad|latitude|inspiron|vostro|\bxps\b|"
                          r"optiplex|elitedesk|prodesk|thinkcentre|ideapad|surface|macbook|imac|mac mini|"
                          r"chromebook|all-in-one|desktop")
_SERVER_HW = re.compile(r"proliant|poweredge|thinksystem|system x|\bucs\b|primergy|supermicro|superserver|"
                        r"\brack\b|blade|\bserver\b")
_HYPERVISOR = re.compile(r"esxi|vsphere|proxmox|xenserver|xcp-ng|hyper-v server|nutanix|\bahv\b|ovirt")
_NET_VENDOR = re.compile(r"cisco|juniper|fortinet|fortigate|palo alto|mikrotik|aruba|ubiquiti|netgear|tp-link|"
                         r"sonicwall|check ?point|arista|extreme networks|ruckus|meraki|watchguard|zyxel|"
                         r"d-link|huawei|f5 networks|barracuda")
_STORAGE_VENDOR = re.compile(r"synology|qnap|netapp|truenas|freenas|\bemc\b|isilon|pure storage|nimble|drobo|"
                             r"asustor|terramaster|unraid|openmediavault")
_PRINTER_HW = re.compile(r"laserjet|officejet|deskjet|pagewide|imagerunner|bizhub|workcentre|ecosys|\bmfp\b|printer")
_NET_KIND = (("Firewall", r"firewall|fortigate|fortios|\basa\b|firepower|pa-\d|palo alto|pan-?os|sonicwall|"
                          r"check ?point|gaia|watchguard|pfsense|opnsense|\bsrx"),
             ("Wireless", r"wireless|aironet|access point|\bwlc\b|\bap\d|ruckus|meraki mr|instant on"),
             ("Switch", r"switch|catalyst|nexus|nx-?os|procurve|comware|powerconnect|arista|meraki ms"),
             ("Router", r"router|routeros|mikrotik|\bisr\b|\basr\b|edgerouter|vyos|junos|ios[ -]?x[er]|cisco ios"))
_IOT_KIND = {"printer": "Printer", "camera": "IP camera / NVR", "voip": "VoIP phone / PBX",
             "ups": "UPS / power", "appliance": "Embedded appliance"}
_HOST_FAMS = {"Windows", "Linux", "macOS"}
_DB_PORT_LABEL = {"postgres": "PostgreSQL", "mysql": "MySQL", "mssql": "SQL Server", "oracle": "Oracle",
                  "mongodb": "MongoDB", "redis": "Redis", "elasticsearch": "Elasticsearch"}
_ASSET_TYPE = (("Database", r"database|\bdb\b"), ("Network device", r"network|router|switch|firewall"),
               ("Storage", r"storage|\bnas\b|\bsan\b"), ("Virtualization", r"hypervisor|virtuali[sz]ation"),
               ("Printer / IoT", r"printer|\biot\b|camera"), ("Workstation / endpoint", r"workstation|laptop|desktop|endpoint"),
               ("Server", r"server"))


def _hw_text(a, fp: Dict[str, Any]) -> str:
    return " ".join(str(x or "") for x in (getattr(a, "manufacturer", None), getattr(a, "model", None),
                                          fp.get("vendor"), fp.get("product"))).lower()


def _first(options, text: str, default: str) -> str:
    return next((label for label, rx in options if re.search(rx, text)), default)


def _db_engine(a, fp: Dict[str, Any]) -> str:
    eng = sbp._db_engines(a)
    if eng:
        return db_label(eng[0][0])
    return _DB_PORT_LABEL.get(str(fp.get("product") or "").lower(), "Engine not identified")


def classify_internal(a, dt: Optional[str], fp: Dict[str, Any]) -> Tuple[str, str]:
    """(class, subtype) for an internal asset."""
    pk = (getattr(a, "platform_kind", None) or "").lower()
    fam, line = os_of(a, fp)
    hw = _hw_text(a, fp)
    ostext = _os_text(a)
    if pk == "database":
        return "Database", _db_engine(a, fp)
    if pk == "network":
        return "Network device", _first(_NET_KIND, f"{hw} {ostext}", "Other network gear")
    if pk == "cluster":
        return "Virtualization", "Container cluster"
    if pk == "cloud":
        return "Other", "Cloud account"
    if pk == "identity":
        return "Other", "Identity platform"
    if dt == "hypervisor" or _HYPERVISOR.search(f"{ostext} {hw}"):
        return "Virtualization", "Hypervisor host"
    if fam == "Network OS" or dt in ("network_device", "router", "switch", "firewall") or (
            _NET_VENDOR.search(hw) and fam not in _HOST_FAMS and not _SERVER_HW.search(hw)):
        return "Network device", _first(_NET_KIND, f"{hw} {ostext}", "Other network gear")
    if dt == "storage" or (_STORAGE_VENDOR.search(hw) and fam not in _HOST_FAMS):
        return "Storage", "NAS / storage array"
    if dt in _IOT_KIND:
        return "Printer / IoT", _IOT_KIND[dt]
    if _PRINTER_HW.search(hw):
        return "Printer / IoT", "Printer"
    if dt in ("directory", "dns_server"):
        return "Other", "Directory / DNS"
    if fam == "Windows" and not line.endswith("(version not profiled)"):
        return ("Server", line) if is_win_server(line) else ("Workstation / endpoint", line)
    if fam == "macOS":
        return "Workstation / endpoint", line
    if fam in ("Linux", "Other OS") and ostext:
        if _ENDPOINT_HW.search(hw) or "desktop" in ostext:
            return "Workstation / endpoint", line
        return "Server", line
    if dt == "database":
        return "Database", _db_engine(a, fp)
    if _ENDPOINT_HW.search(hw):
        return "Workstation / endpoint", line if fam != "OS not visible" else "OS not profiled"
    if _SERVER_HW.search(hw):
        return "Server", line if fam != "OS not visible" else "OS not profiled"
    at = (getattr(a, "asset_type", None) or "").lower()
    typed = _first(_ASSET_TYPE, at, "")
    if typed:
        return typed, "Set on the register"
    if (getattr(a, "asset_role", None) or "").lower() == "application" or re.search(r"application|\bapp\b|\bweb\b", at):
        return "Other", "Application"
    if dt == "host" or fam != "OS not visible":
        return "Unidentified", "Host, OS & role unknown" if fam == "OS not visible" else f"{fam} host, role unknown"
    return "Unidentified", "No identifying signal"


def refine_server(a, fp: Dict[str, Any]) -> Optional[Tuple[str, str]]:
    """A server-class host with an installed database-server product IS a database
    server (sbp_inventory role evidence). Needs its software/services loaded."""
    return ("Database", _db_engine(a, fp)) if sbp._is_db(a) == "Yes" else None


# ---------- external ----------
_EXPOSED = {  # port -> exposed-service category (display categories, never product names)
    **dict.fromkeys((22, 23, 3389, 5900, 5901, 5985, 5986), "Remote access (SSH / RDP / VNC)"),
    **dict.fromkeys((1433, 1521, 3306, 5432, 6379, 9200, 11211, 27017, 5984), "Database port"),
    **dict.fromkeys((2082, 2083, 2086, 2087, 2095, 2096, 8006, 10000), "Admin panel / console"),
    **dict.fromkeys((21, 139, 445, 2049, 873), "File transfer / sharing"),
    **dict.fromkeys((161, 623, 2375, 2376, 6443, 10250), "Management interface"),
}
_EXPOSED_ORDER = ("Remote access (SSH / RDP / VNC)", "Database port", "Admin panel / console",
                  "Management interface", "File transfer / sharing")
_ADMIN_TITLE = re.compile(r"cpanel|\bwhm\b|webmin|plesk|phpmyadmin|directadmin|adminer|esxi|vsphere|proxmox|"
                          r"fortigate|pfsense|opnsense|sonicwall|\bidrac\b|\bilo\b|jenkins|grafana|kibana|portainer|"
                          r"router login|admin(istrator)? (login|panel|console)")
_API_LABEL = re.compile(r"^(api|apis|graphql|gateway|apigw|rest)([-\d]|$)")
_CDN = re.compile(r"cloudflare|akamai|fastly|incapsula|imperva|sucuri|cloudfront|edgecast|stackpath|bunny")
_CLOUD = re.compile(r"amazon|\baws\b|google|microsoft|azure|digitalocean|linode|oracle|alibaba|tencent|"
                    r"hetzner|\bovh|vultr|\bibm\b|scaleway")


def _dns_name(a) -> str:
    return str(getattr(a, "fqdn", None) or getattr(a, "host_name", None) or getattr(a, "name", None) or "").lower().rstrip(".")


def _is_fqdn(n: str) -> bool:
    try:
        ipaddress.ip_address(n)
        return False
    except ValueError:
        return "." in n and bool(re.search(r"[a-z]", n))


def hosting(ep: Dict[str, Any]) -> str:
    org = str(ep.get("asn_org") or "").lower()
    if ep.get("cdn_waf") or _CDN.search(f"{str(ep.get('server') or '').lower()} {org}"):
        return "CDN / WAF-fronted"
    if _CLOUD.search(org):
        return "Cloud-hosted"
    return "Hosting provider / ISP" if org else "Hosting unknown"


def classify_external(a, ports: Set[int]) -> Tuple[str, str]:
    """(class, subtype) for an external asset. The riskiest proven fact wins:
    an exposed remote/admin port, then an API, a web application, a bare name."""
    hits = {_EXPOSED[p] for p in ports if p in _EXPOSED}
    if hits:
        return "Remote / admin service", next(k for k in _EXPOSED_ORDER if k in hits)
    ep = sbp._ep(a)
    title = html.unescape(html.unescape(str(ep.get("title") or ""))).lower()
    if ep.get("live") and _ADMIN_TITLE.search(title):
        return "Remote / admin service", "Admin panel / console"
    ctype = str(ep.get("content_type") or "").lower()
    label = _dns_name(a).split(".")[0]
    if ep.get("live") and ("json" in ctype or "graphql" in ctype or (_API_LABEL.match(label) and "html" not in ctype)):
        return "API", hosting(ep)
    if sbp._ext_web(a):
        return "Web application", hosting(ep)
    if not ep and not ports and not _is_fqdn(_dns_name(a)):
        return "Unidentified", "No outside-in evidence"
    return "Domain / subdomain", probe_status(a, ports)


_WEB_PORTS = {80, 443, 8080, 8443}


def probe_status(a, ports: Set[int] = frozenset()) -> str:
    """What outside-in evidence proved about the name (VERIFICATION): a live web
    service, other listening ports (enrichment), a resolving-but-silent name, a
    name that no longer resolves, or nothing checked yet."""
    ep = sbp._ep(a)
    if sbp._ext_web(a):
        return "Live web service"
    if ports - _WEB_PORTS:
        return "Open non-web ports"
    if not ep:
        return "Not yet probed"
    if not ep.get("ip") and not ep.get("dns_a"):
        return "Doesn't resolve"
    return "No web response"


def is_external(a) -> bool:
    """The register's rule (InventoryRedesign.isExt) so Overview and register agree."""
    return bool(getattr(a, "internet_facing", None) or getattr(a, "origin_source", None) == "easm"
                or getattr(a, "last_seen_source", None) == "external")


def fingerprint(a) -> Dict[str, Any]:
    pp = getattr(a, "platform_properties", None) or {}
    for key in ("fingerprint", "discovery_classification"):
        v = pp.get(key) if isinstance(pp, dict) else None
        if isinstance(v, dict) and (v.get("device_type") or v.get("os_guess") or v.get("vendor")):
            return v
    return {}


# ---------- roll-up ----------
def _bucket() -> Dict[str, Any]:
    return {"n": 0, "sub": Counter(), "seen_30d": 0, "owner": 0, "cis": 0,
            "crit": dict.fromkeys(CRITS, 0), "eol_past": 0, "eol_soon": 0, "eol_known": 0}


def _subs(c: Counter) -> List[Dict[str, Any]]:
    top = c.most_common()
    if len(top) > SUBTYPE_CAP:
        rest = top[SUBTYPE_CAP - 1:]
        top = top[:SUBTYPE_CAP - 1] + [(f"Other ({len(rest)} kinds)", sum(n for _, n in rest))]
    return [{"label": k, "n": n, "gap": k in GAPS or k.endswith("unknown") or k == "OS not profiled"} for k, n in top]


def summarize(assets: Iterable[Any], cis_ids: Set[int], ports: Dict[int, Set[int]],
              dtypes: Dict[int, Optional[str]], now: datetime) -> Dict[str, Any]:
    """assets: objects with the ITAsset attributes this module reads (platform_properties
    limited to fingerprint / discovery_classification / external_probe / engine, plus
    detected_software_json + services for server-class hosts) · cis_ids: assets with a CIS
    run · ports / dtypes: latest discovery open ports + device type per asset id."""
    sides = {"external": {c: _bucket() for c in EXTERNAL}, "internal": {c: _bucket() for c in INTERNAL}}
    os_fam = {f: Counter() for f in OS_FAMILIES}
    ext, ext_host, ext_ver = Counter(), Counter(), Counter()
    life = Counter()
    soon, stale_before = now + timedelta(days=90), now - timedelta(days=30)
    total = 0
    for a in assets:
        total += 1
        fp = fingerprint(a)
        dt = (fp.get("device_type") or dtypes.get(a.id) or "").lower() or None
        if is_external(a):
            side = "external"
            cls, sub = classify_external(a, ports.get(a.id, set()))
            ep = sbp._ep(a)
            h = hosting(ep) if ep else "Not yet probed"
            ext_host[h] += 1
            ext_ver[probe_status(a, ports.get(a.id, set()))] += 1
            if ep:
                ext["probed"] += 1
                days = ep.get("tls_days_to_expiry")
                ext["tls_expired"] += bool(ep.get("tls_expired"))
                ext["tls_expiring_30d"] += bool(not ep.get("tls_expired") and isinstance(days, (int, float)) and 0 <= days <= 30)
                ext["cdn_waf"] += h == "CDN / WAF-fronted"
                ext["cloud"] += h == "Cloud-hosted"
            ext["live"] += sbp._ext_web(a)
        else:
            side = "internal"
            cls, sub = classify_internal(a, dt, fp)
            if cls == "Server":
                cls, sub = refine_server(a, fp) or (cls, sub)
            fam, line = os_of(a, fp)
            os_fam[os_bucket(fam, line)][line] += 1
        b = sides[side][cls]
        b["n"] += 1
        b["sub"][sub] += 1
        seen = getattr(a, "last_seen_at", None)
        b["seen_30d"] += bool(seen and seen >= stale_before)
        b["owner"] += bool(getattr(a, "owner_id", None) or getattr(a, "primary_owner_id", None))
        b["cis"] += a.id in cis_ids
        c = (getattr(a, "criticality", None) or "").lower()
        b["crit"][c if c in CRITS else "unrated"] += 1
        eol = sbp._eol(a)
        if eol:
            b["eol_known"] += 1
            b["eol_past"] += eol <= now
            b["eol_soon"] += now < eol <= soon
        life[(getattr(a, "lifecycle_state", None) or getattr(a, "status", None) or "unset").lower()] += 1

    def side_out(name: str, order) -> Dict[str, Any]:
        classes = []
        for cls in order:
            b = sides[name][cls]
            classes.append({
                "label": cls, "n": b["n"], "gap": cls in GAPS, "subtypes": _subs(b["sub"]),
                "seen_30d": b["seen_30d"], "owner": b["owner"], "crit": b["crit"],
                # Host benchmarks and OS end-of-life can't be observed outside-in: n/a, not 0.
                "cis": b["cis"] if name == "internal" else None,
                "eol": {"past": b["eol_past"], "soon": b["eol_soon"], "known": b["eol_known"]} if name == "internal" else None,
            })
        return {"total": sum(c["n"] for c in classes), "classes": classes}

    out_ext, out_int = side_out("external", EXTERNAL), side_out("internal", INTERNAL)
    out_ext["facets"] = {k: ext[k] for k in ("probed", "live", "cdn_waf", "cloud", "tls_expired", "tls_expiring_30d")}
    out_ext["hosting"] = [{"label": h, "n": ext_host[h], "gap": h in GAPS} for h in HOSTING]
    out_ext["verification"] = [{"label": v, "n": ext_ver[v], "gap": v in GAPS} for v in VERIFICATION]
    out_int["os"] = [{"label": f, "n": sum(os_fam[f].values()), "gap": f in GAPS, "subtypes": _subs(os_fam[f])}
                     for f in OS_FAMILIES]
    out_int["facets"] = {"os_profiled": sum(o["n"] for o in out_int["os"] if o["label"] != "OS not visible")}
    allc = out_ext["classes"] + out_int["classes"]
    return {
        "as_of": datetime.now(timezone.utc).isoformat(),
        "total": total,
        "external": out_ext,
        "internal": out_int,
        "coverage": {"seen_30d": sum(c["seen_30d"] for c in allc), "owner": sum(c["owner"] for c in allc),
                     "cis": sum(c["cis"] or 0 for c in out_int["classes"])},
        "eol": {k: sum(c["eol"][k] for c in out_int["classes"]) for k in ("past", "soon", "known")},
        "lifecycle": [{"label": k, "n": n} for k, n in life.most_common()],
        "unidentified": sides["external"]["Unidentified"]["n"] + sides["internal"]["Unidentified"]["n"],
    }


if __name__ == "__main__":  # self-check on synthetic assets — no DB needed
    from types import SimpleNamespace as NS

    now = datetime(2026, 9, 28, 12, 0)

    def A(i, **kw):
        base = dict(id=i, name=f"a{i}", fqdn=None, host_name=None, asset_type="infrastructure", asset_role=None,
                    platform_kind=None, origin_source=None, internet_facing=False, last_seen_source=None,
                    status="active", lifecycle_state=None, os_family=None, os_version=None, os_normalized=None,
                    os_build=None, manufacturer=None, model=None, owner_id=None, primary_owner_id=None,
                    criticality=None, last_seen_at=now - timedelta(days=2), eol_date=None,
                    platform_properties={}, detected_software_json=None)
        base.update(kw)
        return NS(**base)

    laptop = A(1, platform_kind="server", os_family="windows", os_version="Microsoft Windows 11 Pro 25H2",
               manufacturer="HP", model="HP EliteBook 840 G8 Notebook PC",
               detected_software_json=[{"name": "PostgreSQL 18", "version": "18.0"}])
    winsrv = A(2, platform_kind="server", os_family="windows", os_version="Microsoft Windows Server 2012 R2 Standard")
    dbsrv = A(3, os_family="linux", os_version="Ubuntu 22.04.4 LTS",
              detected_software_json=[{"name": "postgresql-16", "version": "16.2"}])
    fw = A(4, manufacturer="Fortinet", model="FortiGate 60F")
    esx = A(5, os_version="VMware ESXi 7.0.3")
    nas = A(6, platform_properties={"fingerprint": {"device_type": "storage", "vendor": "synology"}})
    blank = A(7)
    portdb = A(8)  # only a discovery observation: 5432 listening
    web = A(9, name="shop.example.com", origin_source="easm", internet_facing=True, platform_properties={"external_probe": {
        "live": True, "status_code": 200, "scheme": "https", "title": "Shop", "server": "cloudflare",
        "cdn_waf": "Cloudflare", "ip": "1.2.3.4", "content_type": "text/html", "tls_days_to_expiry": 12}})
    api = A(10, name="api.example.com", origin_source="easm", internet_facing=True, platform_properties={"external_probe": {
        "live": True, "status_code": 200, "scheme": "https", "content_type": "application/json", "asn_org": "AMAZON-02",
        "ip": "5.6.7.8"}})
    rdp = A(11, name="vpn.example.com", origin_source="easm", internet_facing=True)
    unprobed = A(12, name="mail.example.com", origin_source="easm", internet_facing=True)
    dangling = A(13, name="old.example.com", origin_source="easm", internet_facing=True,
                 platform_properties={"external_probe": {"live": False, "ip": None, "dns_a": []}})
    bareip = A(14, name="203.0.113.9", internet_facing=True)

    assert classify_internal(laptop, "host", {}) == ("Workstation / endpoint", "Windows 11")  # 'server' kind is a placeholder
    assert refine_server(laptop, {}) is not None  # has a DB product...
    assert classify_internal(winsrv, None, {}) == ("Server", "Windows Server 2012 R2")
    assert classify_internal(dbsrv, None, {}) == ("Server", "Ubuntu 22.04") and refine_server(dbsrv, {}) == ("Database", "PostgreSQL")
    assert classify_internal(fw, None, {}) == ("Network device", "Firewall")
    assert classify_internal(esx, None, {}) == ("Virtualization", "Hypervisor host")
    assert classify_internal(nas, None, fingerprint(nas)) == ("Storage", "NAS / storage array")
    assert classify_internal(blank, None, {}) == ("Unidentified", "No identifying signal")
    assert classify_internal(portdb, "database", {"product": "postgres"}) == ("Database", "PostgreSQL")
    assert classify_external(web, set()) == ("Web application", "CDN / WAF-fronted")
    assert classify_external(api, set()) == ("API", "Cloud-hosted")
    assert classify_external(rdp, {443, 3389}) == ("Remote / admin service", "Remote access (SSH / RDP / VNC)")
    assert classify_external(unprobed, set()) == ("Domain / subdomain", "Not yet probed")
    assert classify_external(dangling, set()) == ("Domain / subdomain", "Doesn't resolve")
    assert classify_external(bareip, set()) == ("Unidentified", "No outside-in evidence")

    out = summarize([laptop, winsrv, dbsrv, fw, esx, nas, blank, portdb, web, api, rdp, unprobed, dangling, bareip],
                    cis_ids={2}, ports={11: {443, 3389}}, dtypes={1: "host", 8: "database"}, now=now)
    by = {c["label"]: c for c in out["internal"]["classes"]}
    assert out["total"] == 14 and out["external"]["total"] == 6 and out["internal"]["total"] == 8
    assert by["Workstation / endpoint"]["n"] == 1 and by["Server"]["n"] == 1 and by["Database"]["n"] == 2  # laptop stays an endpoint
    assert by["Server"]["cis"] == 1 and by["Server"]["eol"]["past"] == 1  # 2012 R2 extended support ended 2023-10-10
    assert [c["label"] for c in out["external"]["classes"]] == list(EXTERNAL)  # fixed buckets, zeros kept
    assert out["external"]["classes"][0]["cis"] is None and out["external"]["facets"]["tls_expiring_30d"] == 1
    os_rows = {o["label"]: o for o in out["internal"]["os"]}
    assert out["unidentified"] == 2 and os_rows["Windows Server"]["n"] == 1 and os_rows["Windows client"]["n"] == 1
    assert os_rows["Windows client"]["subtypes"][0]["label"] == "Windows 11" and os_rows["Linux"]["subtypes"][0]["label"] == "Ubuntu 22.04"
    assert {h["label"]: h["n"] for h in out["external"]["hosting"]} == {
        "CDN / WAF-fronted": 1, "Cloud-hosted": 1, "Hosting provider / ISP": 0, "Hosting unknown": 1, "Not yet probed": 3}
    assert {v["label"]: v["n"] for v in out["external"]["verification"]} == {
        "Live web service": 2, "Open non-web ports": 1, "No web response": 0, "Doesn't resolve": 1, "Not yet probed": 2}
    assert os_bucket("Windows", "Windows (version not profiled)") == "Windows (edition unknown)"
    assert summarize([], set(), {}, {}, now)["total"] == 0
    print("estate_overview self-check OK")
