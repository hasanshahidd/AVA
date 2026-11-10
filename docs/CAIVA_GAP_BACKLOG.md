# CAIVA — Gap Backlog (what's missing)

Proactive, evidence-based gap analysis of the CAIVA cyber-assurance product, so gaps
surface here before a customer finds them. Every item was confirmed by reading the code
(path cited) or a read-only check on prod. Produced Nov 10 2026 against `origin/main @ da4e82b`.

Scope note: CAIVA is cyber-only by design — NO compliance frameworks (SOC2/ISO/NIST),
no IoT, no big PCI-requirements module, no Frappe helpdesk. It keeps the CIS benchmark
library + SCF control library + helpdesk. Those are intentional and are NOT gaps.

Status key: `missing` · `partial` (exists but incomplete) · `in-progress` (being built) · `done`.

---

## Executive summary — top 10, in suggested build order

1. **No scheduler deployed → scheduled jobs are dormant.** [CONFIRMED on prod] Cheapest, highest-impact fix.
2. **`/grc/tenants` writes had no permission check** — any logged-in user could create/edit/delete tenants. **[DONE this session, pending deploy]**
3. **Sign-in below bank bar:** no MFA for local users, no SAML/generic OIDC (Entra only), logout doesn't revoke tokens.
4. **Can't ingest the bank's existing scanners** (Tenable.sc, Qualys) and no password-vault (CyberArk/Delinea/HashiCorp) for scan logins.
5. **EDR/identity connectors pull alerts only, not device lists** — no CAASM coverage gap ("in CrowdStrike but not in CAIVA").
6. **Audit trail not immutable/exportable, no retention policy**; finding & asset History miss system events.
7. **No outbound integration surface:** no API keys/tokens, no webhooks, no SIEM/syslog forwarding, no Teams/Slack alerting.
8. **Customizable workflow engine has no builder UI** and doesn't run on-prem; actions target old GRC, not CAIVA.
9. **Remediation governance thin:** severity-only SLAs, manual SLA-breach escalation, single-approver exceptions, no CIS deviation/waiver.
10. **Day-two ops:** no customer backup/restore, no upgrade path (no Alembic), static health check, permanent asset delete (no soft-delete/approval).

Already in progress in a separate session (do not duplicate): Broadcom Service Desk + CMDB connectors; asset change-history (dedicated page + inventory "Changes" column + click-through + alert-on-change).

---

## 0. Cross-cutting — Scheduler (CRITICAL, confirmed)

| Gap | Evidence | Size |
|---|---|---|
| **No Celery beat / scheduler process is deployed.** `celery_app.py:174` defines a beat schedule (KEV/EPSS refresh, exception expiry, discovery schedule, connector sync hourly, cloud sync 6-hourly, CMDB sync). But `run-worker.sh` and `onprem/templates/caiva-worker.service` start ONLY `grc.modules.pentest.tasks`. **Prod check (read-only SSH):** the only celery process is the pentest worker; the only timer is a hand-added `ava-epss-sweep.timer`. So scheduled network discovery, connector sync, KEV/EPSS refresh on open findings, scheduled/emailed reports and exception expiry **never fire on their own.** | `celery_app.py:174`, `run-worker.sh`, `onprem/templates/caiva-worker.service`; prod `ps aux`/`systemctl list-timers` | S–M |

> Fix once, benefits everywhere: add a `caiva-beat` service + a `-Q parsing` queue to the worker, both in prod and in the on-prem installer. ⚠ When enabled it will immediately run every overdue job — do it in a quiet window (restarts/scans have collided before).

---

## 1. Assets & Inventory

### Critical
| Gap | Why a bank cares | Competitor | Evidence | Size |
|---|---|---|---|---|
| Permanent cascade asset delete, no soft-delete/approval | Banks need record retention + maker-checker | ServiceNow ITAM | `assets_router.py:1877,657` → `_purge_asset_references` + `db.delete`; no "approval"/"maker-checker" | M |

### Important
| Gap | Competitor | Evidence | Size |
|---|---|---|---|
| SNMP inventory is v2c only (bank standard is SNMPv3) | Lansweeper, Armis | `snmp.py:201` registered `snmp_v2c`, version hard-coded | M |
| No unauthorised/prohibited software detection (allow/deny list) — CIS Control 2 | Lansweeper, Defender | no "denylist"/"unauthorized" in assets/licenses | M |
| No per-package software EOL/EOS (OS-level EOL exists) | Lansweeper, Qualys | `SoftwarePanel.tsx:449` says not tracked | M |

### Nice-to-have
| Gap | Evidence | Size |
|---|---|---|
| No free-form tags / custom fields on assets | `_14_it_asset_inventory.py` | M |
| No GCP inventory collector (AWS/Azure/DO/K8s exist) | `platform_collectors/` has no GCP | M |
| Vendor warranty lookup (dates are manual/import only) | `warranty_expiry` read/write only | M |

---

## 2. Integrations / Connectors

### Critical
| Gap | Why a bank cares | Competitor | Evidence | Size |
|---|---|---|---|---|
| No Tenable.sc / Qualys import | They're the scanners banks already own | Axonius, Tenable | `adapter_factory.py` knows only nessus/tenable/rapid7; no `.sc /rest/`; qualys only in enums | M |
| EDR/identity connectors pull alerts/logs only, not devices | No CAASM coverage checks | Axonius | CrowdStrike `/detects`, Defender `/api/alerts`, SentinelOne `/threats`, Entra `signIns`, Okta `/logs`; no edr/identity branch in `sync_runner._dispatch_sync` | M–L |
| No endpoint-mgmt / virtualisation connectors (SCCM/MECM, Intune, Jamf, Workspace ONE, vCenter, Hyper-V) | Banks' real source of truth for managed endpoints/VMs | Axonius, Lansweeper | not in `connectors/providers/` or `platform_collectors` | M each |
| Ticketing beyond ServiceNow/BMC/Halo (Jira, ManageEngine SDP, Freshservice) | ManageEngine common regionally; Jira in IT/sec | Axonius, Tenable | no backend provider; Jira only in frontend catalogue | M each |
| Broadcom Service Desk (CA SDM) + Broadcom CMDB | Owner-requested | — | **in-progress (separate session)** | M |

### Important
| Gap | Evidence | Size |
|---|---|---|
| No outbound SIEM forwarding (syslog/CEF/Splunk HEC) for CAIVA findings & audit | Splunk/QRadar only `fetch_events`; no `SysLogHandler` | S–M |
| No API keys / service accounts for third-party access | `get_current_user` accepts only user cookie/bearer; no API-key model | M |
| No notification channel wired (Teams/O365/Zoom have `send_message`, nothing calls it); no Slack/PagerDuty/webhook | only providers/`base.py` define `send_message` | M |
| Firewall connectors missing (Palo Alto, Fortinet) | `cisco.py` netdev SSH only | M |

### Nice-to-have
| Gap | Evidence | Size |
|---|---|---|
| Orphan `/connectors` page: 40 "Not connected" providers, SOC2 wording, old "Verity" branding, reachable by URL (demo risk) | `connectors/page.tsx`, `connector-catalogue.ts:1` | S (delete) |

---

## 3. Vulnerability, Threat, Pentest & CIS

### Critical
| Gap | Why a bank cares | Competitor | Evidence | Size |
|---|---|---|---|---|
| No scheduled vuln / pentest / CIS scans (see §0) | Regulators expect continuous scanning | Tenable, Qualys | `schedule_cron` read nowhere outside router/models; no beat | M |
| KEV/EPSS never re-checked on open findings | A newly-KEV CVE stays non-KEV forever | Tenable VPR, Qualys | `deploy/systemd/README.md` "one-time"; `kev_cache.py:27` loads once | S |
| No authenticated web-app scanning, no API-spec (OpenAPI) scanning | Banking portals/APIs sit behind login | Tenable WAS, InsightAppSec | `web_scan_tools.py:25,1333` `wapiti-auth` not wired; creds dropped `service.py:7427` | M |
| Can't ingest findings from scanners the bank owns (.nessus, Qualys XML, Burp, SARIF) | Banks already run Qualys/Tenable/Defender | Tenable One, Rapid7 | import is CSV/XLSX only; `adapter_factory.py:13` | L |
| Scan logins can't come from a password vault (CyberArk/Delinea/HashiCorp) | Banks forbid storing privileged creds in third-party tools | Tenable, Qualys | no cyberark/conjur/delinea/vault in scan-cred code | M |

### Important
| Gap | Evidence | Size |
|---|---|---|
| Finding History misses system events (scanner auto-close/reopen, KEV change) | `entity_extras_router.py:113` per-finding audit only; scanner close logged vs connection | S |
| Due dates severity-only (no tighter SLA for KEV/internet-facing/crown-jewel) | SLA model holds only `severity`+`remediation_days` (`_23_*.py:442`) | S |
| SLA-breach escalation is manual | only `POST /escalations/run-sla-check`; no scheduled job | S |
| Exceptions: single approver, per-finding only (no 2-level, no bulk rule) | `vuln_exception.py` requested→approved by one; engine multi-approval unused | M |
| CIS: no per-rule approved deviation/waiver; no alert when a passing rule starts failing | no waiver/deviation/exempt in `compliance_plugins`; no run-to-run compare | M |
| No Jira ticketing | no Jira provider; `create_ticket` only ServiceNow/BMC/Halo | S |
| No patch-deployment integration (SCCM/Intune/WSUS/Tanium) | names only as text in `plan_generator.py` | M |
| Change windows apply only to network discovery (not exploit/CIS) | `is_in_blackout` used only by discovery | S |

### Nice-to-have
| Gap | Evidence | Size |
|---|---|---|
| No lookalike/typosquat domain or brand-phishing monitoring | no dnstwist/typosquat | M |
| No leaked-credential / dark-web monitoring | no hibp/dehashed/dark-web | M |
| No breach & attack simulation (did EDR/SIEM catch it?) | no caldera/atomic-red | L |
| SBOM built internally but no user download | CycloneDX in `pentest/service.py:1180`, no download | S |

---

## 4. Platform, Identity & Enterprise Readiness

### Critical
| Gap | Why a bank cares | Competitor | Evidence | Size |
|---|---|---|---|---|
| `/grc/tenants` writes needed only a login (any user could create/edit/delete tenants) | Security hole | — | was `require_auth` at `tenants_router.py:28,71,105` | **DONE (this session, pending deploy)** |
| No MFA for local users | Regulators expect MFA on admin/security tools | all | `mfa_enabled` is an Entra-sync field only; no TOTP/pyotp flow | M |
| SSO is Entra-only (no SAML / generic OIDC) | Banks run ADFS, Okta, Ping | ServiceNow, Qualys | `sso_router.py:77` hardcodes Graph scope; no "saml" | M |
| Audit trail not tamper-evident, no export, no retention policy | Inspection evidence, log immutability | ServiceNow, Qualys | no hash chain in `audit_logger.py`; `/admin/audit-logs` no export | M |
| No customer backup/restore or DR tooling | BCP/DR is mandatory | Tenable SC, ServiceNow | `pg_dump` only in installer bundle seeding | M |
| No upgrade path (no Alembic; hand-written column adds) | Each release is a manual op | all | `onprem/` install+uninstall only; `identity/schema_migrations.py` | M–L |

### Important
| Gap | Evidence | Size |
|---|---|---|
| Logout doesn't revoke tokens; no session list | `logout()` only deletes cookie (`auth_router.py:597`); token valid 24h | S–M |
| No Teams/Slack alerting, no alert-rule model | `msteams.py` unused outside provider | M |
| Help Desk SLA breach not proactively warned/escalated | `sla.py:504` inline; breach checker watches GRC Issue not HD tickets | S–M |
| Email-to-ticket not automatic (admin must click poll) | `mail.py:672` `/email/poll` only caller | S |
| No KMS/Vault; the key-rotation script `crypto.py` names is missing | `rotate_secrets.py` not found | S |
| No product licence / usage metering (on-prem commercial control) | `license_management` is software-asset licensing | M |
| Static health check (can't see DB/Redis failure) | `main.py:399` returns healthy unconditionally; no Prometheus | S |

### Nice-to-have
| Gap | Evidence | Size |
|---|---|---|
| No localization (Urdu/Arabic, RTL) | no i18n lib in grc-frontend | L |
| HD time tracking, ticket merge, major incident, on-call, change-freeze calendar | greps empty | M each |
| No HA/clustering (single-node installer, no PG replication) | installer single-node | L |
| No IP allowlist / rate limiting | no slowapi/allowlist | S |

---

## 5. Customizable workflow engine (owner-flagged)

**What exists:** a substantial backend engine — definitions with create/update + versioning + rollback
(`workflow_engine/routers/definitions.py:715,826,1003`), condition evaluator, state machine, timers,
AI draft generator, in-app/email notifications, audit-log-polled triggers + threshold checks
(agent offline, CIS pass-rate drop), and 10 seeded templates (`seed_workflow_engine_defaults.py:15`).

**What's missing (this IS the gap the owner means):**
| Gap | Evidence | Size |
|---|---|---|
| No builder UI — users can't create/edit workflows | `workflowEngineApi` (`lib/api.ts:4155`) never called from any page; no workflow route under `(dashboard)` | L (canvas) / M (form "when X, if Y, then Z") |
| Doesn't run on-prem | `backend.env.tpl:51` `DISABLE_EMBEDDED_WORKFLOW_RUNTIME=1`; no process starts the runtime | S |
| Actions target old GRC, not CAIVA | `create_incident` writes ERM `RiskIncident` (`action_handlers.py:3428`), not a Help Desk ticket; no create-ticket/Teams/Slack/webhook/auto-remediate action | M |
| Auto-ticketing is env-flag driven, not user rules | `HELPDESK_AUTO_TICKET` etc. in env, not configurable rules | S |

---

_Caveats: the scheduler verdict was checked against repo deploy files + a read-only prod check; everything
else is repo evidence only. Not reviewed in depth: AI Pentest exploit-lane internals, Risk Posture scoring,
accessibility/mobile/white-labelling, GRC repo, CMDB field parity._
