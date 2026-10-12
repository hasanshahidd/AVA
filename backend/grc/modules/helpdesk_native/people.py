"""Agents / teams / customers / contacts — STUB. Filled by the people agent.

Each returns the §A6–§A9 empty shape so the router wires the full surface and
the UI renders (empty lists, never 4xx — §E). TODO(convert): people — read
HDAgent / HDTeam(+members) / HDCustomer and compute customers.contacts_count;
contacts map onto AVA's own contact/user store.
"""
from __future__ import annotations

from sqlalchemy.orm import Session


def list_agents(db: Session, tid: int) -> dict:
    return {"agents": []}


def list_teams(db: Session, tid: int) -> dict:
    return {"teams": []}


def list_customers(db: Session, tid: int) -> dict:
    return {"customers": []}


def list_contacts(db: Session, tid: int) -> dict:
    return {"contacts": []}
