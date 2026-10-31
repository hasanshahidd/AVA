-- Cleanup: synthetic/reserved 2026 CVE rows polluting the CAIVA vulnerability register.
-- DB: cyber_ava   tenant: ava   verified 2026-10-31.
--
-- WHY THESE ROWS ARE BOGUS
--   source = 'ai-pentest:nmap' ingests nmap `--script vulners` output verbatim (see
--   backend/grc/modules/pentest/linux_scan_tools.py :: _parse_nmap). The vulners feed returned
--   NON-PUBLISHED / reserved 2026 CVE IDs for the Metasploitable2 lab host (asset 68, 172.17.0.2):
--   contiguous blocks such as CVE-2026-59995..60002, CVE-2026-6469..6479, CVE-2026-14662..14681 —
--   a signature real per-service scan results never produce. The 2024/2025 nmap CVEs from the SAME
--   feed are GENUINE (CVE-2024-6387 regreSSHion, CVE-2025-1094 Postgres, etc.) and are NOT touched.
--   These bogus rows are correctly left UNARMED (harmless to exploitation) but inflate the
--   critical/exploitable headline counts and reports.
--
-- SCOPE: 120 rows, 93 distinct CVE IDs, all source='ai-pentest:nmap', all CVE-2026-*.
--   2026 is the current year, so "future year" cannot filter these; the year+contiguity+lab-target
--   evidence is what confirms them synthetic. The source-level code guard added on this branch only
--   rejects FUTURE-year ids (zero false positives); it does NOT retroactively remove these current-year
--   rows — hence this one-off cleanup. See report: the TRUE source (the vulners feed surfacing reserved
--   ids) needs an owner decision (real keyed vulners API / NVD-existence filter / accept as demo data).

-- ============================================================================================
-- STEP 1 — REVIEW (read-only). Run this first; confirm it returns the 120 synthetic rows.
-- ============================================================================================
SELECT id, cve_id, source, severity, title, created_at
FROM grc_vulnerabilities
WHERE source = 'ai-pentest:nmap'
  AND cve_id ~ '^CVE-2026-[0-9]+$'
ORDER BY cve_id;

SELECT count(*) AS rows_to_delete, count(DISTINCT cve_id) AS distinct_ids
FROM grc_vulnerabilities
WHERE source = 'ai-pentest:nmap'
  AND cve_id ~ '^CVE-2026-[0-9]+$';

-- ============================================================================================
-- STEP 2 — DELETE. ***DO NOT AUTO-RUN.*** Owner review required. Run inside a transaction and
-- confirm the row count equals STEP 1 before COMMIT. (If a FK references grc_vulnerabilities,
-- delete/cascade the child links first — e.g. vuln<->asset link rows for these ids.)
-- ============================================================================================
-- BEGIN;
-- DELETE FROM grc_vulnerabilities
-- WHERE source = 'ai-pentest:nmap'
--   AND cve_id ~ '^CVE-2026-[0-9]+$';
-- -- verify count, then:
-- COMMIT;   -- or ROLLBACK;

-- ============================================================================================
-- STEP 3 — OWNER REVIEW, SEPARATE SOURCES (NOT included in the DELETE above; classify first).
--   CVE-2026-4480  source='ai-pentest:hexstrike-arsenal'  — a nuclei template id (javascript/critical);
--                   verify whether that template is legitimate before removing.
--   CVE-2026-9852  source IS NULL, title 'hasan'          — a hand-entered manual test row.
-- ============================================================================================
SELECT id, cve_id, source, severity, title, created_at
FROM grc_vulnerabilities
WHERE cve_id ~ '^CVE-2026-'
  AND (source <> 'ai-pentest:nmap' OR source IS NULL)
ORDER BY source NULLS LAST, cve_id;
