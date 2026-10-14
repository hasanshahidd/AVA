"""ITSM seeder (spec §3) — idempotent, safe to re-run.

Makes the ITIL-lite surface usable on an existing tenant DB: ALTER-adds the §1
HDTicket extension columns (create_all can't add columns to an existing table),
ensures the priorities / statuses / per-process ticket types the dropdowns need,
creates the four per-process SLAs via the existing `sla.create_sla` validator,
and backfills `process` on existing tickets from their ticket type.

All DB work is gated behind `seed_itsm` / the endpoint; the `__main__` self-check
is pure (matrix + SLA target table) and needs no DB.
"""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from ...models import (
    HDServiceLevelAgreement,
    HDTicket,
    HDTicketPriority,
    HDTicketStatus,
    HDTicketType,
    get_db,
)
from . import sla
from .common import require_edit, tenant_id

logger = logging.getLogger(__name__)

# ─── seed data (spec §3) ─────────────────────────────────────────────────────
# §3.1 — one ALTER per §1 column (Postgres ADD COLUMN IF NOT EXISTS → idempotent).
_ALTER_COLUMNS = [
    ("process", "VARCHAR(20) NOT NULL DEFAULT 'incident'"),
    ("impact", "VARCHAR(10)"),
    ("urgency", "VARCHAR(10)"),
    ("change_type", "VARCHAR(20)"),
    ("change_risk", "VARCHAR(10)"),
    ("planned_start", "TIMESTAMP"),
    ("planned_end", "TIMESTAMP"),
    ("implementation_plan", "TEXT"),
    ("backout_plan", "TEXT"),
    ("approval_state", "VARCHAR(20)"),
    ("approved_by", "VARCHAR(255)"),
    ("approved_at", "TIMESTAMP"),
    ("root_cause", "TEXT"),
    ("workaround", "TEXT"),
    ("known_error", "BOOLEAN DEFAULT false"),
    ("problem_resolution", "TEXT"),
    ("linked_incident_ids", "TEXT"),
    ("request_category", "VARCHAR(100)"),
    ("request_subcategory", "VARCHAR(100)"),
]

# §3.2 priorities (name == level) and §3.3 statuses (label, category).
_PRIORITIES = ["Urgent", "High", "Medium", "Low"]
_STATUSES = [("Open", "Open"), ("Replied", "Open"),
             ("Resolved", "Resolved"), ("Closed", "Resolved")]

# §3.4 one ticket type per process label (name, process) — default priority Medium.
_TICKET_TYPES = ["Incident", "Problem", "Change", "Service Request", "Question"]

# §3.5 service catalog — category → subcategories. Served by service_request.py
# (Agent B) via GET /helpdesk/service-catalog; a constant, no new table.
SERVICE_CATALOG = {
    "IT": ["Hardware", "Software", "Network", "Access/Account", "Email"],
    "Facilities": ["Office", "Equipment"],
    "HR": ["Onboarding", "Payroll"],
    "Finance": ["Expense", "Procurement"],
}

# §3.6 per-process SLAs: (service_level, condition, {level: (response_s, resolution_s)}).
# Business-hours seconds; resolution ≥ response; Default priority per SLA = Medium.
_SLA_DEFS = [
    ("Incident SLA", "doc.process == 'incident'", {
        "Urgent": (3600, 14400), "High": (7200, 28800),
        "Medium": (14400, 86400), "Low": (28800, 172800)}),
    ("Service Request SLA", "doc.process == 'service_request'", {
        "Urgent": (14400, 28800), "High": (14400, 57600),
        "Medium": (28800, 144000), "Low": (28800, 288000)}),
    ("Change SLA", "doc.process == 'change'", {
        "Urgent": (14400, 86400), "High": (28800, 259200),
        "Medium": (28800, 432000), "Low": (28800, 864000)}),
    ("Problem SLA", "doc.process == 'problem'", {
        "Urgent": (28800, 259200), "High": (28800, 432000),
        "Medium": (28800, 864000), "Low": (28800, 1728000)}),
]

_SERVICE_DAYS = [{"workday": d, "start_time": "09:00:00", "end_time": "17:00:00"}
                 for d in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]]

# §3 backfill: existing tickets → process from ticket_type.name; else incident.
_TYPE_TO_PROCESS = {"Change": "change", "Problem": "problem",
                    "Service Request": "service_request"}


# ─── steps ────────────────────────────────────────────────────────────────────
def _add_columns(db: Session) -> int:
    """§3.1 — ALTER-add each extension column; IF NOT EXISTS makes it a no-op when
    present, and per-column try/except keeps one failure from aborting the rest."""
    added = 0
    for name, ddl in _ALTER_COLUMNS:
        try:
            db.execute(text(f"ALTER TABLE grc_hd_ticket ADD COLUMN IF NOT EXISTS {name} {ddl}"))
            db.commit()
            added += 1
        except Exception:  # noqa: BLE001 — a pre-existing/variant column is non-fatal
            db.rollback()
            logger.warning("itsm_seed: ALTER for column %s skipped", name, exc_info=True)
    return added


def _ensure_priorities(db: Session, tid: int) -> dict:
    """§3.2 — ensure Urgent/High/Medium/Low; return {name: id}."""
    out: dict = {}
    for name in _PRIORITIES:
        p = (db.query(HDTicketPriority)
             .filter(HDTicketPriority.tenant_id == tid, HDTicketPriority.name == name)
             .first())
        if not p:
            p = HDTicketPriority(tenant_id=tid, name=name, level=name)
            db.add(p)
            db.flush()
        out[name] = p.id
    db.commit()
    return out


def _ensure_statuses(db: Session, tid: int) -> None:
    """§3.3 — ensure the four lifecycle statuses (by label_agent)."""
    for label, category in _STATUSES:
        exists = (db.query(HDTicketStatus)
                  .filter(HDTicketStatus.tenant_id == tid,
                          HDTicketStatus.label_agent == label)
                  .first())
        if not exists:
            db.add(HDTicketStatus(tenant_id=tid, label_agent=label, category=category))
    db.commit()


def _ensure_ticket_types(db: Session, tid: int, medium_priority_id) -> None:
    """§3.4 — one ticket type per process label, default priority Medium."""
    for name in _TICKET_TYPES:
        exists = (db.query(HDTicketType)
                  .filter(HDTicketType.tenant_id == tid, HDTicketType.name == name)
                  .first())
        if not exists:
            db.add(HDTicketType(tenant_id=tid, name=name, priority_id=medium_priority_id))
    db.commit()


def _ensure_slas(db: Session, tid: int, pri_ids: dict) -> list:
    """§3.6 — create each per-process SLA via sla.create_sla (so validation +
    default-priority resolution run); skip when the service_level already exists."""
    created = []
    for service_level, condition, targets in _SLA_DEFS:
        exists = (db.query(HDServiceLevelAgreement)
                  .filter(HDServiceLevelAgreement.tenant_id == tid,
                          HDServiceLevelAgreement.service_level == service_level)
                  .first())
        if exists:
            continue
        priorities = [
            {
                "priority_id": pri_ids[level],
                "default_priority": level == "Medium",
                "response_time": resp,
                "resolution_time": reso,
            }
            for level, (resp, reso) in targets.items()
        ]
        sla.create_sla(db, tid, {
            "service_level": service_level,
            "condition": condition,
            "enabled": True,
            "default_sla": False,
            "apply_sla_for_resolution": True,
            "priorities": priorities,
            "service_days": _SERVICE_DAYS,
        })
        created.append(service_level)
    return created


def backfill_process(db: Session, tid: int) -> dict:
    """§3 — set `process` on existing tickets from ticket_type.name
    (Change→change, Problem→problem, Service Request→service_request, else
    incident). Idempotent: re-running only touches rows whose value differs."""
    updated = 0
    for t in db.query(HDTicket).filter(HDTicket.tenant_id == tid).all():
        tname = t.ticket_type.name if t.ticket_type else None
        proc = _TYPE_TO_PROCESS.get(tname, "incident")
        if t.process != proc:
            t.process = proc
            updated += 1
    db.commit()
    return {"updated": updated}


def seed_itsm(db: Session, tid: int) -> dict:
    """§3 — idempotent ITSM seed. Order matters: columns exist before backfill,
    priorities exist before the SLAs reference them."""
    columns = _add_columns(db)
    pri_ids = _ensure_priorities(db, tid)
    _ensure_statuses(db, tid)
    _ensure_ticket_types(db, tid, pri_ids.get("Medium"))
    slas_created = _ensure_slas(db, tid, pri_ids)
    backfill = backfill_process(db, tid)
    return {
        "ok": True,
        "columns_processed": columns,
        "priorities": list(pri_ids),
        "statuses": [s[0] for s in _STATUSES],
        "ticket_types": list(_TICKET_TYPES),
        "service_catalog": list(SERVICE_CATALOG),
        "slas": [d[0] for d in _SLA_DEFS],
        "slas_created": slas_created,
        "backfilled": backfill["updated"],
    }


# ─── endpoint (Agent B mounts this router alongside the others) ──────────────
router = APIRouter(prefix="/helpdesk", tags=["Help Desk ITSM"])


@router.post("/itsm/seed")
def _seed_itsm_ep(db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return seed_itsm(db, tenant_id(db))


if __name__ == "__main__":
    # Pure self-check — the matrix (§4) + the SLA target table (§3.6). No DB.
    from .tickets import priority_name_from_matrix as pm

    assert pm("high", "high") == "Urgent"
    assert pm("high", "medium") == "High"
    assert pm("high", "low") == "Medium"
    assert pm("medium", "high") == "High"
    assert pm("medium", "medium") == "Medium"
    assert pm("medium", "low") == "Low"
    assert pm("low", "high") == "Medium"
    assert pm("low", "medium") == "Low"
    assert pm("low", "low") == "Low"
    assert pm("bogus", "low") is None and pm(None, None) is None

    assert [d[0] for d in _SLA_DEFS] == [
        "Incident SLA", "Service Request SLA", "Change SLA", "Problem SLA"]
    for name, cond, targets in _SLA_DEFS:
        assert cond.startswith("doc.process =="), cond
        assert set(targets) == set(_PRIORITIES), name
        for level, (resp, reso) in targets.items():
            assert resp > 0 and reso >= resp, (name, level)

    print("itsm_seed self-check ok")
