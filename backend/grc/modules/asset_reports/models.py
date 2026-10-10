"""Persisted generated asset-inventory reports.

One row per generated file. The bytes are stored inline (LargeBinary) so a
report stays the exact point-in-time artifact it was when generated — an audit
report must not silently change when the estate does. A dedicated table created
by create_all automatically (same pattern as SbpAssetInventory — NO per-tenant
column ALTER).
"""
from __future__ import annotations

from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, LargeBinary, String

from grc.models import Base


class GeneratedAssetReport(Base):
    __tablename__ = "grc_generated_asset_reports"

    id = Column(Integer, primary_key=True)
    tenant_id = Column(Integer, nullable=False, index=True)
    report_key = Column(String(50), nullable=False)    # inventory | executive
    report_title = Column(String(255), nullable=False)
    fmt = Column(String(10), nullable=False)            # pdf | xlsx | csv | html
    filename = Column(String(255), nullable=False)
    content_type = Column(String(120), nullable=False)
    size_bytes = Column(Integer, nullable=False, default=0)
    asset_count = Column(Integer, nullable=False, default=0)
    content = Column(LargeBinary, nullable=False)
    generated_at = Column(DateTime, default=datetime.utcnow, index=True)
    generated_by = Column(String(255), nullable=True)
