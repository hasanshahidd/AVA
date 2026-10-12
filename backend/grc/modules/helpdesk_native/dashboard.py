"""Dashboard + analytics (contract §A1, §A2).

Native port of the Frappe proxy's `/dashboard` (recent[]) and
`/dashboard-analytics` (compute_analytics) handlers in helpdesk/router.py — the
same KPI formulas, 30-day trend and 4 breakdowns, computed over the native
HDTicket table instead of Frappe rows. Native timestamps are real datetimes, so
no string parsing is needed. Empty tenant → zeros/None/empty, never 4xx (§E).
"""
from __future__ import annotations

from collections import Counter
from datetime import datetime, timedelta
from typing import List, Optional

from sqlalchemy.orm import Session

from ...models import HDTicket
from .common import iso


def _mean(xs: List[float]) -> Optional[float]:
    return round(sum(xs) / len(xs), 2) if xs else None


def recent(db: Session, tid: int) -> dict:
    """§A1. The dashboard page reads ONLY recent[] — the 8 most recently
    modified tickets (proxy's rows[:8], ordered by modified desc)."""
    rows = (
        db.query(HDTicket)
        .filter(HDTicket.tenant_id == tid)
        .order_by(HDTicket.updated_at.desc())
        .limit(8)
        .all()
    )
    return {"recent": [{
        "name": str(t.id),
        "subject": t.subject,
        "status": t.status.label_agent if t.status else None,
        "priority": (t.priority.name or t.priority.level) if t.priority else None,
        "modified": iso(t.updated_at),
    } for t in rows]}


def analytics(db: Session, tid: int) -> dict:
    """§A2. KPIs + 30-day trend + 4 donuts, matching compute_analytics()."""
    rows = db.query(HDTicket).filter(HDTicket.tenant_id == tid).all()
    # Native timestamps are UTC (datetime.utcnow); the proxy used datetime.now().
    # Using utcnow keeps the 30-day window aligned with how rows are stamped.
    now = datetime.utcnow()
    total = len(rows)

    # SLA: % Fulfilled among tickets that actually carry an SLA verdict.
    with_sla = [t for t in rows if t.agreement_status]
    fulfilled = sum(1 for t in with_sla if t.agreement_status == "Fulfilled")
    sla_pct = round(fulfilled / len(with_sla) * 100, 1) if with_sla else None

    # Avg first response (hours) and resolution (days), from timestamp deltas.
    resp_hrs, res_days = [], []
    for t in rows:
        c = t.created_at
        if c and t.first_responded_on and t.first_responded_on >= c:
            resp_hrs.append((t.first_responded_on - c).total_seconds() / 3600)
        if c and t.resolution_date and t.resolution_date >= c:
            res_days.append((t.resolution_date - c).total_seconds() / 86400)

    # Avg feedback on a 0–5 scale (stored 0–1); 0/blank ratings excluded.
    ratings = [float(t.feedback_rating) for t in rows
               if t.feedback_rating not in (None, 0, "0", "")]
    avg_feedback = round(_mean(ratings) * 5, 2) if ratings else None

    # 30-day daily trend: created-per-day vs resolved-per-day.
    start = (now - timedelta(days=29)).date()
    days = [start + timedelta(days=i) for i in range(30)]
    created_by, resolved_by = Counter(), Counter()
    for t in rows:
        if t.created_at and t.created_at.date() >= start:
            created_by[t.created_at.date()] += 1
        if t.resolution_date and t.resolution_date.date() >= start:
            resolved_by[t.resolution_date.date()] += 1
    trend = [{"date": d.isoformat(), "created": created_by.get(d, 0),
              "resolved": resolved_by.get(d, 0)} for d in days]

    def _by(key, default: str) -> dict:
        return dict(Counter(key(t) or default for t in rows))

    return {
        "total": total,
        "sla_fulfilled_pct": sla_pct,
        "avg_first_response_hours": _mean(resp_hrs),
        "avg_resolution_days": _mean(res_days),
        "avg_feedback_rating": avg_feedback,
        "feedback_count": len(ratings),
        "trend": trend,
        "by_team": _by(lambda t: t.team.team_name if t.team else None, "Unassigned"),
        "by_priority": _by(
            lambda t: (t.priority.name or t.priority.level) if t.priority else None, "—"),
        "by_type": _by(lambda t: t.ticket_type.name if t.ticket_type else None, "Unset"),
        "by_status_category": _by(lambda t: t.status_category, "Open"),
    }
