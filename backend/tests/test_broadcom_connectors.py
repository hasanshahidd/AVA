"""End-to-end proof of the Broadcom connectors over real HTTP against a strict
CA SDM REST mock (tests/ca_sdm_mock.py), with the real sync runner and the
asset change journal on a real SQLAlchemy session.

Service Desk: test-connection, ticket push (priority/customer/status SRELs),
status + resolution sync-back, close with activity-log comment, access-key
expiry → re-login, bad credentials / unreachable host.
CMDB: test-connection, paged CI import matched on serial / MAC / hostname / IP,
inactive CIs filtered, new CIs created, change journal labelled "connector",
optional push-back (idempotent).
"""
from types import SimpleNamespace

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from grc.models import AuditLog, ITAsset
from grc.modules.connectors import sync_runner
from grc.modules.connectors.base import TicketRequest
from grc.modules.connectors.providers.broadcom_cmdb import BroadcomCmdbAdapter
from grc.modules.connectors.providers.broadcom_service_desk import BroadcomServiceDeskAdapter
from grc.modules.connectors.registry import PROVIDER_REGISTRY

from tests import ca_sdm_mock as mock


@pytest.fixture()
def sdm():
    srv, state, url = mock.serve()
    yield state, url
    srv.shutdown()


def _creds(pwd=mock.PASSWORD):
    return {"username": mock.USER, "password": pwd}


def _desk(url, **cfg):
    return BroadcomServiceDeskAdapter(console_url=url, credentials=_creds(), config=cfg)


def _cmdb(url, **cfg):
    return BroadcomCmdbAdapter(console_url=url, credentials=_creds(), config=cfg)


def test_both_providers_registered_not_beta():
    for key, cat in (("broadcom_service_desk", "ticketing"), ("broadcom_cmdb", "cmdb")):
        meta = PROVIDER_REGISTRY[key]
        assert meta.category == cat and meta.beta is False
        flags = {f.key: f.is_credential for f in meta.fields}
        assert flags["password"] is True and flags["console_url"] is False


# ── Service Desk ─────────────────────────────────────────────────────

def test_service_desk_test_connection(sdm):
    _state, url = sdm
    r = _desk(url).test_connection()
    assert r.success, r.message
    assert "read access to 'in'" in r.message


def test_service_desk_bad_password_and_unreachable(sdm):
    _state, url = sdm
    bad = BroadcomServiceDeskAdapter(console_url=url, credentials=_creds("wrong"), config={}).test_connection()
    assert not bad.success and "login rejected (401)" in bad.message and "wrong" not in bad.message
    down = _desk("http://127.0.0.1:9").test_connection()
    assert not down.success and "cannot reach" in down.message


def test_service_desk_push_sync_back_and_close(sdm):
    state, url = sdm
    desk = _desk(url, default_group="Security Operations", default_category="Security.Vulnerability")
    ref = desk.create_ticket(TicketRequest(summary="CVE-2024-6387 on web01", description="regreSSHion",
                                           severity="critical", kind="vulnerability", external_id="7"))
    row = next(r for r in state.objs["in"] if r["ref_num"] == ref)
    assert row["priority"] == {"@COMMON_NAME": "1"}
    assert row["group"] == {"@COMMON_NAME": "Security Operations"}
    assert row["customer"]["@id"] == state.objs["cnt"][0]["@id"]   # resolved from the service account

    (st,) = desk.fetch_statuses([ref])
    assert (st.external_id, st.status, st.normalised_status) == (ref, "Open", "new")

    row["status"] = {"@COMMON_NAME": "Work In Progress"}             # analyst picks it up in CA SDM
    assert desk.fetch_statuses([ref])[0].normalised_status == "in_progress"
    row["status"] = {"@COMMON_NAME": "Resolved"}                     # analyst resolves it
    assert desk.fetch_statuses([ref, "no-such"])[0].normalised_status == "resolved"

    assert desk.close_ticket(ref, "Patched to OpenSSH 9.8p1") is True
    assert row["status"] == {"@COMMON_NAME": "Resolved"}
    (log,) = state.objs["alg"]
    assert log["call_req_id"] == {"@id": row["@id"]} and "9.8p1" in log["description"]
    assert desk.close_ticket("99999", "x") is False


def test_service_desk_batches_status_queries(sdm):
    state, url = sdm
    desk = _desk(url)
    refs = [desk.create_ticket(TicketRequest(summary=f"t{i}", description="", severity="low",
                                             kind="vulnerability", external_id=str(i))) for i in range(30)]
    before = sum(1 for r in state.requests if r == "GET in")
    assert {s.external_id for s in desk.fetch_statuses(refs)} == set(refs)
    assert sum(1 for r in state.requests if r == "GET in") - before == 2   # 25 + 5


def test_expired_access_key_relogs_once(sdm):
    state, url = sdm
    desk = _desk(url)
    desk.test_connection()
    logins = state.logins
    state.expire_keys()
    assert desk.fetch_statuses(["1"]) == []
    assert state.logins == logins + 1


# ── CMDB ─────────────────────────────────────────────────────────────

@pytest.fixture()
def db(monkeypatch):
    eng = create_engine("sqlite://")
    ITAsset.__table__.metadata.create_all(eng, tables=[ITAsset.__table__, AuditLog.__table__])
    import grc.services.asset_criticality as crit
    monkeypatch.setattr(crit, "recompute_for_asset", lambda *a, **k: None)
    s = sessionmaker(bind=eng, autoflush=False, future=True)()
    yield s
    s.close()


def _seed_cis(state):
    ci = lambda **kw: state.add("nr", {"delete_flag": 0, "is_ci": 1, "class": {"@COMMON_NAME": "Server"}, **kw})
    ci(name="DB-PROD-01", serial_number="SN-123", system_name="dbprod01", alarm_id="10.0.0.5",
       manufacturer={"@COMMON_NAME": "Dell"}, model={"@COMMON_NAME": "PowerEdge R750"},
       location={"@COMMON_NAME": "London DC1"})
    ci(name="Core switch", mac_address="AA:BB:CC:00:11:22", alarm_id="10.0.0.1")
    ci(name="mail", system_name="MAIL01")
    ci(name="Printer 4F", alarm_id="10.0.4.40", location={"@COMMON_NAME": "HQ Floor 4"})
    ci(name="New SAN", serial_number="SAN-9", system_name="san01")
    ci(name="Retired box", system_name="old01", delete_flag=1)
    for i in range(120):                         # forces a second page (size=100)
        ci(name=f"vm-{i:03d}", system_name=f"vm{i:03d}")


def _conn(**cfg):
    return SimpleNamespace(id=1, tenant_id=1, category="cmdb", integration_type="broadcom_cmdb",
                           provider_config=cfg, last_sync_at=None)


def test_cmdb_test_connection_counts_cis(sdm):
    state, url = sdm
    _seed_cis(state)
    r = _cmdb(url).test_connection()
    assert r.success and r.details["total_records"] == 126


def test_cmdb_import_matches_journals_and_filters(sdm, db):
    state, url = sdm
    _seed_cis(state)
    a_serial = ITAsset(tenant_id=1, name="db-prod", asset_type="server", serial_number="SN-123")
    a_mac = ITAsset(tenant_id=1, name="sw-core", asset_type="network", primary_mac="aa:bb:cc:00:11:22")
    a_host = ITAsset(tenant_id=1, name="mail01", asset_type="server", host_name="mail01")
    a_ip = ITAsset(tenant_id=1, name="prn", asset_type="printer", ip_address="10.0.4.40")
    db.add_all([a_serial, a_mac, a_host, a_ip])
    db.commit()

    res = sync_runner._dispatch_sync(_cmdb(url), _conn(), db)
    assert res.success, res.errors
    assert res.details["cmdb"] == {"fetched": 125, "created": 121, "updated": 4}
    assert db.query(ITAsset).count() == 125                       # 4 matched + 121 new, none duplicated
    assert db.query(ITAsset).filter(ITAsset.host_name == "old01").count() == 0   # inactive CI skipped

    db.refresh(a_serial)
    assert (a_serial.manufacturer, a_serial.model, a_serial.location, a_serial.ip_address) == \
        ("Dell", "PowerEdge R750", "London DC1", "10.0.0.5")
    assert a_serial.platform_properties["cmdb"]["broadcom_cmdb"]["ci_type"] == "Server"

    rows = db.query(AuditLog).filter(AuditLog.action == "asset.updated").all()
    assert {r.resource_id for r in rows} == {a_serial.id, a_mac.id, a_host.id, a_ip.id}
    assert all(r.changes["source"] == "connector" for r in rows)
    serial_row = next(r for r in rows if r.resource_id == a_serial.id)
    by = {f["field"]: f for f in serial_row.changes["fields"]}
    assert by["manufacturer"] == {"field": "manufacturer", "category": "platform", "old": None, "new": "Dell"}
    assert by["ip_address"]["category"] == "identity"


def test_cmdb_push_back_is_opt_in_and_idempotent(sdm, db):
    state, url = sdm
    _seed_cis(state)
    db.add_all([ITAsset(tenant_id=1, name="caiva-only-01", asset_type="server", host_name="caivaonly01",
                        ip_address="10.9.9.9"),
                ITAsset(tenant_id=1, name="Payroll SaaS", asset_type="application")])  # no hardware identity
    db.commit()

    sync_runner._dispatch_sync(_cmdb(url), _conn(), db)
    assert not any(r["name"] == "caiva-only-01" for r in state.objs["nr"])   # off by default

    res = sync_runner._dispatch_sync(_cmdb(url), _conn(push_assets="true"), db)
    assert res.details["push"]["pushed"] == 1 and res.details["push"]["failed"] == 0
    pushed = next(r for r in state.objs["nr"] if r["name"] == "caiva-only-01")
    assert pushed["class"] == {"@COMMON_NAME": "Discovered Hardware"}
    assert (pushed["system_name"], pushed["alarm_id"]) == ("caivaonly01", "10.9.9.9")

    res2 = sync_runner._dispatch_sync(_cmdb(url), _conn(push_assets="true"), db)
    assert res2.details["push"]["pushed"] == 0                                  # already linked
    assert sum(r["name"] == "caiva-only-01" for r in state.objs["nr"]) == 1
    assert sync_runner._cfg_truthy("false") is False


def test_cmdb_paging_survives_a_server_size_cap(sdm):
    state, url = sdm
    _seed_cis(state)
    state.max_size = 30                    # server returns 30 even though we ask for 100
    assert len(_cmdb(url).fetch_cis()) == 125
