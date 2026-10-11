"""Guards the Help Desk assignment root-cause fix.

Frappe's assignment rule keys on `agent_group` (e.g. "agent_group == 'ava'").
The platform-env push path set no team, so `agent_group` stayed NULL and tickets
were never auto-assigned. The adapter now defaults `agent_group` to the tenant
partition (`ava_tenant`) when a team of that name exists. These tests pin that
behaviour without touching a live Frappe.
"""
import html
from types import SimpleNamespace

from grc.modules.connectors.base import TicketRequest
from grc.modules.connectors.providers.frappe_helpdesk import FrappeHelpdeskAdapter, _fit_subject


def test_fit_subject_fits_escaped_length():
    # Real failing title: lots of <package>/<version> that balloon when escaped.
    t = ("Dockerfile DL3013: Pin versions in pip. Instead of `pip install <package>` "
         "use `pip install <package>==<version>` or `pip install --requirement "
         "<requirements file>`")
    s = _fit_subject(t)
    assert len(html.escape(s)) <= 140   # Frappe validates the ESCAPED length
    assert s.endswith("…")


def test_fit_subject_leaves_short_titles():
    assert _fit_subject("CVE-2026-1 in pkg") == "CVE-2026-1 in pkg"
    assert _fit_subject("") == "Finding"


def _adapter(config):
    return FrappeHelpdeskAdapter(
        console_url="http://engine", credentials={"api_key": "k", "api_secret": "s"},
        config=config,
    )


def _req(kind="vulnerability"):
    return TicketRequest(kind="vulnerability", summary="s", description="d",
                         severity="critical", external_id="42",
                         extra_fields={"cve_id": "CVE-1", "affected_host": "h"})


def _stub(adapter, *, team_exists, team_create_ok=True, existing=None):
    """Capture the create payload; simulate _find_by_finding_id + team lookup +
    team auto-create + a successful ticket create — no network."""
    captured = {"team_created": False}

    def fake_req(method, path, **kw):
        if path.startswith("/api/resource/HD Team/"):           # GET existence probe
            return SimpleNamespace(status_code=200 if team_exists else 404)
        if method == "POST" and path == "/api/resource/HD Team":  # auto-create
            captured["team_created"] = True
            return SimpleNamespace(status_code=201 if team_create_ok else 417,
                                   json=lambda: {"data": {"name": kw.get("json", {}).get("team_name")}})
        if path.startswith("/api/resource/HD Ticket?"):         # idempotency probe
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
    assert cap["team_created"] is False                # existing team → no create


def test_new_tenant_team_is_auto_created_then_assigned():
    # Onboarding is automatic: a tenant with no team yet gets one created on first
    # ticket, and agent_group is set so auto-assignment still fires.
    a = _adapter({"ava_tenant": "newtenant"})
    cap = _stub(a, team_exists=False, team_create_ok=True)
    a.create_ticket(_req())
    assert cap["team_created"] is True
    assert cap["payload"]["agent_group"] == "newtenant"


def test_agent_group_omitted_when_team_create_fails():
    # If the team can't be created, don't set agent_group (would fail Frappe link validation).
    a = _adapter({"ava_tenant": "ghosttenant"})
    cap = _stub(a, team_exists=False, team_create_ok=False)
    a.create_ticket(_req())
    assert "agent_group" not in cap["payload"]


def test_explicit_team_overrides_partition_default():
    a = _adapter({"ava_tenant": "ava", "agent_group": "SpecialTeam"})
    cap = _stub(a, team_exists=True)
    a.create_ticket(_req())
    assert cap["payload"]["agent_group"] == "SpecialTeam"
