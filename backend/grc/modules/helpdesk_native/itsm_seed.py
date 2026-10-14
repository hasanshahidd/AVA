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
    HDDepartment,
    HDServiceLevelAgreement,
    HDTicket,
    HDTicketPriority,
    HDTicketStatus,
    HDTicketTemplate,
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

# §A1 — same mechanism for grc_hd_ticket_template (create_all can't add the new
# request-library columns to an existing table). Plain columns; the department_id
# FK constraint is omitted (SQLAlchemy's relationship works off the column, and
# the live grc_hd_ticket ALTERs add no FK either). ponytail: add the FK in a real
# migration only if referential enforcement is ever needed here.
_TEMPLATE_ALTER_COLUMNS = [
    ("department_id", "INTEGER"),
    ("process", "VARCHAR(20) DEFAULT 'incident'"),
    ("default_subject", "VARCHAR(255)"),
    ("default_description", "TEXT"),
    ("default_category", "VARCHAR(100)"),
    ("default_subcategory", "VARCHAR(100)"),
    ("default_impact", "VARCHAR(10)"),
    ("default_urgency", "VARCHAR(10)"),
    ("icon", "VARCHAR(40)"),
    ("enabled", "BOOLEAN DEFAULT true"),
]

# §A2 — the 5 standard departments the request library is organized by.
_DEPARTMENTS = ["IT", "Sales", "Finance", "HR", "Facilities"]

# §A2 — the predefined request/problem library, by department. Each entry:
# (title, process, default_category, default_impact, default_urgency, icon, description).
# title == template_name == default_subject; description == default_description.
_REQUEST_TEMPLATES = {
    "IT": [
        ("My PC is slow", "incident", None, "medium", "medium", "gauge",
         "My computer has become slow or unresponsive."),
        ("Password reset / can't log in", "service_request", "Access/Account", None, None, "key-round",
         "I need my password reset or I'm unable to log in."),
        ("Email not working", "incident", None, None, None, "mail",
         "I'm having trouble sending or receiving email."),
        ("VPN won't connect", "incident", None, None, None, "shield",
         "I can't connect to the VPN."),
        ("Request a new laptop", "service_request", "Hardware", None, None, "laptop",
         "I'd like to request a new laptop."),
        ("Install software", "service_request", "Software", None, None, "download",
         "Please install software on my machine."),
        ("Printer not working", "incident", None, None, None, "printer",
         "The printer isn't working."),
        ("Request system access", "service_request", "Access/Account", None, None, "user-plus",
         "I need access to a system or application."),
    ],
    "Sales": [
        ("CRM is down / slow", "incident", None, "high", "high", "trending-down",
         "The CRM is down or running slowly."),
        ("Can't access CRM", "incident", "Access/Account", None, None, "lock",
         "I'm unable to access the CRM."),
        ("New rep needs CRM access", "service_request", None, None, None, "user-plus",
         "A new sales rep needs CRM access."),
        ("Laptop issue", "incident", None, None, None, "laptop",
         "I'm having a problem with my laptop."),
    ],
    "Finance": [
        ("Expense reimbursement", "service_request", "Expense", None, None, "receipt",
         "I'd like to submit an expense for reimbursement."),
        ("Procurement request", "service_request", "Procurement", None, None, "shopping-cart",
         "I need to request a purchase."),
        ("Accounting software error", "incident", None, None, None, "calculator",
         "The accounting software is showing an error."),
        ("Invoice / payment issue", "incident", None, None, None, "file-text",
         "There's a problem with an invoice or payment."),
    ],
    "HR": [
        ("New employee onboarding", "service_request", "Onboarding", None, None, "user-plus",
         "Please onboard a new employee."),
        ("Payroll issue", "incident", "Payroll", None, None, "banknote",
         "There's an issue with my payroll."),
        ("Leave-system access", "service_request", None, None, None, "calendar",
         "I need access to the leave system."),
        ("Update personal info", "service_request", None, None, None, "user-cog",
         "I'd like to update my personal information."),
    ],
    "Facilities": [
        ("Office AC / heating issue", "incident", None, None, None, "thermometer",
         "The office AC or heating isn't working properly."),
        ("Broken equipment", "incident", "Equipment", None, None, "wrench",
         "A piece of office equipment is broken."),
        ("Desk / office move", "service_request", "Office", None, None, "move",
         "I need to request a desk or office move."),
        ("Meeting room booking issue", "service_request", None, None, None, "calendar-clock",
         "There's a problem with a meeting room booking."),
    ],
}

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
def _alter_add_columns(db: Session, table: str, cols: list) -> int:
    """ALTER-add each column; IF NOT EXISTS makes it a no-op when present, and
    per-column try/except keeps one failure from aborting the rest."""
    added = 0
    for name, ddl in cols:
        try:
            db.execute(text(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {name} {ddl}"))
            db.commit()
            added += 1
        except Exception:  # noqa: BLE001 — a pre-existing/variant column is non-fatal
            db.rollback()
            logger.warning("itsm_seed: ALTER for %s.%s skipped", table, name, exc_info=True)
    return added


def _add_columns(db: Session) -> int:
    """§3.1 + §A1 — migrate the HDTicket extension columns AND the new
    HDTicketTemplate request-library columns onto existing tenant tables."""
    return (_alter_add_columns(db, "grc_hd_ticket", _ALTER_COLUMNS)
            + _alter_add_columns(db, "grc_hd_ticket_template", _TEMPLATE_ALTER_COLUMNS))


def _ensure_departments(db: Session, tid: int) -> dict:
    """§A2 — ensure the 5 standard departments exist (enabled); return {name: id}."""
    out: dict = {}
    for name in _DEPARTMENTS:
        d = (db.query(HDDepartment)
             .filter(HDDepartment.tenant_id == tid, HDDepartment.name == name)
             .first())
        if not d:
            d = HDDepartment(tenant_id=tid, name=name, enabled=True)
            db.add(d)
            db.flush()
        out[name] = d.id
    db.commit()
    return out


def seed_request_templates(db: Session, tid: int) -> int:
    """§A2 — seed the department-wise request library. Idempotent: skip a template
    whose template_name + department already exists. Returns the count created."""
    dept_ids = {d.name: d.id for d in
                db.query(HDDepartment).filter(HDDepartment.tenant_id == tid).all()}
    created = 0
    for dept_name, entries in _REQUEST_TEMPLATES.items():
        did = dept_ids.get(dept_name)
        for title, process, category, impact, urgency, icon, desc in entries:
            exists = (db.query(HDTicketTemplate)
                      .filter(HDTicketTemplate.tenant_id == tid,
                              HDTicketTemplate.template_name == title,
                              HDTicketTemplate.department_id == did)
                      .first())
            if exists:
                continue
            db.add(HDTicketTemplate(
                tenant_id=tid, template_name=title, department_id=did,
                process=process, default_subject=title, default_description=desc,
                default_category=category, default_impact=impact,
                default_urgency=urgency, icon=icon, enabled=True,
            ))
            created += 1
    db.commit()
    return created


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
    depts = _ensure_departments(db, tid)
    templates_created = seed_request_templates(db, tid)
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
        "departments": list(depts),
        "templates_created": templates_created,
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

    # §A2 request library: 5 depts, 24 templates, valid process/impact/urgency,
    # unique template_names (template_name is unique per tenant).
    assert set(_REQUEST_TEMPLATES) == set(_DEPARTMENTS), _REQUEST_TEMPLATES.keys()
    _procs = {"incident", "problem", "change", "service_request", "question"}
    _levels = {None, "low", "medium", "high"}
    all_titles = []
    for entries in _REQUEST_TEMPLATES.values():
        for title, process, category, impact, urgency, icon, desc in entries:
            assert process in _procs, process
            assert impact in _levels and urgency in _levels, (title, impact, urgency)
            assert title and icon and desc, title
            all_titles.append(title)
    assert len(all_titles) == 24, len(all_titles)
    assert len(all_titles) == len(set(all_titles)), "duplicate template_name"

    print("itsm_seed self-check ok")
