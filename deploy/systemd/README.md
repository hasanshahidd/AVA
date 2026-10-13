# AVA register CVE enrichment sweep

Automatic background enrichment (CVSS score+vector, EPSS, CISA-KEV, CWE) for the
vulnerability **register**. Replaces the need to click "Find exploitable" or open
a finding for enrichment to run — a systemd timer drains every un-enriched
register CVE, across every tenant, on its own.

- **Sweep:** `grc/modules/vuln_management/enrichment/sweep.py`
  (`python -m grc.modules.vuln_management.enrichment.sweep`)
- **Scope:** register only — `exclude_adhoc` (managed-inventory findings) +
  `nvd_last_synced_at IS NULL` + CVE-id prefix. Ad-hoc / unlinked / non-CVE rows
  are never touched (lazy-on-open still covers an ad-hoc finding someone opens).
- **Reuses** the shared `ensure_cve_enriched` path. No new data source/engine, no
  hardcoded CVE values.
- **Tenants** are enumerated from the master catalog (`grc_tenants`), so new
  tenants are swept automatically. Override with `ENRICH_SWEEP_TENANTS=slug1,slug2`.
- **Idempotent** (gated on `nvd_last_synced_at IS NULL`), **single-instance**
  (flock at `$ENRICH_SWEEP_LOCK`, default `/tmp/ava-enrich-sweep.lock`),
  **best-effort** (one bad CVE never aborts; never raises out).
- **Pacing:** ~6s per NEW distinct CVE unkeyed (NVD 5/30s); set `NVD_API_KEY` for
  ~0.7s (50/30s). Repeats are served from the 7-day Redis cache (no sleep).

## Install on the box (run after the units are committed/pulled)

```sh
sudo cp /root/AVA/deploy/systemd/ava-enrich-sweep.service /etc/systemd/system/
sudo cp /root/AVA/deploy/systemd/ava-enrich-sweep.timer   /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now ava-enrich-sweep.timer

# Verify
systemctl list-timers ava-enrich-sweep.timer
systemctl status ava-enrich-sweep.service
journalctl -u ava-enrich-sweep.service -n 50 --no-pager

# Kick a run immediately (optional)
sudo systemctl start ava-enrich-sweep.service
```

A full drain of ~400 register CVEs takes ~40 min unkeyed (6s/CVE) or ~5 min with
an `NVD_API_KEY` (0.7s/CVE). Once drained, each fire finds 0 un-enriched and
exits in seconds. New-scan findings land un-enriched (`nvd_last_synced_at` NULL)
and are picked up by the next fire with no extra wiring.
