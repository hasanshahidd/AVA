"""Agents / teams / customers / contacts — native read (§A6–§A9) + write side.

READ (§A6–§A9): tenant-scoped transcription of the Frappe-proxy people handlers
onto AVA's own tables. Reads only; never 4xx on empty — a tenant with no rows gets
the documented empty shape (§E).

WRITE (`people_write_router`): native conversion of the Frappe controller write
logic the read side left out —
  * HD Agent (doctype/hd_agent/hd_agent.py): availability validate + change-stamp,
    set-active, agent_name store, update_agent_role.
  * HD Customer (doctype/hd_customer/hd_customer.py + api/customer.py): create /
    update / delete (delete-or-unlink tickets via a flag), membership via
    HDCustomerMember, primary-contact, manager flag.
Contact CRUD lives in contacts.py; this module reuses it for the customer
primary-contact create path and for list_contacts.

Conversions / gaps (noted, not faked):
  * agent_name <-> User sync (hd_agent.before_save) — AVA just stores agent_name;
    there is no two-way write back to a User row.
  * role grants (hd_agent.set_user_roles / update_agent_role; customer
    sync_contact_role) map to AVA's own RBAC (UserRole/Role rows), which is NOT
    written from here (would require editing auth/RBAC outside these files). The
    membership `is_manager` flag IS stored; the matching AVA role grant is not.
  * realtime availability broadcast (hd_agent.publish_availability_update) — no
    socket layer natively; omitted.
  * invites (customer.add_primary_contact / invite_contacts) — intent is honoured
    by creating the contact + membership; the external email invitation has no
    native store and is not sent.
  * ERPNext sync (hd_customer after_insert/on_update/on_trash) — N/A, skipped.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import func
from sqlalchemy.orm import Session

from ...models import (
    GRCUser,
    HDAgent,
    HDContact,
    HDCustomer,
    HDCustomerMember,
    HDTeam,
    HDTicket,
    get_db,
)
from ...routers.auth_router import require_auth
from . import agent_status, contacts
from .common import require_edit, tenant_id

people_write_router = APIRouter(prefix="/helpdesk", tags=["Help Desk (native)"])

CUSTOMER_ROLES = ("HD Customer", "HD Customer Manager")


# ═══════════════════════════════════════════════════════════════════════════
# READ (§A6–§A9)
# ═══════════════════════════════════════════════════════════════════════════
def list_agents(db: Session, tid: int) -> dict:
    """§A6. availability keys the UI style map (active/away/unavailable); fall back
    to the active flag when no HD Agent Status is set — exactly as the proxy did."""
    rows = (
        db.query(HDAgent)
        .filter(HDAgent.tenant_id == tid)
        .order_by(HDAgent.agent_name.asc())
        .all()
    )
    return {"agents": [{
        "name": a.user,
        "agent_name": a.agent_name or a.user,
        "email": a.user,
        "availability": a.availability or ("Active" if a.is_active else "Unavailable"),
        "is_active": bool(a.is_active),
    } for a in rows]}


def list_teams(db: Session, tid: int) -> dict:
    """§A7. `name` == team_name on purpose: the ticket assign/update endpoints
    resolve a team by its name (tickets.assign/update), and that's the value the
    team dropdown sends back. members carry only `user` (user→grc_users join is
    deferred, so no full_name)."""
    rows = (
        db.query(HDTeam)
        .filter(HDTeam.tenant_id == tid)
        .order_by(HDTeam.team_name.asc())
        .all()
    )
    return {"teams": [{
        "name": t.team_name,
        "team_name": t.team_name,
        "assignment_rule": t.assignment_rule,
        "members": [{"name": m.user} for m in t.users],
    } for t in rows]}


def list_customers(db: Session, tid: int) -> dict:
    """§A8. contacts_count is COMPUTED (proxy hardcoded 0). Now that HD Customer
    Member exists it is the real membership count, one grouped query for the
    tenant (was previously derived from distinct ticket contacts)."""
    counts = dict(
        db.query(HDCustomerMember.customer_id, func.count(HDCustomerMember.id))
        .join(HDCustomer, HDCustomer.id == HDCustomerMember.customer_id)
        .filter(HDCustomer.tenant_id == tid)
        .group_by(HDCustomerMember.customer_id)
        .all()
    )
    rows = (
        db.query(HDCustomer)
        .filter(HDCustomer.tenant_id == tid)
        .order_by(HDCustomer.customer_name.asc())
        .all()
    )
    return {"customers": [{
        "name": str(c.id),
        "customer_name": c.customer_name or str(c.id),
        "domain": c.domain,
        "contacts_count": counts.get(c.id, 0),
    } for c in rows]}


def list_contacts(db: Session, tid: int) -> dict:
    """§A9. Real rows now — delegated to the native contact store (contacts.py)."""
    return contacts.list_contacts(db, tid)


# ═══════════════════════════════════════════════════════════════════════════
# WRITE — HD Agent (doctype/hd_agent/hd_agent.py)
# ═══════════════════════════════════════════════════════════════════════════
class AgentCreate(BaseModel):
    user: str                       # login email
    agent_name: str | None = None
    availability: str | None = None
    user_image: str | None = None
    is_active: bool = True


class AvailabilityBody(BaseModel):
    availability: str


class ActiveBody(BaseModel):
    is_active: bool


class AgentRoleBody(BaseModel):
    user: str
    new_role: str                   # "Agent" | "Manager"


def _get_agent(db: Session, tid: int, user: str) -> HDAgent | None:
    """Agents are addressed by their login email (`user`) — the §A6 `name`."""
    return (
        db.query(HDAgent)
        .filter(HDAgent.tenant_id == tid, HDAgent.user == user)
        .first()
    )


def _validate_availability(db: Session, tid: int, availability: str) -> None:
    """hd_agent.validate_availability — only an ENABLED HD Agent Status may be set."""
    from ...models import HDAgentStatus
    ok = (
        db.query(HDAgentStatus)
        .filter(
            HDAgentStatus.tenant_id == tid,
            HDAgentStatus.agent_status == availability,
            HDAgentStatus.enabled.is_(True),
        )
        .first()
    )
    if not ok:
        raise HTTPException(status_code=400, detail="Invalid availability")


def create_agent(db: Session, tid: int, payload: dict, actor: str | None) -> dict:
    """hd_agent before_insert + validate + before_save (store-only slice).

    before_insert: default availability from HD Settings when unset.
    validate: the availability must be an enabled status.
    before_save: stamp availability_changed_on/by (an insert IS a change).
    set_user_roles (grant Agent) maps to AVA RBAC — noted, not written here."""
    availability = payload.get("availability") or agent_status.get_default_agent_status(db, tid)
    _validate_availability(db, tid, availability)
    user = payload["user"]
    row = HDAgent(
        tenant_id=tid,
        user=user,
        agent_name=payload.get("agent_name") or user,
        user_image=payload.get("user_image"),
        is_active=payload.get("is_active", True),
        availability=availability,
        availability_changed_on=func.now(),
        availability_changed_by=actor,
    )
    db.add(row)
    db.commit()
    return {"ok": True, "name": row.user}


def set_agent_availability(db: Session, tid: int, user: str, availability: str,
                           actor: str | None) -> dict:
    """hd_agent validate_availability + before_save change-stamp (the field that
    changed is availability)."""
    a = _get_agent(db, tid, user)
    if not a:
        raise HTTPException(status_code=404, detail="not found")
    if a.availability != availability:
        _validate_availability(db, tid, availability)
        a.availability = availability
        a.availability_changed_on = func.now()
        a.availability_changed_by = actor
        db.commit()
    return {"ok": True}


def set_agent_active(db: Session, tid: int, user: str, is_active: bool) -> dict:
    """HD Agent.is_active toggle (the Active/Inactive dot, §A6)."""
    a = _get_agent(db, tid, user)
    if not a:
        raise HTTPException(status_code=404, detail="not found")
    a.is_active = is_active
    db.commit()
    return {"ok": True}


def update_agent_role(db: Session, tid: int, user: str, new_role: str) -> dict:
    """hd_agent.update_agent_role. Frappe granted/removed the Agent / Agent Manager
    / System Manager roles on the User. In AVA that maps to the native RBAC
    (UserRole/Role) which is NOT written from this module — see module docstring.
    This validates the request and the agent's existence; no role is granted here."""
    if new_role not in ("Agent", "Manager"):
        raise HTTPException(status_code=400, detail="Invalid role")
    if not _get_agent(db, tid, user):
        raise HTTPException(status_code=404, detail="not found")
    # NOTE: AVA RBAC grant intentionally not performed here (maps to UserRole rows).
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# WRITE — HD Customer (doctype/hd_customer/hd_customer.py + api/customer.py)
# ═══════════════════════════════════════════════════════════════════════════
class PrimaryContact(BaseModel):
    first_name: str | None = None
    last_name: str | None = None
    email: str | None = None
    mobile_no: str | None = None


class CustomerCreate(BaseModel):
    customer_name: str | None = None
    customer_type: str | None = None
    domain: str | None = None
    image: str | None = None
    country: str | None = None
    primary_contact: PrimaryContact | None = None


class CustomerUpdate(BaseModel):
    customer_name: str | None = None
    customer_type: str | None = None
    domain: str | None = None
    image: str | None = None
    country: str | None = None


class AddContacts(BaseModel):
    contacts: list[str]             # HDContact ids (§A9 `name`)
    role: str = "HD Customer"       # "HD Customer" | "HD Customer Manager"


class PrimaryBody(BaseModel):
    contact: str                    # HDContact id


def _get_customer(db: Session, tid: int, name: str) -> HDCustomer | None:
    try:
        pk = int(name)
    except (TypeError, ValueError):
        return None
    return (
        db.query(HDCustomer)
        .filter(HDCustomer.id == pk, HDCustomer.tenant_id == tid)
        .first()
    )


def _member(customer: HDCustomer, contact_id: int) -> HDCustomerMember | None:
    return next((m for m in customer.contacts if m.contact_id == contact_id), None)


def _add_member(db: Session, customer: HDCustomer, contact_id: int, is_manager: bool) -> bool:
    """hd_customer.add_contact — append membership; False if already a member."""
    existing = _member(customer, contact_id)
    if existing:
        if is_manager and not existing.is_manager:
            existing.is_manager = True
        return False
    db.add(HDCustomerMember(
        customer_id=customer.id, contact_id=contact_id,
        is_manager=is_manager, idx=len(customer.contacts) + 1,
    ))
    return True


def _set_primary(db: Session, customer: HDCustomer, contact_id: int) -> None:
    """hd_customer.set_primary — member-as-manager + primary pointer + fetched
    email/mobile (ensure_primary_contact_is_manager)."""
    _add_member(db, customer, contact_id, is_manager=True)
    customer.primary_contact = str(contact_id)
    c = db.query(HDContact).filter(
        HDContact.id == contact_id, HDContact.tenant_id == customer.tenant_id
    ).first()
    if c:
        customer.email_id = c.email_id
        customer.mobile_no = c.mobile_no or c.phone


def create_customer(db: Session, tid: int, payload: dict, actor: str | None) -> dict:
    """api/customer.create_customer (+ add_primary_contact). Creates the customer,
    then — when a primary contact with an email is supplied — reuses an existing
    contact for that email or creates one, adds it as manager and sets it primary.
    The external email invitation is noted, not sent (no invite store)."""
    row = HDCustomer(
        tenant_id=tid,
        customer_name=payload.get("customer_name"),
        customer_type=payload.get("customer_type"),
        domain=payload.get("domain"),
        image=payload.get("image"),
        country=payload.get("country"),
    )
    db.add(row)
    db.flush()                      # need row.id for membership

    pc = payload.get("primary_contact")
    if pc and pc.get("email"):
        contact = (
            db.query(HDContact)
            .filter(HDContact.tenant_id == tid, HDContact.email_id == pc["email"])
            .first()
        )
        if not contact:
            contact = HDContact(
                tenant_id=tid,
                first_name=pc.get("first_name"),
                last_name=pc.get("last_name"),
                email_id=pc["email"],
                mobile_no=pc.get("mobile_no"),
            )
            db.add(contact)
            db.flush()
        _set_primary(db, row, contact.id)

    db.commit()
    return {"ok": True, "name": str(row.id)}


def update_customer(db: Session, tid: int, name: str, payload: dict) -> dict:
    c = _get_customer(db, tid, name)
    if not c:
        raise HTTPException(status_code=404, detail="not found")
    for field in ("customer_name", "customer_type", "domain", "image", "country"):
        if payload.get(field) is not None:
            setattr(c, field, payload[field])
    db.commit()
    return {"ok": True}


def delete_customer(db: Session, tid: int, name: str, delete_tickets: bool = False) -> dict:
    """api/customer.delete_customer + hd_customer.on_trash(unlink_tickets). Tickets
    are deleted when the flag is set, otherwise their customer link is cleared;
    membership rows cascade with the customer. ERPNext/invitation unlink skipped."""
    c = _get_customer(db, tid, name)
    if not c:
        raise HTTPException(status_code=404, detail="not found")
    tq = db.query(HDTicket).filter(HDTicket.tenant_id == tid, HDTicket.customer_id == c.id)
    if delete_tickets:
        tq.delete(synchronize_session=False)
    else:
        tq.update({HDTicket.customer_id: None}, synchronize_session=False)
    db.delete(c)
    db.commit()
    return {"ok": True}


def add_customer_contacts(db: Session, tid: int, name: str, contact_ids: list[str],
                          role: str = "HD Customer") -> dict:
    """hd_customer.add_contacts. Entries that resolve to a known contact are added
    directly; the manager flag follows the role. Email-only invites are noted, not
    sent. validate_contact_update_permission's role check is kept."""
    if role not in CUSTOMER_ROLES:
        raise HTTPException(status_code=400, detail=f"Invalid role {role}")
    c = _get_customer(db, tid, name)
    if not c:
        raise HTTPException(status_code=404, detail="not found")
    is_manager = role == "HD Customer Manager"
    added = []
    for raw in dict.fromkeys(contact_ids):     # dedup within the batch (pending adds aren't in customer.contacts yet)
        try:
            cid = int(raw)
        except (TypeError, ValueError):
            continue
        contact = db.query(HDContact).filter(
            HDContact.id == cid, HDContact.tenant_id == tid
        ).first()
        if contact and _add_member(db, c, cid, is_manager):
            added.append(str(cid))
    db.commit()
    return {"ok": True, "added": added}


def remove_customer_contact(db: Session, tid: int, name: str, contact: str) -> dict:
    """hd_customer.remove_contact — drop membership; clear primary state if it was
    the primary contact (clear_primary)."""
    c = _get_customer(db, tid, name)
    if not c:
        raise HTTPException(status_code=404, detail="not found")
    try:
        cid = int(contact)
    except (TypeError, ValueError):
        raise HTTPException(status_code=404, detail="not found")
    m = _member(c, cid)
    if m:
        db.delete(m)
    if c.primary_contact == str(cid):
        c.primary_contact = None
        c.email_id = None
        c.mobile_no = None
    db.commit()
    return {"ok": True}


def set_customer_primary_contact(db: Session, tid: int, name: str, contact: str) -> dict:
    c = _get_customer(db, tid, name)
    if not c:
        raise HTTPException(status_code=404, detail="not found")
    try:
        cid = int(contact)
    except (TypeError, ValueError):
        raise HTTPException(status_code=404, detail="not found")
    _set_primary(db, c, cid)
    db.commit()
    return {"ok": True}


# ═══════════════════════════════════════════════════════════════════════════
# endpoints (people_write_router — not mounted yet, cutover is a later step)
# ═══════════════════════════════════════════════════════════════════════════
@people_write_router.post("/agents")
def agent_create(body: AgentCreate, db: Session = Depends(get_db),
                 current_user: GRCUser = Depends(require_auth), _: bool = Depends(require_edit)):
    return create_agent(db, tenant_id(db), body.model_dump(), actor=current_user.email)


@people_write_router.post("/agents/{user}/availability")
def agent_availability(user: str, body: AvailabilityBody, db: Session = Depends(get_db),
                       current_user: GRCUser = Depends(require_auth), _: bool = Depends(require_edit)):
    return set_agent_availability(db, tenant_id(db), user, body.availability, actor=current_user.email)


@people_write_router.post("/agents/{user}/active")
def agent_active(user: str, body: ActiveBody, db: Session = Depends(get_db),
                 _: bool = Depends(require_edit)):
    return set_agent_active(db, tenant_id(db), user, body.is_active)


@people_write_router.post("/agents/role")
def agent_role(body: AgentRoleBody, db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return update_agent_role(db, tenant_id(db), body.user, body.new_role)


@people_write_router.post("/customers")
def customer_create(body: CustomerCreate, db: Session = Depends(get_db),
                    current_user: GRCUser = Depends(require_auth), _: bool = Depends(require_edit)):
    return create_customer(db, tenant_id(db), body.model_dump(), actor=current_user.email)


@people_write_router.post("/customers/{name}/update")
def customer_update(name: str, body: CustomerUpdate, db: Session = Depends(get_db),
                    _: bool = Depends(require_edit)):
    return update_customer(db, tenant_id(db), name, body.model_dump(exclude_unset=True))


@people_write_router.delete("/customers/{name}")
def customer_delete(name: str, delete_tickets: bool = False, db: Session = Depends(get_db),
                    _: bool = Depends(require_edit)):
    return delete_customer(db, tenant_id(db), name, delete_tickets)


@people_write_router.post("/customers/{name}/contacts")
def customer_add_contacts(name: str, body: AddContacts, db: Session = Depends(get_db),
                          _: bool = Depends(require_edit)):
    return add_customer_contacts(db, tenant_id(db), name, body.contacts, body.role)


@people_write_router.delete("/customers/{name}/contacts/{contact}")
def customer_remove_contact(name: str, contact: str, db: Session = Depends(get_db),
                            _: bool = Depends(require_edit)):
    return remove_customer_contact(db, tenant_id(db), name, contact)


@people_write_router.post("/customers/{name}/primary-contact")
def customer_primary_contact(name: str, body: PrimaryBody, db: Session = Depends(get_db),
                             _: bool = Depends(require_edit)):
    return set_customer_primary_contact(db, tenant_id(db), name, body.contact)
