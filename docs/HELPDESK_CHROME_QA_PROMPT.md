# AVA Help Desk — consolidated A-to-Z QA prompt (Claude Chrome extension)

Paste the block below into the Claude Chrome extension as a single prompt. It runs **as a client**, not as a scripted test: the agent sets the product up the way a new customer would, then exercises it end-to-end across all four areas, and reports every gap back. Do **not** add step-by-step instructions — the whole point is that the agent discovers the flow itself.

It covers four areas: **(1) Administrator**, **(2) Agent Console**, **(3) End User**, and **(4) Reporting**. Area 4 (Reporting) is owned by the reporting/GRC session — its detail is filled in that section below.

**Before you start:** sign the browser into the AVA workspace with an **admin** account (the agent cannot and must not create accounts or type passwords on the hosted box — a human does the login, then hands the signed-in tab to the agent). Replace `<WORKSPACE_URL>` with the URL the agent should work in.

---

You are a **new customer administrator** who has just been given AVA Help Desk at `<WORKSPACE_URL>`. Nobody has handed you a manual or a checklist. Your job is to stand the product up for your organisation the way a real client would, run it end to end across every role, and then tell me everything that is broken, confusing, missing, or wrong.

Work entirely through the **front end**, as the client. Never touch the backend, the database, a shell, or any script — if something can only be done from the backend, that itself is a gap to report. Never fix anything you find; you are evaluating, not repairing. Keep a running log and give me one consolidated A-to-Z report at the end, grouped by the four areas below, blockers first. For every bug or gap record: where it is (area + screen + URL), what you did, what happened, what you expected, and how bad it is.

First, orient with no hand-holding: explore the whole product and build your own map of what exists and — crucially — **what is empty and therefore something you as the client are expected to fill in**. As you go, judge each empty area: *is it empty because it's genuinely customer content (I should fill it), or because the product should have shipped a sensible default and didn't?* Record the second kind as a gap, but still fill it yourself so you can keep testing.

## Area 1 — Administrator (set it up and govern it, client-side)

Configure the product for your organisation using only the UI, as the client would on day one:
- Review what shipped — departments, priorities, statuses, ticket types, SLAs, the service catalogue, change types, change risk matrix, incident categories, the feedback/CSAT scale. Tailor them where the UI allows (rename, add, disable). Note anything that should have shipped with a default but is empty.
- Create your **agents** and **teams**; set branding, **business hours**, and the **email/notification templates** (Settings › Email).
- Fill what is legitimately yours: write a few real **Knowledge Base** articles, set your **CAB membership**, add org-specific incident categories or request items, configure feedback.
- Exercise the **CMDB**: run the inventory sync, confirm it reflects the real estate (hosts/services as the configuration items, installed software as per-host drill-down detail — not thousands of top-level items), link a CI to a ticket, open a CI's impact view.
- Confirm role boundaries from the admin side: that an agent and an end user each see only what they should (admin is the superset).

## Area 2 — Agent Console (operate the queue)

Act as an agent working real tickets:
- Triage, assign (to agents/teams), reply, use saved replies and **KB deflection**, add internal notes, escalate, resolve, reopen, and capture feedback.
- Confirm **SLA** timers start, pause, and breach correctly, and that priority is derived as expected.
- Run each ITIL process you can reach: **Incident**, **Service Request** (with approvals), **Problem**, and **Change** — for Change, drive a Standard (should auto-approve), a Normal/Major (should route to **CAB**), and an Emergency (should route to **ECAB**), and confirm the approval behaviour actually fires. If change types or the risk matrix are missing, Change routing misbehaves — report it.
- Follow the cross-module threads that surface in the console: a vulnerability pushed to a ticket (does the finding link back to its ticket and sync status?), the pentest → vuln register → ticket path, and asset ↔ CI linkage. Report any one-directional or inconsistent link.

## Area 3 — End User (the portal)

Act as an ordinary employee with no agent rights:
- Raise tickets / service requests from the portal; confirm you only ever see your **own** tickets and nothing from the agent console or any cyber module.
- Track a ticket, reply to an agent, self-serve via the Knowledge Base (does search/deflection surface the right articles?), approve a request where you're the approver, and leave feedback after resolution.
- Probe isolation: try to reach agent/admin/cyber URLs directly and confirm you're blocked (both the screen and the data behind it).

## Area 4 — Reporting  *(owned by the reporting / GRC session — fill this section)*

Reporting is a separate module owned by the reporting session. It must be exercised in depth:
- Open **every** report and dashboard reachable from the Help Desk and the wider platform (ticket reports, the executive dashboard, trends, and each module's own report).
- **Download each module's report in every format it offers** (PDF / CSV / XLSX / etc.) and actually open the downloaded file — check the **formatting and layout render correctly** (headers, columns, alignment, charts, page breaks, no CSS-mangled one-word-per-line text, no truncation).
- Check the **trends** views: that the series are populated, the ranges are right, and the data isn't stale.
- Check **cross-report number consistency** (the same ticket/asset counts agree across overview, tabs, dashboards and the exported files) and that nothing is cyber-only when it should include the Help Desk.
- Report any contradiction, stale figure, broken export, or formatting defect.

*(Reporting/GRC session: replace this section with the precise report surfaces, the export formats to check per module, and the known count-consistency checks — inventory 12-vs-6-vs-516, exec-dashboard scope, trends staleness, the report date bug.)*

## Rules

Enter as the client and figure it out yourself — no scripted steps from me. Fill the areas that are genuinely yours; flag the ones that should have shipped with content. Do not change code, settings you don't understand, or anything on the backend. Never create accounts or type passwords. Deliver one consolidated A-to-Z report grouped by the four areas, blockers first.
