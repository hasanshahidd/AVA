"""Register-owned vulnerability scanning.

Scan ownership lives in the Vulnerability Register: an asset can be scanned with no
follow-on action (no pentest run, no exploit). This REUSES the pentest scan engine
seam verbatim — `service.assess()` (lane + scanner + credential decision) then
`service.start_scan()` (find-only; run_id defaults to None) — which already persists
findings into the shared register tables (grc_vulnerabilities +
grc_vulnerability_asset_links, source 'ai-pentest:<tool>'). Nothing new scans here.

Poll progress via GET scan-jobs/{job_id} or assets/{asset_id}/scan-latest.
"""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from ....models import get_db
from ....routers.auth_router import require_auth, get_user_tenants
from ...pentest import service
# Reuse the pentest scan RBAC (fail-open until pentest:* is seeded) — scanning is the
# same capability wherever it is triggered, so no new permission / migration is needed.
from ...pentest.router import _require_scan

router = APIRouter(tags=["Vulnerability Management"])


@router.post("/assets/{asset_id}/scan", dependencies=[Depends(_require_scan)])
def scan_register_asset(
    asset_id: int,
    allow_uncredentialed: bool = False,  # opt-in: scan WITHOUT creds on a creds-required lane
    coverage: str = "auto",              # auto | all | nessus | openvas (passthrough to engine)
    db: Session = Depends(get_db),
    current_user=Depends(require_auth),
):
    """Launch a LIVE find-scan of ONE inventory asset FROM the register. Routes via
    assess() (lane + brain-selected scanner + credential decision), enforces the same
    credential gate as the pentest scan, then queues the scan. Findings land in the
    register; this does NOT create a pentest run. Returns the job id to poll."""
    coverage = (coverage or "auto").lower()
    if coverage not in service._COVERAGE_MODES:
        raise HTTPException(
            status_code=422,
            detail=f"coverage must be one of {', '.join(service._COVERAGE_MODES)}.")
    user_tenants = get_user_tenants(current_user, db)
    if not user_tenants:
        raise HTTPException(status_code=404, detail="asset not found")
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
                    f"asset. Add a credential profile, or re-run with allow_uncredentialed=true."),
        )

    chosen = routing.get("selected_find")
    if coverage in ("nessus", "openvas"):  # CONTRACT C force pins the internal scanner
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
