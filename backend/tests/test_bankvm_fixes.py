"""Regressions found by the on-prem bank install test (Nov 2026)."""
from pydantic import BaseModel, EmailStr

import grc.main  # noqa: F401  (applies the .local e-mail allowance)
from grc.modules.helpdesk_native.router import TicketCreate
from grc.modules.vuln_management.routers import vulnerabilities as vr


class _M(BaseModel):
    e: EmailStr


def test_local_mail_domain_accepted():
    assert _M(e="sara@jsbl.local").e == "sara@jsbl.local"


def test_ticket_create_keeps_problem_and_change_fields():
    d = TicketCreate(subject="x", process="change", implementation_plan="p", backout_plan="b",
                     root_cause="rc", linked_incident_ids=[1, 2]).model_dump()
    assert d["implementation_plan"] == "p" and d["backout_plan"] == "b"
    assert d["root_cause"] == "rc" and d["linked_incident_ids"] == [1, 2]


def test_vuln_id_route_does_not_swallow_exception_queue():
    paths = [r.path for r in vr.router.routes]
    assert "/vulnerabilities/{vuln_id:int}" in paths
    assert "/vulnerabilities/{vuln_id}" not in paths
    assert "/vulnerabilities/exception-queue" in paths
