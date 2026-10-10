"""Fix H — grc.security.secret_encryption: dedicated key, dual-key decrypt,
KDF-cost fallback, rotation, and back-compat with pre-change ciphertext.

The column stores RAW Fernet bytes (no version prefix), so versioning is by
try-each-key via MultiFernet.
"""
import base64

import pytest
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

from grc.security import secret_encryption as se
from grc.scripts.rotate_secrets import plan_idp_value


# Frozen artifact of the PRE-CHANGE secret_encryption.py (PBKDF2 @ 200k, salt
# grc-integration-encryption-v1, SESSION_SECRET-derived, raw Fernet bytes).
IDP_LEGACY_SECRET = "legacy-session-secret-value"
IDP_LEGACY_PLAINTEXT = "azure-client-secret-xyz"
IDP_LEGACY_CIPHERTEXT = base64.b64decode(
    "Z0FBQUFBQnF5a0k4QkF4OWNBY3VMQ1YtdDZQTS0tUFlONTRjUDE4TmFWVEdyQjV3VzlsUXd"
    "Kc0p6dVA2V3NMZE5rTVpLRF9MTUdER1RwclFTZ29xdnFUaEZvcVlQNERQZ2FlX3ZIay1tWX"
    "ZBdWxPRWllX3p4bkk9"
)


@pytest.fixture(autouse=True)
def _clean_env(monkeypatch):
    for v in ("INTEGRATION_ENCRYPTION_KEY", "AVA_CRED_KEY",
              "SESSION_SECRET", "SESSION_SECRET_OLD"):
        monkeypatch.delenv(v, raising=False)
    yield


def test_roundtrip(monkeypatch):
    monkeypatch.setenv("SESSION_SECRET", "sess-abc")
    ct = se.encrypt("client-secret-1")
    assert isinstance(ct, bytes)
    assert se.decrypt(ct) == "client-secret-1"


def test_backcompat_frozen_legacy(monkeypatch):
    """CRITICAL: bytes written by the pre-change code decrypt unchanged."""
    monkeypatch.setenv("SESSION_SECRET", IDP_LEGACY_SECRET)
    assert se.decrypt(IDP_LEGACY_CIPHERTEXT) == IDP_LEGACY_PLAINTEXT


def test_backcompat_live_200k(monkeypatch):
    """Old 200k-derived ciphertext still decrypts though new data uses 600k."""
    monkeypatch.setenv("SESSION_SECRET", "sess-live")
    kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32,
                     salt=se._DERIVATION_SALT, iterations=200_000)
    f = Fernet(base64.urlsafe_b64encode(kdf.derive(b"sess-live")))
    old = f.encrypt(b"old-200k-secret")
    assert se.decrypt(old) == "old-200k-secret"
    assert se.needs_rotation(old) is True   # written at legacy cost


def test_explicit_key_is_primary(monkeypatch):
    key = Fernet.generate_key().decode()
    monkeypatch.setenv("INTEGRATION_ENCRYPTION_KEY", key)
    monkeypatch.setenv("SESSION_SECRET", "ignored-for-new-encrypt")
    ct = se.encrypt("explicit-keyed")
    # decrypts directly under the explicit key (proves it was the primary)
    assert Fernet(key.encode()).decrypt(ct).decode() == "explicit-keyed"
    assert se.needs_rotation(ct) is False


def test_dedicated_key_decoupled(monkeypatch):
    monkeypatch.setenv("AVA_CRED_KEY", "vault-only")
    monkeypatch.setenv("SESSION_SECRET", "jwt-only")
    ct = se.encrypt("dedicated")
    # JWT key rotates — vault data unaffected
    monkeypatch.setenv("SESSION_SECRET", "jwt-rotated")
    assert se.decrypt(ct) == "dedicated"
    # without the vault key, SESSION_SECRET alone cannot read it
    monkeypatch.delenv("AVA_CRED_KEY", raising=False)
    with pytest.raises(Exception):
        se.decrypt(ct)


def test_dual_key_rotation_roundtrip(monkeypatch):
    monkeypatch.setenv("SESSION_SECRET", "old-key")
    ct_old = se.encrypt("rotate-me")

    monkeypatch.setenv("AVA_CRED_KEY", "new-key")
    monkeypatch.setenv("SESSION_SECRET_OLD", "old-key")
    monkeypatch.delenv("SESSION_SECRET", raising=False)
    assert se.decrypt(ct_old) == "rotate-me"       # dual-key fallback
    assert se.needs_rotation(ct_old) is True

    new_val, status = plan_idp_value(ct_old)
    assert status == "rotate"

    monkeypatch.delenv("SESSION_SECRET_OLD", raising=False)
    assert se.decrypt(new_val) == "rotate-me"       # new key alone
    assert se.needs_rotation(new_val) is False


def test_plan_idp_value_skip_paths(monkeypatch):
    monkeypatch.setenv("SESSION_SECRET", "k")
    cur = se.encrypt("x")
    assert plan_idp_value(cur) == (None, "skip")    # already current
    assert plan_idp_value(None) == (None, "skip")
    assert plan_idp_value(b"") == (None, "skip")


def test_fail_loud_when_no_key():
    with pytest.raises(se.EncryptionKeyMissing):
        se.encrypt("x")
    with pytest.raises(se.EncryptionKeyMissing):
        se.decrypt(b"anything")
