"""Dashboard + analytics — STUB. Filled by the dashboard agent.

§A1 (`recent`) and §A2 (KPIs / trend / donuts). Returns safe zero/empty values
so the UI renders `—` KPIs and empty charts (§E). TODO(convert): dashboard —
compute SLA %, avg first-response (hrs), avg resolution (days), feedback mean,
the 30-day created-vs-resolved trend, and the 4 Counter breakdowns (§D).
"""
from __future__ import annotations

from sqlalchemy.orm import Session


def recent(db: Session, tid: int) -> dict:
    return {"recent": []}


def analytics(db: Session, tid: int) -> dict:
    return {
        "total": 0,
        "sla_fulfilled_pct": None,
        "avg_first_response_hours": None,
        "avg_resolution_days": None,
        "avg_feedback_rating": None,
        "feedback_count": 0,
        "trend": [],
        "by_priority": {},
        "by_status_category": {},
        "by_team": {},
        "by_type": {},
    }
