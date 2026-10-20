"""_ensure_departments dedupe: a pre-existing short/alias-named department must be
REUSED and canonicalised, never duplicated alongside its standard-named twin (QA
found "Finance" + "Finance & Accounting" and "HR" + "Human Resources" side by
side on the seeded tenant).

DB harness mirrors tests/test_itsm_engine.py: in-memory SQLite, just the one table.
"""
import os

os.environ.setdefault("SESSION_SECRET", "test-seed")

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from grc.models import (
    HDChangeRiskMatrix, HDChangeType, HDDepartment, HDIncidentCategory,
    HDTicketFeedbackOption, HDTicketType,
)
from grc.modules.helpdesk_native.itsm_seed import (
    _CHANGE_TYPES, _DEPARTMENTS, _DEPT_STD, _FEEDBACK_OPTIONS, _INCIDENT_CATEGORIES,
    _RISK_MATRIX, _ensure_departments, ensure_governance_baseline,
)

TENANT = 1


@pytest.fixture
def db():
    engine = create_engine("sqlite://")
    HDDepartment.__table__.create(engine)
    HDTicketType.__table__.create(engine)  # one department_id FK table, to assert repoint
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


@pytest.fixture
def gov_db():
    engine = create_engine("sqlite://")
    for m in (HDChangeType, HDChangeRiskMatrix, HDIncidentCategory, HDTicketFeedbackOption):
        m.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


def test_governance_baseline_seeds_everything_once(gov_db):
    created = ensure_governance_baseline(gov_db, TENANT)
    assert created == (len(_CHANGE_TYPES) + len(_RISK_MATRIX)
                       + len(_INCIDENT_CATEGORIES) + len(_FEEDBACK_OPTIONS))
    # The approval engine keys off these: Standard auto-approves (no CAB), Emergency
    # always needs one. A missing/empty table silently breaks Change routing.
    std = gov_db.query(HDChangeType).filter_by(tenant_id=TENANT, code="standard").one()
    emg = gov_db.query(HDChangeType).filter_by(tenant_id=TENANT, code="emergency").one()
    assert std.auto_approve is True and std.requires_cab is False
    assert emg.requires_cab is True
    # low×low must be a non-CAB risk cell; high×high must force CAB.
    assert gov_db.query(HDChangeRiskMatrix).filter_by(
        tenant_id=TENANT, impact="low", likelihood="low").one().cab_required is False
    assert gov_db.query(HDChangeRiskMatrix).filter_by(
        tenant_id=TENANT, impact="high", likelihood="high").one().cab_required is True


def test_governance_baseline_is_idempotent(gov_db):
    ensure_governance_baseline(gov_db, TENANT)
    second = ensure_governance_baseline(gov_db, TENANT)
    assert second == 0
    assert gov_db.query(HDChangeType).filter_by(tenant_id=TENANT).count() == len(_CHANGE_TYPES)
    assert gov_db.query(HDTicketFeedbackOption).filter_by(tenant_id=TENANT).count() == len(_FEEDBACK_OPTIONS)


def test_merges_existing_alias_twins_and_repoints_fks(db):
    # The exact stray twins QA found on cyber_ava, side by side with the canonicals.
    for nm in ("Finance", "Finance & Accounting", "HR", "Human Resources",
               "IT", "IT Support", "Information Technology", "Legal", "Legal & Compliance"):
        db.add(HDDepartment(tenant_id=TENANT, name=nm, enabled=True))
    db.commit()
    stray_fin = db.query(HDDepartment).filter_by(tenant_id=TENANT, name="Finance").one()
    stray_it = db.query(HDDepartment).filter_by(tenant_id=TENANT, name="IT Support").one()
    # A ticket type pinned to a stray must follow the merge onto the survivor.
    db.add(HDTicketType(tenant_id=TENANT, name="Expense query", department_id=stray_fin.id))
    db.add(HDTicketType(tenant_id=TENANT, name="Laptop setup", department_id=stray_it.id))
    db.commit()

    out = _ensure_departments(db, TENANT)

    rows = db.query(HDDepartment).filter(HDDepartment.tenant_id == TENANT).all()
    names = sorted(r.name for r in rows)
    # Twins collapsed to exactly one canonical row each — no strays left.
    assert len(rows) == len(_DEPARTMENTS)
    assert names == sorted(_DEPT_STD[s][0] for s in _DEPARTMENTS)
    for gone in ("Finance", "HR", "IT", "IT Support", "Legal"):
        assert db.query(HDDepartment).filter_by(tenant_id=TENANT, name=gone).first() is None
    # The ticket types were repointed to the surviving canonical departments.
    assert db.query(HDTicketType).filter_by(name="Expense query").one().department_id == out["Finance"]
    assert db.query(HDTicketType).filter_by(name="Laptop setup").one().department_id == out["IT"]
    fin = db.query(HDDepartment).filter_by(tenant_id=TENANT, name="Finance & Accounting").one()
    assert fin.code == _DEPT_STD["Finance"][1] and out["Finance"] == fin.id


def test_idempotent_second_pass_creates_nothing(db):
    _ensure_departments(db, TENANT)
    first = db.query(HDDepartment).filter(HDDepartment.tenant_id == TENANT).count()
    _ensure_departments(db, TENANT)
    second = db.query(HDDepartment).filter(HDDepartment.tenant_id == TENANT).count()
    assert first == second == len(_DEPARTMENTS)
