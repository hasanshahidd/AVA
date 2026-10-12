# AVA Help Desk — Fork & Rebrand Report

## What this fork is

`helpdesk-app/` is an **AVA-owned fork** of the Frappe Helpdesk application
(`github.com/frappe/helpdesk`), vendored directly into the AVA repo. It replaces
the previous approach of running the stock Frappe Helpdesk Docker image behind
an AVA proxy — AVA now owns the (rebranded) source.

- Source: shallow clone of `frappe/helpdesk` (the **app**: Vue frontend in
  `desk/` + Frappe Python app in `helpdesk/`), with its `.git` removed. It is
  now AVA source, **not** a git submodule.
- We did **NOT** fork `frappe/frappe` (the framework). That stays an upstream
  dependency installed by `bench` at run time.
- **No build was run** (no `npm install`, no `bench`) — this was source editing
  only. Disk was tight (~5 GB) and a build is not needed to rebrand.

### Pruned on vendoring (not needed to run the app)
`.git` (19 MB), `.github/` CI, `e2e/` Playwright tests, `frappe-ui` empty
submodule, `.gitmodules`, `desk/public/videos/` (12 MB onboarding videos),
`helpdesk/locale/` (7.9 MB `.po` translations — Frappe falls back to the
English source strings), `screenshot.webp`, `AGENTS.md`, `playwright.config.ts`.
Vendored size dropped from ~51 MB to ~8 MB.

## What was rebranded (user-facing → "AVA Help Desk")

31 files touched. Categories:

| Area | Files | Change |
|------|-------|--------|
| Brand logo (vector) | `desk/src/assets/logos/HDLogo.vue` | Frappe purple mark → AVA orb icon (copied from `grc-frontend/public/icon.svg`) |
| Favicon | `desk/public/favicon.svg` | → AVA orb icon |
| Page `<title>` + apple PWA title | `desk/index.html` | "Helpdesk"/"Frappe Helpdesk" → "AVA Help Desk" |
| PWA manifest | `desk/vite.config.js` | `name`/`short_name`/`description` → AVA Help Desk |
| App display metadata | `helpdesk/hooks.py` | `app_title`, `app_publisher`, `app_email`, apps-screen `title` |
| Sidebar brand + menus | `desk/src/components/layouts/Sidebar.vue`, `MobileSidebar.vue` | "Frappe Helpdesk" brand title; removed "Login to Frappe Cloud" and "Support → t.me/frappedesk" menu items; docs link → placeholder |
| Onboarding / persona copy | `desk/src/pages/PersonaForm.vue`, `components/Questionnaire.vue` | "Frappe Helpdesk"/"Helpdesk" → "AVA Help Desk" |
| Brand-name fallbacks | `UserMenu.vue`, `Settings/Preferences/Preferences.vue` | `brandName || "Helpdesk"` → `"AVA Help Desk"` |
| Browser tab titles | `pages/ticket/MobileTicketAgent.vue`, `TicketCustomer.vue` | `document.title` → "AVA Help Desk" |
| Welcome sample ticket | `helpdesk/setup/welcome_ticket.py` | Rewrote Frappe-branded body → concise AVA copy (also removed embeds of the pruned videos/images); subject → "Welcome to AVA Help Desk" |
| Email footer | `helpdesk/templates/emails/macros.html` | "Team Frappe" → "AVA Help Desk Team" |
| Help/doc links | 11 Settings `.vue` + banners | `docs.frappe.io/helpdesk` → `docs.ava.io/help-desk` (**placeholder** — repoint when AVA publishes docs) |
| Example placeholders | `NewCustomerDialog.vue`, `composables/customer.ts` | `"frappe.io"`/`"Frappe"` → `"example.com"`/`"Example Inc"` |

**Strings replaced:** all 7 "Frappe Helpdesk" literals, 8 standalone
user-facing "Helpdesk" product strings, ~14 `docs.frappe.io/helpdesk` links,
2 example placeholders, "Team Frappe" footer, 2 removed Frappe-marketing menu
items. **Assets swapped:** 2 (logo component + favicon, both vector).

## What Frappe references REMAIN — and why

### Internal identifiers (MUST stay — the app and AVA's proxy key on them)
- `app_name = "helpdesk"` in `hooks.py`; the `helpdesk` python module/import
  paths; the `/helpdesk` website route; DocType class names
  (`HelpdeskAssignmentRule`, etc.); the `frappe-ui` npm package + `frappe.*`
  API method strings (e.g. `frappe.desk.reportview.delete_items`).
- All **DocType display names** — `HD Ticket`, `HD Agent`, `HD Team`,
  `HD Saved Reply`, `HD Customer`, `HD Ticket Comment`, etc. — and their field
  names. Renaming these would break the app **and** AVA's REST proxy, which
  calls `/api/resource/HD%20Ticket`, filters on `ava_tenant`/`agent_group`,
  and reads these exact names.
- The Frappe **module name** `"Helpdesk"` (`"module": "Helpdesk"` in every
  DocType/report JSON, and `modules.txt`). This is a structural identifier that
  groups the doctypes — **not** a user-facing product string — so it is left as
  is; renaming it breaks module routing and exports.

### Deliberately NOT rebranded (not the Helpdesk product brand) — flagged for review
- **"Frappe Mail"** (9 refs in `Settings/emailConfig.ts`, `EmailAdd.vue`,
  `EmailEdit.vue`): a real third-party email **service provider** the admin can
  pick (like Gmail/Outlook). The config is keyed on the literal string
  `"Frappe Mail"` and the field `frappe_mail_site` — renaming breaks the
  integration. It is a vendor name, not AVA's product brand.
- **Frappe Cloud billing** (`composables/fc.ts`, `components/icons/FrappeCloudIcon.vue`,
  `www/helpdesk/index.py` `is_fc_site`): hosting/billing integration for
  Frappe's paid cloud. The user-facing "Login to Frappe Cloud" menu item was
  **removed**; the remaining code is now inert/dead on an AVA self-host. Left in
  place to avoid a larger diff; safe to delete later.
- **ERPNext integration** (`erpnext-integration/ERPNextIntegrationSettings.vue`
  `frappe.io/cloud/install`, `Settings/EmailEdit.vue` `docs.frappe.io/erpnext`,
  `hd_ticket_template.py` doc link): an optional Frappe-ecosystem feature AVA
  does not use. Product-name mentions here were rebranded; the ERPNext-specific
  external URLs were left (rebranding a link to an actual ERPNext/Frappe-Cloud
  page would be misleading). Review if ERPNext integration is ever exposed.
- **Test fixtures** (`overrides/test_email_account.py` `support@frappe.io`):
  dummy To:/From: addresses in unit tests — not user-facing.
- **Code comments** mentioning `frappe-ui`/Frappe behavior — developer-facing,
  not shipped UI.

### Residual raster assets (low exposure — flagged)
`desk/public/manifest/` still contains the Frappe-purple PWA app icons and
~30 apple splash screens, and `desk/public/*.png` (article/timers/ticketActivity
marketing images). These only appear if someone installs the Frappe **native**
Vue frontend as a PWA — which AVA does not expose (AVA renders its own React
UI). Replacing them needs rendered PNGs; swap when/if the native PWA is exposed.

## How AVA's existing proxy still works unchanged

`backend/grc/modules/helpdesk/router.py` talks to the engine purely by REST
using **internal identifiers**, all of which were preserved:
`/api/resource/HD Ticket`, `HD Ticket Comment`, `HD Team`, `Communication`;
filters on the `ava_tenant` custom field and `agent_group`; the `frappe_helpdesk`
provider id. Because the rebrand only touched **display labels and assets** —
never DocType names, field names, routes, or the `helpdesk` app id — the proxy
needs no changes. (`ava_tenant` is a Custom Field AVA adds on the running
engine, not part of this stock source.)

## Running it locally later (NOT done in this task)

This requires a real Frappe bench and is heavy (~20 GB disk + MariaDB + Redis) —
do it in WSL, not on the current tight `C:` drive:

1. In WSL: install `bench` (frappe-bench) prerequisites — Python 3.10+, Node 18+,
   MariaDB 10.6+, Redis, wkhtmltopdf.
2. `bench init frappe-bench --frappe-branch version-15 && cd frappe-bench`
3. Make this fork available to bench as the `helpdesk` app, e.g.
   `bench get-app helpdesk /path/to/CyberAssurance/helpdesk-app` (or symlink it
   into `apps/helpdesk`). The app id is still `helpdesk`.
4. `bench new-site helpdesk.localhost`
5. `bench --site helpdesk.localhost install-app helpdesk`
6. `bench build` (compiles the `desk/` Vue frontend — needs `yarn install` first)
7. `bench start`, then open `http://helpdesk.localhost:8000/helpdesk`.

The restored i18n translations (`helpdesk/locale/`) and onboarding videos were
pruned on vendoring; re-pull them from upstream only if you need non-English
locales or the video walkthrough.
