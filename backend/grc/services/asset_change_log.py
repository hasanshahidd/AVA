"""Field-level change journalling for IT assets.

Writes one AuditLog row per asset update carrying the per-field old→new diff and
the change source (manual edit / scan / network discovery / connector / agent),
so the asset History tab and the dedicated history page can render a real diff
timeline filterable by source. Builds on the generic AuditLog — no parallel table.

Any asset write path can adopt this: snapshot() the asset before mutating, then
call record_asset_changes() before the commit. The manual edit path is wired in
assets_router.update_asset; scan / discovery / connector / agent writers can call
the same helper with their own `source`.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from sqlalchemy.orm import Session

from ..models import AuditLog, ITAsset

# Human-meaningful asset columns we journal. Derived/noisy columns (scores,
# timestamps, large JSON blobs) are deliberately excluded so the timeline reads
# as real decisions, not churn.
TRACKED_FIELDS = (
    "name", "asset_type", "description", "status", "lifecycle_state",
    "criticality", "criticality_manual_override",
    "confidentiality_rating", "integrity_rating", "availability_rating",
    "data_classification", "business_function", "environment",
    "owner_name", "owner_id", "custodian",
    "host_name", "ip_address", "fqdn", "primary_mac",
    "os_family", "os_version", "serial_number", "manufacturer", "model",
    "vendor", "location", "department", "assigned_user",
    "internet_facing", "network_segment",
)

VALID_SOURCES = {"manual", "scan", "discovery", "connector", "agent", "import"}

ACTION = "asset.updated"


def snapshot(asset: ITAsset) -> Dict[str, Any]:
    """Capture tracked-field values before a mutation."""
    return {f: getattr(asset, f, None) for f in TRACKED_FIELDS}


def _json(v: Any) -> Any:
    """Keep change values JSON-serialisable and short."""
    if v is None or isinstance(v, (str, int, float, bool)):
        return v
    return str(v)


def diff(before: Dict[str, Any], after: Dict[str, Any]) -> List[Dict[str, Any]]:
    changes: List[Dict[str, Any]] = []
    for f in TRACKED_FIELDS:
        old, new = before.get(f), after.get(f)
        if old != new:
            changes.append({"field": f, "old": _json(old), "new": _json(new)})
    return changes


def record_asset_changes(db: Session, asset: ITAsset, before: Dict[str, Any], *,
                         source: str = "manual", user_id: Optional[int] = None,
                         detail: Optional[str] = None) -> Optional[AuditLog]:
    """Diff `before` (a snapshot()) against the asset's current values and, when
    anything changed, ADD (not commit) an AuditLog row carrying the field diff +
    source. Returns the row, or None when nothing changed. The caller's existing
    commit persists it atomically with the asset."""
    src = source if source in VALID_SOURCES else "manual"
    changes = diff(before, snapshot(asset))
    if not changes:
        return None
    if detail is None:
        names = ", ".join(c["field"] for c in changes[:4])
        more = f" +{len(changes) - 4} more" if len(changes) > 4 else ""
        detail = f"{len(changes)} field{'s' if len(changes) != 1 else ''} changed: {names}{more}"
    row = AuditLog(
        tenant_id=asset.tenant_id,
        user_id=user_id,
        action=ACTION,
        resource_type="it_asset",
        resource_id=asset.id,
        changes={"detail": detail, "source": src, "fields": changes},
    )
    db.add(row)
    return row
