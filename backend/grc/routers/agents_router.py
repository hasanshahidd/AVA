"""Compliance Agent fleet API — the backend the /admin/agents page calls.

Two audiences:
  * USER-facing (require_auth): enroll / list / revoke / bulk-enroll — the console.
  * AGENT-facing (token auth, NO user session): the installed agent on a customer
    device calls enroll → gets a long-lived api_token → then report / heartbeat.

The agent runs the up-front discovery + inventory collection LOCALLY on the host
(for machines we can't reach over the network or where the client won't share
credentials) and POSTs the result here; we land it on the asset the same way the
agentless path does (ITAsset + platform_properties), so both converge on one
record. (CIS/compliance execution by the agent is Phase 2.)

Token model: a short-lived ENROLLMENT token (one install) is exchanged for a
long-lived API token. Only SHA-256 hashes are stored; plaintext is returned once.
"""
from __future__ import annotations

import hashlib
import secrets
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

import os

from fastapi import APIRouter, Depends, Header, HTTPException, Request
from fastapi.responses import FileResponse, PlainTextResponse
from pydantic import BaseModel
from sqlalchemy.orm import Session

from grc.models import get_db, ITAsset
from grc.models._37_artifact_catalog_tenant_artifacts import ComplianceAgent
from grc.routers.auth_router import get_user_primary_tenant, require_auth, GRCUser

router = APIRouter(prefix="/agents", tags=["Compliance Agents"])

# A heartbeat older than this flips an active agent to "stale" — computed
# server-side (the old UI only derived it in the browser, so nothing authoritative
# ever marked an agent stale).
STALE_AFTER = timedelta(minutes=10)
ENROLLMENT_TTL = timedelta(hours=24)


def _hash(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def _effective_status(a: ComplianceAgent, now: datetime) -> str:
    """Authoritative status: revoked/pending as stored; active decays to stale
    when the heartbeat goes quiet."""
    if a.status in ("revoked", "pending"):
        return a.status
    if a.last_heartbeat_at and (now - a.last_heartbeat_at) > STALE_AFTER:
        return "stale"
    return a.status or "active"


def _agent_dict(a: ComplianceAgent, now: datetime) -> Dict[str, Any]:
    return {
        "id": a.id, "agent_name": a.agent_name, "mode": a.mode,
        "os_family": a.os_family, "agent_version": a.agent_version,
        "hostname": a.hostname, "ip_address": a.ip_address,
        "status": _effective_status(a, now), "asset_id": a.asset_id,
        "last_heartbeat_at": a.last_heartbeat_at.isoformat() if a.last_heartbeat_at else None,
        "last_result_at": a.last_result_at.isoformat() if a.last_result_at else None,
        "enrolled_at": a.enrolled_at.isoformat() if a.enrolled_at else None,
        "created_at": a.created_at.isoformat() if a.created_at else None,
    }


def _install_hint(enrollment_token: str, os_family: Optional[str]) -> Dict[str, str]:
    """One-liners the console shows next to a fresh enrollment token. The real
    binary is served from /agents/installer/* (wired when the agent ships); the
    token is what matters for the handshake."""
    return {
        "linux": f"curl -fsSL $AVA_URL/grc/agents/installer/linux | sudo AVA_ENROLL={enrollment_token} sh",
        "windows": f"iwr $AVA_URL/grc/agents/installer/windows -UseB | iex   # AVA_ENROLL={enrollment_token}",
    }


# ── USER-facing (console) ──────────────────────────────────────────────────
class EnrollIn(BaseModel):
    agent_name: str
    mode: Optional[str] = "collector"
    asset_id: Optional[int] = None
    os_family: Optional[str] = None


class BulkHost(BaseModel):
    hostname: str
    mode: Optional[str] = "collector"
    os_family: Optional[str] = None
    asset_id: Optional[int] = None


class BulkEnrollIn(BaseModel):
    hosts: List[BulkHost]
    backend_url: Optional[str] = None


def _new_agent(db: Session, tenant_id: int, *, name: str, mode: str,
               os_family: Optional[str], asset_id: Optional[int],
               user_id: Optional[int], hostname: Optional[str] = None) -> tuple[ComplianceAgent, str]:
    now = datetime.utcnow()
    enr = "enr_" + secrets.token_urlsafe(32)
    agent = ComplianceAgent(
        tenant_id=tenant_id, agent_name=name, mode=(mode or "collector"),
        os_family=os_family, asset_id=asset_id, hostname=hostname,
        status="pending", kind="single",
        enrollment_token_hash=_hash(enr), enrollment_max_uses=1, enrollment_uses=0,
        enrollment_expires_at=now + ENROLLMENT_TTL,
        created_by_user_id=user_id, created_at=now, updated_at=now,
    )
    db.add(agent)
    return agent, enr


@router.get("")
def list_agents(current_user: GRCUser = Depends(require_auth), db: Session = Depends(get_db)):
    tenant_id = get_user_primary_tenant(current_user, db)
    now = datetime.utcnow()
    rows = (db.query(ComplianceAgent)
            .filter(ComplianceAgent.tenant_id == tenant_id)
            .order_by(ComplianceAgent.created_at.desc()).all())
    return {"items": [_agent_dict(a, now) for a in rows]}


@router.post("")
def enroll_agent(body: EnrollIn, current_user: GRCUser = Depends(require_auth),
                 db: Session = Depends(get_db)):
    if not body.agent_name.strip():
        raise HTTPException(422, "agent_name is required")
    tenant_id = get_user_primary_tenant(current_user, db)
    agent, enr = _new_agent(db, tenant_id, name=body.agent_name.strip(),
                            mode=body.mode or "collector", os_family=body.os_family,
                            asset_id=body.asset_id, user_id=current_user.id)
    db.commit(); db.refresh(agent)
    return {"id": agent.id, "agent_name": agent.agent_name, "status": agent.status,
            "enrollment_token": enr, "expires_in": int(ENROLLMENT_TTL.total_seconds()),
            "install": _install_hint(enr, body.os_family)}


@router.post("/bulk-enroll")
def bulk_enroll(body: BulkEnrollIn, current_user: GRCUser = Depends(require_auth),
                db: Session = Depends(get_db)):
    if not body.hosts:
        raise HTTPException(422, "hosts is empty")
    tenant_id = get_user_primary_tenant(current_user, db)
    out = []
    for h in body.hosts:
        agent, enr = _new_agent(db, tenant_id, name=h.hostname.strip() or "agent",
                                mode=h.mode or "collector", os_family=h.os_family,
                                asset_id=h.asset_id, user_id=current_user.id,
                                hostname=h.hostname.strip() or None)
        out.append({"hostname": h.hostname, "agent_id": agent.id, "enrollment_token": enr})
    db.commit()
    return {"count": len(out), "enrollments": out}


@router.post("/{agent_id}/revoke")
def revoke_agent(agent_id: int, reason: Optional[str] = None,
                 current_user: GRCUser = Depends(require_auth), db: Session = Depends(get_db)):
    tenant_id = get_user_primary_tenant(current_user, db)
    agent = (db.query(ComplianceAgent)
             .filter(ComplianceAgent.id == agent_id, ComplianceAgent.tenant_id == tenant_id).first())
    if not agent:
        raise HTTPException(404, "Agent not found")
    now = datetime.utcnow()
    agent.status = "revoked"
    agent.revoked_at = now
    agent.revoked_by_user_id = current_user.id
    agent.revoke_reason = reason
    agent.api_token_hash = None          # the agent can no longer report
    agent.enrollment_token_hash = None   # and the install link is dead
    agent.updated_at = now
    db.commit()
    return {"ok": True, "id": agent_id, "status": "revoked"}


# ── AGENT-facing (token auth, no user session) ──────────────────────────────
class AgentEnrollIn(BaseModel):
    enrollment_token: str
    hostname: Optional[str] = None
    os_family: Optional[str] = None
    agent_version: Optional[str] = None
    ip_address: Optional[str] = None


class ReportIn(BaseModel):
    hostname: Optional[str] = None
    os_name: Optional[str] = None
    os_family: Optional[str] = None
    ip_address: Optional[str] = None
    agent_version: Optional[str] = None
    software: Optional[List[Dict[str, Any]]] = None   # [{name, version, ...}]
    inventory: Optional[Dict[str, Any]] = None         # hardware/os/network block


def _agent_by_api_token(db: Session, authorization: Optional[str]) -> ComplianceAgent:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise HTTPException(401, "Missing bearer api_token")
    token = authorization.split(" ", 1)[1].strip()
    agent = (db.query(ComplianceAgent)
             .filter(ComplianceAgent.api_token_hash == _hash(token)).first())
    if not agent or agent.status == "revoked":
        raise HTTPException(401, "Invalid or revoked api_token")
    return agent


@router.post("/enroll")
def agent_enroll(body: AgentEnrollIn, db: Session = Depends(get_db)):
    """The installed agent exchanges its one-time enrollment token for a
    long-lived api_token. No user session — the enrollment token IS the auth."""
    agent = (db.query(ComplianceAgent)
             .filter(ComplianceAgent.enrollment_token_hash == _hash(body.enrollment_token)).first())
    if not agent or agent.status == "revoked":
        raise HTTPException(401, "Invalid or revoked enrollment token")
    now = datetime.utcnow()
    if agent.enrollment_expires_at and now > agent.enrollment_expires_at:
        raise HTTPException(401, "Enrollment token expired")
    if agent.enrollment_max_uses is not None and (agent.enrollment_uses or 0) >= agent.enrollment_max_uses:
        raise HTTPException(401, "Enrollment token already used")
    api_token = "aak_" + secrets.token_urlsafe(32)
    agent.api_token_hash = _hash(api_token)
    agent.status = "active"
    agent.enrolled_at = now
    agent.enrollment_uses = (agent.enrollment_uses or 0) + 1
    agent.enrollment_token_hash = None  # single-use: burn it
    agent.last_heartbeat_at = now
    if body.hostname:
        agent.hostname = body.hostname
    if body.os_family:
        agent.os_family = body.os_family
    if body.agent_version:
        agent.agent_version = body.agent_version
    if body.ip_address:
        agent.ip_address = body.ip_address
    agent.updated_at = now
    db.commit()
    return {"agent_id": agent.id, "api_token": api_token, "report_interval_s": 3600}


def _upsert_asset_from_report(db: Session, agent: ComplianceAgent, body: ReportIn, now: datetime) -> int:
    """Land the agent's locally-collected inventory on an ITAsset — additive,
    mirroring the agentless credentialed path (platform_properties + software).
    Matches the agent's linked asset, else by hostname within the tenant, else
    creates one. Returns the asset id."""
    asset: Optional[ITAsset] = None
    if agent.asset_id:
        asset = db.get(ITAsset, agent.asset_id)
    host = (body.hostname or agent.hostname or "").strip()
    if asset is None and host:
        asset = (db.query(ITAsset)
                 .filter(ITAsset.tenant_id == agent.tenant_id,
                         ITAsset.host_name == host).first())
    if asset is None:
        asset = ITAsset(
            tenant_id=agent.tenant_id, name=host or f"agent-{agent.id}",
            asset_type="infrastructure", host_name=host or None,
            ip_address=body.ip_address, origin_source="agent",
            source_system="agent", discovery_state="discovered",
            first_seen_at=now,
        )
        db.add(asset)
        db.flush()
    # Fill blanks only for curated identity; always refresh observed telemetry.
    if body.ip_address and not asset.ip_address:
        asset.ip_address = body.ip_address
    if body.os_family:
        asset.os_family = body.os_family
    pp = dict(asset.platform_properties or {})
    pp["agent"] = {
        "provenance": "agent", "agent_id": agent.id,
        "os_name": body.os_name, "os_family": body.os_family,
        "agent_version": body.agent_version, "reported_at": now.isoformat(),
        "inventory": body.inventory or {},
    }
    asset.platform_properties = pp
    if body.software:
        asset.detected_software_json = body.software
    asset.last_seen_at = now
    asset.last_seen_source = "agent"
    return asset.id


@router.post("/report")
def agent_report(body: ReportIn, authorization: Optional[str] = Header(default=None),
                 db: Session = Depends(get_db)):
    """The agent POSTs its locally-collected inventory. Authed by the api_token."""
    agent = _agent_by_api_token(db, authorization)
    now = datetime.utcnow()
    asset_id = _upsert_asset_from_report(db, agent, body, now)
    agent.asset_id = asset_id
    agent.last_result_at = now
    agent.last_heartbeat_at = now
    agent.status = "active"
    if body.hostname and not agent.hostname:
        agent.hostname = body.hostname
    if body.agent_version:
        agent.agent_version = body.agent_version
    agent.updated_at = now
    db.commit()
    return {"ok": True, "asset_id": asset_id}


@router.post("/heartbeat")
def agent_heartbeat(authorization: Optional[str] = Header(default=None),
                    db: Session = Depends(get_db)):
    agent = _agent_by_api_token(db, authorization)
    now = datetime.utcnow()
    agent.last_heartbeat_at = now
    if agent.status != "active":
        agent.status = "active"
    agent.updated_at = now
    db.commit()
    # Tell the agent whether a scan-now was requested from the console.
    return {"ok": True, "scan_now": bool(agent.pending_scan_at)}


# ── Installer download (the "Download agent" buttons) ───────────────────────
# Compiled binaries live outside git (built on the droplet), served from here.
AGENT_DIST = os.environ.get("AVA_AGENT_DIST", "/root/AVA/agent-dist")
_BIN = {"linux": "ava-agent-linux", "windows": "ava-agent-windows.exe"}


def _public_base(request: Request) -> str:
    """The cloud origin the agent reports to — the same host the operator
    downloaded from, via the reverse proxy's X-Forwarded-* (nginx terminates TLS)."""
    override = os.environ.get("CONNECT_WIZARD_PUBLIC_URL", "").strip().rstrip("/")
    if override:
        return override
    proto = request.headers.get("x-forwarded-proto") or request.url.scheme
    host = (request.headers.get("x-forwarded-host") or request.headers.get("host")
            or request.url.netloc).split(",")[0].strip()
    return f"{proto}://{host}"


@router.get("/installer/{os_family}/bin")
def download_agent_binary(os_family: str):
    """The raw compiled agent binary. No auth — the enrollment token (needed to
    actually report) is what gates access to the tenant's data."""
    name = _BIN.get(os_family)
    if not name:
        raise HTTPException(404, "Unknown OS")
    path = os.path.join(AGENT_DIST, name)
    if not os.path.exists(path):
        raise HTTPException(503, "Agent binary not built yet for this platform")
    return FileResponse(path, media_type="application/octet-stream", filename=name)


def _linux_installer(url: str, token: str) -> str:
    return f"""#!/bin/sh
# Ava Compliance Agent installer (Linux). Downloads the agent, installs it as a
# systemd service, enrolls, and sends the first inventory to the cloud.
set -e
AVA_URL="{url}"
AVA_ENROLL="{token}"
[ "$(id -u)" -eq 0 ] || {{ echo "Run as root (sudo)"; exit 1; }}
install -d /opt/ava-agent
echo "Downloading agent..."
curl -fsSL "$AVA_URL/grc/agents/installer/linux/bin" -o /opt/ava-agent/ava-agent
chmod +x /opt/ava-agent/ava-agent
cat > /etc/systemd/system/ava-agent.service <<UNIT
[Unit]
Description=Ava Compliance Agent
After=network-online.target
Wants=network-online.target
[Service]
Environment=AVA_URL=$AVA_URL
Environment=AVA_ENROLL=$AVA_ENROLL
ExecStart=/opt/ava-agent/ava-agent
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now ava-agent
echo "Ava agent installed and started. It will appear in your console shortly."
"""


def _windows_installer(url: str, token: str) -> str:
    return f"""# Ava Compliance Agent installer (Windows). Run in an elevated PowerShell.
$ErrorActionPreference = "Stop"
$AvaUrl = "{url}"
$AvaEnroll = "{token}"
$dir = "$env:ProgramData\\AvaAgent"
New-Item -ItemType Directory -Force -Path $dir | Out-Null
Write-Host "Downloading agent..."
Invoke-WebRequest "$AvaUrl/grc/agents/installer/windows/bin" -OutFile "$dir\\ava-agent.exe" -UseBasicParsing
[Environment]::SetEnvironmentVariable('AVA_URL', $AvaUrl, 'Machine')
[Environment]::SetEnvironmentVariable('AVA_ENROLL', $AvaEnroll, 'Machine')
# Run at startup as SYSTEM (a scheduled task; a full Windows service is a later hardening).
schtasks /Create /TN "AvaAgent" /TR "`"$dir\\ava-agent.exe`"" /SC ONSTART /RU SYSTEM /RL HIGHEST /F | Out-Null
$env:AVA_URL = $AvaUrl; $env:AVA_ENROLL = $AvaEnroll
Start-Process -FilePath "$dir\\ava-agent.exe" -WindowStyle Hidden
Write-Host "Ava agent installed and started. It will appear in your console shortly."
"""


@router.get("/installer/{os_family}/{enrollment_token}", response_class=PlainTextResponse)
def download_installer(os_family: str, enrollment_token: str, request: Request):
    """Personalised one-shot installer script with the tenant's enrollment token
    baked in. The token IS the auth (same model as the connect wizard), so this
    is intentionally not user-session gated."""
    url = _public_base(request)
    if os_family == "linux":
        return _linux_installer(url, enrollment_token)
    if os_family == "windows":
        return _windows_installer(url, enrollment_token)
    raise HTTPException(404, "Unknown OS")


if __name__ == "__main__":  # self-check — pure logic, no DB
    assert _hash("x") == _hash("x") and _hash("x") != _hash("y")
    assert len(_hash("anything")) == 64  # fits String(128)

    class _A:
        def __init__(self, status, hb):
            self.status = status; self.last_heartbeat_at = hb
    now = datetime.utcnow()
    assert _effective_status(_A("pending", None), now) == "pending"
    assert _effective_status(_A("revoked", now), now) == "revoked"
    assert _effective_status(_A("active", now), now) == "active"
    assert _effective_status(_A("active", now - timedelta(minutes=30)), now) == "stale"
    assert _effective_status(_A("active", now - timedelta(minutes=5)), now) == "active"

    lin = _linux_installer("https://app.caiva.io", "enr_abc")
    assert 'AVA_URL="https://app.caiva.io"' in lin and 'AVA_ENROLL="enr_abc"' in lin
    assert "/grc/agents/installer/linux/bin" in lin and "systemctl enable --now ava-agent" in lin
    win = _windows_installer("https://app.caiva.io", "enr_xyz")
    assert '$AvaEnroll = "enr_xyz"' in win and "ava-agent.exe" in win and "schtasks" in win
    assert _BIN["linux"] == "ava-agent-linux" and _BIN["windows"] == "ava-agent-windows.exe"
    print("agents_router self-check PASSED")
