"""Fernet-based encryption for at-rest secrets stored in the per-tenant DB.

Used today for the Microsoft Entra ID client secret
(``grc_identity_provider_configs.client_secret_encrypted``). Designed to be
reusable for any other integration secret.

Unlike ``grc.crypto`` (which prefixes a KDF-version onto its ciphertext), the
column here is a raw ``LargeBinary`` holding a bare Fernet token — there is no
room for our own version marker. So key/cost versioning is handled by TRYING
each candidate key in turn via ``MultiFernet``: a Fernet token authenticates,
so a wrong key fails cleanly and we fall through to the next.

Key resolution (NEW encryptions use the first available):
  1. ``INTEGRATION_ENCRYPTION_KEY`` — an explicit 32-byte url-safe base64 Fernet
     key (no KDF).
  2. ``AVA_CRED_KEY`` — dedicated vault secret, PBKDF2 @ 600k.
  3. ``SESSION_SECRET`` — legacy/fallback vault secret, PBKDF2 @ 600k.

DECRYPTION additionally falls back to the 200k-iteration derivations (how old
ciphertext was written) and to ``SESSION_SECRET_OLD`` (a rotated-out key), so
existing data keeps decrypting across both a KDF-cost bump and a key rotation.

If no key material is available at all we raise rather than silently falling
back to plaintext storage.
"""

from __future__ import annotations

import base64
import os
from functools import lru_cache
from typing import List

from cryptography.fernet import Fernet, InvalidToken, MultiFernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC


# Constant salt is acceptable here because the input keying material
# (AVA_CRED_KEY / SESSION_SECRET) is itself high-entropy and per-deployment.
_DERIVATION_SALT = b"grc-integration-encryption-v1"

# PBKDF2 iteration counts tried on decrypt. The first (current) is used for new
# encryptions; the legacy cost is kept so pre-2026 ciphertext still decrypts.
_KDF_ITERATIONS_CURRENT = 600_000  # OWASP 2023 floor
_KDF_ITERATIONS_LEGACY = 200_000   # pre-2026 data


class EncryptionKeyMissing(RuntimeError):
    """Raised when no key material (explicit key or vault secret) is available."""


@lru_cache(maxsize=1)
def _explicit_fernet(explicit_key: str) -> Fernet:
    try:
        return Fernet(explicit_key.encode("utf-8"))
    except Exception as exc:  # surfaces an obvious config error
        raise EncryptionKeyMissing(
            "INTEGRATION_ENCRYPTION_KEY is set but is not a valid Fernet key "
            "(must be 32 url-safe base64 bytes). Generate one with "
            "`python -c 'from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())'`."
        ) from exc


@lru_cache(maxsize=32)
def _derived_fernet(secret: str, iterations: int) -> Fernet:
    """PBKDF2-derive a Fernet from a vault secret + cost. Cached so the (slow)
    derivation runs once per (secret, cost), not per encrypt/decrypt call."""
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=_DERIVATION_SALT,
        iterations=iterations,
    )
    raw = kdf.derive(secret.encode("utf-8"))
    return Fernet(base64.urlsafe_b64encode(raw))


def _candidate_fernets() -> List[Fernet]:
    """Ordered Fernets to try. index 0 is used for new encryptions; the rest are
    decrypt-only fallbacks (legacy KDF cost, rotated-out key). Built fresh each
    call (cheap — derivations are cached) so env changes are honoured."""
    out: List[Fernet] = []

    explicit = os.getenv("INTEGRATION_ENCRYPTION_KEY", "").strip()
    if explicit:
        out.append(_explicit_fernet(explicit))

    ava = os.getenv("AVA_CRED_KEY", "").strip()
    session = os.getenv("SESSION_SECRET", "").strip()
    old = os.getenv("SESSION_SECRET_OLD", "").strip()

    # Current cost first (new data), then legacy cost (old data), per secret.
    for secret in (ava, session):
        if secret:
            out.append(_derived_fernet(secret, _KDF_ITERATIONS_CURRENT))
    for secret in (ava, session):
        if secret:
            out.append(_derived_fernet(secret, _KDF_ITERATIONS_LEGACY))
    if old:
        out.append(_derived_fernet(old, _KDF_ITERATIONS_CURRENT))
        out.append(_derived_fernet(old, _KDF_ITERATIONS_LEGACY))

    if not out:
        raise EncryptionKeyMissing(
            "Cannot encrypt/decrypt integration secrets: none of "
            "INTEGRATION_ENCRYPTION_KEY, AVA_CRED_KEY, or SESSION_SECRET is set "
            "in the environment."
        )
    return out


def encrypt(plaintext: str) -> bytes:
    """Encrypt a UTF-8 string with the current primary key. Returns Fernet
    ciphertext bytes (store in the LargeBinary column)."""
    if plaintext is None:
        raise ValueError("Cannot encrypt None")
    return MultiFernet(_candidate_fernets()).encrypt(plaintext.encode("utf-8"))


def decrypt(ciphertext: bytes) -> str:
    """Decrypt Fernet ciphertext back to a string, trying every candidate key
    (dual-key + dual-cost) so old ciphertext survives key/cost changes."""
    if ciphertext is None:
        raise ValueError("Cannot decrypt None")
    return MultiFernet(_candidate_fernets()).decrypt(bytes(ciphertext)).decode("utf-8")


def rotate(ciphertext: bytes) -> bytes:
    """Re-encrypt existing ciphertext under the current primary key without
    exposing the plaintext. No-op-safe: if it already decrypts under the primary
    key, MultiFernet.rotate returns an equivalent token under that same key."""
    if ciphertext is None:
        raise ValueError("Cannot rotate None")
    return MultiFernet(_candidate_fernets()).rotate(bytes(ciphertext))


def needs_rotation(ciphertext: bytes) -> bool:
    """True if ``ciphertext`` does NOT decrypt under the CURRENT primary key
    (so it was written under a fallback/old key and should be re-encrypted).
    Lets the rotate script stay idempotent on this raw-bytes column, which —
    unlike grc.crypto's wire format — carries no version marker to inspect."""
    if ciphertext is None:
        return False
    primary = _candidate_fernets()[0]
    try:
        primary.decrypt(bytes(ciphertext))
        return False
    except InvalidToken:
        return True


__all__ = ["encrypt", "decrypt", "rotate", "needs_rotation", "EncryptionKeyMissing"]
