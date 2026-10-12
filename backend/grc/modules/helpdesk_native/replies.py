"""Saved / canned replies — native read + tenant-isolated CRUD (§A11, §A16–§A19).

Native transcription backed by the single HDSavedReply table (the proxy kept two
Frappe doctypes; the native model consolidated to one). `name` == the integer PK
as string, same convention as tickets.

Isolation (owner's #1 requirement — mirrors the proxy's `_saved_reply_in_tenant`):
  * create tags tenant_id, so the reply can only ever surface for this tenant.
  * edit/delete resolve the row WITH the tenant_id filter first; an out-of-tenant
    id returns no row → 404 (never confirms another tenant's record, never writes
    it). `_get_reply` IS that guard.

`list_canned_responses` returns the `message` body too (the proxy did not), so the
ticket composer's "insert canned reply" inserts the real text, not just the title
(§A11 FLAG).
"""
from __future__ import annotations

from fastapi import HTTPException
from sqlalchemy.orm import Session

from ...models import HDSavedReply
from .common import iso


def _get_reply(db: Session, tid: int, name: str):
    """Tenant-scoped fetch by contract `name` (our integer PK). The tenant_id
    filter is the isolation guard: a crafted/cross-tenant id yields None."""
    try:
        pk = int(name)
    except (TypeError, ValueError):
        return None
    return (
        db.query(HDSavedReply)
        .filter(HDSavedReply.id == pk, HDSavedReply.tenant_id == tid)
        .first()
    )


def list_saved_replies(db: Session, tid: int) -> dict:
    """§A16. Full replies with body for the settings page."""
    rows = (
        db.query(HDSavedReply)
        .filter(HDSavedReply.tenant_id == tid)
        .order_by(HDSavedReply.updated_at.desc())
        .all()
    )
    return {"saved_replies": [{
        "name": str(r.id),
        "title": r.title or str(r.id),
        "message": r.message or "",
        "owner": None,          # no owner column natively (user→grc_users deferred); not shown on settings page
        "modified": iso(r.updated_at),
    } for r in rows]}


def list_canned_responses(db: Session, tid: int) -> dict:
    """§A11. Same store as saved-replies; returns `message` so inserts use the
    real body, not the title."""
    rows = (
        db.query(HDSavedReply)
        .filter(HDSavedReply.tenant_id == tid)
        .order_by(HDSavedReply.updated_at.desc())
        .all()
    )
    return {"responses": [{
        "name": str(r.id),
        "title": r.title or str(r.id),
        "message": r.message or "",
        "owner": None,
    } for r in rows]}


def create_saved_reply(db: Session, tid: int, payload: dict) -> dict:
    """§A17. Tags tenant_id so the reply stays tenant-scoped (message is reqd
    non-null → default "")."""
    db.add(HDSavedReply(
        tenant_id=tid,
        title=payload.get("title") or "Untitled",
        message=payload.get("message") or "",
    ))
    db.commit()
    return {"ok": True}


def update_saved_reply(db: Session, tid: int, name: str, payload: dict) -> dict:
    """§A18. In-tenant guard first (404 on a cross-tenant id), then write."""
    r = _get_reply(db, tid, name)
    if not r:
        raise HTTPException(status_code=404, detail="not found")
    if payload.get("title") is not None:
        r.title = payload["title"]
    r.message = payload.get("message") or ""
    db.commit()
    return {"ok": True}


def delete_saved_reply(db: Session, tid: int, name: str) -> dict:
    """§A19. In-tenant guard first (404 on a cross-tenant id), then delete."""
    r = _get_reply(db, tid, name)
    if not r:
        raise HTTPException(status_code=404, detail="not found")
    db.delete(r)
    db.commit()
    return {"ok": True}
