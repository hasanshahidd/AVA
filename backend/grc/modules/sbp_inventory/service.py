"""Build the SBP inventory row for an asset (derive what Ava collects, merge the
stored overrides), save stored fields, and export the whole tenant as the SBP
template .xlsx. No writes to ITAsset — stored values live in SbpAssetInventory.
"""
from __future__ import annotations

import io
import re
from datetime import datetime
from typing import Any, Dict, List, Optional

from sqlalchemy.orm import Session

from grc.models import ITAsset, PentestExploitResult, Vulnerability, VulnerabilityAssetLink
from grc.services.asset_criticality import derive_bucket
from . import registry as R
from . import vendor_feeds
from .models import SbpAssetInventory

_YN = lambda b: "Yes" if b else "No"
# Filled when a column is known NOT to apply (not a DB / not obsolete / control
# present / not public) — the bank's own template uses this exact wording.
_NA = "Not Applicable"


def ensure_table(db: Session) -> None:
    SbpAssetInventory.__table__.create(bind=db.get_bind(), checkfirst=True)


def _d(dt) -> str:
    return dt.strftime("%Y-%m-%d") if isinstance(dt, datetime) else ""


def _subnet(ip: Optional[str]) -> str:
    if not ip:
        return ""
    try:
        o = int(str(ip).split(".")[0])
    except (ValueError, IndexError):
        return ""
    if 1 <= o <= 126: return "A"
    if 128 <= o <= 191: return "B"
    if 192 <= o <= 223: return "C"
    if 224 <= o <= 239: return "D"
    return "E"


def _os(a: ITAsset) -> str:
    v = getattr(a, "os_version", None)
    if v:
        return str(v)
    fam = getattr(a, "os_family", None) or ""
    build = getattr(a, "os_build", None) or ""
    return (f"{fam} {build}").strip()


def _dbms(a: ITAsset) -> str:
    """R 'DBMS version': each engine's product line ('PostgreSQL 18; MariaDB 12.3')."""
    return "; ".join(dict.fromkeys(_product_line(n, v) for n, v in _db_engines(a)))


def _pp_data(a: ITAsset, section: str) -> Any:
    """platform_properties[section]['data'] from the deep scan, or None."""
    pp = getattr(a, "platform_properties", None) or {}
    blk = pp.get(section) if isinstance(pp, dict) else None
    return blk.get("data") if isinstance(blk, dict) else None


def _edr_agents(a: ITAsset) -> list:
    sec = _pp_data(a, "security_products")
    return [e for e in ((sec or {}).get("edr_xdr") or []) if isinstance(e, dict)] \
        if isinstance(sec, dict) else []


def _edr(a: ITAsset) -> str:
    """Yes only when an EDR/XDR agent is RUNNING — an installed-but-stopped agent
    protects nothing. Reads the deep scan's security-products read first (the
    posture summary has missed agents the scan saw), else the posture summary;
    '' when neither was collected (never fabricate a "No")."""
    agents = _edr_agents(a)
    if agents:
        return _YN(any(e.get("running") for e in agents))
    if isinstance(_pp_data(a, "security_products"), dict):
        return "No"  # security products were read and none is an EDR
    sp = getattr(a, "security_posture", None)
    if not isinstance(sp, dict) or "has_edr" not in sp:
        return ""
    return _YN(bool(sp.get("has_edr")))


def _av_note(a: ITAsset) -> str:
    """One factual line on the host antivirus, from the deep scan."""
    d = _pp_data(a, "defender")
    if isinstance(d, dict) and d.get("antivirus_enabled"):
        return ("Microsoft Defender Antivirus is enabled"
                + (" with real-time protection." if d.get("realtime_protection")
                   else ", but real-time protection is OFF."))
    sec = _pp_data(a, "security_products")
    av = [x.get("name") for x in ((sec or {}).get("antivirus") or [])
          if isinstance(x, dict) and x.get("enabled")] if isinstance(sec, dict) else []
    return f"Antivirus active: {', '.join(av)}." if av else ""


# Host-installed agent signatures — the SAME host-software signal EDR already uses.
# "Yes" when a known agent is in the collected inventory, "No" when inventory
# exists but none found, "" when there is no software inventory to judge from.
_DLP_SIGS = ("forcepoint", "digital guardian", "symantec dlp", "mcafee dlp",
             "trellix dlp", "netskope", "code42", "safetica", "endpoint dlp",
             "gtb inspector", "teramind", "zscaler")
_SIEM_SIGS = ("splunk", "universalforwarder", "splunkforwarder", "wazuh",
              "winlogbeat", "filebeat", "elastic agent", "elastic-agent", "nxlog",
              "syslog-ng", "rsyslog", "wincollect", "logrhythm", "arcsight",
              "fluentd", "fluent-bit", "cribl", "datadog agent",
              "microsoft monitoring agent", "azure monitor agent")
_DAM_SIGS = ("imperva", "guardium", "datasunrise", "dbprotect", "jsonar",
             "mcafee database", "trellix database")
# WAF / IPS / virtual-patching agents. Trend Micro Deep Security ("ds_agent") is
# the canonical host virtual-patching product; the rest are WAF/IPS agents that
# shield an unpatched app. Specific product tokens only — no bare "waf"/"asm".
_VPATCH_SIGS = ("modsecurity", "mod_security", "imperva", "securesphere",
                "big-ip", "bigip", "f5 networks", "fortiweb", "cloudflare",
                "akamai", "kona site defender", "deep security", "ds_agent",
                "tippingpoint", "signal sciences", "nginx app protect",
                "app protect", "barracuda web", "citrix adc", "netscaler",
                "snort", "suricata")


def _software_names(a: ITAsset) -> list:
    names = []
    sw = getattr(a, "detected_software_json", None) or []
    if isinstance(sw, list):
        for s in sw:
            n = s.get("name") if isinstance(s, dict) else s
            if n:
                names.append(str(n).lower())
    sp = getattr(a, "security_posture", None)
    if isinstance(sp, dict):
        for t in (sp.get("security_tools") or []):
            names.append(str(t).lower())
    return names


def _detect(a: ITAsset, sigs) -> str:
    names = _software_names(a)
    if not names:
        return ""  # no inventory collected -> unknown, leave for a human
    return "Yes" if any(any(sig in n for sig in sigs) for n in names) else "No"


# Server-ROLE evidence: the products that make a host a web/app or database
# server, matched on installed software AND Windows service names. Client tools,
# drivers and dev stubs (SSMS, psqlODBC, pgAdmin, Workbench, IIS Express,
# Node.js, RedisInsight) never match. NB platform_kind "server" is only the UI
# placeholder for ANY agentless OS host — it is never evidence of a role.
_WEB_RX = re.compile(
    r"^(odoo\b|apache http server|apache2?(\.\d+)?$|httpd$|nginx\b|apache tomcat|"
    r"tomcat\d*$|jboss|wildfly|weblogic|websphere|glassfish|jetty\b|lighttpd|"
    r"caddy\b|w3svc$|world wide web publishing service)")
_DB_RX = re.compile(
    r"^(postgresql([- ]\d+(\.\d+)?|\d*-server|-x64-\d+)?$|mysql[- ]server|mysql\d*$|"
    r"mariadb([- ]server|[- ]\d|$)|microsoft sql server 20\d\d( r2)? \(64-bit\)$|"
    r"sql server \(|mssqlserver$|mssql\$|oracle database|oracleservice|"
    r"mongodb([- ]org[- ]server|[- ]server|[- ]\d|$)|mongod$|"
    r"redis([- ]server| on windows|[- ]\d|$)|ibm db2|db2 server|sybase)")


def _software(a: ITAsset) -> list:
    """[(name, version)] from the collected software inventory, original case."""
    out = []
    for s in (getattr(a, "detected_software_json", None) or []):
        n = s.get("name") if isinstance(s, dict) else s
        if n:
            out.append((str(n), str(s.get("version") or "") if isinstance(s, dict) else ""))
    return out


def _services(a: ITAsset) -> list:
    """Windows service names + display names from the deep scan."""
    pp = getattr(a, "platform_properties", None) or {}
    blk = pp.get("services") if isinstance(pp, dict) else None
    data = blk.get("data") if isinstance(blk, dict) else None
    return [str(s[k]) for s in (data if isinstance(data, list) else [])
            if isinstance(s, dict) for k in ("name", "display_name") if s.get(k)]


def _role_evidence(a: ITAsset, rx) -> list:
    """Products proving a server role: software names, else service names."""
    hit = lambda names: list(dict.fromkeys(n for n in names if rx.search(n.lower().strip())))
    return hit(n for n, _v in _software(a)) or hit(_services(a))


def _role(a: ITAsset, rx, kind: Optional[str] = None) -> str:
    """'Yes' when a server product of this role is installed/registered (or a
    typed collector connected the asset as one), 'No' when an inventory exists
    and none is, '' when nothing is known (left for a human)."""
    if (kind and getattr(a, "platform_kind", None) == kind) or _role_evidence(a, rx):
        return "Yes"
    return "No" if (_software(a) or _services(a)) else ""


def _is_db(a: ITAsset) -> str:
    return _role(a, _DB_RX, "database")


def _is_web(a: ITAsset) -> str:
    r = _role(a, _WEB_RX)
    # a typed database-collector asset IS the DB instance, not a web server
    return "No" if (r == "" and getattr(a, "platform_kind", None) == "database") else r


_VER_KEYS = ("version", "db_version", "engine_version", "server_version", "dbms_version")


def _db_engines(a: ITAsset) -> list:
    """[(name, version)] of the host's database engines: installed software, or
    the engine a typed DB collector connected to."""
    eng = [(n, v) for n, v in _software(a) if _DB_RX.search(n.lower().strip())]
    pp = getattr(a, "platform_properties", None) or {}
    if not eng and getattr(a, "platform_kind", None) == "database" and isinstance(pp, dict):
        ver = next((str(pp[k]) for k in _VER_KEYS if pp.get(k)), "")
        eng = [(str(pp.get("engine") or "Database engine"), ver)]
    return eng


def _product_line(name: str, version: str) -> str:
    """'MariaDB 12.3 (x64)' -> 'MariaDB 12.3'; 'Redis on Windows' v5.0.14.1 -> 'Redis 5.0'."""
    m = re.search(r"\d+(\.\d+)?", name) or re.search(r"\d+(\.\d+)?", version or "")
    label = vendor_feeds.db_label(name)
    return f"{label} {m.group(0)}" if m else label


# What each web/app product IS — says which kind of server it is (J) and what
# the application is (B). (pattern on the lowercased name, display label or
# None = keep the installed name, role, what the application is)
_APP_KINDS = [
    (r"^odoo\b", None, "application server",
     "open-source ERP / business-management suite, served as a web application"),
    (r"tomcat", None, "application server", "Java web-application server"),
    (r"jboss|wildfly", None, "application server", "Java EE application server"),
    (r"weblogic", None, "application server", "Oracle Java EE application server"),
    (r"websphere", None, "application server", "IBM Java EE application server"),
    (r"glassfish", None, "application server", "Java EE application server"),
    (r"^jetty\b", None, "application server", "Java web server"),
    (r"^w3svc$|world wide web publishing", "Microsoft IIS", "web server", "Microsoft web server"),
    (r"apache http server|^apache2?(\.\d+)?$|^httpd$", None, "web server", "Apache HTTP web server"),
    (r"^nginx\b", None, "web server", "web server / reverse proxy"),
    (r"lighttpd|^caddy\b", None, "web server", "lightweight web server"),
]


def _web_apps(a: ITAsset) -> list:
    """[(label, role, what it is)] for the host's web/app servers, deduped."""
    out: Dict[str, tuple] = {}
    for n in _role_evidence(a, _WEB_RX):
        hit = next(((lbl or n, role, what) for rx, lbl, role, what in _APP_KINDS
                    if re.search(rx, n.lower().strip())), (n, "web/app server", ""))
        out.setdefault(hit[0], hit)
    return list(out.values())


def _app_desc(a: ITAsset) -> str:
    """What the asset's APPLICATION is — not its data tier — as a factual draft
    from the detected server products ('' when nothing is known)."""
    apps = _web_apps(a)
    if apps:
        return "; ".join(f"{l} — {w}" if w else f"{l} ({r})" for l, r, w in apps)
    dbs = list(dict.fromkeys(_product_line(n, v) for n, v in _db_engines(a)))
    if dbs:
        return f"Database server hosting {', '.join(dbs)}"
    osv = _os(a)
    if osv and (_software(a) or _services(a)):
        if re.search(r"windows (7|8|8\.1|10|11)\b|mac ?os", osv.lower()):
            return f"End-user workstation ({osv}) — no hosted server applications detected"
        return f"{osv} host — no web/application or database server software detected"
    return ""


def _msrc_product(a: ITAsset) -> Optional[str]:
    """Microsoft Security Update Guide product name for a Windows host, e.g.
    'Windows 11 Version 25H2 for x64-based Systems' / 'Windows Server 2022'.
    LTSC editions share their base version's update stream."""
    s = f"{_os(a)} {getattr(a, 'os_build', None) or ''}".lower()
    m = re.search(r"windows server (\d{4})( r2)?", s)
    if m:
        return f"Windows Server {m.group(1)}{' R2' if m.group(2) else ''}"
    m = re.search(r"windows (1[01])\b", s)
    v = re.search(r"\b(1809|1903|1909|2004|2[0-5]h[12])\b", s)
    if not (m and v):
        return None
    pp = getattr(a, "platform_properties", None) or {}
    osd = ((pp.get("os") or {}).get("data") or {}) if isinstance(pp, dict) else {}
    arch = str(osd.get("architecture") or "64-bit").lower()
    plat = ("ARM64-based Systems" if "arm" in arch
            else "x64-based Systems" if "64" in arch else "32-bit Systems")
    return f"Windows {m.group(1)} Version {v.group(1).upper()} for {plat}"


def _db_currency(a: ITAsset) -> list:
    """Per DB engine: installed build vs the vendor's latest in its release
    cycle, plus the cycle's end-of-life (vendor feed; untracked engines skipped)."""
    today = datetime.utcnow().strftime("%Y-%m-%d")
    nums = lambda s: [int(x) for x in re.findall(r"\d+", s or "")]
    out = []
    for n, v in _db_engines(a):
        r = vendor_feeds.latest_db_release(n, v)
        if not r:
            continue
        label, cycle, latest, date, eol, cycle_release = r
        inst, lat = nums(v), nums(latest)
        out.append({"label": label, "cycle": cycle, "installed": v, "latest": latest,
                    "date": date, "eol": eol, "cycle_release": cycle_release,
                    "behind": bool(inst and lat) and inst[:len(lat)] < lat,
                    "eol_passed": eol == "yes" or (bool(eol) and eol <= today)})
    return out


def _installed_db_release(cur: list) -> str:
    """T: release date of the INSTALLED build — only where a vendor source states
    it: it IS the cycle's latest (that date), MariaDB's per-release API, or the
    cycle's first x.0 release (the cycle date). '' otherwise, never guessed."""
    nums = lambda s: [int(x) for x in re.findall(r"\d+", s or "")]
    known = []
    for c in cur:
        inst, lat, cyc = nums(c["installed"]), nums(c["latest"]), nums(c["cycle"])
        if lat and inst[:len(lat)] == lat:
            d = c["date"]
        elif c["label"] == "MariaDB":
            d = vendor_feeds.mariadb_release_date(c["installed"])
        elif cyc and inst[:len(cyc) + 1] == cyc + [0]:
            d = c["cycle_release"]
        else:
            d = ""
        if d:
            known.append((c["label"], d))
    if len(cur) == 1:
        return known[0][1] if known else ""
    return "; ".join(f"{l} {d}" for l, d in known)


def _db_field(a: ITAsset, value: Any) -> Any:
    """A database-only column: its value on a DB host, 'Not Applicable' on a
    host known NOT to be one, '' when that is unknown."""
    db = _is_db(a)
    return value if db == "Yes" else (_NA if db == "No" else "")


def _server_desc(a: ITAsset) -> str:
    """Compose a factual server description from real hardware/OS/model columns."""
    parts = []
    osv = _os(a)
    if osv:
        parts.append(osv)
    mk = " ".join(str(x) for x in (getattr(a, "manufacturer", None), getattr(a, "model", None)) if x)
    if mk:
        parts.append(mk)
    hw = []
    if getattr(a, "cpu_cores", None):
        hw.append(f"{a.cpu_cores} vCPU")
    if getattr(a, "memory_gb", None):
        hw.append(f"{a.memory_gb} GB RAM")
    if getattr(a, "storage_gb", None):
        hw.append(f"{a.storage_gb} GB disk")
    if hw:
        parts.append(", ".join(hw))
    return " · ".join(parts)


# Obsolescence: vendor END OF SUPPORT — the date security updates stop.
# ponytail: static table for the OSes Ava's collectors report; an OS that isn't
# listed stays blank for the analyst (never guessed). Each new OS release needs
# a row — upgrade path: sync from endoflife.date.
_WIN11 = {  # version: (Home/Pro, Enterprise/Education)
    "21h2": ("2023-10-10", "2024-10-08"), "22h2": ("2024-10-08", "2025-10-14"),
    "23h2": ("2025-11-11", "2026-11-10"), "24h2": ("2026-10-13", "2027-10-12"),
    "25h2": ("2027-10-12", "2028-10-10")}
_WIN10 = {
    "1809": ("2020-11-10", "2021-05-11"), "1903": ("2020-12-08", "2020-12-08"),
    "1909": ("2021-05-11", "2022-05-10"), "2004": ("2021-12-14", "2021-12-14"),
    "20h2": ("2022-05-10", "2023-05-09"), "21h1": ("2022-12-13", "2022-12-13"),
    "21h2": ("2023-06-13", "2024-06-11"), "22h2": ("2025-10-14", "2025-10-14")}
_WIN10_LTSC = {"2015": "2025-10-14", "2016": "2026-10-13",
               "2019": "2029-01-09", "2021": "2027-01-12"}
_WIN_SERVER = {"2003": "2015-07-14", "2008": "2020-01-14", "2012": "2023-10-10",
               "2016": "2027-01-12", "2019": "2029-01-09", "2022": "2031-10-14",
               "2025": "2034-11-14"}  # extended-support end; an R2 shares its base year
_EOL_RX = [  # checked in order — specific before general
    (r"windows xp", "2014-04-08"), (r"windows 7\b", "2020-01-14"),
    (r"windows 8\.1", "2023-01-10"), (r"windows 8\b", "2016-01-12"),
    (r"(red hat enterprise linux|rhel)\D*6\b", "2020-11-30"),
    (r"(red hat enterprise linux|rhel)\D*7\b", "2024-06-30"),
    (r"(red hat enterprise linux|rhel)\D*8\b", "2029-05-31"),
    (r"(red hat enterprise linux|rhel)\D*9\b", "2032-05-31"),
    (r"centos stream\D*8\b", "2024-05-31"),
    (r"centos\D*6\b", "2020-11-30"), (r"centos\D*7\b", "2024-06-30"),
    (r"centos(?! stream)\D*8\b", "2021-12-31"),
    (r"ubuntu\D*16\.04", "2021-04-30"), (r"ubuntu\D*18\.04", "2023-05-31"),
    (r"ubuntu\D*20\.04", "2025-05-31"),
    (r"debian\D*9\b", "2022-06-30"), (r"debian\D*10\b", "2024-06-30"),
    (r"debian\D*11\b", "2026-08-31"), (r"debian\D*12\b", "2028-06-30"),
]


def _vendor_eol(os_s: str) -> Optional[datetime]:
    """Vendor end-of-support date for an OS string, or None when not in the table."""
    s = (os_s or "").lower()
    d = None
    m = re.search(r"windows server (\d{4})", s)
    if m:
        d = _WIN_SERVER.get(m.group(1))
    elif re.search(r"windows 1[01]\b", s):
        if "ltsc" in s or "ltsb" in s:  # long-term channel runs on its own dates
            y = re.search(r"lts[bc]\D*(\d{4})", s)
            y = y.group(1) if y else None
            if "windows 10" in s:  # (Windows 11 LTSC isn't tabled -> stays blank)
                d = "2032-01-13" if (y == "2021" and "iot" in s) else _WIN10_LTSC.get(y)
        else:
            v = re.search(r"\b(1809|1903|1909|2004|2[0-5]h[12])\b", s)
            pair = (_WIN11 if "windows 11" in s else _WIN10).get(v.group(1)) if v else None
            if pair:
                d = pair[1 if re.search(r"enterprise|education", s) else 0]
    else:
        d = next((dd for rx, dd in _EOL_RX if re.search(rx, s)), None)
    return datetime.strptime(d, "%Y-%m-%d") if d else None


def _eol(a: ITAsset) -> Optional[datetime]:
    """End of vendor support: the asset's own eol_date when an analyst set one,
    else the vendor date for its detected OS; None when neither is known."""
    return getattr(a, "eol_date", None) or _vendor_eol(
        f"{_os(a)} {getattr(a, 'os_build', None) or ''}")


def _obsolescence_timeline(a: ITAsset) -> str:
    eol = _eol(a)
    if not eol:
        return ""
    now = datetime.utcnow()
    if eol <= now:
        return f"Obsolete since {eol.strftime('%Y-%m-%d')}"
    return f"EOL {eol.strftime('%Y-%m-%d')} ({(eol - now).days} days remaining)"


# VA vs PT (confirmed with the pentest-engine session, Sep 27 2026):
#  * The finding's LANE (Vulnerability.source) says which tool FOUND it — not the
#    link note, which the orchestrator stamps "AI pentest scan" on EVERY link.
#    Substring "pentestgpt" = PT; everything else = VA. Deliberately NO scanner
#    allowlist: find lanes are being de-branded to generic slugs
#    ("ai-pentest:scanner") and merged into union forms ("…:hexstrike+zap").
#  * A scanner finding the pentest then PROVED (grc_pentest_exploit_results
#    row, confirmed + CVE-specific) is ALSO a PT finding — found by VA,
#    exploited by PT — so it legitimately appears in both sections.
#  * "Last PT performed" = latest exploit run that actually ENGAGED the host:
#    "executed" (tool ran; confirmed says whether it proved the vuln) and
#    "confirmed-vulnerable" (Metasploit check proved it). "not-exploitable" is
#    dual-source — a pure classification (nothing ran) OR a Metasploit check that
#    RAN and came back safe (technique "Metasploit check — …") — only the latter
#    counts. needs-verification / manual / exploitable-unarmed / no-tool / error
#    fired nothing at the host. finding_id = str(vuln.id), else the CVE, else "".
_PT_LANES = ("pentestgpt",)
_PT_RAN = {"executed", "confirmed-vulnerable"}
_CLOSED = {"remediated", "resolved", "closed", "verified", "fixed", "false_positive"}


def _is_pt(source: Optional[str]) -> bool:
    return any(lane in (source or "").lower() for lane in _PT_LANES)


def _pt_ran(run) -> bool:
    st = (run.status or "").lower()
    return st in _PT_RAN or (st == "not-exploitable" and
                             (run.technique or "").lower().startswith("metasploit check"))


def _scan_block(rows, pre: str, date_key: str, activity=()) -> Dict[str, Any]:
    """One section's 5 columns. All blank (UNKNOWN — never '0 open') when nothing
    of this kind is evidenced, so a test that never ran isn't reported clean.
    `activity` = dates the test ran without producing a finding row (a PT exploit
    run that proved nothing still dates the PT, with 0 open)."""
    activity = [d for d in activity if d]
    if not rows and not activity:
        return {date_key: "", f"{pre}_open_critical": "", f"{pre}_days_critical_open": "",
                f"{pre}_open_high": "", f"{pre}_days_high_open": ""}
    now = datetime.utcnow()
    seen = [r.last_seen or r.discovered_at for r in rows if (r.last_seen or r.discovered_at)] + activity
    is_open = lambda r: (r.status or "open").lower().replace(" ", "_") not in _CLOSED
    opened = lambda sev: [r.discovered_at for r in rows
                          if (r.severity or "").lower() == sev and is_open(r)]
    # none open -> "days open" doesn't apply; dates missing -> unknown
    days = lambda ds: _NA if not ds else ((now - min(d for d in ds if d)).days if any(ds) else "")
    crit, high = opened("critical"), opened("high")
    return {date_key: _d(max(seen)) if seen else "",
            f"{pre}_open_critical": len(crit), f"{pre}_days_critical_open": days(crit),
            f"{pre}_open_high": len(high), f"{pre}_days_high_open": days(high)}


def _split_scans(rows, runs=()) -> Dict[str, Any]:
    ran = [r for r in runs if _pt_ran(r)]
    # a generic credentialed proof (cve_specific False) proves access, not THIS
    # finding; an ad-hoc finding may be keyed by its CVE instead of the vuln id
    proven = {str(r.finding_id) for r in runs
              if r.confirmed and r.cve_specific is not False and r.finding_id}
    pt = [r for r in rows if _is_pt(r.source) or str(r.id) in proven
          or (getattr(r, "cve_id", None) or "") in proven]
    out = _scan_block([r for r in rows if not _is_pt(r.source)], "va", "last_va_date")
    out.update(_scan_block(pt, "pt", "last_pt_date", [r.created_at for r in ran]))
    return out


def _scan_blocks(db: Session, tenant_id: int, asset_id: int) -> Dict[str, Any]:
    return _split_scans(*_scan_rows(db, tenant_id, asset_id))


def scan_sources(db: Session, tenant_id: int, asset_id: int) -> Dict[str, Any]:
    """Where this asset's VA / PT columns come from — shown beside the Sync
    button so the analyst sees exactly what was pulled in."""
    rows, runs = _scan_rows(db, tenant_id, asset_id)
    va = [r for r in rows if not _is_pt(r.source)]
    lanes: Dict[str, int] = {}
    for r in va:  # "ai-pentest:openvas" -> "openvas"
        lane = (r.source or "manual").split(":")[-1]
        lanes[lane] = lanes.get(lane, 0) + 1
    return {"va_findings": len(va), "va_lanes": lanes,
            "pt_findings": sum(1 for r in rows if _is_pt(r.source)),
            "exploit_runs": len([r for r in runs if _pt_ran(r)]),
            "exploits_confirmed": sum(1 for r in runs if r.confirmed),
            "synced_at": datetime.utcnow().isoformat(timespec="seconds") + "Z"}


def _scan_rows(db: Session, tenant_id: int, asset_id: int) -> tuple:
    rows = (
        db.query(Vulnerability.id, Vulnerability.cve_id, Vulnerability.severity,
                 Vulnerability.status, Vulnerability.discovered_at, Vulnerability.last_seen,
                 Vulnerability.source)
        .join(VulnerabilityAssetLink, VulnerabilityAssetLink.vulnerability_id == Vulnerability.id)
        .filter(VulnerabilityAssetLink.asset_id == asset_id, Vulnerability.tenant_id == tenant_id)
        .all()
    )
    runs = (
        db.query(PentestExploitResult.finding_id, PentestExploitResult.status,
                 PentestExploitResult.technique, PentestExploitResult.confirmed,
                 PentestExploitResult.cve_specific, PentestExploitResult.created_at)
        .filter(PentestExploitResult.tenant_id == tenant_id,
                PentestExploitResult.asset_id == asset_id)
        .all()
    )
    return rows, runs


def _required_patch(db: Session, tenant_id: int, asset_id: int, kind: str, a: ITAsset = None) -> str:
    """Latest patch the host still NEEDS, from the KB/patch references a credentialed
    scanner attaches to its findings (`Vulnerability.patch_references`). kind='os' →
    newest KB-type reference; kind='db' → newest reference on a database host. ''
    when no finding carries a patch reference (e.g. info-only scans) — Ava holds no
    vendor patch catalog, so this fills only from real scan data, never invented."""
    if kind == "db" and _is_db(a) != "Yes":
        return ""
    rows = (
        db.query(Vulnerability.patch_references)
        .join(VulnerabilityAssetLink, VulnerabilityAssetLink.vulnerability_id == Vulnerability.id)
        .filter(VulnerabilityAssetLink.asset_id == asset_id, Vulnerability.tenant_id == tenant_id)
        .all()
    )
    ids = []
    for (pr,) in rows:
        if not isinstance(pr, list):
            continue
        for ref in pr:
            if not isinstance(ref, dict) or not ref.get("id"):
                continue
            if kind == "os" and str(ref.get("type", "")).lower() != "kb":
                continue
            ids.append(str(ref["id"]))
    if not ids:
        return ""
    num = lambda x: int(re.search(r"\d+", x).group()) if re.search(r"\d+", x) else 0
    return max(set(ids), key=num)  # highest KB/patch number ≈ the newest one needed


def _norm_date(s: Any) -> str:
    """Best-effort normalise a captured date string to YYYY-MM-DD. Keeps the raw
    string if it can't be parsed — never fabricates a date."""
    raw = str(s or "").strip()
    if not raw:
        return ""
    core = raw.split(" ")[0].split("T")[0]  # drop any time component
    for fmt in ("%m/%d/%Y", "%Y-%m-%d", "%d/%m/%Y", "%m/%d/%y", "%d-%m-%Y"):
        try:
            return datetime.strptime(core, fmt).strftime("%Y-%m-%d")
        except ValueError:
            continue
    return raw


def _hotfixes(a: ITAsset) -> list:
    """The deep scan's Get-HotFix list (platform_properties.windows_update)."""
    data = _pp_data(a, "windows_update")
    rec = data.get("recent_hotfixes") if isinstance(data, dict) else None
    return [h for h in (rec or []) if isinstance(h, dict) and h.get("id")]


def _win_last_patch(a: ITAsset) -> tuple:
    """(kb, install_date) of the most recently INSTALLED security update (any
    update when types weren't captured), from the deep scan's Get-HotFix output.
    ('','') for a non-Windows host or when no patch history was collected. The
    RELEASE date comes from Microsoft's feed (build_row), not from this."""
    fixes = _hotfixes(a)
    sec = [h for h in fixes if "security" in str(h.get("type") or "").lower()]
    pick = sorted(sec or fixes, key=lambda h: _norm_date(h.get("installed")), reverse=True)
    if pick:
        return str(pick[0]["id"]), _norm_date(pick[0].get("installed"))
    data = _pp_data(a, "windows_update")
    if not isinstance(data, dict) or not data.get("last_hotfix"):
        return "", ""
    return str(data["last_hotfix"]), _norm_date(data.get("last_installed"))


def _running_services(a: ITAsset) -> list:
    data = _pp_data(a, "services")
    return [str(s["name"]) for s in (data if isinstance(data, list) else [])
            if isinstance(s, dict) and s.get("name")
            and str(s.get("state") or "").lower() == "running"]


def _db_patch(a: ITAsset) -> str:
    """The APPLIED database patch/build level the typed collector read from the
    engine (MSSQL product_level + build; the version string is the patch level
    for the others), else each installed engine's exact version. '' for a
    non-database asset. The vendor's LATEST patch and the patch DATE are not
    held by Ava, so those columns stay manual."""
    if getattr(a, "platform_kind", None) != "database":
        return "; ".join(f"{vendor_feeds.db_label(n)} {v}" for n, v in _db_engines(a) if v)
    pp = getattr(a, "platform_properties", None) or {}
    if not isinstance(pp, dict):
        return ""
    ver = next((str(pp[k]) for k in _VER_KEYS if pp.get(k)), "")
    lvl = pp.get("product_level")  # MSSQL only: RTM / SPn / CUn — a real patch level
    if lvl and ver:
        return f"{lvl} · {ver}"
    return str(lvl or ver or "")


def _integrated_bmc(a: ITAsset) -> str:
    """Yes/No. Ava has no BMC/CMDB asset-sync connector (the only BMC provider,
    bmc_remedy, is ticketing-only and never stamps assets), so the truthful value
    is 'No' for every asset — unless one was explicitly sourced from a BMC system
    (future-proofs the Yes case without ever asserting a false Yes today)."""
    src = " ".join(str(getattr(a, c, "") or "")
                   for c in ("source_system", "last_seen_source", "origin_source")).lower()
    return "Yes" if ("bmc" in src or "remedy" in src) else "No"


_DR_TOKENS = ("dr", "standby", "replica", "secondary", "failover", "passive")


def _primary_dr(a: ITAsset) -> str:
    """'DR' when indicated — environment == dr, a name/fqdn token
    (dr/standby/replica/secondary/failover/passive), or a database reporting a
    standby/replica role; otherwise 'Primary' (editable — the analyst corrects
    a DR asset that carries none of those markers)."""
    if str(getattr(a, "environment", "") or "").lower() == "dr":
        return "DR"
    hay = " ".join(str(getattr(a, c, "") or "")
                   for c in ("name", "host_name", "fqdn")).lower()
    for tok in _DR_TOKENS:
        if re.search(r'(?<![a-z])' + tok + r'(?![a-z])', hay):
            return "DR"
    pp = getattr(a, "platform_properties", None) or {}
    if isinstance(pp, dict):
        for sec in ("replication", "high_availability", "instance"):
            blk = pp.get(sec)
            data = blk.get("data") if isinstance(blk, dict) else None
            if isinstance(data, dict):
                role = str(data.get("role") or data.get("database_role") or "").lower()
                if any(w in role for w in ("standby", "replica", "recovery")):
                    return "DR"
    return "Primary"


# SBP column I offers Production / Dev / UAT. A word-bounded name marker first
# (so "testasp.vulnweb.com" is not a test box), else Production — editable.
_ENV_MARKERS = [(r"uat|sit|preprod|pre-prod|staging|stg|test|qa", "UAT"),
                (r"dev|development|sandbox", "Dev"),
                (r"prod|production|live", "Production")]
_ENV_NAMES = {"production": "Production", "prod": "Production", "live": "Production",
              "development": "Dev", "dev": "Dev", "sandbox": "Dev", "uat": "UAT",
              "test": "UAT", "testing": "UAT", "qa": "UAT", "staging": "UAT"}


def _environment(a: ITAsset) -> str:
    """The asset's own environment when set; else a name/fqdn marker; else
    'Production' (an inventoried asset's default — the analyst corrects it)."""
    own = str(getattr(a, "environment", "") or "").strip()
    if own:
        return _ENV_NAMES.get(own.lower(), own.title())
    hay = " ".join(str(getattr(a, c, "") or "") for c in ("name", "host_name", "fqdn")).lower()
    for rx, env in _ENV_MARKERS:
        if re.search(rf"(?<![a-z])({rx})(?![a-z])", hay):
            return env
    return "Production"


def _classification(a: ITAsset) -> str:
    """The asset's criticality when set, else Ava's own criticality model run on
    the asset's CIA / data-classification / exposure / business-function inputs
    (it rates an asset with none of those 'Medium' — never silently 'Low')."""
    c = getattr(a, "criticality", None)
    if c:
        return str(c).title()
    return derive_bucket(
        confidentiality_rating=getattr(a, "confidentiality_rating", None),
        integrity_rating=getattr(a, "integrity_rating", None),
        availability_rating=getattr(a, "availability_rating", None),
        data_classification=getattr(a, "data_classification", None),
        internet_facing=bool(getattr(a, "internet_facing", False)),
        business_function=getattr(a, "business_function", None),
    ).title()


def _installed_kbs(a: ITAsset) -> set:
    return {str(h["id"]).upper() for h in _hotfixes(a)}


# Deterministic justification drafts — emitted ONLY when the DETECTED gap is real.
# Factual + editable, never an invented business excuse; "Not Applicable" when the
# condition is known not to hold, blank when it is genuinely unknown.
_OWNER = "To be confirmed by the asset owner."
_REASON_TEXT = {
    "reason_obsolete_os":         "Operating system is past its vendor end-of-support date — upgrade/replacement plan to be confirmed by the asset owner.",
    "reason_not_bmc":             "Asset is not integrated with a BMC/CMDB system — no BMC asset-sync connector is configured in Ava; integration status to be confirmed by the asset owner.",
    "reason_no_virtual_patching": "No virtual-patching (WAF/IPS) agent was detected in the latest software inventory — status to be confirmed by the asset owner.",
    "reason_dlp":                 "No DLP agent was detected in the latest software inventory — status to be confirmed by the asset owner.",
    "reason_public_dmz":          "Asset resolves to a public / internet-facing address in Ava's scan data — DMZ placement and exposure to be confirmed by the asset owner.",
    "reason_db_monitoring":       "No database-activity-monitoring agent was detected on this database host — status to be confirmed by the asset owner.",
    "reason_siem":                "No SIEM log-forwarding agent was detected in the latest software inventory — status to be confirmed by the asset owner.",
}


def _open_ch(va: Dict[str, Any]) -> Optional[int]:
    """Open critical+high VA findings; None when no VA is evidenced."""
    if not va.get("last_va_date"):
        return None
    try:
        return int(va.get("va_open_critical") or 0) + int(va.get("va_open_high") or 0)
    except (TypeError, ValueError):
        return 0


def _os_patch_reason(a: ITAsset, va: Dict[str, Any]) -> str:
    """Patch currency from facts: Microsoft's latest security update vs the
    host's installed-update list, plus the open critical/high count."""
    n = _open_ch(va)
    found = (f" {n} open critical/high finding{'' if n == 1 else 's'} in the latest "
             f"vulnerability scan.") if n else ""
    latest, rel = str(va.get("latest_os_patch") or ""), va.get("latest_os_patch_date") or ""
    kbs = _installed_kbs(a)
    if latest.upper().startswith("KB") and kbs:
        if latest.upper() in kbs:
            return (f"Microsoft's latest security update {latest} ({rel}) is installed."
                    f"{found} {_OWNER}") if n else _NA
        last_kb, last_rel = _win_last_patch(a)[0], va.get("last_os_patch_date") or ""
        return (f"Microsoft's latest security update {latest} (released {rel}) is not "
                f"installed; the newest installed security update is {last_kb}"
                f"{f' (released {last_rel})' if last_rel else ''}.{found} {_OWNER}")
    if n is None:
        return ""  # no vendor feed and no scan -> unknown
    return f"Patch-currency review recommended —{found} {_OWNER}" if n else _NA


def _db_patch_reason(a: ITAsset, va: Dict[str, Any]) -> str:
    """Per-engine currency from the vendor feed: installed vs latest, and a
    release line past its end of life."""
    db = _is_db(a)
    if db != "Yes":
        return _NA if db == "No" else ""
    cur = va.get("db_currency")
    if not cur:
        return ""  # vendor feed unavailable -> unknown, never guessed
    gaps = []
    for c in cur:
        if c["behind"]:
            gaps.append(f"{c['label']} {c['installed']} installed, latest is {c['latest']}"
                        + (f" (released {c['date']})" if c["date"] else ""))
        if c["eol_passed"]:
            gaps.append(f"{c['label']} {c['cycle']} line reached end of life"
                        + (f" on {c['eol']}" if c["eol"] not in ("", "yes") else ""))
    if not gaps:
        return _NA
    return "Database patch gaps: " + "; ".join(gaps) + ". Upgrade plan to be confirmed by the asset owner."


def _role_reason(a: ITAsset, web: bool) -> str:
    """Why it's a web/app or database server: the products, where they were
    found, and which of their services are running."""
    state = _is_web(a) if web else _is_db(a)
    if state != "Yes":
        return _NA if state == "No" else ""
    what = ([f"{l} ({r})" for l, r, _w in _web_apps(a)] if web
            else list(dict.fromkeys(_product_line(n, v) for n, v in _db_engines(a))))
    rx = _WEB_RX if web else _DB_RX
    running = [s for s in _running_services(a) if rx.search(s.lower())]
    src = ("Ava's database collector connection" if (not web and not _software(a))
           else "the installed software")
    return (f"Hosts {', '.join(what)} — found in {src}"
            + (f"; running service{'s' if len(running) > 1 else ''}: {', '.join(running)}"
               if running else "")
            + ". Classification to be confirmed by the asset owner.")


def _edr_reason(a: ITAsset) -> str:
    state = _edr(a)
    if state != "No":
        return _NA if state == "Yes" else ""
    stopped = [e for e in _edr_agents(a) if not e.get("running")]
    if stopped:
        e = stopped[0]
        head = (f"{e.get('product') or 'An EDR/XDR agent'} is installed but its service "
                f"({e.get('service') or 'agent'}) is {str(e.get('status') or 'not running').lower()}"
                " — EDR/XDR protection is not active.")
    else:
        head = "No XDR/EDR agent was detected in the latest scan."
    return " ".join(x for x in (head, _av_note(a), _OWNER) if x)


def _reason_value(key: str, a: ITAsset, va: Optional[Dict[str, Any]] = None) -> str:
    """Tri-state: the gap-tied draft when the DETECTED gap is real; 'Not
    Applicable' when the condition is known NOT to hold (control present / not a
    DB / not obsolete / not public / patch-current); '' when unknown."""
    va = va or {}
    tri = lambda state, text: text if state == "Yes" else (_NA if state == "No" else "")
    if key == "reason_os_patch":
        return _os_patch_reason(a, va)
    if key == "reason_db_patch":
        return _db_patch_reason(a, va)
    if key == "reason_obsolete_os":
        eol = _eol(a)
        return "" if not eol else tri(_YN(eol <= datetime.utcnow()), _REASON_TEXT[key])
    if key in ("reason_web_app", "reason_db_server"):
        return _role_reason(a, web=key == "reason_web_app")
    if key == "reason_no_xdr_edr":
        return _edr_reason(a)
    if key == "reason_db_monitoring":
        if _is_db(a) != "Yes":
            return tri(_is_db(a), "")
        dam = _detect(a, _DAM_SIGS)  # the gap is its ABSENCE
        return tri({"No": "Yes", "Yes": "No"}.get(dam, ""), _REASON_TEXT[key])
    if key == "reason_public_dmz":
        return tri(_YN(bool(getattr(a, "internet_facing", False))), _REASON_TEXT[key])
    control = {"reason_not_bmc": _integrated_bmc,
               "reason_no_virtual_patching": lambda x: _detect(x, _VPATCH_SIGS),
               "reason_dlp": lambda x: _detect(x, _DLP_SIGS),
               "reason_siem": lambda x: _detect(x, _SIEM_SIGS)}.get(key)
    if not control:
        return ""
    present = control(a)  # the gap is the control's ABSENCE
    return tri({"No": "Yes", "Yes": "No"}.get(present, ""), _REASON_TEXT[key])


def _base_value(key: str, a: ITAsset, va: Dict[str, Any]) -> Any:
    """The auto value BEFORE any stored override, for one field key."""
    if key == "asset_name":        return getattr(a, "name", None) or ""
    if key == "ip_address":        return getattr(a, "ip_address", None) or ""
    if key == "application_description":  # the asset's own text wins; else a factual draft
        return getattr(a, "description", None) or _app_desc(a)
    if key == "environment":       return _environment(a)
    if key == "subnet":            return _subnet(getattr(a, "ip_address", None))
    if key == "public_facing_dmz": return _YN(bool(getattr(a, "internet_facing", False)))
    if key == "os_with_version":   return _os(a)
    if key == "dbms_version":      return _db_field(a, _dbms(a))
    if key == "xdr_edr":           return _edr(a)
    if key == "server_description": return _server_desc(a)
    if key == "classification":    return _classification(a)
    if key == "dlp":               return _detect(a, _DLP_SIGS)
    if key == "siem_coverage":     return _detect(a, _SIEM_SIGS)
    if key == "db_monitoring":     return _db_field(a, _detect(a, _DAM_SIGS))
    if key == "obsolescence_timeline": return _obsolescence_timeline(a)
    if key == "database_server":   # WHICH engines, not just "Yes"
        d = _is_db(a)
        return (", ".join(dict.fromkeys(vendor_feeds.db_label(n) for n, _v in _db_engines(a)))
                if d == "Yes" else d)
    if key == "web_app_server":    # WHICH server, and whether web or application
        w = _is_web(a)
        return "; ".join(f"{l} ({r})" for l, r, _w in _web_apps(a)) if w == "Yes" else w
    if key == "obsolescence_status":
        eol = _eol(a)
        return "" if not eol else ("Y" if eol <= datetime.utcnow() else "N")
    if key == "obsolete_since_days":
        eol = _eol(a)
        if not eol:
            return ""
        return (datetime.utcnow() - eol).days if eol <= datetime.utcnow() else _NA
    if key == "virtual_patching":  return _detect(a, _VPATCH_SIGS)
    if key == "integrated_bmc":    return _integrated_bmc(a)
    if key == "primary_dr":        return _primary_dr(a)
    if key == "last_os_patch":     return _win_last_patch(a)[0]
    # Microsoft's RELEASE date for that KB (build_row) — not the install date
    if key == "last_os_patch_date": return va.get("last_os_patch_date", "")
    if key == "last_db_patch":     return _db_field(a, _db_patch(a))
    if key == "latest_db_patch":   return _db_field(a, va.get("latest_db_patch", ""))
    if key == "latest_db_patch_date": return _db_field(a, va.get("latest_db_patch_date", ""))
    if key == "last_db_patch_date": return _db_field(a, va.get("last_db_patch_date", ""))
    if key.startswith("reason_"):  return _reason_value(key, a, va)
    if key in va:
        return va[key]
    return ""  # everything else is stored/reason -> no auto value


def get_stored(db: Session, tenant_id: int, asset_id: int) -> Dict[str, Any]:
    ensure_table(db)
    row = db.query(SbpAssetInventory).filter_by(tenant_id=tenant_id, asset_id=asset_id).first()
    return dict(row.data or {}) if row else {}


def build_row(db: Session, tenant_id: int, asset: ITAsset) -> List[Dict[str, Any]]:
    va = _scan_blocks(db, tenant_id, asset.id)
    # latest patch = the VENDOR's newest release (feed); a scanner's required-KB
    # reference is the fallback when the feed is unreachable
    prod = _msrc_product(asset)
    osu = vendor_feeds.latest_windows_update(prod) if prod else None
    va["latest_os_patch"] = osu[0] if osu else _required_patch(db, tenant_id, asset.id, "os")
    va["latest_os_patch_date"] = osu[1] if osu else ""
    kb = _win_last_patch(asset)[0]
    va["last_os_patch_date"] = (vendor_feeds.windows_kb_release_date(kb)
                                if kb.upper().startswith("KB") else "")
    cur = _db_currency(asset)
    va["db_currency"] = cur
    va["latest_db_patch"] = ("; ".join(f"{c['label']} {c['latest']}" for c in cur)
                             or _required_patch(db, tenant_id, asset.id, "db", asset))
    va["latest_db_patch_date"] = (cur[0]["date"] if len(cur) == 1 else
                                  "; ".join(f"{c['label']} {c['date']}" for c in cur if c["date"]))
    va["last_db_patch_date"] = _installed_db_release(cur)
    stored = get_stored(db, tenant_id, asset.id)
    out: List[Dict[str, Any]] = []
    for (key, letter, label, group, src) in R.FIELDS:
        base = "" if src == "reason" else _base_value(key, asset, va)
        ov = stored.get(key)
        overridden = ov is not None and str(ov) != ""
        out.append({
            "key": key, "letter": letter, "label": label, "group": group, "src": src,
            "editable": key in R.STORABLE_KEYS,
            "value": ov if overridden else base,
            "auto_value": base,
            "overridden": overridden,
        })
    return out


def set_stored(db: Session, tenant_id: int, asset_id: int,
               values: Dict[str, Any], user: Optional[str] = None) -> Dict[str, Any]:
    ensure_table(db)
    row = db.query(SbpAssetInventory).filter_by(tenant_id=tenant_id, asset_id=asset_id).first()
    data = dict(row.data or {}) if row else {}
    for k, v in (values or {}).items():
        if k in R.STORABLE_KEYS:      # ignore anything not user-writable
            data[k] = v
    if row is None:
        row = SbpAssetInventory(tenant_id=tenant_id, asset_id=asset_id, data=data, updated_by=user)
        db.add(row)
    else:
        row.data = data
        row.updated_by = user
    db.commit()
    return data


def export_rows(db: Session, tenant_id: int) -> List[List[Any]]:
    assets = db.query(ITAsset).filter(ITAsset.tenant_id == tenant_id).order_by(ITAsset.id).all()
    rows = []
    for a in assets:
        by_key = {f["key"]: f["value"] for f in build_row(db, tenant_id, a)}
        rows.append([by_key.get(k, "") for (k, *_r) in R.FIELDS])
    return rows


def export_xlsx(db: Session, tenant_id: int) -> bytes:
    from openpyxl import Workbook
    wb = Workbook(); ws = wb.active; ws.title = "Asset Inventory"
    ws.append(R.EXPORT_HEADERS)  # bank's EXACT headers, verbatim (not the clean UI labels)
    for r in export_rows(db, tenant_id):
        ws.append(r)
    buf = io.BytesIO(); wb.save(buf); return buf.getvalue()


def _selftest() -> None:
    """Pure-logic checks for the derivations (no DB). Asserts real values are
    produced AND that unknown inputs never yield a false 'Yes'/reason."""
    from types import SimpleNamespace as NS

    def A(**kw):
        base = dict(platform_kind=None, platform_properties=None,
                    detected_software_json=None, security_posture=None,
                    eol_date=None, internet_facing=False, environment=None,
                    name="", host_name="", fqdn="", source_system="discovery",
                    last_seen_source="cidr", origin_source="easm")
        base.update(kw)
        return NS(**base)

    # Windows host with a Get-HotFix history → last OS patch + normalised date.
    win = A(platform_properties={"windows_update": {"status": "discovered", "data": {
        "last_hotfix": "KB5129195", "last_installed": "09/15/2026 00:00:00",
        "recent_hotfixes": [{"id": "KB5129195", "installed": "09/15/2026 00:00:00"}]}}},
        security_posture={"has_edr": False}, detected_software_json=[{"name": "7-Zip"}])
    assert _win_last_patch(win) == ("KB5129195", "2026-09-15"), _win_last_patch(win)
    assert _base_value("last_os_patch", win, {}) == "KB5129195"
    # O = Microsoft's RELEASE date for that KB (feed), never the install date
    assert _base_value("last_os_patch_date", win, {"last_os_patch_date": "2026-08-11"}) == "2026-08-11"
    assert _base_value("last_os_patch_date", win, {}) == ""        # feed unavailable -> unknown
    # has_edr False + inventory present → No, and the reason fires.
    assert _edr(win) == "No"
    assert _reason_value("reason_no_xdr_edr", win).startswith("No XDR/EDR agent was detected")
    assert _reason_value("reason_dlp", win)        # no DLP in inventory → fires
    assert _reason_value("reason_not_bmc", win)    # no BMC connector → fires

    # EASM host: no software, empty posture → every control UNKNOWN, no false gap.
    easm = A(internet_facing=True, security_posture={}, detected_software_json=[],
             name="adfs.superior.edu.pk")
    assert _edr(easm) == "" and _detect(easm, _DLP_SIGS) == "" and _detect(easm, _VPATCH_SIGS) == ""
    assert _reason_value("reason_no_xdr_edr", easm) == ""   # unknown ≠ No
    assert _reason_value("reason_dlp", easm) == ""
    assert _reason_value("reason_no_virtual_patching", easm) == ""
    assert _reason_value("reason_public_dmz", easm)          # public IP → fires
    assert _integrated_bmc(easm) == "No"

    # BMC-sourced asset → Yes (future case).
    assert _integrated_bmc(A(source_system="bmc_helix")) == "Yes"

    # primary_dr: DR when indicated, else Primary (editable default)
    assert _primary_dr(A(name="DESKTOP-EQ55Q8H")) == "Primary"
    assert _primary_dr(A(name="sql-standby-02")) == "DR"
    assert _primary_dr(A(host_name="web-dr-01")) == "DR"
    assert _primary_dr(A(environment="dr")) == "DR"
    assert _primary_dr(A(platform_kind="database", platform_properties={
        "replication": {"data": {"role": "Replica (in recovery)"}}})) == "DR"

    # DB patch level (MSSQL product_level + build; blank for non-DB).
    mssql = A(platform_kind="database",
              platform_properties={"engine": "Microsoft SQL Server",
                                   "version": "15.0.4326.1", "product_level": "RTM"})
    assert _db_patch(mssql) == "RTM · 15.0.4326.1", _db_patch(mssql)
    pg = A(platform_kind="database", platform_properties={"engine": "PostgreSQL", "version": "16.2"})
    assert _db_patch(pg) == "16.2"
    assert _db_patch(win) == ""  # a Windows server is not a database

    # virtual patching detection.
    assert _detect(A(detected_software_json=[{"name": "Trend Micro Deep Security Agent"}]), _VPATCH_SIGS) == "Yes"

    # classification: platform_kind "server" is the UI placeholder for ANY agentless
    # host — NOT evidence of a web role (this used to mark every laptop a web server)
    assert _is_web(A(platform_kind="server")) == "" and _is_db(A(platform_kind="server")) == ""
    assert _reason_value("reason_web_app", A(platform_kind="server")) == ""
    assert _reason_value("reason_web_app", A(platform_kind=None)) == ""
    assert _reason_value("reason_db_server", A(platform_kind="database"))
    assert _is_db(A(platform_kind="database")) == "Yes" and _is_web(A(platform_kind="database")) == "No"
    # dynamic patch-currency reason: fires only on a real open critical/high count
    scanned = {"last_va_date": "2026-09-26"}
    assert _reason_value("reason_os_patch", A(), {**scanned, "va_open_critical": 2, "va_open_high": 1})
    assert _reason_value("reason_os_patch", A(), {**scanned, "va_open_critical": 0, "va_open_high": 0}) == _NA
    assert _reason_value("reason_os_patch", A(), {"va_open_critical": 0}) == ""  # never scanned
    assert _reason_value("reason_db_patch", A(platform_kind="server"), {"va_open_high": 5}) == ""  # unknown role

    # server-role product matching — real installed-software / service names
    for n in ("postgresql 18", "postgresql-16", "postgresql16-server", "postgresql-x64-18",
              "mariadb 12.3 (x64)", "mysql server 8.0", "mysql80", "mssqlserver",
              "microsoft sql server 2019 (64-bit)", "mssql$sqlexpress", "mongodb",
              "oracle database 19c enterprise edition", "redis on windows", "redis-server"):
        assert _DB_RX.search(n), f"DB engine missed: {n}"
    for n in ("psqlodbc 13.02.0000", "postgresql-client-16", "postgresql16", "pgadmin 4",
              "mysql workbench 8.0 ce", "mariadb connector c 64-bit", "mongodb compass",
              "microsoft sql server management studio - 19.1", "redisinsight",
              "microsoft sql server 2012 native client", "oracle client 19c"):
        assert not _DB_RX.search(n), f"DB client counted as a server: {n}"
    for n in ("odoo 19.0", "odoo-server-19.0", "apache http server 2.4.58", "apache2.4",
              "httpd", "nginx", "apache tomcat 9.0 tomcat9 (remove only)", "tomcat9",
              "w3svc", "world wide web publishing service"):
        assert _WEB_RX.search(n), f"web server missed: {n}"
    for n in ("iis 10.0 express", "node.js", "apache openoffice 4.1.14",
              "tenable nessus (x64)", "apache maven"):
        assert not _WEB_RX.search(n), f"not a web server: {n}"

    # a dev laptop that really hosts Odoo + PostgreSQL/MariaDB/Redis (the live case)
    dev = A(detected_software_json=[
        {"name": "Odoo 19.0", "version": "19.0"}, {"name": "PostgreSQL 18", "version": "18.0-2"},
        {"name": "MariaDB 12.3 (x64)", "version": "12.3.2.0"}, {"name": "psqlODBC"},
        {"name": "Redis on Windows", "version": "5.0.14.1"}, {"name": "Node.js"}])
    assert _is_web(dev) == "Yes" and _is_db(dev) == "Yes"
    # J / K say WHAT it is, not just "Yes"; R = product line; S = installed build
    assert _base_value("web_app_server", dev, {}) == "Odoo 19.0 (application server)"
    assert _base_value("database_server", dev, {}) == "PostgreSQL, MariaDB, Redis"
    assert _dbms(dev) == "PostgreSQL 18; MariaDB 12.3; Redis 5.0", _dbms(dev)
    assert _db_patch(dev) == "PostgreSQL 18.0-2; MariaDB 12.3.2.0; Redis 5.0.14.1", _db_patch(dev)
    assert _reason_value("reason_web_app", dev).startswith("Hosts Odoo 19.0 (application server)")
    assert "PostgreSQL 18" in _reason_value("reason_db_server", dev)
    assert _base_value("db_monitoring", dev, {}) == "No"          # a DB with no DAM agent
    assert _reason_value("reason_db_monitoring", dev)             # ...so the gap draft fires
    assert _base_value("last_db_patch_date", dev, {}) == ""       # no vendor date -> unknown
    # B describes the APPLICATION (what Odoo is) — never the database list
    assert _app_desc(dev).startswith("Odoo 19.0 — open-source ERP"), _app_desc(dev)
    assert "PostgreSQL" not in _app_desc(dev)
    # DB currency from the vendor feed: behind / end-of-life -> factual gap draft
    cur = [{"label": "PostgreSQL", "cycle": "18", "installed": "18.0-2", "latest": "18.6",
            "date": "2026-08-11", "eol": "2030-11-14", "cycle_release": "2025-09-25",
            "behind": True, "eol_passed": False},
           {"label": "Redis", "cycle": "5.0", "installed": "5.0.14.1", "latest": "5.0.14",
            "date": "2021-10-04", "eol": "2022-04-27", "cycle_release": "2018-10-17",
            "behind": False, "eol_passed": True}]
    gap = _reason_value("reason_db_patch", dev, {"db_currency": cur})
    assert "PostgreSQL 18.0-2 installed, latest is 18.6 (released 2026-08-11)" in gap, gap
    assert "Redis 5.0 line reached end of life on 2022-04-27" in gap, gap
    assert _reason_value("reason_db_patch", dev, {"db_currency": [
        dict(cur[0], behind=False, eol_passed=False)]}) == _NA           # current -> no gap
    assert _reason_value("reason_db_patch", dev, {}) == ""               # feed down -> unknown
    # T: installed build's release date only where a vendor states it
    assert _installed_db_release([cur[0]]) == "2025-09-25"   # 18.0 = the cycle's first release
    assert _installed_db_release([cur[1]]) == "2021-10-04"   # 5.0.14 = the cycle's latest
    assert _installed_db_release([dict(cur[0], installed="18.3")]) == ""  # mid-cycle: unknown
    # an office PC: client tools only -> known NOT a web/DB server -> Not Applicable
    office = A(detected_software_json=[{"name": n} for n in (
        "Google Chrome", "Microsoft SQL Server Management Studio - 19.1", "IIS 10.0 Express",
        "MySQL Workbench 8.0 CE", "pgAdmin 4", "psqlODBC", "Node.js")])
    assert _is_web(office) == "No" and _is_db(office) == "No"
    for k in ("dbms_version", "last_db_patch", "latest_db_patch", "db_monitoring",
              "last_db_patch_date", "latest_db_patch_date", "reason_db_server",
              "reason_db_monitoring", "reason_db_patch", "reason_web_app"):
        assert _base_value(k, office, scanned) == _NA, (k, _base_value(k, office, scanned))
    assert _base_value("reason_public_dmz", office, {}) == _NA    # internal host
    # IIS is a Windows ROLE (no installed-program entry) — seen via its service
    iis = A(platform_properties={"services": {"data": [
        {"name": "W3SVC", "display_name": "World Wide Web Publishing Service", "state": "Running"}]}})
    assert _is_web(iis) == "Yes"
    assert _base_value("web_app_server", iis, {}) == "Microsoft IIS (web server)"
    assert "running service: W3SVC" in _reason_value("reason_web_app", iis)
    # control present -> its "reason for NOT having it" is Not Applicable
    assert _reason_value("reason_no_xdr_edr", A(security_posture={"has_edr": True})) == _NA
    # EDR from the deep scan's security-products read: installed-but-STOPPED is not
    # protection; the posture summary is only the fallback (it missed these agents)
    sec = lambda running: A(security_posture={"has_edr": False}, platform_properties={
        "security_products": {"data": {"edr_xdr": [{"product": "Microsoft Defender for Endpoint",
                                                    "service": "Sense", "status": "Stopped" if not running else "Running",
                                                    "running": running}]}},
        "defender": {"data": {"antivirus_enabled": True, "realtime_protection": True}}})
    assert _edr(sec(False)) == "No" and _edr(sec(True)) == "Yes"
    r = _reason_value("reason_no_xdr_edr", sec(False))
    assert "Microsoft Defender for Endpoint is installed but its service (Sense) is stopped" in r, r
    assert "Microsoft Defender Antivirus is enabled with real-time protection" in r, r
    assert _reason_value("reason_no_xdr_edr", sec(True)) == _NA

    # OS patch currency: Microsoft's latest KB vs the host's installed updates
    host = A(platform_properties={"windows_update": {"data": {"recent_hotfixes": [
        {"id": "KB5129195", "installed": "09/15/2026 00:00:00", "type": "Security Update"},
        {"id": "KB5126052", "installed": "09/16/2026 00:00:00", "type": "Update"}]}}})
    assert _win_last_patch(host)[0] == "KB5129195"   # newest SECURITY update, not the .NET one
    feed = {**scanned, "va_open_critical": 3, "va_open_high": 4, "latest_os_patch": "KB5124008",
            "latest_os_patch_date": "2026-09-08", "last_os_patch_date": "2026-08-11"}
    r = _reason_value("reason_os_patch", host, feed)
    assert r.startswith("Microsoft's latest security update KB5124008 (released 2026-09-08) is not installed"), r
    assert "KB5129195 (released 2026-08-11)" in r and "7 open critical/high findings" in r, r
    ok = dict(feed, latest_os_patch="KB5129195", va_open_critical=0, va_open_high=0)
    assert _reason_value("reason_os_patch", host, ok) == _NA          # current + clean

    # D classification: the asset's criticality, else Ava's own criticality model
    assert _base_value("classification", A(criticality="high"), {}) == "High"
    assert _base_value("classification", A(), {}) == "Medium"   # no inputs -> never silently Low
    # I environment: own value, else a word-bounded name marker, else Production
    assert _environment(A()) == "Production"
    assert _environment(A(name="app-uat-01")) == "UAT" and _environment(A(name="dev-box")) == "Dev"
    assert _environment(A(environment="development")) == "Dev"
    assert _environment(A(name="testasp.vulnweb.com")) == "Production"  # "testasp" is no marker

    # obsolescence: vendor end-of-support table (static dates, not time-relative)
    eol = lambda s: (_vendor_eol(s) or datetime.min).strftime("%Y-%m-%d")
    assert eol("Microsoft Windows 11 Pro 25H2") == "2027-10-12"
    assert eol("Microsoft Windows 11 Enterprise 25H2") == "2028-10-10"
    assert eol("Microsoft Windows 10 Pro 22H2") == "2025-10-14"
    assert eol("Microsoft Windows 10 Enterprise 21H2") == "2024-06-11"
    assert eol("Windows 10 Enterprise LTSC 2019") == "2029-01-09"
    assert eol("Windows 10 IoT Enterprise LTSC 2021") == "2032-01-13"
    assert _vendor_eol("Windows 11 Enterprise LTSC 2024 24H2") is None   # untabled, no fall-through
    assert eol("Microsoft Windows Server 2012 R2 Standard") == "2023-10-10"
    assert eol("Microsoft Windows Server 2022 Datacenter") == "2031-10-14"
    assert eol("Microsoft Windows 8.1 Pro") == "2023-01-10"            # not Windows 8's date
    assert eol("Red Hat Enterprise Linux Server release 7.9 (Maipo)") == "2024-06-30"
    assert eol("CentOS Stream 8") == "2024-05-31" and eol("CentOS Linux 8") == "2021-12-31"
    assert _vendor_eol("CentOS Stream 9") is None and _vendor_eol("Ubuntu 22.04.4 LTS") is None
    assert eol("Ubuntu 20.04.6 LTS") == "2025-05-31"
    assert eol("Debian GNU/Linux 11 (bullseye)") == "2026-08-31"
    assert _vendor_eol("") is None and _vendor_eol("macOS 14.5") is None
    # an analyst's eol_date wins over the table; status/days/reason follow it
    from datetime import timedelta
    now = datetime.utcnow()
    past = A(os_version="Microsoft Windows 11 Pro 25H2", eol_date=now - timedelta(days=10))
    assert _base_value("obsolescence_status", past, {}) == "Y"
    assert _base_value("obsolete_since_days", past, {}) in (9, 10)
    assert _reason_value("reason_obsolete_os", past) == _REASON_TEXT["reason_obsolete_os"]
    live = A(eol_date=now + timedelta(days=90))
    assert _base_value("obsolescence_status", live, {}) == "N"
    assert _base_value("obsolete_since_days", live, {}) == _NA
    assert _reason_value("reason_obsolete_os", live) == _NA
    assert _base_value("obsolescence_status", A(), {}) == ""        # unknown OS stays blank

    # VA vs PT: split by LANE — a scanner finding is VA even inside a pentest run
    R_ = lambda sev, src, st="open", d=3, i=0, cve=None: NS(
        id=i, cve_id=cve, severity=sev, status=st, source=src,
        discovered_at=now - timedelta(days=d), last_seen=None)
    split = _split_scans([R_("critical", "ai-pentest:openvas"), R_("high", "ai-pentest:zap"),
                          R_("high", "nessus", st="in_progress"),
                          R_("critical", "ai-pentest:hexstrike", st="remediated"),
                          R_("medium", "ai-pentest:pentestgpt"), R_("info", "ai-pentest:pentestgpt")])
    assert (split["va_open_critical"], split["va_open_high"]) == (1, 2), split  # remediated excluded
    assert (split["pt_open_critical"], split["pt_open_high"]) == (0, 0), split  # PT ran, none crit/high
    assert split["pt_days_critical_open"] == _NA and isinstance(split["va_days_critical_open"], int)
    assert split["last_pt_date"] and split["last_va_date"]
    none_pt = _split_scans([R_("high", "nessus")])
    assert none_pt["pt_open_critical"] == "" and none_pt["last_pt_date"] == ""  # never ran ≠ clean
    assert _split_scans([])["va_open_critical"] == ""
    # de-branded + union find lanes stay VA (no scanner allowlist to rot)
    u = _split_scans([R_("high", "ai-pentest:scanner"), R_("high", "ai-pentest:hexstrike+zap")])
    assert u["va_open_high"] == 2 and u["last_pt_date"] == "", u
    # exploit runs (grc_pentest_exploit_results): a scanner finding the pentest
    # PROVED is a PT finding too — found by VA, exploited by PT
    X = lambda fid, st="executed", ok=True, cve=True, d=1, tech="": NS(
        finding_id=fid, status=st, technique=tech, confirmed=ok, cve_specific=cve,
        created_at=now - timedelta(days=d))
    scan = [R_("critical", "ai-pentest:openvas", i=101),
            R_("high", "ai-pentest:zap", i=102, cve="CVE-2026-1111")]
    p = _split_scans(scan, [X("101")])
    assert (p["va_open_critical"], p["pt_open_critical"], p["pt_open_high"]) == (1, 1, 0), p
    assert p["last_pt_date"] == _d(now - timedelta(days=1)), p  # the run dates the PT
    # a Metasploit check that PROVED it ("confirmed-vulnerable") is a PT that ran
    m = _split_scans(scan, [X("101", st="confirmed-vulnerable")])
    assert m["pt_open_critical"] == 1 and m["last_pt_date"], m
    # a generic credentialed proof proves access, not THIS finding
    assert _split_scans(scan, [X("101", cve=False)])["pt_open_critical"] == 0
    # a web exploit that RAN without proof (executed, unconfirmed) dates the PT, 0 open
    q = _split_scans(scan, [X("102", ok=False)])
    assert q["last_pt_date"] and q["pt_open_high"] == 0 and q["pt_days_high_open"] == _NA, q
    # "not-exploitable" is dual-source: only a Metasploit check that RAN engaged the host
    assert _split_scans(scan, [X("102", st="not-exploitable", ok=False)])["last_pt_date"] == ""
    assert _split_scans(scan, [X("102", st="not-exploitable", ok=False,
                                 tech="Metasploit check — target appears safe")])["last_pt_date"]
    # nothing fired at the host -> NOT a PT performed
    assert _split_scans(scan, [X("101", st=s, ok=False) for s in (
        "needs-verification", "manual", "exploitable-unarmed", "no-tool", "error",
        "blocked")])["last_pt_date"] == ""
    # an ad-hoc proof keyed by CVE still maps; an empty finding_id never matches
    assert _split_scans(scan, [X("CVE-2026-1111")])["pt_open_high"] == 1
    assert _split_scans(scan, [X("")])["pt_open_critical"] == 0

    # vendor-feed plumbing (pure parts — no network in the selftest)
    lap = A(os_version="Microsoft Windows 11 Pro 25H2", os_build="25H2",
            platform_properties={"os": {"data": {"architecture": "64-bit"}}})
    assert _msrc_product(lap) == "Windows 11 Version 25H2 for x64-based Systems", _msrc_product(lap)
    assert _msrc_product(A(os_version="Microsoft Windows 10 Pro 22H2")) == \
        "Windows 10 Version 22H2 for x64-based Systems"
    assert _msrc_product(A(os_version="Microsoft Windows Server 2012 R2 Standard")) == "Windows Server 2012 R2"
    assert _msrc_product(A(os_version="Microsoft Windows Server 2022 Datacenter")) == "Windows Server 2022"
    assert _msrc_product(A(os_version="Microsoft Windows 11 Pro 24H2", platform_properties={
        "os": {"data": {"architecture": "ARM 64-bit Processor"}}})).endswith("for ARM64-based Systems")
    assert _msrc_product(A(os_version="Ubuntu 22.04.4 LTS")) is None
    assert _msrc_product(A(os_version="Microsoft Windows 11 Pro")) is None  # no version -> no guess
    mc = vendor_feeds.match_cycle
    pg = [{"cycle": "18", "latest": "18.6"}, {"cycle": "17", "latest": "17.9"}]
    assert mc(pg, "PostgreSQL 18", "18.0-2")["latest"] == "18.6"
    maria = [{"cycle": "12.3", "latest": "12.3.3"}, {"cycle": "12.2", "latest": "12.2.9"}]
    assert mc(maria, "MariaDB 12.3 (x64)", "12.3.2.0")["latest"] == "12.3.3"
    assert mc(maria, "MariaDB 11.4", "11.4.2") is None                    # untracked cycle -> blank
    mssql = [{"cycle": "2022", "latest": "16.0.4185.3"}, {"cycle": "2019", "latest": "15.0.4430.1"}]
    assert mc(mssql, "Microsoft SQL Server 2019 (64-bit)", "15.0.2000.5")["cycle"] == "2019"
    assert mc(mssql, "Microsoft SQL Server", "16.0.1000.6")["cycle"] == "2022"  # typed collector
    assert _app_desc(office) == ""                                         # nothing served
    assert _base_value("application_description", A(description="Core banking"), {}) == "Core banking"

    # field-count invariant: automation increased the auto set.
    auto = sum(1 for f in R.FIELDS if f[4].startswith("asset") or f[4] == "derived")
    assert auto == 52, auto
    # every newly-wired field is still analyst-editable.
    for k in ("last_os_patch", "integrated_bmc", "primary_dr", "virtual_patching",
              "last_db_patch", "reason_no_xdr_edr", "reason_public_dmz",
              "latest_os_patch", "latest_db_patch", "last_pt_date", "pt_open_critical",
              "reason_web_app", "reason_db_server", "reason_os_patch", "reason_db_patch",
              "latest_os_patch_date", "latest_db_patch_date", "last_db_patch_date"):
        assert k in R.STORABLE_KEYS, k
    print(f"sbp_inventory selftest OK — {auto}/52 auto")


if __name__ == "__main__":
    _selftest()
