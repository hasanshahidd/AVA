"""P0b repo-scan LINKAGE — the ava-repo-scan arsenal registry (repo_scan_tools) + its shape contract.

STANDALONE: imports ONLY repo_scan_tools (NOT service.py — that module is mid-edit; the dispatcher wiring is
deferred). Deterministic + offline: each parser is fed CAPTURED sample tool output and we assert the
normalized finding rows (shape, severity, component, cve, corroboration-ready source slug). No live scan, no
docker, no repo checkout. Also asserts garbage-safety (never raises / never fabricates), that every registry
argv is bounded + read-only (no push/write/commit), and that no wired tool is also listed as deferred/missing.
"""
import json

import grc.modules.pentest.repo_scan_tools as rst


# ---- row shape contract (matches web_scan_tools._row so dedup + ingest consume it unchanged) ----------
def _assert_shape(rows):
    for r in rows:
        assert r["kind"] == "repo"
        assert set(("vid", "source_slug", "title", "affected_url", "fields")) <= set(r)
        assert r["vid"].startswith("AIPT-REPO-") and len(r["vid"]) <= 50
        f = r["fields"]
        assert f["severity"] in rst._SEV
        assert f["source"].startswith("ai-pentest:") and f["plugin_family"] == "AI Pentest"
        assert f["status"] == "open" and f["title"]


T, A, U = "/work", 7, "https://github.com/acme/app.git"


# ======================================================================================================
# SECRET SCANNERS
# ======================================================================================================
def test_gitleaks():
    out = json.dumps([
        {"RuleID": "aws-access-token", "Description": "AWS Access Key", "File": "src/config.py",
         "StartLine": 12, "Secret": "AKIAIOSFODNN7EXAMPLE", "Match": "key=AKIA..."},
        {"RuleID": "generic-api-key", "File": "app/settings.js", "StartLine": 5, "Secret": "abcd1234secret"},
    ])
    rows = rst.parse_tool("gitleaks", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 2 and all(r["fields"]["severity"] == "high" for r in rows)
    r0 = rows[0]
    assert r0["affected_component"] == "src/config.py"
    # the raw secret is REDACTED, never dumped verbatim
    assert "AKIAIOSFODNN7EXAMPLE" not in r0["fields"]["evidence"] and "chars)" in r0["fields"]["evidence"]


def test_trufflehog_verified_is_critical():
    out = "\n".join([
        "banner line ignored",
        json.dumps({"DetectorName": "AWS", "Verified": True, "Raw": "AKIAABC123SECRETKEY",
                    "SourceMetadata": {"Data": {"Filesystem": {"file": "creds.env", "line": 3}}}}),
        json.dumps({"DetectorName": "Slack", "Verified": False, "Raw": "xoxb-notreal",
                    "SourceMetadata": {"Data": {"Filesystem": {"file": "bot.py", "line": 9}}}}),
    ])
    rows = rst.parse_tool("trufflehog", out, T, A, U)
    _assert_shape(rows)
    by = {r["affected_component"]: r["fields"]["severity"] for r in rows}
    assert by == {"creds.env": "critical", "bot.py": "high"}
    aws = next(r for r in rows if r["affected_component"] == "creds.env")
    assert "AKIAABC123SECRETKEY" not in aws["fields"]["evidence"]  # redacted


def test_detect_secrets():
    out = json.dumps({"version": "1.4.0", "results": {
        "settings.py": [{"type": "Secret Keyword", "line_number": 20, "hashed_secret": "deadbeefcafe"}],
        "empty.txt": [],
    }})
    rows = rst.parse_tool("detect-secrets", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1
    assert rows[0]["fields"]["severity"] == "medium" and rows[0]["affected_component"] == "settings.py"


# ======================================================================================================
# SAST
# ======================================================================================================
def test_semgrep_severity_map():
    out = json.dumps({"results": [
        {"check_id": "python.lang.security.audit.exec-use", "path": "app/run.py",
         "start": {"line": 44}, "extra": {"severity": "ERROR", "message": "Detected exec()",
                                          "metadata": {"cwe": ["CWE-95"]}}},
        {"check_id": "generic.style", "path": "app/x.py", "start": {"line": 1},
         "extra": {"severity": "WARNING", "message": "style"}},
    ]})
    rows = rst.parse_tool("semgrep", out, T, A, U)
    _assert_shape(rows)
    sev = [r["fields"]["severity"] for r in rows]
    assert sev == ["high", "medium"]
    assert rows[0]["affected_component"] == "app/run.py" and "CWE-95" in rows[0]["fields"]["evidence"]


def test_bandit():
    out = json.dumps({"results": [
        {"filename": "app/db.py", "line_number": 7, "issue_severity": "HIGH", "test_id": "B608",
         "issue_text": "Possible SQL injection", "issue_confidence": "MEDIUM"},
    ]})
    rows = rst.parse_tool("bandit", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "high"
    assert rows[0]["affected_component"] == "app/db.py"


def test_gosec_carries_cwe():
    out = json.dumps({"Issues": [
        {"severity": "HIGH", "confidence": "HIGH", "details": "Potential hardcoded credentials",
         "file": "main.go", "line": "31", "rule_id": "G101", "cwe": {"id": "798"}},
    ]})
    rows = rst.parse_tool("gosec", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "high"
    assert rows[0]["cve_id"] == "CWE-798" and rows[0]["affected_component"] == "main.go"


# ======================================================================================================
# SCA / DEPENDENCY-CVE / SBOM
# ======================================================================================================
def test_syft_feeder_info_row():
    out = json.dumps({"artifacts": [
        {"name": "requests", "version": "2.25.0", "type": "python"},
        {"name": "flask", "version": "1.1.2", "type": "python"},
    ]})
    rows = rst.parse_tool("syft", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "info"
    assert "2 components" in rows[0]["fields"]["title"] and "requests@2.25.0" in rows[0]["fields"]["evidence"]


def test_grype():
    out = json.dumps({"matches": [
        {"vulnerability": {"id": "CVE-2021-33503", "severity": "High"},
         "artifact": {"name": "urllib3", "version": "1.26.4"}},
        {"vulnerability": {"id": "GHSA-xxxx", "severity": "Critical"},
         "artifact": {"name": "lodash", "version": "4.17.11"}},
    ]})
    rows = rst.parse_tool("grype", out, T, A, U)
    _assert_shape(rows)
    by = {r["fields"]["severity"]: r for r in rows}
    assert set(by) == {"high", "critical"}
    cve = next(r for r in rows if r["source_slug"] == "grype" and r["cve_id"])
    assert cve["cve_id"] == "CVE-2021-33503" and cve["affected_component"] == "urllib3@1.26.4"
    # a GHSA id is not a CVE -> cve_id stays None
    ghsa = next(r for r in rows if "lodash" in (r["affected_component"] or ""))
    assert ghsa["cve_id"] is None


def test_trivy_handles_null_vulns():
    out = json.dumps({"Results": [
        {"Target": "package-lock.json", "Vulnerabilities": [
            {"VulnerabilityID": "CVE-2020-8203", "Severity": "HIGH", "PkgName": "lodash",
             "InstalledVersion": "4.17.15", "Title": "Prototype pollution"}]},
        {"Target": "empty", "Vulnerabilities": None},
    ]})
    rows = rst.parse_tool("trivy", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["cve_id"] == "CVE-2020-8203"
    assert rows[0]["affected_component"] == "lodash@4.17.15" and rows[0]["fields"]["severity"] == "high"


def test_osv_scanner_severity_from_group():
    out = json.dumps({"results": [
        {"source": {"path": "go.mod"}, "packages": [
            {"package": {"name": "golang.org/x/net", "version": "0.0.1", "ecosystem": "Go"},
             "vulnerabilities": [{"id": "GO-2023-1234", "summary": "HTTP/2 flood"}],
             "groups": [{"ids": ["GO-2023-1234"], "max_severity": "7.5"}]}]},
    ]})
    rows = rst.parse_tool("osv-scanner", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1
    assert rows[0]["fields"]["severity"] == "high"  # CVSS 7.5 -> high
    assert rows[0]["affected_component"] == "golang.org/x/net@0.0.1"


def test_pip_audit_both_shapes():
    # newer dict shape
    d = json.dumps({"dependencies": [
        {"name": "jinja2", "version": "2.11.2", "vulns": [
            {"id": "CVE-2020-28493", "fix_versions": ["2.11.3"], "description": "ReDoS"}]},
        {"name": "clean", "version": "1.0", "vulns": []},
    ]})
    rows = rst.parse_tool("pip-audit", d, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["cve_id"] == "CVE-2020-28493"
    assert "2.11.3" in rows[0]["fields"]["evidence"]
    # older bare-list shape parses too
    lst = json.dumps([{"name": "pyyaml", "version": "5.1", "vulns": [{"id": "CVE-2020-14343"}]}])
    rows2 = rst.parse_tool("pip-audit", lst, T, A, U)
    assert len(rows2) == 1 and rows2[0]["cve_id"] == "CVE-2020-14343"


def test_snyk_gated_tool_parses_when_fed():
    out = json.dumps({"vulnerabilities": [
        {"id": "SNYK-JS-LODASH-567746", "severity": "medium", "packageName": "lodash",
         "version": "4.17.15", "title": "Prototype Pollution", "identifiers": {"CVE": ["CVE-2019-10744"]}},
    ]})
    rows = rst.parse_tool("snyk", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "medium"
    assert rows[0]["cve_id"] == "CVE-2019-10744" and rows[0]["affected_component"] == "lodash@4.17.15"


# ======================================================================================================
# IaC
# ======================================================================================================
def test_checkov_dict_and_list_shapes():
    d = json.dumps({"results": {"failed_checks": [
        {"check_id": "CKV_AWS_20", "check_name": "S3 bucket not public", "file_path": "/main.tf",
         "severity": "HIGH", "resource": "aws_s3_bucket.data", "file_line_range": [10, 20]},
        {"check_id": "CKV_AWS_20", "check_name": "S3 bucket not public", "file_path": "/main.tf",
         "severity": "HIGH", "resource": "aws_s3_bucket.data", "file_line_range": [10, 20]},  # dup -> deduped
    ]}})
    rows = rst.parse_tool("checkov", d, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "high"
    assert rows[0]["affected_component"] == "aws_s3_bucket.data"
    # per-framework LIST shape also parses
    lst = json.dumps([{"check_type": "terraform", "results": {"failed_checks": [
        {"check_id": "CKV_AWS_21", "check_name": "Versioning", "file_path": "/s3.tf",
         "severity": None, "resource": "aws_s3_bucket.logs"}]}}])
    rows2 = rst.parse_tool("checkov", lst, T, A, U)
    assert len(rows2) == 1 and rows2[0]["fields"]["severity"] == "medium"  # null severity -> medium default


def test_kics():
    out = json.dumps({"queries": [
        {"query_name": "S3 Bucket Without Encryption", "severity": "MEDIUM", "files": [
            {"file_name": "s3.tf", "line": 4, "expected_value": "encryption enabled"},
            {"file_name": "s3b.tf", "line": 9}]},
    ]})
    rows = rst.parse_tool("kics", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 2 and all(r["fields"]["severity"] == "medium" for r in rows)
    assert {r["affected_component"] for r in rows} == {"s3.tf", "s3b.tf"}


def test_noseyparker_redacts_secret():
    # report --format json: array of findings; match carries provenance.path, location line, snippet.matching
    out = json.dumps([
        {"rule_name": "GitHub Personal Access Token", "num_matches": 1, "matches": [
            {"provenance": [{"kind": "file", "path": "creds.txt"}],
             "location": {"source_span": {"start": {"line": 2, "column": 12}}},
             "snippet": {"matching": "ghp_1234567890abcdefghijklmnopqrstuvwx12"}}]},
    ])
    rows = rst.parse_tool("noseyparker", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "high"
    assert rows[0]["affected_component"] == "creds.txt"
    assert "ghp_1234567890abcdefghijklmnopqrstuvwx12" not in rows[0]["fields"]["evidence"]  # redacted


# ======================================================================================================
# CI/CD + container
# ======================================================================================================
def test_hadolint_level_map():
    out = json.dumps([
        {"code": "DL3002", "line": 5, "column": 1, "level": "error", "message": "Last USER should not be root",
         "file": "Dockerfile"},
        {"code": "DL3009", "line": 2, "column": 1, "level": "info", "message": "Delete the apt-get lists",
         "file": "Dockerfile"},
    ])
    rows = rst.parse_tool("hadolint", out, T, A, U)
    _assert_shape(rows)
    assert [r["fields"]["severity"] for r in rows] == ["high", "info"]  # error->high, info->info
    assert all(r["affected_component"] == "Dockerfile" for r in rows)


def test_actionlint_injection_is_high():
    out = json.dumps([
        {"message": "object filter extracts potentially untrusted input into a run: step (injection)",
         "filepath": ".github/workflows/ci.yml", "line": 22, "column": 9, "kind": "expression"},
        {"message": "shellcheck reported issue SC2086", "filepath": ".github/workflows/ci.yml",
         "line": 30, "column": 1, "kind": "shellcheck"},
    ])
    rows = rst.parse_tool("actionlint", out, T, A, U)
    _assert_shape(rows)
    sev = [r["fields"]["severity"] for r in rows]
    assert sev == ["high", "low"]  # injection -> high, lint -> low


def test_actionlint_argv_does_not_append_second_json():
    # Regression (live-fire): actionlint exits 1 WHEN it finds issues. An `|| echo '[]'` fallback then
    # appended a 2nd array to the finding JSON ("[{...}]\n[]"), which _first_json's greedy rfind spanned,
    # breaking json.loads and silently dropping every finding. The argv must not append a JSON literal.
    spec = next(s for s in rst.REPO_SCAN_TOOLS if s["name"] == "actionlint")
    cmd = spec["argv"]("/src", None)[-1]
    assert "echo '[]'" not in cmd and "echo []" not in cmd


# ======================================================================================================
# ARM-REPO: CI/CD pipeline security (owner HIGH priority) — fixtures are REAL captured tool output
# ======================================================================================================
def test_poutine_joins_rule_level():
    # real shape: findings[] carry rule_id + meta{path,line,details}; the level/title live in rules[id]
    out = json.dumps({"findings": [
        {"meta": {"details": "Sources: github.event.issue.title", "line": 16,
                  "path": ".github/workflows/ci.yml", "job": "build", "step": "1"}, "rule_id": "injection"},
        {"meta": {"line": 19, "path": ".github/workflows/ci.yml"}, "rule_id": "unverified_script_exec"},
    ], "rules": {
        "injection": {"id": "injection", "level": "warning", "title": "Injection"},
        "unverified_script_exec": {"id": "unverified_script_exec", "level": "error", "title": "Script Exec"},
    }})
    rows = rst.parse_tool("poutine", out, T, A, U)
    _assert_shape(rows)
    by = {r["fields"]["title"].split(":")[0].split("[")[1].rstrip("]"): r["fields"]["severity"] for r in rows}
    assert by == {"injection": "medium", "unverified_script_exec": "high"}  # warning->medium, error->high


def test_zizmor_sarif_severity():
    out = json.dumps({"runs": [{"results": [
        {"ruleId": "zizmor/template-injection", "level": "error", "message": {"text": "code injection"},
         "locations": [{"physicalLocation": {"artifactLocation": {"uri": ".github/workflows/ci.yml"},
                                             "region": {"startLine": 17}}}]},
        {"ruleId": "zizmor/artipacked", "level": "warning", "message": {"text": "credential persistence"},
         "locations": [{"physicalLocation": {"artifactLocation": {"uri": ".github/workflows/ci.yml"},
                                             "region": {"startLine": 12}}}]},
    ]}]})
    rows = rst.parse_tool("zizmor", out, T, A, U)
    _assert_shape(rows)
    sev = sorted(r["fields"]["severity"] for r in rows)
    assert sev == ["high", "medium"]  # error->high, warning->medium
    assert any("ci.yml" in (r["affected_component"] or "") for r in rows)


def test_octoscan_kind_severity():
    # octoscan --format json is the actionlint shape; severity keys on `kind`
    out = json.dumps([
        {"message": "Expression injection, untrusted.", "filepath": ".github/workflows/ci.yml",
         "line": 17, "column": 39, "kind": "expression-injection"},
        {"message": "Use of 'actions/checkout' with a custom ref.", "filepath": ".github/workflows/ci.yml",
         "line": 14, "column": 16, "kind": "dangerous-checkout"},
        {"message": "shellcheck SC2086", "filepath": ".github/workflows/ci.yml", "line": 20,
         "column": 1, "kind": "shellcheck"},
    ])
    rows = rst.parse_tool("octoscan", out, T, A, U)
    _assert_shape(rows)
    sev = [r["fields"]["severity"] for r in rows]
    assert sev == ["high", "high", "low"]  # injection+dangerous-checkout->high, shellcheck->low


def test_gato_x_pinned_schema():
    # schema pinned from gato-x source: enumeration.repositories[].risks[] + .accessible_runners[]
    out = json.dumps({"username": "u", "enumeration": {"repositories": [
        {"name": "org/repo",
         "risks": [{"issue_type": "pwn_request", "confidence": "HIGH", "attack_complexity": "LOW",
                    "initial_workflow": "ci.yml", "triggers": ["pull_request_target"]}],
         "accessible_runners": [{"name": "r1"}]},
    ]}})
    rows = rst.parse_tool("gato-x", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 2 and all(r["fields"]["severity"] == "high" for r in rows)
    assert any("pwn_request" in r["fields"]["title"] for r in rows)
    assert any("self-hosted runner" in r["fields"]["title"] for r in rows)


# ======================================================================================================
# ARM-REPO: mobile APK/DEX (owner HIGH priority)
# ======================================================================================================
def test_apkid_evasion_vs_compiler():
    out = json.dumps({"files": [{"filename": "a.apk!classes.dex", "matches": {
        "compiler": ["dx (possible dexmerge)"], "anti_vm": ["Build.MODEL check"],
        "manipulator": ["dexmerge"]}}]})
    rows = rst.parse_tool("apkid", out, T, A, U)
    _assert_shape(rows)
    by = {r["fields"]["evidence"].split(":")[0]: r["fields"]["severity"] for r in rows}
    assert by == {"compiler": "info", "anti_vm": "medium", "manipulator": "medium"}


def test_apkleaks_secret_is_high_and_redacted():
    out = json.dumps({"package": "com.x", "results": [
        {"name": "IP_Address", "matches": ["1.1.1.1", "10.0.2.2"]},
        {"name": "AWS_API_Key", "matches": ["AKIAIOSFODNN7EXAMPLE"]},
    ]})
    rows = rst.parse_tool("apkleaks", out, T, A, U)
    _assert_shape(rows)
    ip = next(r for r in rows if "IP_Address" in r["fields"]["title"])
    aws = next(r for r in rows if "AWS_API_Key" in r["fields"]["title"])
    assert ip["fields"]["severity"] == "info"
    assert aws["fields"]["severity"] == "high"
    assert "AKIAIOSFODNN7EXAMPLE" not in aws["fields"]["evidence"]  # redacted


# ======================================================================================================
# ARM-REPO: Kubernetes manifest security + OPA/Rego (provisionable)
# ======================================================================================================
def test_kube_linter_reports():
    out = json.dumps({"Reports": [
        {"Check": "host-network", "Diagnostic": {"Message": "resource shares host's network namespace"},
         "Object": {"Metadata": {"FilePath": "deployment.yaml"},
                    "K8sObject": {"Name": "web", "GroupVersionKind": {"Kind": "Deployment"}}}},
    ]})
    rows = rst.parse_tool("kube-linter", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "medium"
    assert rows[0]["affected_component"] == "Deployment/web"


def test_kubesec_critical_only():
    out = json.dumps([{"object": "Deployment/web.default", "fileName": "deployment.yaml", "score": -46,
                       "scoring": {"critical": [
                           {"id": "Privileged", "selector": "...", "reason": "Privileged containers", "points": -30}],
                                   "advise": [{"id": "ApparmorAny", "reason": "advisory"}]}}])
    rows = rst.parse_tool("kubesec", out, T, A, U)
    _assert_shape(rows)
    assert len(rows) == 1  # only scoring.critical -> findings; advise skipped
    assert rows[0]["fields"]["severity"] == "high" and "Privileged" in rows[0]["fields"]["title"]


def test_polaris_security_signal_only():
    out = json.dumps({"Results": [{"Kind": "Deployment", "Name": "web", "Results": {
        "deploymentMissingReplicas": {"ID": "deploymentMissingReplicas", "Message": "one replica",
                                      "Success": False, "Severity": "warning", "Category": "Reliability"}},
        "PodResult": {"Results": {
            "hostNetworkSet": {"ID": "hostNetworkSet", "Message": "Host network", "Success": False,
                               "Severity": "danger", "Category": "Security"}},
            "ContainerResults": [{"Name": "web", "Results": {
                "runAsPrivileged": {"ID": "runAsPrivileged", "Message": "privileged", "Success": False,
                                    "Severity": "danger", "Category": "Security"},
                "cpuLimitsMissing": {"ID": "cpuLimitsMissing", "Message": "cpu", "Success": False,
                                     "Severity": "warning", "Category": "Efficiency"},
                "passing": {"ID": "passing", "Message": "ok", "Success": True,
                            "Severity": "danger", "Category": "Security"}}}]}}]})
    rows = rst.parse_tool("polaris", out, T, A, U)
    _assert_shape(rows)
    # only FAILED Security/danger checks: hostNetworkSet + runAsPrivileged (reliability/efficiency + passing dropped)
    assert len(rows) == 2 and all(r["fields"]["severity"] == "high" for r in rows)
    ids = {r["fields"]["title"].split("[")[1].split("]")[0] for r in rows}
    assert ids == {"hostNetworkSet", "runAsPrivileged"}


def test_conftest_failures_and_warnings():
    out = json.dumps([{"filename": "deployment.yaml",
                       "failures": [{"msg": "runs privileged", "metadata": {"query": "data.main.deny"}}],
                       "warnings": [{"msg": "latest tag", "metadata": {"query": "data.main.warn"}}]}])
    rows = rst.parse_tool("conftest", out, T, A, U)
    _assert_shape(rows)
    by = {r["fields"]["severity"] for r in rows}
    assert by == {"high", "low"}  # failures->high, warnings->low


# ======================================================================================================
# ARM-REPO: applicability gates + credential gating are present in the argv (not just the parser)
# ======================================================================================================
def test_cicd_tools_gate_on_workflows():
    for name in ("poutine", "zizmor", "octoscan"):
        spec = next(s for s in rst.REPO_SCAN_TOOLS if s["name"] == name)
        cmd = spec["argv"]("/work", U)[-1]
        assert ".github/workflows" in cmd or ".gitlab-ci" in cmd, f"{name} has no CI/CD applicability gate"
        assert "exit 0" in cmd  # honest-skip path


def test_gato_x_is_credential_gated():
    spec = next(s for s in rst.REPO_SCAN_TOOLS if s["name"] == "gato-x")
    assert spec.get("needs_creds") is True
    cmd = spec["argv"]("/work", U)[-1]
    assert "GH_TOKEN" in cmd and "exit 0" in cmd  # honest-skip without a token


def test_k8s_tools_gate_on_manifests():
    for name in ("kube-linter", "kubesec", "polaris", "conftest"):
        spec = next(s for s in rst.REPO_SCAN_TOOLS if s["name"] == name)
        cmd = spec["argv"]("/work", U)[-1]
        assert "apiVersion|kind" in cmd and "exit 0" in cmd, f"{name} has no k8s applicability gate"


def test_mobile_apk_tools_gate_on_package():
    for name in ("apkid", "apkleaks"):
        spec = next(s for s in rst.REPO_SCAN_TOOLS if s["name"] == name)
        cmd = spec["argv"]("/work", U)[-1]
        assert "*.apk" in cmd and "exit 0" in cmd, f"{name} has no mobile-package gate"


def test_gh_slug_extraction():
    assert rst._gh_slug("https://github.com/org/repo.git") == "org/repo"
    assert rst._gh_slug("git@github.com:org/repo.git") == "org/repo"
    assert rst._gh_slug("https://gitlab.com/org/repo") == ""  # not github


# ======================================================================================================
# ROBUSTNESS — every wired parser is garbage-safe (never raises, never fabricates on junk/empty)
# ======================================================================================================
def test_all_parsers_garbage_safe():
    for spec in rst.REPO_SCAN_TOOLS:
        for junk in ("", "   ", "not json at all", "{", "[}", "null", "<html>err</html>", "\x00\x01"):
            assert rst.parse_tool(spec["name"], junk, T, A, U) == [], f"{spec['name']} on {junk!r}"


def test_unknown_tool_returns_empty():
    assert rst.parse_tool("no-such-tool", '{"x":1}', T, A, U) == []


# ======================================================================================================
# REGISTRY CONTRACT — bounded, read-only argv; consistent specs; no wired tool also deferred/missing
# ======================================================================================================
_WRITE_TOKENS = ("git push", "git commit", "git add", "git-push", " push ", "--write ", "rm -rf /",
                 " > /work", ">> /work", "git checkout -b", "git tag")


def test_argv_is_bounded_and_read_only():
    for spec in rst.REPO_SCAN_TOOLS:
        assert callable(spec["argv"]) and callable(spec["parse"])
        assert isinstance(spec["timeout"], int) and 0 < spec["timeout"] <= 900
        argv = spec["argv"](T, U)
        assert isinstance(argv, list) and argv and all(isinstance(a, str) for a in argv)
        joined = " ".join(argv)
        for bad in _WRITE_TOKENS:
            assert bad not in joined, f"{spec['name']} argv looks non-read-only: {bad!r}"


def test_argv_handles_url_target_without_crashing():
    # a bare clone-URL target (no local path) must fall back to '.' — argv still builds
    for spec in rst.REPO_SCAN_TOOLS:
        argv = spec["argv"](U, U)
        assert isinstance(argv, list) and argv


def test_gated_tools_marked_needs_creds():
    snyk = next(s for s in rst.REPO_SCAN_TOOLS if s["name"] == "snyk")
    assert snyk.get("needs_creds") is True


def test_no_wired_tool_is_also_deferred_or_missing():
    wired = {s["name"] for s in rst.REPO_SCAN_TOOLS}
    assert not (wired & set(rst._STILL_UNWIRED_REPO_SCAN_TOOLS)), "a wired tool is listed as still-unwired"
    assert not (wired & set(rst._MISSING_FROM_IMAGE)), "a wired tool is listed as missing-from-image"
    # names are unique in the registry
    names = [s["name"] for s in rst.REPO_SCAN_TOOLS]
    assert len(names) == len(set(names))
