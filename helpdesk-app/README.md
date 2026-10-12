# AVA Help Desk

AVA's own Help Desk / IT service desk engine. This is an **AVA-owned fork** of
Frappe Helpdesk (the Helpdesk app only — the Frappe framework itself remains an
upstream dependency installed via `bench`). The product has been rebranded to
**AVA Help Desk**; see [`REBRAND_REPORT.md`](./REBRAND_REPORT.md) for exactly
what was changed, what upstream references deliberately remain, and how to run
it locally.

AVA renders its own React UI in front of this engine and talks to it over REST
through `backend/grc/modules/helpdesk/router.py`. Internal identifiers
(DocType names like `HD Ticket`, field names, API routes, the `helpdesk` app
id) are preserved so that proxy keeps working unchanged.

Licensed under AGPLv3 (see `LICENSE`), per the upstream project.
