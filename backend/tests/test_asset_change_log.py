"""Asset change journal: the before_flush listener records every real change
with its source, on a real SQLAlchemy session (sqlite)."""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from grc.models import AuditLog, ITAsset
from grc.services.asset_change_log import (
    CATEGORIES, COLUMN_CATEGORIES, SECTION_CATEGORIES, TRACKED_COLUMNS, change_source, field_tracks, mark_source,
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


def test_estate_change_log_lists_changes_across_assets(db, monkeypatch):
    from types import SimpleNamespace
    import grc.routers.entity_extras_router as R
    a, b = _asset(db, location="HQ"), ITAsset(tenant_id=1, name="db02", asset_type="server")
    db.add(b); db.commit()
    with change_source("agent"):
        a.location = "DC-1"
        b.os_version = "22.04"
    db.commit()
    monkeypatch.setattr(R, "get_user_tenants", lambda u, d: [1])
    rows = R.asset_change_log(30, 300, db=db, current_user=SimpleNamespace(id=1))
    assert {(r.asset_name, r.source) for r in rows} == {("web01", "agent"), ("db02", "agent")}
    assert all(r.asset_id and r.fields for r in rows)


def test_agent_report_churn_is_not_journalled(db):
    pp = lambda ports, state, ts, speed: {
        "recon": {"status": "discovered", "data": {"open_ports": ports}},
        "services": {"status": "discovered", "data": [{"name": "Spooler", "state": state, "start_mode": "Auto"}]},
        "network": {"status": "discovered", "data": [{"name": "Wi-Fi", "speed_bps": speed, "gateway": "10.0.0.1"}]},
    }
    a = _asset(db, platform_properties=pp([{"port": 445, "proto": "tcp"}, {"port": 50001, "proto": "udp"}], "Running", "t1", 1),
               security_posture={"computed_at": "t1", "has_antivirus": True})
    a.platform_properties = pp([{"port": 445, "proto": "tcp"}, {"port": 61234, "proto": "udp"}], "Stopped", "t2", 9)
    a.security_posture = {"computed_at": "t2", "has_antivirus": True}
    db.commit()
    assert _rows(db) == []                                 # ephemeral port, run state, speed, computed_at
    a.platform_properties = pp([{"port": 445, "proto": "tcp"}, {"port": 3389, "proto": "tcp"}], "Stopped", "t3", 9)
    db.commit()
    (row,) = _rows(db)
    assert [(f["field"], f["change"]) for f in row.changes["fields"]] == [("recon.data.open_ports[3389/tcp]", "added")]


def test_history_read_hides_old_churn_rows():
    from types import SimpleNamespace
    from grc.routers.entity_extras_router import _history_row
    noise = SimpleNamespace(id=1, action="asset.updated", timestamp=None, user=None, changes={
        "source": "agent", "fields": [{"field": "security_posture.computed_at", "section": "security_posture",
                                       "category": "security", "old": "a", "new": "b"}],
        "sections": {"security_posture": {"category": "security", "added": 0, "removed": 0, "changed": 1}}, "total_fields": 1})
    assert _history_row(noise, {"user": {}, "asset": {}}) is None
    mixed = SimpleNamespace(**{**noise.__dict__, "changes": {**noise.changes, "fields": noise.changes["fields"] + [
        {"field": "ip_address", "section": "ip_address", "category": "identity", "old": "1", "new": "2"}], "total_fields": 2}})
    h = _history_row(mixed, {"user": {}, "asset": {}})
    assert h["total_fields"] == 1 and list(h["sections"]) == ["ip_address"]


def test_volume_free_space_wobble_is_not_add_remove(db):
    vols = lambda free: {"volumes": {"status": "discovered", "data": [
        {"filesystem": "NTFS", "drive_letter": "C:", "capacity_gb": 237, "free_gb": free},
        {"filesystem": "ext4", "capacity_gb": 50, "used_gb": 50 - free}]}}   # second one has no identity key
    a = _asset(db, platform_properties=vols(40))
    a.platform_properties = vols(31)
    db.commit()
    assert _rows(db) == []
    a.platform_properties = {"volumes": {"status": "discovered", "data": [
        {"filesystem": "NTFS", "drive_letter": "C:", "capacity_gb": 512, "free_gb": 3},
        {"filesystem": "ext4", "capacity_gb": 50, "used_gb": 9}]}}
    db.commit()
    (row,) = _rows(db)
    assert [(f["field"], f["change"]) for f in row.changes["fields"]] == [("volumes.data[C:].capacity_gb", "changed")]


def test_history_read_drops_identical_remove_add_pairs():
    from grc.services.asset_change_log import drop_churn
    same = "NTFS (drive_letter: C:, capacity_gb: 237)"
    pair = [
        {"field": 'volumes.data[{"capacity_gb": 237, "free_gb": 40}]', "section": "volumes", "change": "removed", "old": same, "new": None},
        {"field": 'volumes.data[{"capacity_gb": 237, "free_gb": 31}]', "section": "volumes", "change": "added", "old": None, "new": same},
    ]
    real = {"field": "volumes.data[D:]", "section": "volumes", "change": "added", "old": None, "new": "D: (capacity_gb: 1)"}
    assert drop_churn(pair) == []
    assert drop_churn(pair + [real]) == [real]
    moved = [{**pair[0], "field": "volumes.data[X]"}, {**pair[1], "field": "disks.data[X]"}]   # different list: kept
    assert drop_churn(moved) == moved


def test_shared_port_listeners_are_not_paired_by_order(db):
    ports = lambda *svcs: {"recon": {"status": "discovered", "data": {"open_ports": [
        {"port": 5353, "proto": "udp", "service": s} for s in svcs] + [{"port": 445, "proto": "tcp"}]}}}
    a = _asset(db, platform_properties=ports("chrome", "svchost"))
    a.platform_properties = ports("svchost", "chrome")          # same listeners, other order
    db.commit()
    assert _rows(db) == []
    a.platform_properties = ports("svchost", "msedge")
    db.commit()
    (row,) = _rows(db)
    assert sorted((f["field"], f["change"]) for f in row.changes["fields"]) == [
        ("recon.data.open_ports[5353/udp (chrome)]", "removed"), ("recon.data.open_ports[5353/udp (msedge)]", "added")]


def test_field_tracks_use_journal_paths_and_cover_every_column(db):
    a = _asset(db, location="HQ", platform_properties={
        "defender": {"status": "discovered", "data": {"realtime_protection": True, "signature_age_days": 2}},
        "storage": {"status": "discovered", "data": {"volumes": [{"drive_letter": "C:", "capacity_gb": 237, "free_gb": 9}]}},
        "processes": {"status": "discovered", "data": [{"name": "x"}]}})
    by = {t["path"]: t for t in field_tracks(a)}
    assert {c for c in TRACKED_COLUMNS if c != "platform_properties"} <= set(by)
    assert by["location"] == {"path": "location", "section": "location", "category": "ownership",
                              "kind": "value", "value": "HQ", "count": None}
    assert by["defender.data.realtime_protection"]["category"] == "security"
    assert by["defender.data.signature_age_days"]["kind"] == "value"
    vols = by["storage.data.volumes"]
    assert vols["kind"] == "list" and vols["count"] == 1 and vols["category"] == "hardware"
    assert not any(p.startswith("processes") for p in by)        # volatile section never listed
    # Same naming as the journal: a real change lands on a listed path.
    a.platform_properties = {**a.platform_properties,
                             "defender": {"status": "discovered", "data": {"realtime_protection": False}}}
    db.commit()
    assert "defender.data.realtime_protection" in {f["field"] for f in _rows(db)[0].changes["fields"]}


def test_windows_per_user_service_suffix_is_not_a_change(db):
    from grc.services.asset_change_log import drop_churn
    svc = lambda sfx, mode="Manual": {"services": {"status": "discovered", "data": [
        {"name": f"AarSvc_{sfx}", "display_name": f"Agent Activation Runtime_{sfx}", "start_mode": mode}]}}
    a = _asset(db, platform_properties=svc("7d7b4"))
    a.platform_properties = svc("854d4")
    db.commit()
    assert _rows(db) == []
    a.platform_properties = svc("9ab12", "Auto")
    db.commit()
    (row,) = _rows(db)
    assert [(f["field"], f["change"]) for f in row.changes["fields"]] == [("services.data[AarSvc].start_mode", "changed")]
    old = [{"field": "services.data[AarSvc_7d7b4]", "section": "services", "change": "removed", "old": "AarSvc_7d7b4 (start_mode: Manual)"},
           {"field": "services.data[AarSvc_854d4]", "section": "services", "change": "added", "new": "AarSvc_854d4 (start_mode: Manual)"}]
    assert drop_churn(old) == []


def test_estate_field_catalog_counts_assets_holding_each_field(db):
    from grc.services.asset_change_log import estate_field_catalog
    a = _asset(db, location="HQ", platform_properties={"services": {"status": "discovered", "data": [{"name": "x"}]}})
    b = ITAsset(tenant_id=1, name="db02", asset_type="server")
    db.add(b); db.commit()
    cat = estate_field_catalog([a, b])
    by = {f["path"]: f for f in cat["fields"]}
    assert cat["assets"] == 2
    assert by["location"]["count"] == 1 and by["name"]["count"] == 2
    assert by["services.data"]["kind"] == "list" and by["services.data"]["count"] == 1 and by["services.data"]["value"] is None


def test_hotfix_rolling_off_recent_list_is_not_an_uninstall(db):
    hf = lambda *ids: {"windows_update": {"status": "discovered", "data": {
        "recent_hotfixes": [{"id": i, "type": "Security Update"} for i in ids]}}}
    a = _asset(db, platform_properties=hf("KB1", "KB2"))
    a.platform_properties = hf("KB2", "KB3")
    db.commit()
    (row,) = _rows(db)
    assert [(f["field"], f["change"]) for f in row.changes["fields"]] == [
        ("windows_update.data.recent_hotfixes[KB3]", "added")]


def test_virtual_adapter_new_mac_is_a_mac_change_not_remove_add(db):
    nic = lambda mac: {"network": {"status": "discovered", "data": [{"name": "", "description": "WAN Miniport (IP)", "mac": mac}]}}
    a = _asset(db, platform_properties=nic("BE:E3:20:52:41:53"))
    a.platform_properties = nic("6C:68:20:52:41:53")
    db.commit()
    (row,) = _rows(db)
    assert [(f["field"], f["change"]) for f in row.changes["fields"]] == [("network.data[WAN Miniport (IP)].mac", "changed")]


def test_history_read_drops_order_paired_duplicates_and_rolled_off_hotfixes():
    from grc.services.asset_change_log import drop_churn
    rows = [
        {"field": "recon.open_ports[5353/udp].service", "section": "recon", "change": "changed", "old": "chrome", "new": "msedge"},
        {"field": "recon.open_ports[5353/udp']", "section": "recon", "change": "added", "old": None, "new": "port: 5353"},
        {"field": "recon.windows.hotfixes", "section": "recon", "change": "removed", "old": "KB5127648", "new": None},
        {"field": "windows_update.data.recent_hotfixes[KB5127648]", "section": "windows_update", "change": "removed", "old": "KB5127648", "new": None},
        {"field": "services.data[OneSyncSvc_1cf2d1]", "section": "services", "change": "removed", "old": "OneSyncSvc_1cf2d1", "new": None},
        {"field": "recon.open_ports[8834/tcp]", "section": "recon", "change": "added", "old": None, "new": "port: 8834"},
    ]
    assert [f["field"] for f in drop_churn(rows)] == ["recon.open_ports[8834/tcp]"]


def test_recon_parts_are_filed_where_they_belong(db):
    from grc.services.asset_change_log import category_for
    assert category_for("recon", "recon.packages[openssl].version", "identity") == "software"
    assert category_for("recon", "recon.windows.hotfixes", "identity") == "security"
    assert category_for("recon", "recon.open_ports[445/tcp]", "identity") == "identity"
    assert category_for("defender", "defender.data.x", "security") == "security"
    a = _asset(db, platform_properties={"recon": {"packages": [{"name": "openssl", "version": "1"}], "open_ports": []}})
    a.platform_properties = {"recon": {"packages": [{"name": "openssl", "version": "3"}], "open_ports": [{"port": 22, "proto": "tcp"}]}}
    db.commit()
    cats = {f["field"]: f["category"] for f in _rows(db)[0].changes["fields"]}
    assert cats == {"recon.packages[openssl].version": "software", "recon.open_ports[22/tcp]": "identity"}
    by = {t["path"]: t["category"] for t in field_tracks(a)}
    assert by["recon.packages"] == "software" and by["recon.open_ports"] == "identity"


def test_linux_running_services_list_start_stop_is_not_add_remove(db):
    from grc.services.asset_change_log import drop_churn
    svc = lambda *names: {"services": {"status": "discovered", "data": {"init_system": "systemd",
        "services": [{"name": n, "state": "running"} for n in names]}}}
    a = _asset(db, platform_properties=svc("ssh.service", "cron.service"))
    a.platform_properties = svc("ssh.service", "cron.service", "fwupd.service")   # on-demand service started
    db.commit()
    assert _rows(db) == []
    old = [{"field": "services.data.services[fwupd.service]", "section": "services", "change": "added",
            "old": None, "new": "fwupd.service (state: running)"}]
    assert drop_churn(old) == []
    win = [{"field": "services.data[CoworkVMService]", "section": "services", "change": "added", "old": None,
            "new": "CoworkVMService (account: LocalSystem, path: C:/x.exe, start_mode: Auto)"}]
    assert drop_churn(win) == win          # a Windows service install is still a change
