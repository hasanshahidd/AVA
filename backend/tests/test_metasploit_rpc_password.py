"""MSF_RPC_PASSWORD fail-closed: the Metasploit RPC client must NEVER fall back to
a hardcoded default password (bank-blocker fix). Unset -> fail closed (no connect,
available() False); set -> uses the env value verbatim. Offline, no msfrpcd needed."""
from grc.modules.connectors.providers.metasploit_rpc import MsfRpc


def test_unset_password_fails_closed(monkeypatch):
    monkeypatch.delenv("MSF_RPC_PASSWORD", raising=False)
    c = MsfRpc()
    # No hardcoded default: password resolves to None, never a literal.
    assert c.password is None
    # Fail closed: the capability reports unavailable without attempting a connect.
    assert c.available() is False
    # Public methods still degrade gracefully (never raise, no default login).
    assert c.search_cve("CVE-2017-0143") == []


def test_set_password_uses_env_value(monkeypatch):
    monkeypatch.setenv("MSF_RPC_PASSWORD", "per-deploy-secret-123")
    c = MsfRpc()
    assert c.password == "per-deploy-secret-123"


def test_explicit_arg_beats_env(monkeypatch):
    monkeypatch.setenv("MSF_RPC_PASSWORD", "env-value")
    c = MsfRpc(password="explicit")
    assert c.password == "explicit"
