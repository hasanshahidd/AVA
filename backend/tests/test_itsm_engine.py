"""Flow/engine tests (Phase 2b). Piece #1: priority auto-compute — the ticket's
P-level is derived server-side from the tenant's own ingested priority matrix
(grc_hd_priority_matrix, seeded from the workbook), with the built-in ITIL names
as a fallback only when the tenant has no matrix row for that cell.

DB harness mirrors tests/test_itsm_import.py: in-memory SQLite, create just the
tables under test.
"""
import os

os.environ.setdefault("SESSION_SECRET", "test-engine")  # tickets.py imports auth_router

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from types import SimpleNamespace

from grc.models import HDTicketPriority, HDPriorityMatrix, HDTicketStatus, HDStateTransition
from grc.modules.helpdesk_native.tickets import priority_from_matrix, transition_allowed

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
