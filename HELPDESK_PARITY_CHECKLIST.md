# Frappe Helpdesk → AVA Help Desk — feature parity & flows

**Naming:** Frappe's product is **Helpdesk** (ticket-centric customer/IT help desk). A full **ITIL IT Service Desk** (incident→problem→change) is a different class (that's GLPI). In Frappe, "incident management" = tickets of **type = Incident**; the core object is the **Ticket**. So "Help Desk" / "Service Desk" here both mean *ticket management*.

## Frappe's own agent sidebar (what it actually shows)
Tickets · Dashboard · Knowledge Base · Customers · Contacts · Agents · Teams · Canned Responses · Settings (SLA policies, Ticket Types, Email) · Call Logs (telephony)

## Parity table — have / missed
| # | Frappe feature | How it behaves | AVA Help Desk section | Status |
|---|---|---|---|---|
| 1 | **Tickets list** | filter/sort/search, status tabs, open a ticket | **Tickets** | ✅ built (list + board) |
| 2 | **Ticket detail + conversation** | email thread, agent replies, internal notes, timeline | **Ticket detail** | ✅ built (timeline + composer) |
| 3 | **Status lifecycle** (Open→Replied→Resolved→Closed, reopen) | agent/customer actions move status | status chips + Resolve/Close | ✅ |
| 4 | **Ticket types** (Incident / Request / Question) | categorises a ticket | field shown on ticket | ⚠️ shown, no type filter yet |
| 5 | **Priority + SLA** (Urgent…Low, response/resolution timers, breach) | timers run, `agreement_status` flags breach | SLA fields on detail | ✅ shown (timers run in engine) |
| 6 | **Assignment** (agent/team + assignment rules) | auto-routes new tickets | Agents + Teams sections | ✅ structure (rules run in engine) |
| 7 | **Agents** (profiles, availability Active/Away) | who works tickets | **Agents** | ✅ |
| 8 | **Teams** (group agents + a rule) | route to a team | **Teams** | ✅ |
| 9 | **Canned responses** | reusable replies | **Canned Responses** | ✅ |
| 10 | **Knowledge Base** (articles + categories) | help content | **Knowledge Base** | ✅ |
| 11 | **Customers** (orgs) | ticket requesters' companies | **Customers** | ✅ |
| 12 | **Contacts** (people) | individual requesters | **Contacts** | ✅ |
| 13 | **Dashboard / analytics** (volume, SLA, by status/priority) | ops overview | **Dashboard** | ✅ (KPIs + breakdowns) |
| 14 | **Email-to-ticket** (inbound mailbox → ticket) | customers email → ticket auto-created | runs **inside the Frappe engine** | ✅ engine (configure once) |
| 15 | **Customer portal** (external self-service) | customers submit/track their own tickets | — | ❌ by design (AVA is internal) — build later if needed |
| 16 | **CSAT / feedback** (post-resolution rating) | satisfaction survey | — | ❌ not yet (easy add) |
| 17 | **Ticket ops**: reply, comment, resolve, close, reassign | agent actions | reply/resolve/close wired | ⚠️ merge/split, bulk actions not yet |
| 18 | **Settings** (SLA policies, ticket types, email accounts) | admin config | — | ⚠️ configured in Frappe directly, not surfaced in AVA yet |
| 19 | **Tags / saved views / bulk actions** | organise lists | — | ❌ not yet |
| 20 | **Call logs** (telephony) | call records on tickets | — | ❌ intentionally skipped (no telephony) |

## What AVA ADDS beyond a vanilla Frappe Helpdesk (your edge)
- **Findings auto-become tickets** (Push-to-ITSM) carrying CVE / CVSS / affected host / finding id.
- **Ticket ↔ finding ↔ asset cross-links** (a ticket links to its finding; a finding lists its tickets).
- **Resolution feeds back** → advances the AVA remediation plan.
- Tickets born from scanner + AI-pentest + manual findings — no human typing.

## End-to-end flow (how it actually works)
1. **Create** — (a) from an AVA finding via **Push-to-ITSM** → HD Ticket with CVE/CVSS/host; (b) inbound **email** → ticket (engine); (c) manual.
2. **Route** — assignment rule assigns a team/agent (engine).
3. **SLA clock** — `response_by` / `resolution_by` set from priority; `agreement_status` tracks breach (engine).
4. **Work** — agent replies (email), adds internal notes, changes status.
5. **Resolve → Close** — resolved; auto-closed after N idle days (engine).
6. **Sync back** — resolution advances AVA's remediation plan.
7. **Reopen** — a customer reply reopens the ticket.

## Decide next (gaps worth closing)
- **CSAT screen** (feedback rating) — small add.
- **Settings UI** in AVA (SLA policies, ticket types, email) — or keep configuring in the engine.
- **Ticket type filter** + **tags / saved views / bulk actions**.
- **Customer portal** — only if you want external requesters.
