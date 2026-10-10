# Help Desk Product Integration (SRS summary)

## 1. Information architecture
Sidebar (Administration popover stays pinned at the bottom, unchanged):

| Top level | Contents |
|---|---|
| Performance (standalone) | `/dashboard`, cross-product home |
| IT Asset | Discovery `/asset-discovery`, Inventory `/assets`, Assets Risk Posture `/risk-posture` |
| Cybersecurity | Vulnerabilities `/vulnerabilities`, AI Pentest `/pentest`, Reports `/reports` |
| Help Desk | Dashboard, Tickets, Agents, Teams, Customers, Contacts, Knowledge Base, Canned Responses (`/helpdesk/*`) |

Existing permission, module, `activeMatch` and `adminOnly` gates are unchanged; only grouping changed. A group with no visible children is hidden.

## 2. Where Help Desk sits
Help Desk is the remediation-execution layer of the CTEM loop: Discover (IT Asset) -> Find (Cybersecurity) -> Mobilise (Help Desk) -> Verify (re-scan). It is a peer top-level category, backed by an isolated Frappe engine over REST (`helpdesk-sidecar/`).

## 3. Data flows
1. **Finding -> ticket:** the finding detail ITSM panel pushes the finding to a configured ticketing connector. A remediation plan is created or reused and a ticket opened.
2. **Context on the ticket:** the ticket carries asset and CVE context (`cve_id` / `finding_id` where supplied), so agents see what must be fixed and on which asset.
3. **Ticket status -> plan:** syncing statuses maps the ticket to a normalised status. Resolved advances the remediation plan to *applied*. *Verified* is reserved for the scanner re-test path and is never set by a ticket.

## 4. Cross-navigation
- Ticket detail, Properties sidebar: a "Related finding" row appears only if the ticket has `finding_id` (links to `/vulnerabilities/<id>`) or `cve_id` (links to `/vulnerabilities?q=<cve>`).
- Finding detail, ITSM panel: a "View in Help Desk" link to `/helpdesk/tickets`.
- Sidebar places Help Desk beside the modules it serves.

## 5. Roles and permissions
- Sidebar visibility follows the existing per-item gates (e.g. `vulnerabilities:vulnerability_register:*`, `assets:asset_inventory:*`, `erm:risks:*`).
- Pushing to ITSM requires `vulnerabilities:vulnerability_register:edit`.
- Help Desk items carry no extra frontend gate today; access is enforced by the helpdesk API. Admins bypass the nav gates.

## 6. End-to-end flows
**Agent:** open a finding -> Push to ITSM -> ticket appears in Help Desk Tickets -> assign agent/team, reply or comment -> resolve -> sync -> plan advances to applied -> follow "Related finding" back to the finding -> re-scan verifies.

**Requester:** a contact raises a ticket (or receives one created from a finding) -> receives agent replies -> sees resolution -> the finding is re-scanned and closed when proven fixed.
