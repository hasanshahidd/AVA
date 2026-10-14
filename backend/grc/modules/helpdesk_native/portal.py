"""Requester portal — the end-user surface of Help Desk.

A normal employee (a "requester") can raise a request, track ONLY their own
requests, reply on them, and browse the self-service catalog / request library
/ knowledge base. This is the non-agent view: every endpoint is gated by the
`helpdesk:requests:*` perms (which a requester-only role has but the agent
`helpdesk:tickets:*` perms it does NOT), and own-ticket isolation is enforced
server-side on `raised_by == current_user.email` — the client is never trusted
to say whose tickets it wants. Administrator + primary-contact bypass the gate
as everywhere, which is fine.

Tenant isolation is inherited from get_db (DB-per-tenant) + tenant_id(db); the
extra layer here is the per-USER filter.
"""
from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ...models import get_db
from . import department, kb, itsm_seed, tickets
from .common import (
    current_user_email,
    require_request_create,
    require_requester,
    tenant_id,
)

router = APIRouter(prefix="/helpdesk/portal", tags=["Help Desk (requester portal)"])


# ─── request bodies ──────────────────────────────────────────────────────
class RequestCreate(BaseModel):
    subject: str
    description: Optional[str] = None
    process: Optional[str] = None          # defaults to 'incident' in create_ticket
    department_id: Optional[int] = None    # routed to a Team, like the agent form
    impact: Optional[str] = None           # feeds the priority matrix
    urgency: Optional[str] = None
    request_category: Optional[str] = None
    request_subcategory: Optional[str] = None


class RequestReply(BaseModel):
    content: str = ""


# ─── own-ticket helper ─────────────────────────────────────────────────────
def _own_ticket(db: Session, tid: int, name: str, email: str):
    """Fetch a ticket ONLY if it belongs to this requester (tenant-scoped +
    raised_by match). Anything else → 404, so a requester can neither read nor
    act on another user's ticket (and can't tell one exists)."""
    ticket = tickets._get_ticket(db, tid, name)
    if not ticket or (ticket.raised_by or "").lower() != (email or "").lower():
        raise HTTPException(status_code=404, detail="not found")
    return ticket


# ─── requests (create / track-own / reply) ─────────────────────────────────
@router.post("/requests")
def create_request(body: RequestCreate, db: Session = Depends(get_db),
                   email: str = Depends(current_user_email),
                   _: bool = Depends(require_request_create)):
    """Raise a request. raised_by is FORCED to the signed-in user (the body has
    no raised_by field, so create_ticket falls back to this kwarg) — a requester
    can never file as someone else."""
    tid = tenant_id(db)
    data = body.model_dump(exclude_none=True)
    # Same department→Team routing the agent create does, so the request lands
    # on the right queue; assignment + SLA then run unchanged in create_ticket.
    if data.get("department_id"):
        team_id = department.resolve_department_team(db, tid, data["department_id"])
        if team_id:
            data["agent_group_id"] = team_id
    return tickets.create_ticket(db, tid, data, raised_by=email)


@router.get("/my-requests")
def my_requests(status: Optional[str] = None, q: Optional[str] = None,
                db: Session = Depends(get_db),
                email: str = Depends(current_user_email),
                _: bool = Depends(require_requester)):
    """List ONLY the caller's own requests (raised_by filtered at the SQL layer
    in list_tickets — never trusting a client-supplied owner)."""
    return tickets.list_tickets(db, tenant_id(db), status, q, raised_by=email)


@router.get("/requests/{name}")
def request_detail(name: str, db: Session = Depends(get_db),
                   email: str = Depends(current_user_email),
                   _: bool = Depends(require_requester)):
    """Full detail + conversation for the caller's OWN request only; 404 otherwise."""
    _own_ticket(db, tenant_id(db), name, email)  # ownership gate (raises 404)
    return tickets.get_detail(db, tenant_id(db), name)


@router.post("/requests/{name}/reply")
def reply_request(name: str, body: RequestReply, db: Session = Depends(get_db),
                  email: str = Depends(current_user_email),
                  _: bool = Depends(require_request_create)):
    """The requester replies on their OWN request (customer-reply path: files a
    Received message + reopens per the lifecycle). Ownership-guarded."""
    tid = tenant_id(db)
    _own_ticket(db, tid, name, email)  # ownership gate (raises 404)
    return tickets.receive_customer_reply(db, tid, name, body.content, sender=email)


# ─── self-service reads (so the requester form + help page work) ────────────
@router.get("/catalog")
def catalog(db: Session = Depends(get_db), email: str = Depends(current_user_email),
            _: bool = Depends(require_requester)):
    """The category→subcategory service catalog (shared with the agent form)."""
    return itsm_seed.SERVICE_CATALOG


@router.get("/templates")
def templates(department_id: Optional[int] = None, process: Optional[str] = None,
              db: Session = Depends(get_db), email: str = Depends(current_user_email),
              _: bool = Depends(require_requester)):
    """The predefined request library, optionally filtered by department/process."""
    from .request_templates import list_request_templates
    return list_request_templates(department_id, process, db, True)


@router.get("/kb")
def knowledge_base(db: Session = Depends(get_db), email: str = Depends(current_user_email),
                   _: bool = Depends(require_requester)):
    """Browse the knowledge base (gated on requests:view_own so any requester can
    read self-help; authoring stays behind the agent kb:author/edit gates)."""
    return kb.list_articles(db, tenant_id(db))
