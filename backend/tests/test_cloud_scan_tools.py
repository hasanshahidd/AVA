"""P0b cloud-scan LINKAGE — the ava-cloud-scan arsenal registry (cloud_scan_tools) + its shape contract.

Deterministic + offline: each parser is fed CAPTURED sample tool output and we assert the normalized finding
rows (shape, severity, component, corroboration-ready source slug). No live scan, no docker, no cloud creds.
Also asserts garbage-safety (never raises / never fabricates) and that every registry argv is bounded +
read-only. The two wired tools are the credential-free anonymous-S3 auditors; the rest are deferred (they
need cloud-account credentials the dispatcher can't pass).
"""
import json

import grc.modules.pentest.cloud_scan_tools as cst


# ---- row shape contract (matches web_scan_tools._row so dedup + ingest consume it unchanged) ----------
def _assert_shape(rows):
    for r in rows:
        assert r["kind"] == "cloud"
        assert set(("vid", "source_slug", "title", "affected_url", "fields")) <= set(r)
        assert r["vid"].startswith("AIPT-CLOUD-") and len(r["vid"]) <= 50
        f = r["fields"]
        assert f["severity"] in cst._SEV
        assert f["source"].startswith("ai-pentest:") and f["plugin_family"] == "AI Pentest"
        assert f["status"] == "open" and f["title"]


# ---- s3scanner -----------------------------------------------------------------------------------------
def test_s3scanner_severity_ladder():
    out = "\n".join([
        "Warning: AWS credentials not configured - functionality will be limited.",
        "acme-notexist | bucket_not_exist",
        "acme-bad_name | bucket_invalid_name",
        "acme | bucket_exists | AuthUsers: [], AllUsers: []",
        "acme-media | bucket_exists | AuthUsers: [], AllUsers: [Read]",
        "acme-backups | bucket_exists | AuthUsers: [], AllUsers: [Read | WriteACP]",
        "acme-data | bucket_exists | AuthUsers: [Read], AllUsers: []",
        "acme-logs | bucket_exists | AuthUsers: [FullControl], AllUsers: []",
    ])
    rows = cst.parse_tool("s3scanner", out, "acme.com", 1, "http://acme.com")
    _assert_shape(rows)
    sev = {r["affected_component"]: r["fields"]["severity"] for r in rows}
    assert sev == {"acme": "low", "acme-media": "high", "acme-backups": "critical",
                   "acme-data": "medium", "acme-logs": "high"}
    # not_exist / invalid_name never become findings
    comps = set(sev)
    assert "acme-notexist" not in comps and "acme-bad_name" not in comps
    # public bucket carries its S3 endpoint URL + bucket name as component (distinct-bucket dedup)
    media = next(r for r in rows if r["affected_component"] == "acme-media")
    assert media["affected_url"] == "https://acme-media.s3.amazonaws.com"


def test_s3scanner_comma_and_pipe_separators():
    # get_human_readable joins with ', ' but the docstring shows ' | ' — handle both.
    out = "x-prod | bucket_exists | AuthUsers: [Read, WriteACP], AllUsers: [FullControl]"
    rows = cst.parse_tool("s3scanner", out, "x.com", 2, "http://x.com")
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "critical"


# ---- festin --------------------------------------------------------------------------------------------
def test_festin_listable_vs_exposed():
    out = "\n".join([
        "some banner line ignored",
        '{"domain": "acme.com", "bucket_name": "acme-public", "objects": ["index.html", "db.sql", "key.pem"]}',
        '{"domain": "acme.com", "bucket_name": "acme-empty", "objects": []}',
    ])
    rows = cst.parse_tool("festin", out, "acme.com", 3, "http://acme.com")
    _assert_shape(rows)
    by = {r["affected_component"]: r for r in rows}
    assert by["acme-public"]["fields"]["severity"] == "high"
    assert "3 object" in by["acme-public"]["fields"]["title"]
    assert "db.sql" in by["acme-public"]["fields"]["evidence"]
    assert by["acme-empty"]["fields"]["severity"] == "medium"
    assert by["acme-public"]["affected_url"] == "https://acme-public.s3.amazonaws.com"


def test_festin_dedupes_repeated_bucket():
    line = '{"domain": "acme.com", "bucket_name": "dup", "objects": []}'
    rows = cst.parse_tool("festin", line + "\n" + line, "acme.com", 4, "http://acme.com")
    assert len(rows) == 1


# ---- garbage-safety: never raise, never fabricate ------------------------------------------------------
def test_parsers_never_raise_on_garbage():
    junk = ["", "   ", "not json at all", "{bad json", "null", "[]", "{}",
            "| bucket_exists |", "random | text | here",
            '{"objects": ["a"]}',                       # no bucket_name -> skipped
            "\x00\xff binary garbage \n more"]
    for name in ("s3scanner", "festin"):
        for j in junk:
            assert cst.parse_tool(name, j, "t.com", 9, "http://t.com") == []
    assert cst.parse_tool("nonexistent-tool", "whatever", "t", 1, "http://t") == []


# ---- registry: bounded + read-only argv, valid parsers -------------------------------------------------
# genuinely destructive tokens (shell / S3 write verbs / the s3scanner --dangerous ACL-mutating flag).
# NB: benign bucket-name suffixes like "-uploads" are read-only names, not mutations, so we match
# whole destructive flags/commands, not bare substrings.
_MUTATING = (" rm ", " rm -", " del ", "put-object", "put-bucket", "delete-object", "delete-bucket",
             "--dangerous", " dd ", " mkfs", ">/dev/sd", "shutdown", "reboot", "s3scanner dump")


def test_registry_specs_bounded_and_readonly():
    names = {s["name"] for s in cst.CLOUD_SCAN_TOOLS}
    assert names == {"festin", "s3scanner", "gcpbucketbrute", "subfinder", "dnsx",
                     "scoutsuite", "cloudsplaining", "cloudsploit", "kubescape", "kube-bench", "amass"}
    for spec in cst.CLOUD_SCAN_TOOLS:
        assert callable(spec["parse"]) and callable(spec["argv"])
        assert isinstance(spec["timeout"], int) and 0 < spec["timeout"] <= 600
        argv = spec["argv"]("acme.com", "http://acme.com")
        assert isinstance(argv, list) and argv and all(isinstance(a, str) for a in argv)
        joined = " ".join(argv).lower()
        assert not any(m in joined for m in _MUTATING), (spec["name"], joined)
        # deferred tools are honestly excluded, not silently half-wired
        assert spec["name"] not in cst._DEFERRED_CLOUD_SCAN_TOOLS


def test_bucket_candidates_bounded_and_valid():
    cands = cst._bucket_candidates("www.example.com")
    assert cands and len(cands) <= cst._MAX_CANDIDATES
    assert "example" in cands                       # registrable label seeded
    for c in cands:
        assert 3 <= len(c) <= 63 and c == c.lower()
    # no host -> no candidates -> s3scanner argv is a no-op, parser yields []
    assert cst._bucket_candidates("") == []
    assert cst._s3scanner_argv("", "") == ["true"]


def test_deferred_list_is_honest():
    # still-unwired / missing / broken heavy hitters are named, not pretended-wired
    for t in ("prowler", "cloudfox", "pmapper", "checkov", "cartography", "steampipe", "cnquery", "pacu"):
        assert t in cst._DEFERRED_CLOUD_SCAN_TOOLS
    # every wired spec name is ABSENT from the deferred set (no half-wiring)
    for spec in cst.CLOUD_SCAN_TOOLS:
        assert spec["name"] not in cst._DEFERRED_CLOUD_SCAN_TOOLS
    # missing/broken tools carry a concrete rebuild reason
    for t in ("prowler", "pmapper", "parliament", "cloud_enum", "CloudBrute", "trivy"):
        assert cst._MISSING_FROM_IMAGE.get(t)
    # pass-2 present-but-unlinkable tools are catalogued with an honest reason, not fake-wired
    for t in ("aws_public_ips", "KubiScan", "MicroBurst", "monkey365", "MFASweep", "GraphRunner", "BARK"):
        assert t in cst._DEFERRED_CLOUD_SCAN_TOOLS
        assert cst._STILL_UNWIRED_CLOUD_SCAN_TOOLS.get(t)


# ---- subfinder: cloud subdomain surface -> one summary row --------------------------------------------
def test_subfinder_summary():
    out = "api.acme.com\nwww.acme.com\ndev.acme.com\nnot a host line\n"
    rows = cst.parse_tool("subfinder", out, "acme.com", 10, "http://acme.com")
    _assert_shape(rows)
    assert len(rows) == 1
    assert "3 subdomain" in rows[0]["fields"]["title"]
    assert rows[0]["fields"]["severity"] == "info"


# ---- dnsx: flag cloud-endpoint CNAMEs + records summary ----------------------------------------------
def test_dnsx_cloud_cname_flagging():
    out = "\n".join([
        "acme.com [A] [1.2.3.4]",
        "www.acme.com [CNAME] [d123.cloudfront.net]",
        "cdn.acme.com [CNAME] [acme.blob.core.windows.net]",
        "app.acme.com [CNAME] [acme.appspot.com]",
    ])
    rows = cst.parse_tool("dnsx", out, "acme.com", 11, "http://acme.com")
    _assert_shape(rows)
    by = {r["affected_component"]: r for r in rows if r["fields"]["severity"] == "low"}
    assert "AWS CloudFront" in by and "Azure Blob" in by and "GCP App Engine" in by
    # exactly one info summary row exists alongside the cloud-asset lows
    summ = [r for r in rows if r["fields"]["severity"] == "info"]
    assert len(summ) == 1 and "4" in summ[0]["fields"]["title"]


# ---- gcpbucketbrute: GCS anonymous-access severity ladder --------------------------------------------
def test_gcpbucketbrute_severity_ladder():
    out = "\n".join([
        "Generated 1300 bucket permutations.",
        "",
        "    UNAUTHENTICATED ACCESS ALLOWED: acme-public",
        "        - UNAUTHENTICATED LISTABLE (storage.objects.list)",
        "        - UNAUTHENTICATED READABLE (storage.objects.get)",
        "    UNAUTHENTICATED ACCESS ALLOWED: acme-writable",
        "        - VULNERABLE TO PRIVILEGE ESCALATION (storage.buckets.setIamPolicy)",
        "        - UNAUTHENTICATED WRITABLE (storage.objects.create, storage.objects.delete)",
        "    EXISTS: acme-private",
        "",
        "Scanned 1300 potential buckets in 2 minute(s) and 3 second(s).",
    ])
    rows = cst.parse_tool("gcpbucketbrute", out, "acme.com", 12, "http://acme.com")
    _assert_shape(rows)
    sev = {r["affected_component"]: r["fields"]["severity"] for r in rows}
    assert sev == {"acme-public": "high", "acme-writable": "critical", "acme-private": "low"}
    pub = next(r for r in rows if r["affected_component"] == "acme-public")
    assert pub["affected_url"] == "https://storage.googleapis.com/acme-public"
    assert "LISTABLE" in pub["fields"]["evidence"]


def test_gcpbucketbrute_authenticated_is_lower_sev():
    out = "\n".join([
        "    AUTHENTICATED ACCESS ALLOWED: corp-data",
        "        - AUTHENTICATED READABLE (storage.objects.get)",
    ])
    rows = cst.parse_tool("gcpbucketbrute", out, "corp.com", 13, "http://corp.com")
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "medium"


# ---- scoutsuite: results-JS -> findings (danger/warning, flagged_items>0) -----------------------------
def test_scoutsuite_findings_by_level():
    js = 'scoutsuite_results =\n' + json.dumps({
        "account_id": "123456789012",
        "services": {
            "s3": {"findings": {
                "s3-bucket-world-acl": {"description": "World-accessible bucket ACL", "level": "danger",
                                        "flagged_items": 2, "items": ["s3.buckets.a", "s3.buckets.b"]},
                "s3-no-mfa-delete": {"description": "MFA delete off", "level": "warning",
                                     "flagged_items": 1, "items": ["s3.buckets.c"]},
                "s3-ok": {"description": "fine", "level": "danger", "flagged_items": 0, "items": []},
            }},
            "iam": {"findings": {
                "iam-inline-policy": {"description": "Inline policy", "level": "warning",
                                      "flagged_items": 3, "items": ["iam.users.bob"]},
            }},
        },
    })
    rows = cst.parse_tool("scoutsuite", js, "acme.com", 14, "http://acme.com")
    _assert_shape(rows)
    by = {r["affected_component"]: r["fields"]["severity"] for r in rows}
    assert by == {"s3-bucket-world-acl": "high", "s3-no-mfa-delete": "medium", "iam-inline-policy": "medium"}
    assert "s3-ok" not in by                            # flagged_items==0 -> not a finding


# ---- cloudsplaining: IAM risk categories -> findings -------------------------------------------------
def test_cloudsplaining_risk_categories():
    doc = json.dumps({
        "AdminAccess": {
            "PrivilegeEscalation": [{"type": "CreateAccessKey"}],
            "ResourceExposure": ["iam:PassRole"],
            "DataExfiltration": ["s3:GetObject"],
            "InfrastructureModification": ["ec2:RunInstances"],
            "PrivilegeEscalationCount": 1,          # non-list -> ignored, never raises
        },
        "ReadOnly": {"PrivilegeEscalation": [], "ResourceExposure": [], "DataExfiltration": []},
    })
    rows = cst.parse_tool("cloudsplaining", doc, "acme.com", 15, "http://acme.com")
    _assert_shape(rows)
    sev = {r["fields"]["title"]: r["fields"]["severity"] for r in rows}
    assert any("PrivilegeEscalation" in t and s == "critical" for t, s in sev.items())
    assert any("ResourceExposure" in t and s == "high" for t, s in sev.items())
    assert any("InfrastructureModification" in t and s == "medium" for t, s in sev.items())
    # empty-list categories on ReadOnly produce nothing
    assert all("ReadOnly" not in t for t in sev)


# ---- new parsers are garbage-safe too ----------------------------------------------------------------
def test_new_parsers_never_raise_on_garbage():
    junk = ["", "   ", "not json", "{bad", "null", "[]", "{}", "\x00\xff bin",
            "scoutsuite_results =\n{bad", '{"services": "notadict"}', "EXISTS:",
            "    UNAUTHENTICATED ACCESS ALLOWED:"]
    for name in ("subfinder", "dnsx", "gcpbucketbrute", "scoutsuite", "cloudsplaining",
                 "cloudsploit", "kubescape", "kube-bench", "amass"):
        for j in junk:
            assert cst.parse_tool(name, j, "t.com", 9, "http://t.com") == []


# ---- cloudsploit: multi-cloud posture, FAIL/WARN -> findings (distinct ruleset from scoutsuite) --------
def test_cloudsploit_status_ladder():
    doc = json.dumps([
        {"plugin": "bucketAllUsersPolicy", "category": "S3", "title": "S3 Bucket All Users Policy",
         "resource": "arn:aws:s3:::acme-open", "region": "us-east-1", "status": "FAIL",
         "message": "Bucket policy allows global access"},
        {"plugin": "mfaEnabled", "category": "IAM", "title": "MFA Enabled", "resource": "arn:aws:iam::1:user/x",
         "region": "global", "status": "WARN", "message": "MFA not enabled"},
        {"plugin": "rootAccount", "category": "IAM", "title": "Root Account", "resource": "root",
         "region": "global", "status": "OK", "message": "fine"},
        {"plugin": "x", "category": "EC2", "title": "y", "resource": "z", "status": "UNKNOWN"},
    ])
    rows = cst.parse_tool("cloudsploit", doc, "acme.com", 20, "http://acme.com")
    _assert_shape(rows)
    sev = {r["affected_component"]: r["fields"]["severity"] for r in rows}
    assert sev == {"arn:aws:s3:::acme-open": "high", "arn:aws:iam::1:user/x": "medium"}
    # OK / UNKNOWN never become findings
    fail = next(r for r in rows if r["affected_component"] == "arn:aws:s3:::acme-open")
    assert "S3" in fail["fields"]["title"] and "global access" in fail["fields"]["evidence"]


def test_cloudsploit_object_wrapped_results():
    doc = json.dumps({"results": [{"plugin": "p", "category": "GCP", "title": "t", "resource": "r",
                                   "region": "us", "status": "FAIL", "message": "m"}]})
    rows = cst.parse_tool("cloudsploit", doc, "acme.com", 21, "http://acme.com")
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "high"


# ---- kubescape: failed controls -> findings, scoreFactor -> severity ----------------------------------
def test_kubescape_controls_by_score():
    doc = json.dumps({"summaryDetails": {"controls": {
        "C-0016": {"controlID": "C-0016", "name": "Allow privilege escalation", "scoreFactor": 7.0,
                   "ResourceCounters": {"passedResources": 1, "failedResources": 3, "excludedResources": 0}},
        "C-0009": {"controlID": "C-0009", "name": "Resource limits", "scoreFactor": 4.0,
                   "ResourceCounters": {"passedResources": 5, "failedResources": 2}},
        "C-0002": {"controlID": "C-0002", "name": "Exec into container", "scoreFactor": 1.0,
                   "ResourceCounters": {"passedResources": 9, "failedResources": 1}},
        "C-0777": {"controlID": "C-0777", "name": "All good", "scoreFactor": 9.0,
                   "ResourceCounters": {"passedResources": 3, "failedResources": 0}},
    }}})
    rows = cst.parse_tool("kubescape", doc, "cluster", 22, "http://cluster")
    _assert_shape(rows)
    sev = {r["affected_component"]: r["fields"]["severity"] for r in rows}
    assert sev == {"C-0016": "high", "C-0009": "medium", "C-0002": "low"}
    assert "C-0777" not in sev                          # failedResources==0 -> not a finding


# ---- kube-bench: CIS FAIL/WARN -> findings ------------------------------------------------------------
def test_kube_bench_status_ladder():
    doc = json.dumps({"Controls": [{"tests": [{"results": [
        {"test_number": "1.2.1", "test_desc": "Ensure anonymous-auth is off", "status": "FAIL",
         "remediation": "Set --anonymous-auth=false"},
        {"test_number": "1.2.2", "test_desc": "Ensure basic-auth is off", "status": "WARN",
         "remediation": "Remove --basic-auth-file"},
        {"test_number": "1.2.3", "test_desc": "TLS configured", "status": "PASS", "remediation": ""},
        {"test_number": "1.2.4", "test_desc": "manual check", "status": "INFO"},
    ]}]}]})
    rows = cst.parse_tool("kube-bench", doc, "node", 23, "http://node")
    _assert_shape(rows)
    sev = {r["affected_component"]: r["fields"]["severity"] for r in rows}
    assert sev == {"1.2.1": "high", "1.2.2": "medium"}   # PASS/INFO excluded
    assert "anonymous-auth=false" in next(r for r in rows if r["affected_component"] == "1.2.1")["fields"]["evidence"]


# ---- amass fallback: bare FQDNs -> one subdomain-surface summary (same shape as subfinder) -------------
def test_amass_fallback_summary():
    out = "api.acme.com\ncdn.acme.com\nnot a host\nadmin.acme.com\n"
    rows = cst.parse_tool("amass", out, "acme.com", 24, "http://acme.com")
    _assert_shape(rows)
    assert len(rows) == 1 and "3 subdomain" in rows[0]["fields"]["title"]
    assert rows[0]["source_slug"] == "amass"


# ---- arm-and-gate + fallback + feeder wiring contract (the Mechanism the dispatcher consumes) ----------
def test_credentialed_tools_are_armed_and_gated():
    """Each credential/cluster-gated posture tool is ARMED (in the registry, counts as armed) yet marked
    needs_creds AND self-gates in its argv so it stays DORMANT (emits nothing) until its input is present."""
    gated = {s["name"]: s for s in cst.CLOUD_SCAN_TOOLS if s.get("needs_creds")}
    # the posture/cluster tools armed in THIS pass carry the needs_creds dormancy flag (scoutsuite/
    # cloudsplaining were pre-wired as plain primaries that self-gate by emitting [] without creds).
    assert {"cloudsploit", "kubescape", "kube-bench"} <= set(gated)
    # cloudsploit self-gates on provider creds; kube* self-gate on a cluster/kubeconfig -> `exit 0` when absent.
    for name, guard in (("cloudsploit", "AWS_ACCESS_KEY_ID"), ("kubescape", "KUBECONFIG"),
                        ("kube-bench", "KUBECONFIG")):
        argv = gated[name]["argv"]("acme.com", "http://acme.com")
        joined = " ".join(argv)
        assert "exit 0" in joined and guard in joined       # dormant without the input
    # ...but the parser FIRES when the input yields real output (proved by the parser tests above).
    assert cst.parse_tool("cloudsploit", json.dumps(
        [{"plugin": "p", "category": "S3", "title": "t", "resource": "r", "status": "FAIL", "message": "m"}]),
        "acme.com", 25, "http://acme.com")


def test_amass_is_a_fallback_for_subfinder():
    """The duplicate (amass, subfinder's class) is wired as a FALLBACK, not dropped — the dispatcher fires it
    ONLY when subfinder produced nothing (runtime gating is dispatcher-tested); here we assert the linkage."""
    amass = next(s for s in cst.CLOUD_SCAN_TOOLS if s["name"] == "amass")
    subfinder_names = {s["name"] for s in cst.CLOUD_SCAN_TOOLS}
    assert amass.get("fallback_for") == "subfinder" and "subfinder" in subfinder_names
    # a fallback is NOT a primary and NOT a feeder (dispatcher partitions the registry on these keys)
    assert not amass.get("feeds") and not amass.get("needs_creds")
    # and it is runnable, not dead: its argv is bounded + read-only
    argv = amass["argv"]("acme.com", "http://acme.com")
    assert argv and argv[0] in ("sh", "true")
