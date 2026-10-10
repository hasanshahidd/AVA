"""IT asset-inventory report generation.

Pulls the real IT asset estate and renders it as a professional asset-inventory
report. Two report types share one aggregation + rendering engine:

  inventory : full register (every asset, all columns) + estate summary
  executive : estate summary only (KPIs + breakdowns), no per-asset rows

Four standard downloadable formats: PDF, XLSX, CSV, HTML. The aggregation and
per-format rendering are DB-free (take a plain list of asset objects) so they
test without a database; only generate()/_load_assets() touch the session.
"""
from __future__ import annotations

import csv
import html
import io
from collections import Counter
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

from sqlalchemy.orm import Session

from grc.models import ITAsset
from .models import GeneratedAssetReport

# ── Report catalogue ────────────────────────────────────────────────────────
REPORTS: Dict[str, Dict[str, Any]] = {
    "inventory": {
        "title": "IT Asset Inventory Report",
        "detail": True,
        "description": (
            "Full asset register — every asset with identity, ownership, location, "
            "lifecycle, hardware and security classification — plus an estate "
            "breakdown summary. For auditors and operations."
        ),
    },
    "executive": {
        "title": "Executive Asset Estate Summary",
        "detail": False,
        "description": (
            "One-page leadership summary: estate KPIs and breakdowns by type, "
            "criticality, department, lifecycle, OS, environment and data "
            "classification. No per-asset rows."
        ),
    },
}
FORMATS = ["pdf", "xlsx", "csv", "html"]

_CT: Dict[str, Tuple[str, str]] = {
    "pdf": ("application/pdf", "pdf"),
    "xlsx": ("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "xlsx"),
    "csv": ("text/csv", "csv"),
    "html": ("text/html; charset=utf-8", "html"),
}

# Full detail columns (XLSX / CSV / HTML): (column key, header).
COLUMNS: List[Tuple[str, str]] = [
    ("id", "Asset ID"), ("name", "Asset Name"), ("asset_type", "Type"),
    ("criticality", "Criticality"), ("status", "Status"), ("lifecycle", "Lifecycle"),
    ("owner", "Owner"), ("department", "Department"), ("business_function", "Business Function"),
    ("location", "Location"), ("host_name", "Host Name"), ("fqdn", "FQDN"),
    ("ip_address", "IP Address"), ("os", "Operating System"), ("environment", "Environment"),
    ("manufacturer", "Manufacturer"), ("model", "Model"), ("serial_number", "Serial Number"),
    ("cpu_cores", "CPU (cores)"), ("memory_gb", "RAM (GB)"), ("storage_gb", "Storage (GB)"),
    ("data_classification", "Data Classification"), ("internet_facing", "Internet-Facing"),
    ("compliance_scope", "Compliance Scope"), ("vendor", "Vendor"),
    ("purchase_date", "Purchase Date"), ("purchase_cost", "Purchase Cost"),
    ("warranty_expiry", "Warranty Expiry"), ("eol_date", "EOL Date"),
    ("last_seen_at", "Last Seen"),
]
# Narrower subset for the PDF detail table (fits landscape letter).
PDF_KEYS = ["id", "name", "asset_type", "criticality", "owner", "department",
            "os", "ip_address", "environment", "status", "data_classification"]


# ── Cell formatting ──────────────────────────────────────────────────────────
def _d(v: Any) -> str:
    if isinstance(v, datetime):
        return v.date().isoformat()
    return str(v)


def _cell(a: Any, key: str) -> str:
    if key == "owner":
        v = getattr(a, "owner_name", None) or getattr(a, "assigned_user", None)
    elif key == "lifecycle":
        v = getattr(a, "lifecycle_state", None)
    elif key == "os":
        v = getattr(a, "os_version", None) or getattr(a, "os_family", None)
    elif key == "criticality":
        v = getattr(a, "criticality", None) or "Unrated"
    elif key == "internet_facing":
        return "Yes" if (getattr(a, "internet_facing", False) or getattr(a, "is_internet_facing", False)) else "No"
    elif key == "compliance_scope":
        v = getattr(a, "compliance_scope", None)
        if isinstance(v, (list, tuple)):
            v = ", ".join(str(x) for x in v)
    elif key == "purchase_cost":
        c = getattr(a, "purchase_cost", None)
        return f"{float(c):,.2f}" if c not in (None, "") else ""
    else:
        v = getattr(a, key, None)
    return _d(v) if v not in (None, "") else ""


def _record(a: Any) -> Dict[str, str]:
    return {k: _cell(a, k) for (k, _h) in COLUMNS}


# ── Aggregation ──────────────────────────────────────────────────────────────
def _past(v: Any) -> bool:
    return isinstance(v, datetime) and v < datetime.utcnow()


def _summary(assets: List[Any]) -> Dict[str, Any]:
    def tally(keyfn) -> Dict[str, int]:
        c: Counter = Counter()
        for a in assets:
            c[keyfn(a) or "—"] += 1
        # highest count first, then alpha — deterministic for every renderer
        return dict(sorted(c.items(), key=lambda kv: (-kv[1], str(kv[0]))))

    kpi = {
        "Total assets": len(assets),
        "Internet-facing": sum(
            1 for a in assets
            if getattr(a, "internet_facing", False) or getattr(a, "is_internet_facing", False)
        ),
        "Criticality unrated": sum(1 for a in assets if not getattr(a, "criticality", None)),
        "Past end-of-life": sum(1 for a in assets if _past(getattr(a, "eol_date", None))),
        "Warranty expired": sum(1 for a in assets if _past(getattr(a, "warranty_expiry", None))),
        "Decommissioned / retired": sum(
            1 for a in assets
            if getattr(a, "status", None) == "decommissioned"
            or getattr(a, "lifecycle_state", None) in ("decommissioned", "retired")
        ),
        "Total purchase cost": round(
            sum(float(getattr(a, "purchase_cost", 0) or 0) for a in assets), 2),
        "Total valuation": round(
            sum(float(getattr(a, "valuation", 0) or 0) for a in assets), 2),
    }
    breakdowns = {
        "By Asset Type": tally(lambda a: getattr(a, "asset_type", None)),
        "By Criticality": tally(lambda a: getattr(a, "criticality", None) or "Unrated"),
        "By Department": tally(lambda a: getattr(a, "department", None)),
        "By Lifecycle / Status": tally(
            lambda a: getattr(a, "lifecycle_state", None) or getattr(a, "status", None)),
        "By Operating System": tally(lambda a: getattr(a, "os_family", None)),
        "By Environment": tally(lambda a: getattr(a, "environment", None)),
        "By Data Classification": tally(lambda a: getattr(a, "data_classification", None)),
    }
    return {"kpi": kpi, "breakdowns": breakdowns}


def build_payload(assets: List[Any]) -> Dict[str, Any]:
    return {
        "records": [_record(a) for a in assets],
        "summary": _summary(assets),
        "total": len(assets),
    }


# ── CSV ───────────────────────────────────────────────────────────────────────
def _csv(detail: bool, payload: Dict[str, Any], meta: Dict[str, Any]) -> bytes:
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow([meta["report_title"]])
    w.writerow(["Organization", meta["tenant_name"]])
    w.writerow(["Generated", meta["generated_at"].strftime("%Y-%m-%d %H:%M UTC")])
    w.writerow([])
    s = payload["summary"]
    w.writerow(["Summary"])
    for k, v in s["kpi"].items():
        w.writerow([k, v])
    w.writerow([])
    for name, dist in s["breakdowns"].items():
        w.writerow([name])
        for k, v in dist.items():
            w.writerow([k, v])
        w.writerow([])
    if detail:
        w.writerow([h for (_k, h) in COLUMNS])
        for rec in payload["records"]:
            w.writerow([rec[k] for (k, _h) in COLUMNS])
        if not payload["records"]:
            w.writerow(["No assets in inventory."])
    return buf.getvalue().encode("utf-8-sig")  # BOM → Excel opens UTF-8 cleanly


# ── HTML ───────────────────────────────────────────────────────────────────────
_HTML_CSS = """
:root{color-scheme:light}
*{box-sizing:border-box}
body{font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;color:#1e293b;margin:0;padding:32px;background:#f8fafc}
.wrap{max-width:1200px;margin:0 auto}
h1{font-size:22px;margin:0 0 4px}
.sub{color:#64748b;font-size:13px;margin-bottom:24px}
h2{font-size:15px;margin:28px 0 10px;color:#0f172a;border-bottom:2px solid #e2e8f0;padding-bottom:6px}
.kpis{display:flex;flex-wrap:wrap;gap:12px;margin-bottom:8px}
.kpi{flex:1 1 160px;background:#fff;border:1px solid #e2e8f0;border-radius:10px;padding:14px 16px}
.kpi .n{font-size:22px;font-weight:700;color:#0f172a}
.kpi .l{font-size:12px;color:#64748b;margin-top:2px}
.cols{display:flex;flex-wrap:wrap;gap:20px}
.col{flex:1 1 300px}
table{border-collapse:collapse;width:100%;background:#fff;font-size:12px}
.break table{border:1px solid #e2e8f0;border-radius:8px;overflow:hidden}
th,td{text-align:left;padding:7px 10px;border-bottom:1px solid #eef2f7}
th{background:#0f172a;color:#fff;font-weight:600;font-size:11px;text-transform:uppercase;letter-spacing:.03em}
.break th{background:#f1f5f9;color:#334155}
tbody tr:nth-child(even){background:#f8fafc}
.detail{overflow-x:auto;margin-top:6px}
.detail td{white-space:nowrap}
.foot{margin-top:28px;color:#94a3b8;font-size:11px}
"""


def _html(detail: bool, payload: Dict[str, Any], meta: Dict[str, Any]) -> bytes:
    e = html.escape
    s = payload["summary"]
    out = [
        "<!doctype html><html><head><meta charset='utf-8'>",
        f"<title>{e(meta['report_title'])}</title><style>{_HTML_CSS}</style></head><body><div class='wrap'>",
        f"<h1>{e(meta['report_title'])}</h1>",
        f"<div class='sub'>{e(meta['tenant_name'])} &middot; Generated "
        f"{e(meta['generated_at'].strftime('%Y-%m-%d %H:%M UTC'))} &middot; "
        f"{payload['total']} asset{'' if payload['total'] == 1 else 's'}</div>",
        "<h2>Estate Summary</h2><div class='kpis'>",
    ]
    for k, v in s["kpi"].items():
        disp = f"{v:,.2f}" if isinstance(v, float) else f"{v:,}"
        out.append(f"<div class='kpi'><div class='n'>{e(disp)}</div><div class='l'>{e(k)}</div></div>")
    out.append("</div><h2>Breakdowns</h2><div class='cols'>")
    for name, dist in s["breakdowns"].items():
        rows = "".join(
            f"<tr><td>{e(str(k))}</td><td style='text-align:right'>{v}</td></tr>"
            for k, v in dist.items()
        ) or "<tr><td colspan='2'>No data</td></tr>"
        out.append(
            f"<div class='col break'><table><thead><tr><th>{e(name)}</th>"
            f"<th style='text-align:right'>Count</th></tr></thead><tbody>{rows}</tbody></table></div>"
        )
    out.append("</div>")
    if detail:
        out.append("<h2>Asset Register</h2><div class='detail'><table><thead><tr>")
        out.append("".join(f"<th>{e(h)}</th>" for (_k, h) in COLUMNS))
        out.append("</tr></thead><tbody>")
        for rec in payload["records"]:
            out.append("<tr>" + "".join(f"<td>{e(rec[k])}</td>" for (k, _h) in COLUMNS) + "</tr>")
        if not payload["records"]:
            out.append(f"<tr><td colspan='{len(COLUMNS)}'>No assets in inventory.</td></tr>")
        out.append("</tbody></table></div>")
    out.append("<div class='foot'>Generated by ComplyVerse GRC — Reports</div></div></body></html>")
    return "".join(out).encode("utf-8")


# ── XLSX ───────────────────────────────────────────────────────────────────────
def _xlsx(detail: bool, payload: Dict[str, Any], meta: Dict[str, Any]) -> bytes:
    from openpyxl import Workbook
    from openpyxl.styles import Alignment, Font, PatternFill
    from openpyxl.utils import get_column_letter

    hdr_fill = PatternFill("solid", fgColor="0F172A")
    hdr_font = Font(bold=True, color="FFFFFF")
    title_font = Font(bold=True, size=14)
    sect_font = Font(bold=True, size=11, color="0F172A")
    s = payload["summary"]

    wb = Workbook()
    ws = wb.active
    ws.title = "Summary"
    ws["A1"] = meta["report_title"]; ws["A1"].font = title_font
    ws["A2"] = f"{meta['tenant_name']}  ·  Generated {meta['generated_at'].strftime('%Y-%m-%d %H:%M UTC')}"
    r = 4
    ws.cell(r, 1, "Estate Summary").font = sect_font
    r += 1
    for k, v in s["kpi"].items():
        ws.cell(r, 1, k)
        ws.cell(r, 2, v)
        r += 1
    r += 1
    for name, dist in s["breakdowns"].items():
        ws.cell(r, 1, name).font = sect_font
        r += 1
        for k, v in dist.items():
            ws.cell(r, 1, str(k))
            ws.cell(r, 2, v)
            r += 1
        r += 1
    ws.column_dimensions["A"].width = 34
    ws.column_dimensions["B"].width = 16

    if detail:
        wd = wb.create_sheet("Inventory")
        headers = [h for (_k, h) in COLUMNS]
        wd.append(headers)
        for c in range(1, len(headers) + 1):
            cell = wd.cell(1, c)
            cell.fill = hdr_fill
            cell.font = hdr_font
            cell.alignment = Alignment(vertical="center")
        for rec in payload["records"]:
            wd.append([rec[k] for (k, _h) in COLUMNS])
        wd.freeze_panes = "A2"
        if payload["records"]:
            wd.auto_filter.ref = f"A1:{get_column_letter(len(headers))}{len(payload['records']) + 1}"
        for c, (_k, h) in enumerate(COLUMNS, start=1):
            wd.column_dimensions[get_column_letter(c)].width = min(max(len(h) + 2, 12), 40)

    buf = io.BytesIO()
    wb.save(buf)
    return buf.getvalue()


# ── PDF ────────────────────────────────────────────────────────────────────────
def _pdf(detail: bool, payload: Dict[str, Any], meta: Dict[str, Any]) -> bytes:
    from reportlab.lib import colors
    from reportlab.lib.pagesizes import letter, landscape
    from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
    from reportlab.lib.units import inch
    from reportlab.platypus import (
        SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer)

    styles = getSampleStyleSheet()
    cell = ParagraphStyle("cell", parent=styles["BodyText"], fontSize=7, leading=8.5)
    hcell = ParagraphStyle("hcell", parent=cell, textColor=colors.white, fontName="Helvetica-Bold")
    s = payload["summary"]
    buf = io.BytesIO()
    doc = SimpleDocTemplate(
        buf, pagesize=landscape(letter),
        leftMargin=0.5 * inch, rightMargin=0.5 * inch,
        topMargin=0.5 * inch, bottomMargin=0.5 * inch,
        title=meta["report_title"],
    )
    el: List[Any] = [
        Paragraph(meta["report_title"], styles["Title"]),
        Paragraph(
            f"{html.escape(meta['tenant_name'])} &middot; Generated "
            f"{meta['generated_at'].strftime('%Y-%m-%d %H:%M UTC')} &middot; "
            f"{payload['total']} assets", styles["Normal"]),
        Spacer(1, 14),
    ]

    hdr_style = TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#0F172A")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, -1), 8),
        ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#E2E8F0")),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F8FAFC")]),
        ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
        ("LEFTPADDING", (0, 0), (-1, -1), 5), ("RIGHTPADDING", (0, 0), (-1, -1), 5),
        ("TOPPADDING", (0, 0), (-1, -1), 3), ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
    ])

    # Estate summary KPIs (two-column table)
    el.append(Paragraph("Estate Summary", styles["Heading2"]))
    kpi_rows = [["Metric", "Value"]]
    for k, v in s["kpi"].items():
        kpi_rows.append([k, f"{v:,.2f}" if isinstance(v, float) else f"{v:,}"])
    t = Table(kpi_rows, colWidths=[3.2 * inch, 2.0 * inch])
    t.setStyle(hdr_style)
    el.append(t)
    el.append(Spacer(1, 12))

    # Breakdown tables (side-by-side via a grid of mini-tables, 2 per row)
    el.append(Paragraph("Breakdowns", styles["Heading2"]))
    minis = []
    for name, dist in s["breakdowns"].items():
        rows = [[name, "Count"]] + [[str(k), str(v)] for k, v in dist.items()]
        if len(rows) == 1:
            rows.append(["No data", ""])
        mt = Table(rows, colWidths=[2.3 * inch, 0.9 * inch])
        mt.setStyle(hdr_style)
        minis.append(mt)
    # pack 3 per row
    for i in range(0, len(minis), 3):
        grp = minis[i:i + 3]
        grp += [""] * (3 - len(grp))
        wrap = Table([grp], colWidths=[3.4 * inch] * 3)
        wrap.setStyle(TableStyle([
            ("VALIGN", (0, 0), (-1, -1), "TOP"),
            ("LEFTPADDING", (0, 0), (-1, -1), 0), ("RIGHTPADDING", (0, 0), (-1, -1), 8),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 10),
        ]))
        el.append(wrap)

    if detail:
        el.append(Spacer(1, 8))
        el.append(Paragraph("Asset Register", styles["Heading2"]))
        headers = [dict(COLUMNS)[k] for k in PDF_KEYS]
        data = [[Paragraph(h, hcell) for h in headers]]
        for rec in payload["records"]:
            data.append([Paragraph(html.escape(rec[k]) or "&mdash;", cell) for k in PDF_KEYS])
        if not payload["records"]:
            data.append([Paragraph("No assets in inventory.", cell)] + [Paragraph("", cell)] * (len(PDF_KEYS) - 1))
        # proportional widths across the usable landscape width (~10 inch)
        usable = 10.0 * inch
        weights = {"id": 0.5, "name": 1.6, "asset_type": 0.9, "criticality": 0.9,
                   "owner": 1.2, "department": 1.1, "os": 1.4, "ip_address": 1.0,
                   "environment": 0.9, "status": 0.8, "data_classification": 1.0}
        tot = sum(weights[k] for k in PDF_KEYS)
        widths = [usable * weights[k] / tot for k in PDF_KEYS]
        dt = Table(data, colWidths=widths, repeatRows=1)
        dt.setStyle(hdr_style)
        el.append(dt)

    doc.build(el)
    return buf.getvalue()


# ── Render dispatch ─────────────────────────────────────────────────────────
def render(report_key: str, fmt: str, payload: Dict[str, Any],
           meta: Dict[str, Any]) -> Tuple[bytes, str, str]:
    if report_key not in REPORTS:
        raise ValueError(f"unknown report '{report_key}'")
    if fmt not in _CT:
        raise ValueError(f"unknown format '{fmt}'")
    detail = REPORTS[report_key]["detail"]
    data = {"csv": _csv, "html": _html, "xlsx": _xlsx, "pdf": _pdf}[fmt](detail, payload, meta)
    ct, ext = _CT[fmt]
    return data, ct, ext


# ── DB + persistence ──────────────────────────────────────────────────────────
def _load_assets(db: Session, tenant_id: int) -> List[ITAsset]:
    return (db.query(ITAsset)
            .filter(ITAsset.tenant_id == tenant_id)
            .order_by(ITAsset.id)
            .all())


def _slug(text: str) -> str:
    import re
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")[:48] or "report"


def generate(db: Session, tenant_id: int, report_key: str, fmt: str,
             user: Optional[str] = None, tenant_name: str = "Organization"
             ) -> Tuple[GeneratedAssetReport, bytes]:
    if report_key not in REPORTS:
        raise ValueError(f"unknown report '{report_key}'")
    if fmt not in _CT:
        raise ValueError(f"unknown format '{fmt}'")
    now = datetime.utcnow()
    payload = build_payload(_load_assets(db, tenant_id))
    meta = {"report_title": REPORTS[report_key]["title"], "tenant_name": tenant_name,
            "generated_at": now, "generated_by": user}
    data, ct, ext = render(report_key, fmt, payload, meta)
    filename = f"{_slug(REPORTS[report_key]['title'])}-{now:%Y-%m-%d}.{ext}"
    row = GeneratedAssetReport(
        tenant_id=tenant_id, report_key=report_key, report_title=REPORTS[report_key]["title"],
        fmt=fmt, filename=filename, content_type=ct, size_bytes=len(data),
        asset_count=payload["total"], content=data, generated_at=now, generated_by=user)
    db.add(row)
    db.commit()
    db.refresh(row)
    return row, data


def list_reports(db: Session, tenant_id: int, limit: int = 100) -> List[GeneratedAssetReport]:
    return (db.query(GeneratedAssetReport)
            .filter(GeneratedAssetReport.tenant_id == tenant_id)
            .order_by(GeneratedAssetReport.generated_at.desc())
            .limit(limit)
            .all())


# ── Self-test (ponytail: one runnable check for the money/format logic) ───────
def _selftest() -> None:
    from types import SimpleNamespace as NS

    def A(**kw):
        base = dict(id=1, name="web-01", asset_type="infrastructure", criticality="high",
                    status="active", lifecycle_state="active", owner_name="Pat Lee",
                    assigned_user=None, department="IT", business_function="Payments",
                    location="DC1", host_name="web01", fqdn="web01.bank.local",
                    ip_address="10.0.0.5", os_version="Ubuntu 22.04", os_family="linux",
                    environment="production", manufacturer="Dell", model="R740",
                    serial_number="SN1", cpu_cores=8, memory_gb=32, storage_gb=500,
                    data_classification="confidential", internet_facing=True,
                    is_internet_facing=False, compliance_scope=["PCI-DSS"], vendor="Dell",
                    purchase_cost=1200.5, valuation=5000.0, purchase_date=datetime(2023, 1, 1),
                    warranty_expiry=datetime(2020, 1, 1), eol_date=datetime(2099, 1, 1))
        base.update(kw)
        return NS(**base)

    assets = [A(), A(id=2, name="db-01", asset_type="data", criticality=None,
                    department="Finance", os_family="windows", internet_facing=False,
                    environment="dev", purchase_cost=None, compliance_scope=[])]
    payload = build_payload(assets)
    s = payload["summary"]
    assert s["kpi"]["Total assets"] == 2
    assert s["kpi"]["Internet-facing"] == 1                     # only web-01
    assert s["kpi"]["Criticality unrated"] == 1                 # db-01 has none
    assert s["kpi"]["Warranty expired"] == 2                    # both expiry in the past
    assert s["kpi"]["Past end-of-life"] == 0                    # both EOL in 2099
    assert s["kpi"]["Total purchase cost"] == 1200.5            # None cost ignored
    assert s["breakdowns"]["By Criticality"]["Unrated"] == 1
    assert payload["records"][0]["internet_facing"] == "Yes"
    assert payload["records"][1]["internet_facing"] == "No"
    assert payload["records"][0]["criticality"] == "high"
    assert payload["records"][1]["criticality"] == "Unrated"
    assert payload["records"][0]["compliance_scope"] == "PCI-DSS"
    assert payload["records"][0]["purchase_cost"] == "1,200.50"

    meta = {"report_title": "Test", "tenant_name": "Acme Bank",
            "generated_at": datetime(2026, 1, 2, 3, 4), "generated_by": "x@y.z"}
    for rk in REPORTS:
        for fmt in FORMATS:
            data, ct, ext = render(rk, fmt, payload, meta)
            assert data and isinstance(data, bytes), (rk, fmt)
            if fmt == "pdf":
                assert data[:4] == b"%PDF", (rk, "pdf magic")
            elif fmt == "xlsx":
                assert data[:2] == b"PK", (rk, "xlsx zip magic")
            elif fmt == "html":
                assert b"<table" in data and b"Estate Summary" in data
            elif fmt == "csv":
                assert b"Total assets" in data

    # empty estate still renders a valid file in every format
    empty = build_payload([])
    for fmt in FORMATS:
        data, _ct, _ext = render("inventory", fmt, empty, meta)
        assert data and isinstance(data, bytes), ("empty", fmt)
    print("asset_reports self-test OK")


if __name__ == "__main__":
    _selftest()
