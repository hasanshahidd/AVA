"""Synchronous sync execution (shared by the Celery task and the
inline-fallback path in the router).

The dispatcher decides which adapter method to call based on
`connection.category`:

  * ticketing  → push queued vulns/exceptions + pull statuses on known external_ids
  * siem       → fetch_events since last_sync_at → enrich vulns
  * pentest    → fetch_exploits since last_sync_at → boost vuln priority
  * collab     → light health probe (active sends are on-demand)
  * transcribe → fetch_transcripts → create CommitteeMeetingMinutes rows

This module owns the dispatch + result persistence; the actual data
fan-out (vuln/exception lookup, exploitation enrichment, meeting minute
creation) is delegated to small helpers below so each category stays
testable in isolation.
"""
from __future__ import annotations

import logging
import os
from datetime import datetime
from typing import Any, Dict, List

from sqlalchemy.orm import Session

from ...models import IntegrationConnection, SyncHistory
from ...services.connector_credentials import (
    decrypt_credentials,
    encrypt_credentials,
)
from .base import (
    CollabAdapter,
    PenTestAdapter,
    SiemAdapter,
    SyncResult,
    TicketingAdapter,
    TranscribeAdapter,
)
from .registry import build_adapter

logger = logging.getLogger(__name__)


def run_inline_sync(conn: IntegrationConnection, db: Session) -> Dict[str, Any]:
    """Entry point shared with the Celery task. Returns a serialisable dict."""
    started = datetime.utcnow()
    history = SyncHistory(
        tenant_id=conn.tenant_id,
        connection_id=conn.id,
        sync_type="manual",
        started_at=started,
        status="running",
    )
    db.add(history)
    db.commit()
    db.refresh(history)

    try:
        creds = decrypt_credentials(conn.encrypted_credentials) or {}
        tokens = decrypt_credentials(conn.oauth_tokens) or {}
        adapter = build_adapter(
            provider=conn.integration_type,
            console_url=conn.console_url,
            credentials=creds,
            config=conn.provider_config or {},
            oauth_tokens=tokens,
        )

        result = _dispatch_sync(adapter, conn, db)

        # Adapter may have refreshed OAuth tokens during the sync — persist.
        if adapter.oauth_tokens and adapter.oauth_tokens != tokens:
            conn.oauth_tokens = encrypt_credentials(adapter.oauth_tokens)

        conn.last_sync_at = datetime.utcnow()
        conn.last_sync_status = "success" if result.success else (
            "partial" if (result.items_pulled + result.items_pushed + result.items_updated) else "failed"
        )
        conn.last_sync_stats = {
            "pushed": result.items_pushed,
            "pulled": result.items_pulled,
            "updated": result.items_updated,
            "closed": result.items_closed,
            "errors": result.errors[:10],
        }
        conn.consecutive_failures = 0 if result.success else (conn.consecutive_failures or 0) + 1
        conn.status = "connected" if result.success else "error"

        completed = datetime.utcnow()
        history.completed_at = completed
        history.duration_ms = int((completed - started).total_seconds() * 1000)
        history.status = conn.last_sync_status
        history.errors_count = len(result.errors)
        history.error_details = {"errors": result.errors[:25]} if result.errors else None
        history.sync_metadata = result.details
        db.commit()

        return {
            "success": result.success,
            "stats": conn.last_sync_stats,
            "errors": result.errors[:10],
        }
    except Exception as exc:
        logger.exception("Connector sync failed for %s", conn.id)
        conn.last_sync_status = "failed"
        conn.consecutive_failures = (conn.consecutive_failures or 0) + 1
        conn.status = "error"
        history.completed_at = datetime.utcnow()
        history.status = "failed"
        history.errors_count = 1
        history.error_details = {"errors": [str(exc)]}
        db.commit()
        return {"success": False, "errors": [str(exc)]}


def _dispatch_sync(adapter, conn: IntegrationConnection, db: Session) -> SyncResult:
    """Route to the right adapter call based on category."""
    cat = (conn.category or "").lower()

    if cat == "ticketing":
        return _sync_ticketing(adapter, conn, db)
    if cat == "siem":
        return adapter.run_sync(since=conn.last_sync_at)
    if cat == "pentest":
        return adapter.run_sync(since=conn.last_sync_at)
    if cat == "collab":
        return adapter.run_sync()
    if cat == "transcribe":
        result = adapter.run_sync(since=conn.last_sync_at)
        _persist_transcripts(result, conn, db)
        return result
    # Unknown category — run the health probe equivalent.
    return adapter.run_sync() if hasattr(adapter, "run_sync") else SyncResult(success=False, errors=[f"Unknown category {cat}"])


# ─── Ticketing fan-out ──────────────────────────────────────────────

def _auto_cfg(conn: IntegrationConnection) -> Dict[str, Any]:
    """Auto-ticket settings. Platform env wins (the Help Desk engine is operator-
    managed, never customer-configured); per-connection config is the override."""
    cfg = conn.provider_config or {}
    env_on = (os.getenv("HELPDESK_AUTO_TICKET") or "").strip().lower()
    enabled = (env_on in ("1", "true", "yes")) if env_on else bool(cfg.get("auto_ticket", False))
    sevs_env = (os.getenv("HELPDESK_AUTO_SEVERITIES") or "").strip()
    sevs = ([s.strip().lower() for s in sevs_env.split(",") if s.strip()] if sevs_env
            else [str(s).lower() for s in (cfg.get("auto_severities") or ["critical"])])
    try:
        limit = int(os.getenv("HELPDESK_AUTO_LIMIT") or cfg.get("auto_limit", 25))
    except (TypeError, ValueError):
        limit = 25
    return {"enabled": enabled, "severities": sevs, "limit": max(1, limit)}


def _ticketing_status_sync(conn: IntegrationConnection, db: Session) -> SyncResult:
    """Pull ticket statuses back and advance remediation plans (resolved-only)."""
    from ...services import itsm_service
    result = SyncResult(success=True)
    try:
        counts = itsm_service.sync_ticket_statuses(db, conn)
        db.commit()
        if isinstance(counts, dict):
            result.items_updated = int(counts.get("synced") or 0)
            result.details.update(counts)
    except Exception as exc:  # noqa: BLE001 — a status pull must never fail the run
        db.rollback()
        logger.exception("helpdesk status sync failed")
        result.errors.append(f"status sync: {exc}")
        result.success = False
    return result


def _sync_ticketing(adapter: TicketingAdapter, conn: IntegrationConnection, db: Session) -> SyncResult:
    """Auto-create tickets for qualifying findings, then pull statuses back.

    Routes every creation through `itsm_service.push_finding()` — the SAME path
    the manual "Create Help Desk ticket" button uses — so auto-created tickets
    land in `VulnTicketLink` (what the Help Desk actually reads), get a
    remediation plan, and are idempotent per (finding, connection).

    This replaces an earlier implementation that was broken in three ways: it
    wrote ticket ids into `Vulnerability.template_fields` (a store the Help Desk
    never reads, so auto-created tickets were invisible), it created no
    remediation plan, and its PolicyException branch raised AttributeError
    (`metadata_info` does not exist on that model) which failed the whole run.
    The exception branch is dropped — it never worked, and a policy exception is
    not a remediation task.

    Selection is SEVERITY-based, not CVSS-based: AI-pentest findings frequently
    carry a NULL cvss_score, so a CVSS threshold silently skipped most of them.
    Opt-in by design (`enabled` defaults False) so enabling it is a deliberate act.
    """
    from ...models import Vulnerability, VulnTicketLink
    from ...services import itsm_service

    cfg = _auto_cfg(conn)
    if not cfg["enabled"]:
        return _ticketing_status_sync(conn, db)

    OPEN_STATES = ("open", "in_progress", "reopened")
    linked = {
        l.vulnerability_id
        for l in db.query(VulnTicketLink).filter(
            VulnTicketLink.connection_id == conn.id,
            VulnTicketLink.resolved_at.is_(None),
        ).all()
    }
    candidates = (
        db.query(Vulnerability)
        .filter(
            Vulnerability.tenant_id == conn.tenant_id,
            Vulnerability.severity.in_(cfg["severities"]),
        )
        .order_by(Vulnerability.id.desc())
        .all()
    )
    todo = [v for v in candidates
            if v.id not in linked and (v.status or "open") in OPEN_STATES][:cfg["limit"]]

    result = SyncResult(success=True)
    for v in todo:
        try:
            r = itsm_service.push_finding(db, v, conn, user_id=None)
            db.commit()
            if r.get("error"):
                result.errors.append(f"{v.vuln_id}: {r['error']}")
            else:
                result.items_pushed += 1
        except Exception as exc:  # noqa: BLE001 — one bad finding must not kill the run
            db.rollback()
            logger.exception("auto-ticket failed for vuln_id=%s", v.id)
            result.errors.append(f"{v.vuln_id}: {exc}")

    status = _ticketing_status_sync(conn, db)
    result.items_updated = status.items_updated
    result.details.update(status.details)
    result.errors.extend(status.errors)
    result.details["auto"] = {"severities": cfg["severities"], "limit": cfg["limit"],
                              "considered": len(todo)}
    result.success = not result.errors
    return result


# ─── Transcript fan-out ─────────────────────────────────────────────

def _persist_transcripts(result: SyncResult, conn: IntegrationConnection, db: Session) -> None:
    """Best-effort persistence of pulled transcripts as committee meeting
    minutes. The transcript-to-committee mapping needs explicit pairing
    (calendar invite → committee), which is configured via
    `provider_config['committee_id']`. If that's not set we leave the
    transcripts as raw artefacts on the SyncHistory row.
    """
    try:
        from ...models import CommitteeMeeting, GovernanceCommittee
    except Exception:
        return

    committee_id = (conn.provider_config or {}).get("committee_id")
    if not committee_id:
        return
    committee = db.query(GovernanceCommittee).filter(
        GovernanceCommittee.id == committee_id,
        GovernanceCommittee.tenant_id == conn.tenant_id,
    ).first()
    if not committee:
        return

    summaries = result.details.get("transcripts") or []
    for s in summaries:
        started_iso = s.get("started_at")
        try:
            started_at = datetime.fromisoformat((started_iso or "").replace("Z", "+00:00"))
        except Exception:
            started_at = datetime.utcnow()
        existing = db.query(CommitteeMeeting).filter(
            CommitteeMeeting.tenant_id == conn.tenant_id,
            CommitteeMeeting.committee_id == committee.id,
            CommitteeMeeting.title == s.get("title"),
            CommitteeMeeting.scheduled_at == started_at,
        ).first()
        if existing:
            continue
        try:
            meeting = CommitteeMeeting(
                tenant_id=conn.tenant_id,
                committee_id=committee.id,
                title=s.get("title") or "(Imported meeting)",
                scheduled_at=started_at,
                duration_minutes=s.get("duration"),
                status="completed",
                source=f"transcribe:{conn.integration_type}",
            )
            db.add(meeting)
        except Exception:
            logger.exception("Failed to create CommitteeMeeting from transcript")

    try:
        db.commit()
    except Exception:
        logger.exception("Failed to commit transcript-derived meetings")
        db.rollback()
