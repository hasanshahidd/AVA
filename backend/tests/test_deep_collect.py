"""Credential store + deep-collection guard rails.

DB-free: the encryption boundary, credential-selection logic, and transport
inference. The full authenticated round-trip is exercised live elsewhere.
"""
import pytest

from grc.models import CredentialProfile
from grc.modules.asset_discovery.services import deep_collect as dc


# ── Credential model / secrecy ───────────────────────────────────────────────

def test_credential_secret_column_is_separate_from_a_returnable_field():
    """The secret lives in secret_encrypted; there is no plaintext column that
    could accidentally be serialised."""
    cols = set(CredentialProfile.__table__.columns.keys())
    assert "secret_encrypted" in cols
    assert "secret" not in cols and "password" not in cols


def test_credential_name_unique_per_tenant():
    uqs = [c for c in CredentialProfile.__table__.constraints
           if c.__class__.__name__ == "UniqueConstraint"]
    cols = {tuple(sorted(col.name for col in u.columns)) for u in uqs}
    assert ("name", "tenant_id") in cols


def test_credential_dict_never_includes_the_secret():
    from grc.modules.asset_discovery.router import _credential_dict

    class C:
        id = 1; name = "x"; kind = "winrm"; username = "u"; secret_kind = "password"
        secret_encrypted = "ENCRYPTED_BLOB"; domain = None; port = None
        winrm_transport = None; ssh_accept_unknown_hosts = False
        applies_to_cidrs = None; priority = 100; is_active = True
        created_at = None; created_by_name = None
    d = _credential_dict(C())
    assert "secret" not in d and "secret_encrypted" not in d
    assert d["has_secret"] is True  # presence signalled, value hidden


# ── Transport inference ──────────────────────────────────────────────────────

class _Asset:
    def __init__(self, fam=None):
        self.os_family = fam; self.os_normalized = None; self.ip_address = "10.0.0.1"


class _Obs:
    def __init__(self, ports):
        self.raw = {"open_ports": ports}


def test_transport_prefers_known_os():
    assert dc._transport_for_host(_Asset("windows"), _Obs([22])) == "windows"
    assert dc._transport_for_host(_Asset("ubuntu"), _Obs([445])) == "linux"


def test_transport_infers_from_ports_when_os_unknown():
    assert dc._transport_for_host(_Asset(), _Obs([445])) == "windows"
    assert dc._transport_for_host(_Asset(), _Obs([3389])) == "windows"
    assert dc._transport_for_host(_Asset(), _Obs([22])) == "linux"
    assert dc._transport_for_host(_Asset(), _Obs([])) is None


# ── CIDR applicability ───────────────────────────────────────────────────────

def test_cidr_match_semantics():
    assert dc._cidr_match("10.0.0.5", ["10.0.0.0/24"]) is True
    assert dc._cidr_match("10.9.0.5", ["10.0.0.0/24"]) is False
    assert dc._cidr_match("1.2.3.4", None) is True     # no cidrs = applies to all
    assert dc._cidr_match("1.2.3.4", []) is True
    assert dc._cidr_match(None, ["10.0.0.0/24"]) is False  # scoped cred needs an IP


def test_credentials_dict_shape_for_each_transport():
    class P:
        username = "svc"; domain = "CORP"; port = None; winrm_transport = None
        secret_kind = "password"; secret_encrypted = None
        ssh_accept_unknown_hosts = False
    win = dc._credentials_dict(P(), "10.0.0.9", "windows")
    assert win["winrm_endpoint"].endswith(":5986/wsman")
    assert win["winrm_username"] == "CORP\\svc"
    lin = dc._credentials_dict(P(), "10.0.0.9", "linux")
    assert lin["ssh_host"] == "10.0.0.9" and lin["ssh_port"] == 22


def test_executor_runs_deep_collect_after_resolve():
    import inspect
    from grc.modules.asset_discovery.services import executor
    src = inspect.getsource(executor.execute_run)
    assert "deep_collect_run" in src, "execute_run must attempt deep-collection after resolving"


def test_deep_collect_is_bounded_per_run():
    assert isinstance(dc.MAX_DEEP_COLLECT_PER_RUN, int) and dc.MAX_DEEP_COLLECT_PER_RUN > 0


def test_wmi_collect_stays_windows_and_reads_defender(monkeypatch):
    """transport='wmi' is Windows over DCOM: no SSH/Linux path may run, the OS
    comes from the WMI caption (healing the old 'linux' mislabel), and the WMI
    security read feeds the posture. Rows are shaped like impacket's — CIM
    booleans arrive as the STRINGS 'True'/'False'."""
    import re
    from grc.models import ITAsset
    from grc.modules.compliance_plugins.services import agentless_inventory as ai, os_detector

    # The WMI EDR map must stay the PowerShell probe's $known map.
    ps = re.search(r"\$known = @\{(.*?)\}", ai._WIN_DEEP_PS).group(1)
    assert ai._EDR_SERVICES == dict(re.findall(r"'([^']+)'='([^']+)'", ps))

    linux = []
    monkeypatch.setattr(os_detector, "detect_linux", lambda c: linux.append("os") or ("linux", None, None))
    monkeypatch.setattr(ai, "collect_linux_deep", lambda c: linux.append("deep") or {})
    monkeypatch.setattr(dc, "decrypt_secret", lambda s: "pw")
    monkeypatch.setattr(ai, "collect_windows_wmi", lambda c: ([], {"os_version": "Microsoft Windows 11 Pro"}))
    rows = {"MSFT_MpComputerStatus": [{"AntivirusEnabled": "True", "RealTimeProtectionEnabled": "False"}],
            "AntiVirusProduct": [{"displayName": "Windows Defender", "productState": 0x61100},
                                 {"displayName": "Old AV", "productState": 0x60110}],
            "Win32_Service": [{"Name": "Sense", "State": "Stopped"}]}
    q = lambda ns, wql: next(v for k, v in rows.items() if k in wql)  # noqa: E731
    monkeypatch.setattr(ai, "collect_windows_wmi_deep", lambda c: ai._wmi_security_sections(q))

    class P:
        username = "svc"; domain = None; secret_encrypted = "x"

    class DB:
        add = flush = lambda self, *a: None
        def query(self, *a): raise RuntimeError("no db")  # connection registration is best-effort

    a = ITAsset(ip_address="10.0.0.7", os_family="linux", os_normalized="linux")
    dc.collect_host(DB(), a, P(), "wmi")

    assert linux == []
    assert (a.os_family, a.os_normalized, a.os_edition) == ("windows", "windows-11", "Pro")
    d = a.platform_properties["defender"]["data"]
    assert d["antivirus_enabled"] is True and d["realtime_protection"] is False
    av = a.platform_properties["security_products"]["data"]["antivirus"]
    assert [(x["enabled"], x["up_to_date"]) for x in av] == [(True, True), (False, False)]
    assert a.security_posture["antivirus_products"] == ["Windows Defender"]
    assert a.security_posture["edr_stopped"] == ["Microsoft Defender for Endpoint"]
