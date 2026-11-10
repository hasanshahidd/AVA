"""Asset change journal: the before_flush listener records every real change
with its source, on a real SQLAlchemy session (sqlite)."""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from grc.models import AuditLog, ITAsset
from grc.services.asset_change_log import (
    CATEGORIES, COLUMN_CATEGORIES, SECTION_CATEGORIES, TRACKED_COLUMNS, change_source, mark_source,
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


def test_every_asset_column_is_journalled_and_categorised():
    # Every column except bookkeeping is tracked, and each has an explicit
    # asset-record category (a new column must be filed, not land in "other").
    assert {"platform_properties", "security_posture", "purchase_cost", "owning_team_id"} <= set(TRACKED_COLUMNS)
    assert not {"id", "tenant_id", "created_at", "last_seen_at"} & set(TRACKED_COLUMNS)
    uncategorised = [c for c in TRACKED_COLUMNS if c != "platform_properties" and c not in COLUMN_CATEGORIES]
    assert uncategorised == []
    assert set(COLUMN_CATEGORIES.values()) | set(SECTION_CATEGORIES.values()) <= set(CATEGORIES)


def test_context_label_and_exact_old_values_after_commit(db):
    a = _asset(db, os_family="linux")
    with change_source("discovery"):
        a.os_version, a.primary_mac = "22.04", "aa:bb:cc:dd:ee:ff"
    db.commit()
    (row,) = _rows(db)
    assert row.resource_type == "it_asset" and row.resource_id == a.id
    assert row.changes["source"] == "discovery"
    by = {f["field"]: f for f in row.changes["fields"]}
    assert by["os_version"] == {"field": "os_version", "section": "os_version", "category": "software",
                                "change": "changed", "old": None, "new": "22.04"}
    assert by["primary_mac"]["category"] == "identity"


def test_explicit_mark_carries_actor(db):
    a = _asset(db)
    mark_source(a, "manual", user_id=7)
    a.name = "web01-renamed"
    db.commit()
    (row,) = _rows(db)
    assert (row.user_id, row.changes["source"]) == (7, "manual")
    f = row.changes["fields"][0]
    assert (f["field"], f["category"], f["old"], f["new"]) == ("name", "identity", "web01", "web01-renamed")


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
    a.last_seen_source = "agent"      # bookkeeping column, not journalled
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
    monkeypatch.setattr(acl, "diff_asset", lambda a: 1 / 0)
    a = _asset(db)
    a.location = "HQ"
    db.commit()                            # the asset write still lands
    db.refresh(a)
    assert a.location == "HQ" and _rows(db) == []


def _pp(**sections):
    return {k: {"status": "discovered", "collected_at": "t0", "data": v} for k, v in sections.items()}


def test_telemetry_is_deep_diffed_by_asset_record_category(db):
    a = _asset(db, platform_properties=_pp(
        cpu={"model": "Xeon E5", "cores": 8, "load_percentage": 12},
        memory={"total_gb": 32, "available_gb": 20},
        packages={"items": [{"name": "openssl", "version": "3.0.2"}, {"name": "curl", "version": "7.81"}]},
        defender={"real_time_protection_enabled": True},
        local_users=[{"name": "admin", "enabled": True}],
        identity={"uptime_hours": 10, "bios_version": "1.2"},
    ))
    with change_source("scan"):
        a.platform_properties = _pp(
            cpu={"model": "Xeon E5", "cores": 16, "load_percentage": 88},          # cores real, load volatile
            memory={"total_gb": 32, "available_gb": 2},                           # volatile only
            packages={"items": [{"name": "openssl", "version": "3.0.13"},          # upgraded
                                {"name": "nginx", "version": "1.24"}]},            # curl removed, nginx added
            defender={"real_time_protection_enabled": False},
            local_users=[{"name": "admin", "enabled": True}, {"name": "svc_backup", "enabled": True}],
            identity={"uptime_hours": 99, "bios_version": "1.2"},                 # volatile only
        )
    db.commit()
    (row,) = _rows(db)
    by = {f["field"]: f for f in row.changes["fields"]}
    assert set(by) == {
        "cpu.data.cores", "packages.data.items[openssl].version", "packages.data.items[curl]",
        "packages.data.items[nginx]", "defender.data.real_time_protection_enabled", "local_users.data[svc_backup]",
    }
    assert by["cpu.data.cores"]["category"] == "hardware"
    assert by["packages.data.items[openssl].version"] == {
        "field": "packages.data.items[openssl].version", "section": "packages", "category": "software",
        "change": "changed", "old": "3.0.2", "new": "3.0.13"}
    assert (by["packages.data.items[curl]"]["change"], by["packages.data.items[curl]"]["old"]) == ("removed", "curl 7.81")
    assert (by["packages.data.items[nginx]"]["change"], by["packages.data.items[nginx]"]["new"]) == ("added", "nginx 1.24")
    assert by["defender.data.real_time_protection_enabled"]["category"] == "security"
    assert by["local_users.data[svc_backup]"]["change"] == "added"
    assert row.changes["sections"]["packages"] == {"category": "software", "added": 1, "removed": 1, "changed": 1}
    assert row.changes["source"] == "scan" and row.changes["total_fields"] == 6


def test_volatile_only_rescan_writes_nothing(db):
    a = _asset(db, platform_properties=_pp(memory={"total_gb": 32, "free_gb": 9}, identity={"uptime_hours": 1}))
    a.platform_properties = _pp(memory={"total_gb": 32, "free_gb": 3}, identity={"uptime_hours": 50})
    db.commit()
    assert _rows(db) == []


def test_business_procurement_and_json_columns(db):
    a = _asset(db, known_ips=["10.0.0.1"])
    a.purchase_cost, a.cde_environment, a.known_ips = 1200.0, True, ["10.0.0.1", "10.0.0.2"]
    a.security_posture = {"has_antivirus": True}
    db.commit()
    by = {(f["field"], f["change"]): f for f in _rows(db)[0].changes["fields"]}
    assert by[("purchase_cost", "changed")]["category"] == "procurement"
    assert by[("cde_environment", "changed")]["category"] == "business"
    assert by[("known_ips", "added")]["new"] == "10.0.0.2"
    assert by[("security_posture.has_antivirus", "changed")]["category"] == "security"


def test_huge_package_churn_is_capped_but_totals_are_complete(db):
    import grc.services.asset_change_log as acl
    a = _asset(db, platform_properties=_pp(packages=[{"name": f"p{i}", "version": "1"} for i in range(500)]))
    a.platform_properties = _pp(packages=[{"name": f"p{i}", "version": "2"} for i in range(500)])
    db.commit()
    ch = _rows(db)[0].changes
    assert len(ch["fields"]) == acl.MAX_FIELDS and ch["total_fields"] == 500
    assert ch["truncated"] == 500 - acl.MAX_FIELDS and ch["sections"]["packages"]["changed"] == 500


def test_history_reads_legacy_name_only_rows():
    from grc.routers.entity_extras_router import _with_categories
    rows = _with_categories(["confidentiality_rating", "is_internet_facing", {"field": "name", "old": "a", "new": "b"}])
    assert [(r["field"], r["category"], r.get("change")) for r in rows] == [
        ("confidentiality_rating", "business", "updated"), ("is_internet_facing", "identity", "updated"),
        ("name", "identity", None)]
