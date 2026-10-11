"""Help Desk proxy — serves AVA's native Help Desk module from the Frappe
Helpdesk engine over REST, TENANT-SCOPED.

Tenancy model (matches AVA's DB-per-tenant isolation):
  * The Frappe connection is resolved from the tenant's OWN database — `get_db`
    already bound this request to the tenant's DB, so the `IntegrationConnection`
    we read belongs only to this tenant (its Frappe URL + API key + partition).
  * Each tenant may point at its own Frappe instance (separate `console_url` →
    automatic isolation) OR share one Frappe partitioned by an `ava_tenant` tag.
    To cover the shared case, every TICKET query is additionally filtered by the
    tenant's partition, so Tenant A can never read Tenant B's tickets.
  * Dev fallback: if no connection is configured, env vars
    (HELPDESK_FRAPPE_URL / _KEY / _SECRET) are used with NO partition filter
    (single-tenant local dev only).

Every call is defensive: on any Frappe error it returns empty data so the UI
still renders.
"""
from __future__ import annotations

import json
import html
import logging
import os
from collections import Counter
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional
from urllib.parse import quote


def _parse_dt(value: Any) -> Optional[datetime]:
    """Parse a Frappe datetime string ("YYYY-MM-DD HH:MM:SS[.ffffff]"). None on
    anything unparseable, so the aggregation never raises on dirty data."""
    if not isinstance(value, str) or not value.strip():
        return None
    try:
        return datetime.fromisoformat(value.strip())
    except ValueError:
        for fmt in ("%Y-%m-%d %H:%M:%S.%f", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d"):
            try:
                return datetime.strptime(value.strip(), fmt)
            except ValueError:
                continue
    return None


def _mean(xs: List[float]) -> Optional[float]:
    return round(sum(xs) / len(xs), 2) if xs else None


def compute_analytics(rows: List[Dict[str, Any]], now: Optional[datetime] = None) -> Dict[str, Any]:
    """Pure aggregation over HD Ticket rows → the dashboard-analytics payload.

    Factored out (no I/O, no engine names) so the math is unit-testable. Expects
    raw Frappe field names on each row; emits de-branded JSON.
    """
    now = now or datetime.now()
    total = len(rows)

    # SLA: % Fulfilled among tickets that actually carry an SLA verdict.
    with_sla = [r for r in rows if r.get("agreement_status")]
    fulfilled = sum(1 for r in with_sla if r.get("agreement_status") == "Fulfilled")
    sla_pct = round(fulfilled / len(with_sla) * 100, 1) if with_sla else None

    # Avg first response (hours) and resolution (days), from timestamp deltas.
    resp_hrs, res_days = [], []
    for r in rows:
        c = _parse_dt(r.get("creation"))
        fr = _parse_dt(r.get("first_responded_on"))
        rd = _parse_dt(r.get("resolution_date"))
        if c and fr and fr >= c:
            resp_hrs.append((fr - c).total_seconds() / 3600)
        if c and rd and rd >= c:
            res_days.append((rd - c).total_seconds() / 86400)

    # Avg feedback on a 0–5 scale (Frappe stores a 0–1 fraction).
    ratings = [float(r["feedback_rating"]) for r in rows
               if r.get("feedback_rating") not in (None, 0, "0", "")]
    avg_feedback = round(_mean(ratings) * 5, 2) if ratings else None

    # 30-day daily trend: created-per-day vs resolved-per-day.
    start = (now - timedelta(days=29)).date()
    days = [start + timedelta(days=i) for i in range(30)]
    created_by, resolved_by = Counter(), Counter()
    for r in rows:
        c = _parse_dt(r.get("creation"))
        if c and c.date() >= start:
            created_by[c.date()] += 1
        rd = _parse_dt(r.get("resolution_date"))
        if rd and rd.date() >= start:
            resolved_by[rd.date()] += 1
    trend = [{"date": d.isoformat(), "created": created_by.get(d, 0),
              "resolved": resolved_by.get(d, 0)} for d in days]

    def _by(field: str, default: str) -> Dict[str, int]:
        return dict(Counter(r.get(field) or default for r in rows))

    return {
        "total": total,
        "sla_fulfilled_pct": sla_pct,
        "avg_first_response_hours": _mean(resp_hrs),
        "avg_resolution_days": _mean(res_days),
        "avg_feedback_rating": avg_feedback,
        "feedback_count": len(ratings),
        "trend": trend,
        "by_team": _by("agent_group", "Unassigned"),
        "by_priority": _by("priority", "—"),
        "by_type": _by("ticket_type", "Unset"),
        "by_status_category": _by("status_category", "Open"),
    }


def _fmt_duration(seconds: Any) -> Optional[str]:
    """Frappe Duration fields store seconds. Render a compact human target
    (e.g. 4h, 2d) for the read-only SLA display. None on junk / non-positive."""
    try:
        s = int(float(seconds))
    except (TypeError, ValueError):
        return None
    if s <= 0:
        return None
    if s % 86400 == 0:
        return f"{s // 86400}d"
    if s % 3600 == 0:
        return f"{s // 3600}h"
    if s < 3600:
        return f"{s // 60}m"
    return f"{round(s / 3600, 1)}h"


def _sla_targets(doc: Dict[str, Any]) -> Dict[str, Any]:
    """Pure projection of an HD Service Level Agreement doc → the read-only
    config payload (per-priority response/resolution + service days). No I/O,
    no engine names, so it is unit-testable."""
    priorities = [{
        "priority": p.get("priority"),
        "response": _fmt_duration(p.get("response_time")),
        "resolution": _fmt_duration(p.get("resolution_time")),
    } for p in (doc.get("priorities") or [])]
    service_days = [{
        "day": d.get("workday"), "start": d.get("start_time"), "end": d.get("end_time"),
    } for d in (doc.get("support_and_resolution") or [])]
    return {
        "policy": doc.get("service_level") or doc.get("name"),
        "priorities": priorities,
        "service_days": service_days,
        "holiday_list": doc.get("holiday_list"),
    }


def _subj(value: Any) -> str:
    """Frappe stores the ticket subject HTML-ESCAPED (`<`→`&lt;`). Un-escape it for
    display so titles read `<package>` not `&lt;package&gt;`. Safe: the UI (React)
    re-escapes on render, so no markup is injected."""
    return html.unescape(value) if isinstance(value, str) else (value or "")

import requests
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ...routers.auth_router import require_auth, require_tenant_permission
from ...models import GRCUser, IntegrationConnection, Tenant, get_db

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/helpdesk", tags=["Help Desk"])

PROVIDER = "frappe_helpdesk"

# RBAC — the Help Desk surfaces remediation tickets for findings, so it is gated
# on the same tenant permissions as the ITSM push/sync endpoints. Authentication
# alone is NOT enough: a Viewer without these rights must not read tenant tickets.
VIEW = Depends(require_tenant_permission("vulnerabilities:vulnerability_register:view"))
EDIT = Depends(require_tenant_permission("vulnerabilities:vulnerability_register:edit"))


# ─── tenant context ────────────────────────────────────────────────
def _resolve_connection(db: Session) -> Optional[IntegrationConnection]:
    """The tenant's active Frappe Helpdesk connection, from the tenant's own DB
    (get_db already scoped us to it)."""
    try:
        return (
            db.query(IntegrationConnection)
            .filter(
                IntegrationConnection.integration_type == PROVIDER,
                IntegrationConnection.is_active == True,  # noqa: E712
            )
            .order_by(IntegrationConnection.id.desc())
            .first()
        )
    except Exception:
        logger.exception("helpdesk: connection lookup failed")
        return None


def _tenant_partition(db: Session) -> Optional[str]:
    """The tenant's partition, derived SERVER-SIDE from the tenant itself.

    Deliberately NOT customer-supplied: a tenant must never see — let alone
    change — which partition it reads. `get_db` already bound this request to
    the tenant's own database, so the single Tenant row here IS the caller.
    """
    try:
        t = db.query(Tenant).first()
        if t is not None:
            return getattr(t, "slug", None) or getattr(t, "subdomain", None) or None
    except Exception:
        logger.exception("helpdesk: tenant partition lookup failed")
    return None


def _ctx(db: Session) -> Dict[str, Any]:
    """Frappe is AVA's OWN infrastructure — not a customer-owned third party.

    Credentials therefore come from PLATFORM config (server env, set once by the
    operator), NEVER from a per-tenant connector the customer fills in: the
    client must never learn that an external engine exists. Tenant separation is
    still absolute — enforced by a partition derived from the tenant itself.

    The IntegrationConnection branch survives only as an operator-level override
    (e.g. pinning one tenant to a dedicated Frappe). It is hidden from the
    customer-facing connectors UI and never asks the client for anything.
    """
    partition = _tenant_partition(db)
    url = (os.getenv("HELPDESK_FRAPPE_URL") or "").rstrip("/")
    key = os.getenv("HELPDESK_FRAPPE_KEY") or ""
    secret = os.getenv("HELPDESK_FRAPPE_SECRET") or ""
    if url and key:
        return {"url": url, "key": key, "secret": secret, "partition": partition,
                "verify": True, "source": "platform"}

    conn = _resolve_connection(db)
    if conn is not None:
        try:
            from ...services.connector_credentials import decrypt_credentials
            creds = decrypt_credentials(conn.encrypted_credentials) or {}
        except Exception:
            logger.exception("helpdesk: credential decrypt failed")
            creds = {}
        cfg = conn.provider_config or {}
        return {
            "url": (conn.console_url or "").rstrip("/"),
            "key": creds.get("api_key", ""),
            "secret": creds.get("api_secret", ""),
            # partition stays tenant-derived — never read from provider_config
            "partition": partition,
            "verify": bool(cfg.get("verify_ssl", True)),
            "source": "operator-override",
        }
    return {"url": "", "key": "", "secret": "", "partition": partition,
            "verify": True, "source": "unconfigured"}


def _tenant_filters(ctx: Dict[str, Any], base: Optional[list] = None) -> Optional[list]:
    """Append the tenant partition filter so the shared Frappe only returns this
    tenant's tickets. No partition (per-tenant Frappe / dev) → base only."""
    f = list(base or [])
    if ctx.get("partition"):
        f.append(["ava_tenant", "=", ctx["partition"]])
    return f or None


# ─── low-level Frappe calls (take the tenant ctx) ──────────────────
def _get(ctx: Dict[str, Any], path: str) -> Optional[Any]:
    try:
        r = requests.get(
            f"{ctx['url']}{path}",
            headers={"Authorization": f"token {ctx['key']}:{ctx['secret']}", "Accept": "application/json"},
            verify=ctx.get("verify", True), timeout=12,
        )
        if r.status_code == 200:
            return r.json().get("data")
        logger.warning("helpdesk proxy %s -> %s", path, r.status_code)
    except Exception as exc:
        logger.warning("helpdesk proxy %s failed: %s", path, exc)
    return None


def _write(ctx: Dict[str, Any], method: str, path: str, payload: dict) -> bool:
    try:
        r = requests.request(
            method, f"{ctx['url']}{path}",
            headers={"Authorization": f"token {ctx['key']}:{ctx['secret']}",
                     "Content-Type": "application/json", "Accept": "application/json"},
            json=payload, verify=ctx.get("verify", True), timeout=12,
        )
        return r.status_code in (200, 201, 202)  # 202: Frappe DELETE
    except Exception as exc:
        logger.warning("helpdesk write %s %s failed: %s", method, path, exc)
        return False


def _resource(ctx: Dict[str, Any], doctype: str, fields: List[str], filters: Optional[list] = None,
              order_by: str = "modified desc", limit: int = 0) -> List[Dict]:
    dt = quote(doctype)
    q = f"/api/resource/{dt}?fields={quote(json.dumps(fields))}&limit_page_length={limit}&order_by={quote(order_by)}"
    if filters:
        q += f"&filters={quote(json.dumps(filters))}"
    data = _get(ctx, q)
    return data if isinstance(data, list) else []


# ─── endpoints ─────────────────────────────────────────────────────
@router.get("/ping")
def ping(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    data = _get(ctx, "/api/method/frappe.ping")
    return {"configured": bool(ctx["key"]), "frappe_url": ctx["url"],
            "tenant_partition": ctx["partition"], "source": ctx["source"],
            "reachable": data is not None}


@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    rows = _resource(ctx, "HD Ticket",
                     ["name", "subject", "status", "priority", "status_category", "modified", "agreement_status"],
                     filters=_tenant_filters(ctx), order_by="modified desc")
    by_status = Counter(r.get("status") or "Open" for r in rows)
    by_priority = Counter(r.get("priority") or "—" for r in rows)
    cat = Counter((r.get("status_category") or "Open") for r in rows)
    overdue = sum(1 for r in rows if (r.get("agreement_status") == "Failed"))
    recent = [{"name": r["name"], "subject": _subj(r.get("subject")), "status": r.get("status"),
               "priority": r.get("priority"), "modified": r.get("modified")} for r in rows[:8]]
    return {
        "open": cat.get("Open", 0), "resolved": cat.get("Resolved", 0),
        "overdue": overdue, "unassigned": 0, "total": len(rows),
        "by_status": dict(by_status), "by_priority": dict(by_priority), "recent": recent,
    }


@router.get("/dashboard-analytics")
def dashboard_analytics(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    """Rich dashboard metrics for this tenant: KPIs, 30-day trend, breakdowns.
    Partition-filtered (tenant-scoped) + VIEW-gated like every other read."""
    ctx = _ctx(db)
    rows = _resource(ctx, "HD Ticket",
                     ["name", "status", "status_category", "priority", "agent_group",
                      "ticket_type", "agreement_status", "feedback_rating",
                      "creation", "first_responded_on", "resolution_date", "response_by"],
                     filters=_tenant_filters(ctx), order_by="creation desc")
    return compute_analytics(rows)


@router.get("/tickets")
def tickets(status: Optional[str] = None, q: Optional[str] = None,
            db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    base = [["status", "=", status]] if status else []
    rows = _resource(ctx, "HD Ticket",
                     ["name", "subject", "status", "priority", "ticket_type", "agent_group",
                      "_assign", "agreement_status", "customer",
                      "contact", "raised_by", "creation", "modified", "response_by", "resolution_by",
                      "feedback_rating", "ava_finding_id", "cve_id"],
                     filters=_tenant_filters(ctx, base), order_by="modified desc")
    if q:
        s = q.lower()
        rows = [r for r in rows if s in (str(r.get("subject", "")) + str(r.get("name", ""))).lower()]
    out = [{
        "name": r["name"], "subject": _subj(r.get("subject")), "status": r.get("status"),
        "priority": r.get("priority"), "type": r.get("ticket_type"),
        "team": r.get("agent_group"), "agent": _assignee(r.get("_assign")),
        "agreement_status": r.get("agreement_status"), "customer": r.get("customer"),
        "contact": r.get("contact") or r.get("raised_by"), "created": r.get("creation"),
        "modified": r.get("modified"),
        "response_by": r.get("response_by"), "resolution_by": r.get("resolution_by"),
        "feedback_rating": r.get("feedback_rating"),
        "cve_id": r.get("cve_id"),
    } for r in rows]
    summary = dict(Counter(r.get("status") or "Open" for r in rows))
    return {"tickets": out, "summary": summary, "total": len(out)}


def _assignee(raw: Any) -> Optional[str]:
    """First user in Frappe's `_assign` field (a JSON string list)."""
    try:
        lst = json.loads(raw) if isinstance(raw, str) else (raw or [])
        return lst[0] if lst else None
    except Exception:
        return None


def _sla_block(t: Dict[str, Any]) -> Dict[str, Any]:
    """Structure the SLA state from HD Ticket's native fields (no extra call).
    `agreement_status` is Frappe's own verdict (Fulfilled / Failed / *Due)."""
    status = t.get("agreement_status")
    return {
        "policy": t.get("sla"),
        "agreement_status": status,
        "response_by": t.get("response_by"),
        "resolution_by": t.get("resolution_by"),
        "first_responded_on": t.get("first_responded_on"),
        "resolution_date": t.get("resolution_date"),
        "on_hold_since": t.get("on_hold_since"),
        "breached": status == "Failed",
        "response_failed_by": t.get("first_response_failed_by"),
        "resolution_failed_by": t.get("resolution_failed_by"),
    }


@router.get("/tickets/{name}")
def ticket_detail(name: str, db: Session = Depends(get_db),
                  current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    # Fetch via a partition-filtered query so a user cannot read another tenant's
    # ticket by guessing its name.
    rows = _resource(ctx, "HD Ticket",
                     ["name", "subject", "description", "status", "status_category", "priority",
                      "ticket_type", "agent_group", "_assign", "customer", "contact", "raised_by",
                      "response_by", "resolution_by", "agreement_status", "resolution_details",
                      "sla", "first_responded_on", "resolution_date", "on_hold_since",
                      "first_response_failed_by", "resolution_failed_by",
                      "feedback", "feedback_rating", "feedback_extra",
                      "creation", "modified", "ava_finding_id", "cve_id", "cvss_score", "asset_host"],
                     filters=_tenant_filters(ctx, [["name", "=", name]]), limit=1)
    if not rows:
        return {"ticket": {"name": name, "not_found": True}, "conversation": []}
    ticket = rows[0]
    ticket["subject"] = _subj(ticket.get("subject"))  # un-escape for display (description stays HTML)
    # Surface team + assignee under the names the UI reads.
    ticket["team"] = ticket.get("agent_group")
    ticket["agent"] = _assignee(ticket.get("_assign"))
    ticket["sla"] = _sla_block(ticket)

    # ── full conversation: public replies + internal notes + activity ──
    # These child/related doctypes carry NO ava_tenant tag, so they are read
    # ONLY by the key of a ticket we JUST confirmed is in-partition above —
    # never by a global query (isolation via the parent, per the parity matrix).
    conv: List[Dict[str, Any]] = []
    for c in _resource(ctx, "Communication",
                       ["name", "sender", "content", "communication_date", "sent_or_received"],
                       filters=[["reference_doctype", "=", "HD Ticket"], ["reference_name", "=", name]],
                       order_by="communication_date asc"):
        conv.append({
            "type": "received" if (c.get("sent_or_received") == "Received") else "sent",
            "sender": c.get("sender"), "content": c.get("content"), "date": c.get("communication_date"),
        })
    for c in _resource(ctx, "HD Ticket Comment",
                       ["name", "content", "commented_by", "creation"],
                       filters=[["reference_ticket", "=", name]], order_by="creation asc"):
        conv.append({"type": "comment", "sender": c.get("commented_by"),
                     "content": c.get("content"), "date": c.get("creation")})
    for a in _resource(ctx, "HD Ticket Activity",
                       ["name", "action", "owner", "creation"],
                       filters=[["ticket", "=", name]], order_by="creation asc"):
        conv.append({"type": "activity", "sender": a.get("owner"),
                     "content": a.get("action"), "date": a.get("creation")})
    conv.sort(key=lambda m: m.get("date") or "")
    return {"ticket": ticket, "conversation": conv}


@router.get("/meta")
def meta(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    """Global option lists for the ticket editor (priorities / types / statuses /
    feedback options). These are shared enums — not tenant data — so they carry
    no partition filter."""
    ctx = _ctx(db)
    priorities = _resource(ctx, "HD Ticket Priority", ["name"], order_by="name asc")
    types = _resource(ctx, "HD Ticket Type", ["name"], filters=[["disabled", "=", 0]], order_by="name asc")
    statuses = _resource(ctx, "HD Ticket Status", ["name", "category", "order"],
                         filters=[["enabled", "=", 1]], order_by="order asc")
    feedback = _resource(ctx, "HD Ticket Feedback Option", ["name", "label", "rating"],
                         filters=[["disabled", "=", 0]], order_by="rating asc")
    return {
        "priorities": [p["name"] for p in priorities],
        "ticket_types": [t["name"] for t in types],
        "statuses": [{"name": s["name"], "category": s.get("category")} for s in statuses],
        "feedback_options": [{"label": f.get("label") or f["name"], "rating": f.get("rating")} for f in feedback],
    }


def _ticket_in_tenant(ctx: Dict[str, Any], name: str) -> bool:
    """Guard: does this ticket belong to the caller's tenant? (No partition →
    per-tenant Frappe / dev, always true.)"""
    if not ctx.get("partition"):
        return True
    rows = _resource(ctx, "HD Ticket", ["name"],
                     filters=_tenant_filters(ctx, [["name", "=", name]]), limit=1)
    return bool(rows)


@router.get("/agents")
def agents(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    rows = _resource(ctx, "HD Agent", ["name", "agent_name", "user", "is_active", "availability"],
                     filters=_tenant_filters(ctx), order_by="agent_name asc")
    return {"agents": [{
        "name": r["name"], "agent_name": r.get("agent_name") or r.get("user"),
        "email": r.get("user"),
        # Prefer the richer HD Agent Status (Available/Away/Busy); fall back to the
        # active flag when no status is set.
        "availability": r.get("availability") or ("Active" if r.get("is_active") else "Unavailable"),
        "is_active": bool(r.get("is_active")),
    } for r in rows]}


@router.get("/teams")
def teams(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    rows = _resource(ctx, "HD Team", ["name", "team_name", "assignment_rule"],
                     filters=_tenant_filters(ctx), order_by="team_name asc")
    out = []
    for r in rows:
        doc = _get(ctx, f"/api/resource/HD%20Team/{quote(r['name'])}")
        members = []
        if isinstance(doc, dict):
            members = [{"name": u.get("user")} for u in (doc.get("users") or [])]
        out.append({"name": r["name"], "team_name": r.get("team_name"),
                    "assignment_rule": r.get("assignment_rule"), "members": members})
    return {"teams": out}


@router.get("/customers")
def customers(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    rows = _resource(ctx, "HD Customer", ["name", "customer_name", "domain"],
                     filters=_tenant_filters(ctx), order_by="customer_name asc")
    return {"customers": [{
        "name": r["name"], "customer_name": r.get("customer_name") or r["name"],
        "domain": r.get("domain"), "contacts_count": 0,
    } for r in rows]}


@router.get("/contacts")
def contacts(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    rows = _resource(ctx, "Contact", ["name", "first_name", "last_name", "email_id", "phone", "company_name"],
                     filters=_tenant_filters(ctx), order_by="modified desc")
    return {"contacts": [{
        "name": r["name"], "first_name": r.get("first_name"), "last_name": r.get("last_name"),
        "email_id": r.get("email_id"), "phone": r.get("phone"), "company_name": r.get("company_name"),
    } for r in rows]}


@router.get("/articles")
def articles(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    rows = _resource(ctx, "HD Article", ["name", "title", "category", "status", "author", "modified", "views"],
                     filters=_tenant_filters(ctx), order_by="modified desc")
    # Article feedback (helpful / not) — HD Article Feedback has no ava_tenant, so
    # read it ONLY for this tenant's own articles (isolation via the parent).
    names = [r["name"] for r in rows]
    # HD Article Feedback.feedback is a Select "1"=like/helpful, "2"=dislike
    # (per helpdesk/api/article.py). Read only for this tenant's own articles.
    fb: Dict[str, Counter] = {}
    if names:
        for f in _resource(ctx, "HD Article Feedback", ["article", "feedback"],
                           filters=[["article", "in", names]]):
            fb.setdefault(f.get("article"), Counter())[str(f.get("feedback"))] += 1
    cats = Counter(r.get("category") or "Uncategorised" for r in rows)
    articles = []
    for r in rows:
        c = fb.get(r["name"], Counter())
        articles.append({
            "name": r["name"], "title": r.get("title"), "category": r.get("category") or "Uncategorised",
            "status": r.get("status"), "author": r.get("author"), "modified": r.get("modified"),
            "views": r.get("views") or 0,
            "helpful": c.get("1", 0), "not_helpful": c.get("2", 0),
        })
    return {"articles": articles,
            "categories": [{"name": n, "count": c} for n, c in sorted(cats.items())]}


@router.get("/canned-responses")
def canned_responses(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    for dt, title_field in (("HD Canned Response", "title"), ("HD Saved Reply", "subject")):
        rows = _resource(ctx, dt, ["name", title_field, "owner"],
                            filters=_tenant_filters(ctx), order_by="modified desc")
        if rows:
            return {"responses": [{"name": r["name"], "title": r.get(title_field) or r["name"],
                                   "owner": r.get("owner")} for r in rows]}
    return {"responses": []}


class StatusUpdate(BaseModel):
    status: str


class ReplyBody(BaseModel):
    content: str = ""
    body: str = ""          # FE sends `body`; `content` kept for back-compat
    internal: bool = False
    cc: Optional[str] = None   # public reply only; comma-separated addresses
    bcc: Optional[str] = None


class FieldUpdate(BaseModel):
    priority: Optional[str] = None
    ticket_type: Optional[str] = None
    status: Optional[str] = None
    agent_group: Optional[str] = None


class AssignBody(BaseModel):
    agent: Optional[str] = None     # HD Agent user (email); None clears assignment
    team: Optional[str] = None      # agent_group


@router.post("/tickets/{name}/status")
def set_ticket_status(name: str, body: StatusUpdate, db: Session = Depends(get_db),
                      current_user: GRCUser = Depends(require_auth), _perm: bool = EDIT):
    ctx = _ctx(db)
    if not _ticket_in_tenant(ctx, name):
        return {"ok": False, "error": "not found"}
    ok = _write(ctx, "PUT", f"/api/resource/HD%20Ticket/{quote(name)}", {"status": body.status})
    return {"ok": ok, "status": body.status}


@router.post("/tickets/{name}/reply")
def reply_ticket(name: str, body: ReplyBody, db: Session = Depends(get_db),
                 current_user: GRCUser = Depends(require_auth), _perm: bool = EDIT):
    ctx = _ctx(db)
    if not _ticket_in_tenant(ctx, name):
        return {"ok": False, "error": "not found"}
    content = body.content or body.body
    if body.internal:
        ok = _write(ctx, "POST", "/api/resource/HD%20Ticket%20Comment",
                    {"reference_ticket": name, "content": content})
    else:
        payload = {
            "communication_type": "Communication", "reference_doctype": "HD Ticket",
            "reference_name": name, "content": content, "sent_or_received": "Sent",
            "subject": f"Re: {name}",
        }
        # Cc/Bcc pass through to the logged Communication. NOTE: this only RECORDS
        # the reply (+ addressees); outbound email delivery depends on the engine
        # having SMTP configured. Creating the Communication never fails for lack
        # of SMTP, so the reply always logs even when email isn't set up.
        if body.cc:
            payload["cc"] = body.cc
        if body.bcc:
            payload["bcc"] = body.bcc
        ok = _write(ctx, "POST", "/api/resource/Communication", payload)
    return {"ok": ok}


@router.post("/tickets/{name}/update")
def update_ticket_fields(name: str, body: FieldUpdate, db: Session = Depends(get_db),
                         current_user: GRCUser = Depends(require_auth), _perm: bool = EDIT):
    """Change priority / type / status / team on an in-partition ticket. Each
    is a plain HD Ticket field, so one PUT covers them (assignee is separate —
    see /assign — because it routes through Frappe's assign_to engine)."""
    ctx = _ctx(db)
    if not _ticket_in_tenant(ctx, name):
        return {"ok": False, "error": "not found"}
    payload = {k: v for k, v in body.model_dump().items() if v is not None}
    if not payload:
        return {"ok": True, "unchanged": True}
    ok = _write(ctx, "PUT", f"/api/resource/HD%20Ticket/{quote(name)}", payload)
    return {"ok": ok, "updated": list(payload.keys())}


def _agent_in_tenant(ctx: Dict[str, Any], user: str) -> bool:
    """Only assign to an agent that belongs to this tenant's partition (HD Agent
    carries ava_tenant). No partition (dev / per-tenant Frappe) → allow."""
    if not ctx.get("partition"):
        return True
    rows = _resource(ctx, "HD Agent", ["name"],
                     filters=_tenant_filters(ctx, [["user", "=", user]]), limit=1)
    return bool(rows)


@router.post("/tickets/{name}/assign")
def assign_ticket(name: str, body: AssignBody, db: Session = Depends(get_db),
                  current_user: GRCUser = Depends(require_auth), _perm: bool = EDIT):
    """Manual assignment. Sets the team (agent_group) and/or assigns an agent via
    Frappe's own assign_to engine (the same ToDo-backed mechanism the auto rule
    uses, so the desk stays consistent). Guards: ticket in-partition, agent
    in-partition."""
    ctx = _ctx(db)
    if not _ticket_in_tenant(ctx, name):
        return {"ok": False, "error": "not found"}
    team_ok = agent_ok = True
    if body.team is not None:
        team_ok = _write(ctx, "PUT", f"/api/resource/HD%20Ticket/{quote(name)}",
                         {"agent_group": body.team})
    if body.agent:
        if not _agent_in_tenant(ctx, body.agent):
            return {"ok": False, "error": "agent not in tenant"}
        agent_ok = _write(ctx, "POST", "/api/method/frappe.desk.form.assign_to.add",
                          {"doctype": "HD Ticket", "name": name, "assign_to": [body.agent]})
    return {"ok": bool(team_ok and agent_ok), "agent": body.agent, "team": body.team}


# ─── Settings: saved replies (the one genuinely per-tenant, safe-to-edit config) ──
# All other Settings surfaces (SLA policies, business holidays, assignment rules,
# email accounts) are GLOBAL engine config shared across tenants and are NOT
# ava_tenant-tagged — editing them from a tenant UI would mutate shared state, so
# they are DISPLAY-ONLY via /config below. Saved replies carry ava_tenant, so they
# are the only writable Settings area.
def _canned_spec(ctx: Dict[str, Any]) -> tuple:
    """(doctype, title_field) for this engine's saved-reply doctype — prefers
    HD Canned Response, falls back to HD Saved Reply. Body field is `message`.

    The existence probe is itself PARTITION-FILTERED so it can never surface
    another tenant's reply names: an empty list ([]) still proves the doctype
    exists, while None means it does not (or the query errored)."""
    for dt, tf in (("HD Canned Response", "title"), ("HD Saved Reply", "title")):
        probe = _resource(ctx, dt, ["name"], filters=_tenant_filters(ctx), limit=1)
        # _resource returns [] on a successful empty result AND on error, so
        # fall back to a raw _get only to distinguish doctype-missing from empty.
        if probe or _get(ctx, f"/api/resource/{quote(dt)}?limit_page_length=0") is not None:
            return dt, tf
    return "HD Canned Response", "title"


def _saved_reply_in_tenant(ctx: Dict[str, Any], name: str) -> bool:
    """ISOLATION GUARD for saved-reply edit/delete. Confirms the target record
    is in THIS tenant's partition by querying it WITH the ava_tenant filter —
    an out-of-partition id returns no rows, so a crafted id can never edit or
    delete another tenant's reply. No partition (dev / per-tenant engine) →
    allow. Mirrors `_ticket_in_tenant`."""
    if not ctx.get("partition"):
        return True
    dt, _tf = _canned_spec(ctx)
    rows = _resource(ctx, dt, ["name"],
                     filters=_tenant_filters(ctx, [["name", "=", name]]), limit=1)
    return bool(rows)


class SavedReplyBody(BaseModel):
    title: Optional[str] = None
    message: str = ""


@router.get("/saved-replies")
def saved_replies(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    """Full saved replies (with body) for this tenant — partition-filtered."""
    ctx = _ctx(db)
    dt, tf = _canned_spec(ctx)
    rows = _resource(ctx, dt, ["name", tf, "message", "owner", "modified"],
                     filters=_tenant_filters(ctx), order_by="modified desc")
    return {"saved_replies": [{
        "name": r["name"], "title": r.get(tf) or r["name"],
        "message": r.get("message") or "", "owner": r.get("owner"), "modified": r.get("modified"),
    } for r in rows]}


@router.post("/saved-replies")
def create_saved_reply(body: SavedReplyBody, db: Session = Depends(get_db),
                       current_user: GRCUser = Depends(require_auth), _perm: bool = EDIT):
    ctx = _ctx(db)
    dt, tf = _canned_spec(ctx)
    payload: Dict[str, Any] = {tf: body.title or "Untitled", "message": body.message}
    if ctx.get("partition"):
        payload["ava_tenant"] = ctx["partition"]   # tag so the list stays tenant-scoped
    ok = _write(ctx, "POST", f"/api/resource/{quote(dt)}", payload)
    return {"ok": ok}


@router.put("/saved-replies/{name}")
def update_saved_reply(name: str, body: SavedReplyBody, db: Session = Depends(get_db),
                       current_user: GRCUser = Depends(require_auth), _perm: bool = EDIT):
    ctx = _ctx(db)
    # 404 (not 403) on an out-of-partition id so cross-tenant existence isn't confirmed.
    if not _saved_reply_in_tenant(ctx, name):
        raise HTTPException(status_code=404, detail="not found")
    dt, tf = _canned_spec(ctx)
    payload: Dict[str, Any] = {"message": body.message}
    if body.title is not None:
        payload[tf] = body.title
    ok = _write(ctx, "PUT", f"/api/resource/{quote(dt)}/{quote(name)}", payload)
    return {"ok": ok}


@router.delete("/saved-replies/{name}")
def delete_saved_reply(name: str, db: Session = Depends(get_db),
                       current_user: GRCUser = Depends(require_auth), _perm: bool = EDIT):
    ctx = _ctx(db)
    if not _saved_reply_in_tenant(ctx, name):
        raise HTTPException(status_code=404, detail="not found")
    dt, _tf = _canned_spec(ctx)
    ok = _write(ctx, "DELETE", f"/api/resource/{quote(dt)}/{quote(name)}", {})
    return {"ok": ok}


@router.get("/config")
def config(db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    """READ-ONLY 'how your Help Desk is configured' panel: the active SLA targets,
    business hours, and whether auto-assignment is on. SLA/holidays are GLOBAL
    engine config (not tenant-tagged) so they are shown but NOT editable here.
    Auto-assignment is inferred from the tenant's own team (partition-safe)."""
    ctx = _ctx(db)
    slas = _resource(ctx, "HD Service Level Agreement", ["name", "default_sla", "enabled"],
                     order_by="modified desc")
    doc: Dict[str, Any] = {}
    if slas:
        pick = next((s for s in slas if s.get("default_sla")), slas[0])
        full = _get(ctx, f"/api/resource/HD%20Service%20Level%20Agreement/{quote(pick['name'])}")
        if isinstance(full, dict):
            doc = full
    teams = _resource(ctx, "HD Team", ["name", "assignment_rule"], filters=_tenant_filters(ctx))
    return {
        "sla": _sla_targets(doc),
        "auto_assignment": any(t.get("assignment_rule") for t in teams),
        "managed": True,   # UI labels this "Managed by your administrator"
    }
