"""Notes, History and derived Alerts for assets and vulnerabilities.

Three things the reference product has that we lacked. Grouped in one router
because they share the same shape (given an entity, return a list) and the
same tenant-scoping.

  * Notes    — a real collaboration thread, backed by `grc_entity_notes`.
  * History  — an audit trail. We write to the existing generic AuditLog on
               asset/vuln edits elsewhere; here we READ it back per entity.
  * Alerts   — DERIVED, not stored. There is no alert producer in our system,
               so a table would be permanently empty. Instead we compute the
               alerts that matter from data we already hold: open KEV/critical
               findings, overdue SLAs, and stale discovery. Populated from day
               one, nothing to maintain.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import func
from sqlalchemy.orm import Session

from ..models import (
    ASSET_RELATIONSHIP_TYPES, AssetAlertState, AssetRelationship, AuditLog,
    EntityNote, GRCUser, ITAsset, Vulnerability, VulnerabilityAssetLink, get_db,
)
from .auth_router import require_auth, get_user_tenants

logger = logging.getLogger(__name__)
router = APIRouter(tags=["Notes, History & Alerts"])

_VALID_ENTITIES = {"asset", "vulnerability"}


def _check_entity(entity_type: str, entity_id: int, tenants: List[int], db: Session) -> None:
    """404 if the entity doesn't exist in one of the caller's tenants."""
    if entity_type not in _VALID_ENTITIES:
        raise HTTPException(400, f"Unknown entity type '{entity_type}'")
    model = ITAsset if entity_type == "asset" else Vulnerability
    exists = db.query(model.id).filter(
        model.id == entity_id, model.tenant_id.in_(tenants)
    ).first()
    if not exists:
        raise HTTPException(404, f"{entity_type} not found in this tenant")


# ─── Notes ──────────────────────────────────────────────────────────────────

class NoteIn(BaseModel):
    body: str = Field(min_length=1, max_length=8000)


class NoteOut(BaseModel):
    id: int
    body: str
    author_name: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True


@router.get("/notes/{entity_type}/{entity_id}", response_model=List[NoteOut])
def list_notes(entity_type: str, entity_id: int, db: Session = Depends(get_db),
               current_user: GRCUser = Depends(require_auth)):
    tenants = get_user_tenants(current_user, db) or []
    _check_entity(entity_type, entity_id, tenants, db)
    return (
        db.query(EntityNote)
        .filter(
            EntityNote.tenant_id.in_(tenants),
            EntityNote.entity_type == entity_type,
            EntityNote.entity_id == entity_id,
        )
        .order_by(EntityNote.created_at.desc())
        .all()
    )


@router.post("/notes/{entity_type}/{entity_id}", response_model=NoteOut, status_code=201)
def add_note(entity_type: str, entity_id: int, body: NoteIn, db: Session = Depends(get_db),
             current_user: GRCUser = Depends(require_auth)):
    tenants = get_user_tenants(current_user, db) or []
    _check_entity(entity_type, entity_id, tenants, db)
    note = EntityNote(
        tenant_id=tenants[0],
        entity_type=entity_type,
        entity_id=entity_id,
        body=body.body.strip(),
        author_id=current_user.id,
        author_name=getattr(current_user, "display_name", None) or current_user.username,
    )
    db.add(note)
    db.commit()
    db.refresh(note)
    return note


# ─── History (read the generic AuditLog per entity) ──────────────────────────

class HistoryOut(BaseModel):
    id: int
    action: str
    detail: Optional[str] = None
    actor_name: Optional[str] = None
    created_at: Optional[datetime] = None
    # Field-level diff + source for the change-history timeline (asset.updated rows).
    source: Optional[str] = None
    fields: Optional[List[Dict[str, Any]]] = None
    sections: Optional[Dict[str, Any]] = None    # per-section added/removed/changed totals
    total_fields: Optional[int] = None
    truncated: Optional[int] = None


@router.get("/history/{entity_type}/{entity_id}", response_model=List[HistoryOut])
def entity_history(entity_type: str, entity_id: int, db: Session = Depends(get_db),
                   current_user: GRCUser = Depends(require_auth)):
    """Audit rows for one entity. Empty until edits start being journalled —
    which we do on the asset/vuln update paths."""
    tenants = get_user_tenants(current_user, db) or []
    _check_entity(entity_type, entity_id, tenants, db)
    resource = "it_asset" if entity_type == "asset" else "vulnerability"
    rows = (
        db.query(AuditLog)
        .filter(
            AuditLog.tenant_id.in_(tenants),
            AuditLog.resource_type == resource,
            AuditLog.resource_id == entity_id,          # resource_id is Integer
        )
        .order_by(AuditLog.timestamp.desc())
        .limit(1000)  # shortcut: newest 1000 rows; page this if an asset ever exceeds it
        .all()
    )
    names = _ref_names(db, rows)
    out = [_history_row(r, names) for r in rows]
    return [HistoryOut(**h) for h in out if h is not None]


def _history_row(r: AuditLog, names: Dict[str, Dict[int, str]]) -> Optional[Dict[str, Any]]:
    """One history entry, or None when every journalled field is now classed as
    churn (rows written before a noise rule existed)."""
    changes = r.changes if isinstance(r.changes, dict) else None
    raw = changes.get("fields") if changes else None
    fields = _with_categories(raw, names)
    sections, total = (changes or {}).get("sections"), (changes or {}).get("total_fields")
    if isinstance(raw, list) and raw and fields is not None and len(fields) < len(raw):
        if not fields:
            return None
        if not (changes or {}).get("truncated"):   # complete rows: recount what's left
            sections = {}
            for f in fields:
                t = sections.setdefault(f.get("section") or f["field"],
                                        {"category": f["category"], "added": 0, "removed": 0, "changed": 0})
                t[f.get("change") if f.get("change") in ("added", "removed") else "changed"] += 1
            total = len(fields)
    detail = None
    if changes:
        detail = changes.get("detail") or ", ".join(
            f"{k}: {v}" for k, v in list(changes.items())[:4]
        ) or None
    actor = None
    try:
        if r.user is not None:
            actor = getattr(r.user, "display_name", None) or getattr(r.user, "username", None)
    except Exception:
        actor = None
    return dict(
        id=r.id,
        action=r.action or "changed",
        detail=detail,
        actor_name=actor,
        created_at=r.timestamp,
        source=(changes.get("source") if changes else None),
        fields=fields,
        sections=sections,
        total_fields=total,
        truncated=(changes.get("truncated") if changes else None),
    )


@router.get("/asset-fields/{asset_id}")
def asset_fields(asset_id: int, db: Session = Depends(get_db),
                 current_user: GRCUser = Depends(require_auth)):
    """Every field of one asset as it is now (columns + telemetry), with the same
    paths as the change journal, for the field-by-field history view."""
    from ..services.asset_change_log import field_tracks
    tenants = get_user_tenants(current_user, db) or []
    asset = db.query(ITAsset).filter(ITAsset.id == asset_id, ITAsset.tenant_id.in_(tenants)).first()
    if asset is None:
        raise HTTPException(404, "asset not found in this tenant")
    fields = field_tracks(asset)
    # Owner / parent ids read as names, like they do in the history rows.
    ids = {k: {t["value"] for t in fields if t["path"] in refs and isinstance(t["value"], int)}
           for k, refs in (("user", _USER_REF_FIELDS), ("asset", _ASSET_REF_FIELDS))}
    names: Dict[str, Dict[int, str]] = {"user": {}, "asset": {}}
    if ids["user"]:
        names["user"] = {u.id: getattr(u, "display_name", None) or u.username
                         for u in db.query(GRCUser).filter(GRCUser.id.in_(ids["user"])).all()}
    if ids["asset"]:
        names["asset"] = dict(db.query(ITAsset.id, ITAsset.name).filter(
            ITAsset.id.in_(ids["asset"]), ITAsset.tenant_id.in_(tenants)).all())
    for t in fields:
        kind = "user" if t["path"] in _USER_REF_FIELDS else "asset" if t["path"] in _ASSET_REF_FIELDS else None
        if kind and isinstance(t["value"], int):
            t["label"] = names[kind].get(t["value"])
    return {"fields": fields}


@router.get("/asset-field-catalog")
def asset_field_catalog(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth)):
    """Every field across the caller's assets (paths as in the change journal) with
    how many assets hold a value for each: the estate field-by-field history."""
    from ..services.asset_change_log import estate_field_catalog
    tenants = get_user_tenants(current_user, db) or []
    # shortcut: walks every asset per request (~1 s per few thousand assets); cache per tenant if it gets slow.
    # Same managed-asset set as the inventory register (GET /assets): no transient pentest ad-hoc targets.
    assets = (db.query(ITAsset)
              .filter(ITAsset.tenant_id.in_(tenants),
                      func.coalesce(ITAsset.status, "") != "adhoc",
                      func.coalesce(ITAsset.last_seen_source, "") != "pentest-adhoc")
              .order_by(ITAsset.id).yield_per(200))
    return estate_field_catalog(assets)


class EstateHistoryOut(HistoryOut):
    asset_id: Optional[int] = None
    asset_name: Optional[str] = None
    asset_type: Optional[str] = None


@router.get("/asset-change-log", response_model=List[EstateHistoryOut])
def asset_change_log(days: int = 30, limit: int = 300, db: Session = Depends(get_db),
                     current_user: GRCUser = Depends(require_auth)):
    """Estate-wide asset change journal (newest first) for the Inventory
    'Asset history' view: the same rows as each asset's history, plus which asset."""
    tenants = get_user_tenants(current_user, db) or []
    since = datetime.utcnow() - timedelta(days=max(1, min(days, 365)))
    rows = (
        db.query(AuditLog)
        .filter(
            AuditLog.tenant_id.in_(tenants),
            AuditLog.resource_type == "it_asset",
            AuditLog.action == "asset.updated",
            AuditLog.timestamp >= since,
        )
        .order_by(AuditLog.timestamp.desc())
        .limit(max(1, min(limit, 1000)))
        .all()
    )
    names = _ref_names(db, rows)
    ids = {r.resource_id for r in rows if r.resource_id is not None}
    assets = {a.id: a for a in db.query(ITAsset.id, ITAsset.name, ITAsset.asset_type)
              .filter(ITAsset.id.in_(ids), ITAsset.tenant_id.in_(tenants)).all()} if ids else {}
    out: List[EstateHistoryOut] = []
    for r in rows:
        h = _history_row(r, names)
        if h is None:
            continue
        a = assets.get(r.resource_id)
        out.append(EstateHistoryOut(**h, asset_id=r.resource_id,
                                    asset_name=a.name if a else None, asset_type=a.asset_type if a else None))
    return out


_USER_REF_FIELDS = {"owner_id", "primary_owner_id", "secondary_owner_id", "business_owner_id", "escalation_contact_id"}
_ASSET_REF_FIELDS = {"parent_asset_id", "replacement_asset_id"}


def _ref_names(db: Session, rows: List[AuditLog]) -> Dict[str, Dict[int, str]]:
    """Display names for user / asset ids that appear as old/new values."""
    want: Dict[str, set] = {"user": set(), "asset": set()}
    for r in rows:
        for f in ((r.changes or {}).get("fields") or []) if isinstance(r.changes, dict) else []:
            if not isinstance(f, dict):
                continue
            kind = "user" if f.get("field") in _USER_REF_FIELDS else "asset" if f.get("field") in _ASSET_REF_FIELDS else None
            if kind:
                want[kind].update(v for v in (f.get("old"), f.get("new")) if isinstance(v, int))
    out: Dict[str, Dict[int, str]] = {"user": {}, "asset": {}}
    if want["user"]:
        for u in db.query(GRCUser).filter(GRCUser.id.in_(want["user"])).all():
            out["user"][u.id] = getattr(u, "display_name", None) or getattr(u, "username", None) or f"User #{u.id}"
    if want["asset"]:
        for a in db.query(ITAsset.id, ITAsset.name).filter(ITAsset.id.in_(want["asset"])).all():
            out["asset"][a.id] = a.name
    return out


def _with_categories(fields: Optional[List[Dict[str, Any]]],
                     names: Optional[Dict[str, Dict[int, str]]] = None) -> Optional[List[Dict[str, Any]]]:
    """Re-file plain column fields into the asset-record categories (older rows
    used a coarser set) and attach display names for user / asset references."""
    if not isinstance(fields, list):
        return None
    from ..services.asset_change_log import column_category, drop_churn
    names = names or {"user": {}, "asset": {}}
    out = []
    for f in drop_churn(fields):
        if isinstance(f, str):
            # Older journal rows recorded only which fields changed, not the values.
            f = {"field": f, "change": "updated", "old": None, "new": None}
        if not isinstance(f, dict):
            continue
        name = f.get("field", "")
        row = {**f, "category": column_category(name) or f.get("category") or "other"}
        kind = "user" if name in _USER_REF_FIELDS else "asset" if name in _ASSET_REF_FIELDS else None
        if kind:
            row["old_label"] = names[kind].get(f.get("old")) if isinstance(f.get("old"), int) else None
            row["new_label"] = names[kind].get(f.get("new")) if isinstance(f.get("new"), int) else None
        out.append(row)
    return out


@router.get("/asset-change-summary")
def asset_change_summary(days: int = 30, db: Session = Depends(get_db),
                         current_user: GRCUser = Depends(require_auth)):
    """Per-asset recent-change counts for the inventory 'Changes' column.
    Returns {asset_id: {count, last_at}} for the caller's tenants."""
    tenants = get_user_tenants(current_user, db) or []
    since = datetime.utcnow() - timedelta(days=max(1, min(days, 365)))
    rows = (
        db.query(AuditLog.resource_id, AuditLog.timestamp, AuditLog.changes)
        .filter(
            AuditLog.tenant_id.in_(tenants),
            AuditLog.resource_type == "it_asset",
            AuditLog.action == "asset.updated",
            AuditLog.timestamp >= since,
        )
        .all()
    )
    items: Dict[str, Dict[str, Any]] = {}
    for rid, ts, changes in rows:
        if rid is None or _is_churn_only(changes):
            continue   # same rows the history page hides, so the counts agree with it
        it = items.setdefault(str(rid), {"count": 0, "last_at": None})
        it["count"] += 1
        if ts and (it["last_at"] is None or ts.isoformat() > it["last_at"]):
            it["last_at"] = ts.isoformat()
    return {"items": items, "days": days}


def _is_churn_only(changes: Any) -> bool:
    """True when every journalled field of a row is churn under the current rules."""
    from ..services.asset_change_log import drop_churn
    fields = changes.get("fields") if isinstance(changes, dict) else None
    return isinstance(fields, list) and bool(fields) and all(isinstance(f, dict) for f in fields) and not drop_churn(fields)


# ─── Alerts (derived, no table) ──────────────────────────────────────────────

class AlertOut(BaseModel):
    severity: str          # 'critical' | 'warning' | 'info'
    title: str
    detail: str
    kind: str              # 'kev' | 'sla' | 'stale' | 'exposure'
    # Human response, read from grc_asset_alert_states. The alert itself is
    # derived; only the response to it is stored.
    status: str = "open"   # open | acknowledged | resolved
    acknowledged_by_name: Optional[str] = None
    resolved_by_name: Optional[str] = None


@router.get("/asset-alerts/{asset_id}", response_model=List[AlertOut])
def asset_alerts(asset_id: int, db: Session = Depends(get_db),
                 current_user: GRCUser = Depends(require_auth)):
    """Alerts computed live from what we already store. No producer, no table."""
    tenants = get_user_tenants(current_user, db) or []
    asset = db.query(ITAsset).filter(
        ITAsset.id == asset_id, ITAsset.tenant_id.in_(tenants)
    ).first()
    if not asset:
        raise HTTPException(404, "Asset not found in this tenant")

    alerts: List[AlertOut] = []
    now = datetime.utcnow()

    # Vulnerabilities on this asset — KEV, criticals, overdue SLA.
    vulns = (
        db.query(Vulnerability)
        .join(VulnerabilityAssetLink, VulnerabilityAssetLink.vulnerability_id == Vulnerability.id)
        .filter(VulnerabilityAssetLink.asset_id == asset_id)
        .all()
    )
    active = [v for v in vulns if (v.status or "").lower() not in ("remediated", "verified", "closed", "resolved", "accepted")]

    kev = [v for v in active if getattr(v, "kev_flag", False)]
    if kev:
        alerts.append(AlertOut(
            severity="critical", kind="kev",
            title=f"{len(kev)} known-exploited finding{'s' if len(kev) != 1 else ''} open",
            detail="Listed in CISA KEV — actively exploited in the wild. Treat as an incident.",
        ))

    crit = [v for v in active if (v.severity or "").lower() == "critical" and not getattr(v, "kev_flag", False)]
    if crit:
        alerts.append(AlertOut(
            severity="critical", kind="kev",
            title=f"{len(crit)} critical-severity finding{'s' if len(crit) != 1 else ''} open",
            detail="Critical CVSS severity, not yet remediated.",
        ))

    overdue = [v for v in active if getattr(v, "due_date", None) and v.due_date < now]
    if overdue:
        alerts.append(AlertOut(
            severity="warning", kind="sla",
            title=f"{len(overdue)} finding{'s' if len(overdue) != 1 else ''} past SLA",
            detail="Remediation due date has passed.",
        ))

    # Exposure.
    if getattr(asset, "internet_facing", False) and active:
        alerts.append(AlertOut(
            severity="warning", kind="exposure",
            title="Internet-facing with open findings",
            detail="This asset is reachable from the internet and has unresolved vulnerabilities.",
        ))

    # Risk acceptances that have lapsed, or are about to.
    #
    # Computed from the dates rather than from `exception_status`, so this is
    # right the moment the date passes — it does not wait for the expiry sweep.
    # An acceptance with no review date is called out separately: "accepted
    # forever" is a decision nobody consciously makes, it's what you get when
    # the field was left blank.
    lapsed, lapsing, undated = [], [], []
    for v in vulns:
        if (getattr(v, "exception_status", None) or "none") not in ("approved", "expired"):
            continue
        exp = getattr(v, "exception_expires_at", None)
        if exp is None:
            undated.append(v)
        elif exp < now:
            lapsed.append(v)
        elif (exp - now).days <= 30:
            lapsing.append(v)

    if lapsed:
        alerts.append(AlertOut(
            severity="critical", kind="exception_expired",
            title=f"{len(lapsed)} risk acceptance{'s have' if len(lapsed) != 1 else ' has'} expired",
            detail="The agreed review date has passed, so the risk is being carried "
                   "without current sign-off. These findings are back in the open queue.",
        ))
    if lapsing:
        soonest = min((v.exception_expires_at for v in lapsing))
        alerts.append(AlertOut(
            severity="warning", kind="exception_expiring",
            title=f"{len(lapsing)} risk acceptance{'s' if len(lapsing) != 1 else ''} up for review",
            detail=f"Earliest review date is {soonest:%d %b %Y}. Re-approve or remediate "
                   "before it lapses.",
        ))
    if undated:
        alerts.append(AlertOut(
            severity="warning", kind="exception_undated",
            title=f"{len(undated)} risk acceptance{'s' if len(undated) != 1 else ''} with no review date",
            detail="Accepted indefinitely. Set a review date so the decision is revisited.",
        ))

    # Stale discovery.
    last_seen = getattr(asset, "last_seen_at", None)
    if last_seen:
        days = (now - last_seen).days if last_seen.tzinfo is None else (datetime.now(timezone.utc) - last_seen).days
        if days > 30:
            alerts.append(AlertOut(
                severity="info", kind="stale",
                title=f"Not seen for {days} days",
                detail="No scan or agent contact recently — the record may be stale.",
            ))

    # Recent configuration changes — surface the field-level change journal as an
    # alert so an edit / scan / connector change is noticed, not just logged.
    change_rows = (
        db.query(AuditLog)
        .filter(
            AuditLog.resource_type == "it_asset",
            AuditLog.resource_id == asset_id,
            AuditLog.action == "asset.updated",
            AuditLog.timestamp >= now - timedelta(days=7),
        )
        .order_by(AuditLog.timestamp.desc())
        .all()
    )
    change_rows = [r for r in change_rows if not _is_churn_only(r.changes)]
    if change_rows:
        lc = change_rows[0].changes if isinstance(change_rows[0].changes, dict) else {}
        n = len(change_rows)
        by_source: Dict[str, int] = {}
        for r in change_rows:
            src = (r.changes or {}).get("source") if isinstance(r.changes, dict) else None
            by_source[src or "manual"] = by_source.get(src or "manual", 0) + 1
        mix = ", ".join(f"{c} {s}" for s, c in sorted(by_source.items(), key=lambda kv: -kv[1]))
        detail_txt = f"Latest: {lc.get('detail') or 'details changed'}. By source: {mix}."
        alerts.append(AlertOut(
            severity="info", kind="change",
            title=f"{n} configuration change{'s' if n != 1 else ''} in the last 7 days",
            detail=detail_txt,
        ))

    # Overlay the stored human response onto each derived alert.
    states = {
        s.alert_kind: s
        for s in db.query(AssetAlertState).filter(AssetAlertState.asset_id == asset_id).all()
    }
    for a in alerts:
        st = states.get(a.kind)
        if st:
            a.status = st.status
            a.acknowledged_by_name = st.acknowledged_by_name
            a.resolved_by_name = st.resolved_by_name

    # Unresolved first, then by severity — the same ordering as the reference.
    sev_rank = {"critical": 0, "warning": 1, "info": 2}
    alerts.sort(key=lambda a: (a.status == "resolved", sev_rank.get(a.severity, 3)))
    return alerts


def _set_alert_state(asset_id: int, kind: str, new_status: str,
                     db: Session, current_user: GRCUser) -> AlertOut:
    """Upsert the acknowledgement row for one derived alert."""
    tenants = get_user_tenants(current_user, db) or []
    asset = db.query(ITAsset).filter(
        ITAsset.id == asset_id, ITAsset.tenant_id.in_(tenants)
    ).first()
    if not asset:
        raise HTTPException(404, "Asset not found in this tenant")

    who = getattr(current_user, "display_name", None) or current_user.username
    now = datetime.utcnow()
    st = db.query(AssetAlertState).filter(
        AssetAlertState.asset_id == asset_id, AssetAlertState.alert_kind == kind
    ).first()
    if st is None:
        st = AssetAlertState(tenant_id=asset.tenant_id, asset_id=asset_id, alert_kind=kind)
        db.add(st)

    st.status = new_status
    if new_status == "acknowledged":
        st.acknowledged_by_name = who
        st.acknowledged_at = now
    elif new_status == "resolved":
        st.resolved_by_name = who
        st.resolved_at = now
        # Resolving implies it was seen.
        if not st.acknowledged_at:
            st.acknowledged_by_name, st.acknowledged_at = who, now
    db.commit()
    db.refresh(st)
    return AlertOut(
        severity="info", kind=kind, title="", detail="",
        status=st.status,
        acknowledged_by_name=st.acknowledged_by_name,
        resolved_by_name=st.resolved_by_name,
    )


@router.post("/asset-alerts/{asset_id}/{kind}/acknowledge", response_model=AlertOut)
def acknowledge_alert(asset_id: int, kind: str, db: Session = Depends(get_db),
                      current_user: GRCUser = Depends(require_auth)):
    return _set_alert_state(asset_id, kind, "acknowledged", db, current_user)


@router.post("/asset-alerts/{asset_id}/{kind}/resolve", response_model=AlertOut)
def resolve_alert(asset_id: int, kind: str, db: Session = Depends(get_db),
                  current_user: GRCUser = Depends(require_auth)):
    return _set_alert_state(asset_id, kind, "resolved", db, current_user)


# ─── Asset relationships (the CMDB edge) ────────────────────────────────────

class RelationshipIn(BaseModel):
    target_asset_id: int
    relationship_type: str = Field(default="depends_on")
    notes: Optional[str] = None


class RelationshipOut(BaseModel):
    id: int
    relationship_type: str
    direction: str            # 'outgoing' | 'incoming'
    other_asset_id: int
    other_asset_name: Optional[str] = None
    other_asset_criticality: Optional[str] = None
    notes: Optional[str] = None
    created_by_name: Optional[str] = None


@router.get("/assets/{asset_id}/relationships", response_model=List[RelationshipOut])
def list_relationships(asset_id: int, db: Session = Depends(get_db),
                       current_user: GRCUser = Depends(require_auth)):
    """Every edge touching this asset, in BOTH directions.

    Direction is preserved so the UI can say "depends on X" vs "is depended on
    by Y" — collapsing them would lose the meaning of the edge.
    """
    tenants = get_user_tenants(current_user, db) or []
    _check_entity("asset", asset_id, tenants, db)

    rows = db.query(AssetRelationship).filter(
        AssetRelationship.tenant_id.in_(tenants),
        (AssetRelationship.source_asset_id == asset_id)
        | (AssetRelationship.target_asset_id == asset_id),
    ).all()

    # One lookup for every counterpart asset rather than N queries.
    other_ids = {r.target_asset_id if r.source_asset_id == asset_id else r.source_asset_id for r in rows}
    others = {}
    if other_ids:
        for a in db.query(ITAsset).filter(ITAsset.id.in_(other_ids)).all():
            others[a.id] = a

    out: List[RelationshipOut] = []
    for r in rows:
        outgoing = r.source_asset_id == asset_id
        oid = r.target_asset_id if outgoing else r.source_asset_id
        a = others.get(oid)
        out.append(RelationshipOut(
            id=r.id,
            relationship_type=r.relationship_type,
            direction="outgoing" if outgoing else "incoming",
            other_asset_id=oid,
            other_asset_name=a.name if a else None,
            other_asset_criticality=a.criticality if a else None,
            notes=r.notes,
            created_by_name=r.created_by_name,
        ))
    return out


@router.post("/assets/{asset_id}/relationships", response_model=RelationshipOut, status_code=201)
def create_relationship(asset_id: int, body: RelationshipIn, db: Session = Depends(get_db),
                        current_user: GRCUser = Depends(require_auth)):
    tenants = get_user_tenants(current_user, db) or []
    _check_entity("asset", asset_id, tenants, db)
    _check_entity("asset", body.target_asset_id, tenants, db)

    if body.relationship_type not in ASSET_RELATIONSHIP_TYPES:
        raise HTTPException(400, f"relationship_type must be one of {', '.join(ASSET_RELATIONSHIP_TYPES)}")
    if body.target_asset_id == asset_id:
        raise HTTPException(400, "An asset cannot be related to itself")

    existing = db.query(AssetRelationship).filter(
        AssetRelationship.source_asset_id == asset_id,
        AssetRelationship.target_asset_id == body.target_asset_id,
        AssetRelationship.relationship_type == body.relationship_type,
    ).first()
    if existing:
        raise HTTPException(409, "That relationship already exists")

    rel = AssetRelationship(
        tenant_id=tenants[0],
        source_asset_id=asset_id,
        target_asset_id=body.target_asset_id,
        relationship_type=body.relationship_type,
        notes=body.notes,
        created_by_id=current_user.id,
        created_by_name=getattr(current_user, "display_name", None) or current_user.username,
    )
    db.add(rel)
    db.commit()
    db.refresh(rel)

    target = db.query(ITAsset).filter(ITAsset.id == body.target_asset_id).first()
    return RelationshipOut(
        id=rel.id, relationship_type=rel.relationship_type, direction="outgoing",
        other_asset_id=body.target_asset_id,
        other_asset_name=target.name if target else None,
        other_asset_criticality=target.criticality if target else None,
        notes=rel.notes, created_by_name=rel.created_by_name,
    )


@router.delete("/assets/{asset_id}/relationships/{rel_id}", status_code=204)
def delete_relationship(asset_id: int, rel_id: int, db: Session = Depends(get_db),
                        current_user: GRCUser = Depends(require_auth)):
    tenants = get_user_tenants(current_user, db) or []
    rel = db.query(AssetRelationship).filter(
        AssetRelationship.id == rel_id,
        AssetRelationship.tenant_id.in_(tenants),
    ).first()
    if not rel:
        raise HTTPException(404, "Relationship not found")
    # Either end may remove the edge — it is one shared fact, not two.
    if asset_id not in (rel.source_asset_id, rel.target_asset_id):
        raise HTTPException(400, "That relationship does not involve this asset")
    db.delete(rel)
    db.commit()
    return None


@router.get("/asset-relationship-types", response_model=List[str])
def relationship_types(current_user: GRCUser = Depends(require_auth)):
    return list(ASSET_RELATIONSHIP_TYPES)
