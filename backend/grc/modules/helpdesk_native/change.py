"""Changes — the approval workflow over the shared ticket engine (spec §5).

A change is an HDTicket with process='change'; its lifecycle is the
`approval_state` column: draft → pending_approval → approved → scheduled →
in_progress → review → closed, plus reject (from pending_approval) and a
cancel-from-anywhere. Each action resolves its target state against an
allowed-transition map and rejects an illegal move with 400 — the same shape as
tickets.is_valid_status_transition. Writes route through Agent A's
`update_ticket`; `complete` also closes the ticket itself (status 'Closed'),
and `approve` stamps the signed-in agent + time.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ...models import GRCUser, HDTicket, get_db
from ...routers.auth_router import require_auth
from . import tickets  # Agent A's write path; attrs resolve at call time
from .common import require_edit, require_view, tenant_id

router = APIRouter(prefix="/helpdesk/changes", tags=["Help Desk (native)"])

DRAFT = "draft"

# action -> (allowed-from states, resulting approval_state). `None` allowed-from
# means "any state" (cancel). A move whose current state is not in allowed-from
# is rejected with 400, mirroring tickets.is_valid_status_transition.
TRANSITIONS = {
    "submit":   ({"draft"}, "pending_approval"),
    "approve":  ({"pending_approval"}, "approved"),
    "reject":   ({"pending_approval"}, "rejected"),
    "schedule": ({"approved"}, "scheduled"),
    "start":    ({"scheduled"}, "in_progress"),
    "review":   ({"in_progress"}, "review"),
    "complete": ({"review"}, "closed"),
    "cancel":   (None, "cancelled"),
}


def _target_state(action: str, current: str) -> str:
    """Resulting approval_state for `action` from `current`, or 400 on an illegal
    move. Pure — the self-check exercises it with no DB."""
    allowed_from, to_state = TRANSITIONS[action]
    if allowed_from is not None and current not in allowed_from:
        raise HTTPException(status_code=400,
                            detail=f"Cannot {action} a change in state '{current}'")
    return to_state


def _get_change(db: Session, tid: int, cid: int) -> Optional[HDTicket]:
    return (
        db.query(HDTicket)
        .filter(HDTicket.id == cid, HDTicket.tenant_id == tid)
        .first()
    )


def _apply(db: Session, tid: int, cid: int, action: str,
           extra: Optional[dict] = None) -> dict:
    """Fetch, guard the transition (400 if illegal), write the new approval_state
    (+ any extra extension fields) through Agent A's update_ticket."""
    ticket = _get_change(db, tid, cid)
    if not ticket:
        return {"ok": False, "error": "not found"}
    to_state = _target_state(action, ticket.approval_state or DRAFT)  # may raise 400
    payload = {"approval_state": to_state}
    if extra:
        payload.update(extra)
    return tickets.update_ticket(db, tid, cid, payload)


class ScheduleBody(BaseModel):
    planned_start: Optional[datetime] = None
    planned_end: Optional[datetime] = None


@router.get("")
def list_changes(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return tickets.list_tickets(db, tenant_id(db), process="change")


@router.post("/{cid}/submit")
def submit_change(cid: int, db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return _apply(db, tenant_id(db), cid, "submit")


@router.post("/{cid}/approve")
def approve_change(cid: int, db: Session = Depends(get_db),
                   current_user: GRCUser = Depends(require_auth),
                   _: bool = Depends(require_edit)):
    return _apply(db, tenant_id(db), cid, "approve",
                  {"approved_by": current_user.email, "approved_at": datetime.utcnow()})


@router.post("/{cid}/reject")
def reject_change(cid: int, db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return _apply(db, tenant_id(db), cid, "reject")


@router.post("/{cid}/schedule")
def schedule_change(cid: int, body: ScheduleBody, db: Session = Depends(get_db),
                    _: bool = Depends(require_edit)):
    return _apply(db, tenant_id(db), cid, "schedule",
                  {"planned_start": body.planned_start, "planned_end": body.planned_end})


@router.post("/{cid}/start")
def start_change(cid: int, db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return _apply(db, tenant_id(db), cid, "start")


@router.post("/{cid}/review")
def review_change(cid: int, db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return _apply(db, tenant_id(db), cid, "review")


@router.post("/{cid}/complete")
def complete_change(cid: int, db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    # Set approval_state=closed, then ACTUALLY close the ticket via the label path
    # (tickets.update → _apply_status_change → SLA recompute). update_ticket only
    # writes extension fields, so the status close must go through update().
    tid = tenant_id(db)
    r = _apply(db, tid, cid, "complete")
    if r.get("ok"):
        tickets.update(db, tid, str(cid), {"status": "Closed"})
    return r


@router.post("/{cid}/cancel")
def cancel_change(cid: int, db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return _apply(db, tenant_id(db), cid, "cancel")


if __name__ == "__main__":  # pure transition-map self-check, no DB
    from fastapi import HTTPException as _HE

    legal = [("submit", "draft"), ("approve", "pending_approval"),
             ("schedule", "approved"), ("start", "scheduled"),
             ("review", "in_progress"), ("complete", "review"),
             ("reject", "pending_approval")]
    for action, frm in legal:
        assert _target_state(action, frm) == TRANSITIONS[action][1], (action, frm)
    # cancel from anywhere
    for frm in ("draft", "approved", "in_progress", "review"):
        assert _target_state("cancel", frm) == "cancelled"
    # illegal moves → 400
    for action, bad in [("approve", "draft"), ("start", "approved"),
                        ("complete", "in_progress"), ("submit", "approved"),
                        ("reject", "approved")]:
        try:
            _target_state(action, bad)
        except _HE as e:
            assert e.status_code == 400
        else:
            raise AssertionError(f"{action} from {bad} should be illegal")
    print("change.py transition map OK")
