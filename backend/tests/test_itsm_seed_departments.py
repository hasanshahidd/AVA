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

from grc.models import HDDepartment
from grc.modules.helpdesk_native.itsm_seed import (
    _DEPARTMENTS, _DEPT_STD, _ensure_departments,
)

TENANT = 1


@pytest.fixture
def db():
    engine = create_engine("sqlite://")
    HDDepartment.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    yield s
    s.close()


def test_reuses_and_canonicalises_alias_rows_without_duplicating(db):
    # Pre-existing strays an earlier seed/import could have left: short names, no code.
    db.add(HDDepartment(tenant_id=TENANT, name="Finance", enabled=True))
    db.add(HDDepartment(tenant_id=TENANT, name="HR", enabled=True))
    db.commit()

    out = _ensure_departments(db, TENANT)

    rows = db.query(HDDepartment).filter(HDDepartment.tenant_id == TENANT).all()
    names = sorted(r.name for r in rows)
    # Exactly one row per catalogue department — the strays were reused, not twinned.
    assert len(rows) == len(_DEPARTMENTS)
    assert names == sorted(_DEPT_STD[s][0] for s in _DEPARTMENTS)
    # The alias rows were healed to the standard name + code, same ids returned.
    fin = db.query(HDDepartment).filter_by(tenant_id=TENANT, name="Finance & Accounting").one()
    hr = db.query(HDDepartment).filter_by(tenant_id=TENANT, name="Human Resources").one()
    assert fin.code == _DEPT_STD["Finance"][1] and hr.code == _DEPT_STD["HR"][1]
    assert out["Finance"] == fin.id and out["HR"] == hr.id
    assert db.query(HDDepartment).filter_by(tenant_id=TENANT, name="Finance").first() is None


def test_idempotent_second_pass_creates_nothing(db):
    _ensure_departments(db, TENANT)
    first = db.query(HDDepartment).filter(HDDepartment.tenant_id == TENANT).count()
    _ensure_departments(db, TENANT)
    second = db.query(HDDepartment).filter(HDDepartment.tenant_id == TENANT).count()
    assert first == second == len(_DEPARTMENTS)
