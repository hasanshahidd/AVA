"""Agent-console lifecycle fixes (overnight pass):

  * assign auto-transition: taking ownership of an un-worked ticket advances it
    from its entry status to the next working status where the seeded state
    machine allows it (incident New→Assigned), and only there (service_request at
    'Submitted' — whose only forward hop is the Paused approval gate — is left
    alone; 'change' is never auto-moved by assignment).
  * approved-advancement: opening an approval parks a service_request in its
    Paused waiting status (Submitted→Pending Approval); granting it releases the
    ticket to the next workflow status (Pending Approval→Approved) and resumes the
    SLA clock; a reject releases it to 'Rejected'.
  * set_status rejection stays a 200 {ok:false, error} dict (the FE guard surfaces
    res.data.error — chosen over raising, since change.complete_change / mail /
    replies all consume the dict return).

In-memory SQLite, direct function calls (mirrors the sibling helpdesk tests).
"""
import os

os.environ.setdefault("SESSION_SECRET", "test-lifecycle-assign-approval")

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from grc.models import (
    Tenant, HDTicket, HDTicketStatus, HDStateTransition, HDTicketActivity,
    HDApproval, HDApprovalVote, HDCommunication, HDTicketComment,
    HDServiceLevelAgreement, HDSLATarget, HDSettings, AuditLog,
)
from grc.modules.helpdesk_native import tickets, approvals, portal

TENANT = 1

# Statuses mirroring the seeded cyber_ava machine (subset we exercise).
_STATUSES = [
    # label, process, category, order
    ("New", "shared", "Open", 0),
    ("Assigned", "incident", "Open", 1),
    ("In Progress", "incident", "Open", 2),
    ("Submitted", "service_request", "Open", 0),
    ("Pending Approval", "service_request", "Paused", 1),
    ("Approved", "service_request", "Open", 2),
    ("Rejected", "shared", "Resolved", 7),
]
# from_label, to_label, process (guard empty)
_TRANSITIONS = [
    ("New", "Assigned", "incident"),
    ("Assigned", "In Progress", "incident"),
    ("Submitted", "Pending Approval", "service_request"),
    ("Pending Approval", "Approved", "service_request"),
    ("Pending Approval", "Rejected", "service_request"),
]


@pytest.fixture
def db():
    engine = create_engine("sqlite://")
    for m in (Tenant, HDTicket, HDTicketStatus, HDStateTransition, HDTicketActivity,
              HDApproval, HDApprovalVote, HDCommunication, HDTicketComment,
              HDServiceLevelAgreement, HDSLATarget, HDSettings, AuditLog):
        m.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    s.add(Tenant(id=TENANT, name="Acme", slug="acme"))
    by_label = {}
    for label, proc, cat, order in _STATUSES:
        st = HDTicketStatus(tenant_id=TENANT, label_agent=label, category=cat,
                            process=proc, order=order, enabled=True)
        s.add(st)
        s.flush()
        by_label[label] = st
    for frm, to, proc in _TRANSITIONS:
        s.add(HDStateTransition(tenant_id=TENANT, process=proc,
                                from_status_id=by_label[frm].id,
                                to_status_id=by_label[to].id))
    s.commit()
    s._by_label = by_label  # handy for assertions
    yield s
    s.close()


def _mk(db, process, status_label, **kw):
    st = db._by_label[status_label]
    t = HDTicket(tenant_id=TENANT, subject="x", process=process,
                 status_id=st.id, status_category=st.category, **kw)
    db.add(t)
    db.commit()
    return t


def _status_label(db, t):
    db.refresh(t)
    return db.query(HDTicketStatus).get(t.status_id).label_agent


# ─── 3(a) assign auto-transition ─────────────────────────────────────────────
def test_assign_advances_new_incident_to_assigned(db):
    t = _mk(db, "incident", "New")
    r = tickets.assign(db, TENANT, str(t.id), agent="agent@x.com", team=None)
    assert r["ok"] is True
    assert _status_label(db, t) == "Assigned"


def test_clearing_assignee_does_not_advance(db):
    t = _mk(db, "incident", "New")
    tickets.assign(db, TENANT, str(t.id), agent=None, team=None)
    assert _status_label(db, t) == "New"


def test_reassign_in_progress_incident_does_not_move(db):
    # already past the entry status → stays put (not the entry, so no advance)
    t = _mk(db, "incident", "In Progress")
    tickets.assign(db, TENANT, str(t.id), agent="agent@x.com", team=None)
    assert _status_label(db, t) == "In Progress"


def test_assign_service_request_does_not_skip_approval_gate(db):
    # Submitted's only forward hop is the Paused 'Pending Approval' → not Open, so
    # assignment must NOT advance it (the approval gate still runs).
    t = _mk(db, "service_request", "Submitted")
    tickets.assign(db, TENANT, str(t.id), agent="agent@x.com", team=None)
    assert _status_label(db, t) == "Submitted"


# ─── 3(b) approval → status advancement ──────────────────────────────────────
def test_open_approval_parks_sr_in_pending_approval(db):
    t = _mk(db, "service_request", "Submitted")
    approvals.open_approval(db, TENANT, t, kind="request", required_quorum=1)
    db.commit()
    assert t.approval_state == "pending_approval"
    assert _status_label(db, t) == "Pending Approval"
    assert t.status_category == "Paused"


def test_granting_approval_releases_sr_to_approved(db):
    t = _mk(db, "service_request", "Submitted", raised_by="req@x.com")
    ap = approvals.open_approval(db, TENANT, t, kind="request", required_quorum=1)
    db.commit()
    approvals.cast_vote(db, TENANT, ap.id, "approver@x.com", "approve")
    db.commit()
    assert ap.state == "approved"
    assert t.approval_state == "approved"
    assert _status_label(db, t) == "Approved"
    assert t.status_category == "Open"


def test_rejecting_approval_releases_sr_to_rejected(db):
    t = _mk(db, "service_request", "Submitted", raised_by="req@x.com")
    ap = approvals.open_approval(db, TENANT, t, kind="request", required_quorum=1)
    db.commit()
    approvals.cast_vote(db, TENANT, ap.id, "approver@x.com", "reject")
    db.commit()
    assert ap.state == "rejected"
    assert t.approval_state == "rejected"
    assert _status_label(db, t) == "Rejected"


def test_approval_resumes_sla_pause_conditions(db):
    # sla.recompute pauses while (status Paused) OR (approval_state ==
    # 'pending_approval'); it resumes once BOTH clear. Confirm the release flips
    # both so the clock is free to resume (no SLA policy needed to prove the gate).
    t = _mk(db, "service_request", "Submitted", raised_by="req@x.com")
    ap = approvals.open_approval(db, TENANT, t, kind="request", required_quorum=1)
    db.commit()
    assert t.status_category == "Paused" and t.approval_state == "pending_approval"  # paused
    approvals.cast_vote(db, TENANT, ap.id, "approver@x.com", "approve")
    db.commit()
    assert t.status_category == "Open" and t.approval_state == "approved"  # both clear → resumes


# ─── 1 set_status rejection contract (FE-guard approach b) ───────────────────
def test_set_status_illegal_transition_returns_ok_false_dict(db):
    # New→Approved is not a seeded incident transition → logical rejection as a
    # 200 {ok:false, error}, which the FE act() helper now surfaces instead of a
    # success toast.
    t = _mk(db, "incident", "New")
    r = tickets.set_status(db, TENANT, str(t.id), "Approved")
    assert r["ok"] is False
    assert "illegal transition" in (r.get("error") or "")
    assert _status_label(db, t) == "New"  # nothing changed


# ─── 2 portal detail approval summary ────────────────────────────────────────
def test_portal_approval_summary_surfaces_state_and_vote_gate(db):
    t = _mk(db, "service_request", "Submitted", raised_by="req@x.com")
    ap = approvals.open_approval(db, TENANT, t, kind="request", required_quorum=1)
    db.commit()
    # the raiser may NOT vote on their own request (SoD)
    mine = portal._approval_summary(db, TENANT, t.id, "req@x.com")
    assert mine["state"] == "pending" and mine["can_vote"] is False
    # a different approver can act, and sees the quorum/tally
    other = portal._approval_summary(db, TENANT, t.id, "approver@x.com")
    assert other["can_vote"] is True
    assert other["required_quorum"] == 1 and other["approve_count"] == 0
    # once decided, nobody can still act via the summary
    approvals.cast_vote(db, TENANT, ap.id, "approver@x.com", "approve")
    db.commit()
    done = portal._approval_summary(db, TENANT, t.id, "approver@x.com")
    assert done["state"] == "approved" and done["can_vote"] is False


def test_portal_approval_summary_none_without_approval(db):
    t = _mk(db, "incident", "New")
    assert portal._approval_summary(db, TENANT, t.id, "x@x.com") is None
