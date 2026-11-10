"""Self-tests for the two Broadcom connectors — CA SDM Service Desk (ticketing)
and CA CMDB (asset import). All HTTP is mocked; no live Broadcom endpoint is
required. Covers: access-key login, ticket create/status parsing, CI parsing,
and the CI→asset field mapping (`_apply_ci`).
"""
import json

import pytest

from grc.modules.connectors.base import (
    CmdbAdapter,
    ConfigurationItem,
    TicketingAdapter,
    TicketRequest,
)
from grc.modules.connectors.providers import broadcom_service_desk as bsd
from grc.modules.connectors.providers import broadcom_cmdb as bcm
from grc.modules.connectors.registry import PROVIDER_REGISTRY


class FakeResp:
    def __init__(self, status=200, body=None, text=None):
        self.status_code = status
        self._body = body
        self.text = text if text is not None else (json.dumps(body) if body is not None else "")
        self.headers = {}

    def json(self):
        return self._body


class FakeRequests:
    """Stand-in for the `requests` module. `post` answers login; `request`
    answers everything else, routed by (method, url) through `handler`."""
    def __init__(self, handler):
        self.handler = handler
        self.calls = []

    def post(self, url, **kw):
        self.calls.append(("POST", url, kw))
        return self.handler("POST", url, kw)

    def request(self, method, url, **kw):
        self.calls.append((method, url, kw))
        return self.handler(method, url, kw)


# ── registry guard ───────────────────────────────────────────────────

def test_both_providers_registered():
    sd = PROVIDER_REGISTRY.get("broadcom_service_desk")
    cm = PROVIDER_REGISTRY.get("broadcom_cmdb")
    assert sd is not None and sd.category == "ticketing" and sd.beta is False
    assert cm is not None and cm.category == "cmdb" and cm.beta is False
    # Password must be a credential (encrypted), URL/config must not be.
    assert {f.key: f.is_credential for f in sd.fields}["password"] is True
    assert {f.key: f.is_credential for f in sd.fields}["console_url"] is False


# ── Service Desk ─────────────────────────────────────────────────────

def _sd_adapter():
    return bsd.BroadcomServiceDeskAdapter(
        console_url="https://sd.example:8050",
        credentials={"username": "svc", "password": "secret"},
        config={"status_resolved": "Resolved"},
    )


def test_service_desk_login_and_create(monkeypatch):
    def handler(method, url, kw):
        if url.endswith("/rest_access"):
            assert kw.get("auth") == ("svc", "secret")
            return FakeResp(200, {"rest_access": {"access_key": "KEY123"}})
        if method == "POST" and url.endswith("/caisd-rest/in"):
            assert kw["headers"]["X-AccessKey"] == "KEY123"
            assert kw["json"]["in"]["summary"].startswith("SQLi")
            return FakeResp(201, {"in": {"ref_num": "I1234"}})
        raise AssertionError(f"unexpected {method} {url}")

    fake = FakeRequests(handler)
    monkeypatch.setattr(bsd, "requests", fake)
    a = _sd_adapter()
    assert a.test_connection().success is True
    num = a.create_ticket(TicketRequest(
        kind="vulnerability", summary="SQLi on web01", description="d",
        severity="critical", external_id="V1"))
    assert num == "I1234"


def test_service_desk_fetch_statuses_normalises(monkeypatch):
    def handler(method, url, kw):
        if url.endswith("/rest_access"):
            return FakeResp(200, {"rest_access": {"access_key": "K"}})
        if method == "GET" and url.endswith("/caisd-rest/in"):
            return FakeResp(200, {"collection": {"in": [
                {"ref_num": "I1234", "status": {"@COMMON_NAME": "Resolved"}, "resolution": "patched"}
            ]}})
        raise AssertionError(f"unexpected {method} {url}")

    monkeypatch.setattr(bsd, "requests", FakeRequests(handler))
    a = _sd_adapter()
    out = a.fetch_statuses(["I1234"])
    assert len(out) == 1
    assert out[0].external_id == "I1234"
    assert out[0].normalised_status == "resolved"
    assert out[0].resolution_note == "patched"


def test_service_desk_close_sets_resolved(monkeypatch):
    seen = {}

    def handler(method, url, kw):
        if url.endswith("/rest_access"):
            return FakeResp(200, {"rest_access": {"access_key": "K"}})
        if method == "POST" and "/caisd-rest/in/" in url:
            seen.update(kw["json"]["in"])
            return FakeResp(200, {})
        raise AssertionError(f"unexpected {method} {url}")

    monkeypatch.setattr(bsd, "requests", FakeRequests(handler))
    a = _sd_adapter()
    assert a.close_ticket("I1234", "fixed") is True
    assert seen["status"] == "Resolved"
    assert seen["resolution"] == "fixed"


# ── CMDB ─────────────────────────────────────────────────────────────

def _cmdb_adapter(config=None):
    return bcm.BroadcomCmdbAdapter(
        console_url="https://sd.example:8050",
        credentials={"username": "svc", "password": "secret"},
        config=config or {},
    )


def test_cmdb_fetch_cis_parses_and_paginates(monkeypatch):
    def handler(method, url, kw):
        if url.endswith("/rest_access"):
            return FakeResp(200, {"rest_access": {"access_key": "K"}})
        if method == "GET" and url.endswith("/caisd-rest/nr"):
            # one short page → loop stops after first fetch
            return FakeResp(200, {"collection": {"nr": [
                {"id": "C1", "name": "web01", "dns_name": "web01.corp",
                 "ip_address": "10.0.0.5", "mac_address": "AA:BB:CC",
                 "serial_number": "SN1", "class": {"@COMMON_NAME": "Server"}},
            ]}})
        raise AssertionError(f"unexpected {method} {url}")

    monkeypatch.setattr(bcm, "requests", FakeRequests(handler))
    a = _cmdb_adapter()
    cis = a.fetch_cis()
    assert len(cis) == 1
    ci = cis[0]
    assert isinstance(ci, ConfigurationItem)
    assert ci.source_id == "C1"
    assert ci.host_name == "web01.corp"
    assert ci.ip_address == "10.0.0.5"
    assert ci.serial_number == "SN1"
    assert ci.ci_type == "Server"


def test_cmdb_push_ci(monkeypatch):
    class DummyAsset:
        name = "db01"; host_name = "db01.corp"; ip_address = "10.0.0.9"
        primary_mac = None; serial_number = "SN9"; manufacturer = "Dell"; model = "R740"

    def handler(method, url, kw):
        if url.endswith("/rest_access"):
            return FakeResp(200, {"rest_access": {"access_key": "K"}})
        if method == "POST" and url.endswith("/caisd-rest/nr"):
            vals = kw["json"]["nr"]
            assert vals["name"] == "db01" and vals["serial_number"] == "SN9"
            return FakeResp(201, {"nr": {"id": "NEWCI"}})
        raise AssertionError(f"unexpected {method} {url}")

    monkeypatch.setattr(bcm, "requests", FakeRequests(handler))
    a = _cmdb_adapter()
    assert a.push_ci(DummyAsset()) == "NEWCI"


def test_pull_only_push_raises():
    # The base CmdbAdapter.push_ci default is pull-only.
    class PullOnly(CmdbAdapter):
        provider = "x"
        def test_connection(self):  # pragma: no cover - not exercised
            ...
        def fetch_cis(self, *, since=None, limit=5000):
            return []
    with pytest.raises(NotImplementedError):
        PullOnly(console_url="", credentials={}).push_ci(object())


# ── CI → asset mapping (the sync fan-out helper) ─────────────────────

def test_apply_ci_maps_fields_and_stamps_provenance():
    from grc.modules.connectors.sync_runner import _apply_ci

    class DummyAsset:
        asset_type = None
        host_name = ip_address = fqdn = primary_mac = None
        serial_number = manufacturer = model = location = os_version = None
        source_system = last_seen_source = last_seen_at = origin_source = None
        name = "web01"
        platform_properties = None

    ci = ConfigurationItem(
        source_id="C1", name="web01", ci_type="Server",
        host_name="web01.corp", ip_address="10.0.0.5", mac_address="AA:BB",
        serial_number="SN1", manufacturer="HP", model="DL380", os_name="RHEL 8",
        location="DC1",
    )
    a = DummyAsset()
    _apply_ci(a, ci, "broadcom_cmdb", "cmdb:broadcom_cmdb")

    assert a.host_name == "web01.corp"
    assert a.primary_mac == "AA:BB"
    assert a.serial_number == "SN1"
    assert a.os_version == "RHEL 8"
    assert a.asset_type == "infrastructure"           # required col set on create
    assert a.source_system == "broadcom_cmdb"
    assert a.last_seen_source == "cmdb:broadcom_cmdb"
    assert a.origin_source == "cmdb"
    assert a.platform_properties["cmdb"]["broadcom_cmdb"]["ci_id"] == "C1"


def test_apply_ci_never_blanks_existing():
    from grc.modules.connectors.sync_runner import _apply_ci

    class DummyAsset:
        asset_type = "application"
        host_name = "keep.me"
        ip_address = fqdn = primary_mac = None
        serial_number = manufacturer = model = location = os_version = None
        source_system = last_seen_source = last_seen_at = origin_source = None
        name = "web01"
        platform_properties = None

    # CI provides no host_name → must NOT blank the existing one.
    ci = ConfigurationItem(source_id="C2", name="web01", ip_address="10.0.0.6")
    a = DummyAsset()
    _apply_ci(a, ci, "broadcom_cmdb", "cmdb:broadcom_cmdb")
    assert a.host_name == "keep.me"      # preserved
    assert a.ip_address == "10.0.0.6"    # updated
    assert a.asset_type == "application"  # not overwritten
