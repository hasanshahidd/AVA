"""Field-level change journal for IT assets — every column and every telemetry field.

One SQLAlchemy ``before_flush`` listener (same pattern as ``audit_capture``)
writes one ``AuditLog`` row per changed asset per flush: action
``asset.updated``, resource ``it_asset``/<id>, and ``changes`` =
``{"detail", "source", "fields": [...], "sections": {...}, "total_fields"}``.

Coverage: EVERY ``ITAsset`` column except pure bookkeeping (ids, created/seen
timestamps). JSON columns are deep-diffed, so telemetry inside
``platform_properties`` (cpu, memory, disks, OS, packages, services, Defender,
firewall, BitLocker, local users, …) is journalled per field: a package version
bump, a new local user or a Defender toggle each becomes its own row. Lists of
objects are matched by a natural key (name / id / path / …) so an added or
removed package reads as "added"/"removed", not a wall of index shifts.
Volatile readings (uptime, free space, load, collected_at …) are ignored so the
journal records real changes, not churn.

Categories mirror the asset record: identity & network, hardware / software /
security telemetry, ownership, business & risk context, procurement & cost,
lifecycle & status, platform telemetry (database / network / cloud / cluster /
directory collectors).

Source labelling: ``@change_source("discovery")`` (decorator or ``with``) labels
every asset attribute set inside it; ``mark_source(asset, "manual", user_id=…)``
stamps one asset explicitly and wins. Unlabelled changes fall back to ``manual``
inside an audited HTTP request and ``system`` elsewhere. Only ORM unit-of-work
writes are seen (bulk/Core UPDATEs bypass it, as documented in audit_capture).
"""
from __future__ import annotations

import json
import logging
import re
from collections import Counter
from contextlib import contextmanager
from contextvars import ContextVar
from typing import Any, Dict, Iterator, List, Optional, Tuple

from sqlalchemy import event, inspect as sa_inspect
from sqlalchemy.orm import Session

from ..audit_capture import _coerce, _collector, is_sensitive_key
from ..models import AuditLog, ITAsset

logger = logging.getLogger(__name__)

CATEGORIES = ("identity", "hardware", "software", "security", "ownership",
              "business", "procurement", "lifecycle", "platform", "other")

# Bookkeeping columns: they move on every touch and say nothing about the asset.
_EXCLUDED_COLUMNS = {"id", "tenant_id", "created_at", "first_seen_at", "last_seen_at", "last_seen_source"}

COLUMN_CATEGORIES: Dict[str, str] = {
    **dict.fromkeys(("name", "description", "asset_type", "asset_role", "platform_kind", "host_name", "fqdn",
                     "ip_address", "known_ips", "dns_aliases", "primary_mac", "network_segment",
                     "internet_facing", "is_internet_facing", "cloud_resource_id", "parent_asset_id"), "identity"),
    **dict.fromkeys(("manufacturer", "model", "serial_number", "cpu_cores", "memory_gb", "storage_gb"), "hardware"),
    **dict.fromkeys(("os_family", "os_version", "os_normalized", "os_build", "os_edition", "agent_version",
                     "detected_software_json", "app_attributes_json"), "software"),
    **dict.fromkeys(("security_posture", "credential_profile_id"), "security"),
    **dict.fromkeys(("owner_id", "owner_name", "primary_owner_id", "secondary_owner_id", "business_owner_id",
                     "escalation_contact_id", "owning_team", "owning_team_id", "custodian", "department",
                     "assigned_user", "location"), "ownership"),
    **dict.fromkeys(("criticality", "criticality_score", "criticality_manual_override", "criticality_override_reason",
                     "confidentiality_rating", "integrity_rating", "availability_rating", "data_classification",
                     "business_function", "environment", "cde_environment", "pci_dss", "ephi_environment", "hipaa",
                     "compliance_scope", "regulated_data_type", "is_customer_facing", "op_dep_business_impact",
                     "business_impact_notes"), "business"),
    **dict.fromkeys(("vendor", "purchase_cost", "purchase_date", "warranty_expiry", "eol_date", "valuation"),
                    "procurement"),
    **dict.fromkeys(("status", "lifecycle_state", "decommissioned_at", "retirement_reason", "replacement_asset_id",
                     "discovery_state", "source_system", "origin_source"), "lifecycle"),
}

# platform_properties section → category (same grouping as the asset Overview tabs).
SECTION_CATEGORIES: Dict[str, str] = {
    **dict.fromkeys(("cpu", "memory", "gpu", "firmware", "storage", "storage_disks", "storage_mounts", "lvm", "raid",
                     "identity", "hardware", "modules", "environment"), "hardware"),
    **dict.fromkeys(("network", "net_addr", "net_link", "net_route", "dns", "surface", "recon", "fingerprint",
                     "external_probe", "discovery_classification", "interfaces", "ip_interfaces"), "identity"),
    **dict.fromkeys(("os", "operating_system", "packages", "pkg", "services", "scheduled_tasks", "shares", "virt",
                     "virtualization", "docker", "podman", "agent", "software", "hotfixes"), "software"),
    **dict.fromkeys(("security_products", "defender", "firewall", "bitlocker", "selinux", "apparmor", "sshd",
                     "ssh_config", "local_users", "local_groups", "users", "groups", "sudoers", "windows_update",
                     "sec_updates", "security_updates", "roles", "logins", "security"), "security"),
    "cmdb": "lifecycle",
}
_VOLATILE_SECTIONS = {"processes", "running_processes", "connections", "netstat", "sessions"}
_VOLATILE_KEYS = {"timestamp", "boot_time", "last_boot_time", "last_boot_up_time", "uptime", "uptime_hours",
                  "uptime_seconds", "current_clock_mhz", "current_clock_speed", "duration_ms",
                  "speed_bps", "speed_mbps", "link_speed", "rssi", "signal", "signal_strength", "signal_quality"}
# Runtime state that flips between reports without anyone changing anything.
_SECTION_VOLATILE = {"services": {"state", "status", "sub_state", "active_state", "running", "pid"}}
_EPHEMERAL_PORT = 49152   # IANA dynamic range: client sockets (e.g. a browser's UDP) churn every report
_ALWAYS_VOLATILE_TOKENS = {"pid", "uptime", "temperature", "celsius", "rpm"}
_MEASURE_TOKENS = {"free", "available", "usage", "utilization", "utilisation", "load", "used"}
_UNIT_TOKENS = {"gb", "mb", "kb", "bytes", "pct", "percent", "percentage", "mhz"}
_ITEM_KEYS = ("name", "Name", "display_name", "DisplayName", "package", "username", "user", "UserName",
              "hotfix_id", "HotFixID", "id", "path", "mount", "mountpoint", "device", "DeviceID", "drive",
              "interface", "iface", "key", "serial", "slot", "bank", "label", "letter", "drive_letter",
              "volume", "sid",
              "mac", "mac_address", "description", "model", "title")

MAX_FIELDS = 300   # field rows stored per entry; section totals are always complete

VALID_SOURCES = {"manual", "scan", "discovery", "connector", "agent", "import", "system"}
ACTION = "asset.updated"

_STASH = "asset_change_ctx"     # label captured at attribute-set time
_MARK = "asset_change_mark"     # explicit per-object label (wins)

_ctx: ContextVar[Optional[Tuple[str, Optional[int]]]] = ContextVar("asset_change_source", default=None)

TRACKED_COLUMNS: Tuple[str, ...] = tuple(
    a.key for a in sa_inspect(ITAsset).column_attrs if a.key not in _EXCLUDED_COLUMNS)


def _norm(source: str) -> str:
    return source if source in VALID_SOURCES else "system"


@contextmanager
def change_source(source: str, user_id: Optional[int] = None) -> Iterator[None]:
    """Label asset changes made inside this block (or decorated function)."""
    token = _ctx.set((_norm(source), user_id))
    try:
        yield
    finally:
        _ctx.reset(token)


def mark_source(asset: ITAsset, source: str, user_id: Optional[int] = None) -> None:
    """Stamp one asset's pending changes with an explicit source/actor."""
    sa_inspect(asset).info[_MARK] = (_norm(source), user_id)


def column_category(field: str) -> Optional[str]:
    """Category of a plain column field (used to re-file rows journalled before
    categories were aligned with the asset record); None for telemetry paths."""
    return COLUMN_CATEGORIES.get(field)


# ─── deep diff ───────────────────────────────────────────────────────

def _volatile(key: str) -> bool:
    """Live readings (free space, load, uptime, temperatures, timestamps) — not changes.
    "updates_available" stays tracked; "available_gb" does not."""
    k = str(key).lower()
    toks = set(k.split("_"))
    if (k in _VOLATILE_KEYS or k.startswith(("last_", "days_since")) or k.endswith("_at")
            or toks & _ALWAYS_VOLATILE_TOKENS):
        return True
    return bool(toks & _MEASURE_TOKENS) and (bool(toks & _UNIT_TOKENS) or toks <= _MEASURE_TOKENS)


def _summary(v: Any) -> Any:
    """Compact display value for a list item / nested object."""
    if isinstance(v, dict):
        key = next((k for k in _ITEM_KEYS if v.get(k) not in (None, "")), None)
        ver = v.get("version") or v.get("Version") or v.get("DisplayVersion")
        if key is not None and ver:
            return _coerce(f"{v[key]} {ver}")
        # name plus a few plain attributes, e.g. "DIMM2 (size_gb: 16)"
        extra = [f"{k}: {x}" for k, x in v.items()
                 if k != key and isinstance(x, (str, int, float, bool)) and not _volatile(k)][:3]
        head = str(v[key]) if key is not None else ""
        if head or extra:
            return _coerce(f"{head} ({', '.join(extra)})" if head and extra else head or ", ".join(extra))
        return _coerce(json.dumps(v, default=str, sort_keys=True)[:300])
    if isinstance(v, list):
        return _coerce(json.dumps(v, default=str)[:300])
    return _coerce(v)


def _item_key(item: Any, section: str = "") -> str:
    if isinstance(item, dict) and item.get("port") is not None:
        return f"{item['port']}/{item.get('proto') or item.get('protocol') or 'tcp'}"
    if isinstance(item, dict):
        for k in _ITEM_KEYS:
            if item.get(k) not in (None, ""):
                return str(item[k])
        # No identity field: key on the stable fields only, or a free-space wobble
        # would read as the item being removed and re-added every report.
        skip = _SECTION_VOLATILE.get(section, ())
        item = {k: v for k, v in item.items() if not _volatile(k) and k not in skip}
    return json.dumps(item, default=str, sort_keys=True)[:120]


class _Diff:
    def __init__(self) -> None:
        self.rows: List[Dict[str, Any]] = []
        self.sections: Dict[str, Dict[str, Any]] = {}
        self.total = 0

    def add(self, field: str, section: str, cat: str, change: str, old: Any, new: Any) -> None:
        self.total += 1
        s = self.sections.setdefault(section, {"category": cat, "added": 0, "removed": 0, "changed": 0})
        s[change] += 1
        if len(self.rows) < MAX_FIELDS:
            self.rows.append({"field": field, "section": section, "category": cat,
                              "change": change, "old": _summary(old), "new": _summary(new)})

    def tree(self, path: str, section: str, cat: str, a: Any, b: Any) -> None:
        if a == b:
            return
        # A newly present / vanished object is diffed field by field, not as one blob.
        if a is None and isinstance(b, dict):
            a = {}
        elif b is None and isinstance(a, dict):
            b = {}
        if isinstance(a, dict) and isinstance(b, dict):
            skip = _SECTION_VOLATILE.get(section, ())
            for k in sorted(set(a) | set(b), key=str):
                if not _volatile(k) and k not in skip:
                    self.tree(f"{path}.{k}", section, cat, a.get(k), b.get(k))
            return
        if isinstance(a, list) and isinstance(b, list):
            self._list(path, section, cat, a, b)
            return
        if a is None and isinstance(b, (dict, list)) and b:
            self.add(path, section, cat, "added", None, b)
        elif b is None and isinstance(a, (dict, list)) and a:
            self.add(path, section, cat, "removed", a, None)
        else:
            self.add(path, section, cat, "changed", a, b)

    def _list(self, path: str, section: str, cat: str, a: list, b: list) -> None:
        a, b = [x for x in a if not _ephemeral(x)], [x for x in b if not _ephemeral(x)]
        if any(isinstance(x, dict) for x in a + b):
            def keyed(items):
                groups: Dict[str, List[Any]] = {}
                for it in items:
                    groups.setdefault(_item_key(it, section), []).append(it)
                out: Dict[str, Any] = {}
                for k, its in groups.items():
                    if len(its) == 1:
                        out[k] = its[0]
                        continue
                    # Same key twice (e.g. chrome + msedge both on 5353/udp): name each one,
                    # never pair them by list order, which flips between reports.
                    for it in sorted(its, key=lambda x: json.dumps(x, default=str, sort_keys=True)):
                        kk = f"{k} ({_tag(it, section)})"
                        while kk in out:
                            kk += "'"
                        out[kk] = it
                return out
            ka, kb = keyed(a), keyed(b)
            for k in sorted(set(ka) | set(kb)):
                if k not in ka:
                    self.add(f"{path}[{k}]", section, cat, "added", None, kb[k])
                elif k not in kb:
                    self.add(f"{path}[{k}]", section, cat, "removed", ka[k], None)
                else:
                    self.tree(f"{path}[{k}]", section, cat, ka[k], kb[k])
            return
        sa = {json.dumps(x, default=str) for x in a}
        sb = {json.dumps(x, default=str) for x in b}
        for x in b:
            if json.dumps(x, default=str) not in sa:
                self.add(path, section, cat, "added", None, x)
        for x in a:
            if json.dumps(x, default=str) not in sb:
                self.add(path, section, cat, "removed", x, None)


def _tag(item: Any, section: str) -> str:
    if isinstance(item, dict):
        for k in ("service", "process", "process_name", "program", "address", "ip"):
            if item.get(k) not in (None, ""):
                return str(item[k])
        skip = _SECTION_VOLATILE.get(section, ())
        item = {k: v for k, v in item.items() if not _volatile(k) and k not in skip}
    return json.dumps(item, default=str, sort_keys=True)[:60]


def _ephemeral(item: Any) -> bool:
    port = item.get("port") if isinstance(item, dict) else None
    return isinstance(port, int) and port >= _EPHEMERAL_PORT


_BRACKET_TAIL = re.compile(r"\[([^\[\]]*)\]$")


def is_noise(field: str, section: Optional[str] = None) -> bool:
    """Same rules as the live diff, applied at read time so rows journalled
    before a rule existed don't show churn (timestamps, link speed, run state,
    ephemeral ports). Plain columns are never noise."""
    if not section or field == section:
        return False
    m = _BRACKET_TAIL.search(field)
    if m and m.group(1).startswith("{"):
        try:
            return _ephemeral(json.loads(m.group(1)))
        except ValueError:
            return False
    leaf = _BRACKET_TAIL.sub("", field).rsplit(".", 1)[-1] if not m else ""
    return bool(leaf) and (_volatile(leaf) or leaf in _SECTION_VOLATILE.get(section, ()))


def _list_path(field: str) -> str:
    """'pp.volumes[<item key>]' -> 'pp.volumes' (balanced scan; keys may be JSON)."""
    if not field.endswith("]"):
        return field
    depth = 0
    for i in range(len(field) - 1, -1, -1):
        depth += {"]": 1, "[": -1}.get(field[i], 0)
        if depth == 0:
            return field[:i]
    return field.split("[", 1)[0]   # key truncated mid-bracket


def drop_churn(fields: List[Any]) -> List[Any]:
    """Journalled fields minus churn under the current rules: noise rows, plus
    removed+added pairs of one list item that read identically (rows written
    when a keyless item was keyed on a volatile value such as free space)."""
    kept = [f for f in fields if not (isinstance(f, dict) and is_noise(str(f.get("field", "")), f.get("section")))]

    def twin(f: Any) -> Optional[Tuple[str, Any, str]]:
        ch = f.get("change") if isinstance(f, dict) else None
        if ch not in ("added", "removed"):
            return None
        val = f.get("new" if ch == "added" else "old")
        return ch, (_list_path(str(f.get("field", ""))), f.get("section"), json.dumps(val, default=str, sort_keys=True))

    keys = [twin(f) for f in kept]
    added = Counter(k[1] for k in keys if k and k[0] == "added")
    removed = Counter(k[1] for k in keys if k and k[0] == "removed")
    budget = {"added": added & removed, "removed": added & removed}
    out = []
    for f, k in zip(kept, keys):
        if k and budget[k[0]][k[1]] > 0:
            budget[k[0]][k[1]] -= 1
            continue
        out.append(f)
    return out


def diff_asset(asset: ITAsset) -> _Diff:
    state = sa_inspect(asset)
    d = _Diff()
    for col in TRACKED_COLUMNS:
        hist = state.attrs[col].history
        if not hist.has_changes():
            continue
        old = hist.deleted[0] if hist.deleted else None
        new = hist.added[0] if hist.added else None
        if col == "platform_properties":
            a = old if isinstance(old, dict) else {}
            b = new if isinstance(new, dict) else {}
            for sec in sorted(set(a) | set(b), key=str):
                if sec not in _VOLATILE_SECTIONS and not _volatile(sec):
                    d.tree(sec, sec, SECTION_CATEGORIES.get(sec, "platform"), a.get(sec), b.get(sec))
        else:
            d.tree(col, col, COLUMN_CATEGORIES.get(col, "other"), old, new)
    return d


_LIST_PREVIEW = 50     # current items sent per list field; the count is always complete
_MAX_TRACKS = 5000   # leaf fields; a list counts once however many items


def field_tracks(asset: ITAsset) -> List[Dict[str, Any]]:
    """Every field of the asset as it is now, named exactly like the journal's
    field paths so each one can be joined to its changes. kind: 'value' (one
    value), 'list' (items: count + preview), 'live' (a reading the journal
    deliberately ignores, e.g. free space)."""
    out: List[Dict[str, Any]] = []

    def put(path: str, section: str, cat: str, kind: str, value: Any, count: Optional[int] = None) -> None:
        if len(out) < _MAX_TRACKS:
            hidden = is_sensitive_key(path.rsplit(".", 1)[-1]) and value not in (None, "")
            out.append({"path": path, "section": section, "category": cat, "kind": kind,
                        "value": "***" if hidden else value, "count": count})

    def walk(path: str, section: str, cat: str, v: Any) -> None:
        if isinstance(v, dict):
            skip = _SECTION_VOLATILE.get(section, ())
            for k in sorted(v, key=str):
                if _volatile(k) or k in skip:
                    if not isinstance(v[k], (dict, list)):
                        put(f"{path}.{k}", section, cat, "live", _coerce(v[k]))
                    continue
                walk(f"{path}.{k}", section, cat, v[k])
            return
        if isinstance(v, list):
            items = [x for x in v if not _ephemeral(x)]
            put(path, section, cat, "list", [_summary(x) for x in items[:_LIST_PREVIEW]], len(items))
            return
        put(path, section, cat, "value", _coerce(v))

    for col in TRACKED_COLUMNS:
        v = getattr(asset, col, None)
        if col != "platform_properties":
            walk(col, col, COLUMN_CATEGORIES.get(col, "other"), v)
            continue
        for sec, data in sorted((v or {}).items(), key=lambda kv: str(kv[0])):
            if sec not in _VOLATILE_SECTIONS and not _volatile(sec):
                walk(sec, sec, SECTION_CATEGORIES.get(sec, "platform"), data)
    return out


def _detail(d: _Diff) -> str:
    by_cat: Dict[str, int] = {}
    for s in d.sections.values():
        by_cat[s["category"]] = by_cat.get(s["category"], 0) + s["added"] + s["removed"] + s["changed"]
    parts = ", ".join(f"{c} {n}" for c, n in sorted(by_cat.items(), key=lambda kv: -kv[1]))
    return f"{d.total} change{'s' if d.total != 1 else ''} ({parts})"


def build_entry(asset: ITAsset) -> Optional[AuditLog]:
    """AuditLog row for this asset's pending changes, or None. Labels are
    consumed either way, so one never leaks onto a later change."""
    d = diff_asset(asset)
    info = sa_inspect(asset).info
    mark, stash = info.pop(_MARK, None), info.pop(_STASH, None)
    if not d.total:
        return None
    source, user_id = mark or stash or (("manual" if _collector.get() is not None else "system"), None)
    return AuditLog(
        tenant_id=asset.tenant_id, user_id=user_id, action=ACTION,
        resource_type="it_asset", resource_id=asset.id,
        changes={"detail": _detail(d), "source": source, "fields": d.rows, "sections": d.sections,
                 "total_fields": d.total, "truncated": max(0, d.total - len(d.rows))},
    )


# ─── listeners ───────────────────────────────────────────────────────

def _on_set(target, value, oldvalue, initiator):
    # Latest writer labels the pending change; an unlabelled write clears a stale label.
    ctx = _ctx.get()
    info = sa_inspect(target).info
    if ctx is not None:
        info[_STASH] = ctx
    else:
        info.pop(_STASH, None)
    return value


def _on_before_flush(session: Session, flush_context, instances) -> None:
    try:
        for obj in list(session.dirty):
            if isinstance(obj, ITAsset) and obj.id is not None:
                row = build_entry(obj)
                if row is not None:
                    session.add(row)
    except Exception:
        # Journalling must never break or roll back the caller's write.
        logger.warning("asset change journal failed; continuing", exc_info=True)


# active_history loads the old value before a set, so the diff is exact even on
# expired (post-commit) instances.
for _col in TRACKED_COLUMNS:
    event.listen(getattr(ITAsset, _col), "set", _on_set, active_history=True, retval=True)
event.listen(Session, "before_flush", _on_before_flush)
