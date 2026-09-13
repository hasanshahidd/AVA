"""Fable attack-pipeline API.

Stage 1 (find), driven off the IT Asset Inventory:
  GET  /attack-pipeline/capabilities        the MCP matrix (what each can do)
  GET  /attack-pipeline/classify?asset_id=  Fable's classification of one asset (dry)
  POST /attack-pipeline/run?asset_id=       classify → pick MCP → find → vulns + trace

Stage 2 (build + run the exploit on the produced vuln) is a later portion on this
same router. The core Eva AI is not modified — this is an additive module.
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from ...models import ITAsset, GRCUser, get_db
from ...routers.auth_router import require_auth, require_tenant_permission
from .fable import Fable, classify

router = APIRouter(prefix="/attack-pipeline", tags=["Attack Pipeline (Fable)"])

_PERM = require_tenant_permission("vulnerabilities:vulnerability_register:view")


def _load_asset(db: Session, asset_id: int) -> ITAsset:
    asset = db.query(ITAsset).filter(ITAsset.id == asset_id).first()
    if not asset:
        raise HTTPException(status_code=404, detail="Asset not found in the IT Asset Inventory")
    return asset


@router.get("/capabilities")
def capabilities(
    current_user: GRCUser = Depends(require_auth),
    _perm: bool = Depends(_PERM),
):
    """The MCP layer matrix — what Fable can pick from and what each is for."""
    return {"capabilities": Fable().capabilities()}


@router.get("/classify")
def classify_asset(
    asset_id: int = Query(..., description="An IT Asset Inventory asset id"),
    db: Session = Depends(get_db),
    current_user: GRCUser = Depends(require_auth),
    _perm: bool = Depends(_PERM),
):
    """Fable's classification of one asset (no scan) — device class, credential
    need, and the rationale/signals it decided from."""
    asset = _load_asset(db, asset_id)
    return {"asset_id": asset_id, "asset_name": getattr(asset, "name", None),
            "classification": classify(asset).as_dict()}


@router.post("/run")
def run_stage1(
    asset_id: int = Query(..., description="An IT Asset Inventory asset id (from the inventory)"),
    db: Session = Depends(get_db),
    current_user: GRCUser = Depends(require_auth),
    _perm: bool = Depends(_PERM),
):
    """Stage 1: classify the asset → pick the MCP by class + credential need →
    run the finder → return vulnerabilities plus Fable's full decision trace."""
    asset = _load_asset(db, asset_id)
    result = Fable().run_stage1(db, asset)
    return {"asset_id": asset_id, "asset_name": getattr(asset, "name", None), **result}
