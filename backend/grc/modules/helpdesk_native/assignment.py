"""Assignment engine — STUB. Filled by the assignment conversion agent.

Converts logic spec §2: the core Assignment Rule strategies (Round Robin /
Load Balancing / Weighted Distribution), per-team rule provisioning, and
`remove_assignment_if_not_in_team` cleanup. The ticket core already persists the
single current assignee on `HDTicket.assigned_agent` (manual assign, §A15); this
module adds the automatic selection.
"""
from __future__ import annotations

from sqlalchemy.orm import Session


def auto_assign(db: Session, ticket) -> None:
    """Pick and stamp an agent when a ticket is created/becomes Open with a team.

    TODO(convert): assignment — implement the team's rule strategy (spec §2.2)
    and set ticket.assigned_agent. No-op for now (ticket stays unassigned until
    an agent manually assigns via §A15).
    """
    return None


def remove_if_not_in_team(db: Session, ticket) -> None:
    """Clear the assignee when the team changes and they aren't on the new team.

    TODO(convert): assignment — spec §2.3 remove_assignment_if_not_in_team.
    """
    return None
