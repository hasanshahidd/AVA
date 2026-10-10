# How much of a full IT Service Desk does Frappe Helpdesk cover?

Legend: ✅ Frappe covers it · 🟡 partial / needs custom fields or config · ❌ Frappe doesn't have it · **AVA** = already provided by AVA (not Frappe).

| # | ITSM area | Frappe coverage | Notes / what's missing | AVA fills? |
|---|---|---|---|---|
| 1 | **User Management** | 🟡 | Framework User + Contact + HD Customer give email, phone, roles, permissions, auth, last-login, status. Missing natively: Employee ID, Department, Job Title, Manager, VIP flag, preferred language/channel → custom fields. | AVA Identity module (RBAC, IdP) |
| 2 | **Ticket Management** (core) | ✅ | HD Ticket covers ID/number, title, description, type, priority, status, requester, agent, team, timestamps, due/SLA, attachments, public+internal comments, comm history, merge/split, reopen count, resolution, feedback. Missing/custom: Category+Subcategory (only ticket_type), separate Severity, Root Cause, Related Assets/Services. | Asset/CVE context added |
| 3 | **Ticket statuses** | ✅ | Open/Replied/Resolved/Closed seeded; admin can add New/Assigned/In Progress/Pending/Cancelled. Fully configurable. | — |
| 4 | **Incident Management** | 🟡 | An incident = ticket `type=Incident` (with SLA, triggers, routing) — this IS incidents. Missing as first-class: Impact×Urgency matrix, Related Problem, Related Change, Post-Incident Review, Business Impact. | — |
| 5 | **Service Request Mgmt** | 🟡 | Requests = ticket `type=Request`. Missing: **approval workflow**, business justification, approver, cost estimate/actual, fulfillment workflow. Frappe Helpdesk has no request-approval engine. | AVA workflow_engine (approvals) |
| 6 | **SLA Management** | ✅ | Strong: per-priority response/resolution targets, business hours, holiday calendar, pause-on-hold, breach (`agreement_status`), actual times, compliance. Missing: severity-based SLA (priority only), explicit multi-level escalation rules. | — |
| 7 | **IT Asset Management** | ❌ | Frappe Helpdesk has **no asset module**. | **AVA ✅** — full IT Asset Discovery + Inventory (hostname, IP, MAC, OS, CPU/RAM/storage, location, owner, status) |
| 8 | **Knowledge Base** | ✅ | HD Article + categories + feedback (title, category, author, publish status, views, helpful votes, visibility). Missing/custom: structured Symptoms/Steps fields, versioning, formal review workflow, expiry/review date. | — |
| 9 | **Agent Management** | 🟡 | HD Agent + availability + Teams. Missing: skills, certifications, experience, shift/working hours, live workload/active-ticket count, per-agent MTTR/CSAT (computable via reports), escalation level. | — |
| 10 | **IT Service Catalog** | 🟡/❌ | Only ticket types as a weak proxy. No true catalog (service offerings, request forms, eligibility, fulfillment workflow, per-service SLA, cost). | — (net-new) |
| 11 | **Problem Management** | ❌ | **No Problem entity**, no known-error DB, no linking many incidents to a root-cause problem. | — (net-new) |
| 12 | **Access Management** | ❌ | No access-request → provisioning → revocation → review workflow (could be a ticket type, but no engine). Framework has RBAC. | AVA Identity (RBAC/IdP) partial |
| 13 | **Network/Infra Monitoring** | ❌ | Helpdesk doesn't monitor infrastructure. | **AVA 🟡** — asset discovery, network topology, scanning (not live CPU/uptime perf) |
| 14 | **Communication / Notifications** | ✅ | Email + in-app (HD Notification): recipient, channel, type, related ticket, message, trigger, delivery/read status. Missing: SMS, rich user preferences. | AVA notifications too |
| 15 | **Approval Workflows** | ❌ | Helpdesk ships no approval engine (framework has a generic Workflow state machine, but not wired for requests/changes). | **AVA workflow_engine ✅** |
| 16 | **Reporting & Analytics** | ✅ | Operational metrics strong (total/open/closed, by category/priority/agent/team, unassigned, overdue, reopened, backlog). Performance: MTTR, first response, SLA compliance/breach built or computable. Missing: cost-per-ticket, self-service-resolution rate. | AVA exec dashboards |
| 17 | **Security & Audit** | ✅ | Framework-level: auth, MFA, RBAC, permission mgmt, change audit (Version), login history, failed logins, sessions, encryption. Missing/custom: sensitive-data masking, retention policy. | AVA audit logs + identity |
| 18 | **Self-Service Portal** | ✅ | Frappe HAS a customer portal (submit/track tickets, KB, search, attachments, status, notifications). Weak: service-catalog in portal. (We chose not to surface it since AVA is internal — but it exists.) | — |
| 19 | **Integrations** | 🟡 | Framework: REST API, Webhooks (HMAC), email, OAuth/SAML/LDAP, ERPNext, telephony. Specific connectors vary. | **AVA ✅** — rich connectors module (ServiceNow, SIEM, scanners, M365/Entra) |
| 20 | **CMDB** | ❌ | No configuration-item model / CI relationships in Helpdesk. | **AVA 🟡/✅** — asset inventory + network topology (CI-like with relationships; not a full ITIL CMDB) |
| 21 | **Remote IT Support** | ❌ | No remote-desktop/session feature (telephony app is calls only). | — (external tool) |
| 22 | **Procurement / Vendor Mgmt** | ❌ | Not in Helpdesk (that's ERPNext). | — (net-new) |
| 23 | **AI-Powered Service Desk** | ❌ | Frappe Helpdesk is not AI-native. | **AVA ✅ (core strength)** — AI-native: auto-categorisation, routing, KB/RAG search, suggested resolutions, summarisation, root-cause hints, SLA-breach prediction |
| 24 | **Dashboard widgets** | ✅ | HD Dashboard: total/open/unassigned, SLA, critical, MTTR, FCR, agent workload, trends, category, CSAT. Missing: SLA-at-risk, service-availability, pending-approvals widgets. | AVA dashboards |
| 25 | **DB structure** | 🟡 | Frappe collapses incidents/requests/problems/changes into **one HD Ticket table + type**, not separate tables. Has users/agents/teams/tickets/comments/attachments/history/SLA/KB/surveys/notifications. Missing tables: assets, services, problems, changes, approvals, cmdb, procurement. | AVA has assets/cmdb/workflow tables |

## Layer-by-layer verdict (your Section 26)

| Layer | Frappe | With AVA |
|---|---|---|
| **1 — UI** (portal, agent workspace, admin, dashboard) | ✅ | ✅ (AVA's own UI) |
| **2 — Core Service Desk** (ticket, incident, request, SLA, escalation, KB) | ✅ **strong** (escalation partial) | ✅ |
| **3 — IT Operations** (asset, problem, change, catalog, CMDB, remote) | ❌ **mostly missing** | 🟡 AVA fills **asset + CMDB**; problem/change/catalog/remote still net-new |
| **4 — Automation & Integration** (workflow, approval, email, identity, monitoring, APIs) | 🟡 (email✅, APIs✅) | ✅ AVA fills **approval(workflow_engine), identity, monitoring, connectors** |
| **5 — Security & Governance** (RBAC, MFA, audit, data protection, compliance) | ✅ framework | ✅ + AVA audit/identity/compliance |
| **6 — Intelligence & Analytics** (reporting, predictive, AI classify/troubleshoot/automate) | reporting✅, AI❌ | ✅ AVA is **AI-native** |

## Bottom line (the honest number)
- **Frappe Helpdesk alone** covers roughly the **Core Service Desk spine** — about **45–50%** of your full enterprise blueprint: tickets, incidents-as-tickets, service-requests-as-tickets, SLA, KB, agents/teams, notifications, portal, operational reporting, framework security.
- **It does NOT have:** Problem Mgmt, Change Mgmt, Service Catalog, Access provisioning, CMDB, Asset Mgmt, Monitoring, Approvals, Remote support, Procurement, AI.
- **AVA already fills a big chunk of those gaps:** **Asset Management + CMDB-like inventory/topology, AI (core), Connectors/Integrations, Workflow engine (approvals), Identity/RBAC, dashboards.**
- **Frappe + AVA together** ≈ **70–80%** of the enterprise blueprint out of the box.
- **Genuinely net-new (neither has):** **Problem Management, Change Management, full Service Catalog, Access-request provisioning, Remote support, Procurement/Vendor.** These would be new modules if you want full ITIL.

## Recommended split for AVA's "IT Service Desk"
- **Use Frappe for:** tickets/incidents/requests, SLA, KB, agents/teams, notifications, portal, operational reporting (the Core Service Desk).
- **Use AVA's existing modules for:** Asset Mgmt + CMDB, AI assistance, Connectors/Integrations, Approvals (workflow_engine), Identity/RBAC, exec dashboards.
- **Decide whether to build:** Problem Mgmt, Change Mgmt, Service Catalog, Access provisioning (these are the real ITIL additions).
