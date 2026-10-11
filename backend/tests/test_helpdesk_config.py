"""Unit tests for the Help Desk read-only config projection (pure, no I/O)."""
from grc.modules.helpdesk.router import _fmt_duration, _sla_targets


def test_fmt_duration():
    assert _fmt_duration(3600) == "1h"
    assert _fmt_duration(14400) == "4h"
    assert _fmt_duration(86400) == "1d"
    assert _fmt_duration(172800) == "2d"
    assert _fmt_duration(1800) == "30m"
    assert _fmt_duration(5400) == "1.5h"
    assert _fmt_duration(0) is None
    assert _fmt_duration(None) is None
    assert _fmt_duration("junk") is None


def test_sla_targets_projection():
    doc = {
        "name": "Default",
        "service_level": "Standard",
        "holiday_list": "Company Holidays",
        "priorities": [
            {"priority": "Urgent", "response_time": 3600, "resolution_time": 14400},
            {"priority": "Low", "response_time": 0, "resolution_time": 172800},
        ],
        "support_and_resolution": [
            {"workday": "Monday", "start_time": "09:00:00", "end_time": "17:00:00"},
        ],
    }
    out = _sla_targets(doc)
    assert out["policy"] == "Standard"
    assert out["holiday_list"] == "Company Holidays"
    assert out["priorities"][0] == {"priority": "Urgent", "response": "1h", "resolution": "4h"}
    assert out["priorities"][1]["response"] is None        # 0s → no target
    assert out["priorities"][1]["resolution"] == "2d"
    assert out["service_days"] == [{"day": "Monday", "start": "09:00:00", "end": "17:00:00"}]


def test_sla_targets_empty_doc():
    out = _sla_targets({})
    assert out == {"policy": None, "priorities": [], "service_days": [], "holiday_list": None}


def test_saved_reply_guard_rejects_out_of_partition(monkeypatch):
    """Adversarial isolation: the edit/delete guard must reject a crafted id that
    belongs to another tenant. The guard queries WITH the partition filter, so a
    simulated engine returns the record only for its owning partition."""
    from grc.modules.helpdesk import router as R

    monkeypatch.setattr(R, "_canned_spec", lambda ctx: ("HD Canned Response", "title"))

    # Simulated engine: one reply "SR-001" owned by partition "tenantA".
    def fake_resource(ctx, dt, fields, filters=None, order_by="", limit=0):
        want_tenant = want_name = None
        for f in (filters or []):
            if f[0] == "ava_tenant":
                want_tenant = f[2]
            if f[0] == "name":
                want_name = f[2]
        if want_tenant == "tenantA" and want_name in (None, "SR-001"):
            return [{"name": "SR-001"}]
        return []

    monkeypatch.setattr(R, "_resource", fake_resource)

    assert R._saved_reply_in_tenant({"partition": "tenantA"}, "SR-001") is True
    # crafted cross-tenant id → guard rejects
    assert R._saved_reply_in_tenant({"partition": "tenantB"}, "SR-001") is False
    # nonexistent id in own partition → rejected
    assert R._saved_reply_in_tenant({"partition": "tenantA"}, "SR-999") is False
    # dev / single-tenant engine (no partition) → allowed
    assert R._saved_reply_in_tenant({"partition": None}, "anything") is True
