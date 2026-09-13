# DEFERRED — Security Assessment / MCP Pen-testing (Priority 5)

**Status:** built as a working Stage-1 prototype, then **deferred** on 2026-09-13 to
focus on higher priorities (Control Library → AWS/VPN → Website). This folder is
**outside the `grc` package**, so it is NOT imported or served by the app. Nothing
in the live product depends on it.

## Priority order (owner, 2026-09-13)
1. Separation of product platform — DONE (Ava split from GRC)
2. **Control Library** — bring GRC's control library into Ava; used at CTEM **stage 4 (validation)** ← current focus
3. AWS tenant + VPN for client scanning
4. Website
5. **Security Assessment / MCP pen-testing** — THIS (Fable + HexStrike) — deferred

## What was built (the "Fable" attack pipeline, Stage 1 = FIND)
A separate module `grc/modules/attack_pipeline/` (now moved here) implementing the
diagram: **IT Asset Inventory → Fable classifies the asset → picks the MCP by class +
credential-need → runs it → vulnerabilities.** (Stage 2 = exploit was not built.)

Files (here under `attack_pipeline/`):
- `fable.py` — the core:
  - `classify(asset) -> Classification` — the brain. Reads real `ITAsset` fields
    (`platform_kind` authoritative; else derives from `asset_type`/`cloud_resource_id`/
    software/os/exposure) → `device_class` (host|database|cloud|network|identity|cluster|
    web|external-surface|unknown), `needs_creds` (deep/authenticated vs external/surface),
    `credential_kind`, rationale + signals. Verified on 20 real `cyber_ava` assets:
    19 EASM external hosts → surface/no-creds → HexStrike; 1 internal Windows server →
    needs-creds → Nessus. (Bug fixed: `platform_kind` must win over software-token DB derivation.)
  - `Capability` ABC with declarative metadata (`fits_classes`, `needs_creds`,
    `can_exploit`, `kind`) + `NessusCapability` (deep/creds, reuses
    `integrations.adapters.adapter_factory.build_adapter` which absorbs the connector
    credential vault, + `adapter.get_asset_vulnerabilities(hostname/ip)` — pull-only) +
    `HexStrikeCapability` (surface/no-creds, HTTP to the local HexStrike Flask engine).
  - `Fable` orchestrator — `classify → select(by class + creds posture) → available() →
    run first available → {classification, considered, chosen, findings, needs_action}`.
- `router.py` — `GET /attack-pipeline/capabilities`, `GET /attack-pipeline/classify?asset_id=`,
  `POST /attack-pipeline/run?asset_id=` (auth + `vulnerabilities:vulnerability_register:view`).
- `__init__.py`.

## How it was verified
- Classification correct on 20 real assets (credential-driven MCP routing).
- End-to-end `run_stage1` exercised the real Nessus adapter + availability/fallback:
  `#164` internal host → chose Nessus; `#166` EASM host → HexStrike (down) → fell back to
  Nessus. Findings 0 (local Nessus had no completed scan for those hosts; HexStrike not up).
- All 3 endpoints registered; backend healthy.

## Environment learnings (for resume)
- **HexStrike** (`C:/Users/HP/OneDrive/Desktop/hexstrike-ai`): Flask engine on
  `127.0.0.1:8888`, **unauthenticated RCE — bind localhost only, never 0.0.0.0**. Start with
  UTF-8 forced (else it crashes on emoji logs on the Windows cp1252 console):
  `PYTHONUTF8=1 PYTHONIOENCODING=utf-8 hexstrike-env/Scripts/python.exe hexstrike_server.py`.
  Its startup tool-probe is slow and blocks `/health` briefly (single-threaded dev server).
  Most of its 150+ tools are Kali/Linux binaries absent on Windows → need WSL2/Docker or a
  Linux runner for real power; Windows-native subset: nmap/nuclei/sqlmap/ffuf IF installed.
- **Nessus**: a real `IntegrationConnection` exists in `cyber_ava` (id 6, active, `https://127.0.0.1`).
  The adapter is **pull-only** (no launch-scan) — reads a host's vulns from completed scans.
- **MCP landscape** (research): real MCP servers exist for Nessus, Shodan, VirusTotal,
  Prowler, Metasploit, Nuclei, plus collections (FuzzingLabs/mcp-security-hub, etc.).
  Windows-frictionless Stage-1 finders: Nessus (owned) + Shodan + VirusTotal + Nuclei.

## To resume (priority 5)
1. `mv _deferred_stage5_attack_pipeline/attack_pipeline backend/grc/modules/attack_pipeline`
2. In `backend/grc/main.py`: re-add `from .modules.attack_pipeline.router import router as
   attack_pipeline_router` (by the vuln-management import) and
   `app.include_router(attack_pipeline_router)` (after `vuln_management_router`).
3. Restart the backend. Recon detail: this session's transcript + the workflow output at
   `…/tasks/wom782cv4.output` (full architecture/inventory/HexStrike/landscape/reuse analysis).

**Do not scan third-party hosts.** The seed EASM assets (liztek.ca, lums.edu.pk …) are not
owned — any live scan/exploit needs the target owner's authorization or an owned/authorized target.
