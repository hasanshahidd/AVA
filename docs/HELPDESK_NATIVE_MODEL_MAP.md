# Help Desk native model map (Frappe → AVA)

Step 1 of running the Help Desk as native AVA code (FastAPI + Postgres,
per-tenant) instead of on the Frappe framework. Source of truth = the rebranded
Frappe DocType JSON under `helpdesk-app/helpdesk/helpdesk/doctype/<name>/`.

- **Models:** `backend/grc/models/_60_helpdesk_native_models.py` (registered in
  `models/__init__.py`).
- **Schemas:** `backend/grc/schemas/_15_helpdesk_native_schemas.py` (registered in
  `schemas/__init__.py`).
- **Not built yet (later steps):** service logic, endpoints, Alembic migration,
  UI wiring. The existing proxy (`grc/modules/helpdesk/router.py`) is untouched.

## Conventions

| Frappe | AVA-native |
|---|---|
| DocType | SQLAlchemy model, `__tablename__ = "grc_hd_<name>"` |
| implicit doc id | surrogate `id = Column(Integer, primary_key=True)` |
| `ava_tenant` partition | real `tenant_id` FK → `grc_tenants.id` on every top-level table |
| Link → a converted DocType | real FK `<fieldname>_id` + `relationship()` |
| Link → a framework DocType we don't convert | plain `String` holding the external name (see below) |
| Table / Table MultiSelect | child model with parent FK + `idx` order column |
| Data / Small Text / Code / Text Editor | `String` / `Text` |
| Select | `String` (allowed values noted in a comment) |
| Check | `Boolean` |
| Int / Float | `Integer` / `Float` |
| Duration (seconds) | `Float` |
| Rating (0..1) | `Float` |
| Date / Datetime / Time | `Date` / `DateTime` / `Time` |
| Section/Column/Tab Break, HTML, Button, virtual | dropped (layout/computed only) |

Child tables carry **no** `tenant_id` — they are scoped through their parent.
All models carry `created_at` / `updated_at`.

## DocType → table

**22 DocTypes converted → 22 tables** (14 top-level, 8 child).

### Core
| DocType | Model | Table | Kind |
|---|---|---|---|
| HD Ticket | `HDTicket` | `grc_hd_ticket` | top-level |
| HD Ticket Comment | `HDTicketComment` | `grc_hd_ticket_comment` | top-level |
| HD Ticket Activity | `HDTicketActivity` | `grc_hd_ticket_activity` | top-level |
| HD Ticket Status | `HDTicketStatus` | `grc_hd_ticket_status` | top-level |
| HD Ticket Priority | `HDTicketPriority` | `grc_hd_ticket_priority` | top-level |
| HD Ticket Type | `HDTicketType` | `grc_hd_ticket_type` | top-level |
| HD Ticket Template | `HDTicketTemplate` | `grc_hd_ticket_template` | top-level |
| HD Ticket Template Field | `HDTicketTemplateField` | `grc_hd_ticket_template_field` | child → template |

### People
| DocType | Model | Table | Kind |
|---|---|---|---|
| HD Agent | `HDAgent` | `grc_hd_agent` | top-level |
| HD Team | `HDTeam` | `grc_hd_team` | top-level |
| HD Team Member | `HDTeamMember` | `grc_hd_team_member` | child → team |
| HD Customer | `HDCustomer` | `grc_hd_customer` | top-level |

### SLA
| DocType | Model | Table | Kind |
|---|---|---|---|
| HD Service Level Agreement | `HDServiceLevelAgreement` | `grc_hd_service_level_agreement` | top-level |
| HD Service Level Priority | `HDServiceLevelPriority` | `grc_hd_service_level_priority` | child → SLA |
| HD Service Day | `HDServiceDay` | `grc_hd_service_day` | child → SLA |
| HD Service Holiday List | `HDServiceHolidayList` | `grc_hd_service_holiday_list` | top-level |
| HD Holiday | `HDHoliday` | `grc_hd_holiday` | child → holiday list |

### Knowledge base
| DocType | Model | Table | Kind |
|---|---|---|---|
| HD Article | `HDArticle` | `grc_hd_article` | top-level |
| HD Article Category | `HDArticleCategory` | `grc_hd_article_category` | top-level (self-nesting) |

### Replies / Feedback
| DocType | Model | Table | Kind |
|---|---|---|---|
| HD Saved Reply | `HDSavedReply` | `grc_hd_saved_reply` | top-level |
| HD Ticket Feedback Option | `HDTicketFeedbackOption` | `grc_hd_ticket_feedback_option` | top-level |

## Link fields → kept as String (framework DocTypes NOT converted)

These point at Frappe-framework DocTypes outside Help Desk scope; the external
name is stored as a `String` until the matching AVA identity is wired in a later
step.

| Table.column | → Frappe DocType |
|---|---|
| `hd_ticket.contact` | Contact |
| `hd_ticket.email_account` | Email Account |
| `hd_ticket_comment.commented_by` | User |
| `hd_agent.user`, `hd_agent.availability_changed_by` | User |
| `hd_agent.availability` | HD Agent Status (Help Desk, but out of this step's scope) |
| `hd_team_member.user` | User |
| `hd_team.assignment_rule` | Assignment Rule |
| `hd_customer.country` | Country |
| `hd_customer.primary_contact` | Contact |
| `hd_article.author` | User |

> AVA agents == AVA users; mapping `hd_agent.user` / `commented_by` / `author`
> onto `grc_users` is deferred to the CRUD/service step so the model stays a
> faithful transcription here.

## Deferred fields / child tables (and why)

| Source | Where | Why deferred |
|---|---|---|
| HD Comment Reaction (`reactions` table on HD Ticket Comment) | not modelled | Reactions are a SKIP in the parity matrix; comment itself is `deprecated:1` upstream. |
| HD Customer Member (`contacts` table on HD Customer) | not modelled | Child DocType not in this step's convert list. |
| HD Saved Reply Team (`teams` Table MultiSelect on HD Saved Reply) | not modelled | Child DocType not in this step's convert list; `scope` string still carried. |
| `title_slug` (HD Article) | dropped | Frappe virtual (`is_virtual`) / computed field — not stored. |
| SLA `condition` / `condition_json` | kept as `Text` | Python/portal expression strings stored verbatim; no evaluation engine in this step. |
| HD Ticket permlevel/track_changes/states metadata | dropped | Frappe permission/workflow metadata, replaced by AVA RBAC + the activity table. |

## Notes

- **Frappe `name` kept where it carries data:** HD Ticket Type and HD Ticket
  Priority use `autoname: Prompt`, so their document `name` *is* the label. A
  `name` column preserves that identifier (and maps cleanly on a later data
  migration). Doctypes named `field:<x>` already have that field as a column, so
  no extra `name` was added there.
- **HD Ticket Priority** keeps both `name` (Prompt identifier) and `level`
  (its own Select field) exactly as the JSON has them.
- **HD Article Category** `nsm_parent_field` (Frappe nested set) → a nullable
  self-FK `parent_category_id`; the lft/rgt nested-set bookkeeping columns are
  not carried (ordinary adjacency parent link is enough for a category tree).
- **HD Ticket** self-references (`merged_with_id`, `ticket_split_from_id`) use
  explicit `foreign_keys` on their relationships; the multiple status FKs on SLA
  (`default_ticket_status_id`, `ticket_reopen_status_id`) likewise.
- Per-tenant uniqueness that Frappe enforced globally (status label, team name,
  SLA name, saved-reply title, customer name, holiday-list name, feedback label,
  template name, agent user) is re-expressed as composite unique indexes on
  `(tenant_id, <field>)`.
