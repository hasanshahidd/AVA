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

## Area 4 — Reporting & Dashboards

Act as a client validating reporting. Set things up yourself, use your judgment, report what works, what's confusing, and anything that 500s, mismatches, or renders wrong. Open the file/screen and check — don't assume.

**A. Report Builder (/reports → Builder)**
1. Builder = left controls rail + dashboard canvas on the right. Pick dataset "Help Desk Tickets" — canvas should auto-populate.
2. Group by status, then priority, process, team, department (one at a time) — each renders a breakdown card (share %, counts). Apply a filter (status=Open), click Update, confirm canvas + counts refresh. Switch a card to Top-N, then Donut/Bars.
3. Switch dataset to Assets, then Vulnerabilities, Discovered Devices, CIS, Pentest Findings — each loads its own columns/breakdowns.
4. Confirm GRC datasets (risks, controls, evidence, vendors) do NOT appear in the dataset dropdown (Ava is cyber-only). Report any that do.

**B. Exports — every format**
For a built report (try it on Help Desk Tickets AND Assets AND Vulnerabilities): download CSV, XLSX, PDF, HTML. For EACH file, open it and verify: headers + columns correct and respecting your selected columns/filters; numbers match the screen; PDF/HTML layout renders — no text wrapping one word per line, no truncated columns, charts/tables intact, sane page breaks; no empty/garbled/failed download. Report any format that fails or looks wrong.

**C. Dashboards & count consistency**
Open the Inventory module and the exec/Performance dashboard and reconcile asset numbers across surfaces. These are DIFFERENT scopes BY DESIGN — verify each is internally consistent, not that they're all equal:
- Inventory register total vs its left-nav filter chips: every chip (Infrastructure, Internet-facing, Unowned, Needs-CIA, EASM…) must be ≤ the register total and match the rows shown when clicked. A chip exceeding the total is a bug (recently fixed — confirm it's gone).
- Inventory Overview shows a broader estate number (includes EASM/active) — a different scope than the managed register; confirm it reads sensibly, not that it equals the register.
- Discovery shows raw scanned hosts (hundreds) — a separate pre-adoption view, expected to be much larger. Not a contradiction.
- Exec/Performance dashboard: KPI tiles fill the row, gauges/grades render, MultiSelect filters (asset category, PCI scope) change the data. Confirm it's cyber-only — NO Help Desk ticket KPIs on it (by design); report any that appear. It scores only assessed assets, so its asset count may be lower than inventory — that's expected.

**D. Saved, Scheduled, Trends**
- Save a report, reload, confirm it returns with its config and the correct "Updated <today>" (a save made today must show today, not yesterday — recently fixed, confirm).
- Open a saved report's Trends view: "As of <date>" should render a correct, readable date and the metric definitions should wrap normally (not one word per line — recently fixed, confirm). If trend data is several days stale, flag it (the daily snapshot may not be running).
- Create a schedule (timed email is dormant until SMTP/celery — it should save, not necessarily send).

Report anything that 500s, mismatches a source module, exports wrong, or is confusing to set up.

## Rules

Enter as the client and figure it out yourself — no scripted steps from me. Fill the areas that are genuinely yours; flag the ones that should have shipped with content. Do not change code, settings you don't understand, or anything on the backend. Never create accounts or type passwords. Deliver one consolidated A-to-Z report grouped by the four areas, blockers first.
