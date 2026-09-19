"""/asset-import endpoints — smart Excel/CSV import wizard (isolated module).

analyze : parse + auto-map + preview (NO writes)
commit  : apply the confirmed mapping -> create/update assets (+ provenance batch)
undo    : remove the assets a batch created
Template download reuses the existing GET /assets/template/download.
"""
from __future__ import annotations

import json
from typing import Optional

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from grc.models import GRCUser, get_db
from grc.routers.auth_router import get_user_primary_tenant, require_auth

from . import service
from .schema import AnalyzeResponse, CommitResponse, UndoResponse

router = APIRouter(prefix="/asset-import", tags=["Asset Import"])

_MAX_BYTES = 15 * 1024 * 1024  # 15 MB upload cap


async def _read_capped(file: UploadFile) -> bytes:
    content = await file.read()
    if len(content) > _MAX_BYTES:
        raise HTTPException(status_code=413, detail="File too large (max 15 MB).")
    if not content:
        raise HTTPException(status_code=400, detail="Empty file.")
    return content


@router.post("/analyze", response_model=AnalyzeResponse)
async def analyze_file(
    file: UploadFile = File(...),
    current_user: GRCUser = Depends(require_auth),
):
    content = await _read_capped(file)
    try:
        return service.analyze(content, file.filename or "upload")
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:  # noqa: BLE001
        raise HTTPException(status_code=400, detail=f"Could not read the file: {e}")


@router.post("/commit", response_model=CommitResponse)
async def commit_file(
    file: UploadFile = File(...),
    mapping: str = Form(...),          # JSON: {source_header: canonical_field|null}
    options: str = Form("{}"),         # JSON: {dupe_strategy: "skip"|"update", header_row: int}
    db: Session = Depends(get_db),
    current_user: GRCUser = Depends(require_auth),
):
    tenant_id = get_user_primary_tenant(current_user, db)
    if not tenant_id:
        raise HTTPException(status_code=400, detail="User is not assigned to any tenant.")
    try:
        colmap = json.loads(mapping)
        opts = json.loads(options or "{}")
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Malformed mapping/options JSON.")
    content = await _read_capped(file)
    try:
        return service.commit(
            db, tenant_id, content, file.filename or "upload", colmap,
            dupe_strategy=str(opts.get("dupe_strategy", "skip")),
            header_row=opts.get("header_row"),
        )
    except ValueError as e:
        db.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:  # noqa: BLE001
        db.rollback()
        raise HTTPException(status_code=400, detail=f"Import failed: {e}")


@router.post("/undo/{batch_id}", response_model=UndoResponse)
def undo_batch(
    batch_id: str,
    db: Session = Depends(get_db),
    current_user: GRCUser = Depends(require_auth),
):
    tenant_id = get_user_primary_tenant(current_user, db)
    if not tenant_id:
        raise HTTPException(status_code=400, detail="User is not assigned to any tenant.")
    return service.undo(db, tenant_id, batch_id)
