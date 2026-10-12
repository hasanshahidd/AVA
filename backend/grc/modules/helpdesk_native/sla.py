"""SLA engine — STUB. Filled by the SLA conversion agent.

Converts logic spec §1 (get_sla selection, calc_time/calc_elapsed_time
business-hours math, handle_agreement_status, on-hold accrual). For now the
ticket core persists response_by/resolution_by/agreement_status/first_responded_on/
resolution_date as plain columns; these functions just surface what is stored so
the UI renders honestly before the math lands.
"""
from __future__ import annotations

from typing import Optional

from sqlalchemy.orm import Session

from .common import iso


def compute_sla_block(db: Session, ticket) -> dict:
    """§A4 nested `sla` block. Honest passthrough of persisted ticket columns.

    TODO(convert): sla — recompute response_by/resolution_by via calc_time over
    the policy's business hours + holidays, and derive agreement_status
    (§1.3–§1.5) instead of echoing the stored value.
    """
    agreement_status = ticket.agreement_status
    return {
        "policy": ticket.sla.service_level if ticket.sla else None,
        "agreement_status": agreement_status,
        "breached": agreement_status == "Failed",
        "first_responded_on": iso(ticket.first_responded_on),
        "resolution_date": iso(ticket.resolution_date),
        "response_by": iso(ticket.response_by),
        "resolution_by": iso(ticket.resolution_by),
        "on_hold_since": iso(ticket.on_hold_since),
    }


def recompute(db: Session, ticket, *, prev_status_category: Optional[str] = None) -> None:
    """Re-run SLA math after a status/field change (spec §1.2 apply).

    TODO(convert): sla — set_default_priority, start_clock, handle_doc_status,
    handle_targets, handle_agreement_status, set_hold_time. No-op for now; the
    ticket core already stamps resolution_date / first_responded_on directly.
    """
    return None


def config(db: Session, tid: int) -> dict:
    """§A20 /config block.

    TODO(convert): sla — read the default/ranked SLA + its priority targets and
    service days, format durations to human strings (`4h`, `2d`) via
    _fmt_duration, expose service_days as HH:MM:SS, and set auto_assignment =
    any team has an assignment rule.
    """
    return {
        "sla": {"policy": None, "priorities": [], "service_days": [], "holiday_list": None},
        "auto_assignment": False,
        "managed": True,
    }
