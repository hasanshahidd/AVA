"""Fix H — grc.crypto: dedicated vault key, dual-decrypt, KDF versioning,
rotation round-trip, and the CRITICAL guarantee that ciphertext written by the
pre-change code still decrypts.

No DB needed: all env-driven, functions are pure.
"""
import base64

import pytest
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

import grc.crypto as crypto
from grc.scripts.rotate_secrets import plan_crypto_value


# Frozen artifact of the PRE-CHANGE crypto.py (PBKDF2 @ 200k, salt
# complyverse-cred-vault-v1, "enc:v1:" prefix). Minted once with the old code;
# Fernet decrypt is deterministic, so this is the authoritative back-compat proof.
LEGACY_SECRET = "legacy-session-secret-value"
LEGACY_PLAINTEXT = "S3cr3t-P@ssw0rd!"
LEGACY_CIPHERTEXT = (
    "enc:v1:gAAAAABqykIzauRPAxPdbJJJe1mbZynPtIG-zZPXj1tWkhnjCzKeuTVJwHwA9lGS"
    "bDyLk1vkKBYb4VE_zqrofNtzhXawsVSS2K1Sz0JnGpST3KR77Ovt--U="
)


@pytest.fixture(autouse=True)
def _clean_env(monkeypatch):
    for v in ("AVA_CRED_KEY", "SESSION_SECRET", "SESSION_SECRET_OLD"):
        monkeypatch.delenv(v, raising=False)
    yield


def _old_v1(secret: str, plaintext: str) -> str:
    """Encrypt exactly as the pre-change code did (200k, enc:v1)."""
    kdf = PBKDF2HMAC(algorithm=hashes.SHA256(), length=32,
                     salt=crypto._KDF_SALT, iterations=200_000)
    key = base64.urlsafe_b64encode(kdf.derive(secret.encode()))
    return "enc:v1:" + Fernet(key).encrypt(plaintext.encode()).decode("ascii")


def test_roundtrip_uses_current_version(monkeypatch):
    monkeypatch.setenv("SESSION_SECRET", "sess-abc")
    ct = crypto.encrypt_secret("hunter2")
    assert ct.startswith("enc:v2:")           # new KDF version
    assert crypto.decrypt_secret(ct) == "hunter2"


def test_backcompat_frozen_legacy_ciphertext(monkeypatch):
    """CRITICAL: a blob produced by the pre-change code decrypts unchanged."""
    monkeypatch.setenv("SESSION_SECRET", LEGACY_SECRET)
    assert crypto.decrypt_secret(LEGACY_CIPHERTEXT) == LEGACY_PLAINTEXT


def test_backcompat_live_v1_format(monkeypatch):
    monkeypatch.setenv("SESSION_SECRET", "sess-xyz")
    legacy = _old_v1("sess-xyz", "old-cred")
    assert crypto.decrypt_secret(legacy) == "old-cred"
    assert crypto.needs_rotation(legacy) is True   # v1 cost → wants re-encrypt


def test_dedicated_key_decoupled_from_session_secret(monkeypatch):
    """Vault key (AVA_CRED_KEY) must be independent of the JWT key (SESSION_SECRET)."""
    monkeypatch.setenv("AVA_CRED_KEY", "vault-key-1")
    monkeypatch.setenv("SESSION_SECRET", "jwt-key-unrelated")
    ct = crypto.encrypt_secret("api-token-value")

    # Rotating the JWT key must NOT affect decryptability of vault data.
    monkeypatch.setenv("SESSION_SECRET", "jwt-key-rotated")
    assert crypto.decrypt_secret(ct) == "api-token-value"

    # And data encrypted under the dedicated key must NOT decrypt from
    # SESSION_SECRET alone (proves it isn't secretly using the JWT key).
    monkeypatch.delenv("AVA_CRED_KEY", raising=False)
    with pytest.raises(RuntimeError):
        crypto.decrypt_secret(ct)


def test_ava_cred_key_introduced_later_still_reads_old_data(monkeypatch):
    """Data written when only SESSION_SECRET existed must decrypt after a
    dedicated AVA_CRED_KEY is introduced (SESSION_SECRET kept as fallback)."""
    monkeypatch.setenv("SESSION_SECRET", "sess-legacy")
    ct = crypto.encrypt_secret("cred-before-split")
    monkeypatch.setenv("AVA_CRED_KEY", "new-dedicated-vault-key")
    assert crypto.decrypt_secret(ct) == "cred-before-split"


def test_dual_decrypt_and_rotation_roundtrip(monkeypatch):
    # 1) encrypt under the OLD key
    monkeypatch.setenv("SESSION_SECRET", "old-key")
    ct_old = crypto.encrypt_secret("rotate-me")

    # 2) rotate: new primary + old kept as SESSION_SECRET_OLD → dual-decrypt
    monkeypatch.setenv("SESSION_SECRET", "new-key")
    monkeypatch.setenv("SESSION_SECRET_OLD", "old-key")
    assert crypto.decrypt_secret(ct_old) == "rotate-me"
    assert crypto.needs_rotation(ct_old) is True

    # 3) re-encrypt under the new key (what rotate_secrets.py does)
    new_val, status = plan_crypto_value(ct_old)
    assert status == "rotate"

    # 4) retire the old key entirely — new value must still decrypt
    monkeypatch.delenv("SESSION_SECRET_OLD", raising=False)
    assert crypto.decrypt_secret(new_val) == "rotate-me"
    assert crypto.needs_rotation(new_val) is False


def test_plan_crypto_value_statuses(monkeypatch):
    monkeypatch.setenv("SESSION_SECRET", "k")
    # already current → skip
    cur = crypto.encrypt_secret("x")
    assert plan_crypto_value(cur) == (None, "skip")
    # legacy plaintext → backfill
    new_val, status = plan_crypto_value("plaintext-pw")
    assert status == "backfill" and crypto.decrypt_secret(new_val) == "plaintext-pw"
    # plaintext with backfill disabled → skip
    assert plan_crypto_value("plaintext-pw", include_plaintext=False) == (None, "skip")
    # empty / None → skip
    assert plan_crypto_value("") == (None, "skip")
    assert plan_crypto_value(None) == (None, "skip")


def test_idempotent_second_run_is_noop(monkeypatch):
    monkeypatch.setenv("SESSION_SECRET", "new-key")
    monkeypatch.setenv("SESSION_SECRET_OLD", "old-key")
    # a value under the OLD key rotates once...
    monkeypatch.setenv("SESSION_SECRET", "old-key")
    ct_old = crypto.encrypt_secret("v")
    monkeypatch.setenv("SESSION_SECRET", "new-key")
    rotated, status = plan_crypto_value(ct_old)
    assert status == "rotate"
    # ...and a second pass over the rotated value is a no-op.
    assert plan_crypto_value(rotated) == (None, "skip")


def test_fail_loud_when_no_key(monkeypatch):
    with pytest.raises(RuntimeError):
        crypto.encrypt_secret("x")
    with pytest.raises(RuntimeError):
        crypto.decrypt_secret("enc:v2:anything")


def test_passthrough_none_empty_and_plaintext(monkeypatch):
    monkeypatch.setenv("SESSION_SECRET", "k")
    assert crypto.encrypt_secret(None) is None
    assert crypto.encrypt_secret("") == ""
    assert crypto.decrypt_secret(None) is None
    assert crypto.decrypt_secret("legacy-plaintext") == "legacy-plaintext"
    # double-encrypt guard
    ct = crypto.encrypt_secret("v")
    assert crypto.encrypt_secret(ct) == ct
