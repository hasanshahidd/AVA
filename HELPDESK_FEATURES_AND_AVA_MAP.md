# Frappe Helpdesk — every feature, and how it maps into AVA

AVA already does: **asset discovery, scanning, asset inventory, vulnerability management, connectors, assignment, SLA (partial), remediation plans**. A help desk adds the **ticket workflow layer** on top — conversations, SLA engine, routing, self-service, KB, CSAT, analytics.

**How integration works for ALL of it (one mechanism):** Frappe runs hidden as the engine. AVA's backend talks to it over REST (the connector/adapter). AVA's frontend shows the screens. So each feature is either: **(data)** read/write over REST and shown in AVA's UI, **(behavior)** runs automatically inside Frappe and AVA just benefits, or **(AVA already has it)** so we feed AVA's data in instead of duplicating.

Legend: 🟢 surface in AVA UI over API · ⚙️ runs inside Frappe automatically · 🔵 AVA already has an equivalent (feed it in)

---

## 1. Core ticketing
| Frappe feature | What it does | AVA integration |
|---|---|---|
| **HD Ticket** | The ticket: subject, description, status, priority, type, team, dates | 🟢 Create from any AVA finding (push-to-ITSM, already wired). Shown on AVA's Help Desk board. |
| **Status lifecycle** | Open → Replied → Resolved → Closed (+ reopen); categories Open/Paused/Resolved | 🟢 Mapped to AVA's taxonomy (new/in_progress/on_hold/resolved/closed). 🔵 AVA findings also have their own status — kept separate (ticket close ≠ finding verified). |
| **Priorities** | Urgent / High / Medium / Low | 🔵 Driven by AVA finding **severity** (critical→Urgent, …). Auto-set on push. |
| **Ticket types** | Categorise tickets (Incident, Request, etc.) | 🟢 Set a default type per connection; e.g. "Vulnerability Remediation". |
| **Custom fields** | Extra fields on a ticket | 🔵 We add `ava_finding_id`, `cve_id`, `cvss_score`, `asset_host` so each ticket carries AVA context. |

## 2. Workflow, SLA & routing  (the biggest value-add)
| Frappe feature | What it does | AVA integration |
|---|---|---|
| **SLA engine** | Response + resolution targets per priority, business hours, holidays, auto-pause on hold, breach tracking (`agreement_status`) | ⚙️ Runs inside Frappe automatically once configured. 🔵 Richer than AVA's current SLA router — this becomes AVA's SLA clock for remediation. |
| **Teams (HD Team)** | Group agents; route tickets to a team | 🟢 One team per **AVA tenant** (keeps tenants isolated). Also usable as department queues. |
| **Assignment Rules** | Auto-assign tickets (round-robin / load-based), agent availability tiers | ⚙️ Runs in Frappe. 🔵 Complements AVA's `assigned_to` (person) — ticket routing + AVA owner. |
| **Agents (HD Agent)** | Agent profiles, availability (Active/Away/Unavailable) | 🟢 Map AVA users → agents, or keep a small ops team. |
| **Escalation** | Escalate on SLA breach (via rules/SLA levels) | ⚙️ Configure in Frappe; AVA sees the escalated state via status sync. |
| **Auto-close** | Close resolved tickets after N idle days | ⚙️ Runs in Frappe (daily job). |

## 3. Collaboration & communication
| Frappe feature | What it does | AVA integration |
|---|---|---|
| **Conversations (Communication)** | Full email/reply thread per ticket (agent ↔ requester) | 🟢 Surface the thread in AVA's ticket detail; post replies via API. This is what AVA's vuln module lacks today. |
| **Internal comments** | Private agent notes | 🟢 Show/add in AVA ticket detail. |
| **Email-to-ticket** | Inbound email auto-creates/updates tickets (bounce-loop guarded, thread stitching) | ⚙️ Configure a mailbox in Frappe; tickets appear in AVA automatically. Lets non-AVA users raise tickets by email. |
| **Canned responses (Saved Reply)** | Reusable reply templates, team-scoped | 🟢 Expose in the AVA reply box. |
| **Mentions / notifications** | Notify agents on events | ⚙️ Frappe sends; or mirror into AVA's existing notifications. |
| **Merge & split** | Combine duplicate tickets / split one | 🟢 Optional AVA actions over API. |

## 4. Self-service & knowledge
| Frappe feature | What it does | AVA integration |
|---|---|---|
| **Customer portal** | External users submit & track their tickets | 🟢 Either build an AVA-branded portal over the API, or expose Frappe's portal on a subdomain **only if** you don't mind a separate UI. (For "no Frappe visible", build AVA's.) |
| **Knowledge Base (HD Article)** | Help articles + categories + feedback | 🟢 Surface in AVA (e.g. remediation how-tos linked to findings). 🔵 Could tie KB articles to CVE/finding types. |

## 5. Insight
| Frappe feature | What it does | AVA integration |
|---|---|---|
| **Dashboards / analytics** | Ticket volume, SLA performance, agent stats | 🟢 Pull metrics via API into AVA's exec/estate dashboards, AVA-branded. |
| **CSAT / feedback** | Post-resolution rating + comment | 🟢 Collect via AVA UI or email; show satisfaction in AVA. |
| **Tags** | Label/filter tickets | 🟢 Use for CVE class, campaign, etc. |

---

## What AVA feeds INTO the help desk (your edge)
Because AVA already does discovery/scan/vuln, your tickets are **auto-enriched** in ways a bare help desk can't:
- **Finding → ticket** automatically (scanner, AI-pentest, or manual) — no human typing tickets.
- **Asset context** (`affected_host`, exposure) from AVA's asset discovery — as ticket fields (never a duplicate CMDB).
- **Severity/CVE/CVSS/KEV/EPSS** from AVA enrichment → ticket priority + fields.
- **Remediation plan** text from AVA → ticket body.
- **Status sync-back** → closing a ticket advances AVA's remediation plan.

## What stays in Frappe vs built in AVA
- **Stays in Frappe (hidden engine, configure once):** SLA engine, assignment rules, auto-close, email ingestion, webhooks, the data store.
- **Built in AVA (your UI, your brand):** the Help Desk board, ticket detail + conversation, reply box, KB view, dashboards, (optional) customer portal.
- **AVA already has (don't duplicate):** asset inventory, finding register, finding status, owner assignment, remediation plans.

---

### Bottom line
You get **100% of Frappe's help-desk features**, but your users only ever see AVA. The heavy engine features (SLA, routing, email, auto-close) run inside Frappe for free; the screens are AVA's; and AVA's scanning/asset/vuln data makes the tickets smarter than a standalone help desk could.
