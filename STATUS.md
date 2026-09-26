# AVA AI-Pentest — Build Status

_Snapshot: 2026-09-23. Sources: `ava-pentest-engine/{DEVELOPMENT_PLAN,MIGRATION,ARCHITECTURE}.md`, `external-tools/manifest.yaml`, and the actual code layout. Honest state, not the plan's aspiration._

Three parts: **① engine** (`ava-pentest-engine/`, portable Python package) · **② external-tools** (git-cloned MCP repos, never imported) · **③ EVA adapter** (`backend/grc/modules/pentest/` + `/pentest` page).

---

## 1. DONE

### Engine package — `ava-pentest-engine/ava_pentest/`
- **models.py** — `Target` (with `network_position`, `cred_ref`, `in_scope`), `Finding`, `Asset`, `Lane`, `ScoreCard`. `Session` lives in `session/store.py`, `Artifact` in `session/ledger.py`.
- **router/** — `classify.py` · `select_lane.py` · `deny.py` (+ `_config.py`, `_legacy.py`). The deterministic safety spine.
- **mcp/** — `registry.py` · `gateway.py` · `client.py` · `executor.py` · `plan.py`.
- **phases/** — `normalize.py` · `triage.py` · `confirm.py`. (Only 3 of the planned recon→cleanup set exist.)
- **session/** — `store.py` (Session, SessionStore) · `ledger.py` (Artifact, ArtifactLedger).
- **reporting/** — `report.py` (PTES/NIST-style template).
- **orchestrator.py** + **config.py**.
- Caveats: `governance/` is an empty `__init__.py` (gate/scope/audit not built yet). Migration is partial — legacy flat files still present (`brain.py`, `llm.py`, `lanes.py`, `mcp_client.py`, `hexstrike_client.py`, `nessus.py`, `evaluate.py`, `pentestgpt_*.py`); `brain/` and `lanes/` sub-packages not yet split out.

### Tests — `ava-pentest-engine/tests/`
8 `test_*.py`, **77 assertions** total, + `stub_mcp_server.py` helper:
`test_deny.py` (11) · `test_engine.py` (14) · `test_mcp.py` (14) · `test_session.py` (13) · `test_phases.py` (11) · `test_report.py` (6) · `test_executor.py` (5) · `test_client.py` (3).

### Real report
From `ai-pentest-eval/ground-truth/my_pc.nessus` → `ava-pentest-engine/reports/192.168.1.13.json` (**344 findings**) + human-readable `my_pc.md`. These are the Nessus baseline imported and rendered through the engine's report path — all `unconfirmed`, `urgent: 0`, `confirmed: 0` (confirm/exploit phases not run live).
_(Note: eval dir is `ai-pentest-eval/`, not `ava-`.)_

### EVA adapter — backend + frontend
- **`backend/grc/modules/pentest/`** — `router.py` + `service.py` (no `schema.py`/`mapping.py` yet). Mounted in `backend/grc/main.py`. Endpoints (all auth-gated):
  - `GET /pentest/fleet` — the fleet from `reports/fleet.json`
  - `GET /pentest/assessments` — stored reports
  - `GET /pentest/assessment/{host}` — one report
  - `GET /pentest/run/{host}` — deterministic routing decision (internal → internal-host lane, **HexStrike denied**; else external) + stored findings.
- **`grc-frontend/src/app/(dashboard)/pentest/page.tsx`** — target picker (from asset inventory), Run button → `/pentest/run/{host}`, 18-stage pipeline visual (stages 11–16 exploit = gated/pending), MCP-fleet cards that react to a run (selected / denied / dimmed), findings table + tool drawer. Routing is real; the scan itself is animated with timers over stored data.

### MCP fleet cloned — 15 repos under `external-tools/<lane>/{find,exploit}/`
| Lane | find | exploit |
|---|---|---|
| external | `burp-mcp`; `_dual/hexstrike-ai`, `_dual/mcp-for-security` (sqlmap) | (dual repos above) |
| internal-host | `nessus-mcp-server`, `openvas-mcp-server` | `metasploit-framework`, `netexec-mcp` |
| internal-ad | `bloodhound-mcp-ai` | `adstrike`, `hashcat-mcp` |
| cloud | `prowler`, `roadrecon-mcp`, `steampipe-mcp` | — |
| container | `trivy-mcp` | — |
| code | `semgrep-mcp` | — |

Plus the brain **`PentestGPT/`** (top-level) and 4 build-gap tools in `_build/` (pacu, roadtools, peirates, graphrunner) — no MCP exists for those; we wrap them later.

---

## 2. IN PROGRESS

**Fleet install on Ubuntu/WSL** — `external-tools/setup_fleet.sh` (install-only; runs no scan/exploit):
- toolchains via apt: python/node/go/java/rust, nmap/masscan, jq, pipx, uv;
- FIND binaries: projectdiscovery (subfinder/dnsx/naabu/httpx/katana/nuclei), semgrep, trivy, prowler, gitleaks;
- EXPLOIT binaries: netexec, impacket (sqlmap/hashcat/metasploit left as noted manual steps);
- per-repo MCP deps: npm / pip (venv) / go build / gradle for every cloned repo.

Why Ubuntu: the Windows host has only Python + Node, and several MCPs are Linux-only (AdStrike) or wrap Linux tools; isolation is also mandatory (HexStrike + sqlmap have unauth-RCE, PentestGPT runs FULL_ACCESS).

---

## 3. NEXT (in order)

1. **Verify which MCP servers actually start on Ubuntu.** Only HexStrike is proven runnable today; the rest are cloned/verified but not yet booted with their toolchain.
2. **Wire PentestGPT ↔ MCPs** via `CodexConfig(config_overrides=['mcp_servers.hexstrike.command=...', 'mcp_servers.hexstrike.args=[...]'])` so the brain actually sees the tools — fixes the "Found 0 tools" bug (both `UnifiedAgent` are built with no tool server). There is **no** SDK `tools=` kwarg.
3. **Connect the frontend "Run" to the real engine** — a real analyze endpoint that scans, replacing today's timer-animated run over stored reports.
4. **Exploit lane stays human-gated** — pipeline stages 11–16 gated, deny rule (internal → never HexStrike) enforced before any connect.

---

## 4. Runtime & scope
- **Hosted on Ubuntu** (WSL2 / ephemeral container). Engine (Python) may run on the host; MCP servers + tool binaries live in the sandbox. Isolation is mandatory, not optional.
- **Deliverable = proof of exploitability + evidence** (assurance), not a persistent foothold. Loop: find → confirm → exploit-to-*prove* → evidence → pivot via harvested creds.
- **Exploit execution is human-triggered** — tiered gate surfaces in the UI; nothing dangerous fires without a click. C2/persistence lane is off by default, hard-gated.
