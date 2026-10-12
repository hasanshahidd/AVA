# Helpdesk Engine Logic Spec

Reverse-engineered from the forked Frappe Helpdesk Python app so it can be
reimplemented faithfully in native FastAPI/SQLAlchemy. **Read this against the
source** — every rule cites `file:function`. Source root:
`helpdesk-app/helpdesk/helpdesk/` (branch `feat/helpdesk-fork-rebrand`).
Paths below are relative to that root unless noted.

A note on the framework substrate we must replace: Frappe gives these controllers
`before_validate` → `validate` → `before_save` → (insert: `before_insert` /
`after_insert`) → `on_update` document hooks, a permlevel field-access system, a
`_assign` JSON column maintained by core `frappe.desk.form.assign_to`, a core
`Assignment Rule` engine, a core `Communication` doctype, a core `Comment`
doctype, and `track_changes` → `Version` rows. A native port owns all of these;
the relevant behaviors are spelled out so you don't have to read Frappe itself.

---

## 0. Ticket core fields & lifecycle hook order

`HD Ticket` (`doctype/hd_ticket/hd_ticket.py`). Numeric autoname `.####`
(`hd_ticket.json: autoname`, `naming_rule: Expression`) → sequential integer id;
`autoname()` is a no-op passthrough. `track_changes: 1` → every field change writes
a core `Version` row (this is the real activity feed; see §4).

Server-maintained datetime/metric fields (from `consts.py: SERVER_COMPUTED_FIELDS`
plus related): `service_level_agreement_creation` (SLA clock start), `response_by`,
`resolution_by`, `first_responded_on`, `resolution_date`, `on_hold_since`,
`total_hold_time`, `first_response_time`, `resolution_time`,
`first_response_failed_by`, `resolution_failed_by`, `status_category`, `sla`,
`agreement_status`, `last_customer_response`, `last_agent_response`,
`raised_outside_working_hours`, `key` (uuid for guest feedback links).

**Hook order on every save** (`hd_ticket.py`):
- `before_insert`: `generate_key()` (uuid4), `apply_ticket_insert_rules()`.
- `before_validate`: `set_ticket_type` → `set_raised_by` → `set_priority` →
  `set_first_responded_on` → `set_feedback_values` → `set_default_status` →
  `set_status_category` → `set_sla` → portal/contact/customer setters.
- `validate`: `validate_feedback`.
- `before_save`: `set_resolution_date` → `apply_sla` → `handle_email_feedback`;
  on insert also stamps `raised_outside_working_hours`.
- `after_insert`: telemetry, first-ticket tag, create the opening `Communication`
  from `description`, send acknowledgement email.
- `on_update`: reopen notification, `remove_assignment_if_not_in_team`,
  publish realtime update, telemetry.

Order matters: `set_sla` picks the policy and `set_first_responded_on` /
`set_resolution_date` stamp the timestamps **before** `apply_sla` runs the SLA math
in `before_save`.

---

## 1. SLA (Service Level Agreement)

Doctypes: `HD Service Level Agreement` (`doctype/hd_service_level_agreement/`),
child `HD Service Level Priority` (per-priority targets), child workday rows in
`support_and_resolution` (a `HD Service Day`: `workday` Select, `start_time` Time,
`end_time` Time), `HD Service Holiday List` → `HD Service Holiday` rows
(`holiday_date`).

SLA header fields (`hd_service_level_agreement.json`): `enabled`, `default_sla`,
`rank` (int, lower = higher precedence; `0`/unranked sorts last),
`start_date`/`end_date` (validity window), `condition` (Python expr evaluated against
the ticket), `condition_json` (UI mirror), `apply_sla_for_resolution` (bool — if off,
only first-response is tracked), `holiday_list`, `default_priority`,
`default_ticket_status`, `ticket_reopen_status`, and the `priorities` +
`support_and_resolution` child tables.

### 1.1 How a ticket gets its SLA — `hd_ticket.set_sla` → `hd_service_level_agreement/utils.get_sla`

Runs in `before_validate` on **every** save (so SLA can attach/detach as fields
change). `get_sla(ticket)` query (`utils.py:12`):
1. Candidates = SLAs where `enabled` is true AND now is inside
   `[start_date, end_date]` (null bound = open).
2. If the ticket has a priority, inner-join `HD Service Level Priority` and require
   a row matching that priority — **an SLA only applies if it defines the ticket's
   priority.**
3. Order: `default_sla` ASC (non-default first, Default considered **last**), then
   ranked-before-unranked (`rank == 0` sorts after), then `rank` ASC, then
   `creation` ASC.
4. Walk candidates in order: a `default_sla` row wins immediately; a row with a
   blank `condition` is skipped (not a match); otherwise `frappe.safe_eval(condition,
   context)` against the serialized ticket (`utils.get_context`) — first truthy wins.
5. No match → `None`.

`set_sla`: if found, `self.sla = sla.name`; else `clear_sla_fields()`
(`hd_ticket.py:977`) — nulls `sla`, `response_by`, `resolution_by`; nulls
`on_hold_since` **unless** currently Paused; nulls `agreement_status` **unless** it
is already `Failed` (a failure is sticky). The clock start
(`service_level_agreement_creation`) is deliberately **kept** so toggling a condition
off/on buys no extra time.

### 1.2 Applying the SLA — `hd_ticket.apply_sla` → `HDServiceLevelAgreement.apply`

`apply` (`hd_service_level_agreement.py:189`) runs in `before_save` and does, in order:
1. `set_default_priority`: `doc.priority = doc.priority or self.default_priority`.
2. `start_clock`: stamp `service_level_agreement_creation = now` **once** (if unset).
   This is the anchor for all target math — it is when the SLA attached, which may be
   long after the ticket was raised.
3. `handle_doc_status`: only when `is_valid_status_transition()` is true (status
   actually changed; see §3.1) — computes first-response time, hold time, resolution
   time.
4. `handle_targets`: (re)compute `response_by` and `resolution_by`.
5. `handle_agreement_status`: set the `agreement_status` label.

### 1.3 response_by / resolution_by — `calc_time` (`hd_service_level_agreement.py:326`)

Both are deadlines computed by walking business time forward from
`service_level_agreement_creation` by the priority's target seconds.

- `response_by  = calc_time(start, priority, "response_time")`
- `resolution_by = calc_time(start, priority, "resolution_time", hold_time=total_hold_time)`
  — **hold time is added to the resolution budget** so a paused ticket's deadline
  slides out by exactly the time it was on hold.

`calc_time` algorithm (business-hours walk, not wall-clock):
- Inputs: target seconds from the matching `HD Service Level Priority` row; holiday
  dates (`get_holidays`); workdays dict keyed by weekday name (`get_workdays`, from
  `support_and_resolution`).
- For resolution, `remaining += hold_time` first.
- Loop while `remaining_target_time > 0`, cursor `result` starting at `start`:
  - If the cursor's date is a holiday or the weekday has no workday row → jump to
    next day's midnight, continue.
  - Compute `current_time_in_seconds` = seconds since midnight of the cursor.
    `start_time = max(workday.start_time, current_time_in_seconds)` (if cursor is
    before shift start, wait for start; if mid-shift, start now).
    `till_start_time = max(start_time - current_time_in_seconds, 0)`.
    `end_time = max(workday.end_time, current_time_in_seconds)`.
    `time_left = max(end_time - start_time, 0)`; if zero (already past shift end)
    → jump to next day.
  - `time_taken = min(remaining, time_left)`; `remaining -= time_taken`;
    advance cursor by `till_start_time + time_taken` seconds.
- Returns the datetime when the budget is exhausted = the deadline.

Note `end_time = max(workday.end_time, current_time_in_seconds)` means if the cursor
is already past shift end, `time_left` is 0 and the day is skipped — correct, but
reimplement the `max`/skip exactly; don't "fix" it to clamp.

### 1.4 first_responded_on, first_response_time, resolution_date, resolution_time

- **`first_responded_on`** set two ways:
  - `hd_ticket.set_first_responded_on` (`:367`): on save (not new, not already set),
    if transitioning Open→Resolved category **or** into Paused, stamp `now`. (So
    resolving/pausing without an explicit agent reply still records a first response.)
  - `hd_ticket.on_communication_update` (`:1058`): when an **outgoing** (`Sent`,
    non-"Automated Message") Communication lands, `first_responded_on =
    first_responded_on or now`, and `last_agent_response = now`.
- **`first_response_time`** (business-seconds taken) = `calc_elapsed_time(
  service_level_agreement_creation, first_responded_on)`
  (`set_first_response_time`, `:212`). If `first_responded_on > response_by`,
  also set `first_response_failed_by = calc_elapsed_time(response_by,
  first_responded_on)`.
- **`resolution_date`** (wall-clock stamp) — `hd_ticket.set_resolution_date`
  (`:952`), runs for every ticket with or without an SLA. On a valid status
  transition: if the new `status_category != "Resolved"`, null `resolution_date`
  and `resolution_time`; if it is Resolved and not already stamped (or the category
  changed), `resolution_date = now`.
- **`resolution_time`** (effective business-seconds) — `set_resolution_time`
  (`:225`): `time_took = calc_elapsed_time(sla_creation, resolution_date)`;
  `resolution_time = max(time_took - total_hold_time, 0)`. If
  `resolution_date > resolution_by`, `resolution_failed_by =
  calc_elapsed_time(resolution_by, resolution_date)`.

`calc_elapsed_time` (`:422`) is the inverse of `calc_time`: counts working seconds
between two datetimes, skipping holidays/non-work-days and clamping each day to its
workday `[start_time, end_time]` window. Reimplement per the day-by-day loop:
first day clamps lower bound to the start datetime, last day clamps upper bound to
the end datetime, and `convert_to_seconds` (`utils.py:55`) is seconds-since-midnight
of a datetime.

### 1.5 agreement_status — `handle_agreement_status` (`:295`)

Evaluated in priority order (first true wins):
1. **`Failed`** — if `is_first_response_failed` OR `is_resolution_failed`.
   - `is_first_response_failed` (`:309`): no response yet →
     `response_by < get_active_ticket_time(doc)`; else `response_by <
     first_responded_on`.
   - `is_resolution_failed` (`:314`): only when `apply_sla_for_resolution` and
     `resolution_by` set. No resolution yet → `resolution_by <
     get_active_ticket_time(doc)`; else `resolution_by < resolution_date`.
   - `get_active_ticket_time` (`:321`): `on_hold_since` if paused, else `now` — an
     on-hold ticket is measured against when it paused, not wall-clock now.
2. **`Paused`** — elif `on_hold_since` set.
3. **`First Response Due`** — elif no `first_responded_on`.
4. **`Resolution Due`** — elif `apply_sla_for_resolution` and no `resolution_date`.
5. **`Fulfilled`** — else.

**Status values are exactly:** `Failed`, `Paused`, `First Response Due`,
`Resolution Due`, `Fulfilled` (plus transient `None` when no SLA attaches and no prior
failure). Once `Failed`, `clear_sla_fields` keeps it (sticky).

Background refresh: `update_sla_status_in_ticket` (`hd_ticket.py:1526`, scheduler
`hourly_long`) re-runs `handle_agreement_status` on every **open-category** SLA
ticket and writes `agreement_status` directly (so "Due" flips to "Failed" when a
deadline passes even with no user activity).

### 1.6 On-hold / pause — `set_hold_time` (`hd_service_level_agreement.py:242`)

"Paused" is driven by **status category**, not a flag. A status whose
`HD Ticket Status.category == "Paused"` (seed: `Replied`) pauses the clock.
On a valid status transition:
- Determine `was_paused`/`is_paused` by whether prev/next status is in the
  Paused-category set.
- `paused_since = on_hold_since`; if none and the ticket is **not** currently
  Resolved, fall back to the old doc's `resolution_date` (so time spent resolved
  counts as hold **only when the ticket is reopened**).
- **Entering pause** (`is_paused and not was_paused`): move `response_by` to
  `resolution_by` if a first response exists (else null), null
  `resolution_date`/`resolution_by`/`resolution_time`, set `on_hold_since = now`.
- **Leaving pause** (`not is_paused and was_paused`): `on_hold_since = None`.
- If still paused or no `paused_since` → return (don't accrue yet).
- Otherwise (a resume): null `on_hold_since`, add
  `max(calc_elapsed_time(paused_since, now), 0)` business-seconds to
  `total_hold_time`.

`total_hold_time` then feeds `resolution_by` (budget slides out, §1.3) and
`resolution_time` (subtracted, §1.4).

---

## 2. Assignment

Helpdesk delegates round-robin / load-balancing to Frappe's **core `Assignment
Rule`** engine and the core `_assign` JSON column; it only *configures* the rules
and does cleanup. A native port must reimplement the core engine's selection too —
summarized here.

### 2.1 Rule provisioning — `HDTeam` (`doctype/hd_team/hd_team.py`)

Each `HD Team` owns one `Assignment Rule` created in `after_insert`
(`create_assignment_rule`, `:63`):
- `document_type = "HD Ticket"`, `priority = 1`.
- `assign_condition = "status == 'Open' and agent_group == '<team>'"` (+ JSON
  mirror) — **auto-assign fires only for Open tickets whose `agent_group` is this
  team.**
- `unassign_condition = "agent_group != '<team>'"` — reassigning a ticket to another
  team clears this team's assignment.
- `assignment_days` = all 7 days.
- Users synced from `HD Team.users`: into `users` child (round-robin / load-balance)
  **or**, when the rule's `rule == "Weighted Distribution"`, into `weighted_users`
  with per-user `weight` (default 1, existing weights preserved).
- `disabled` mirrors the team's `disabled`.

`on_update` re-syncs users and disabled flag into the rule. `on_trash` deletes the
rule. `after_rename` rewrites both conditions with the new team name.

There is also a **base** "Support Rotation" rule
(`hd_settings.create_base_support_rotation`, `:64`): `document_type HD Ticket`,
`assign_condition "status == 'Open'"`, `priority 0`, **disabled by default** (enabled
once agents exist). Stored on `HD Settings.base_support_rotation`.

### 2.2 Core selection logic (to reimplement)

The core `Assignment Rule` has a `rule` field with three strategies:
- **Round Robin** — cycle through `users` in order, tracking the last-assigned user
  so each new matching doc goes to the next user (wraps around).
- **Load Balancing** — pick the user in `users` with the fewest **currently open
  assignments** (open ToDo rows) for that rule's document type.
- **Weighted Distribution** — distribute across `weighted_users` proportional to
  `weight`.

When a doc matches `assign_condition`, core assigns via a `ToDo` + updates the
doc's `_assign` JSON list; when it matches `unassign_condition`, core clears the
assignment. Rules fire on the document's `after_insert` and `on_update` (so a ticket
created Open with a team auto-assigns immediately; a ticket that later becomes Open
or gets a team assigns then). `assignment_days` gates which weekdays a rule may
assign on.

### 2.3 What sets `agent_group` / `_assign`

- `agent_group` (the team) is set by the client/API or template; nothing in the
  controller auto-derives it. It is the join key for both the team SLA conditions and
  the team assignment rule.
- `_assign` is the core JSON list of assignee user ids, maintained by
  `frappe.desk.form.assign_to.add/clear` and by the Assignment Rule engine.
- Manual assignment: `HDTicket.assign_agent(agent)` (`:477`, agent-only) →
  `assign_to.add(...)` (notifies/emails the agent). `get_assigned_agent` /
  `get_assigned_agents` read `_assign` (falling back to a ToDo lookup) and filter to
  rows that are actual `HD Agent`s.
- Cleanup: `remove_assignment_if_not_in_team` (`:422`, in `on_update`) — when
  `agent_group` changes and the ticket is Open, if the current assignee is **not** a
  member of the new team and the new team's rule has users, clear **all**
  assignments (so the rule can reassign to someone on the right team).

---

## 3. Ticket lifecycle

### 3.1 Statuses, categories, transitions

`HD Ticket Status` is a **user-editable master** (`doctype/hd_ticket_status/`), not a
fixed enum. Each status has a `category` ∈ {`Open`, `Paused`, `Resolved`} — only
three categories exist (`hd_ticket_status.json` options). `status_category` on the
ticket is derived from the status (`set_status_category`, `hd_ticket.py:1015`).

Seed statuses (`setup/install.py:add_default_status`):

| status   | category | note |
|----------|----------|------|
| Open     | Open     | order 1, red; SLA default + reopen status |
| Replied  | Paused   | order 2, blue; customer label "Awaiting Response"; pauses SLA |
| Resolved | Resolved | order 3, green |
| Closed   | Resolved | order 4, gray |

`HD Settings.default_ticket_status = "Open"`, `ticket_reopen_status = "Open"`.
An SLA may override both per-policy (`default_ticket_status` / `ticket_reopen_status`
on the SLA, read by `HDTicket.default_open_status` / `.ticket_reopen_status`,
`:50`/`:58`).

Status-master invariants (`hd_ticket_status.py`): `Closed` cannot be renamed; only
`color`/`order` of `Closed` are editable; at least one enabled status must remain per
category; a status referenced as an SLA/Settings default or reopen status cannot be
disabled.

**There is no explicit transition state machine** — any status→status change is
allowed at the data layer. The only guard is `is_valid_status_transition`
(`hd_ticket.py:943`): returns false if new/unchanged or new-doc; and **closing an
already-`Resolved`-category ticket is NOT a "valid transition"** for SLA purposes
(wrapping up an outcome, not a new one), so moving Resolved→Closed does **not**
re-stamp resolution timestamps. This gate drives whether SLA recompute + resolution
stamping happen.

### 3.2 "Resolve" / "Close"

Neither is a special method — both are status changes to a status in the `Resolved`
category. Effects flow from the hooks:
- Moving into Resolved category (from Open) → `set_resolution_date` stamps
  `resolution_date = now`; `apply_sla` (if valid transition) computes
  `resolution_time`; `set_first_responded_on` stamps a first response if none;
  `handle_agreement_status` → `Fulfilled` (or `Failed`). Telemetry `ticket_resolved`.
- Moving **out** of Resolved category → `resolution_date`/`resolution_time` nulled.
- Resolved→Closed is not a "valid transition" (above): resolution stamps are
  preserved, not recomputed.
- Customer (non-agent) via portal may set status only to **Closed** (not Resolved —
  that's the agent's call) or trigger a reply-reopen; see
  `customer_edit_controller.customer_writable_after_create` (`:82`).

### 3.3 Reopen

Two paths, both set status to the reopen status (`ticket_reopen_status`, default
`Open`):
- **Customer replies via portal** — `create_communication_via_contact` (`:803`):
  unless it's a brand-new ticket, sets `status = ticket_reopen_status`, flags
  `customer_reply_reopen` (lets the non-agent status change through the edit guard),
  saves.
- **Inbound email reply** — `on_communication_update` (`:1058`) on a `Received`
  Communication: if an agent has already replied → `status = ticket_reopen_status`
  and record `flags.reopened_by = sender`; if no agent reply yet → `status =
  default_open_status`. Also stamps `last_customer_response = now`.
- `on_update` (`:232`): when `status_category` goes from non-Open back to Open,
  notify the assigned agents via `notify_ticket_reopened(name, agents, reopened_by)`.
- Auto-close reversal is not a thing; auto-close is one-directional (§5).

### 3.4 Feedback / CSAT

- `HD Ticket Feedback Option` master (`doctype/hd_ticket_feedback_option/`): each has
  a `rating` ∈ {0.2, 0.4, 0.6, 0.8, 1.0} (validated; at least one enabled option per
  rating value must remain). Ticket fields: `feedback` (link to the option),
  `feedback_rating` (the numeric rating, copied from the option by
  `set_feedback_values`, `hd_ticket.py:385`), `feedback_extra` (free text).
- `validate_feedback` (`:402`): if `HD Settings.is_feedback_mandatory` and the ticket
  is Resolved-category and an agent has replied and the actor is a non-agent and no
  rating yet → throw "Ticket must be resolved with a feedback". (Agents are exempt.)
- Customer can always write `feedback` / `feedback_extra` / `status_category`
  (`consts.CUSTOMER_ALWAYS_WRITABLE_FIELDS`).
- **Email CSAT flow** — `handle_email_feedback` (`hd_ticket.py:128`, in
  `before_save`): on a status change (not new, not via portal, not already rated,
  has a `key`), if `HD Settings.enable_email_ticket_feedback` and the new status
  matches `send_email_feedback_on_status` (or that's blank and status is `Closed`),
  email the raiser a link `/ticket-feedback/new?key=<uuid>`. The guest feedback page
  is authenticated by the ticket's `key` uuid.

---

## 4. Conversation model — three distinct record types

A ticket's thread is built from **core** doctypes, not helpdesk ones. The SPA renders
it via `useActivityTimeline("HD Ticket", id, SHARED_VISIBLE_TYPES)`
(`desk/.../TicketAgent.vue:103`), which reads Frappe `docinfo` (versions + comments +
communications). The API also exposes `get_communications` directly
(`doctype/hd_ticket/api.py:83`).

### 4.1 Replies — core `Communication` (type `Communication`)

Customer-facing messages (email in/out). Keyed by `reference_doctype="HD Ticket"`,
`reference_name=<id>`, `sent_or_received` ∈ {`Sent` (agent), `Received` (customer)}.
- **Agent reply** — `HDTicket.reply_via_agent` (`:662`, agent-only): builds a
  `Communication` (`communication_type="Communication"`, medium `Email` unless
  `skip_email_workflow`, `sent_or_received="Sent"`, `status="Linked"`), threads it via
  `in_reply_to = _last_threadable_communication()` (newest comm with a `message_id`),
  inserts it, optionally queues the outbound email (only then assigns `message_id`,
  so a reply that failed to send can't become a parent). Attachments are linked to
  both the Communication and the ticket.
- **Customer reply** — `create_communication_via_contact` (`:803`): inserts a
  `Received` Communication, reopens the ticket (§3.3).
- **Opening message** — `after_insert` turns the ticket `description` into the first
  `Received` Communication (`:186`).
- `on_communication_update` (`:1058`) is the single reconciliation point: reopen on
  received, stamp first/last response on sent, redirect to merge target if merged,
  backfill `description` on blank email tickets. Automated-Message communications are
  ignored for first-response stamping.

### 4.2 Internal comments — core `Comment` (comment_type `Comment`)

Agent-only private notes. `HDTicket.new_comment(content, attachments)` (`:611`,
agent-only) → `self.add_comment("Comment", content)` (core), then
`claim_comment_files` (`:626`) moves uploaded files off the ticket (customer-readable)
onto the Comment (agent-only) so embedded images inherit the comment's visibility.
Comment permission is overridden by `helpdesk.extends.comment.has_permission`
(hooks `has_permission["Comment"]`).

`HD Ticket Comment` (`doctype/hd_ticket_comment/hd_ticket_comment.py`) is **dead** —
"Superseded by core Comment. The table survives the migration so the old rows stay
readable; nothing writes it anymore." A port can read-migrate old rows but should
model new internal comments on core Comment.

### 4.3 Activity — core `Version` (+ informational Comments)

`HD Ticket Activity` (`doctype/hd_ticket_activity/hd_ticket_activity.py`) is an empty
`pass` controller and **nothing in the backend writes it** (confirmed by grep). The
real activity feed is:
- **`Version` rows** auto-written by `track_changes: 1` on `HD Ticket` — every field
  change (status, priority, assignment, SLA fields) is a diff row. This is what a
  native port must emulate for "field X changed from A to B" timeline entries.
- **Informational `Comment`s** (`comment_type="Info"`) added explicitly for events
  the Version log wouldn't explain: ticket split (`"split the ticket from #N"`,
  `:210`), auto-close reason (`"automatically closed ... after N days"`, `:1512`),
  merge note (`api.py:220`).

So: three write paths to reimplement — Communication (customer thread), Comment
(Comment = internal note, Info = system event), and a Version-equivalent change log.

---

## 5. Other non-obvious engine behavior

- **Ticket numbering**: `.####` expression naming → sequential integers. Simplest
  native equivalent: autoincrement PK. (`hd_ticket.json`.)
- **Default values on create** (`before_validate`, each only when empty):
  `ticket_type` ← `HD Settings.default_ticket_type` (`consts`: "Unspecified");
  `priority` ← `HD Ticket Type.priority` else `HD Settings.default_priority`
  ("Medium"); `raised_by` ← session user; `status` ← SLA's or Settings'
  `default_ticket_status` ("Open"); `contact`/`customer` derived from `raised_by`
  email (`set_contact`/`set_customer`, auto-set customer only when the contact maps
  to exactly one). (`consts.py`, `install.py`.)
- **Auto-close** — `close_tickets_after_n_days` (`hd_ticket.py:1469`, scheduler
  `daily`): if `HD Settings.auto_close_tickets`, find tickets in
  `auto_close_status` whose **last Communication** is older than
  `auto_close_after_days` (cutoff computed in system tz), set each to `Closed`
  (`ignore_validate`), add an Info comment with the reason. One-way.
- **SLA status refresh** — `update_sla_status_in_ticket` (scheduler `hourly_long`),
  §1.5.
- **Merge** — `api.merge_ticket` (`:161`): copies source's Comments/Communications/
  Files to target (preserving timestamps/owner), closes source with
  `is_merged=1`/`merged_with=target`, posts cross-link Communication + Comment.
  `get_merge_target` (`hd_ticket.py:1022`) follows the merge chain with cycle/dead-end
  guards; a reply to a merged ticket is redirected to the final target
  (`redirect_communication_to_merge_target`).
- **Split** — `api.split_ticket` (`:290`): creates a new ticket from a communication
  point forward, moving later Communications/Comments/Files to it; `duplicate_ticket`
  resets SLA fields (`agreement_status="First Response Due"`, fresh
  `service_level_agreement_creation`, cleared holds/deadlines).
- **Dedupe / first-ticket tag** — `tag_first_ticket` (`:215`): first ever ticket for
  a `raised_by` gets a special tag. No content-level dedupe of tickets themselves;
  "similar tickets" is a stub (`get_recent_similar_tickets` returns `[]` for similar).
- **Outside-working-hours**: `raised_outside_working_hours` stamped on insert
  (`is_currently_outside_working_hours`, `:1002` — holiday today or now outside the
  SLA window). Drives an optional portal banner (`api.show_outside_hours_banner`).
- **Notification triggers** (`notifications.py`, defer if desired): reaction on a
  comment (`notify_reaction`), ticket reopened (`notify_ticket_reopened`), plus
  transactional emails from the ticket controller — acknowledgement on create
  (`send_acknowledgement_email`, gated by `HD Settings.send_acknowledgement_email`),
  agent-reply email (gated by `enable_reply_email_via_agent`), reply-to-agent email
  on customer reply (gated by `enable_reply_email_to_agent`), CSAT email (§3.4).
- **Realtime**: `publish_update` emits `helpdesk:ticket-update` on every `on_update`;
  a native port can replace with websockets/SSE or drop it.
- **Permissions** (walled off from engine logic but affects queries): row-level
  visibility via `permission_query` / `has_permission` (`hd_ticket.py:1329`+) — admins
  all; customers see own + managed-customer tickets; agents see own-assigned + their
  teams' tickets, gated by `HD Settings.restrict_tickets_by_agent_group`.

---

## Source reference index

| Concern | File | Key symbols |
|---|---|---|
| Ticket controller / hooks / lifecycle | `doctype/hd_ticket/hd_ticket.py` | `before_validate`, `before_save`, `set_sla`, `apply_sla`, `set_resolution_date`, `is_valid_status_transition`, `on_communication_update`, `close_tickets_after_n_days`, `update_sla_status_in_ticket` |
| SLA selection | `doctype/hd_service_level_agreement/utils.py` | `get_sla`, `convert_to_seconds` |
| SLA computation | `doctype/hd_service_level_agreement/hd_service_level_agreement.py` | `apply`, `calc_time`, `calc_elapsed_time`, `set_hold_time`, `handle_agreement_status`, `set_first_response_time`, `set_resolution_time` |
| Assignment rules | `doctype/hd_team/hd_team.py`, `doctype/hd_settings/hd_settings.py` | `create_assignment_rule`, `assign_condition`, `sync_users`, `create_base_support_rotation` |
| Assignment on ticket | `doctype/hd_ticket/hd_ticket.py` | `assign_agent`, `get_assigned_agent(s)`, `remove_assignment_if_not_in_team` |
| Statuses | `doctype/hd_ticket_status/hd_ticket_status.py`, `setup/install.py` | `add_default_status`, status/category invariants |
| Priority / type / feedback | `doctype/hd_ticket_priority/…`, `hd_ticket_type/…`, `hd_ticket_feedback_option/…` | rating bounds, defaults |
| Conversation | `doctype/hd_ticket/hd_ticket.py`, `doctype/hd_ticket/api.py`, `doctype/hd_ticket_comment/…` | `reply_via_agent`, `create_communication_via_contact`, `new_comment`, `get_communications`; dead `HDTicketComment`/`HDTicketActivity` |
| Constants / defaults | `consts.py`, `setup/install.py` | `SERVER_COMPUTED_FIELDS`, default type/priority/SLA/status |
| Scheduler / doc events | `hooks.py` | `scheduler_events`, `permission_query_conditions`, `has_permission` |
