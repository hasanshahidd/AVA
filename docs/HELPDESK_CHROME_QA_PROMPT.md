# AVA Help Desk — consolidated A-to-Z QA prompt (Claude Chrome extension)

Paste the block below into the Claude Chrome extension as a single prompt. It is written to be run **as a client**, not as a scripted test: the agent sets the product up the way a new customer would, then exercises it end-to-end, and reports every gap back. Do **not** add step-by-step instructions — the whole point is that the agent discovers the flow itself.

**Before you start:** sign the browser into the AVA workspace with an **admin** account (the agent cannot and must not create accounts or type passwords on the hosted box — a human does the login, then hands the signed-in tab to the agent). Replace `<WORKSPACE_URL>` below with the URL the agent should work in.

---

You are a **new customer administrator** who has just been given AVA Help Desk at `<WORKSPACE_URL>`. Nobody has handed you a manual or a checklist. Your job is to stand the product up for your organisation the way a real client would, run it end to end, and then tell me everything that is broken, confusing, missing, or wrong.

Work entirely through the **front end**, as the client. Never touch the backend, the database, a shell, or any script — if something can only be done from the backend, that itself is a gap to report. Never fix anything you find; you are evaluating, not repairing. Keep a running log and give me one consolidated A-to-Z report at the end.

**Phase 0 — Orient as a client (no hand-holding).**
Explore the whole product first. Find the Help Desk and everything around it (Service Desk Admin / Settings, the agent console, the end-user portal, CMDB, governance, reporting). Build your own mental map of what exists and, crucially, **what is empty and therefore something you as the client are expected to fill in**. Write that list down before you change anything.

**Phase 1 — Set it up, client-side, completely.**
Now configure the product for your organisation using only the UI, as the client would on day one. At minimum:
- Review the departments, priorities, statuses, ticket types, SLAs and the service catalogue that shipped with the product. Tailor them to your org where the UI lets you (rename, add, disable).
- Create your agents and teams, and set the branding, business hours and the email/notification templates.
- Fill the areas that are legitimately **yours** to fill: write a few real Knowledge Base articles, set your CAB membership, add any org-specific incident categories or request items, and configure feedback.
- As you go, judge each empty area: *is it empty because it's genuinely customer content (I should fill it), or empty because the product should have shipped a sensible default and didn't?* Record the second kind as a gap — but still fill it yourself so you can keep testing.

**Phase 2 — Operate it end to end.**
Act out the real lifecycle across roles (requester, agent, admin):
- Raise tickets from the end-user portal; confirm the requester only sees their own.
- As an agent, triage, assign, reply, use saved replies and KB deflection, escalate, resolve, and capture feedback. Check SLA timers start/pause/breach correctly.
- Run each ITIL process you can reach: **Incident**, **Service Request** (with approvals), **Problem**, and **Change** — for Change, drive a Standard (should auto-approve), a Normal/Major (should route to CAB), and an Emergency (should route to ECAB), and confirm the approval/CAB behaviour actually fires. If change types or a risk matrix are missing, Change routing will misbehave — report it.
- Exercise the CMDB: link a CI to a ticket, open a CI's impact view, and confirm the CMDB reflects real inventory (hosts/services as the estate, installed software as per-host detail — not thousands of top-level items).

**Phase 3 — Cross-module.**
Follow the threads that cross out of the Help Desk: a vulnerability pushed to a ticket (does the finding link back to its ticket and sync status?), the pentest → vuln register → ticket path, CMDB ↔ IT-asset inventory consistency, and asset ↔ CI linkage. Report every one-directional or inconsistent link.

**Phase 4 — Reporting.**
Open every report and dashboard you can reach from the Help Desk and the wider platform (ticket reports and their exports, the executive dashboard, trends). Check the numbers are internally consistent (e.g. the same asset/ticket counts across overview, tabs, and dashboards), the date ranges are right, and nothing is cyber-only when it should include the Help Desk. Report any contradiction, stale figure, or broken export. *(GRC/reporting owner: refine this phase with the specific report surfaces and the known count-consistency checks.)*

**Rules.** Enter as the client and figure it out yourself — no scripted steps from me. Fill the areas that are genuinely yours to fill; flag the ones that should have shipped with content. For every bug or gap, record: where it is (role + screen + URL), what you did, what happened, what you expected, and how bad it is. Do not change code, settings you don't understand, or anything on the backend. Deliver one consolidated A-to-Z report grouped by area, with the blockers first.
