"""Parse an uploaded sheet, commit rows to ITAsset, and undo a batch.

Stateless: the client re-sends the file on /commit with the confirmed mapping,
so nothing is stored server-side between analyze and commit. Row -> asset upsert
mirrors the existing template importer (dedupe by name/host/ip, criticality
recompute, OS normalization) but lives here so the existing endpoint is untouched.
"""
from __future__ import annotations

import csv
import io
import uuid
from typing import Any, Dict, List, Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from grc.models import ITAsset
from . import mapping as M

_VALID_TYPE = {"application", "infrastructure", "data", "cloud", "third_party"}
_MAX_ROWS = 5000  # ponytail: v1 cap; raise + stream when a client needs more


# ── file parsing ─────────────────────────────────────────────────────────────
def _load_grid(content: bytes, filename: str) -> List[List[Any]]:
    """Raw grid (list of rows) of the file's active sheet. CSV + XLSX only."""
    name = (filename or "").lower()
    if name.endswith(".csv"):
        text = content.decode("utf-8-sig", errors="replace")
        return [list(r) for r in csv.reader(io.StringIO(text))]
    if name.endswith(".xlsx"):
        from openpyxl import load_workbook
        wb = load_workbook(io.BytesIO(content), read_only=True, data_only=True)
        try:
            ws = wb.active
            return [list(r) for r in ws.iter_rows(values_only=True)]
        finally:
            wb.close()
    raise ValueError("Unsupported file type — upload .csv or .xlsx (convert .xls to .xlsx first).")


def _clean(grid: List[List[Any]]) -> List[List[Any]]:
    return [r for r in grid if any(str(c if c is not None else "").strip() for c in r)]


# ── analyze (no writes) ──────────────────────────────────────────────────────
def analyze(content: bytes, filename: str) -> Dict[str, Any]:
    grid = _clean(_load_grid(content, filename))
    if not grid:
        raise ValueError("No data rows found in the file.")
    hidx = M.detect_header_row(grid)
    headers = [str(c if c is not None else "").strip() for c in grid[hidx]]
    data = grid[hidx + 1:]
    columns = [[row[i] for row in data[:25] if i < len(row)] for i in range(len(headers))]
    suggested = M.guess_mapping(headers, columns)
    samples = [
        {headers[i]: (row[i] if i < len(row) else None) for i in range(len(headers)) if headers[i]}
        for row in data[:8]
    ]
    return {
        "filename": filename,
        "header_row": hidx,
        "columns": [h for h in headers if h],
        "row_count": len(data),
        "sample_rows": samples,
        "suggested_mapping": {h: v for h, v in suggested.items() if h},
        "canonical_fields": [
            {"key": k, "label": v["label"], "required": bool(v.get("required"))}
            for k, v in M.CANONICAL_FIELDS.items()
        ],
    }


# ── commit ───────────────────────────────────────────────────────────────────
def _stash(asset: ITAsset, key: str, val: Any) -> None:
    """Extra (unmapped) fields go into platform_properties JSON — no schema change."""
    if not hasattr(asset, "platform_properties"):
        return
    props = dict(getattr(asset, "platform_properties", None) or {})
    props.setdefault("import_extra", {})[key] = val
    asset.platform_properties = props


def _apply(asset: ITAsset, rec: Dict[str, Any], normalize_os) -> None:
    for f, v in rec.items():
        if f == "asset_type":
            v = v if v in _VALID_TYPE else "infrastructure"
        elif f == "os_family" and normalize_os:
            try:
                v = normalize_os(str(v)) or v
            except Exception:  # noqa: BLE001
                pass
        if hasattr(asset, f):
            setattr(asset, f, v)
        else:
            _stash(asset, f, v)
    if hasattr(asset, "asset_type") and not getattr(asset, "asset_type", None):
        asset.asset_type = "infrastructure"


def _tag(asset: ITAsset, batch: str, filename: str, created: bool) -> None:
    """Batch id ONLY on created rows so undo can never delete a pre-existing
    asset that an import merely refreshed."""
    if not hasattr(asset, "platform_properties"):
        return
    props = dict(getattr(asset, "platform_properties", None) or {})
    if created:
        props["import_batch"] = batch
    props["import_source_file"] = filename
    asset.platform_properties = props


def commit(db: Session, tenant_id: int, content: bytes, filename: str,
           colmap: Dict[str, Optional[str]], dupe_strategy: str = "skip",
           header_row: Optional[int] = None) -> Dict[str, Any]:
    grid = _clean(_load_grid(content, filename))
    if not grid:
        raise ValueError("No data rows found in the file.")
    hidx = header_row if header_row is not None else M.detect_header_row(grid)
    headers = [str(c if c is not None else "").strip() for c in grid[hidx]]
    data = grid[hidx + 1:]
    if len(data) > _MAX_ROWS:
        raise ValueError(f"File has {len(data)} rows; the limit for one import is {_MAX_ROWS}.")

    field_by_col = {h: f for h, f in (colmap or {}).items() if f}
    if "name" not in field_by_col.values() and not any(
        f in field_by_col.values() for f in ("host_name", "ip_address")
    ):
        raise ValueError("Map at least one column to Asset name (or hostname / IP).")

    try:
        from grc.services.asset_criticality import recompute_for_asset
    except Exception:  # noqa: BLE001
        recompute_for_asset = None
    try:
        from grc.modules.compliance_plugins.services.os_detector import normalize_os_string
    except Exception:  # noqa: BLE001
        normalize_os_string = None

    batch = uuid.uuid4().hex[:12]
    created = updated = skipped = 0
    errors: List[str] = []

    for rn, row in enumerate(data, start=1):
        try:
            rec = M.apply_mapping(headers, row, field_by_col)
            ident = rec.get("name") or rec.get("host_name") or rec.get("ip_address")
            if not ident:
                errors.append(f"Row {rn}: no name / hostname / IP — skipped")
                continue
            rec.setdefault("name", str(ident))

            q = db.query(ITAsset).filter(ITAsset.tenant_id == tenant_id)
            existing = q.filter(func.lower(ITAsset.name) == str(rec["name"]).lower()).first()
            if not existing and rec.get("host_name"):
                existing = q.filter(ITAsset.host_name == rec["host_name"]).first()
            if not existing and rec.get("ip_address"):
                existing = q.filter(ITAsset.ip_address == rec["ip_address"]).first()

            if existing:
                if dupe_strategy != "update":
                    skipped += 1
                    continue
                _apply(existing, rec, normalize_os_string)
                _tag(existing, batch, filename, created=False)
                if recompute_for_asset:
                    try:
                        recompute_for_asset(db, existing)
                    except Exception:  # noqa: BLE001
                        pass
                updated += 1
            else:
                asset = ITAsset(tenant_id=tenant_id)
                _apply(asset, rec, normalize_os_string)
                if hasattr(asset, "origin_source"):
                    asset.origin_source = "import"
                _tag(asset, batch, filename, created=True)
                db.add(asset)
                db.flush()
                if recompute_for_asset:
                    try:
                        recompute_for_asset(db, asset)
                    except Exception:  # noqa: BLE001
                        pass
                created += 1
        except Exception as e:  # noqa: BLE001 — one bad row must not kill the batch
            errors.append(f"Row {rn}: {e}")

    db.commit()
    changed = created + updated
    return {
        "created": created,
        "updated": updated,
        "skipped": skipped,
        "errors": errors[:50],
        "total_errors": len(errors),
        "row_count": len(data),
        "batch_id": batch,
        "message": (f"Imported {created} new, updated {updated}, skipped {skipped}."
                    if changed or skipped else "Nothing imported."),
    }


# ── undo ─────────────────────────────────────────────────────────────────────
def undo(db: Session, tenant_id: int, batch_id: str) -> Dict[str, Any]:
    """Delete only the assets CREATED by this batch (batch id lives on created
    rows only). Guarded per-asset so a row that has since gained children (FK)
    is reported rather than aborting the whole undo."""
    rows = db.query(ITAsset).filter(ITAsset.tenant_id == tenant_id).all()
    victims = [
        a for a in rows
        if (getattr(a, "platform_properties", None) or {}).get("import_batch") == batch_id
    ]
    deleted = failed = 0
    for a in victims:
        try:
            db.delete(a)
            db.flush()
            deleted += 1
        except Exception:  # noqa: BLE001
            db.rollback()
            failed += 1
    db.commit()
    return {
        "deleted": deleted,
        "failed": failed,
        "batch_id": batch_id,
        "message": f"Removed {deleted} imported asset(s)." + (f" {failed} could not be removed (in use)." if failed else ""),
    }
