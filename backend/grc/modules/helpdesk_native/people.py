"""Agents / teams / customers / contacts — native read (§A6–§A9).

Tenant-scoped transcription of the Frappe-proxy people handlers onto AVA's own
tables (HDAgent / HDTeam+HDTeamMember / HDCustomer). Reads only; never 4xx on
empty — a tenant with no rows gets the documented empty shape (§E).

Two deliberate conversions from the proxy:
  * customers.contacts_count — the proxy hardcoded 0. There is no native contact
    store yet (HD Customer Member + the Contact doctype are deferred, see
    HELPDESK_NATIVE_MODEL_MAP.md), so the real count is derived from the only
    native signal that links a person to a customer: the distinct `contact`
    values on that customer's tickets.
  * contacts — same reason, the contact store isn't converted yet, so the honest
    native result is the empty shape (ticket.contact holds a bare email, none of
    the first/last/phone/company fields §A9 expects).
"""
from __future__ import annotations

from sqlalchemy import func
from sqlalchemy.orm import Session

from ...models import HDAgent, HDCustomer, HDTeam, HDTicket


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
    """§A8. contacts_count is COMPUTED (proxy hardcoded 0) — distinct ticket
    contacts per customer, one grouped query for the whole tenant."""
    counts = dict(
        db.query(HDTicket.customer_id, func.count(func.distinct(HDTicket.contact)))
        .filter(
            HDTicket.tenant_id == tid,
            HDTicket.customer_id.isnot(None),
            HDTicket.contact.isnot(None),
        )
        .group_by(HDTicket.customer_id)
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
    """§A9. No native contact store yet (deferred — see module docstring), so the
    honest result is the empty shape; the UI renders it fine (§E)."""
    return {"contacts": []}
