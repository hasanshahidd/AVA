"""Approvals engine (flow #3) — ONE engine for both service-request sign-offs and
Change Advisory Board (CAB) decisions.

An HDApproval is attached to the ticket it gates; approvers cast HDApprovalVote
rows (one per approver). The approval is decided when the votes satisfy its
quorum AND every required role has approved (CAB), or immediately rejected the
moment any vote rejects (one reject fails it). On decision the ticket's
`approval_state` is bridged to 'approved' / 'rejected' so BOTH the existing change
lifecycle (change.py) and the #2 state-machine guard (guard='approved') observe
the outcome. While pending, the ticket sits in 'pending_approval' and the #2
guard blocks it from advancing — that is the "hold until quorum".

Pure data layer: no HTTP, no other tenants. Endpoint wiring is a later step; this
module is the engine those endpoints (and the CAB board UI) will call.
"""
from __future__ import annotations

from datetime import datetime
from typing import Optional

from sqlalchemy import func
from sqlalchemy.orm import Session

from ...models import (
    HDApproval,
    HDApprovalVote,
    HDChangeType,
    HDChangeRiskMatrix,
    HDTicket,
)

# ITIL default CAB: a quorum of 3 that MUST include the Change Manager and the
# Service Owner. Overridable per call (e.g. from HDCABConfig) — these are the
# fallback when the caller passes nothing.
DEFAULT_CAB_QUORUM = 3
DEFAULT_CAB_ROLES = ("ROLE-CHGMGR", "ROLE-SVCOWN")

_DECISIONS = ("approve", "reject", "abstain")


def open_approval(db: Session, tid: int, ticket: HDTicket, *, kind: str = "request",
                  required_quorum: int = 1, required_role_codes=None,
                  opened_by: Optional[str] = None) -> HDApproval:
    """Open a pending approval on `ticket` and park it in 'pending_approval'.
    kind: 'request' (single sign-off) | 'cab' | 'ecab'."""
    ap = HDApproval(
        tenant_id=tid, ticket_id=ticket.id, kind=kind,
        required_quorum=max(1, int(required_quorum or 1)),
        required_role_codes=list(required_role_codes) if required_role_codes else None,
        state="pending", opened_by=opened_by, opened_at=datetime.utcnow(),
    )
    db.add(ap)
    db.flush()
    ticket.approval_state = "pending_approval"
    db.flush()
    return ap


def cast_vote(db: Session, tid: int, approval_id: int, approver: str, decision: str,
              *, role: Optional[str] = None, comment: Optional[str] = None) -> HDApproval:
    """Record one approver's decision (one vote per approver — a re-vote updates in
    place) and re-evaluate. Votes on an already-decided approval are ignored."""
    ap = db.query(HDApproval).filter_by(id=approval_id, tenant_id=tid).first()
    if ap is None:
        raise ValueError("approval not found")
    if ap.state != "pending":
        return ap  # already decided — late votes are a no-op
    d = (decision or "").strip().lower()
    if d not in _DECISIONS:
        raise ValueError(f"decision must be one of {_DECISIONS}")
    vote = db.query(HDApprovalVote).filter_by(approval_id=ap.id, approver=approver).first()
    if vote is None:
        vote = HDApprovalVote(approval_id=ap.id, approver=approver)
        db.add(vote)
    vote.approver_role = role
    vote.decision = d
    vote.comment = comment
    vote.voted_at = datetime.utcnow()
    db.flush()
    _evaluate(db, ap)
    return ap


def _evaluate(db: Session, ap: HDApproval) -> None:
    """Decide the approval from its votes: any reject fails it; otherwise it passes
    when approve-votes meet the quorum AND every required role has approved."""
    votes = db.query(HDApprovalVote).filter_by(approval_id=ap.id).all()
    if any((v.decision or "") == "reject" for v in votes):
        _decide(db, ap, "rejected")
        return
    approvers = [v for v in votes if (v.decision or "") == "approve"]
    roles_ok = True
    if ap.required_role_codes:
        have = {(v.approver_role or "") for v in approvers}
        roles_ok = all(r in have for r in ap.required_role_codes)
    if len(approvers) >= (ap.required_quorum or 1) and roles_ok:
        _decide(db, ap, "approved")


def _decide(db: Session, ap: HDApproval, state: str) -> None:
    ap.state = state
    ap.decided_at = datetime.utcnow()
    ticket = db.query(HDTicket).filter_by(id=ap.ticket_id).first()
    if ticket is not None:
        ticket.approval_state = "approved" if state == "approved" else "rejected"
    db.flush()


def requirements_for_change(db: Session, tid: int, ticket: HDTicket) -> Optional[dict]:
    """Decide whether a change needs CAB, and the quorum/roles/kind, from the
    tenant's seeded change_type + risk matrix. Returns None when NO approval is
    needed (a Standard / pre-authorised change), else the kwargs for open_approval.

    A Standard change with auto_approve skips CAB; a Normal/Major needs it; an
    Emergency needs an ECAB. A risk level flagged cab_required forces CAB even when
    the change type alone would not."""
    ct_code = (ticket.change_type or "").strip().lower()
    ct = (db.query(HDChangeType).filter_by(tenant_id=tid, code=ct_code).first()
          if ct_code else None)
    needs = True
    if ct is not None:
        if ct.auto_approve and not ct.requires_cab:
            return None
        needs = bool(ct.requires_cab)
    risk = (ticket.change_risk or "").strip().lower()
    if risk:
        rm = (db.query(HDChangeRiskMatrix)
              .filter(HDChangeRiskMatrix.tenant_id == tid,
                      func.lower(HDChangeRiskMatrix.risk_level) == risk)
              .first())
        if rm is not None and rm.cab_required:
            needs = True
    if not needs:
        return None
    kind = "ecab" if ct_code == "emergency" else "cab"
    return {"kind": kind, "required_quorum": DEFAULT_CAB_QUORUM,
            "required_role_codes": list(DEFAULT_CAB_ROLES)}
