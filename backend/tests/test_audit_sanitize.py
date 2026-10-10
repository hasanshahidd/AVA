"""Fix G — audit-log redaction must blank secret-bearing keys by case-insensitive
substring, recursively, without corrupting benign boolean/count metadata.

Importing grc.audit_logger pulls the auth router, which requires SESSION_SECRET,
so set it before the import.
"""
import os

os.environ.setdefault("SESSION_SECRET", "test-session-secret-for-audit")

from grc.audit_logger import _sanitize_value  # noqa: E402

REDACTED = "***"


def test_connect_wizard_fields_redacted():
    """The exact fields the old exact-match redactor leaked (MEMORY: supply-chain
    + domain-admin creds in grc_audit_logs) must now be blanked."""
    payload = {
        "agent_password": "DomainAdmin!23",
        "azure_client_secret": "aZ~secret",
        "kubeconfig": "apiVersion: v1\nclusters: ...",
        "k8s_token": "eyJhbGciOi...",
        "do_api_token": "dop_v1_abc",
    }
    out = _sanitize_value(payload)
    for k in payload:
        assert out[k] == REDACTED, f"{k} not redacted: {out[k]!r}"


def test_nested_dicts_and_lists_redacted():
    payload = {
        "connection": {
            "username": "svc-scan",
            "agent_password": "p@ss",
            "extra": {"ldap_password": "x", "private_key": "-----BEGIN-----"},
        },
        "creds": [
            {"api_key": "AKIA...", "label": "prod"},
            {"access_key": "secretval"},
        ],
    }
    out = _sanitize_value(payload)
    assert out["connection"]["username"] == "svc-scan"       # benign preserved
    assert out["connection"]["agent_password"] == REDACTED
    assert out["connection"]["extra"]["ldap_password"] == REDACTED
    assert out["connection"]["extra"]["private_key"] == REDACTED
    assert out["creds"][0]["api_key"] == REDACTED
    assert out["creds"][0]["label"] == "prod"
    assert out["creds"][1]["access_key"] == REDACTED


def test_existing_exact_match_keys_still_redacted():
    """Back-compat: the keys the original redactor handled must keep working."""
    payload = {"password": "pw", "token": "tk", "secret": "sc",
               "authorization": "Bearer z", "cookie": "sid=abc", "api_key": "k"}
    out = _sanitize_value(payload)
    for k in payload:
        assert out[k] == REDACTED, f"{k} regressed: {out[k]!r}"


def test_benign_metadata_not_corrupted():
    """Booleans/counts whose KEY matches a sensitive substring must pass through —
    they carry no secret, only presence/shape info the admin UI needs."""
    payload = {
        "has_secret": True,
        "secret_present": False,
        "token_count": 5,
        "password_length": 12,
        "credential_count": 0,
        "azure_client_secret": "",          # empty → nothing to hide, keep ""
    }
    out = _sanitize_value(payload)
    assert out["has_secret"] is True
    assert out["secret_present"] is False
    assert out["token_count"] == 5
    assert out["password_length"] == 12
    assert out["credential_count"] == 0
    assert out["azure_client_secret"] == ""


def test_non_sensitive_strings_preserved():
    payload = {"name": "My Risk", "status": "open", "description": "token bucket note"}
    out = _sanitize_value(payload)
    assert out == payload  # values untouched; only KEY names trigger redaction


def test_case_insensitive_substring():
    payload = {"Agent_Password": "x", "AZURE_CLIENT_SECRET": "y", "DO_Api_Token": "z"}
    out = _sanitize_value(payload)
    assert all(v == REDACTED for v in out.values())
