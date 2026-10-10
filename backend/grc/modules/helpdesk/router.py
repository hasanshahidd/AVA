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
import logging
import os
from collections import Counter
from typing import Any, Dict, List, Optional
from urllib.parse import quote

import requests
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from ...routers.auth_router import require_auth, require_tenant_permission
from ...models import GRCUser, IntegrationConnection, get_db

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


def _ctx(db: Session) -> Dict[str, Any]:
    """Resolve the Frappe endpoint + credentials + tenant partition for THIS
    request's tenant. Connection first (per-tenant), env fallback for dev."""
    conn = _resolve_connection(db)
    if conn is not None:
        try:
            from ...services.connector_credentials import decrypt_credentials
            creds = decrypt_credentials(conn.encrypted_credentials) or {}
        except Exception:
            logger.exception("helpdesk: credential decrypt failed")
            creds = {}
        cfg = conn.provider_config or {}
        partition = (str(cfg.get("ava_tenant") or "").strip() or None)
        return {
            "url": (conn.console_url or "").rstrip("/"),
            "key": creds.get("api_key", ""),
            "secret": creds.get("api_secret", ""),
            "partition": partition,
            "verify": bool(cfg.get("verify_ssl", True)),
            "source": "connection",
        }
    return {
        "url": (os.getenv("HELPDESK_FRAPPE_URL") or "http://localhost:8088").rstrip("/"),
        "key": os.getenv("HELPDESK_FRAPPE_KEY") or "",
        "secret": os.getenv("HELPDESK_FRAPPE_SECRET") or "",
        "partition": None,
        "verify": True,
        "source": "env",
    }


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
        return r.status_code in (200, 201)
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
    recent = [{"name": r["name"], "subject": r.get("subject"), "status": r.get("status"),
               "priority": r.get("priority"), "modified": r.get("modified")} for r in rows[:8]]
    return {
        "open": cat.get("Open", 0), "resolved": cat.get("Resolved", 0),
        "overdue": overdue, "unassigned": 0, "total": len(rows),
        "by_status": dict(by_status), "by_priority": dict(by_priority), "recent": recent,
    }


@router.get("/tickets")
def tickets(status: Optional[str] = None, q: Optional[str] = None,
            db: Session = Depends(get_db), current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    base = [["status", "=", status]] if status else []
    rows = _resource(ctx, "HD Ticket",
                     ["name", "subject", "status", "priority", "agent_group", "customer",
                      "contact", "raised_by", "creation", "response_by", "resolution_by",
                      "ava_finding_id", "cve_id"],
                     filters=_tenant_filters(ctx, base), order_by="modified desc")
    if q:
        s = q.lower()
        rows = [r for r in rows if s in (str(r.get("subject", "")) + str(r.get("name", ""))).lower()]
    out = [{
        "name": r["name"], "subject": r.get("subject"), "status": r.get("status"),
        "priority": r.get("priority"), "team": r.get("agent_group"), "customer": r.get("customer"),
        "contact": r.get("contact") or r.get("raised_by"), "created": r.get("creation"),
        "response_by": r.get("response_by"), "cve_id": r.get("cve_id"),
    } for r in rows]
    summary = dict(Counter(r.get("status") or "Open" for r in rows))
    return {"tickets": out, "summary": summary, "total": len(out)}


@router.get("/tickets/{name}")
def ticket_detail(name: str, db: Session = Depends(get_db),
                  current_user: GRCUser = Depends(require_auth), _perm: bool = VIEW):
    ctx = _ctx(db)
    # Fetch via a partition-filtered query so a user cannot read another tenant's
    # ticket by guessing its name.
    rows = _resource(ctx, "HD Ticket",
                     ["name", "subject", "description", "status", "status_category", "priority",
                      "ticket_type", "agent_group", "customer", "contact", "raised_by",
                      "response_by", "resolution_by", "agreement_status", "resolution_details",
                      "creation", "modified", "ava_finding_id", "cve_id", "cvss_score", "asset_host"],
                     filters=_tenant_filters(ctx, [["name", "=", name]]), limit=1)
    if not rows:
        return {"ticket": {"name": name, "not_found": True}, "conversation": []}
    ticket = rows[0]
    conv = _resource(ctx, "Communication",
                     ["name", "sender", "content", "communication_date", "sent_or_received"],
                     filters=[["reference_doctype", "=", "HD Ticket"], ["reference_name", "=", name]],
                     order_by="communication_date asc")
    conversation = [{
        "type": "received" if (c.get("sent_or_received") == "Received") else "sent",
        "sender": c.get("sender"), "content": c.get("content"), "date": c.get("communication_date"),
    } for c in conv]
    return {"ticket": ticket, "conversation": conversation}


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
    rows = _resource(ctx, "HD Agent", ["name", "agent_name", "user", "is_active"],
                     filters=_tenant_filters(ctx), order_by="agent_name asc")
    return {"agents": [{
        "name": r["name"], "agent_name": r.get("agent_name") or r.get("user"),
        "email": r.get("user"), "availability": "Active" if r.get("is_active") else "Unavailable",
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
    rows = _resource(ctx, "HD Article", ["name", "title", "category", "status", "author", "modified"],
                     filters=_tenant_filters(ctx), order_by="modified desc")
    return {"articles": [{
        "name": r["name"], "title": r.get("title"), "category": r.get("category"),
        "status": r.get("status"), "author": r.get("author"), "modified": r.get("modified"),
    } for r in rows]}


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
    internal: bool = False


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
    if body.internal:
        ok = _write(ctx, "POST", "/api/resource/HD%20Ticket%20Comment",
                    {"reference_ticket": name, "content": body.content})
    else:
        ok = _write(ctx, "POST", "/api/resource/Communication", {
            "communication_type": "Communication", "reference_doctype": "HD Ticket",
            "reference_name": name, "content": body.content, "sent_or_received": "Sent",
            "subject": f"Re: {name}",
        })
    return {"ok": ok}
