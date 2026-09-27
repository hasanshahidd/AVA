"""Vendor patch feeds for the SBP "latest patch" columns.

  * Microsoft Security Update Guide — newest security update (KB + release date)
    Microsoft lists for a Windows product.
  * endoflife.date — newest release (+ its date) in an installed database
    engine's release cycle.

Public GETs only: just a product name goes out, never tenant data. Cached
in-process; any failure returns None so the column stays blank for the analyst
— a vendor fact is never guessed.
"""
from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from typing import List, Optional, Tuple

# ponytail: per-process dict cache (Ava's backend is single-process); move to
# Redis if it ever runs multi-worker. A failure is only cached for 2 min so one
# slow vendor response can't blank the columns for long. MSRC's filtered query
# measured 1.6-7.7s, so the timeout must sit well above that.
_TTL, _NEG_TTL, _TIMEOUT = 12 * 3600, 120, 20
_cache: dict = {}


def _get_json(url: str):
    hit = _cache.get(url)
    if hit and time.time() - hit[0] < (_TTL if hit[1] is not None else _NEG_TTL):
        return hit[1]
    try:
        req = urllib.request.Request(url, headers={"Accept": "application/json",
                                                   "User-Agent": "Ava-SBP/1.0"})
        with urllib.request.urlopen(req, timeout=_TIMEOUT) as r:
            val = json.load(r)
    except Exception:  # noqa: BLE001 — offline / rate-limited / schema drift -> blank
        val = None
    _cache[url] = (time.time(), val)
    return val


_SUG = "https://api.msrc.microsoft.com/sug/v2.0/en-US/affectedProduct"


def _sug_rows(flt: str, top: int = 1) -> list:
    d = _get_json(f"{_SUG}?$orderBy=releaseDate%20desc&$top={top}&$filter={urllib.parse.quote(flt)}")
    return ((d or {}).get("value") if isinstance(d, dict) else None) or []


def latest_windows_update(product: str) -> Optional[Tuple[str, str]]:
    """(KBnnnnnnn, YYYY-MM-DD) of the newest security update Microsoft lists for
    an MSRC product name, e.g. 'Windows 11 Version 25H2 for x64-based Systems'."""
    rows = _sug_rows(f"product eq '{product}'")
    if not rows:
        return None
    kb = next((str(k["articleName"]) for k in rows[0].get("kbArticles") or []
               if str(k.get("articleName") or "").isdigit()), None)
    date = str(rows[0].get("releaseDate") or "")[:10]
    return (f"KB{kb}", date) if kb else None


def windows_kb_release_date(kb: str) -> str:
    """Microsoft's RELEASE date for a security-update KB ('' when Microsoft's
    Security Update Guide doesn't list it — e.g. a non-security update)."""
    num = re.sub(r"\D", "", kb or "")
    if not num:
        return ""
    rows = _sug_rows(f"kbArticles/any(k:k/articleName eq '{num}')")
    return str(rows[0].get("releaseDate") or "")[:10] if rows else ""


# installed-engine name -> endoflife.date product slug + display label
_DB_PRODUCTS = [("postgresql", "postgresql", "PostgreSQL"), ("mariadb", "mariadb", "MariaDB"),
                ("mysql", "mysql", "MySQL"), ("redis", "redis", "Redis"),
                ("mongodb", "mongodb", "MongoDB"), ("sql server", "mssqlserver", "SQL Server"),
                ("oracle database", "oracle-database", "Oracle Database")]


def match_cycle(cycles: List[dict], name: str, version: str) -> Optional[dict]:
    """The release cycle an installed engine belongs to: by version prefix
    ('18.0-2' -> '18', '12.3.2.0' -> '12.3'), or by the year in the name for
    SQL Server ('Microsoft SQL Server 2019 (64-bit)' -> '2019')."""
    nums = re.findall(r"\d+", version or "")
    year = None
    if "sql server" in name.lower():  # cycles are years; a typed collector gives 15.0.x
        y = re.search(r"\b(20\d\d)\b", name)
        year = y.group(1) if y else {"16": "2022", "15": "2019", "14": "2017",
                                     "13": "2016", "12": "2014"}.get(nums[0] if nums else "")
    for c in cycles or []:
        cyc = str(c.get("cycle") or "")
        if "sql server" in name.lower():
            if year and cyc == year:
                return c
        elif cyc and nums[:len(cyc.split("."))] == cyc.split("."):
            return c
    return None


def db_label(name: str) -> str:
    """Engine family for an installed DB product name ('MariaDB 12.3 (x64)' ->
    'MariaDB'); the name itself when it isn't a tracked engine."""
    n = name.lower()
    return next((label for key, _slug, label in _DB_PRODUCTS if key in n), name)


def mariadb_release_date(version: str) -> str:
    """MariaDB's own date for one exact release (downloads.mariadb.org REST API)."""
    parts = re.findall(r"\d+", version or "")
    if len(parts) < 3:
        return ""
    d = _get_json(f"https://downloads.mariadb.org/rest-api/mariadb/{'.'.join(parts[:2])}/")
    rel = ((d.get("releases") or {}).get(".".join(parts[:3])) if isinstance(d, dict) else None) or {}
    return str(rel.get("date_of_release") or "")[:10]


def latest_db_release(name: str, version: str) -> Optional[Tuple[str, str, str, str, str, str]]:
    """(label, cycle, latest version, its release date, cycle end-of-life date,
    cycle's first-release date) for the installed engine's release cycle. eol is
    '' when not published, 'yes' when ended without a date."""
    n = name.lower()
    hit = next(((slug, label) for key, slug, label in _DB_PRODUCTS if key in n), None)
    if not hit:
        return None
    c = match_cycle(_get_json(f"https://endoflife.date/api/{hit[0]}.json") or [], name, version)
    if not c or not c.get("latest"):
        return None
    eol = c.get("eol")
    eol = eol if isinstance(eol, str) else ("yes" if eol is True else "")
    return (hit[1], str(c.get("cycle") or ""), str(c["latest"]),
            str(c.get("latestReleaseDate") or ""), eol, str(c.get("releaseDate") or ""))
