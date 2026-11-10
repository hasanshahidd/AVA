"""Field-level change journal for IT assets.

One SQLAlchemy ``before_flush`` listener (the same pattern as ``audit_capture``)
writes one ``AuditLog`` row per changed asset per flush: action
``asset.updated``, resource ``it_asset``/<id>, and
``changes = {"detail", "source", "fields": [{field, category, old, new}]}``.
Because it sits at the ORM layer, EVERY write path is journalled: manual edits,
scans, network discovery, connector syncs (incl. Broadcom CMDB), agent reports
and imports. There is no parallel table.

Each write path says where a change came from:

* ``@change_source("discovery")`` (decorator or ``with`` block) labels every
  asset attribute set inside it;
* ``mark_source(asset, "manual", user_id=...)`` stamps one asset explicitly
  (wins over the context label).

Unlabelled changes fall back to ``manual`` inside an audited HTTP request and
``system`` elsewhere. Only ORM unit-of-work writes are seen (bulk/Core UPDATEs
bypass it, as documented in ``audit_capture``).
"""
from __future__ import annotations

import logging
from contextlib import contextmanager
from contextvars import ContextVar
from typing import Any, Dict, Iterator, List, Optional, Tuple

from sqlalchemy import event, inspect as sa_inspect
from sqlalchemy.orm import Session

from ..audit_capture import _coerce, _collector
from ..models import AuditLog, ITAsset

logger = logging.getLogger(__name__)

# Field → category. Order here is the order fields render inside a category.
FIELD_CATEGORIES: Dict[str, str] = {
    # Identity — what the asset is and how it is addressed.
    "name": "identity", "asset_type": "identity", "description": "identity",
    "host_name": "identity", "fqdn": "identity", "ip_address": "identity",
    "primary_mac": "identity", "serial_number": "identity",
    # Classification — how much it matters.
    "criticality": "classification", "criticality_manual_override": "classification",
    "confidentiality_rating": "classification", "integrity_rating": "classification",
    "availability_rating": "classification", "data_classification": "classification",
    "business_function": "classification", "environment": "classification",
    # Ownership — who is accountable and where it lives.
    "owner_name": "ownership", "owner_id": "ownership", "owning_team": "ownership",
    "custodian": "ownership", "department": "ownership", "assigned_user": "ownership",
    "location": "ownership",
    # Platform — hardware and operating system.
    "os_family": "platform", "os_version": "platform", "os_build": "platform",
    "os_edition": "platform", "manufacturer": "platform", "model": "platform",
    "vendor": "platform", "agent_version": "platform",
    # Lifecycle — state over time.
    "status": "lifecycle", "lifecycle_state": "lifecycle",
    "warranty_expiry": "lifecycle", "eol_date": "lifecycle",
    # Exposure — reachability.
    "internet_facing": "exposure", "network_segment": "exposure",
}
TRACKED_FIELDS: Tuple[str, ...] = tuple(FIELD_CATEGORIES)
CATEGORIES = ("identity", "classification", "ownership", "platform", "lifecycle", "exposure")

VALID_SOURCES = {"manual", "scan", "discovery", "connector", "agent", "import", "system"}
ACTION = "asset.updated"

_STASH = "asset_change_ctx"     # label captured at attribute-set time
_MARK = "asset_change_mark"     # explicit per-object label (wins)

# (source, user_id) for the code currently mutating assets.
_ctx: ContextVar[Optional[Tuple[str, Optional[int]]]] = ContextVar("asset_change_source", default=None)


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


def category_of(field: str) -> str:
    return FIELD_CATEGORIES.get(field, "other")


def _on_set(target, value, oldvalue, initiator):
    # Latest writer labels the pending change; an unlabelled write clears a stale label.
    ctx = _ctx.get()
    info = sa_inspect(target).info
    if ctx is not None:
        info[_STASH] = ctx
    else:
        info.pop(_STASH, None)
    return value


def _field_changes(asset: ITAsset) -> List[Dict[str, Any]]:
    state = sa_inspect(asset)
    out: List[Dict[str, Any]] = []
    for f in TRACKED_FIELDS:
        hist = state.attrs[f].history
        if not hist.has_changes():
            continue
        old = hist.deleted[0] if hist.deleted else None
        new = hist.added[0] if hist.added else None
        if old == new:
            continue
        out.append({"field": f, "category": category_of(f), "old": _coerce(old), "new": _coerce(new)})
    return out


def _detail(changes: List[Dict[str, Any]]) -> str:
    names = ", ".join(c["field"] for c in changes[:4])
    more = f" +{len(changes) - 4} more" if len(changes) > 4 else ""
    return f"{len(changes)} field{'s' if len(changes) != 1 else ''} changed: {names}{more}"


def build_entry(asset: ITAsset) -> Optional[AuditLog]:
    """AuditLog row for this asset's pending tracked-field changes, or None.
    Labels are consumed either way, so one never leaks onto a later change."""
    changes = _field_changes(asset)
    info = sa_inspect(asset).info
    mark, stash = info.pop(_MARK, None), info.pop(_STASH, None)
    if not changes:
        return None
    source, user_id = mark or stash or (("manual" if _collector.get() is not None else "system"), None)
    return AuditLog(
        tenant_id=asset.tenant_id, user_id=user_id, action=ACTION,
        resource_type="it_asset", resource_id=asset.id,
        changes={"detail": _detail(changes), "source": source, "fields": changes},
    )


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
for _f in TRACKED_FIELDS:
    event.listen(getattr(ITAsset, _f), "set", _on_set, active_history=True, retval=True)
event.listen(Session, "before_flush", _on_before_flush)
