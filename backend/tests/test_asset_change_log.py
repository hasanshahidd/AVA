"""Self-test for the asset field-level change journal."""
from types import SimpleNamespace

from grc.services.asset_change_log import (
    TRACKED_FIELDS, diff, record_asset_changes, snapshot,
)


class FakeDB:
    def __init__(self):
        self.added = []

    def add(self, x):
        self.added.append(x)


def _asset(**kw):
    base = {f: None for f in TRACKED_FIELDS}
    base.update(kw)
    base.setdefault("tenant_id", 1)
    base.setdefault("id", 5)
    return SimpleNamespace(**base)


def test_diff_detects_only_changed_fields():
    a = _asset(name="old", status="active")
    before = snapshot(a)
    a.name, a.status, a.criticality = "new", "inactive", "high"
    fields = {c["field"] for c in diff(before, snapshot(a))}
    assert fields == {"name", "status", "criticality"}


def test_record_writes_auditlog_with_source_and_diff():
    a = _asset(name="old")
    before = snapshot(a)
    a.name = "new"
    db = FakeDB()
    row = record_asset_changes(db, a, before, source="manual", user_id=9)
    assert row is not None and len(db.added) == 1
    assert row.action == "asset.updated"
    assert row.resource_type == "it_asset" and row.resource_id == 5
    assert row.changes["source"] == "manual"
    fld = row.changes["fields"][0]
    assert fld == {"field": "name", "old": "old", "new": "new"}


def test_record_noop_when_nothing_changed():
    a = _asset(name="x")
    db = FakeDB()
    assert record_asset_changes(db, a, snapshot(a), source="manual") is None
    assert db.added == []


def test_invalid_source_falls_back_to_manual():
    a = _asset(name="x")
    before = snapshot(a)
    a.name = "y"
    row = record_asset_changes(FakeDB(), a, before, source="bogus")
    assert row.changes["source"] == "manual"
