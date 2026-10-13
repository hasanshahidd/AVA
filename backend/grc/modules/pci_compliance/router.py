"""/pci-compliance — PCI-DSS 4.0.1 compliance (real requirements + assessment).

overview         : per-requirement-group coverage + overall (dashboard roll-up)
requirements     : the full requirement tree with status/note/evidence (?group=3)
POST assess      : set status/note/evidence for one requirement code
POST bulk        : set a whole top-level group to one status
"""
from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Body, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from grc.models import GRCUser, get_db
from grc.routers.auth_router import get_user_primary_tenant, require_auth

from . import service

router = APIRouter(prefix="/pci-compliance", tags=["PCI Compliance"])


def _tenant(current_user: GRCUser, db: Session) -> int:
    tid = get_user_primary_tenant(current_user, db)
    if not tid:
        raise HTTPException(status_code=400, detail="User is not assigned to any tenant.")
    return tid


@router.get("/overview")
def overview(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth)):
    return service.overview(db, _tenant(current_user, db))


@router.get("/requirements")
def requirements(
    group: Optional[str] = Query(None),
    db: Session = Depends(get_db),
    current_user: GRCUser = Depends(require_auth),
):
    return service.requirements(db, _tenant(current_user, db), group)


@router.post("/assess")
def assess(
    payload: dict = Body(...),
    db: Session = Depends(get_db),
    current_user: GRCUser = Depends(require_auth),
):
    code = (payload or {}).get("requirement_code")
    status = (payload or {}).get("status")
    if not code or not status:
        raise HTTPException(status_code=422, detail="requirement_code and status are required.")
    try:
        row = service.assess(
            db,
            _tenant(current_user, db),
            code,
            status,
            note=payload.get("note"),
            evidence=payload.get("evidence"),
            user=getattr(current_user, "email", None),
        )
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    return {"requirement_code": row.requirement_code, "status": row.status}


@router.post("/bulk")
def bulk(
    payload: dict = Body(...),
    db: Session = Depends(get_db),
    current_user: GRCUser = Depends(require_auth),
):
    group = (payload or {}).get("group")
    status = (payload or {}).get("status")
    if not group or not status:
        raise HTTPException(status_code=422, detail="group and status are required.")
    try:
        n = service.bulk_assess(db, _tenant(current_user, db), str(group), status,
                                user=getattr(current_user, "email", None))
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))
    return {"group": group, "status": status, "updated": n}
