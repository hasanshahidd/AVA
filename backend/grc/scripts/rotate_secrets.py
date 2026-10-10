"""Re-encrypt stored credentials under the current vault key.

Rotating the vault key (``AVA_CRED_KEY`` / ``SESSION_SECRET``) makes every
credential encrypted under the OLD key undecryptable once the old value is
removed from the environment. ``grc.crypto`` / ``grc.security.secret_encryption``
dual-decrypt (current key, then ``SESSION_SECRET``, then ``SESSION_SECRET_OLD``)
so nothing breaks WHILE the old value is still present as ``SESSION_SECRET_OLD`` —
this script is what lets you finally RETIRE the old value: it walks every tenant
DB and re-encrypts each stored secret under the current primary key + current
KDF cost, so ``SESSION_SECRET_OLD`` can be unset afterwards.

Scope (per the handoff ticket):
  * ``CredentialProfile.secret_encrypted``          (grc.crypto wire format)
  * ``IdentityProviderConfig.client_secret_encrypted`` (grc.security bytes)

NOT covered: integration-connection ``password`` / ``extra`` blobs. Those keep
working via dual-decrypt as long as ``SESSION_SECRET_OLD`` stays set; add them to
``_FIELD_SPECS`` when you want to retire the old key for those too.

Usage (run from backend/):
    python -m grc.scripts.rotate_secrets                # DRY RUN — reports only
    python -m grc.scripts.rotate_secrets --apply        # actually re-encrypt
    python -m grc.scripts.rotate_secrets --tenant ubl   # scope to one tenant
    python -m grc.scripts.rotate_secrets --no-plaintext # skip legacy-plaintext backfill

Safety:
  * DRY RUN is the default. Nothing is written without ``--apply``.
  * Idempotent: a value already under the current key + version is skipped, so
    re-running (even after a partial run) is safe.
  * Fail-loud: aborts immediately if no vault key is set in the environment.
  * NEVER prints a secret value — only counts and row ids.
"""
from __future__ import annotations

import argparse
import os
import sys
from typing import Optional, Tuple

# Allow both `python -m grc.scripts.rotate_secrets` and a direct file run.
_BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
if _BACKEND_DIR not in sys.path:
    sys.path.insert(0, _BACKEND_DIR)

# Best-effort .env load (the backend uses one in dev); harmless if absent.
try:  # pragma: no cover
    from dotenv import load_dotenv

    load_dotenv()
except Exception:  # pragma: no cover
    pass

from grc.crypto import decrypt_secret, encrypt_secret, is_encrypted, needs_rotation
from grc.security import secret_encryption


# ---------------------------------------------------------------------------
# Pure planning helpers (unit-tested without a DB — see tests/test_crypto_rotation.py)
# ---------------------------------------------------------------------------

def plan_crypto_value(old: Optional[str], include_plaintext: bool = True) -> Tuple[Optional[str], str]:
    """Decide the new value for a ``grc.crypto``-encrypted string field.

    Returns ``(new_value, status)``; ``status`` is one of
    ``"skip" | "rotate" | "backfill"`` and ``new_value`` is ``None`` on skip.
    """
    if old is None or old == "":
        return None, "skip"
    if is_encrypted(old):
        if needs_rotation(old):
            return encrypt_secret(decrypt_secret(old)), "rotate"
        return None, "skip"
    # Not encrypted at all → legacy plaintext row.
    if include_plaintext:
        return encrypt_secret(old), "backfill"
    return None, "skip"


def plan_idp_value(ciphertext) -> Tuple[Optional[bytes], str]:
    """Decide the new value for the ``grc.security`` raw-bytes field.

    Returns ``(new_value, status)``; ``status`` is ``"skip" | "rotate"``.
    """
    if ciphertext is None or (isinstance(ciphertext, (bytes, bytearray)) and len(ciphertext) == 0):
        return None, "skip"
    if secret_encryption.needs_rotation(bytes(ciphertext)):
        return secret_encryption.rotate(bytes(ciphertext)), "rotate"
    return None, "skip"


# ---------------------------------------------------------------------------
# DB walk
# ---------------------------------------------------------------------------

def _preflight() -> None:
    """Fail loud before touching any DB if no vault key is configured."""
    if not (os.environ.get("AVA_CRED_KEY") or os.environ.get("SESSION_SECRET")):
        raise SystemExit(
            "ABORT: no vault key set. Export AVA_CRED_KEY (or SESSION_SECRET) "
            "before running the rotation."
        )


def _tenant_slugs(only: Optional[str]) -> list[str]:
    from grc.db import MasterSession
    from grc.models import Tenant

    db = MasterSession()
    try:
        q = db.query(Tenant)
        if hasattr(Tenant, "is_active"):
            q = q.filter((Tenant.is_active == True) | (Tenant.is_active.is_(None)))  # noqa: E712
        slugs = []
        for t in q.all():
            slug = getattr(t, "slug", None) or getattr(t, "schema_name", None)
            if slug and (only is None or slug == only):
                slugs.append(slug)
        return slugs
    finally:
        db.close()


def _rotate_tenant(slug: str, apply: bool, include_plaintext: bool) -> dict:
    from grc.db import open_tenant_session
    from grc.models import CredentialProfile, IdentityProviderConfig

    stats = {"cred_scanned": 0, "cred_rotated": 0, "cred_backfilled": 0,
             "idp_scanned": 0, "idp_rotated": 0, "errors": 0}
    db = open_tenant_session(slug)
    try:
        # CredentialProfile.secret_encrypted (grc.crypto)
        try:
            for prof in db.query(CredentialProfile).all():
                stats["cred_scanned"] += 1
                new, status = plan_crypto_value(prof.secret_encrypted, include_plaintext)
                if status == "rotate":
                    stats["cred_rotated"] += 1
                    if apply:
                        prof.secret_encrypted = new
                elif status == "backfill":
                    stats["cred_backfilled"] += 1
                    if apply:
                        prof.secret_encrypted = new
        except Exception as exc:  # table may not exist on an old tenant DB
            stats["errors"] += 1
            print(f"  [{slug}] CredentialProfile skipped: {type(exc).__name__}: {exc}")

        # IdentityProviderConfig.client_secret_encrypted (grc.security)
        try:
            for cfg in db.query(IdentityProviderConfig).all():
                if cfg.client_secret_encrypted is None:
                    continue
                stats["idp_scanned"] += 1
                new, status = plan_idp_value(cfg.client_secret_encrypted)
                if status == "rotate":
                    stats["idp_rotated"] += 1
                    if apply:
                        cfg.client_secret_encrypted = new
        except Exception as exc:
            stats["errors"] += 1
            print(f"  [{slug}] IdentityProviderConfig skipped: {type(exc).__name__}: {exc}")

        if apply:
            db.commit()
        else:
            db.rollback()
    finally:
        db.close()
    return stats


def main(argv: Optional[list[str]] = None) -> int:
    parser = argparse.ArgumentParser(description="Re-encrypt stored credentials under the current vault key.")
    parser.add_argument("--apply", action="store_true", help="actually write (default is a dry run)")
    parser.add_argument("--tenant", default=None, help="limit to a single tenant slug")
    parser.add_argument("--no-plaintext", action="store_true",
                        help="do NOT backfill-encrypt legacy plaintext rows")
    args = parser.parse_args(argv)

    _preflight()

    mode = "APPLY" if args.apply else "DRY RUN"
    print(f"=== rotate_secrets [{mode}] ===")
    slugs = _tenant_slugs(args.tenant)
    if not slugs:
        print("No tenants found.")
        return 0

    totals = {"cred_scanned": 0, "cred_rotated": 0, "cred_backfilled": 0,
              "idp_scanned": 0, "idp_rotated": 0, "errors": 0}
    for slug in slugs:
        s = _rotate_tenant(slug, apply=args.apply, include_plaintext=not args.no_plaintext)
        for k in totals:
            totals[k] += s[k]
        print(f"  [{slug}] creds: {s['cred_rotated']} rotated / {s['cred_backfilled']} backfilled "
              f"/ {s['cred_scanned']} scanned | idp: {s['idp_rotated']} rotated / {s['idp_scanned']} scanned")

    print("--- totals ---")
    print(f"  credential profiles : {totals['cred_rotated']} rotated, "
          f"{totals['cred_backfilled']} backfilled, {totals['cred_scanned']} scanned")
    print(f"  identity providers  : {totals['idp_rotated']} rotated, {totals['idp_scanned']} scanned")
    if totals["errors"]:
        print(f"  errors (tables skipped): {totals['errors']}")
    if not args.apply:
        print("DRY RUN — nothing written. Re-run with --apply to commit.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
