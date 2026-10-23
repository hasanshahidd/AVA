"""Automatic ORM-level before/after field-diff capture for the audit log.

A single SQLAlchemy ``before_flush`` listener (attached to the base ``Session``
class) records column-level changes for every create / update / delete made on a
TENANT session during an audited HTTP request. The changes accumulate on a
request-scoped ``ContextVar`` which ``audit_logger.write_audit_log`` folds into
the single ``AuditLog`` row it already writes (``changes["field_changes"]``) —
no extra rows, no DB migration.

Design notes
------------
* Scoped to tenant sessions only (``session.info["tenant_slug"]`` is set by
  ``db.open_tenant_session``) so the master catalog session and any ad-hoc
  sessions are ignored.
* The audit table itself (``grc_audit_logs``) is skipped so the audit-write's
  own INSERT is never captured.
* Tenant sessionmakers use ``autoflush=False`` (see ``db.py``), so ``before_flush``
  fires on explicit flush/commit only — no partial-state double capture.
* Bullet-proof: every failure is swallowed so audit capture can never break or
  roll back the caller's transaction (mirrors ``rich_audit``).

Known limitation
----------------
Only ORM unit-of-work writes fire ``before_flush``. BULK / CORE statements —
``query(...).delete(synchronize_session=...)``, ``.update(synchronize_session=...)``,
``bulk_save_objects``/``bulk_*_mappings``, and raw ``db.execute(delete()/update())``
— bypass this listener and log NOTHING. Any such site must emit its own
``rich_audit.write_rich_audit_log`` event explicitly (see pentest ``delete_run``).
"""
from __future__ import annotations

import logging
from contextvars import ContextVar, Token
from datetime import date, datetime
from decimal import Decimal
from typing import Any, List, Optional
from uuid import UUID

from sqlalchemy import event, inspect as sa_inspect
from sqlalchemy.orm import Session

from .rich_audit import SENSITIVE_KEYS

logger = logging.getLogger(__name__)

# Request-scoped collector. None ⇒ not inside an audited request (don't capture).
_collector: ContextVar[Optional[List[dict]]] = ContextVar("audit_change_collector", default=None)

# Bookkeeping columns that change on nearly every write; pure noise in a diff.
_SKIP_FIELDS = {
    "updated_at", "created_at", "last_seen", "last_seen_at", "last_scanned",
    "last_scanned_at", "modified_at", "updated_on", "created_on",
    "last_activity_at",  # bumped on nearly every request; pure noise (last_login is kept)
}
# Never record changes to the audit table itself (the audit-write's own INSERT).
_SKIP_TABLES = {"grc_audit_logs"}

_MAX_ENTITIES = 20          # per request
_MAX_FIELDS = 40            # per entity
_MAX_VALUE_LEN = 2048       # per value


def begin_capture() -> Token:
    """Start capturing for the current request. Returns a reset token."""
    return _collector.set([])


def end_capture(token: Optional[Token]) -> List[dict]:
    """Return the captured changes and clear the collector."""
    changes = _collector.get() or []
    try:
        if token is not None:
            _collector.reset(token)
        else:
            _collector.set(None)
    except Exception:
        _collector.set(None)
    return changes


def _coerce(v: Any) -> Any:
    if v is None or isinstance(v, (bool, int, float)):
        return v
    if isinstance(v, str):
        return v if len(v) <= _MAX_VALUE_LEN else v[:_MAX_VALUE_LEN] + "…"
    if isinstance(v, (datetime, date)):
        return v.isoformat()
    if isinstance(v, (Decimal, UUID)):
        return str(v)
    s = str(v)
    return s if len(s) <= _MAX_VALUE_LEN else s[:_MAX_VALUE_LEN] + "…"


def _field(name: str, old: Any, new: Any) -> dict:
    if name.lower() in SENSITIVE_KEYS:
        return {"old": "***" if old is not None else None,
                "new": "***" if new is not None else None}
    return {"old": _coerce(old), "new": _coerce(new)}


def _table_and_mapper(obj):
    mapper = sa_inspect(obj).mapper
    table = mapper.local_table.name if mapper.local_table is not None else obj.__class__.__name__
    return table, mapper


def _pk(obj, mapper) -> Any:
    try:
        vals = [v for v in (getattr(obj, c.key, None) for c in mapper.primary_key) if v is not None]
        if not vals:
            return None
        return vals[0] if len(vals) == 1 else vals
    except Exception:
        return None


def _on_before_flush(session: Session, flush_context, instances) -> None:
    coll = _collector.get()
    if coll is None:
        return
    if not session.info.get("tenant_slug"):
        return  # tenant sessions only
    try:
        # ── updates ──────────────────────────────────────────────────────
        for obj in session.dirty:
            if len(coll) >= _MAX_ENTITIES:
                return
            if not session.is_modified(obj, include_collections=False):
                continue
            table, mapper = _table_and_mapper(obj)
            if table in _SKIP_TABLES:
                continue
            state = sa_inspect(obj)
            fields: dict = {}
            for attr in mapper.column_attrs:
                if attr.key in _SKIP_FIELDS or len(fields) >= _MAX_FIELDS:
                    continue
                hist = state.attrs[attr.key].history
                if not hist.has_changes():
                    continue
                old = hist.deleted[0] if hist.deleted else None
                new = hist.added[0] if hist.added else None
                fields[attr.key] = _field(attr.key, old, new)
            if fields:
                coll.append({"entity": table, "op": "update", "pk": _pk(obj, mapper), "fields": fields})
        # ── creates ──────────────────────────────────────────────────────
        for obj in session.new:
            if len(coll) >= _MAX_ENTITIES:
                return
            table, mapper = _table_and_mapper(obj)
            if table in _SKIP_TABLES:
                continue
            fields = {}
            for attr in mapper.column_attrs:
                if attr.key in _SKIP_FIELDS or len(fields) >= _MAX_FIELDS:
                    continue
                val = getattr(obj, attr.key, None)
                if val is None:
                    continue
                fields[attr.key] = _field(attr.key, None, val)
            if fields:
                coll.append({"entity": table, "op": "create", "pk": _pk(obj, mapper), "fields": fields})
        # ── deletes ──────────────────────────────────────────────────────
        for obj in session.deleted:
            if len(coll) >= _MAX_ENTITIES:
                return
            table, mapper = _table_and_mapper(obj)
            if table in _SKIP_TABLES:
                continue
            fields = {}
            for attr in mapper.column_attrs:
                if attr.key in _SKIP_FIELDS or len(fields) >= _MAX_FIELDS:
                    continue
                val = getattr(obj, attr.key, None)
                if val is None:
                    continue
                fields[attr.key] = _field(attr.key, val, None)
            if fields:
                coll.append({"entity": table, "op": "delete", "pk": _pk(obj, mapper), "fields": fields})
    except Exception:
        logger.debug("audit change capture failed; continuing", exc_info=True)


# Attach once to the base Session class so every tenant session is covered.
event.listen(Session, "before_flush", _on_before_flush)
