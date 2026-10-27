"""Register-owned vulnerability scanning.

Scan ownership lives in the Vulnerability Register: an asset can be scanned with no
follow-on action (no pentest run, no exploit). This REUSES the pentest scan engine
seam verbatim — `service.assess()` (auto-routes lane + scanner + credential decision)
then `service.start_scan()` (find-only; run_id defaults to None) — which already
persists findings into the shared register tables (grc_vulnerabilities +
grc_vulnerability_asset_links, source 'ai-pentest:<tool>'). Nothing new scans here.

Two input modes, mirroring the old pentest launcher (NO manual lane pick — the lane is
auto-routed from the asset's type by assess()):
  * from-inventory  — POST /assets/{id}/scan
  * ad-hoc target   — POST /scan/adhoc  (reuses create_or_get_adhoc_target → same scan)

Plan/recon preview is a per-asset read (assess()), no run needed: GET /assets/{id}/scan-plan.
Poll progress via GET /scan-jobs/{job_id} or /assets/{asset_id}/scan-latest.
"""
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ....models import get_db
from ....routers.auth_router import require_auth, get_user_tenants
from ...pentest import service
# Reuse the pentest scan RBAC (fail-open until pentest:* is seeded) — scanning is the
# same capability wherever it is triggered, so no new permission / migration is needed.
from ...pentest.router import _require_scan

router = APIRouter(tags=["Vulnerability Management"])


class AdhocScanIn(BaseModel):
    target: str                       # URL / host / IP / git repo URL (not in inventory)
    authorized: bool = False          # REQUIRED scope gate: operator confirms authorization
    allow_uncredentialed: bool = False
    coverage: str = "auto"


def _launch_find_scan(db: Session, asset_id: int, user_tenants: list, *,
                      allow_uncredentialed: bool, coverage: str) -> dict:
    """Shared body for both scan modes: assess() (auto-route) → credential gate → start_scan()
    (find-only, run_id=None). Raises HTTPException (404/409/422) the router surfaces as-is.
    Returns the queued job {job_id, status}."""
    coverage = (coverage or "auto").lower()
    if coverage not in service._COVERAGE_MODES:
        raise HTTPException(status_code=422,
                            detail=f"coverage must be one of {', '.join(service._COVERAGE_MODES)}.")
    result = service.assess(db, asset_id, user_tenants)
    if result is None:
        raise HTTPException(status_code=404, detail="asset not found")

    creds = result["credentials"]
    routing = result["routing"]
    # Creds-required lane with none configured -> refuse by default (don't scan blind),
    # unless the operator explicitly opted into an uncredentialed run.
    if creds["action"] == "prompt" and creds["mode"] == "required" and not allow_uncredentialed:
        lane = routing.get("lane_label") or routing.get("lane") or "this"
        raise HTTPException(
            status_code=409,
            detail=(f"The {lane} lane requires credentials and none are configured for this "
                    f"asset. Add a credential profile, or re-run with allow_uncredentialed=true."))

    chosen = routing.get("selected_find")           # auto-routed scanner for this asset's lane
    if coverage in ("nessus", "openvas"):            # CONTRACT C force pins the internal scanner
        chosen = coverage
    if not chosen:
        raise HTTPException(
            status_code=422,
            detail=f"No find scanner is available for this asset. {routing.get('reason') or ''}".strip())

    asset = result["asset"]
    target = asset.get("ip") or asset.get("hostname") or asset.get("name")
    if not target:
        raise HTTPException(status_code=422, detail="Asset has no IP or hostname to scan.")

    cred_available = bool(creds.get("have_profile")) or creds.get("action") in ("reuse", "available")
    return service.start_scan(
        db, tenant_id=user_tenants[0], asset_id=asset_id, target=target,
        lane=routing.get("lane"), find_mcp=chosen,
        credentialed=cred_available and not allow_uncredentialed,
        coverage=coverage,
        # run_id defaults to None -> find-only, no exploit (register-owned scan).
    )


@router.post("/assets/{asset_id}/scan", dependencies=[Depends(_require_scan)])
def scan_register_asset(
    asset_id: int,
    allow_uncredentialed: bool = False,  # opt-in: scan WITHOUT creds on a creds-required lane
    coverage: str = "auto",              # auto | all | nessus | openvas (passthrough to engine)
    db: Session = Depends(get_db),
    current_user=Depends(require_auth),
):
    """Launch a LIVE find-scan of ONE inventory asset FROM the register. Lane is auto-routed by
    assess() (no manual pick). Findings land in the register; this does NOT create a pentest run."""
    user_tenants = get_user_tenants(current_user, db)
    if not user_tenants:
        raise HTTPException(status_code=404, detail="asset not found")
    return _launch_find_scan(db, asset_id, user_tenants,
                             allow_uncredentialed=allow_uncredentialed, coverage=coverage)


@router.post("/scan/adhoc", dependencies=[Depends(_require_scan)])
def scan_register_adhoc(
    body: AdhocScanIn,
    db: Session = Depends(get_db),
    current_user=Depends(require_auth),
):
    """Scan an AD-HOC target (not in inventory) from the register. Reuses the pentest engine's
    create_or_get_adhoc_target (transient tagged ITAsset: status='adhoc' / source='pentest-adhoc'),
    then the SAME auto-routed assess()+start_scan path. Ad-hoc findings are stored & viewable in the
    register but EXCLUDED from the inventory-only dashboard rollup (exclude_adhoc). `authorized` is a
    required scope gate. Returns {job_id, status, asset_id, adhoc:true}."""
    if not body.authorized:
        raise HTTPException(status_code=400,
                            detail="Confirm you are authorized to test this target before scanning it.")
    user_tenants = get_user_tenants(current_user, db)
    if not user_tenants:
        raise HTTPException(status_code=404, detail="no tenant")
    try:
        asset = service.create_or_get_adhoc_target(db, user_tenants[0], body.target)
    except ValueError as e:  # empty / loopback / unparseable target
        raise HTTPException(status_code=400, detail=str(e))
    res = _launch_find_scan(db, asset.id, user_tenants,
                            allow_uncredentialed=body.allow_uncredentialed, coverage=body.coverage)
    return {**res, "asset_id": asset.id, "adhoc": True}


@router.get("/assets/{asset_id}/scan-plan")
def scan_plan(
    asset_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_auth),
):
    """Plan / recon preview for ONE asset — the auto-routed lane, selected scanner and credential
    decision, plus the asset's current findings/exploitability. Pure read (assess()), NO run, NO
    scan. This is what the register's plan+scan screen shows before launching a scan."""
    user_tenants = get_user_tenants(current_user, db)
    if not user_tenants:
        raise HTTPException(status_code=404, detail="asset not found")
    result = service.assess(db, asset_id, user_tenants)
    if result is None:
        raise HTTPException(status_code=404, detail="asset not found")
    return result


@router.get("/scan-jobs/{job_id}")
def register_scan_status(
    job_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_auth),
):
    """Poll a register scan job: status/progress/stage/findings_count/error, tenant-scoped."""
    user_tenants = get_user_tenants(current_user, db)
    job = service.get_scan_job(db, job_id, user_tenants) if user_tenants else None
    if job is None:
        raise HTTPException(status_code=404, detail="scan job not found")
    return job


@router.get("/assets/{asset_id}/scan-latest")
def register_scan_latest(
    asset_id: int,
    db: Session = Depends(get_db),
    current_user=Depends(require_auth),
):
    """The asset's most-recent scan job, so the register can reconcile its scan bar to the
    backend's authoritative state on load. {status:'none'} when the asset was never scanned."""
    user_tenants = get_user_tenants(current_user, db)
    job = service.get_latest_scan_job(db, asset_id, user_tenants) if user_tenants else None
    return job or {"status": "none", "asset_id": asset_id}
