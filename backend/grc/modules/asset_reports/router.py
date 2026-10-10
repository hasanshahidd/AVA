"""/asset-reports — IT asset-inventory reporting (second entry in the Reports module).

types                 : the report catalogue (keys, titles, descriptions, formats)
GET                   : history of generated reports for the tenant (metadata only)
POST generate         : generate report_key in fmt, persist it, stream the file back
GET {id}/download     : re-download a previously generated report (stored bytes)
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from grc.models import GRCUser, Tenant, get_db
from grc.routers.auth_router import get_user_primary_tenant, require_auth

from . import service
from .models import GeneratedAssetReport

router = APIRouter(prefix="/asset-reports", tags=["Asset Reports"])


def _tenant_id(current_user: GRCUser, db: Session) -> int:
    tid = get_user_primary_tenant(current_user, db)
    if not tid:
        raise HTTPException(status_code=400, detail="User is not assigned to any tenant.")
    return tid


def _tenant_name(db: Session, tid: int) -> str:
    t = db.query(Tenant).filter(Tenant.id == tid).first()
    return (getattr(t, "name", None) or "Organization") if t else "Organization"


@router.get("/types")
def types(current_user: GRCUser = Depends(require_auth)):
    return {
        "reports": [
            {"key": k, "title": v["title"], "description": v["description"], "detail": v["detail"]}
            for k, v in service.REPORTS.items()
        ],
        "formats": service.FORMATS,
    }


@router.get("")
def history(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth)):
    tid = _tenant_id(current_user, db)
    return [
        {"id": r.id, "report_key": r.report_key, "report_title": r.report_title,
         "fmt": r.fmt, "filename": r.filename, "size_bytes": r.size_bytes,
         "asset_count": r.asset_count, "generated_by": r.generated_by,
         "generated_at": r.generated_at.isoformat() if r.generated_at else None}
        for r in service.list_reports(db, tid)
    ]


@router.post("/generate")
def generate(report: str = Query(...), fmt: str = Query(..., pattern="^(pdf|xlsx|csv|html)$"),
             db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth)):
    tid = _tenant_id(current_user, db)
    if report not in service.REPORTS:
        raise HTTPException(status_code=400, detail=f"Unknown report '{report}'.")
    row, data = service.generate(
        db, tid, report, fmt,
        user=getattr(current_user, "email", None),
        tenant_name=_tenant_name(db, tid))
    return StreamingResponse(
        iter([data]), media_type=row.content_type,
        headers={"Content-Disposition": f'attachment; filename="{row.filename}"'})


@router.get("/{report_id}/download")
def download(report_id: int, db: Session = Depends(get_db),
             current_user: GRCUser = Depends(require_auth)):
    tid = _tenant_id(current_user, db)
    row = (db.query(GeneratedAssetReport)
           .filter(GeneratedAssetReport.id == report_id,
                   GeneratedAssetReport.tenant_id == tid)
           .first())
    if not row:
        raise HTTPException(status_code=404, detail="Report not found.")
    return StreamingResponse(
        iter([row.content]), media_type=row.content_type,
        headers={"Content-Disposition": f'attachment; filename="{row.filename}"'})
