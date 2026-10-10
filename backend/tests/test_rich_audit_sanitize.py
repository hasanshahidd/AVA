"""Fix G (rich_audit) — the workflow/CIS audit path must redact secret-bearing
keys by case-insensitive substring, recursively, without corrupting benign
boolean/count metadata, AND must actually run that redaction on the persisted
`changes` payload (the raw model_to_dict snapshot was previously stored unredacted).

rich_audit imports only models + stdlib, so no SESSION_SECRET is needed here.
"""
from grc.rich_audit import _sanitize, write_rich_audit_log

REDACTED = "***"


def test_connect_wizard_fields_redacted():
    payload = {
        "agent_password": "DomainAdmin!23",
        "azure_client_secret": "aZ~secret",
        "kubeconfig": "apiVersion: v1\n...",
        "k8s_token": "eyJhbGciOi...",
        "do_api_token": "dop_v1_abc",
    }
    out = _sanitize(payload)
    for k in payload:
        assert out[k] == REDACTED, f"{k} not redacted: {out[k]!r}"


def test_nested_and_exact_match_and_benign():
    payload = {
        "snapshot": {
            "username": "svc-scan",
            "agent_password": "p@ss",
            "password_hash": "$2b$...",        # exact-match key still works
            "extra": {"private_key": "-----BEGIN-----", "label": "prod"},
        },
        "has_secret": True,                     # benign metadata preserved
        "token_count": 5,
        "credential_count": 0,
        "name": "My Workflow",
    }
    out = _sanitize(payload)
    assert out["snapshot"]["username"] == "svc-scan"
    assert out["snapshot"]["agent_password"] == REDACTED
    assert out["snapshot"]["password_hash"] == REDACTED
    assert out["snapshot"]["extra"]["private_key"] == REDACTED
    assert out["snapshot"]["extra"]["label"] == "prod"
    assert out["has_secret"] is True
    assert out["token_count"] == 5
    assert out["credential_count"] == 0
    assert out["name"] == "My Workflow"


class _FakeDB:
    """Captures the AuditLog row; write_rich_audit_log never commits."""
    def __init__(self):
        self.added = []

    def add(self, row):
        self.added.append(row)


def test_write_path_redacts_persisted_changes():
    """End-to-end: a secret-bearing snapshot/before/after must be redacted in the
    row's `changes` — proving the redactor is wired into the write path, not
    just defined."""
    db = _FakeDB()
    write_rich_audit_log(
        db=db,
        tenant_id=1,
        user_id=7,
        action="update",
        resource_type="credential_profile",
        resource_id=42,
        snapshot={"kubeconfig": "clusters: ...", "k8s_token": "eyJ..."},
        before={"agent_password": "old-pw", "username": "svc"},
        after={"azure_client_secret": "new-sec", "do_api_token": "dop_x",
               "has_secret": True, "token_count": 5},
    )
    assert len(db.added) == 1
    changes = db.added[0].changes
    snap = changes["snapshot"]
    assert snap["kubeconfig"] == REDACTED
    assert snap["k8s_token"] == REDACTED
    assert snap["before"]["agent_password"] == REDACTED
    assert snap["before"]["username"] == "svc"
    assert snap["after"]["azure_client_secret"] == REDACTED
    assert snap["after"]["do_api_token"] == REDACTED
    assert snap["after"]["has_secret"] is True      # benign metadata survives
    assert snap["after"]["token_count"] == 5
