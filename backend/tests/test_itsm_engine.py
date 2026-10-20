"""Flow/engine tests (Phase 2b). Piece #1: priority auto-compute — the ticket's
P-level is derived server-side from the tenant's own ingested priority matrix
(grc_hd_priority_matrix, seeded from the workbook), with the built-in ITIL names
as a fallback only when the tenant has no matrix row for that cell.

DB harness mirrors tests/test_itsm_import.py: in-memory SQLite, create just the
tables under test.
"""
import os

os.environ.setdefault("SESSION_SECRET", "test-engine")  # tickets.py imports auth_router

from datetime import datetime, timedelta

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from types import SimpleNamespace

from grc.models import (
    HDTicketPriority, HDPriorityMatrix, HDTicketStatus, HDStateTransition, HDTicket,
    HDApproval, HDApprovalVote, HDChangeType, HDChangeRiskMatrix,
)
from grc.models import HDSLATarget, HDServiceLevelAgreement, HDTicketCI
from grc.modules.helpdesk_native.tickets import (
    priority_from_matrix, transition_allowed, update, update_ticket,
)
from grc.modules.helpdesk_native import approvals, sla

TENANT = 1


@pytest.fixture
def db():
    engine = create_engine("sqlite://")
    for m in (HDTicketPriority, HDPriorityMatrix):
        m.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


def seed_priorities(db):
    rows = {
        "Urgent": HDTicketPriority(tenant_id=TENANT, name="Urgent", level="Urgent", code="P1", rank=1),
        "Medium": HDTicketPriority(tenant_id=TENANT, name="Medium", level="Medium", code="P3", rank=3),
        "Planning": HDTicketPriority(tenant_id=TENANT, name="Planning", level="Low", code="P5", rank=5),
    }
    for r in rows.values():
        db.add(r)
    db.commit()
    return {k: v.id for k, v in rows.items()}


def test_db_matrix_cell_resolves(db):
    ids = seed_priorities(db)
    db.add(HDPriorityMatrix(tenant_id=TENANT, impact="high", urgency="high", priority_id=ids["Urgent"]))
    db.commit()
    # case-insensitive match against the ingested cell
    assert priority_from_matrix(db, TENANT, "High", "High") == ids["Urgent"]


def test_db_matrix_overrides_builtin(db):
    # built-in matrix says high/high -> "Urgent"; the tenant's ingested cell says
    # high/high -> "Planning". The ingested (owner-authored) cell must win.
    ids = seed_priorities(db)
    db.add(HDPriorityMatrix(tenant_id=TENANT, impact="high", urgency="high", priority_id=ids["Planning"]))
    db.commit()
    assert priority_from_matrix(db, TENANT, "high", "high") == ids["Planning"]


def test_fallback_to_builtin_when_no_cell(db):
    # no matrix rows at all -> fall back to the built-in names. low/high -> "Medium".
    ids = seed_priorities(db)
    assert db.query(HDPriorityMatrix).count() == 0
    assert priority_from_matrix(db, TENANT, "low", "high") == ids["Medium"]


def test_unknown_cell_returns_none(db):
    seed_priorities(db)
    assert priority_from_matrix(db, TENANT, "banana", "squid") is None
    assert priority_from_matrix(db, TENANT, None, None) is None


def test_tenant_isolation(db):
    ids = seed_priorities(db)
    db.add(HDPriorityMatrix(tenant_id=TENANT, impact="high", urgency="high", priority_id=ids["Urgent"]))
    db.commit()
    # a different tenant has no matrix row -> falls back to built-in, not tenant 1's cell
    assert priority_from_matrix(db, 999, "high", "high") is None


# ─── piece #2: data-driven state-transition enforcement ──────────────────────
@pytest.fixture
def sdb():
    engine = create_engine("sqlite://")
    for m in (HDTicketStatus, HDStateTransition):
        m.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


def seed_states(sdb):
    st = {}
    for lbl in ("New", "Assigned", "Pending", "Resolved"):
        row = HDTicketStatus(tenant_id=TENANT, label_agent=lbl, category="Open")
        sdb.add(row); st[lbl] = row
    sdb.flush()
    def tr(a, b, guard=None):
        sdb.add(HDStateTransition(tenant_id=TENANT, process="incident",
                                  from_status_id=st[a].id, to_status_id=st[b].id, guard=guard))
    tr("New", "Assigned"); tr("Assigned", "Resolved"); tr("Assigned", "Pending")
    tr("Pending", "Resolved", guard="approved")
    sdb.commit()
    return {k: v.id for k, v in st.items()}


def tk(status_id, process="incident", approval_state=None):
    return SimpleNamespace(status_id=status_id, process=process, approval_state=approval_state)


def test_legal_transition_allowed(sdb):
    ids = seed_states(sdb)
    ok, reason = transition_allowed(sdb, TENANT, tk(ids["New"]), SimpleNamespace(id=ids["Assigned"], label_agent="Assigned"))
    assert ok and reason is None


def test_illegal_transition_rejected(sdb):
    ids = seed_states(sdb)
    ok, reason = transition_allowed(sdb, TENANT, tk(ids["New"]), SimpleNamespace(id=ids["Resolved"], label_agent="Resolved"))
    assert not ok and "illegal transition" in reason


def test_noop_same_status_allowed(sdb):
    ids = seed_states(sdb)
    ok, _ = transition_allowed(sdb, TENANT, tk(ids["New"]), SimpleNamespace(id=ids["New"], label_agent="New"))
    assert ok


def test_unseeded_process_not_enforced(sdb):
    ids = seed_states(sdb)
    # 'question' has no transitions seeded -> allow anything (legacy behaviour)
    ok, _ = transition_allowed(sdb, TENANT, tk(ids["New"], process="question"),
                               SimpleNamespace(id=ids["Resolved"], label_agent="Resolved"))
    assert ok


def test_guard_blocks_until_approved(sdb):
    ids = seed_states(sdb)
    to_resolved = SimpleNamespace(id=ids["Resolved"], label_agent="Resolved")
    # Pending -> Resolved carries guard 'approved'
    ok, reason = transition_allowed(sdb, TENANT, tk(ids["Pending"], approval_state=None), to_resolved)
    assert not ok and "approval" in reason
    ok2, _ = transition_allowed(sdb, TENANT, tk(ids["Pending"], approval_state="approved"), to_resolved)
    assert ok2


# ─── audit fixes: the label editor must not bypass #2, and impact/urgency edits
#     must re-derive priority (#1) ──────────────────────────────────────────────
@pytest.fixture
def tdb():
    engine = create_engine("sqlite://")
    for m in (HDTicket, HDTicketStatus, HDStateTransition, HDTicketPriority, HDPriorityMatrix):
        m.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


def test_update_editor_rejects_illegal_status(tdb):
    # New -> Assigned is the only legal incident move
    st = {}
    for lbl in ("New", "Assigned", "Resolved"):
        r = HDTicketStatus(tenant_id=TENANT, label_agent=lbl, category="Open")
        tdb.add(r); st[lbl] = r
    tdb.flush()
    tdb.add(HDStateTransition(tenant_id=TENANT, process="incident",
                              from_status_id=st["New"].id, to_status_id=st["Assigned"].id))
    t = HDTicket(tenant_id=TENANT, subject="x", process="incident",
                 status_id=st["New"].id, status_category="Open")
    tdb.add(t); tdb.commit()
    # the label editor (update) must reject an illegal jump, same as set_status
    res = update(tdb, TENANT, str(t.id), {"status": "Resolved"})
    assert res["ok"] is False and "illegal" in res["error"]
    tdb.refresh(t)
    assert t.status_id == st["New"].id      # nothing mutated on reject


def test_update_ticket_recomputes_priority_on_reclassify(tdb):
    p1 = HDTicketPriority(tenant_id=TENANT, name="Urgent", level="Urgent", code="P1", rank=1)
    tdb.add(p1); tdb.flush()
    tdb.add(HDPriorityMatrix(tenant_id=TENANT, impact="high", urgency="high", priority_id=p1.id))
    t = HDTicket(tenant_id=TENANT, subject="x", process="incident", status_category="Open")
    tdb.add(t); tdb.commit()
    assert t.priority_id is None
    # editing impact+urgency must re-derive the P-level from the matrix
    update_ticket(tdb, TENANT, t.id, {"impact": "high", "urgency": "high"})
    tdb.refresh(t)
    assert t.priority_id == p1.id and t.impact == "high" and t.urgency == "high"


# ─── piece #3: approvals / CAB engine ────────────────────────────────────────
@pytest.fixture
def adb():
    engine = create_engine("sqlite://")
    for m in (HDTicket, HDApproval, HDApprovalVote, HDChangeType, HDChangeRiskMatrix,
              HDTicketCI):
        m.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


def _change(adb, **kw):
    t = HDTicket(tenant_id=TENANT, subject="chg", process="change", status_category="Open", **kw)
    adb.add(t); adb.commit()
    return t


def test_open_approval_parks_ticket(adb):
    t = _change(adb)
    ap = approvals.open_approval(adb, TENANT, t, kind="cab", required_quorum=3,
                                 required_role_codes=["ROLE-CHGMGR", "ROLE-SVCOWN"])
    adb.commit()
    assert ap.state == "pending"
    adb.refresh(t)
    assert t.approval_state == "pending_approval"


def test_request_single_signoff_approves(adb):
    t = _change(adb)
    ap = approvals.open_approval(adb, TENANT, t, kind="request", required_quorum=1)
    approvals.cast_vote(adb, TENANT, ap.id, "mgr@x.com", "approve", role="ROLE-APPROVER")
    adb.commit()
    adb.refresh(t); adb.refresh(ap)
    assert ap.state == "approved" and t.approval_state == "approved"


def test_cab_needs_quorum_and_required_roles(adb):
    t = _change(adb)
    ap = approvals.open_approval(adb, TENANT, t, kind="cab", required_quorum=3,
                                 required_role_codes=["ROLE-CHGMGR", "ROLE-SVCOWN"])
    approvals.cast_vote(adb, TENANT, ap.id, "a@x.com", "approve", role="ROLE-CHGMGR")
    approvals.cast_vote(adb, TENANT, ap.id, "b@x.com", "approve", role="ROLE-SVCOWN")
    adb.refresh(ap)
    assert ap.state == "pending"        # only 2 of 3 quorum
    approvals.cast_vote(adb, TENANT, ap.id, "c@x.com", "approve", role="ROLE-TECH")
    adb.commit(); adb.refresh(ap); adb.refresh(t)
    assert ap.state == "approved" and t.approval_state == "approved"


def test_cab_blocks_when_required_role_absent(adb):
    t = _change(adb)
    ap = approvals.open_approval(adb, TENANT, t, kind="cab", required_quorum=2,
                                 required_role_codes=["ROLE-CHGMGR"])
    approvals.cast_vote(adb, TENANT, ap.id, "a@x.com", "approve", role="ROLE-TECH")
    approvals.cast_vote(adb, TENANT, ap.id, "b@x.com", "approve", role="ROLE-SME")
    adb.refresh(ap)
    assert ap.state == "pending"        # quorum met but Change Manager hasn't approved
    approvals.cast_vote(adb, TENANT, ap.id, "cm@x.com", "approve", role="ROLE-CHGMGR")
    adb.refresh(ap)
    assert ap.state == "approved"


def test_one_reject_fails_and_late_votes_ignored(adb):
    t = _change(adb)
    ap = approvals.open_approval(adb, TENANT, t, kind="cab", required_quorum=3)
    approvals.cast_vote(adb, TENANT, ap.id, "a@x.com", "reject", role="ROLE-CHGMGR", comment="too risky")
    adb.commit(); adb.refresh(ap); adb.refresh(t)
    assert ap.state == "rejected" and t.approval_state == "rejected"
    # a vote after the decision is a no-op
    approvals.cast_vote(adb, TENANT, ap.id, "b@x.com", "approve", role="ROLE-SVCOWN")
    adb.refresh(ap)
    assert ap.state == "rejected"


def test_revote_updates_in_place(adb):
    t = _change(adb)
    ap = approvals.open_approval(adb, TENANT, t, kind="request", required_quorum=1)
    approvals.cast_vote(adb, TENANT, ap.id, "a@x.com", "abstain")
    assert adb.query(HDApprovalVote).filter_by(approval_id=ap.id).count() == 1
    approvals.cast_vote(adb, TENANT, ap.id, "a@x.com", "approve")  # same approver changes mind
    adb.refresh(ap)
    assert adb.query(HDApprovalVote).filter_by(approval_id=ap.id).count() == 1
    assert ap.state == "approved"


def test_requirements_for_change(adb):
    adb.add(HDChangeType(tenant_id=TENANT, code="standard", name="Standard",
                         requires_cab=False, auto_approve=True))
    adb.add(HDChangeType(tenant_id=TENANT, code="normal", name="Normal", requires_cab=True))
    adb.add(HDChangeType(tenant_id=TENANT, code="emergency", name="Emergency", requires_cab=True))
    adb.add(HDChangeRiskMatrix(tenant_id=TENANT, impact="high", likelihood="high",
                               risk_level="high", cab_required=True))
    adb.commit()
    assert approvals.requirements_for_change(adb, TENANT, _change(adb, change_type="standard")) is None
    normal = approvals.requirements_for_change(adb, TENANT, _change(adb, change_type="normal"))
    assert normal["kind"] == "cab" and normal["required_quorum"] == 3
    assert "ROLE-CHGMGR" in normal["required_role_codes"]
    emer = approvals.requirements_for_change(adb, TENANT, _change(adb, change_type="emergency"))
    assert emer["kind"] == "ecab"
    # risk forces CAB even when the change type is unknown/unset
    risky = approvals.requirements_for_change(adb, TENANT, _change(adb, change_risk="high"))
    assert risky is not None and risky["kind"] == "cab"


# ─── piece #4: SLA clock from ingested targets (with pause) ───────────────────
@pytest.fixture
def sladb():
    engine = create_engine("sqlite://")
    for m in (HDTicket, HDTicketPriority, HDSLATarget, HDServiceLevelAgreement):
        m.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


def _sla_setup(sladb, created, resp=15, reso=240, window="24x7"):
    p1 = HDTicketPriority(tenant_id=TENANT, name="Urgent", level="Urgent", code="P1", rank=1)
    sladb.add(p1); sladb.flush()
    sladb.add(HDSLATarget(tenant_id=TENANT, process="incident", priority_label="P1 - Critical",
                          priority_code="P1", service_window=window,
                          response_minutes=resp, resolution_minutes=reso))
    t = HDTicket(tenant_id=TENANT, subject="x", process="incident", status_category="Open",
                 priority_id=p1.id, created_at=created)
    sladb.add(t); sladb.commit()
    return t


def test_sla_due_dates_from_ingested_target(sladb):
    created = datetime.utcnow()  # near-now so the deadlines are still in the future
    t = _sla_setup(sladb, created, resp=15, reso=240)
    sla.recompute(sladb, t)
    assert t.response_by == created + timedelta(minutes=15)
    assert t.resolution_by == created + timedelta(minutes=240)
    assert t.agreement_status == "First Response Due"
    assert t.sla_id is None


def test_sla_pause_freezes_then_extends_on_resume(sladb):
    created = datetime.utcnow()
    t = _sla_setup(sladb, created, resp=15, reso=240)
    sla.recompute(sladb, t)
    base_reso = t.resolution_by
    # pause
    t.status_category = "Paused"
    sla.recompute(sladb, t, prev_status_category="Open")
    assert t.agreement_status == "Paused" and t.on_hold_since is not None
    # simulate 30 minutes held, then resume
    t.on_hold_since = datetime.utcnow() - timedelta(minutes=30)
    t.status_category = "Open"
    sla.recompute(sladb, t, prev_status_category="Paused")
    # resolution deadline pushed out by ~the held 30 minutes
    assert t.on_hold_since is None and t.total_hold_time >= 29 * 60
    assert (t.resolution_by - base_reso) >= timedelta(minutes=29)


def test_sla_breach_marks_failed(sladb):
    created = datetime(2020, 1, 1, 9, 0, 0)  # long past → deadlines already blown
    t = _sla_setup(sladb, created, resp=15, reso=240)
    sla.recompute(sladb, t)
    assert t.agreement_status == "Failed"


def test_sla_pauses_while_pending_approval(sladb):
    # bridge to #3: an open approval (approval_state=pending_approval) freezes the SLA
    created = datetime.utcnow()
    t = _sla_setup(sladb, created, resp=15, reso=240)
    sla.recompute(sladb, t)
    assert t.agreement_status == "First Response Due"
    t.approval_state = "pending_approval"
    sla.recompute(sladb, t)
    assert t.agreement_status == "Paused" and t.on_hold_since is not None
    # decision resumes the clock and banks the held time
    t.on_hold_since = datetime.utcnow() - timedelta(minutes=20)
    t.approval_state = "approved"
    sla.recompute(sladb, t)
    assert t.on_hold_since is None and t.total_hold_time >= 19 * 60


def test_sla_no_target_clears_fields(sladb):
    # a process with no ingested target and no Frappe policy → no due dates
    t = HDTicket(tenant_id=TENANT, subject="x", process="problem", status_category="Open",
                 created_at=datetime(2026, 1, 1, 9, 0, 0))
    sladb.add(t); sladb.commit()
    sla.recompute(sladb, t)
    assert t.response_by is None and t.resolution_by is None
