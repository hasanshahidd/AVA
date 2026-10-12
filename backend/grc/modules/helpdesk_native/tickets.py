"""Ticket core — the converted engine (logic spec §0, §3, §4; contract §A3–§A5,
§A12–§A15).

Faithful native port of the Frappe HD Ticket lifecycle the Help Desk UI drives:
list / detail (ticket + SLA block + merged conversation) / create / status /
reply / update / assign. SLA business-hours math and the assignment-rule
strategy are delegated to the `sla` / `assignment` modules (stubs for now).
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy.orm import Session

from ...models import (
    HDTicket,
    HDTicketStatus,
    HDTicketPriority,
    HDTicketType,
    HDTeam,
    HDCommunication,
    HDTicketComment,
    HDTicketActivity,
    HDTicketFeedbackOption,
)
from . import sla, assignment
from .common import iso, ticket_row, ticket_detail

RESOLVED = "Resolved"
PAUSED = "Paused"


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


# ─── reads ───────────────────────────────────────────────────────────────────
def list_tickets(db: Session, tid: int, status: Optional[str] = None,
                 q: Optional[str] = None) -> dict:
    """§A3. FE calls with no params (filters/sorts/groups client-side over the
    full list); `status`/`q` honoured if passed."""
    rows = (
        db.query(HDTicket)
        .filter(HDTicket.tenant_id == tid)
        .order_by(HDTicket.updated_at.desc())
        .all()
    )
    out = [ticket_row(t) for t in rows]
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
        "ticket": ticket_detail(ticket, sla.compute_sla_block(db, ticket)),
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
    """§0/§5 create. Defaults status to the open status when unset; priority/type
    taken from payload. Auto-assign is delegated to the assignment engine."""
    status_id = payload.get("status_id")
    if not status_id:
        s = _default_open_status(db, tid)
        status_id = s.id if s else None
        status_cat = s.category if s else None
    else:
        s = db.query(HDTicketStatus).filter(
            HDTicketStatus.id == status_id, HDTicketStatus.tenant_id == tid).first()
        status_cat = s.category if s else None

    ticket = HDTicket(
        tenant_id=tid,
        subject=payload.get("subject") or "(no subject)",
        description=payload.get("description"),
        raised_by=payload.get("raised_by") or raised_by,
        status_id=status_id,
        status_category=status_cat,
        priority_id=payload.get("priority_id"),
        ticket_type_id=payload.get("ticket_type_id"),
        agent_group_id=payload.get("agent_group_id"),
        customer_id=payload.get("customer_id"),
        contact=payload.get("contact"),
    )
    db.add(ticket)
    db.flush()  # assign the PK before auto-assign / return
    assignment.auto_assign(db, ticket)
    db.commit()
    return {"ok": True, "name": str(ticket.id)}


def set_status(db: Session, tid: int, name: str, status_label: str) -> dict:
    """§A12. Status by label (the UI sends the status `name` = our label)."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}
    new_status = _status_by_label(db, tid, status_label)
    if not new_status:
        return {"ok": False, "error": "unknown status"}
    _apply_status_change(db, tid, ticket, new_status)
    db.commit()
    return {"ok": True}


def reply(db: Session, tid: int, name: str, body: dict, sender: Optional[str] = None) -> dict:
    """§A13. internal=True → internal note (HDTicketComment); else a public reply
    (HDCommunication, Sent). Public reply stamps first/last agent response (§1.4)."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}
    content = body.get("content") or body.get("body") or ""
    if body.get("internal"):
        db.add(HDTicketComment(
            tenant_id=tid, reference_ticket_id=ticket.id,
            content=content, commented_by=sender,
        ))
        _activity(db, tid, ticket, "added an internal note")
    else:
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
    db.commit()
    return {"ok": True}


def update(db: Session, tid: int, name: str, payload: dict) -> dict:
    """§A14. priority / ticket_type / status / agent_group by their label values."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}

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
            db.query(HDTeam)
            .filter(HDTeam.tenant_id == tid, HDTeam.team_name == payload["agent_group"])
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
    return {"ok": True}


def assign(db: Session, tid: int, name: str, agent: Optional[str], team: Optional[str]) -> dict:
    """§A15. agent = HD agent email (null clears); team = team name (null clears)."""
    ticket = _get_ticket(db, tid, name)
    if not ticket:
        return {"ok": False, "error": "not found"}
    # The FE sends both keys; null means "clear".
    ticket.assigned_agent = agent
    _activity(db, tid, ticket, f"assigned to {agent}" if agent else "cleared assignee")
    t = (
        db.query(HDTeam).filter(HDTeam.tenant_id == tid, HDTeam.team_name == team).first()
        if team else None
    )
    ticket.agent_group_id = t.id if t else None
    if t:
        assignment.remove_if_not_in_team(db, ticket)
        _activity(db, tid, ticket, f"moved to team {team}")
    db.commit()
    return {"ok": True}
