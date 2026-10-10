"""IT asset-inventory report generation — DB-free regression tests.

Guards the aggregation arithmetic and that every (report type x format) pair
renders a valid, non-empty file with the right magic bytes. Runs anywhere the
rest of the suite does (no database, no SESSION_SECRET — the service module
does not import the auth router).
"""
from datetime import datetime
from types import SimpleNamespace as NS

from grc.modules.asset_reports import service


def _asset(**kw):
    base = dict(
        id=1, name="web-01", asset_type="infrastructure", criticality="high",
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


def test_catalogue_and_formats():
    assert set(service.REPORTS) == {"inventory", "executive"}
    assert service.REPORTS["inventory"]["detail"] is True
    assert service.REPORTS["executive"]["detail"] is False
    assert service.FORMATS == ["pdf", "xlsx", "csv", "html"]


def test_aggregation_arithmetic():
    assets = [
        _asset(),
        _asset(id=2, name="db-01", asset_type="data", criticality=None,
               department="Finance", os_family="windows", internet_facing=False,
               environment="dev", purchase_cost=None, compliance_scope=[]),
    ]
    s = service.build_payload(assets)["summary"]
    assert s["kpi"]["Total assets"] == 2
    assert s["kpi"]["Internet-facing"] == 1
    assert s["kpi"]["Criticality unrated"] == 1
    assert s["kpi"]["Warranty expired"] == 2
    assert s["kpi"]["Past end-of-life"] == 0
    assert s["kpi"]["Total purchase cost"] == 1200.5
    assert s["breakdowns"]["By Criticality"]["Unrated"] == 1


def test_cell_formatting():
    rec = service.build_payload([_asset()])["records"][0]
    assert rec["internet_facing"] == "Yes"
    assert rec["criticality"] == "high"
    assert rec["compliance_scope"] == "PCI-DSS"
    assert rec["purchase_cost"] == "1,200.50"
    assert rec["purchase_date"] == "2023-01-01"  # datetime -> date iso


def test_every_report_format_renders_valid_bytes():
    payload = service.build_payload([_asset(), _asset(id=2, criticality=None)])
    meta = {"report_title": "T", "tenant_name": "Acme Bank",
            "generated_at": datetime(2026, 1, 2, 3, 4), "generated_by": "x@y.z"}
    for rk in service.REPORTS:
        for fmt in service.FORMATS:
            data, ct, ext = service.render(rk, fmt, payload, meta)
            assert data and isinstance(data, bytes), (rk, fmt)
            assert ext == fmt
            if fmt == "pdf":
                assert data[:4] == b"%PDF"
            elif fmt == "xlsx":
                assert data[:2] == b"PK"
            elif fmt == "html":
                assert b"<table" in data and b"Estate Summary" in data
            elif fmt == "csv":
                assert b"Total assets" in data
    # detail table only in the inventory report, never the executive summary
    inv_html, _, _ = service.render("inventory", "html", payload, meta)
    exec_html, _, _ = service.render("executive", "html", payload, meta)
    assert b"Asset Register" in inv_html
    assert b"Asset Register" not in exec_html


def test_empty_estate_still_renders():
    payload = service.build_payload([])
    meta = {"report_title": "T", "tenant_name": "Acme", "generated_at": datetime(2026, 1, 2),
            "generated_by": None}
    for fmt in service.FORMATS:
        data, _ct, _ext = service.render("inventory", fmt, payload, meta)
        assert data and isinstance(data, bytes), fmt
