"""Native Help Desk router — the full `/helpdesk/*` surface from
`docs/HELPDESK_API_CONTRACT.md`, served from AVA's own DB instead of the Frappe
proxy.

Status: the TICKET CORE (list/detail/meta/create/status/reply/update/assign) is
converted and live here. The other sections (agents, teams, customers, contacts,
KB, saved/canned replies, dashboard, analytics, config) are wired to STUBS in
their sibling modules so the whole surface imports and responds with the
contract's empty shapes; parallel agents fill those in.

NOT MOUNTED YET. `grc/main.py` still mounts the Frappe proxy
(`modules/helpdesk/router.py`). Cutover — swapping the app from proxy → native —
is a later step; this module is self-contained and importable so it can be
tested first.

Contract invariants honoured: 200 + empty shapes on "empty" (never 4xx, §E);
mutating POSTs return {"ok": true}; status/priority values are the label strings
the UI's style maps key on.
"""
from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ...models import GRCUser, get_db
from ...routers.auth_router import require_auth
from . import (  # noqa: F401 (assignment used by tickets)
    tickets, sla, assignment, people, kb, replies, dashboard,
    masters, agent_status, contacts, tags, views, settings, analytics, department, mail,
)
from .common import tenant_id, require_view, require_edit

router = APIRouter(prefix="/helpdesk", tags=["Help Desk (native)"])


# ─── request bodies ──────────────────────────────────────────────────────
class StatusUpdate(BaseModel):
    status: str


class ReplyBody(BaseModel):
    content: str = ""
    body: str = ""
    internal: bool = False
    cc: Optional[str] = None
    bcc: Optional[str] = None


class TicketUpdate(BaseModel):
    priority: Optional[str] = None
    ticket_type: Optional[str] = None
    status: Optional[str] = None
    agent_group: Optional[str] = None


class AssignBody(BaseModel):
    agent: Optional[str] = None
    team: Optional[str] = None


class TicketCreate(BaseModel):
    subject: str
    description: Optional[str] = None
    raised_by: Optional[str] = None
    status_id: Optional[int] = None
    priority_id: Optional[int] = None
    ticket_type_id: Optional[int] = None
    agent_group_id: Optional[int] = None
    customer_id: Optional[int] = None
    contact: Optional[str] = None
    department_id: Optional[int] = None    # AVA net-new: multi-department intake


class SavedReplyBody(BaseModel):
    title: str
    message: str = ""


# ─── dashboard (stubs) ─────────────────────────────────────────────────────
@router.get("/dashboard")
def dashboard_view(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return dashboard.recent(db, tenant_id(db))


@router.get("/dashboard-analytics")
def dashboard_analytics(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return dashboard.analytics(db, tenant_id(db))


# ─── tickets (CORE — converted) ────────────────────────────────────────────
@router.get("/tickets")
def list_tickets(status: Optional[str] = None, q: Optional[str] = None,
                 db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return tickets.list_tickets(db, tenant_id(db), status, q)


@router.get("/meta")
def meta(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return tickets.meta(db, tenant_id(db))


@router.get("/tickets/{name}")
def ticket_detail(name: str, db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return tickets.get_detail(db, tenant_id(db), name)


@router.post("/tickets")
def create_ticket(body: TicketCreate, db: Session = Depends(get_db),
                  current_user: GRCUser = Depends(require_auth), _: bool = Depends(require_edit)):
    tid = tenant_id(db)
    data = body.model_dump()
    # NET-NEW department routing: a chosen department stamps the ticket's Team, then
    # the existing assignment + SLA pipeline runs unchanged. An explicit agent_group wins.
    if data.get("department_id") and not data.get("agent_group_id"):
        team_id = department.resolve_department_team(db, tid, data["department_id"])
        if team_id:
            data["agent_group_id"] = team_id
    return tickets.create_ticket(db, tid, data, raised_by=current_user.email)


@router.post("/tickets/{name}/status")
def set_ticket_status(name: str, body: StatusUpdate, db: Session = Depends(get_db),
                      _: bool = Depends(require_edit)):
    return tickets.set_status(db, tenant_id(db), name, body.status)


@router.post("/tickets/{name}/reply")
def reply_ticket(name: str, body: ReplyBody, db: Session = Depends(get_db),
                 current_user: GRCUser = Depends(require_auth), _: bool = Depends(require_edit)):
    return tickets.reply(db, tenant_id(db), name, body.model_dump(), sender=current_user.email)


@router.post("/tickets/{name}/update")
def update_ticket(name: str, body: TicketUpdate, db: Session = Depends(get_db),
                  _: bool = Depends(require_edit)):
    return tickets.update(db, tenant_id(db), name, body.model_dump(exclude_none=True))


@router.post("/tickets/{name}/assign")
def assign_ticket(name: str, body: AssignBody, db: Session = Depends(get_db),
                  _: bool = Depends(require_edit)):
    return tickets.assign(db, tenant_id(db), name, body.agent, body.team)


# ─── people (stubs) ────────────────────────────────────────────────────────
@router.get("/agents")
def agents(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return people.list_agents(db, tenant_id(db))


@router.get("/teams")
def teams(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return people.list_teams(db, tenant_id(db))


@router.get("/customers")
def customers(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return people.list_customers(db, tenant_id(db))


# /contacts is now served by contacts.router (full contact store).


# ─── knowledge base (stub) ──────────────────────────────────────────────────
@router.get("/articles")
def articles(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return kb.list_articles(db, tenant_id(db))


# ─── saved / canned replies (stubs) ─────────────────────────────────────────
@router.get("/canned-responses")
def canned_responses(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return replies.list_canned_responses(db, tenant_id(db))


@router.get("/saved-replies")
def saved_replies(db: Session = Depends(get_db), _: bool = Depends(require_view)):
    return replies.list_saved_replies(db, tenant_id(db))


@router.post("/saved-replies")
def create_saved_reply(body: SavedReplyBody, db: Session = Depends(get_db),
                       _: bool = Depends(require_edit)):
    return replies.create_saved_reply(db, tenant_id(db), body.model_dump())


@router.put("/saved-replies/{name}")
def update_saved_reply(name: str, body: SavedReplyBody, db: Session = Depends(get_db),
                       _: bool = Depends(require_edit)):
    return replies.update_saved_reply(db, tenant_id(db), name, body.model_dump())


@router.delete("/saved-replies/{name}")
def delete_saved_reply(name: str, db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return replies.delete_saved_reply(db, tenant_id(db), name)


# /config is now served by settings.router (real HD Settings public subset).


# ─── aggregate: the full native surface main.py mounts ──────────────────────
# The core `router` (prefix /helpdesk) above + every converted module's sub-router.
# Sub-routers that are prefix-less (masters, sla config) are mounted under /helpdesk
# here; the rest already carry their own /helpdesk path and mount as-is.
helpdesk_native_router = APIRouter()
helpdesk_native_router.include_router(router)                               # ticket core + reads
helpdesk_native_router.include_router(masters.router, prefix="/helpdesk")   # status/type/template/feedback CRUD
helpdesk_native_router.include_router(sla.config_router, prefix="/helpdesk")  # SLA + holiday-list config CRUD
helpdesk_native_router.include_router(tickets.extra_router)                 # bulk-reply/assign-agent/customer-reply/delete
helpdesk_native_router.include_router(people.people_write_router)           # agent/customer/membership write
helpdesk_native_router.include_router(agent_status.router)                  # /helpdesk/agent-statuses
helpdesk_native_router.include_router(contacts.router)                      # /helpdesk/contacts (store)
helpdesk_native_router.include_router(replies.actions_router)               # rendered + apply-saved-reply-actions
helpdesk_native_router.include_router(kb.kb_write_router)                   # article/category CRUD + feedback
helpdesk_native_router.include_router(dashboard.dashboard_router)           # /helpdesk/dashboard-data
helpdesk_native_router.include_router(analytics.router)                     # /helpdesk/analytics/*
helpdesk_native_router.include_router(tags.router)                          # /helpdesk/tags, ticket tags
helpdesk_native_router.include_router(views.router)                         # /helpdesk/views
helpdesk_native_router.include_router(settings.router)                      # /helpdesk/settings + /helpdesk/config
helpdesk_native_router.include_router(department.router)                    # /helpdesk/departments (NET-NEW)
helpdesk_native_router.include_router(mail.router)                          # /helpdesk/email-accounts + email poll/feedback
