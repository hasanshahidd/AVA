"""PCI-DSS 4.0.1 catalogue (live from the SCF crosswalk) + coverage + assessment.

The requirement list and the control activities under each requirement are read
from grc_scf_mapping / grc_scf_control at request time (cheap: ~1.2k rows). The
crosswalk lives in each tenant's own DB, so no cross-tenant query is needed for
the catalogue; only the assessment rows are tenant-scoped.
"""
from __future__ import annotations

from collections import defaultdict
from datetime import datetime
from typing import Any, Dict, List, Optional

from sqlalchemy import text
from sqlalchemy.orm import Session

from .models import PciAssessment

SOURCE_SLUG = "pci_dss_401"  # the real PCI-DSS 4.0.1 requirement set (351 codes)

STATUSES = ("met", "partial", "gap", "not_applicable", "not_assessed")
_COUNTED = ("met", "partial", "gap", "not_applicable", "not_assessed")

# Official short titles of the PCI-DSS 4.0 top-level requirements + appendices.
# Short factual headings used to label each group.
GROUP_ORDER = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "A1", "A2", "A3"]
GROUP_TITLES = {
    "1": "Install and maintain network security controls",
    "2": "Apply secure configurations to all system components",
    "3": "Protect stored account data",
    "4": "Protect cardholder data with strong cryptography during transmission over open, public networks",
    "5": "Protect all systems and networks from malicious software",
    "6": "Develop and maintain secure systems and software",
    "7": "Restrict access to system components and cardholder data by business need to know",
    "8": "Identify users and authenticate access to system components",
    "9": "Restrict physical access to cardholder data",
    "10": "Log and monitor all access to system components and cardholder data",
    "11": "Test security of systems and networks regularly",
    "12": "Support information security with organizational policies and programs",
    "A1": "Additional requirements for multi-tenant service providers",
    "A2": "Additional requirements for entities using SSL/early TLS for POS POI terminals",
    "A3": "Designated Entities Supplemental Validation (DESV)",
}

_CATALOG_SQL = text(
    """
    select m.requirement_code, c.scf_id, c.name, c.domain_name, c.description
    from grc_scf_mapping m
    join grc_scf_control c on c.scf_id = m.scf_id
    where m.source_slug = :slug
    """
)


def _group_of(code: str) -> str:
    return code.split(".")[0]


def _natkey(code: str):
    out = []
    for p in code.split("."):
        if p.isdigit():
            out.append((0, int(p), ""))
        else:
            out.append((1, 0, p))  # appendix tokens (A1/A2/A3) sort after numerics
    return out


def load_catalog(db: Session) -> List[Dict[str, Any]]:
    """Live requirement catalogue: one entry per PCI requirement code, each with
    the SCF control activities it maps to. Ordered hierarchically (1, 1.1, ...)."""
    by_code: Dict[str, Dict[str, Any]] = {}
    for req, scf_id, name, domain, desc in db.execute(_CATALOG_SQL, {"slug": SOURCE_SLUG}):
        entry = by_code.get(req)
        if entry is None:
            entry = by_code[req] = {
                "code": req,
                "group": _group_of(req),
                "controls": [],
                "_seen": set(),
            }
        if scf_id and scf_id not in entry["_seen"]:
            entry["_seen"].add(scf_id)
            entry["controls"].append(
                {"scf_id": scf_id, "name": name, "domain": domain, "description": desc}
            )
    out = sorted(by_code.values(), key=lambda e: _natkey(e["code"]))
    for e in out:
        e.pop("_seen", None)
    return out


def _assessments(db: Session, tenant_id: int) -> Dict[str, PciAssessment]:
    rows = db.query(PciAssessment).filter(PciAssessment.tenant_id == tenant_id).all()
    return {r.requirement_code: r for r in rows}


def _cov(statuses: List[str]) -> Dict[str, Any]:
    total = len(statuses)
    counts = {s: 0 for s in _COUNTED}
    for s in statuses:
        counts[s] = counts.get(s, 0) + 1
    na = counts["not_applicable"]
    applicable = total - na
    met = counts["met"]
    # Auditor view: coverage = fully-met out of applicable. Partials shown separately.
    coverage_pct = round(100 * met / applicable) if applicable else 0
    assessed = total - counts["not_assessed"]
    assessed_pct = round(100 * assessed / total) if total else 0
    return {
        "total": total,
        "applicable": applicable,
        "met": met,
        "partial": counts["partial"],
        "gap": counts["gap"],
        "not_applicable": na,
        "not_assessed": counts["not_assessed"],
        "coverage_pct": coverage_pct,
        "assessed_pct": assessed_pct,
    }


def overview(db: Session, tenant_id: int) -> Dict[str, Any]:
    catalog = load_catalog(db)
    amap = _assessments(db, tenant_id)
    by_group: Dict[str, List[str]] = defaultdict(list)
    all_status: List[str] = []
    for e in catalog:
        a = amap.get(e["code"])
        st = a.status if a else "not_assessed"
        by_group[e["group"]].append(st)
        all_status.append(st)
    groups = []
    for gid in GROUP_ORDER:
        if gid not in by_group:
            continue
        g = _cov(by_group[gid])
        g["id"] = gid
        g["title"] = GROUP_TITLES.get(gid, gid)
        groups.append(g)
    return {
        "framework": "PCI-DSS 4.0.1",
        "source": "SCF crosswalk (" + SOURCE_SLUG + ")",
        "overall": _cov(all_status),
        "groups": groups,
    }


def requirements(db: Session, tenant_id: int, group: Optional[str] = None) -> Dict[str, Any]:
    catalog = load_catalog(db)
    amap = _assessments(db, tenant_id)
    out = []
    for e in catalog:
        if group and e["group"] != group:
            continue
        a = amap.get(e["code"])
        out.append(
            {
                "code": e["code"],
                "group": e["group"],
                "controls": e["controls"],
                "status": a.status if a else "not_assessed",
                "note": (a.note if a else None),
                "evidence": (a.evidence if a else None),
                "assessed_by": (a.assessed_by if a else None),
                "assessed_at": (a.assessed_at.isoformat() if a and a.assessed_at else None),
            }
        )
    return {"group": group, "count": len(out), "requirements": out}


def _valid_codes(db: Session) -> set:
    return {e["code"] for e in load_catalog(db)}


def assess(
    db: Session,
    tenant_id: int,
    requirement_code: str,
    status: str,
    note: Optional[str] = None,
    evidence: Optional[list] = None,
    user: Optional[str] = None,
) -> PciAssessment:
    if status not in STATUSES:
        raise ValueError("invalid status")
    if requirement_code not in _valid_codes(db):
        raise ValueError("unknown requirement code")
    row = (
        db.query(PciAssessment)
        .filter(PciAssessment.tenant_id == tenant_id, PciAssessment.requirement_code == requirement_code)
        .first()
    )
    if row is None:
        row = PciAssessment(tenant_id=tenant_id, requirement_code=requirement_code)
        db.add(row)
    row.status = status
    if note is not None:
        row.note = note
    if evidence is not None:
        row.evidence = evidence
    row.assessed_by = user
    row.assessed_at = datetime.utcnow()
    db.commit()
    db.refresh(row)
    return row


def bulk_assess(db: Session, tenant_id: int, group: str, status: str, user: Optional[str] = None) -> int:
    """Set every requirement in a top-level group to one status (demo/real convenience)."""
    if status not in STATUSES:
        raise ValueError("invalid status")
    codes = [e["code"] for e in load_catalog(db) if e["group"] == group]
    if not codes:
        raise ValueError("unknown group")
    existing = {
        r.requirement_code: r
        for r in db.query(PciAssessment)
        .filter(PciAssessment.tenant_id == tenant_id, PciAssessment.requirement_code.in_(codes))
        .all()
    }
    now = datetime.utcnow()
    for code in codes:
        row = existing.get(code)
        if row is None:
            row = PciAssessment(tenant_id=tenant_id, requirement_code=code)
            db.add(row)
        row.status = status
        row.assessed_by = user
        row.assessed_at = now
    db.commit()
    return len(codes)
