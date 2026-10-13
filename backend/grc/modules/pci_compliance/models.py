"""One row per (tenant, PCI requirement code) holding the assessment state.

Only assessed requirements get a row; anything without a row is 'not_assessed'.
A dedicated table created by create_all automatically — NO per-tenant column
ALTER — keeps the compliance state cleanly separable/reversible.
"""
from __future__ import annotations

from datetime import datetime

from sqlalchemy import Column, DateTime, Integer, JSON, String, Text, UniqueConstraint

from grc.models import Base


class PciAssessment(Base):
    __tablename__ = "grc_pci_assessment"

    id = Column(Integer, primary_key=True)
    tenant_id = Column(Integer, nullable=False, index=True)
    requirement_code = Column(String(32), nullable=False, index=True)  # "1.1.1", "A3.2"
    status = Column(String(16), nullable=False, default="not_assessed")  # see STATUSES
    note = Column(Text, nullable=True)
    evidence = Column(JSON, nullable=True)  # [{"label": str, "url": str}]
    assessed_by = Column(String(255), nullable=True)
    assessed_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    __table_args__ = (UniqueConstraint("tenant_id", "requirement_code", name="uq_pci_tenant_req"),)
