"""ITSM seeder (spec §3) — idempotent, safe to re-run.

Makes the ITIL-lite surface usable on an existing tenant DB: ALTER-adds the §1
HDTicket extension columns (create_all can't add columns to an existing table),
ensures the priorities / statuses / per-process ticket types the dropdowns need,
creates the four per-process SLAs via the existing `sla.create_sla` validator,
and backfills `process` on existing tickets from their ticket type.

All DB work is gated behind `seed_itsm` / the endpoint; the `__main__` self-check
is pure (matrix + SLA target table) and needs no DB.
"""
from __future__ import annotations

import logging

from fastapi import APIRouter, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from ...models import (
    HDDepartment,
    HDServiceLevelAgreement,
    HDTicket,
    HDTicketPriority,
    HDTicketStatus,
    HDTicketTemplate,
    HDTicketType,
    Role,
    RolePermission,
    get_db,
)
from . import sla
from .common import require_edit, tenant_id

logger = logging.getLogger(__name__)

# ─── seed data (spec §3) ─────────────────────────────────────────────────────
# §3.1 — one ALTER per §1 column (Postgres ADD COLUMN IF NOT EXISTS → idempotent).
_ALTER_COLUMNS = [
    ("process", "VARCHAR(20) NOT NULL DEFAULT 'incident'"),
    ("impact", "VARCHAR(10)"),
    ("urgency", "VARCHAR(10)"),
    ("change_type", "VARCHAR(20)"),
    ("change_risk", "VARCHAR(10)"),
    ("planned_start", "TIMESTAMP"),
    ("planned_end", "TIMESTAMP"),
    ("implementation_plan", "TEXT"),
    ("backout_plan", "TEXT"),
    ("approval_state", "VARCHAR(20)"),
    ("approved_by", "VARCHAR(255)"),
    ("approved_at", "TIMESTAMP"),
    ("root_cause", "TEXT"),
    ("workaround", "TEXT"),
    ("known_error", "BOOLEAN DEFAULT false"),
    ("problem_resolution", "TEXT"),
    ("linked_incident_ids", "TEXT"),
    ("request_category", "VARCHAR(100)"),
    ("request_subcategory", "VARCHAR(100)"),
]

# §A1 — same mechanism for grc_hd_ticket_template (create_all can't add the new
# request-library columns to an existing table). Plain columns; the department_id
# FK constraint is omitted (SQLAlchemy's relationship works off the column, and
# the live grc_hd_ticket ALTERs add no FK either). ponytail: add the FK in a real
# migration only if referential enforcement is ever needed here.
_TEMPLATE_ALTER_COLUMNS = [
    ("department_id", "INTEGER"),
    ("process", "VARCHAR(20) DEFAULT 'incident'"),
    ("default_subject", "VARCHAR(255)"),
    ("default_description", "TEXT"),
    ("default_category", "VARCHAR(100)"),
    ("default_subcategory", "VARCHAR(100)"),
    ("default_impact", "VARCHAR(10)"),
    ("default_urgency", "VARCHAR(10)"),
    ("icon", "VARCHAR(40)"),
    ("enabled", "BOOLEAN DEFAULT true"),
]

# §A2 (v2) — the standard departments the request library is organized by.
_DEPARTMENTS = ["IT", "Sales", "Finance", "HR", "Facilities",
                "Operations", "Legal", "Marketing", "Security"]

# §A2 (v2) — the predefined request/problem library, by department. Each entry:
# (title, process, category, subcategory, impact, urgency, icon, description).
# title == template_name == default_subject; description == default_description.
# category/subcategory are drawn from SERVICE_CATALOG (below). impact/urgency
# feed the priority matrix (outage=high/high, routine=low/low).
_REQUEST_TEMPLATES = {
    "IT": [
        ("Computer running slow", "incident", "Hardware", "Desktop", "medium", "medium", "gauge",
         "My computer has become slow or unresponsive."),
        ("Laptop won't power on", "incident", "Hardware", "Laptop", "high", "high", "laptop",
         "My laptop will not turn on."),
        ("Request a new laptop", "service_request", "Hardware", "Laptop", "low", "low", "laptop",
         "I'd like to request a new laptop."),
        ("Monitor not displaying", "incident", "Hardware", "Monitor", "medium", "medium", "monitor",
         "My external monitor shows no display."),
        ("Install a software application", "service_request", "Software", "Installation", "low", "low", "download",
         "Please install an application on my machine."),
        ("Software license request", "service_request", "Software", "Licensing", "low", "medium", "badge-check",
         "I need a license for a software product."),
        ("Application crashes on launch", "incident", "Software", "Application Error", "medium", "high", "alert-triangle",
         "An application crashes every time I open it."),
        ("VPN won't connect", "incident", "Network", "VPN", "high", "high", "shield",
         "I can't connect to the corporate VPN."),
        ("Wi-Fi keeps dropping", "incident", "Network", "Wi-Fi", "medium", "medium", "wifi",
         "My Wi-Fi connection keeps disconnecting."),
        ("Password reset request", "service_request", "Access & Accounts", "Password Reset", "medium", "high", "key-round",
         "I need my password reset."),
        ("Account locked out", "incident", "Access & Accounts", "Account Lockout", "medium", "high", "lock",
         "My account is locked and I can't sign in."),
        ("Request system access", "service_request", "Access & Accounts", "Access Request", "low", "medium", "user-plus",
         "I need access to a system or application."),
        ("Set up multi-factor authentication", "service_request", "Access & Accounts", "MFA", "low", "low", "smartphone",
         "I need help setting up MFA on my account."),
        ("Email not sending or receiving", "incident", "Email & Collaboration", "Email Delivery", "high", "high", "mail",
         "I'm unable to send or receive email."),
        ("Shared mailbox access", "service_request", "Email & Collaboration", "Mailbox", "low", "low", "mail",
         "I need access to a shared mailbox."),
        ("Printer not printing", "incident", "Printing", "Print Queue", "medium", "medium", "printer",
         "The printer isn't printing my documents."),
        ("Recurring network outages (RCA)", "problem", "Network", "Connectivity", "high", "high", "bug",
         "Investigate the recurring network outages affecting multiple users."),
    ],
    "Sales": [
        ("CRM is down", "incident", "Sales/CRM", "CRM Issue", "high", "high", "trending-down",
         "The CRM is completely down."),
        ("CRM running slowly", "incident", "Sales/CRM", "CRM Issue", "medium", "medium", "gauge",
         "The CRM is slow and unresponsive."),
        ("Can't log in to CRM", "incident", "Sales/CRM", "CRM Access", "high", "high", "lock",
         "I'm unable to log in to the CRM."),
        ("New rep CRM access", "service_request", "Sales/CRM", "CRM Access", "low", "medium", "user-plus",
         "A new sales rep needs CRM access."),
        ("CRM report not loading", "incident", "Sales/CRM", "Reporting", "medium", "medium", "bar-chart",
         "A CRM report fails to load."),
        ("Build a sales dashboard", "service_request", "Sales/CRM", "Reporting", "low", "low", "bar-chart",
         "I'd like a new sales performance dashboard."),
        ("Import leads into CRM", "service_request", "Sales/CRM", "Data Import", "low", "low", "upload",
         "Please import a list of leads into the CRM."),
        ("Quote/contract template change", "service_request", "Sales/CRM", "Quotes/Contracts", "low", "medium", "file-text",
         "I need a change to a quote or contract template."),
        ("Lead routing broken", "incident", "Sales/CRM", "Lead/Opportunity", "high", "medium", "alert-triangle",
         "Leads are not being routed to the right reps."),
        ("Duplicate records in CRM (RCA)", "problem", "Sales/CRM", "Data Import", "medium", "low", "bug",
         "Investigate the duplicate records appearing in the CRM."),
        ("Sales laptop issue", "incident", "Hardware", "Laptop", "medium", "medium", "laptop",
         "I'm having a problem with my sales laptop."),
    ],
    "Finance": [
        ("Submit expense reimbursement", "service_request", "Finance", "Expense", "low", "low", "receipt",
         "I'd like to submit an expense for reimbursement."),
        ("Expense report rejected", "incident", "Finance", "Expense", "low", "medium", "file-text",
         "My expense report was rejected and I need help."),
        ("Purchase order request", "service_request", "Finance", "Procurement", "low", "medium", "shopping-cart",
         "I need to raise a purchase order."),
        ("New vendor setup", "service_request", "Finance", "Vendor", "low", "low", "briefcase",
         "Please set up a new vendor in the system."),
        ("Invoice discrepancy", "incident", "Finance", "Invoicing", "medium", "medium", "file-text",
         "There's a discrepancy on an invoice."),
        ("Payment not processed", "incident", "Finance", "Payment", "high", "high", "banknote",
         "A payment failed to process."),
        ("Accounting software error", "incident", "Software", "Application Error", "medium", "high", "calculator",
         "The accounting software is showing an error."),
        ("Budget access request", "service_request", "Finance", "Budget", "low", "low", "bar-chart",
         "I need access to the budget reports."),
        ("Corporate card request", "service_request", "Finance", "Procurement", "low", "low", "credit-card",
         "I'd like to request a corporate card."),
        ("Month-end close support", "service_request", "Finance", "Invoicing", "medium", "medium", "calendar-clock",
         "I need support with the month-end close."),
        ("Recurring payment failures (RCA)", "problem", "Finance", "Payment", "high", "medium", "bug",
         "Investigate the recurring payment processing failures."),
        ("Tax document request", "service_request", "Finance", "Invoicing", "low", "low", "file-text",
         "I need copies of tax documents."),
    ],
    "HR": [
        ("New employee onboarding", "service_request", "HR", "Onboarding", "medium", "medium", "user-plus",
         "Please onboard a new employee."),
        ("Employee offboarding", "service_request", "HR", "Offboarding", "medium", "high", "user-minus",
         "Please offboard a departing employee."),
        ("Payroll discrepancy", "incident", "HR", "Payroll", "high", "high", "banknote",
         "There's a discrepancy in my paycheck."),
        ("Update personal information", "service_request", "HR", "Personal Info", "low", "low", "user-cog",
         "I'd like to update my personal information."),
        ("Benefits enrollment help", "service_request", "HR", "Benefits", "low", "low", "heart-pulse",
         "I need help enrolling in benefits."),
        ("Leave / time-off request", "service_request", "HR", "Leave/Time-off", "low", "low", "calendar",
         "I'd like to request time off."),
        ("Leave balance incorrect", "incident", "HR", "Leave/Time-off", "low", "medium", "calendar",
         "My leave balance is showing incorrectly."),
        ("Training enrollment request", "service_request", "HR", "Training", "low", "low", "book-open",
         "I'd like to enroll in a training course."),
        ("Employment verification letter", "service_request", "HR", "Personal Info", "low", "low", "file-text",
         "I need an employment verification letter."),
        ("HR policy question", "service_request", "HR", "Policy", "low", "low", "book-open",
         "I have a question about an HR policy."),
        ("Report a workplace concern", "incident", "HR", "Policy", "medium", "high", "alert-triangle",
         "I'd like to report a workplace concern."),
        ("Payroll system outage (RCA)", "problem", "HR", "Payroll", "high", "high", "bug",
         "Investigate the recurring payroll system outages."),
    ],
    "Facilities": [
        ("Office too hot or cold", "incident", "Facilities", "HVAC", "medium", "medium", "thermometer",
         "The office temperature is uncomfortable."),
        ("Broken office equipment", "incident", "Facilities", "Maintenance", "medium", "medium", "wrench",
         "A piece of office equipment is broken."),
        ("Desk or office move", "service_request", "Facilities", "Office Space", "low", "low", "move",
         "I need to request a desk or office move."),
        ("Meeting room booking issue", "incident", "Facilities", "Office Space", "low", "medium", "calendar-clock",
         "There's a problem with a meeting room booking."),
        ("Access badge request", "service_request", "Facilities", "Access Badge", "low", "medium", "badge",
         "I need a new access badge."),
        ("Badge not working", "incident", "Facilities", "Access Badge", "medium", "high", "badge",
         "My access badge isn't working at the door."),
        ("Parking spot request", "service_request", "Facilities", "Parking", "low", "low", "car",
         "I'd like to request a parking spot."),
        ("Lighting not working", "incident", "Facilities", "Lighting", "low", "low", "lightbulb",
         "The lighting in my area isn't working."),
        ("Request office furniture", "service_request", "Facilities", "Furniture", "low", "low", "armchair",
         "I'd like to request office furniture."),
        ("Cleaning request", "service_request", "Facilities", "Cleaning", "low", "low", "sparkles",
         "I'd like to request cleaning for an area."),
        ("Water leak or spill", "incident", "Facilities", "Maintenance", "high", "high", "alert-triangle",
         "There's a water leak or spill that needs attention."),
        ("Plan an office relocation", "change", "Facilities", "Office Space", "medium", "low", "move",
         "Plan and coordinate an office relocation."),
    ],
    "Operations": [
        ("Process not working", "incident", "Operations", "Process", "medium", "medium", "settings",
         "A business process isn't working as expected."),
        ("Request a process change", "change", "Operations", "Process", "medium", "low", "refresh-cw",
         "I'd like to request a change to a process."),
        ("Inventory discrepancy", "incident", "Operations", "Inventory", "medium", "medium", "package",
         "There's a discrepancy in inventory counts."),
        ("Shipment delayed", "incident", "Operations", "Logistics", "high", "high", "truck",
         "A shipment is delayed."),
        ("Schedule change request", "service_request", "Operations", "Scheduling", "low", "low", "calendar",
         "I need a change to a schedule."),
        ("Quality issue report", "incident", "Operations", "Quality", "medium", "high", "alert-triangle",
         "I'd like to report a quality issue."),
        ("Vendor onboarding", "service_request", "Operations", "Vendor Management", "low", "low", "briefcase",
         "Please onboard a new operations vendor."),
        ("Equipment maintenance request", "service_request", "Operations", "Process", "low", "medium", "wrench",
         "I need maintenance scheduled for equipment."),
        ("Logistics system access", "service_request", "Operations", "Logistics", "low", "low", "user-plus",
         "I need access to the logistics system."),
        ("Recurring fulfillment errors (RCA)", "problem", "Operations", "Logistics", "high", "medium", "bug",
         "Investigate the recurring order fulfillment errors."),
        ("Restock inventory request", "service_request", "Operations", "Inventory", "low", "low", "package",
         "Please restock inventory for an item."),
    ],
    "Legal": [
        ("Contract review request", "service_request", "Legal", "Contract Review", "medium", "medium", "file-signature",
         "Please review a contract."),
        ("NDA request", "service_request", "Legal", "NDA", "low", "medium", "file-signature",
         "I need an NDA prepared."),
        ("Compliance question", "service_request", "Legal", "Compliance", "low", "low", "scale",
         "I have a compliance question."),
        ("Policy review request", "service_request", "Legal", "Policy", "low", "low", "book-open",
         "Please review a policy."),
        ("Intellectual property question", "service_request", "Legal", "Intellectual Property", "low", "low", "scale",
         "I have a question about intellectual property."),
        ("Legal dispute escalation", "incident", "Legal", "Dispute", "high", "high", "alert-triangle",
         "I need to escalate a legal dispute."),
        ("Data privacy request", "service_request", "Legal", "Compliance", "medium", "medium", "shield",
         "I have a data privacy / GDPR request."),
        ("Vendor contract renewal", "service_request", "Legal", "Contract Review", "low", "medium", "file-signature",
         "I need a vendor contract renewed."),
        ("Trademark filing request", "service_request", "Legal", "Intellectual Property", "low", "low", "scale",
         "Please file a trademark."),
        ("Litigation hold notice", "change", "Legal", "Dispute", "high", "high", "file-text",
         "Place a litigation hold on records."),
        ("Regulatory filing support", "service_request", "Legal", "Compliance", "medium", "medium", "file-text",
         "I need support with a regulatory filing."),
    ],
    "Marketing": [
        ("Marketing asset request", "service_request", "Marketing", "Asset Request", "low", "low", "image",
         "I'd like to request a marketing asset."),
        ("Campaign setup request", "service_request", "Marketing", "Campaign", "low", "medium", "megaphone",
         "Please set up a marketing campaign."),
        ("Website page update", "service_request", "Marketing", "Website", "low", "medium", "globe",
         "I need a website page updated."),
        ("Website is down", "incident", "Marketing", "Website", "high", "high", "trending-down",
         "The marketing website is down."),
        ("Social media post request", "service_request", "Marketing", "Social Media", "low", "low", "share-2",
         "Please publish a social media post."),
        ("Branding guidelines request", "service_request", "Marketing", "Branding", "low", "low", "palette",
         "I need the branding guidelines."),
        ("Event support request", "service_request", "Marketing", "Event", "low", "medium", "calendar",
         "I need support for an upcoming event."),
        ("Marketing analytics report", "service_request", "Marketing", "Analytics", "low", "low", "bar-chart",
         "I'd like a marketing analytics report."),
        ("Email campaign not sending", "incident", "Marketing", "Campaign", "high", "high", "mail",
         "An email campaign failed to send."),
        ("Landing page build", "service_request", "Marketing", "Website", "low", "low", "globe",
         "Please build a new landing page."),
        ("Logo / design request", "service_request", "Marketing", "Asset Request", "low", "low", "image",
         "I need a logo or design created."),
    ],
    "Security": [
        ("Report a phishing email", "incident", "Security", "Phishing", "high", "high", "alert-triangle",
         "I received a suspicious phishing email."),
        ("Suspected malware infection", "incident", "Security", "Malware", "high", "high", "bug",
         "I think my device is infected with malware."),
        ("Suspicious account activity", "incident", "Security", "Suspicious Activity", "high", "high", "shield",
         "I noticed suspicious activity on my account."),
        ("Report lost or stolen device", "incident", "Security", "Suspicious Activity", "high", "high", "smartphone",
         "My device was lost or stolen."),
        ("Security access review", "service_request", "Security", "Policy Exception", "low", "low", "shield",
         "Please review my security access."),
        ("Request a security exception", "change", "Security", "Policy Exception", "medium", "medium", "shield",
         "I need a security policy exception."),
        ("Firewall rule change", "change", "Network", "Firewall", "medium", "medium", "shield",
         "Please make a firewall rule change."),
        ("SSL certificate renewal", "change", "Security", "Certificate", "high", "medium", "lock",
         "An SSL certificate needs renewal."),
        ("Vulnerability remediation", "problem", "Security", "Vulnerability", "high", "high", "bug",
         "Investigate and remediate a reported vulnerability."),
        ("Data breach investigation", "incident", "Security", "Data Breach", "high", "high", "alert-triangle",
         "Investigate a potential data breach."),
        ("Grant privileged access", "service_request", "Security", "Policy Exception", "medium", "medium", "key-round",
         "I need privileged/admin access granted."),
        ("Security awareness training", "service_request", "Security", "Policy Exception", "low", "low", "book-open",
         "Please enroll me in security awareness training."),
    ],
}

# §3.2 priorities (name == level) and §3.3 statuses (label, category).
_PRIORITIES = ["Urgent", "High", "Medium", "Low"]
_STATUSES = [("Open", "Open"), ("Replied", "Open"),
             ("Resolved", "Resolved"), ("Closed", "Resolved")]

# §3.4 one ticket type per process label (name, process) — default priority Medium.
_TICKET_TYPES = ["Incident", "Problem", "Change", "Service Request", "Question"]

# §3.5 (v2) service catalog — category → subcategories. Served by
# service_request.py via GET /helpdesk/service-catalog; a constant, no new table.
# Also the source of the templates' default_category/default_subcategory above.
SERVICE_CATALOG = {
    "Hardware": ["Laptop", "Desktop", "Monitor", "Peripherals",
                 "Docking Station", "Printer/Scanner", "Audio/Video"],
    "Software": ["Installation", "Licensing", "Updates/Patching",
                 "Application Error", "Configuration", "Access/Permissions"],
    "Network": ["Connectivity", "VPN", "Wi-Fi", "DNS/DHCP",
                "Firewall", "Bandwidth/Performance"],
    "Access & Accounts": ["Password Reset", "Account Lockout", "New Account",
                          "Access Request", "MFA", "Group Membership", "Deprovisioning"],
    "Email & Collaboration": ["Email Delivery", "Mailbox", "Distribution List",
                              "Calendar", "Chat/Teams", "File Sharing", "Video Conferencing"],
    "Security": ["Phishing", "Malware", "Data Breach", "Suspicious Activity",
                 "Policy Exception", "Certificate", "Vulnerability"],
    "Mobile Devices": ["Enrollment", "MDM", "App Install", "Lost/Stolen", "Data Wipe"],
    "Printing": ["Printer Setup", "Print Queue", "Toner/Supplies",
                 "Scan to Email", "Print Quality"],
    "Telephony": ["Desk Phone", "Softphone", "Voicemail", "Conference Line",
                  "Call Routing", "Mobile Plan"],
    "Facilities": ["Office Space", "HVAC", "Lighting", "Furniture",
                   "Access Badge", "Parking", "Cleaning", "Maintenance"],
    "HR": ["Onboarding", "Offboarding", "Payroll", "Benefits",
           "Leave/Time-off", "Personal Info", "Training", "Policy"],
    "Finance": ["Expense", "Procurement", "Invoicing", "Payment", "Budget", "Vendor"],
    "Sales/CRM": ["CRM Access", "CRM Issue", "Lead/Opportunity",
                  "Reporting", "Quotes/Contracts", "Data Import"],
    "Operations": ["Process", "Logistics", "Inventory", "Scheduling",
                   "Quality", "Vendor Management"],
    "Legal": ["Contract Review", "Compliance", "NDA", "Policy",
              "Intellectual Property", "Dispute"],
    "Marketing": ["Asset Request", "Campaign", "Website", "Social Media",
                  "Branding", "Event", "Analytics"],
    "Onboarding/Offboarding": ["New Hire Setup", "Equipment Provisioning",
                               "Access Grant", "Exit Checklist", "Equipment Return"],
}

# §3.6 per-process SLAs: (service_level, condition, {level: (response_s, resolution_s)}).
# Business-hours seconds; resolution ≥ response; Default priority per SLA = Medium.
_SLA_DEFS = [
    ("Incident SLA", "doc.process == 'incident'", {
        "Urgent": (3600, 14400), "High": (7200, 28800),
        "Medium": (14400, 86400), "Low": (28800, 172800)}),
    ("Service Request SLA", "doc.process == 'service_request'", {
        "Urgent": (14400, 28800), "High": (14400, 57600),
        "Medium": (28800, 144000), "Low": (28800, 288000)}),
    ("Change SLA", "doc.process == 'change'", {
        "Urgent": (14400, 86400), "High": (28800, 259200),
        "Medium": (28800, 432000), "Low": (28800, 864000)}),
    ("Problem SLA", "doc.process == 'problem'", {
        "Urgent": (28800, 259200), "High": (28800, 432000),
        "Medium": (28800, 864000), "Low": (28800, 1728000)}),
]

_SERVICE_DAYS = [{"workday": d, "start_time": "09:00:00", "end_time": "17:00:00"}
                 for d in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]]

# §3 backfill: existing tickets → process from ticket_type.name; else incident.
_TYPE_TO_PROCESS = {"Change": "change", "Problem": "problem",
                    "Service Request": "service_request"}

# Preset HD roles (spec §Agent1.5). perm strings are the matrix contract. The
# Requester role is scoped to raise/track-own/KB (NO agent tickets:* perms, so
# it never reaches the agent console); the Agent role is the full console.
_HD_ROLES = {
    "Help Desk Requester": {
        "description": "Raise and track your own Help Desk requests, and browse the knowledge base.",
        "permissions": [
            "helpdesk:requests:create",
            "helpdesk:requests:view_own",
            "helpdesk:kb:view",
        ],
    },
    "Help Desk Agent": {
        "description": "Work the Help Desk agent queue: tickets, ITIL processes, KB authoring, settings.",
        "permissions": [
            "helpdesk:tickets:view",
            "helpdesk:tickets:edit",
            "helpdesk:tickets:assign",
            "helpdesk:processes:view",
            "helpdesk:processes:manage",
            "helpdesk:kb:view",
            "helpdesk:kb:author",
            "helpdesk:requests:view_own",
            "helpdesk:settings:view",
        ],
    },
}


# ─── steps ────────────────────────────────────────────────────────────────────
def _alter_add_columns(db: Session, table: str, cols: list) -> int:
    """ALTER-add each column; IF NOT EXISTS makes it a no-op when present, and
    per-column try/except keeps one failure from aborting the rest."""
    added = 0
    for name, ddl in cols:
        try:
            db.execute(text(f"ALTER TABLE {table} ADD COLUMN IF NOT EXISTS {name} {ddl}"))
            db.commit()
            added += 1
        except Exception:  # noqa: BLE001 — a pre-existing/variant column is non-fatal
            db.rollback()
            logger.warning("itsm_seed: ALTER for %s.%s skipped", table, name, exc_info=True)
    return added


def _add_columns(db: Session) -> int:
    """§3.1 + §A1 — migrate the HDTicket extension columns AND the new
    HDTicketTemplate request-library columns onto existing tenant tables."""
    return (_alter_add_columns(db, "grc_hd_ticket", _ALTER_COLUMNS)
            + _alter_add_columns(db, "grc_hd_ticket_template", _TEMPLATE_ALTER_COLUMNS))


def ensure_attachment_table(db: Session) -> bool:
    """Attachment persistence (bank-hardening) — create grc_hd_attachment on an
    EXISTING tenant DB (create_all only makes it for brand-new tenants). CREATE
    TABLE IF NOT EXISTS + CREATE INDEX IF NOT EXISTS → idempotent, safe to re-run.
    Mirrors the HDAttachment model in _60_helpdesk_native_models.py. Guarded so a
    pre-existing/variant table is non-fatal."""
    try:
        db.execute(text(
            """
            CREATE TABLE IF NOT EXISTS grc_hd_attachment (
                id SERIAL PRIMARY KEY,
                tenant_id INTEGER NOT NULL REFERENCES grc_tenants(id),
                ticket_id INTEGER NOT NULL REFERENCES grc_hd_ticket(id) ON DELETE CASCADE,
                reply_id INTEGER REFERENCES grc_hd_communication(id) ON DELETE SET NULL,
                filename VARCHAR(255) NOT NULL,
                content_type VARCHAR(140),
                size_bytes INTEGER,
                storage_key VARCHAR(64) NOT NULL,
                uploaded_by VARCHAR(255),
                created_at TIMESTAMP DEFAULT now()
            )
            """
        ))
        db.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_hd_attachment_tenant "
            "ON grc_hd_attachment (tenant_id)"))
        db.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_hd_attachment_ticket "
            "ON grc_hd_attachment (ticket_id)"))
        db.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_hd_attachment_reply "
            "ON grc_hd_attachment (reply_id)"))
        db.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_hd_attachment_tenant_ticket "
            "ON grc_hd_attachment (tenant_id, ticket_id)"))
        db.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_hd_attachment_storage_key "
            "ON grc_hd_attachment (storage_key)"))
        db.commit()
        return True
    except Exception:  # noqa: BLE001 — a pre-existing/variant table is non-fatal
        db.rollback()
        logger.warning("itsm_seed: grc_hd_attachment create/index skipped", exc_info=True)
        return False


def _ensure_departments(db: Session, tid: int) -> dict:
    """§A2 — ensure the 5 standard departments exist (enabled); return {name: id}."""
    out: dict = {}
    for name in _DEPARTMENTS:
        d = (db.query(HDDepartment)
             .filter(HDDepartment.tenant_id == tid, HDDepartment.name == name)
             .first())
        if not d:
            d = HDDepartment(tenant_id=tid, name=name, enabled=True)
            db.add(d)
            db.flush()
        out[name] = d.id
    db.commit()
    return out


def seed_request_templates(db: Session, tid: int) -> int:
    """§A2 — seed the department-wise request library. Idempotent: skip a template
    whose template_name + department already exists. Returns the count created."""
    dept_ids = {d.name: d.id for d in
                db.query(HDDepartment).filter(HDDepartment.tenant_id == tid).all()}
    created = 0
    for dept_name, entries in _REQUEST_TEMPLATES.items():
        did = dept_ids.get(dept_name)
        for title, process, category, subcategory, impact, urgency, icon, desc in entries:
            exists = (db.query(HDTicketTemplate)
                      .filter(HDTicketTemplate.tenant_id == tid,
                              HDTicketTemplate.template_name == title,
                              HDTicketTemplate.department_id == did)
                      .first())
            if exists:
                continue
            db.add(HDTicketTemplate(
                tenant_id=tid, template_name=title, department_id=did,
                process=process, default_subject=title, default_description=desc,
                default_category=category, default_subcategory=subcategory,
                default_impact=impact, default_urgency=urgency, icon=icon,
                enabled=True,
            ))
            created += 1
    db.commit()
    return created


def _ensure_priorities(db: Session, tid: int) -> dict:
    """§3.2 — ensure Urgent/High/Medium/Low; return {name: id}."""
    out: dict = {}
    for name in _PRIORITIES:
        p = (db.query(HDTicketPriority)
             .filter(HDTicketPriority.tenant_id == tid, HDTicketPriority.name == name)
             .first())
        if not p:
            p = HDTicketPriority(tenant_id=tid, name=name, level=name)
            db.add(p)
            db.flush()
        out[name] = p.id
    db.commit()
    return out


def _ensure_statuses(db: Session, tid: int) -> None:
    """§3.3 — ensure the four lifecycle statuses (by label_agent)."""
    for label, category in _STATUSES:
        exists = (db.query(HDTicketStatus)
                  .filter(HDTicketStatus.tenant_id == tid,
                          HDTicketStatus.label_agent == label)
                  .first())
        if not exists:
            db.add(HDTicketStatus(tenant_id=tid, label_agent=label, category=category))
    db.commit()


def _ensure_ticket_types(db: Session, tid: int, medium_priority_id) -> None:
    """§3.4 — one ticket type per process label, default priority Medium."""
    for name in _TICKET_TYPES:
        exists = (db.query(HDTicketType)
                  .filter(HDTicketType.tenant_id == tid, HDTicketType.name == name)
                  .first())
        if not exists:
            db.add(HDTicketType(tenant_id=tid, name=name, priority_id=medium_priority_id))
    db.commit()


def _ensure_slas(db: Session, tid: int, pri_ids: dict) -> list:
    """§3.6 — create each per-process SLA via sla.create_sla (so validation +
    default-priority resolution run); skip when the service_level already exists."""
    created = []
    for service_level, condition, targets in _SLA_DEFS:
        exists = (db.query(HDServiceLevelAgreement)
                  .filter(HDServiceLevelAgreement.tenant_id == tid,
                          HDServiceLevelAgreement.service_level == service_level)
                  .first())
        if exists:
            continue
        priorities = [
            {
                "priority_id": pri_ids[level],
                "default_priority": level == "Medium",
                "response_time": resp,
                "resolution_time": reso,
            }
            for level, (resp, reso) in targets.items()
        ]
        sla.create_sla(db, tid, {
            "service_level": service_level,
            "condition": condition,
            "enabled": True,
            "default_sla": False,
            "apply_sla_for_resolution": True,
            "priorities": priorities,
            "service_days": _SERVICE_DAYS,
        })
        created.append(service_level)
    return created


def backfill_process(db: Session, tid: int) -> dict:
    """§3 — set `process` on existing tickets from ticket_type.name
    (Change→change, Problem→problem, Service Request→service_request, else
    incident). Idempotent: re-running only touches rows whose value differs."""
    updated = 0
    for t in db.query(HDTicket).filter(HDTicket.tenant_id == tid).all():
        tname = t.ticket_type.name if t.ticket_type else None
        proc = _TYPE_TO_PROCESS.get(tname, "incident")
        if t.process != proc:
            t.process = proc
            updated += 1
    db.commit()
    return {"updated": updated}


def recompute_all_slas(db: Session, tid: int) -> dict:
    """§1d — recompute the SLA for every ticket in the tenant so tickets created
    before SLA-on-create get response_by / resolution_by / agreement_status
    backfilled. Runs sla.recompute with prev_status_category = the ticket's own
    category (not a status transition — a backfill must not look like a
    pause/resume). Per-ticket guarded so one failure can't abort the backfill.
    Idempotent: recompute is deterministic from the ticket's current state.
    Returns the count recomputed."""
    count = 0
    for t in db.query(HDTicket).filter(HDTicket.tenant_id == tid).all():
        try:
            sla.recompute(db, t, prev_status_category=t.status_category)
            count += 1
        except Exception:  # noqa: BLE001 — a bad row must not block the rest
            logger.warning("itsm_seed: SLA recompute failed for ticket %s", t.id,
                           exc_info=True)
    db.commit()
    return {"recomputed": count}


def seed_hd_roles(db: Session, tid: int) -> list:
    """§Agent1.5 — create the two per-tenant preset HD roles (idempotent).

    Mirrors admin_router.create_role: a tenant-scoped Role plus RolePermission
    rows. Crucially it routes every permission through
    admin_router._get_or_create_permission so the `helpdesk:*` rows are INSERTED
    into grc_permissions on-demand — that is what makes them grantable in the
    Admin > Roles matrix on an already-existing tenant (e.g. ava). Re-running
    only adds roles/links that are missing, never duplicates. Admin +
    primary-contact bypass is untouched (they don't need these roles)."""
    from ...routers.admin_router import _get_or_create_permission  # lazy: avoid import cycle

    out: list = []
    for name, spec in _HD_ROLES.items():
        role = (db.query(Role)
                .filter(Role.tenant_id == tid, Role.name == name)
                .first())
        if not role:
            role = Role(tenant_id=tid, name=name,
                        description=spec["description"], is_system_role=False)
            db.add(role)
            db.flush()  # need role.id for the RolePermission rows
        linked = {rp.permission_id for rp in
                  db.query(RolePermission).filter(RolePermission.role_id == role.id).all()}
        for perm_name in spec["permissions"]:
            perm = _get_or_create_permission(db, perm_name)
            if perm and perm.id not in linked:
                db.add(RolePermission(role_id=role.id, permission_id=perm.id))
                linked.add(perm.id)
        db.commit()
        out.append({"id": role.id, "name": role.name,
                    "permissions": spec["permissions"]})
    return out


def seed_itsm(db: Session, tid: int) -> dict:
    """§3 — idempotent ITSM seed. Order matters: columns exist before backfill,
    priorities exist before the SLAs reference them, and the SLA backfill runs
    last (needs the per-process SLAs already seeded above)."""
    columns = _add_columns(db)
    attachment_table = ensure_attachment_table(db)
    pri_ids = _ensure_priorities(db, tid)
    _ensure_statuses(db, tid)
    _ensure_ticket_types(db, tid, pri_ids.get("Medium"))
    slas_created = _ensure_slas(db, tid, pri_ids)
    depts = _ensure_departments(db, tid)
    templates_created = seed_request_templates(db, tid)
    backfill = backfill_process(db, tid)
    sla_backfill = recompute_all_slas(db, tid)
    hd_roles = seed_hd_roles(db, tid)
    return {
        "ok": True,
        "columns_processed": columns,
        "attachment_table": attachment_table,
        "priorities": list(pri_ids),
        "statuses": [s[0] for s in _STATUSES],
        "ticket_types": list(_TICKET_TYPES),
        "service_catalog": list(SERVICE_CATALOG),
        "slas": [d[0] for d in _SLA_DEFS],
        "slas_created": slas_created,
        "departments": list(depts),
        "templates_created": templates_created,
        "backfilled": backfill["updated"],
        "slas_recomputed": sla_backfill["recomputed"],
        "hd_roles": [r["name"] for r in hd_roles],
    }


# ─── endpoint (Agent B mounts this router alongside the others) ──────────────
router = APIRouter(prefix="/helpdesk", tags=["Help Desk ITSM"])


@router.post("/itsm/seed")
def _seed_itsm_ep(db: Session = Depends(get_db), _: bool = Depends(require_edit)):
    return seed_itsm(db, tenant_id(db))


if __name__ == "__main__":
    # Pure self-check — the matrix (§4) + the SLA target table (§3.6). No DB.
    from .tickets import priority_name_from_matrix as pm

    assert pm("high", "high") == "Urgent"
    assert pm("high", "medium") == "High"
    assert pm("high", "low") == "Medium"
    assert pm("medium", "high") == "High"
    assert pm("medium", "medium") == "Medium"
    assert pm("medium", "low") == "Low"
    assert pm("low", "high") == "Medium"
    assert pm("low", "medium") == "Low"
    assert pm("low", "low") == "Low"
    assert pm("bogus", "low") is None and pm(None, None) is None

    assert [d[0] for d in _SLA_DEFS] == [
        "Incident SLA", "Service Request SLA", "Change SLA", "Problem SLA"]
    for name, cond, targets in _SLA_DEFS:
        assert cond.startswith("doc.process =="), cond
        assert set(targets) == set(_PRIORITIES), name
        for level, (resp, reso) in targets.items():
            assert resp > 0 and reso >= resp, (name, level)

    # §1a service catalog: 10+ categories, each 5–10 subcategories, no dup subs.
    assert len(SERVICE_CATALOG) >= 10, len(SERVICE_CATALOG)
    for cat, subs in SERVICE_CATALOG.items():
        assert 5 <= len(subs) <= 10, (cat, len(subs))
        assert len(subs) == len(set(subs)), f"duplicate subcategory in {cat}"

    # §1b request library: 9 depts, 100+ templates, valid process/impact/urgency,
    # unique template_names (template_name is unique per tenant), and every
    # category/subcategory drawn from the catalog (catches hand-entry typos).
    assert set(_REQUEST_TEMPLATES) == set(_DEPARTMENTS), _REQUEST_TEMPLATES.keys()
    _procs = {"incident", "problem", "change", "service_request", "question"}
    _levels = {None, "low", "medium", "high"}
    all_titles = []
    per_dept = {}
    for dept, entries in _REQUEST_TEMPLATES.items():
        per_dept[dept] = len(entries)
        assert 10 <= len(entries) <= 18, (dept, len(entries))
        for title, process, category, subcategory, impact, urgency, icon, desc in entries:
            assert process in _procs, process
            assert impact in _levels and urgency in _levels, (title, impact, urgency)
            assert title and icon and desc, title
            assert category in SERVICE_CATALOG, (title, category)
            assert subcategory in SERVICE_CATALOG[category], (title, category, subcategory)
            all_titles.append(title)
    assert len(all_titles) >= 100, len(all_titles)
    assert len(all_titles) == len(set(all_titles)), "duplicate template_name"

    # §Agent1.5 preset roles: every granted perm must be a real string in the
    # PERMISSION_MATRIX helpdesk module (catches a typo that would seed a role
    # with a dead/ungrantable permission).
    from ...permissions import get_all_permissions
    _hd_perms = {p["name"] for p in get_all_permissions()
                 if p["module"] == "helpdesk"}
    assert _hd_perms, "helpdesk module missing from PERMISSION_MATRIX"
    for _role, _spec in _HD_ROLES.items():
        for _p in _spec["permissions"]:
            assert _p in _hd_perms, (_role, _p)
    assert _HD_ROLES["Help Desk Requester"]["permissions"] == [
        "helpdesk:requests:create", "helpdesk:requests:view_own", "helpdesk:kb:view"]

    print(f"itsm_seed self-check ok — {len(SERVICE_CATALOG)} categories, "
          f"{len(all_titles)} templates {per_dept}; "
          f"HD roles {list(_HD_ROLES)} perms ok ({len(_hd_perms)} in matrix)")
