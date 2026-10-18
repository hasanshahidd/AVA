"""Ticket core — the converted engine (logic spec §0, §3, §4; contract §A3–§A5,
§A12–§A15).

Faithful native port of the Frappe HD Ticket lifecycle the Help Desk UI drives:
list / detail (ticket + SLA block + merged conversation) / create / status /
reply / update / assign. SLA business-hours math and the assignment-rule
strategy are delegated to the `sla` / `assignment` modules (stubs for now).
"""
from __future__ import annotations

import json
import logging
from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from ...models import (
    HDTicket,
    HDTicketStatus,
    HDTicketPriority,
    HDPriorityMatrix,
    HDTicketType,
    Team,
    HDAgent,
    HDSettings,
    HDCommunication,
    HDTicketComment,
    HDTicketActivity,
    HDTicketFeedbackOption,
    GRCUser,
    get_db,
)
from ...routers.auth_router import require_auth
from . import sla, assignment
from .common import (
    iso, ticket_row, ticket_detail, tenant_id, require_edit,
    require_tickets_assign, require_tickets_delete,
)
from .audit import hd_audit

logger = logging.getLogger(__name__)

RESOLVED = "Resolved"
PAUSED = "Paused"
CLOSED_LABEL = "Closed"

# ─── ITSM process + priority matrix (spec §0, §1, §4) ────────────────────────
PROCESSES = {"incident", "problem", "change", "service_request", "question"}

# ITIL 4-level matrix: PRIORITY_MATRIX[impact][urgency] -> priority name (§4).
PRIORITY_MATRIX = {
    "high":   {"high": "Urgent", "medium": "High",   "low": "Medium"},
    "medium": {"high": "High",   "medium": "Medium", "low": "Low"},
    "low":    {"high": "Medium", "medium": "Low",    "low": "Low"},
}

# extension columns create/update accept (process handled separately — set-once).
_EXT_DATETIME = ("planned_start", "planned_end", "approved_at")
_EXT_FIELDS = (
    "impact", "urgency",
    "change_type", "change_risk", "planned_start", "planned_end",
    "implementation_plan", "backout_plan",
    "approval_state", "approved_by", "approved_at",
    "root_cause", "workaround", "known_error", "problem_resolution",
    "linked_incident_ids",
    "request_category", "request_subcategory",
)


def priority_name_from_matrix(impact: Optional[str], urgency: Optional[str]) -> Optional[str]:
    """Pure §4 lookup — priority *name* for an (impact, urgency) pair, or None."""
    return PRIORITY_MATRIX.get((impact or "").strip().lower(), {}).get(
        (urgency or "").strip().lower())


def priority_from_matrix(db: Session, tid: int, impact: Optional[str],
                         urgency: Optional[str]) -> Optional[int]:
    """§4. Resolve an (impact, urgency) pair to a tenant HDTicketPriority.id.

    Prefers the tenant's OWN ingested priority matrix (grc_hd_priority_matrix,
    seeded from the ITSM workbook) so the owner's authored impact x urgency grid
    is authoritative. Falls back to the built-in ITIL 4-level names only when the
    tenant has no matrix row for that cell (e.g. before the ITSM seed has run),
    so behaviour is unchanged on un-seeded tenants. Missing cell → None."""
    imp = (impact or "").strip().lower()
    urg = (urgency or "").strip().lower()
    if imp and urg:
        cell = (
            db.query(HDPriorityMatrix.priority_id)
            .filter(HDPriorityMatrix.tenant_id == tid,
                    func.lower(HDPriorityMatrix.impact) == imp,
                    func.lower(HDPriorityMatrix.urgency) == urg)
            .first()
        )
        if cell and cell[0]:
            return cell[0]
    # fallback: built-in matrix name -> tenant priority by name
    name = priority_name_from_matrix(impact, urgency)
    if not name:
        return None
    p = (
        db.query(HDTicketPriority)
        .filter(HDTicketPriority.tenant_id == tid, HDTicketPriority.name == name)
        .first()
    )
    return p.id if p else None


def _as_bool(v) -> bool:
    if isinstance(v, str):
        return v.strip().lower() in ("1", "true", "yes", "on")
    return bool(v)


def _as_dt(v) -> Optional[datetime]:
    if v in (None, ""):
        return None
    if isinstance(v, datetime):
        return v
    try:
        return datetime.fromisoformat(str(v).replace("Z", "+00:00"))
    except ValueError:
        return None


def _extension_kwargs(payload: dict) -> dict:
    """Pull + coerce the §1 extension fields present in `payload` (store what's
    sent — no per-process gating, spec §2)."""
    out: dict = {}
    for f in _EXT_FIELDS:
        if f not in payload:
            continue
        v = payload[f]
        if f == "known_error":
            out[f] = _as_bool(v)
        elif f == "linked_incident_ids":
            out[f] = json.dumps(v) if isinstance(v, (list, tuple)) else v
        elif f in _EXT_DATETIME:
            out[f] = _as_dt(v)
        else:
            out[f] = v
    return out


def _parse_linked_ids(v) -> list:
    if not v:
        return []
    try:
        d = json.loads(v)
        return d if isinstance(d, list) else []
    except (ValueError, TypeError):
        return []


def _process_fields(ticket: "HDTicket") -> dict:
    """process + all extension fields, serialized (dates → iso, ids → list) so
    every ticket shape carries them (FE picks the ones the process needs, §2)."""
    return {
        "process": ticket.process or "incident",
        "impact": ticket.impact,
        "urgency": ticket.urgency,
        "change_type": ticket.change_type,
        "change_risk": ticket.change_risk,
        "planned_start": iso(ticket.planned_start),
        "planned_end": iso(ticket.planned_end),
        "implementation_plan": ticket.implementation_plan,
        "backout_plan": ticket.backout_plan,
        "approval_state": ticket.approval_state,
        "approved_by": ticket.approved_by,
        "approved_at": iso(ticket.approved_at),
        "root_cause": ticket.root_cause,
        "workaround": ticket.workaround,
        "known_error": bool(ticket.known_error),
        "problem_resolution": ticket.problem_resolution,
        "linked_incident_ids": _parse_linked_ids(ticket.linked_incident_ids),
        "request_category": ticket.request_category,
        "request_subcategory": ticket.request_subcategory,
    }


def _notify(fn_name: str, db: Session, tid: int, ticket: "HDTicket", *args) -> None:
    """Fire an outbound-mail hook, swallowing any failure so a mail problem can
    never break the ticket operation. `mail` is imported lazily to avoid the
    mail<->tickets import cycle. Local-only: a no-op without a configured account."""
    try:
        from . import mail
        getattr(mail, fn_name)(db, tid, ticket, *args)
    except Exception:  # noqa: BLE001
        logger.warning("helpdesk.mail hook %s failed", fn_name, exc_info=True)

# delete is admin-grade (Frappe `is_admin()` gate) — mapped to AVA RBAC via the
# shared `require_tickets_delete` gate (helpdesk:tickets:delete). The Administrator
# role and the tenant primary contact pass automatically; any other role needs the
# permission granted explicitly, so "only administrators can delete tickets" holds
# unless a tenant deliberately delegates it.


# ─── lookups ───────────────────────────────────────────────────────────────
def _get_ticket(db: Session, tid: int, name: str) -> Optional[HDTicket]:
    """Tenant-scoped fetch by the contract `name` (= our integer PK as string)."""
    try:
        pk = int(name)
    except (TypeError, ValueError):
        return None
    return (
        db.query(HDTicket)
        .filter(HDTicket.id == pk, HDTicket.tenant_id == tid)
        .first()
    )


def _status_by_label(db: Session, tid: int, label: str) -> Optional[HDTicketStatus]:
    return (
        db.query(HDTicketStatus)
        .filter(HDTicketStatus.tenant_id == tid, HDTicketStatus.label_agent == label)
        .first()
    )


def _default_open_status(db: Session, tid: int) -> Optional[HDTicketStatus]:
    """Settings default is "Open" (spec §3.1/§5); fall back to any enabled
    Open-category status ordered by `order`."""
    s = _status_by_label(db, tid, "Open")
    if s:
        return s
    return (
        db.query(HDTicketStatus)
        .filter(
            HDTicketStatus.tenant_id == tid,
            HDTicketStatus.category == "Open",
            HDTicketStatus.enabled == True,  # noqa: E712
        )
        .order_by(HDTicketStatus.order.asc())
        .first()
    )


# ─── lifecycle (spec §3.1) ───────────────────────────────────────────────────
def is_valid_status_transition(old_status, new_status) -> bool:
    """§3.1 `is_valid_status_transition`: false for new/unchanged, and closing an
    already-Resolved-category ticket (Resolved→Closed) is NOT a valid transition
    — it wraps up an outcome, so resolution timestamps are preserved, not
    re-stamped. Gates SLA recompute + resolution stamping."""
    if new_status is None or old_status is None:
        return False
    if old_status.id == new_status.id:
        return False
    if old_status.category == RESOLVED and new_status.category == RESOLVED:
        return False
    return True


def _activity(db: Session, tid: int, ticket: HDTicket, action: str) -> None:
    """Append a change-log row (the native Version/Info-comment equivalent, §4.3)."""
    db.add(HDTicketActivity(tenant_id=tid, ticket_id=ticket.id, action=action))


def _apply_status_change(db: Session, tid: int, ticket: HDTicket, new_status: HDTicketStatus) -> None:
    """Set the status and run the hooks that flow from it (spec §1.4, §3.2)."""
    now = datetime.utcnow()
    old_status = ticket.status
    old_cat = ticket.status_category
    valid = is_valid_status_transition(old_status, new_status)

    # Status always changes at the data layer (§3.1); the gate only controls
    # SLA recompute + resolution stamping.
    ticket.status_id = new_status.id
    ticket.status_category = new_status.category

    if valid:
        # set_resolution_date (§1.4): leaving Resolved nulls it; entering Resolved
        # (and not already stamped, or category changed) stamps now.
        if new_status.category != RESOLVED:
            ticket.resolution_date = None
            ticket.resolution_time = None
        elif ticket.resolution_date is None or old_cat != RESOLVED:
            ticket.resolution_date = now
        # set_first_responded_on (§1.4): resolving/pausing records a first
        # response even without an explicit agent reply.
        if ticket.first_responded_on is None and new_status.category in (RESOLVED, PAUSED):
            ticket.first_responded_on = now
        sla.recompute(db, ticket, prev_status_category=old_cat)

    label = new_status.label_agent
    _activity(db, tid, ticket, f"changed status to {label}")

    # CSAT feedback email when the status reaches the configured feedback status
    # (handle_email_feedback). Fires on any real status change, including the
    # Resolved→Closed transition that is_valid_status_transition rejects, so it is
    # checked here rather than inside the `valid` block above.
    if old_status is None or old_status.id != new_status.id:
        try:
            from . import mail
            if mail.feedback_status_matches(db, tid, new_status):
                mail.notify_feedback(db, tid, ticket)
        except Exception:  # noqa: BLE001 — mail must never break the status change
            logger.warning("helpdesk.mail feedback hook failed", exc_info=True)


# ─── reads ───────────────────────────────────────────────────────────────────
def list_tickets(db: Session, tid: int, status: Optional[str] = None,
                 q: Optional[str] = None, process: Optional[str] = None,
                 raised_by: Optional[str] = None, **filters) -> dict:
    """§A3 / §2. FE calls with no params (filters/sorts/groups client-side over
    the full list); `status`/`q`/`process` honoured if passed. Each row carries
    `process` + all extension fields so the per-process pages can render.
    `status`/`q` stay positional for the existing all-process list caller.
    `raised_by` filters to one requester's own tickets at the SQL layer — the
    requester portal passes it so a user can never see another user's tickets."""
    query = db.query(HDTicket).filter(HDTicket.tenant_id == tid)
    if raised_by:
        query = query.filter(func.lower(HDTicket.raised_by) == raised_by.lower())
    rows = query.order_by(HDTicket.updated_at.desc()).all()
    out = [{**ticket_row(t), **_process_fields(t)} for t in rows]
    if process:
        out = [r for r in out if (r.get("process") or "incident") == process]
    if status:
        out = [r for r in out if (r.get("status") or "") == status]
    if q:
        s = q.lower()
        out = [r for r in out if s in (str(r.get("subject") or "") + str(r.get("name") or "")).lower()]
    summary: dict = {}
    for r in out:
        k = r.get("status") or "Open"
        summary[k] = summary.get(k, 0) + 1
    return {"tickets": out, "summary": summary, "total": len(out)}


def _conversation(db: Session, tid: int, ticket: HDTicket) -> list:
    """Merge replies + internal notes + activity into one list, sorted asc by
    date (§A4, §4). The UI prepends `ticket.description` as the opening received
    bubble, so no opening row is synthesized here."""
    items = []
    for c in (
        db.query(HDCommunication)
        .filter(HDCommunication.tenant_id == tid, HDCommunication.reference_ticket_id == ticket.id)
        .all()
    ):
        items.append({
            "type": "sent" if c.sent_or_received == "Sent" else "received",
            "sender": c.sender,
            "content": c.content,
            "date": c.communication_date or c.created_at,
        })
    for n in (
        db.query(HDTicketComment)
        .filter(HDTicketComment.tenant_id == tid, HDTicketComment.reference_ticket_id == ticket.id)
        .all()
    ):
        items.append({
            "type": "comment",
            "sender": n.commented_by,
            "content": n.content,
            "date": n.created_at,
        })
    for a in (
        db.query(HDTicketActivity)
        .filter(HDTicketActivity.tenant_id == tid, HDTicketActivity.ticket_id == ticket.id)
        .all()
    ):
        items.append({
            "type": "activity",
            "sender": "system",
            "content": a.action,
            "date": a.created_at,
        })
    items.sort(key=lambda x: x["date"] or datetime.min)
    return [{**x, "date": iso(x["date"])} for x in items]


def get_detail(db: Session, tid: int, name: str) -> dict:
    """§A4. Not-found → {"ticket": null, "conversation": []} (never 4xx, §E)."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ticket": None, "conversation": []}
    return {
        "ticket": {**ticket_detail(ticket, sla.compute_sla_block(db, ticket)),
                   **_process_fields(ticket)},
        "conversation": _conversation(db, tid, ticket),
    }


def meta(db: Session, tid: int) -> dict:
    """§A5 status/priority/type pickers."""
    statuses = (
        db.query(HDTicketStatus)
        .filter(HDTicketStatus.tenant_id == tid, HDTicketStatus.enabled == True)  # noqa: E712
        .order_by(HDTicketStatus.order.asc())
        .all()
    )
    priorities = (
        db.query(HDTicketPriority)
        .filter(HDTicketPriority.tenant_id == tid, HDTicketPriority.disabled == False)  # noqa: E712
        .all()
    )
    types = (
        db.query(HDTicketType)
        .filter(HDTicketType.tenant_id == tid, HDTicketType.disabled == False)  # noqa: E712
        .all()
    )
    feedback = (
        db.query(HDTicketFeedbackOption)
        .filter(HDTicketFeedbackOption.tenant_id == tid, HDTicketFeedbackOption.disabled == False)  # noqa: E712
        .all()
    )
    return {
        "priorities": [p.name or p.level for p in priorities],
        "ticket_types": [t.name for t in types if t.name],
        "statuses": [{"name": s.label_agent, "category": s.category} for s in statuses],
        "feedback_options": [{"label": f.label, "rating": f.rating} for f in feedback],
    }


# ─── writes ────────────────────────────────────────────────────────────────
def create_ticket(db: Session, tid: int, payload: dict, raised_by: Optional[str] = None) -> dict:
    """§0/§5/§2 create. Defaults status to the open status when unset; priority is
    taken from payload or derived from the impact/urgency matrix. `process`
    defaults to 'incident' and is set once. Auto-assign is delegated to the
    assignment engine."""
    process = (payload.get("process") or "").strip().lower() or "incident"
    if process not in PROCESSES:
        raise HTTPException(status_code=400, detail=f"unknown process '{process}'")

    status_id = payload.get("status_id")
    if not status_id:
        s = _default_open_status(db, tid)
        status_id = s.id if s else None
        status_cat = s.category if s else None
    else:
        s = db.query(HDTicketStatus).filter(
            HDTicketStatus.id == status_id, HDTicketStatus.tenant_id == tid).first()
        status_cat = s.category if s else None

    # §2: derive priority from the matrix when not given but impact+urgency are.
    priority_id = payload.get("priority_id")
    if not priority_id and payload.get("impact") and payload.get("urgency"):
        priority_id = priority_from_matrix(db, tid, payload.get("impact"), payload.get("urgency"))

    ext = _extension_kwargs(payload)
    if process == "change" and not ext.get("approval_state"):
        ext["approval_state"] = "draft"  # §2: change tickets start in draft

    ticket = HDTicket(
        tenant_id=tid,
        subject=payload.get("subject") or "(no subject)",
        description=payload.get("description"),
        raised_by=payload.get("raised_by") or raised_by,
        status_id=status_id,
        status_category=status_cat,
        priority_id=priority_id,
        ticket_type_id=payload.get("ticket_type_id"),
        agent_group_id=payload.get("agent_group_id"),
        department_id=payload.get("department_id"),  # AVA net-new intake department
        customer_id=payload.get("customer_id"),
        contact=payload.get("contact"),
        assigned_agent=payload.get("assigned_agent"),  # §1c explicit assignee at create
        process=process,
        **ext,
    )
    db.add(ticket)
    db.flush()  # assign the PK before auto-assign / return
    # §1c: an explicit assignee wins — auto_assign is the only caller, so guarding
    # the call here keeps it from overwriting a provided assigned_agent. Team
    # routing (agent_group_id) is kept either way; unassigned tickets still route.
    if not ticket.assigned_agent:
        assignment.auto_assign(db, ticket)
    # §A4: compute the SLA now so a brand-new ticket shows response_by/resolution_by/
    # agreement_status immediately (not only on the first status change). Guarded —
    # a ticket must still be created when no SLA policy matches.
    try:
        sla.recompute(db, ticket, prev_status_category=None)
    except Exception:  # noqa: BLE001 — SLA failure must never block ticket creation
        logger.warning("helpdesk: SLA recompute on create failed", exc_info=True)
    db.commit()
    # H3 audit — ids + which fields were set, never the free-text subject/description.
    hd_audit(
        db, tenant_id=tid, actor_email=raised_by,
        action="ticket.create", entity="ticket", entity_id=ticket.id,
        after={
            "process": process,
            "status_id": status_id,
            "priority_id": priority_id,
            "fields_set": sorted(k for k, v in payload.items() if v not in (None, "")),
        },
    )
    # acknowledgement email to the raiser (gated by HD Settings.send_acknowledgement_email)
    _notify("notify_acknowledgement", db, tid, ticket)
    return {"ok": True, "name": str(ticket.id)}


def set_status(db: Session, tid: int, name: str, status_label: str,
               actor_email: Optional[str] = None) -> dict:
    """§A12. Status by label (the UI sends the status `name` = our label)."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}
    new_status = _status_by_label(db, tid, status_label)
    if not new_status:
        return {"ok": False, "error": "unknown status"}
    old_label = ticket.status.label_agent if ticket.status else None
    _apply_status_change(db, tid, ticket, new_status)
    db.commit()
    hd_audit(
        db, tenant_id=tid, actor_email=actor_email,
        action="ticket.status_change", entity="ticket", entity_id=ticket.id,
        before={"status": old_label}, after={"status": new_status.label_agent},
    )
    return {"ok": True}


def reply(db: Session, tid: int, name: str, body: dict, sender: Optional[str] = None) -> dict:
    """§A13. internal=True → internal note (HDTicketComment); else a public reply
    (HDCommunication, Sent). Public reply stamps first/last agent response (§1.4)."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}
    content = body.get("content") or body.get("body") or ""
    is_public = not body.get("internal")
    if body.get("internal"):
        db.add(HDTicketComment(
            tenant_id=tid, reference_ticket_id=ticket.id,
            content=content, commented_by=sender,
        ))
        _activity(db, tid, ticket, "added an internal note")
    else:
        _public_reply(db, tid, ticket, content, sender)
    db.commit()
    hd_audit(
        db, tenant_id=tid, actor_email=sender,
        action="ticket.reply", entity="ticket", entity_id=ticket.id,
        after={"internal": bool(body.get("internal")), "has_content": bool(content)},
    )
    if is_public:
        # reply-via-agent email to the customer (gated by enable_reply_email_via_agent)
        _notify("notify_reply_via_agent", db, tid, ticket, content)
    return {"ok": True}


def _public_reply(db: Session, tid: int, ticket: HDTicket, content: str,
                  sender: Optional[str]) -> None:
    """Agent's public reply write (HDCommunication, Sent) + first/last-response
    stamping (§1.4). No commit — the caller owns the transaction, so a bulk
    reply can fan out across many tickets in one unit of work."""
    now = datetime.utcnow()
    db.add(HDCommunication(
        tenant_id=tid, reference_ticket_id=ticket.id,
        sent_or_received="Sent", sender=sender, content=content,
        communication_date=now,
    ))
    if ticket.first_responded_on is None:
        ticket.first_responded_on = now
    ticket.last_agent_response = now
    _activity(db, tid, ticket, "replied")


def update(db: Session, tid: int, name: str, payload: dict,
           actor_email: Optional[str] = None) -> dict:
    """§A14. priority / ticket_type / status / agent_group by their label values."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}

    # before-snapshot of the enum/label fields this edit can touch (no PII).
    _before = {
        "priority": (ticket.priority.name or ticket.priority.level) if ticket.priority else None,
        "ticket_type": ticket.ticket_type.name if ticket.ticket_type else None,
        "status": ticket.status.label_agent if ticket.status else None,
        "agent_group": ticket.team.name if ticket.team else None,
    }

    if payload.get("priority"):
        p = (
            db.query(HDTicketPriority)
            .filter(HDTicketPriority.tenant_id == tid, HDTicketPriority.name == payload["priority"])
            .first()
        )
        if p:
            ticket.priority_id = p.id
    if payload.get("ticket_type"):
        t = (
            db.query(HDTicketType)
            .filter(HDTicketType.tenant_id == tid, HDTicketType.name == payload["ticket_type"])
            .first()
        )
        if t:
            ticket.ticket_type_id = t.id
    if payload.get("agent_group"):
        team = (
            db.query(Team)
            .filter(Team.tenant_id == tid, Team.name == payload["agent_group"])
            .first()
        )
        if team:
            ticket.agent_group_id = team.id
            assignment.remove_if_not_in_team(db, ticket)
    if payload.get("status"):
        new_status = _status_by_label(db, tid, payload["status"])
        if new_status:
            _apply_status_change(db, tid, ticket, new_status)

    db.commit()
    _changed = {k: payload[k] for k in ("priority", "ticket_type", "status", "agent_group")
                if payload.get(k)}
    if _changed:
        hd_audit(
            db, tenant_id=tid, actor_email=actor_email,
            action="ticket.update", entity="ticket", entity_id=ticket.id,
            before={k: _before.get(k) for k in _changed}, after=_changed,
        )
    return {"ok": True}


def update_ticket(db: Session, tid: int, id, payload: dict) -> dict:
    """§2. Set the §1 process-extension fields a process detail panel / action
    edits (impact/urgency, change, problem, service-request fields + the change
    approval_state/approved_by/approved_at). `process` is set-once at create and
    is never changed here. Label-based priority/type/status edits go through
    `update()`."""
    ticket = _get_ticket(db, tid, str(id))
    if not ticket:
        return {"ok": False, "error": "not found"}
    for k, v in _extension_kwargs(payload).items():
        setattr(ticket, k, v)
    db.commit()
    return {"ok": True, "name": str(ticket.id)}


def assign(db: Session, tid: int, name: str, agent: Optional[str], team: Optional[str],
           actor_email: Optional[str] = None) -> dict:
    """§A15. agent = HD agent email (null clears); team = team name (null clears)."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}
    old_agent = ticket.assigned_agent
    old_team = ticket.team.name if ticket.team else None
    # The FE sends both keys; null means "clear".
    ticket.assigned_agent = agent
    _activity(db, tid, ticket, f"assigned to {agent}" if agent else "cleared assignee")
    t = (
        db.query(Team).filter(Team.tenant_id == tid, Team.name == team).first()
        if team else None
    )
    ticket.agent_group_id = t.id if t else None
    if t:
        assignment.remove_if_not_in_team(db, ticket)
        _activity(db, tid, ticket, f"moved to team {team}")
    db.commit()
    hd_audit(
        db, tenant_id=tid, actor_email=actor_email,
        action="ticket.assign", entity="ticket", entity_id=ticket.id,
        before={"agent": old_agent, "team": old_team},
        after={"agent": agent, "team": team},
    )
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# CONVERTED TAILS — api/ticket.py + hd_ticket.py functions not in the core above
# ═══════════════════════════════════════════════════════════════════════════

# ─── settings / status lookups (hd_ticket.py:51-64, HD Settings reads) ───────
def _settings(db: Session, tid: int) -> Optional[HDSettings]:
    """The tenant's HD Settings singleton row (grc_hd_settings). Settings are
    converted in a separate module; the tails read the row directly (per task)."""
    return db.query(HDSettings).filter(HDSettings.tenant_id == tid).first()


def _status_by_id(db: Session, tid: int, sid: Optional[int]) -> Optional[HDTicketStatus]:
    if not sid:
        return None
    return (
        db.query(HDTicketStatus)
        .filter(HDTicketStatus.id == sid, HDTicketStatus.tenant_id == tid)
        .first()
    )


def _default_open_status_for(db: Session, tid: int, ticket: HDTicket) -> Optional[HDTicketStatus]:
    """hd_ticket.py:51 `default_open_status` = SLA.default_ticket_status or HD
    Settings.default_ticket_status; falls back to the label-"Open"/enabled-Open
    heuristic (`_default_open_status`) when neither is configured."""
    if ticket.sla and ticket.sla.default_ticket_status_id:
        s = _status_by_id(db, tid, ticket.sla.default_ticket_status_id)
        if s:
            return s
    st = _settings(db, tid)
    if st and st.default_ticket_status_id:
        s = _status_by_id(db, tid, st.default_ticket_status_id)
        if s:
            return s
    return _default_open_status(db, tid)


def _reopen_status(db: Session, tid: int, ticket: HDTicket) -> Optional[HDTicketStatus]:
    """hd_ticket.py:58 `ticket_reopen_status` = SLA.ticket_reopen_status or HD
    Settings.ticket_reopen_status."""
    if ticket.sla and ticket.sla.ticket_reopen_status_id:
        s = _status_by_id(db, tid, ticket.sla.ticket_reopen_status_id)
        if s:
            return s
    st = _settings(db, tid)
    if st and st.ticket_reopen_status_id:
        return _status_by_id(db, tid, st.ticket_reopen_status_id)
    return None


def _has_agent_replied(db: Session, tid: int, ticket: HDTicket) -> bool:
    """hd_ticket.py:391 `has_agent_replied` — any Sent communication exists."""
    return (
        db.query(HDCommunication)
        .filter(
            HDCommunication.tenant_id == tid,
            HDCommunication.reference_ticket_id == ticket.id,
            HDCommunication.sent_or_received == "Sent",
        )
        .first()
        is not None
    )


# ─── attachments (api/ticket.py:39 link_attachments_to_tickets) ──────────────
def link_attachments_to_tickets(db: Session, tid: int,
                                attachments: Optional[list], ticket_ids: list) -> None:
    """api/ticket.py:39. Frappe attaches the uploaded File rows to ticket_ids[0]
    then copies them to the remaining tickets (one upload, many tickets).

    AVA has NO native attachment/File store (no File model in the helpdesk-native
    models, nor a generic one in the repo — see REPORT). Until one exists this is a
    marked no-op so the reply flow is faithful end-to-end without inventing a store.
    """
    if not attachments or not ticket_ids:
        return
    # TODO(attachments): wire to AVA's attachment store once one exists. Frappe's
    # fan-out: attach each File to ticket_ids[0], then frappe.copy_doc() per file
    # onto ticket_ids[1:]. No store to target yet, so nothing is persisted.
    return


# ─── bulk reply (api/ticket.py:7 bulk_reply) ─────────────────────────────────
def bulk_reply(db: Session, tid: int, ticket_ids: list, message: str,
               attachments: Optional[list] = None, sender: Optional[str] = None) -> dict:
    """api/ticket.py:7. Dedupe preserving the agent's order; resolve EVERY ticket
    first (tenant-scoped — the native equivalent of Frappe's per-doc write
    permission check) so one bad ticket doesn't leave the batch half done; fan out
    attachments once; then reply to each as a public agent reply, logging and
    continuing past a per-ticket failure (Frappe's try/except + frappe.log_error)."""
    if not ticket_ids:
        return {"ok": True, "replied": 0, "failed": []}

    # dedupe but keep the order the agent picked (api/ticket.py:16)
    ticket_ids = list(dict.fromkeys(ticket_ids))

    # check every ticket before writing anything (api/ticket.py:20-23): a ticket
    # not in this tenant aborts the whole batch, nothing is written
    tickets: list = []
    for tkid in ticket_ids:
        t = _get_ticket(db, tid, str(tkid))
        if not t:
            return {"ok": False, "error": f"not found: {tkid}"}
        tickets.append(t)

    link_attachments_to_tickets(db, tid, attachments, ticket_ids)

    failed: list = []
    for t in tickets:
        try:
            _public_reply(db, tid, t, message, sender)
        except Exception as e:  # noqa: BLE001 — log + continue, like frappe.log_error
            failed.append({"name": str(t.id), "error": str(e)})
    db.commit()
    hd_audit(
        db, tenant_id=tid, actor_email=sender,
        action="ticket.bulk_reply", entity="ticket",
        after={
            "ticket_ids": [str(t.id) for t in tickets],
            "replied": len(tickets) - len(failed),
            "failed": [f["name"] for f in failed],
        },
    )
    # reply-via-agent email per successfully-replied ticket (gated by settings)
    failed_names = {f["name"] for f in failed}
    for t in tickets:
        if str(t.id) not in failed_names:
            _notify("notify_reply_via_agent", db, tid, t, message)
    return {"ok": True, "replied": len(tickets) - len(failed), "failed": failed}


# ─── assign to agent (api/ticket.py:61 assign_ticket_to_agent) ───────────────
def assign_ticket_to_agent(db: Session, tid: int, name: str,
                           agent: Optional[str] = None,
                           current_user_email: Optional[str] = None) -> dict:
    """api/ticket.py:61. agent defaults to the caller (self-assign); the assignee
    must be an HD Agent of this tenant, else "Tickets can only be assigned to
    agents" (api/ticket.py:72). Stamps the single-assignee store + activity."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}

    agent = agent or current_user_email  # assign to self (api/ticket.py:67-69)
    if not agent:
        return {"ok": False, "error": "no agent"}

    is_agent = (
        db.query(HDAgent)
        .filter(HDAgent.tenant_id == tid, HDAgent.user == agent)
        .first()
        is not None
    )
    if not is_agent:
        return {"ok": False, "error": "Tickets can only be assigned to agents"}

    old_agent = ticket.assigned_agent
    ticket.assigned_agent = agent
    _activity(db, tid, ticket, f"assigned to {agent}")
    db.commit()
    hd_audit(
        db, tenant_id=tid, actor_email=current_user_email,
        action="ticket.assign", entity="ticket", entity_id=ticket.id,
        before={"agent": old_agent}, after={"agent": agent},
    )
    return {"ok": True, "name": str(ticket.id), "agent": agent}


# ─── delete (api/ticket.py:78 delete_ticket) ─────────────────────────────────
def delete_ticket(db: Session, tid: int, name: str,
                  actor_email: Optional[str] = None) -> dict:
    """api/ticket.py:78. Admin-only (gated at the route by `require_delete`);
    hard delete, Frappe's force=True. Conversation rows (communication / comment /
    activity / tags) carry ON DELETE CASCADE, so a Core delete of the ticket row
    clears them; inbound self-references (merged_with / split_from) have no cascade
    and are detached first so the delete cannot hit an FK violation.
    # ponytail: relies on the declared ON DELETE CASCADE; if a target DB runs
    # without FK enforcement (e.g. sqlite sans PRAGMA), delete children explicitly.
    """
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}
    tkid = ticket.id
    db.query(HDTicket).filter(
        HDTicket.tenant_id == tid, HDTicket.merged_with_id == tkid
    ).update({"merged_with_id": None}, synchronize_session=False)
    db.query(HDTicket).filter(
        HDTicket.tenant_id == tid, HDTicket.ticket_split_from_id == tkid
    ).update({"ticket_split_from_id": None}, synchronize_session=False)
    db.query(HDTicket).filter(
        HDTicket.id == tkid, HDTicket.tenant_id == tid
    ).delete(synchronize_session=False)
    db.commit()
    hd_audit(
        db, tenant_id=tid, actor_email=actor_email,
        action="ticket.delete", entity="ticket", entity_id=tkid,
        before={"deleted": True},
    )
    return {"ok": True}


# ─── merge chain (hd_ticket.py:1022 get_merge_target) ────────────────────────
def get_merge_target(db: Session, tid: int, ticket: HDTicket) -> Optional[HDTicket]:
    """hd_ticket.py:1022. Follow the merged_with chain to the final, non-merged
    ticket. Return None if the chain dead-ends on a missing ticket or loops back on
    itself (corrupt cycle), so a reply is never redirected onto another merged
    ticket. Returns the target row (Frappe returns its name)."""
    current_id = ticket.merged_with_id
    visited = {ticket.id}
    while current_id and current_id not in visited:
        row = (
            db.query(HDTicket)
            .filter(HDTicket.id == current_id, HDTicket.tenant_id == tid)
            .first()
        )
        if not row:
            return None
        visited.add(current_id)
        if not row.is_merged:
            return row
        if not row.merged_with_id:
            return None
        current_id = row.merged_with_id
    return None


# ─── customer reply: merge-redirect + reopen (hd_ticket.py:1058 on_communication_update) ──
def receive_customer_reply(db: Session, tid: int, name: str, content: str,
                           sender: Optional[str] = None,
                           actor_email: Optional[str] = None) -> dict:
    """hd_ticket.py:1058 `on_communication_update`, the Received (customer) path:

      * merge redirect — a reply to a merged ticket belongs to its merge target,
        so the communication is filed against the resolved target (get_merge_target).
      * reopen — if an agent has replied, move to the reopen status and record who
        reopened it; otherwise the default open status. Stamp last_customer_response.

    Running the status change through `_apply_status_change` recomputes the SLA
    (set_resolution_date etc. flow from it), matching the save Frappe triggers.
    Not-found → 200-safe error dict (contract §E)."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}

    # redirect onto the merge target when this ticket is merged (hd_ticket.py:1062)
    target = ticket
    if ticket.is_merged and ticket.merged_with_id:
        mt = get_merge_target(db, tid, ticket)
        if mt:
            target = mt

    now = datetime.utcnow()
    db.add(HDCommunication(
        tenant_id=tid, reference_ticket_id=target.id,
        sent_or_received="Received", sender=sender, content=content,
        communication_date=now,
    ))

    # reopen (hd_ticket.py:1069-1078)
    if _has_agent_replied(db, tid, target):
        new_status = _reopen_status(db, tid, target)
    else:
        new_status = _default_open_status_for(db, tid, target)
    if new_status and target.status_id != new_status.id:
        _apply_status_change(db, tid, target, new_status)
    target.last_customer_response = now
    _activity(db, tid, target, "customer replied")
    db.commit()
    hd_audit(
        db, tenant_id=tid, actor_email=actor_email or sender,
        action="ticket.customer_reply", entity="ticket", entity_id=target.id,
        after={
            "redirected_from": str(ticket.id) if target.id != ticket.id else None,
            "has_content": bool(content),
        },
    )
    # notify the assigned agent of the customer reply (gated by enable_reply_email_to_agent)
    _notify("notify_reply_to_agents", db, tid, target, content)
    return {"ok": True, "name": str(target.id)}


# ─── scheduled maintenance (hd_ticket.py:1469 / :1526) ───────────────────────
def close_tickets_after_n_days(db: Session, tid: int) -> dict:
    """hd_ticket.py:1469. Auto-close tickets sitting in the configured
    auto_close_status with no communication for auto_close_after_days. Reads HD
    Settings directly (auto_close_tickets / auto_close_status / auto_close_after_days)
    per task. Closes via the normal status change (so SLA flows), logs the reason,
    commits per ticket, and continues past a per-ticket failure (Frappe parity).

    No-op unless auto_close_tickets is on and a "Closed" status exists."""
    st = _settings(db, tid)
    if not st or not st.auto_close_tickets:
        return {"closed": 0}

    eligible = _status_by_id(db, tid, st.auto_close_status_id)
    if not eligible:
        return {"closed": 0}
    closed_status = _status_by_label(db, tid, CLOSED_LABEL)
    if not closed_status:
        return {"closed": 0}

    days = int(st.auto_close_after_days or 0)
    cutoff = datetime.utcnow() - timedelta(days=days)

    # last communication per ticket; INNER JOIN excludes tickets with none
    # (hd_ticket.py:1488 subquery parity)
    last_comm = (
        db.query(
            HDCommunication.reference_ticket_id.label("tkid"),
            func.max(HDCommunication.communication_date).label("last"),
        )
        .filter(HDCommunication.tenant_id == tid)
        .group_by(HDCommunication.reference_ticket_id)
        .subquery()
    )
    rows = (
        db.query(HDTicket)
        .join(last_comm, HDTicket.id == last_comm.c.tkid)
        .filter(
            HDTicket.tenant_id == tid,
            HDTicket.status_id == eligible.id,
            last_comm.c.last < cutoff,
        )
        .all()
    )

    plural = "s" if days != 1 else ""
    closed = 0
    for ticket in rows:
        try:
            _apply_status_change(db, tid, ticket, closed_status)
            _activity(
                db, tid, ticket,
                f"automatically closed the ticket after {days} day{plural} of inactivity",
            )
            db.commit()
            closed += 1
        except Exception:  # noqa: BLE001 — log + continue (frappe.log_error parity)
            db.rollback()
            continue
    return {"closed": closed}


def update_sla_status_in_ticket(db: Session, tid: int) -> dict:
    """hd_ticket.py:1526. Refresh agreement_status on every Open-category ticket
    that has an SLA, so breaches surface as the clock runs. Mirrors Frappe's
    agreement_status-only update (handle_agreement_status), not a full re-apply, so
    the deadlines are left untouched. Commits per ticket, continues past failures.
    # ponytail: the status write bumps updated_at (ORM onupdate); Frappe used
    # update_modified=False. Cosmetic only — drop if modified-time must be frozen.
    """
    now = datetime.utcnow()
    rows = (
        db.query(HDTicket)
        .filter(
            HDTicket.tenant_id == tid,
            HDTicket.status_category == "Open",
            HDTicket.sla_id.isnot(None),
        )
        .all()
    )
    updated = 0
    for ticket in rows:
        policy = ticket.sla
        if not policy:
            continue
        try:
            sla._handle_agreement_status(ticket, policy, now)
            db.commit()
            updated += 1
        except Exception:  # noqa: BLE001
            db.rollback()
            continue
    return {"updated": updated}


# ═══════════════════════════════════════════════════════════════════════════
# NEW ROUTES — the main session mounts `extra_router` alongside `router`.
# (close_tickets_after_n_days / update_sla_status_in_ticket are scheduled jobs,
#  not HTTP endpoints, so they get no route here.)
# ═══════════════════════════════════════════════════════════════════════════
extra_router = APIRouter(prefix="/helpdesk", tags=["Help Desk (native)"])


class BulkReplyBody(BaseModel):
    ticket_ids: List[str]
    message: str
    attachments: Optional[list] = None


class AssignAgentBody(BaseModel):
    agent: Optional[str] = None  # None => self-assign (caller)


class CustomerReplyBody(BaseModel):
    content: str = ""
    sender: Optional[str] = None


@extra_router.post("/tickets/bulk-reply")
def _bulk_reply(body: BulkReplyBody, db: Session = Depends(get_db),
                current_user: GRCUser = Depends(require_auth),
                _: bool = Depends(require_edit)):
    return bulk_reply(db, tenant_id(db), body.ticket_ids, body.message,
                      body.attachments, sender=current_user.email)


@extra_router.post("/tickets/{name}/assign-agent")
def _assign_agent(name: str, body: AssignAgentBody, db: Session = Depends(get_db),
                  current_user: GRCUser = Depends(require_auth),
                  _: bool = Depends(require_tickets_assign)):
    return assign_ticket_to_agent(db, tenant_id(db), name, body.agent,
                                  current_user_email=current_user.email)


@extra_router.post("/tickets/{name}/customer-reply")
def _customer_reply(name: str, body: CustomerReplyBody, db: Session = Depends(get_db),
                    current_user: GRCUser = Depends(require_auth),
                    _: bool = Depends(require_edit)):
    return receive_customer_reply(db, tenant_id(db), name, body.content, body.sender,
                                  actor_email=current_user.email)


@extra_router.delete("/tickets/{name}")
def _delete_ticket(name: str, db: Session = Depends(get_db),
                   current_user: GRCUser = Depends(require_auth),
                   _: bool = Depends(require_tickets_delete)):
    return delete_ticket(db, tenant_id(db), name, actor_email=current_user.email)
