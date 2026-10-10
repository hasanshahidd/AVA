"""Tenant-secret encryption helper for credentials at rest.

Banks reject any product that stores integration passwords / API keys in
plaintext — they fail audits on it. This module wraps Fernet (AES-128-CBC
HMAC-SHA256) so the `grc_integration_connections.password` column (and any
other secret-bearing field we add later) is stored encrypted.

Wire-format
-----------
Encrypted values carry a ``enc:<kdf-version>:`` prefix so any read path can
distinguish "already encrypted" from "legacy plaintext" AND know which KDF
parameters derived the key, without a schema migration:

    "enc:v2:gAAAAABoUhT..."  → encrypted, PBKDF2 @ 600k iterations (current)
    "enc:v1:gAAAAABoUhT..."  → encrypted, PBKDF2 @ 200k iterations (legacy)
    "MyOldPassword123"        → legacy plaintext, return as-is + warn

New encryptions always use the current version; old versions still decrypt.
This lets us raise the KDF cost over time without a hard cutover.

Key derivation
--------------
The Fernet key is derived via PBKDF2-HMAC-SHA256 from a vault secret. The vault
secret is read, in priority order, from:

    1. ``AVA_CRED_KEY``      — dedicated vault key (preferred).
    2. ``SESSION_SECRET``    — fallback. Historically the vault key WAS the JWT
                               signing key; keeping it as a fallback means every
                               existing ciphertext still decrypts for free.

Rotation
--------
Rotating the vault key would make every stored credential undecryptable, so
decrypt is dual-key: it tries the current vault secret, then ``SESSION_SECRET``
(in case ``AVA_CRED_KEY`` was introduced after the data was written), then
``SESSION_SECRET_OLD`` (a value rotated out but not yet re-encrypted away).
To actually retire an old key: set it as ``SESSION_SECRET_OLD``, point the new
value at ``AVA_CRED_KEY`` (or ``SESSION_SECRET``), run
``grc/scripts/rotate_secrets.py`` to re-encrypt everything under the new key,
then unset ``SESSION_SECRET_OLD``.

Threat model
------------
Protects against: DB dump exfiltration, backup tape theft, read-only DB
access by support staff.

Does NOT protect against: a compromised backend (the key lives in env;
process can decrypt). For that level of paranoia, integrate with a real
KMS (AWS KMS / Azure Key Vault / HashiCorp Vault) — same wire format,
swap out the key derivation.
"""
from __future__ import annotations

import base64
import logging
import os
from functools import lru_cache
from typing import List, Optional

from cryptography.fernet import Fernet, InvalidToken
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC

logger = logging.getLogger(__name__)

_ENC_PREFIX = "enc:"  # every encrypted value starts with this (any KDF version)

# PBKDF2-HMAC-SHA256 iteration count per wire-format version. New data uses the
# current version; every listed version still decrypts old data. Bumping the
# cost is: add a version here, point _CURRENT_KDF_VERSION at it. Never remove a
# version while ciphertext encrypted under it may still exist in a DB.
_KDF_ITERATIONS = {
    "v1": 200_000,   # pre-2026 data
    "v2": 600_000,   # OWASP 2023 floor for PBKDF2-HMAC-SHA256
}
_CURRENT_KDF_VERSION = "v2"

# Stable salt — rotated together with the key. Don't change this without
# bumping the version AND running a re-encryption migration.
_KDF_SALT = b"complyverse-cred-vault-v1"


@lru_cache(maxsize=16)
def _fernet(secret: str, iterations: int) -> Fernet:
    """Derive a Fernet instance from a secret + iteration count. Cached so we
    don't re-run PBKDF2 (slow by design) on every call."""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=_KDF_SALT,
        iterations=iterations,
    )
    key = base64.urlsafe_b64encode(kdf.derive(secret.encode("utf-8")))
    return Fernet(key)


def _current_secret() -> str:
    """The vault secret NEW encryptions use. AVA_CRED_KEY if set, else the
    legacy SESSION_SECRET. Fail loud if neither is set — we refuse to silently
    no-op encryption so a missing secret is caught in staging, not prod."""
    secret = os.environ.get("AVA_CRED_KEY") or os.environ.get("SESSION_SECRET")
    if not secret:
        raise RuntimeError(
            "AVA_CRED_KEY or SESSION_SECRET env var is required for credential "
            "encryption. Set one in your .env before starting the backend."
        )
    return secret


def _candidate_secrets() -> List[str]:
    """Vault secrets that may have produced a stored ciphertext, in try order:
    the dedicated key, the legacy/fallback key, then a rotated-out key. Deduped,
    order preserved (so the common case — current key — is tried first)."""
    out: List[str] = []
    for env in ("AVA_CRED_KEY", "SESSION_SECRET", "SESSION_SECRET_OLD"):
        v = os.environ.get(env)
        if v and v not in out:
            out.append(v)
    return out


def encrypt_secret(plaintext: Optional[str]) -> Optional[str]:
    """Encrypt a credential value with the current key + current KDF version.

    Returns ``None``/``""`` unchanged (so we don't store an "encrypted empty
    string" in nullable columns — keeps the DB clean). Already-encrypted input
    passes through untouched so a double-encrypt can't corrupt a blob.
    """
    if plaintext is None or plaintext == "":
        return plaintext
    if plaintext.startswith(_ENC_PREFIX):
        return plaintext
    iterations = _KDF_ITERATIONS[_CURRENT_KDF_VERSION]
    token = _fernet(_current_secret(), iterations).encrypt(plaintext.encode("utf-8")).decode("ascii")
    return f"{_ENC_PREFIX}{_CURRENT_KDF_VERSION}:{token}"


def _parse(value: str) -> tuple[str, bytes]:
    """Split ``enc:<version>:<token>`` → (version, token-bytes). Fernet tokens
    are url-safe base64 (no ``:``) so a 2-split is unambiguous."""
    try:
        _prefix, version, token = value.split(":", 2)
    except ValueError:
        raise RuntimeError(
            "Malformed encrypted credential (expected 'enc:<version>:<token>')."
        )
    if version not in _KDF_ITERATIONS:
        raise RuntimeError(
            f"Unknown credential KDF version {version!r}; this backend is older "
            "than the data. Upgrade before decrypting."
        )
    return version, token.encode("ascii")


def decrypt_secret(value: Optional[str]) -> Optional[str]:
    """Decrypt a credential value. Legacy plaintext rows pass through unchanged
    so the system keeps working during a rolling backfill.

    Dual-key: tries the current vault secret, then SESSION_SECRET, then
    SESSION_SECRET_OLD — so data survives both the AVA_CRED_KEY split and a
    key rotation (as long as the old value is still in SESSION_SECRET_OLD)."""
    if value is None or value == "":
        return value
    if not value.startswith(_ENC_PREFIX):
        # Legacy plaintext row — return as-is and warn so ops can see how many
        # unencrypted creds are still in flight.
        logger.warning(
            "credential.legacy_plaintext encountered — schedule a re-encrypt"
        )
        return value

    version, token = _parse(value)
    iterations = _KDF_ITERATIONS[version]
    secrets = _candidate_secrets()
    if not secrets:
        raise RuntimeError(
            "AVA_CRED_KEY or SESSION_SECRET env var is required to decrypt "
            "credentials. Set one in your .env before starting the backend."
        )
    for secret in secrets:
        try:
            return _fernet(secret, iterations).decrypt(token).decode("utf-8")
        except InvalidToken:
            continue
    # Every candidate key failed — most common cause is the key was rotated
    # without running the migration (and without leaving SESSION_SECRET_OLD set).
    logger.error("credential.decrypt_failed — key may have rotated")
    raise RuntimeError(
        "Credential decryption failed. The vault key may have changed since "
        "this connection was created — set SESSION_SECRET_OLD to the previous "
        "value and run rotate_secrets.py, or re-enter credentials via "
        "Administration → Integrations."
    )


def is_encrypted(value: Optional[str]) -> bool:
    return bool(value) and value.startswith(_ENC_PREFIX)


def needs_rotation(value: Optional[str]) -> bool:
    """True if ``value`` is an encrypted blob that does NOT already decrypt under
    the CURRENT primary vault secret at the CURRENT KDF version. Lets the rotate
    script stay idempotent: a second run re-encrypts nothing. Plaintext/None
    returns False (rotation is a key→key operation; the script handles
    opportunistic plaintext encryption separately)."""
    if not is_encrypted(value):
        return False
    try:
        version, token = _parse(value)  # type: ignore[arg-type]
    except RuntimeError:
        return True  # malformed/unknown — let the script attempt a repair
    if version != _CURRENT_KDF_VERSION:
        return True  # old KDF cost — re-encrypt to raise it
    try:
        _fernet(_current_secret(), _KDF_ITERATIONS[version]).decrypt(token)
        return False  # already under the current primary key at current version
    except InvalidToken:
        return True  # decrypts only under a fallback/old key — needs re-encrypt


__all__ = ["encrypt_secret", "decrypt_secret", "is_encrypted", "needs_rotation"]
