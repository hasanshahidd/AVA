# Help Desk API Contract

The exact contract AVA's existing Help Desk frontend depends on, so a **native
FastAPI backend can replace the Frappe-proxy** (`backend/grc/modules/helpdesk/router.py`)
with zero/minimal UI change.

**Source of truth = the `.tsx` usage**, not the Pydantic/TS types. Every field
below is one a component actually reads. If a field the proxy returns isn't
listed, no page reads it today — the native backend may drop it.

## Transport / conventions

- Axios base URL is `/api` (`grc-frontend/src/lib/api.ts`). Paths below are what
  the components pass to `apiClient`; the real request is `/api` + that path.
- Auth: `Authorization: Bearer <token>` + `X-Tenant-Slug: <slug>` headers are
  injected by the axios interceptor. The native backend must accept both and
  scope every response to the tenant.
- `useHd(path)` (`helpdesk/_ui.tsx`) does a bare `GET path`, sets `data = res.data`,
  and **swallows all errors** (shows a soft banner). So a native backend should
  return `200` with empty collections rather than `4xx/5xx` on "nothing/not
  configured" — the UI already renders fine against empty shapes.
- Two distinct backends feed these screens:
  - **Native Help Desk** — FE path prefix `/helpdesk/*` (proxy router mounted
    app-level, `prefix="/helpdesk"`). This is the engine being reimplemented.
  - **Remediation/ITSM** — FE path prefix `/vuln-management/*`
    (`modules/vuln_management/routers/itsm.py`). Finding→ticket creation + the
    legacy remediation board live here. **Out of scope to reimplement** but
    documented because two Help Desk pages read it.

### Status / enum values the UI styles (helpdesk/_ui.tsx)

The native backend should emit values that key into these maps (case-insensitive,
spaces→underscore). Unknown values render with a neutral grey chip — safe, but
colour is lost.

- Ticket status chips: `open, replied, paused, resolved, closed` (+ KB:
  `published, draft, archived`; + remediation: `new, in_progress, on_hold, cancelled`).
- Priority chips: `urgent, high, medium, low`.
- Agent availability chips: `active, away, unavailable`.
- Board columns (native tickets page): `Open, Replied, Resolved, Closed` matched
  case-insensitively against `ticket.status`.

---

# A. Native Help Desk endpoints (`/helpdesk/*`) — REIMPLEMENT THESE

## A1. `GET /helpdesk/dashboard`
Consumer: `helpdesk/dashboard/page.tsx` (only `recent[]` is read).

Request: none.

Response — fields the UI reads:
```jsonc
{
  "recent": [            // ← ONLY this array is consumed by the dashboard page
    { "name": "string",  // ticket id; used as key + link /helpdesk/tickets/{name}
      "subject": "string",
      "status": "string",   // → Chip
      "priority": "string", // → PRIORITY chip
      "modified": "ISO ts" }// → timeAgo()
  ]
  // open/resolved/overdue/unassigned/total/by_status/by_priority are returned
  // by the proxy but NOT read anywhere — the dashboard uses dashboard-analytics
  // for its KPIs. Native backend MAY omit them.
}
```

## A2. `GET /helpdesk/dashboard-analytics`
Consumer: `helpdesk/dashboard/page.tsx` (KPIs, trend area-chart, 4 donuts).

Request: none.

Response — every field is read:
```jsonc
{
  "total": 0,                         // KPI "Total tickets"
  "sla_fulfilled_pct": 92.5,          // KPI; null → "—"
  "avg_first_response_hours": 3.4,    // KPI; null → "—"; fmtH() renders m/h/d
  "avg_resolution_days": 1.8,         // KPI; null → "—"
  "avg_feedback_rating": 4.2,         // KPI (/5 scale); null → "—"
  "feedback_count": 12,               // KPI subtitle "N rated"
  "trend": [ { "date": "YYYY-MM-DD", "created": 0, "resolved": 0 } ],
                                      // area chart; expects ~30 daily points
  "by_priority": { "high": 3, ... },  // donut (keyed colour by priority name)
  "by_status_category": { "Open": 5, ... }, // donut
  "by_team": { "Tier 1": 2, ... },    // donut
  "by_type": { "Incident": 4, ... }   // donut
}
```
COMPUTE: all of it — SLA %, avg response/resolution (timestamp deltas), feedback
mean (note proxy stores 0–1 and multiplies by 5), the 30-day created-vs-resolved
daily trend, and the four `Counter` breakdowns. See `compute_analytics()` for the
reference math.

## A3. `GET /helpdesk/tickets`
Consumers: `tickets/page.tsx` (main list/board), `home/page.tsx` ("my queue"),
`tickets/[name]` (agents dropdown via a separate call). **All filtering, sorting,
grouping and saved-views are done CLIENT-SIDE over the full list** — the backend
just returns every tenant ticket.

Request (query params — defined on the proxy, but the FE calls it with **none**;
`useHd` passes no params):
- `status?: string` — exact match (unused by FE today).
- `q?: string` — substring on subject+name (unused by FE; FE filters locally).

Response:
```jsonc
{
  "tickets": [ {
    "name": "string",            // id; key, links, selection, search
    "subject": "string",         // list + board card title, search
    "status": "string",          // Chip; board column match; open/closed logic
    "priority": "string",        // PRIORITY chip; sort key; group key
    "type": "string|null",       // (returned; not shown as column today)
    "team": "string|null",       // "Team" column; filter; group key; search
    "agent": "string|null",      // assignee email; "Assignee" col; filter; "mine" match (home); search
    "agreement_status": "string|null", // "Failed" drives SLA-at-risk view
    "customer": "string|null",   // "Customer" column; search
    "contact": "string|null",    // search only
    "created": "ISO ts",         // timeAgo(); sort "created"; assigned-view ordering
    "modified": "ISO ts",        // assigned-view ordering (fallback to created)
    "response_by": "ISO ts|null",// SlaBadge; SLA-at-risk; sort "sla"
    "resolution_by": "ISO ts|null", // SLA-at-risk check
    "feedback_rating": 0.8,      // "With feedback" view = rating>0 (0–1 scale ok, only >0 tested)
    "cve_id": "string|null"      // "CVE" column (red chip); search
  } ],
  "summary": { "Open": 3, ... }, // returned; NOT read (counts are computed client-side)
  "total": 0                     // returned; NOT read
}
```
Behaviour-driving fields: `status, priority, agreement_status, response_by,
resolution_by, agent, created/modified, feedback_rating`. Display-only: `subject,
team, customer, contact, cve_id, type`.

**Saved views (client-side presets in `tickets/page.tsx`)** — the native backend
needs NO view endpoint, but must return the fields these presets read:
- `all` — everything.
- `pending` — `status ∈ {open, replied}` (lowercased).
- `assigned` — `agent` truthy, sorted by `modified||created` desc, top 25.
- `sla` (at risk) — `agreement_status==="Failed"` OR (not resolved/closed AND
  `response_by` or `resolution_by` ≤ now+24h).
- `feedback` — `Number(feedback_rating) > 0`.

Sort keys: `created` (date), `priority` (urgent/high/medium/low order), `sla`
(`response_by` asc), `status` (string). Group keys: `status, priority, team`.

## A4. `GET /helpdesk/tickets/{name}`
Consumer: `tickets/[name]/page.tsx` (full detail + conversation + SLA sidebar).

Request: path `name` (URL-encoded ticket id).

Response:
```jsonc
{
  "ticket": {
    "name": "string",
    "subject": "string",            // header title
    "description": "HTML string",   // seeds the first "Replies" bubble (as received, from contact/raised_by/customer)
    "status": "string",             // Chip; status <select> value; done-regex for SLA
    "priority": "string",           // Chip; priority <select> value
    "ticket_type": "string|null",   // type <select> value
    "team": "string|null",          // "Team" prop row; assign dropdown default
    "agent": "string|null",         // "Assignee" prop row + avatar; assign default
    "customer": "string|null",      // "Customer" prop row
    "contact": "string|null",       // "Contact" prop row (fallback raised_by)
    "raised_by": "string|null",     // fallback for contact / first-bubble sender
    "response_by": "ISO ts|null",   // "First response by" row + SlaBadge
    "resolution_by": "ISO ts|null", // "Resolution by" row + SlaBadge
    "feedback_rating": 0.8,         // CSAT row: ★ × round(rating*5), "/5" (0–1 scale)
    "created": "ISO ts",            // "Created" row (fallback field `creation`)
    "creation": "ISO ts",           // fallback for created
    "severity": "string|null",      // red header badge (with cve_id)
    "cve_id": "string|null",        // red header badge; "Related finding" link
    "finding_id": "number|null",    // "Related finding" link → /vulnerabilities/{id}
    "sla": {                        // nested block (see below)
      "policy": "string|null",          // shown next to "SLA ·"
      "agreement_status": "string|null",// badge text; "Failed"→red
      "breached": true,                 // badge colour
      "first_responded_on": "ISO ts|null", // marks first-response SlaBadge done
      "resolution_date": "ISO ts|null"     // marks resolution SlaBadge done
      // response_by/resolution_by/on_hold_since/*_failed_by also returned, unread here
    }
  },
  "conversation": [ {               // merged, sorted asc by date
    "type": "received|sent|comment|note|activity", // routing (see TimelineItem)
    "sender": "string",             // avatar + name
    "content": "HTML string",       // rendered via dangerouslySetInnerHTML
    "date": "ISO ts"                // timeAgo() + title
  } ]
}
```
Conversation routing (`tickets/[name]` + `_ui.TimelineItem`):
- `type` matching `/activity/i` → compact system line (Activity tab).
- `type` matching `/comment|note/i` → amber "Internal note" bubble (Comments tab).
- anything else → reply bubble; `/sent/i` = indigo "Reply", else grey "Customer".
- The UI **prepends** `ticket.description` as a synthetic first received reply, so
  the native backend does NOT need a conversation row for the opening message.

Not-found contract: proxy returns `{ "ticket": { "name", "not_found": true },
"conversation": [] }`. The page treats a falsy/empty `ticket` → "Ticket not
found". Native backend can return `{ "ticket": null, "conversation": [] }`.

COMPUTE: `sla.breached` (= status Failed), and the done-flags are derived client
side from `first_responded_on`/`resolution_date` presence — so the native backend
only needs to supply those timestamps honestly.

## A5. `GET /helpdesk/meta`
Consumers: `tickets/[name]/page.tsx` (status/priority/type pickers).

Request: none.

Response — all read:
```jsonc
{
  "priorities": ["Urgent","High",...],   // priority <select> options
  "ticket_types": ["Incident",...],      // type <select> options
  "statuses": [ { "name":"Open", "category":"Open" } ], // status <select>; only `name` is read
  "feedback_options": [ { "label":"Happy", "rating":5 } ] // returned; NOT read by any page
}
```
If `statuses` is empty the detail page falls back to a hardcoded Resolve button,
so an empty list is a valid (degraded) response.

## A6. `GET /helpdesk/agents`
Consumers: `agents/page.tsx`, `tickets/page.tsx` (bulk-assign dropdown),
`tickets/[name]` (assign dropdown).

Response:
```jsonc
{ "agents": [ {
    "name": "string",       // key; fallback label
    "agent_name": "string", // display name
    "email": "string",      // assign <option value>; "mine" match uses this
    "availability": "Active|Away|Unavailable", // AVAIL chip (agents page)
    "is_active": true        // "Active/Inactive" dot (agents page)
} ] }
```

## A7. `GET /helpdesk/teams`
Consumers: `teams/page.tsx`, `tickets/[name]` (team assign dropdown).

Response:
```jsonc
{ "teams": [ {
    "name": "string",            // key; <option value> for team assign; fallback label
    "team_name": "string",       // display name
    "assignment_rule": "string|null", // indigo badge; drives config.auto_assignment
    "members": [ { "name":"user@x", "full_name":"string" } ] // avatars + "N members" count
} ] }
```
`members[].full_name` preferred for avatar, else `name`. Proxy currently only
sets `name` — native backend should include `full_name` for nicer avatars (not
required).

## A8. `GET /helpdesk/customers`
Consumer: `customers/page.tsx`.
```jsonc
{ "customers": [ {
    "name": "string",            // key; fallback label; search
    "customer_name": "string",   // display; search
    "domain": "string|null",     // sky chip; search
    "contacts_count": 0          // "Contacts" column (proxy hardcodes 0)
} ] }
```
FLAG: `contacts_count` is always `0` in the proxy. Native backend should compute
the real count (or keep 0 — UI tolerates it).

## A9. `GET /helpdesk/contacts`
Consumer: `contacts/page.tsx`.
```jsonc
{ "contacts": [ {
    "name": "string",         // key; name fallback
    "first_name": "string|null", // name = "first last"
    "last_name": "string|null",
    "email_id": "string|null",   // "Email" col; search
    "phone": "string|null",      // "Phone" col; search
    "company_name": "string|null"// "Company" col; search
} ] }
```

## A10. `GET /helpdesk/articles`
Consumer: `kb/page.tsx` (grouped by category).
```jsonc
{
  "articles": [ {
    "name": "string",        // key; title fallback
    "title": "string",       // card title; search
    "category": "string",    // group heading; search (proxy defaults "Uncategorised")
    "status": "string",      // Chip (defaults "Draft" in UI)
    "author": "string|null", // "{author} · updated …"; search
    "modified": "ISO ts",    // timeAgo()
    "views": 0,              // eye count
    "helpful": 0,            // 👍 count (shown only if helpful>0 || not_helpful>0)
    "not_helpful": 0         // 👎 count
  } ],
  "categories": [ { "name":"string", "count":0 } ] // returned; NOT read (UI regroups client-side)
}
```
COMPUTE: `helpful`/`not_helpful` aggregate feedback per article; `views` counter.

## A11. `GET /helpdesk/canned-responses`
Consumers: `canned/page.tsx`, `tickets/[name]` (insert-canned-reply dropdown).
```jsonc
{ "responses": [ {
    "name": "string",     // key; <option value>; title fallback
    "title": "string",    // card title / option label; search
    "owner": "string|null"// avatar + name (canned page); search
    // body: the ticket composer reads `message` OR `title` to insert; the canned
    // LIST page reads `response` OR `message` for preview. Neither is returned by
    // this endpoint today (it returns only name/title/owner), so the insert
    // inserts the TITLE. Native backend SHOULD add `message` (HTML body) here.
} ] }
```
FLAG: body text (`message`) is NOT returned by this endpoint in the proxy, so
"insert canned reply" currently inserts the title. Full body lives only in
`/helpdesk/saved-replies`. Native backend should return `message` here too.

## A12. `POST /helpdesk/tickets/{name}/status`
Consumers: `tickets/page.tsx` (bulk Resolve), `tickets/[name]` (Resolve/Close
fallback buttons).

Request body: `{ "status": "Resolved" }`
Response read: none (UI only checks the promise didn't throw, then `reload()`).
Return `{ "ok": true }` (or any 2xx). On failure throw/non-2xx so the catch fires.

## A13. `POST /helpdesk/tickets/{name}/reply`
Consumer: `tickets/[name]` (Send reply / Add internal note).

Request body:
```jsonc
{ "content": "HTML",   // FE sends both; proxy uses content||body
  "body": "HTML",
  "internal": false,   // true → internal comment/note; false → public reply
  "cc": "a@x,b@y",     // optional, public reply only (comma-sep)
  "bcc": "..." }        // optional
```
Response read: none (check-not-thrown → `reload()`). Return `{ "ok": true }`.
Behaviour: `internal:true` must create a comment/note row; `false` a public
reply (the native backend owns delivery). Both must then show up in the next
`GET /helpdesk/tickets/{name}` conversation.

## A14. `POST /helpdesk/tickets/{name}/update`
Consumer: `tickets/[name]` (status / priority / type <select> changes).

Request body (any subset, only non-null sent):
`{ "priority"?, "ticket_type"?, "status"?, "agent_group"? }`
Response read: none → `reload()`. Return `{ "ok": true }`.

## A15. `POST /helpdesk/tickets/{name}/assign`
Consumers: `tickets/page.tsx` (bulk assign), `tickets/[name]` (assign popover).

Request body: `{ "agent": "user@x"|null, "team": "Team Name"|null }`
- agent = HD agent email (`agents[].email||name`); null clears.
- team = team `name`; null clears.
Response read: none → `reload()`. Return `{ "ok": true }`.

## A16. `GET /helpdesk/saved-replies`
Consumer: `settings/page.tsx`.
```jsonc
{ "saved_replies": [ {
    "name": "string",      // key; edit/delete id (URL-encoded)
    "title": "string",     // list title; edit form
    "message": "HTML",     // preview (stripped) + edit form body
    "owner": "string|null",// (returned; not shown on settings page)
    "modified": "ISO ts"   // (returned; not shown)
} ] }
```

## A17. `POST /helpdesk/saved-replies`
Consumer: `settings/page.tsx` (create).
Request body: `{ "title": "string", "message": "HTML" }`
Response read: none → `reload()`.

## A18. `PUT /helpdesk/saved-replies/{name}`
Consumer: `settings/page.tsx` (edit).
Request body: `{ "title": "string", "message": "HTML" }`
Response read: none → `reload()`. Proxy 404s on cross-tenant id.

## A19. `DELETE /helpdesk/saved-replies/{name}`
Consumer: `settings/page.tsx` (delete).
Request: path only. Response read: none → `reload()`.

## A20. `GET /helpdesk/config`
Consumer: `settings/page.tsx` (read-only "How your Help Desk is configured").
```jsonc
{
  "sla": {
    "policy": "string|null",   // "SLA targets · {policy}"
    "priorities": [ { "priority":"High", "response":"4h", "resolution":"2d" } ],
                               // table; response/resolution are PRE-FORMATTED strings
    "service_days": [ { "day":"Monday", "start":"09:00:00", "end":"17:00:00" } ],
                               // business hours list (UI slices to HH:MM)
    "holiday_list": "string|null" // "Holiday calendar: {x}"
  },
  "auto_assignment": true,     // green/grey "Active/Not active" pill
  "managed": true              // (returned; not read — label is hardcoded in UI)
}
```
COMPUTE: `sla.priorities[].response/resolution` are human strings (e.g. `4h`,
`2d`) — the native backend formats durations (see `_fmt_duration`). `service_days`
times are `HH:MM:SS`. `auto_assignment` = any team has an assignment rule.

## A21. `GET /helpdesk/ping` (NOT called by the FE)
Proxy health probe. No page consumes it. Native backend may skip or keep for ops.

---

# B. Remediation / ITSM endpoints (`/vuln-management/*`) — OUT OF SCOPE, documented for completeness

These power the **legacy remediation board** (`helpdesk/page.tsx`) and its detail
(`helpdesk/[id]/page.tsx`), plus the finding→ticket creation on the vulnerability
pages. They are a separate backend and are NOT part of the native Help Desk
reimplementation, but the native engine must coexist with them.

## B1. `GET /vuln-management/helpdesk/tickets`
Consumers: `helpdesk/page.tsx` (remediation board), `helpdesk/[id]/page.tsx`
(finds a ticket in the list by `finding_id`/`ticket_id`).
```jsonc
{
  "tickets": [ {
    "ticket_id": "string|null",   // link id (fallback #finding_id)
    "status": "new|in_progress|on_hold|resolved|closed|cancelled", // STATUS_META key
    "raw_status": "string|null",  // (returned; not read)
    "finding_id": 0,              // link + /vulnerabilities/{id}
    "vuln_id": "string|null",     // "Finding" row; title fallback; search
    "title": "string|null",       // subject; search
    "severity": "string|null",    // SEV chip; search(no)
    "cve_id": "string|null",      // CVE col/badge; search
    "affected_host": "string|null", // Host col; search
    "connection": "string|null",  // detail "Engine / connection" row
    "pushed_at": "ISO ts|null",   // "Opened" timeAgo / toLocaleString
    "last_synced_at": "ISO ts|null", // detail "Last synced"
    "resolved_at": "ISO ts|null", // (returned; not read)
    "push_error": "string|null"   // (returned; not read)
  } ],
  "summary": { "new":0,"in_progress":0,"on_hold":0,"resolved":0,"closed":0,"cancelled":0 },
                                  // board filter-tab counts (READ)
  "total": 0                      // (returned; not read)
}
```

## B2. `POST /vuln-management/helpdesk/tickets/{id}/reply`  ⚠ MISSING ON BACKEND
`helpdesk/[id]/page.tsx` posts `{ body, internal }` here, but **no such route
exists** in `itsm.py`. The call always throws and the UI shows a graceful
"saved locally" note. If the native board detail should actually post, this
endpoint must be created; otherwise it is dead. FLAG for the native effort.

## B3. `POST /vuln-management/vulnerabilities/{id}/push-to-itsm`
Finding → ticket. Query: `?connection_id=<n>` optional (resolved server-side if
omitted). No body. Called from `vulnerabilities/[id]/_components/ItsmPanel.tsx`
(`api.ts` `vulnApi` ~line 2482). Returns `itsm_service.push_finding()` result;
UI only invalidates its query on success.

## B4. `POST /vuln-management/vulnerabilities/bulk-push-to-itsm`
Body: `{ "vuln_ids": number[], "connection_id"?: number }`.
Returns `{ requested, matched, created, skipped, failed, errors:[{vuln_id,error}] }`.

## B5. `GET /vuln-management/vulnerabilities/{id}/itsm-tickets`
Per-finding ticket links. Returns `{ tickets: [{ connection_id,
external_ticket_id, normalised_status, pushed_at, resolved_at, plan_advanced_at,
push_error }] }`.

## B6. `POST /vuln-management/itsm/connections/{connection_id}/sync-statuses`
Pulls ticket status back. Returns a counts object.

---

# C. External dependencies the Help Desk pages also call (not Help Desk endpoints)

- `GET /auth/me` — `home/page.tsx` reads `user.{email, display_name, username}`
  to greet the agent and compute "mine" (tickets where `agent==email`).
- `GET /vuln-management/vulnerabilities/{id}` — `helpdesk/[id]/page.tsx` reads
  `{ description, recommendation|ai_recommendation, severity, cve_id, cvss_score,
  affected_host, title }` to render the finding body/sidebar.

---

# D. What the native backend must COMPUTE (not just store)

1. **dashboard-analytics** — SLA %, avg first-response (hrs), avg resolution
   (days), feedback mean, 30-day created/resolved trend, 4 category breakdowns.
2. **ticket SLA block** — `response_by`/`resolution_by` due timestamps,
   `agreement_status` verdict, `breached`, `first_responded_on`,
   `resolution_date` (the UI derives badge state from these).
3. **conversation merge** — replies + internal notes + activity into one list
   with `{type, sender, content, date}`, sorted asc by date, using the `type`
   vocabulary in §A4.
4. **config** — pre-format SLA durations to human strings (`4h`, `2d`), expose
   service days as `HH:MM:SS`, `auto_assignment` boolean.
5. **articles** — per-article `views`, `helpful`, `not_helpful` aggregates.
6. **customers.contacts_count** — currently always 0 (proxy); compute it.
7. **canned `message` body** — must be returned by `/helpdesk/canned-responses`
   (not just `/saved-replies`) for "insert canned reply" to insert real text.

# E. Response-robustness contract

Every page defends against missing data: lists default to `[]`, scalars to `—`.
A native backend that returns `200` + the documented keys (even empty) keeps the
UI fully functional. **Do not return 4xx for "empty"** — `useHd` turns any
rejection into the generic "engine may not be connected yet" banner.
