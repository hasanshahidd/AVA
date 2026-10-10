"""Guards the Help Desk assignment root-cause fix.

Frappe's assignment rule keys on `agent_group` (e.g. "agent_group == 'ava'").
The platform-env push path set no team, so `agent_group` stayed NULL and tickets
were never auto-assigned. The adapter now defaults `agent_group` to the tenant
partition (`ava_tenant`) when a team of that name exists. These tests pin that
behaviour without touching a live Frappe.
"""
from types import SimpleNamespace

from grc.modules.connectors.base import TicketRequest
from grc.modules.connectors.providers.frappe_helpdesk import FrappeHelpdeskAdapter


def _adapter(config):
    return FrappeHelpdeskAdapter(
        console_url="http://engine", credentials={"api_key": "k", "api_secret": "s"},
        config=config,
    )


def _req(kind="vulnerability"):
    return TicketRequest(kind="vulnerability", summary="s", description="d",
                         severity="critical", external_id="42",
                         extra_fields={"cve_id": "CVE-1", "affected_host": "h"})


def _stub(adapter, *, team_exists, existing=None):
    """Capture the create payload; simulate _find_by_finding_id + team lookup +
    a successful create — no network."""
    captured = {}

    def fake_req(method, path, **kw):
        if path.startswith("/api/resource/HD Team/"):
            return SimpleNamespace(status_code=200 if team_exists else 404)
        if path.startswith("/api/resource/HD Ticket?"):   # idempotency probe
            return SimpleNamespace(status_code=200, json=lambda: {"data": ([{"name": existing}] if existing else [])})
        if method == "POST" and path == "/api/resource/HD Ticket":
            captured["payload"] = kw.get("json")
            return SimpleNamespace(status_code=200, json=lambda: {"data": {"name": "TKT-1"}})
        raise AssertionError(f"unexpected call {method} {path}")

    adapter._req = fake_req  # type: ignore[assignment]
    return captured


def test_agent_group_defaults_to_partition_when_team_exists():
    a = _adapter({"ava_tenant": "ava"})
    cap = _stub(a, team_exists=True)
    a.create_ticket(_req())
    assert cap["payload"]["agent_group"] == "ava"      # rule can now fire
    assert cap["payload"]["ava_tenant"] == "ava"


def test_agent_group_omitted_when_no_team_exists():
    a = _adapter({"ava_tenant": "ghosttenant"})
    cap = _stub(a, team_exists=False)
    a.create_ticket(_req())
    # No such team → must NOT set agent_group (would fail Frappe link validation).
    assert "agent_group" not in cap["payload"]


def test_explicit_team_overrides_partition_default():
    a = _adapter({"ava_tenant": "ava", "agent_group": "SpecialTeam"})
    cap = _stub(a, team_exists=True)
    a.create_ticket(_req())
    assert cap["payload"]["agent_group"] == "SpecialTeam"
