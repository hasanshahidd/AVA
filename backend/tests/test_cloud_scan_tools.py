"""P0b cloud-scan LINKAGE — the ava-cloud-scan arsenal registry (cloud_scan_tools) + its shape contract.

Deterministic + offline: each parser is fed CAPTURED sample tool output and we assert the normalized finding
rows (shape, severity, component, corroboration-ready source slug). No live scan, no docker, no cloud creds.
Also asserts garbage-safety (never raises / never fabricates) and that every registry argv is bounded +
read-only. The two wired tools are the credential-free anonymous-S3 auditors; the rest are deferred (they
need cloud-account credentials the dispatcher can't pass).
"""
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
    assert names == {"festin", "s3scanner"}
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
    # the credentialed-only heavy hitters are named as deferred, not pretended-wired
    for t in ("prowler", "scoutsuite", "cloudfox", "pmapper", "checkov", "kubescape"):
        assert t in cst._DEFERRED_CLOUD_SCAN_TOOLS
