# Business Department Service Catalog — Research & Reference

**Purpose:** a realistic, department-aware **non-IT / business** service catalog for the AVA Help Desk
(shared service desk / enterprise service management). Every item below is a request real enterprises and
banks actually surface on ServiceNow HRSD, Jira Service Management, Archibus, Onit, university/bank shared-
service portals, and ESM reference material — not generic filler.

**Schema enums are aligned to the AVA Help Desk model** (`docs/HELPDESK_ITSM_SPEC.md`):
- `process` ∈ `incident | service_request | problem | change`
- `impact_default` / `urgency_default` ∈ `low | medium | high` (priority derives via the ITIL 4-level matrix)
- Rule of thumb applied: a **working** administrative request = `service_request`; a **broken** business
  system (ERP down, CRM errors, access that stopped working) = `incident`; a recurring root-cause pattern =
  `problem`; a standing/configuration change (new cost center, mail rule, catalog change) = `change`.

**Departments covered (7):** HR · Finance · Procurement · Facilities/Workplace · Sales/CRM · Legal ·
Operations · Marketing. (Finance and Procurement are modelled as two owning departments under one "Finance &
Procurement" business area, per the task's grouping.)

**Record schema (every item):** `title` · `process` · `category` (department) + `subcategory` ·
`short_description` · `department_scope` (owning dept; raisable by anyone to that dept) · `impact_default` ·
`urgency_default` · `suggested_team`.

---

## 1. HR (Human Resources)

Owning department: **HR**. Teams: HR Operations (HR Ops / HR Shared Services), Payroll, Benefits, Talent
Acquisition, HR Business Partner (HRBP). Modelled on ServiceNow HRSD catalog categories (Recruiting &
Onboarding; Compensation, Benefits & Pensions; Time & Absence; Employee Data Management) and common HR
shared-service request lists (proof-of-employment letters, paycheck discrepancy, add beneficiaries).

| # | Title | Process | Subcategory | Short description | Dept scope | Impact | Urgency | Suggested team |
|---|-------|---------|-------------|-------------------|------------|--------|---------|----------------|
| HR-01 | New hire onboarding setup | service_request | Recruiting & Onboarding | Kick off onboarding for a new or returning employee (profile, equipment, access, day-1 checklist). | HR | medium | medium | HR Operations |
| HR-02 | Employee offboarding / termination | service_request | Offboarding | Process a leaver — final pay, access revocation, equipment return, exit checklist. | HR | high | high | HR Operations |
| HR-03 | Report a paycheck discrepancy | incident | Payroll | My pay is wrong, missing, or late and needs correcting. | HR | high | high | Payroll |
| HR-04 | Update direct deposit / bank details | change | Payroll | Change the bank account my salary is paid into. | HR | medium | medium | Payroll |
| HR-05 | Request time off / leave of absence | service_request | Time & Absence | Submit vacation, sick, parental, medical, military, or jury-duty leave. | HR | low | medium | HR Operations |
| HR-06 | Benefits enrollment / life-event change | service_request | Benefits | Enroll in or change health/retirement benefits or add beneficiaries after a qualifying event. | HR | medium | medium | Benefits |
| HR-07 | Request an employment / income verification letter | service_request | Letters & Documents | Proof-of-employment or salary letter for a visa, mortgage, or landlord. | HR | low | medium | HR Operations |
| HR-08 | Update personal data | change | Employee Data Management | Change name, address, marital status, emergency contact, or dependents. | HR | low | low | HR Operations |
| HR-09 | Ask an HR / policy question | service_request | General HR | General question about policy, handbook, pay cycle, or entitlements. | HR | low | low | HR Operations |
| HR-10 | Report a workplace concern / employee relations case | service_request | Employee Relations | Confidentially raise a grievance, harassment, or conduct concern. | HR | high | high | HR Business Partner |
| HR-11 | Immigration / work-visa support request | service_request | Mobility & Visa | Sponsorship, visa renewal, or relocation support for an employee. | HR | medium | medium | HR Operations |
| HR-12 | Training / learning enrollment & tuition request | service_request | Talent Management | Enroll in a course or request tuition reimbursement / certification funding. | HR | low | low | HR Operations |

*Record detail (example — HR-03):*
`{title:"Report a paycheck discrepancy", process:"incident", category:"HR", subcategory:"Payroll",
short_description:"My pay is wrong, missing, or late and needs correcting.", department_scope:["HR"],
impact_default:"high", urgency_default:"high", suggested_team:"Payroll"}`

---

## 2. Finance

Owning department: **Finance**. Teams: Finance Operations (Finance Ops), Accounts Payable (AP), Accounts
Receivable (AR), FP&A (Budget/Cost-Center), ERP/Systems Finance. Modelled on university financial-shared-
services catalogs (Penn State, Kansas, Idaho) and ServiceNow S2P / Freshworks ESM examples (expense reports,
non-PO invoice, journal entry, chart-of-accounts, ERP access).

| # | Title | Process | Subcategory | Short description | Dept scope | Impact | Urgency | Suggested team |
|---|-------|---------|-------------|-------------------|------------|--------|---------|----------------|
| FIN-01 | Submit an expense reimbursement | service_request | Travel & Expense | Reimburse travel or out-of-pocket business expenses (outside Concur). | Finance | low | medium | Accounts Payable |
| FIN-02 | Report an invoice / supplier payment issue | incident | Accounts Payable | A supplier invoice is unpaid, paid late, duplicated, or paid incorrectly. | Finance | high | high | Accounts Payable |
| FIN-03 | Submit a non-PO invoice for payment | service_request | Accounts Payable | Pay an invoice that has no purchase order attached. | Finance | medium | medium | Accounts Payable |
| FIN-04 | Customer / AR invoice or receivables query | service_request | Accounts Receivable | Raise, correct, or query a customer invoice or an unapplied receipt. | Finance | medium | medium | Accounts Receivable |
| FIN-05 | Book a journal entry / accrual | service_request | General Ledger | Request a manual journal, accrual, reclass, or correcting entry. | Finance | medium | low | Finance Operations |
| FIN-06 | New / change cost center or budget line | change | Budget & Cost Center | Create a cost center, GL code, or move budget between lines. | Finance | medium | low | FP&A |
| FIN-07 | Chart-of-accounts maintenance | change | General Ledger | Add or amend a GL account, internal order, or billing rate. | Finance | medium | low | Finance Operations |
| FIN-08 | Request ERP finance-system access | service_request | ERP Access | Grant or change a user's role in SAP/Oracle/finance system. | Finance | medium | medium | ERP/Systems Finance |
| FIN-09 | ERP / finance system error or outage | incident | ERP Access | A finance module (postings, reporting, approvals) is erroring or down. | Finance | high | high | ERP/Systems Finance |
| FIN-10 | Corporate card request / dispute | service_request | Corporate Card | Request a P-card/corporate card, raise a limit, or dispute a charge. | Finance | low | medium | Accounts Payable |
| FIN-11 | Financial / management report request | service_request | Reporting | Request a budget-vs-actual, spend, or ad-hoc financial report. | Finance | low | low | FP&A |
| FIN-12 | Repeated AP payment failures (root cause) | problem | Accounts Payable | Investigate a recurring pattern of failed/duplicate supplier payments. | Finance | high | medium | Finance Operations |

*Record detail (example — FIN-02):*
`{title:"Report an invoice / supplier payment issue", process:"incident", category:"Finance",
subcategory:"Accounts Payable", short_description:"A supplier invoice is unpaid, paid late, duplicated, or
paid incorrectly.", department_scope:["Finance"], impact_default:"high", urgency_default:"high",
suggested_team:"Accounts Payable"}`

---

## 3. Procurement

Owning department: **Procurement**. Teams: Procurement Operations, Vendor/Supplier Management, Sourcing,
Contracts (shared with Legal). Modelled on ServiceNow Source-to-Pay (sourcing request, supplier onboarding
with risk assessment, PO change) and university catalogs (non-catalog requisition, modify existing order).

| # | Title | Process | Subcategory | Short description | Dept scope | Impact | Urgency | Suggested team |
|---|-------|---------|-------------|-------------------|------------|--------|---------|----------------|
| PRC-01 | Create a purchase requisition (non-catalog) | service_request | Purchasing | Request to buy a product or service not in the punch-out catalog. | Procurement | medium | medium | Procurement Operations |
| PRC-02 | New vendor / supplier onboarding | service_request | Vendor Management | Set up a new supplier incl. tax/bank details and risk assessment. | Procurement | medium | medium | Vendor Management |
| PRC-03 | Modify an existing purchase order | change | Purchasing | Change quantity, funding, or partially/fully cancel an existing PO. | Procurement | medium | medium | Procurement Operations |
| PRC-04 | Update existing vendor master data | change | Vendor Management | Change a supplier's bank, remittance, address, or contact details. | Procurement | medium | medium | Vendor Management |
| PRC-05 | Sourcing / RFx request | service_request | Sourcing | Run a competitive quote/RFP/RFQ for a new spend above threshold. | Procurement | medium | low | Sourcing |
| PRC-06 | Goods / services receipting issue | incident | Receiving | Received quantity, goods-receipt, or three-way-match won't process. | Procurement | medium | high | Procurement Operations |
| PRC-07 | Contract / renewal request | service_request | Contracts | Request a new supplier contract, renewal, or extension. | Procurement | medium | medium | Contracts |
| PRC-08 | Software / SaaS purchase approval | service_request | Purchasing | Approve and procure a new software subscription or license. | Procurement | low | medium | Procurement Operations |
| PRC-09 | Procurement policy / spend question | service_request | General Procurement | Question about thresholds, approvals, preferred suppliers, or P2P policy. | Procurement | low | low | Procurement Operations |

*Record detail (example — PRC-02):*
`{title:"New vendor / supplier onboarding", process:"service_request", category:"Procurement",
subcategory:"Vendor Management", short_description:"Set up a new supplier incl. tax/bank details and risk
assessment.", department_scope:["Procurement"], impact_default:"medium", urgency_default:"medium",
suggested_team:"Vendor Management"}`

---

## 4. Facilities / Workplace

Owning department: **Facilities**. Teams: Facilities, Workplace Services, Security/Access, Maintenance,
Mailroom. Modelled on Archibus workplace service catalog (meeting rooms, workspaces, moves, maintenance,
parking, shredding) and UT Dallas / NOAA campus facilities catalogs (key card, conference room, parking
decal, furniture move).

| # | Title | Process | Subcategory | Short description | Dept scope | Impact | Urgency | Suggested team |
|---|-------|---------|-------------|-------------------|------------|--------|---------|----------------|
| FAC-01 | Desk / office move request | service_request | Moves | Move an individual or team to a new desk, office, or floor. | Facilities | low | medium | Workplace Services |
| FAC-02 | Request / replace an access card / badge | service_request | Access & Security | New, replacement, or additional building access card or badge. | Facilities | medium | medium | Security/Access |
| FAC-03 | Report a facilities fault / maintenance issue | incident | Maintenance | HVAC, lighting, plumbing, leak, or broken fixture needs repair. | Facilities | medium | high | Maintenance |
| FAC-04 | Book / support a meeting room or event space | service_request | Space Booking | Reserve a room or request AV/setup for a meeting or event. | Facilities | low | low | Workplace Services |
| FAC-05 | Office equipment / furniture request | service_request | Equipment | Request a chair, monitor arm, standing desk, or office supplies. | Facilities | low | low | Workplace Services |
| FAC-06 | Parking space / permit request | service_request | Parking | Request a parking space, permit, or EV-charging access. | Facilities | low | low | Workplace Services |
| FAC-07 | Cleaning / janitorial request | service_request | Cleaning | Request ad-hoc cleaning, spill response, or waste removal. | Facilities | low | medium | Facilities |
| FAC-08 | Building access / lock-out incident | incident | Access & Security | Door, turnstile, or badge reader not working; locked out of a space. | Facilities | medium | high | Security/Access |
| FAC-09 | Mail / courier / shipping request | service_request | Mailroom | Send, receive, or track a package, courier, or internal mail. | Facilities | low | low | Mailroom |
| FAC-10 | Health & safety / incident report | incident | Health & Safety | Report an unsafe condition, hazard, or workplace injury. | Facilities | high | high | Facilities |

*Record detail (example — FAC-03):*
`{title:"Report a facilities fault / maintenance issue", process:"incident", category:"Facilities",
subcategory:"Maintenance", short_description:"HVAC, lighting, plumbing, leak, or broken fixture needs
repair.", department_scope:["Facilities"], impact_default:"medium", urgency_default:"high",
suggested_team:"Maintenance"}`

---

## 5. Sales / CRM

Owning department: **Sales Operations**. Teams: Sales Operations (Sales Ops), CRM Administration, Deal Desk,
Revenue Operations (RevOps). Modelled on GitLab field-ops internal-support intake (Deal Desk, Sales Ops,
Billing, Renewals teams) and University of Kentucky Salesforce service catalog (CRM access, new report,
data load).

| # | Title | Process | Subcategory | Short description | Dept scope | Impact | Urgency | Suggested team |
|---|-------|---------|-------------|-------------------|------------|--------|---------|----------------|
| CRM-01 | Request CRM access / license | service_request | CRM Access | New Salesforce/CRM user, license, or permission-set change. | Sales Operations | medium | medium | CRM Administration |
| CRM-02 | CRM error / data not saving | incident | CRM Access | A CRM page, flow, or record errors or won't save. | Sales Operations | high | high | CRM Administration |
| CRM-03 | New report / dashboard request | service_request | Reporting | Build a new CRM report or dashboard, or amend an existing one. | Sales Operations | low | low | Sales Operations |
| CRM-04 | Data / record fix or bulk update | service_request | Data Management | Correct, merge, reassign, or bulk-import CRM records. | Sales Operations | medium | medium | Sales Operations |
| CRM-05 | Lead routing / assignment issue | incident | Lead Management | Leads not routing to the right owner, queue, or territory. | Sales Operations | high | high | Revenue Operations |
| CRM-06 | Quote / pricing / CPQ tool help | service_request | Deal Support | Help with a quote, discount approval, or CPQ pricing config. | Sales Operations | medium | medium | Deal Desk |
| CRM-07 | Opportunity / forecast correction | service_request | Deal Support | Fix stage, amount, close date, or forecast category on a deal. | Sales Operations | medium | medium | Sales Operations |
| CRM-08 | Territory / quota / comp plan change | change | Territory & Comp | Change a territory, account assignment, quota, or comp plan. | Sales Operations | medium | low | Revenue Operations |

*Record detail (example — CRM-05):*
`{title:"Lead routing / assignment issue", process:"incident", category:"Sales/CRM",
subcategory:"Lead Management", short_description:"Leads not routing to the right owner, queue, or
territory.", department_scope:["Sales Operations"], impact_default:"high", urgency_default:"high",
suggested_team:"Revenue Operations"}`

---

## 6. Legal

Owning department: **Legal**. Teams: Legal Operations (Legal Ops), Commercial/Contracts Counsel, Privacy,
Ethics & Compliance. Modelled on ServiceNow Legal Service Delivery catalog (Sales Contract Review, Third-
Party Contract Review, NDA, Privacy Impact Assessment, Conflict of Interest, Subpoena, General Legal Request)
and Onit legal request templates (NDA generate/review, redlining, DPA).

| # | Title | Process | Subcategory | Short description | Dept scope | Impact | Urgency | Suggested team |
|---|-------|---------|-------------|-------------------|------------|--------|---------|----------------|
| LEG-01 | Contract review request | service_request | Contracts | Review/redline a customer, vendor, or partner contract (MSA, SOW). | Legal | medium | medium | Commercial/Contracts Counsel |
| LEG-02 | NDA request (generate or review) | service_request | Contracts | Generate a company NDA or review a counterparty's NDA. | Legal | low | medium | Commercial/Contracts Counsel |
| LEG-03 | General legal question / advice | service_request | General Legal | Ask counsel a question on risk, obligations, or interpretation. | Legal | low | low | Legal Operations |
| LEG-04 | Policy / regulatory interpretation request | service_request | Compliance | Clarify how a policy or regulation applies to a situation. | Legal | medium | low | Ethics & Compliance |
| LEG-05 | Privacy impact assessment / DPA request | service_request | Privacy | Assess a new data use or request a data-processing agreement. | Legal | medium | medium | Privacy |
| LEG-06 | Conflict of interest / gifts disclosure | service_request | Ethics & Compliance | Disclose a conflict, outside activity, or gift for pre-clearance. | Legal | medium | low | Ethics & Compliance |
| LEG-07 | Legal hold / litigation preservation | change | Litigation | Place or lift a legal hold preserving data for a matter. | Legal | high | high | Legal Operations |
| LEG-08 | Subpoena / legal demand intake | service_request | Litigation | Route an incoming subpoena, demand, or regulator request. | Legal | high | high | Legal Operations |
| LEG-09 | Marketing / public-content legal review | service_request | Contracts | Legal/brand review of a campaign, PR, claim, or web content. | Legal | low | medium | Commercial/Contracts Counsel |

*Record detail (example — LEG-01):*
`{title:"Contract review request", process:"service_request", category:"Legal", subcategory:"Contracts",
short_description:"Review/redline a customer, vendor, or partner contract (MSA, SOW).",
department_scope:["Legal"], impact_default:"medium", urgency_default:"medium",
suggested_team:"Commercial/Contracts Counsel"}`

---

## 7. Operations

Owning department: **Operations**. Teams: Business Operations (Business Ops), Order Management, Supply Chain,
Data Operations. Modelled on back-office order-desk / supply-chain shared-service roles (order entry, order
blocks, returns, backorders, discrepancies) and ESM service-desk request-type patterns.

| # | Title | Process | Subcategory | Short description | Dept scope | Impact | Urgency | Suggested team |
|---|-------|---------|-------------|-------------------|------------|--------|---------|----------------|
| OPS-01 | New / change sales order entry | service_request | Order Management | Create, amend, or expedite a customer order in the ERP. | Operations | medium | medium | Order Management |
| OPS-02 | Order block / hold release | incident | Order Management | A credit, pricing, or stock block is stopping an order from shipping. | Operations | high | high | Order Management |
| OPS-03 | Return / RMA / credit note request | service_request | Returns | Process a customer return, RMA, or associated credit note. | Operations | medium | medium | Order Management |
| OPS-04 | Backorder / delivery / fulfillment issue | incident | Supply Chain | A shipment is delayed, short, or stuck; customer delivery at risk. | Operations | high | high | Supply Chain |
| OPS-05 | Master-data / record creation request | service_request | Data Operations | Create or update a customer, material, or pricing master record. | Operations | low | medium | Data Operations |
| OPS-06 | Operational / KPI report request | service_request | Reporting | Request an ad-hoc operations, inventory, or SLA report. | Operations | low | low | Business Operations |
| OPS-07 | Process exception / approval request | service_request | Process | Request a one-off exception, override, or manual approval. | Operations | medium | medium | Business Operations |
| OPS-08 | Recurring order-fulfillment defect (root cause) | problem | Supply Chain | Investigate a repeating fulfillment, data, or process failure. | Operations | high | medium | Business Operations |

*Record detail (example — OPS-02):*
`{title:"Order block / hold release", process:"incident", category:"Operations",
subcategory:"Order Management", short_description:"A credit, pricing, or stock block is stopping an order
from shipping.", department_scope:["Operations"], impact_default:"high", urgency_default:"high",
suggested_team:"Order Management"}`

---

## 8. Marketing

Owning department: **Marketing**. Teams: Marketing Operations (Marketing Ops), Brand/Creative, Web/Digital,
Campaigns. Modelled on marketing intake-form examples (Typeform, Wrike, Pipefy, Munson Healthcare, Colorado
Mesa) covering request type, creative brief, brand assets, website/content changes, and campaign/tooling.

| # | Title | Process | Subcategory | Short description | Dept scope | Impact | Urgency | Suggested team |
|---|-------|---------|-------------|-------------------|------------|--------|---------|----------------|
| MKT-01 | Creative / design asset request | service_request | Brand & Creative | Request a new design — deck, flyer, social, print, or ad creative. | Marketing | low | medium | Brand/Creative |
| MKT-02 | Brand asset / logo / guideline request | service_request | Brand & Creative | Get approved logos, templates, fonts, or brand-guideline access. | Marketing | low | low | Brand/Creative |
| MKT-03 | Campaign brief / launch request | service_request | Campaigns | Brief and launch a new marketing campaign across channels. | Marketing | medium | medium | Campaigns |
| MKT-04 | Website content / page change request | service_request | Web & Digital | Add or update web copy, a page, or a landing page. | Marketing | low | medium | Web/Digital |
| MKT-05 | Website / landing page is broken | incident | Web & Digital | A live page, form, or link is down or rendering incorrectly. | Marketing | high | high | Web/Digital |
| MKT-06 | Email / newsletter send request | service_request | Campaigns | Build and schedule an email or newsletter to a segment. | Marketing | low | medium | Campaigns |
| MKT-07 | Marketing tool / platform access | service_request | MarTech | Access to the CMS, marketing automation, or analytics tool. | Marketing | low | low | Marketing Operations |
| MKT-08 | Event / collateral / swag request | service_request | Events | Request event support, printed collateral, or branded merchandise. | Marketing | low | low | Marketing Operations |

*Record detail (example — MKT-05):*
`{title:"Website / landing page is broken", process:"incident", category:"Marketing",
subcategory:"Web & Digital", short_description:"A live page, form, or link is down or rendering
incorrectly.", department_scope:["Marketing"], impact_default:"high", urgency_default:"high",
suggested_team:"Web/Digital"}`

---

## Summary

- **Departments (8 owning scopes across 7 business areas):** HR · Finance · Procurement · Facilities ·
  Sales/CRM · Legal · Operations · Marketing.
- **Total items: 86**
  - HR 12 · Finance 12 · Procurement 9 · Facilities 10 · Sales/CRM 8 · Legal 9 · Operations 8 · Marketing 8.
- **Process split:**
  - `service_request`: **62**
  - `incident`: **15**
  - `change`: **6**
  - `problem`: **3**
- **Design notes:**
  - Most business items are `service_request` (the ESM default). `incident` is reserved for *broken* systems
    and operational breakage (ERP down, CRM errors, lead routing failing, order blocks, broken web pages,
    facilities faults, safety incidents). `change` is used for standing/config changes (bank details, cost
    center, chart-of-accounts, PO/vendor master edits, territory/comp, legal hold). `problem` is used for
    recurring root-cause investigations (AP payment failures, fulfillment defects).
  - `department_scope` holds the **owning** department; each item is shown to that department and raisable to
    it by anyone, matching the shared-service "single entry point" pattern.
  - Impact/urgency defaults feed the ITIL 4-level priority matrix in `HELPDESK_ITSM_SPEC.md` (high/high →
    Urgent for true breakage and leaver/legal-hold/safety cases).

---

## Sources I used

**HR (ServiceNow HRSD):**
- ServiceNow — HR service catalog management: https://www.servicenow.com/docs/r/H8yQl2SqBqnT6LbpTm28UQ/LCLCLIXWpKwA5pnzx9xM9Q
- ServiceNow — HR services (categories: benefits, payroll, direct deposit, relocation, paycheck inquiry): https://www.servicenow.com/docs/r/H8yQl2SqBqnT6LbpTm28UQ/VyUvANAOjXrU2COZdwfdSQ
- ServiceNow Community — list of HR services / leave-of-absence blueprints: https://www.servicenow.com/community/hrsd-forum/list-of-hr-services/m-p/1323361
- ServiceNow HRSD tutorial (HR case → HR tasks flow): https://www.servicenow.com/community/developer-articles/servicenow-hrsd-tutorial-article-part-1/tac-p/3025972

**Finance shared services:**
- Penn State Financial Shared Services (reimburse/reconcile, non-PO invoice, journal entries, chart of accounts): https://fandb.psu.edu/financial-shared-services
- University of Kansas SSC Finance Request (submit invoices, P-card receipts, modify existing order): https://services.ku.edu/TDClient/631/Portal/Requests/Service/9859/SSC-Finance-Request
- University of Idaho Financial Shared Services (EPAF / pay & position changes): https://support.uidaho.edu/TDClient/90/fss/Requests/ServiceCatalog/Category/196/Financial-Shared-Services
- Xurrent — service request management (ERP read-access request example; fulfillment model): https://www.xurrent.com/glossary/request-service-request

**Procurement / Source-to-Pay:**
- ServiceNow — Understanding the end-to-end sourcing workflow in Source-to-Pay Operations (sourcing request, auto requisition, supplier onboarding w/ risk, AP exceptions): https://www.servicenow.com/docs/r/JTWplvZ8VmXxZI9uJMnUeA/OzRbU3Q5eDIlOxyMEUbpLA
- ServiceNow — Source-to-Pay sourcing workflow: https://www.servicenow.com/docs/r/R4_7U~K1gmloMk7~WOJw8A/Ntd0mk3SyxerFQXc5o~3mA

**Facilities / Workplace (Archibus + campus catalogs):**
- Archibus — Service Catalog (Workplace) (meeting rooms, workspaces, moves, maintenance, shredding): https://help.archibus.com/system_v26.3/Content/shared_gloss/service_catalog_def.htm
- Archibus — Service request definition (maintenance, copying, parking, moves, supplies; approval/cost/work orders): https://help.archibus.com/user_en/Subsystems/webc/Content/gloss/service_desk/help_request.htm
- UT Dallas Operations service catalog (room/space, relocations, keys/card authorization): https://atlas.utdallas.edu/TDClient/30/Portal/Requests/ServiceCatalog/Category/126/Operations
- SolarWinds — 20 employee services to automate facilities: https://www.solarwinds.com/blog/20-employee-services-to-automate-facilities

**Sales / CRM:**
- GitLab Handbook — Requesting Internal Support in Salesforce (Deal Desk, Sales Ops, Billing, Renewals; who can submit): https://handbook.gitlab.com/handbook/sales/field-operations/requesting-internal-support
- University of Kentucky — Enterprise Salesforce Operations request service (CRM access, new report, data load): https://its.uky.edu/index.php/our-teams/enterprise-salesforce-operations/request-service

**Legal (ServiceNow LSD + Onit):**
- ServiceNow — Legal services on the Employee Center portal (contract review, NDA, PIA, conflict of interest, subpoena, general legal, marketing content review): https://www.servicenow.com/docs/r/SogDT~k7ktsbe1ZYegnaLg/SYwfhFEZ0bEIbptIuO8cfA
- ServiceNow — Non-disclosure agreement requests (NDA intake → auto-generate from template): https://www.servicenow.com/docs/r/etYGEBUVr6RQYKLnfpRuhw/8nt95wiIX4hNwatrKhLxQw
- Onit — Overview of Unity Legal Service Request (NDA, redlining, amendment/renewal/termination, DPA, campaign/brand review): https://onit.screenstepslive.com/a/2035159-overview-of-unity-lsr
- Checkbox — legal intake form fields & single entry point: https://www.checkbox.ai/legal-intake/best-legal-intake-forms-templates-apps-to-streamline-requests

**Marketing intake:**
- Typeform — marketing request form template (project type, deliverables, deadline, conditional logic): https://www.typeform.com/templates/marketing-request-form-template
- Wrike Community — examples of request forms for marketing teams (routing by channel): https://help.wrike.com/hc/en-us/community/posts/360019496793-Examples-of-Request-Forms-for-Marketing-teams
- Pipefy — custom marketing request form & campaign briefing: https://pipefy.com/blog/marketing-request-form/
- Munson Healthcare — Marketing Intake Request Form (one form for marketing, media, print, website/digital): https://www.munsonhealthcare.org/for-employees/resources/marketing-intake-request-form

**Operations / back office:**
- biomérieux — Order Desk Representative (order entry in SAP/ERP, backorders, returns, credit notes, complaints): https://site-3ws21a.biomerieux.com/job/St-Laurent-Order-Desk-Representative-Queb/806333202
- Werfen — Back Office Representative (order management, order blocks, change requests, supply-chain liaison): https://werfen.com/en/back-office-representative-german-language

**ESM / enterprise service management (cross-department patterns & process classification):**
- Atlassian — Jira Service Management ESM overview (HR, legal, facilities, finance templates; request types): https://www.atlassian.com/software/jira/service-management/product-guide/overview
- Atlassian — service request management (portal → approval → fulfil → close): https://www.atlassian.com/software/jira/service-management/product-guide/getting-started/service-request-management
- Seibert Group — real-world ESM use cases for HR, Facilities, Legal: https://us.seibert.group/blog/bringing-service-excellence-everywhere-real-world-esm-use-cases-for-hr-facilities-legal-and-more
- Freshworks — why an enterprise service catalog matters beyond IT (cross-dept items, new-hire setup engine): https://www.freshworks.com/explore-ex/enterprise-service-catalog-implementation-strategy/
- Aptien — what is an employee services catalog (proof-of-employment letter, time off, training enrollment): https://aptien.com/en/kb/articles/what-is-employee-services-catalog

*Note: vendor/university/job-posting pages describe real practice and product capability rather than
independent benchmarks; item titles, categories, and process classifications here are synthesized across
several of these sources to reflect what shared service desks actually surface.*
