"""Asset change journal: the before_flush listener records every real change
with its source, on a real SQLAlchemy session (sqlite)."""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from grc.models import AuditLog, ITAsset
from grc.services.asset_change_log import (
    CATEGORIES, FIELD_CATEGORIES, TRACKED_FIELDS, change_source, mark_source,
)


@pytest.fixture()
def db():
    eng = create_engine("sqlite://")
    ITAsset.__table__.metadata.create_all(eng, tables=[ITAsset.__table__, AuditLog.__table__])
    s = sessionmaker(bind=eng, autoflush=False, future=True)()
    yield s
    s.close()


def _asset(db, **kw):
    a = ITAsset(tenant_id=1, name="web01", asset_type="server", **kw)
    db.add(a)
    db.commit()
    return a


def _rows(db):
    return db.query(AuditLog).filter(AuditLog.action == "asset.updated").order_by(AuditLog.id).all()


def test_every_tracked_field_is_categorised():
    assert len(TRACKED_FIELDS) == 37
    assert set(FIELD_CATEGORIES.values()) == set(CATEGORIES)
    assert all(hasattr(ITAsset, f) for f in TRACKED_FIELDS)


def test_context_label_and_exact_old_values_after_commit(db):
    a = _asset(db, os_family="linux")
    with change_source("discovery"):
        a.os_version, a.primary_mac = "22.04", "aa:bb:cc:dd:ee:ff"
    db.commit()
    (row,) = _rows(db)
    assert row.resource_type == "it_asset" and row.resource_id == a.id
    assert row.changes["source"] == "discovery"
    by = {f["field"]: f for f in row.changes["fields"]}
    assert by["os_version"] == {"field": "os_version", "category": "platform", "old": None, "new": "22.04"}
    assert by["primary_mac"]["category"] == "identity"


def test_explicit_mark_carries_actor(db):
    a = _asset(db)
    mark_source(a, "manual", user_id=7)
    a.name = "web01-renamed"
    db.commit()
    (row,) = _rows(db)
    assert (row.user_id, row.changes["source"]) == (7, "manual")
    assert row.changes["fields"][0] == {"field": "name", "category": "identity", "old": "web01", "new": "web01-renamed"}


def test_decorated_writer_labels_its_changes(db):
    a = _asset(db, criticality="low")

    @change_source("connector")
    def sync(asset):
        asset.criticality = "high"

    sync(a)
    db.commit()
    assert _rows(db)[0].changes["source"] == "connector"


def test_unlabelled_change_outside_request_is_system(db):
    a = _asset(db)
    a.location = "DC-2"
    db.commit()
    assert _rows(db)[0].changes["source"] == "system"


def test_no_row_for_noop_or_untracked_change(db):
    a = _asset(db, status="active")
    a.status = "active"
    a.platform_properties = {"x": 1}  # untracked column
    db.commit()
    assert _rows(db) == []


def test_unknown_source_is_normalised(db):
    a = _asset(db)
    with change_source("bogus"):
        a.location = "HQ"
    db.commit()
    assert _rows(db)[0].changes["source"] == "system"


def test_savepoint_rollback_drops_its_journal_row(db):
    a = _asset(db, location="HQ")
    with db.begin_nested() as sp:
        with change_source("connector"):
            a.location = "DC-9"
        db.flush()
        sp.rollback()
    db.commit()
    assert _rows(db) == []


def test_label_never_leaks_onto_a_later_change(db):
    a = _asset(db)
    mark_source(a, "manual", user_id=7)   # PUT that changes nothing tracked
    a.status = a.status
    db.flush()
    with change_source("discovery"):
        a.location = "X"
    a.location = "HQ"                      # later unlabelled write clears the stale label
    db.commit()
    (row,) = _rows(db)
    assert (row.changes["source"], row.user_id) == ("system", None)


def test_listener_failure_never_breaks_the_write(db, monkeypatch):
    import grc.services.asset_change_log as acl
    monkeypatch.setattr(acl, "_field_changes", lambda a: 1 / 0)
    a = _asset(db)
    a.location = "HQ"
    db.commit()                            # the asset write still lands
    db.refresh(a)
    assert a.location == "HQ" and _rows(db) == []
