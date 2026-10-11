"""Unit test for the Help Desk dashboard-analytics aggregation (pure math)."""
from datetime import datetime

from grc.modules.helpdesk.router import compute_analytics


def test_compute_analytics_core_math():
    now = datetime(2026, 10, 11, 12, 0, 0)
    rows = [
        # Fulfilled SLA, 2h first response, 1 day resolution, 5-star feedback.
        {"status_category": "Resolved", "priority": "High", "agent_group": "ava",
         "ticket_type": "Incident", "agreement_status": "Fulfilled", "feedback_rating": 1.0,
         "creation": "2026-10-10 10:00:00", "first_responded_on": "2026-10-10 12:00:00",
         "resolution_date": "2026-10-11 10:00:00"},
        # Failed SLA, no response/resolution yet, no feedback.
        {"status_category": "Open", "priority": "Low", "agent_group": "ava",
         "ticket_type": None, "agreement_status": "Failed", "feedback_rating": 0,
         "creation": "2026-10-11 09:00:00"},
        # No SLA verdict at all (excluded from the %), 3-star (0.6) feedback.
        {"status_category": "Open", "priority": "High", "agent_group": None,
         "ticket_type": "Request", "agreement_status": "", "feedback_rating": 0.6,
         "creation": "2026-09-01 09:00:00"},  # outside 30-day window
    ]
    a = compute_analytics(rows, now=now)

    assert a["total"] == 3
    assert a["sla_fulfilled_pct"] == 50.0           # 1 Fulfilled of 2 with a verdict
    assert a["avg_first_response_hours"] == 2.0
    assert a["avg_resolution_days"] == 1.0
    assert a["avg_feedback_rating"] == 4.0          # mean(1.0, 0.6)=0.8 → *5
    assert a["feedback_count"] == 2
    assert a["by_team"] == {"ava": 2, "Unassigned": 1}
    assert a["by_priority"]["High"] == 2
    assert a["by_type"] == {"Incident": 1, "Unset": 1, "Request": 1}
    assert len(a["trend"]) == 30
    # Two tickets created inside the window (one older than 30d is excluded).
    assert sum(d["created"] for d in a["trend"]) == 2
    assert sum(d["resolved"] for d in a["trend"]) == 1


def test_compute_analytics_empty():
    a = compute_analytics([], now=datetime(2026, 10, 11))
    assert a["total"] == 0
    assert a["sla_fulfilled_pct"] is None
    assert a["avg_feedback_rating"] is None
    assert len(a["trend"]) == 30
    assert a["by_team"] == {}
