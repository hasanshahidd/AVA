"""P0b web-scan LINKAGE — the ava-web-scan arsenal registry (web_scan_tools) + its wiring into the finder.

Deterministic + offline: each parser is fed CAPTURED sample tool output and we assert the normalized
finding rows (shape, severity, component, corroboration-ready source slug). No live scan, no docker. Also
asserts the existing web find sweep (nmap/nuclei -> hexstrike rows) still fires and that the arsenal rows
are ADDED on top (no regression), and that a missing image degrades to [] honestly.
"""
import grc.modules.pentest.web_scan_tools as wst
import grc.modules.pentest.service as svc


# ---- row shape contract (matches service._nikto_rows so dedup + ingest consume it unchanged) -----------
def _assert_shape(rows):
    for r in rows:
        assert r["kind"] == "web"
        assert set(("vid", "source_slug", "title", "affected_url", "fields")) <= set(r)
        f = r["fields"]
        assert f["severity"] in wst._SEV
        assert f["source"].startswith("ai-pentest:") and f["plugin_family"] == "AI Pentest"
        assert f["status"] == "open" and f["title"]


def test_whatweb_versioned_and_summary():
    out = ("http://demo.testfire.net [200 OK] Country[UNITED STATES][US], "
           "HTTPServer[Apache-Coyote/1.1], IP[65.61.137.117], Title[Altoro Mutual], "
           "X-Powered-By[Servlet/3.0], PHP[5.5.9]")
    rows = wst.parse_tool("whatweb", out, "demo.testfire.net", 1, "http://demo.testfire.net")
    _assert_shape(rows)
    comps = {r["affected_component"] for r in rows if r["affected_component"]}
    assert "HTTPServer" in comps and "PHP" in comps and "X-Powered-By" in comps
    assert "Country" not in comps and "IP" not in comps          # noise plugins dropped
    assert any(r["fields"]["title"].startswith("Web technology fingerprint") for r in rows)
    assert all(r["source_slug"] == "whatweb" for r in rows)


def test_httpx_json_fingerprint():
    out = ('{"timestamp":"2026-01-01","url":"https://h","status_code":200,"title":"Home",'
           '"webserver":"nginx/1.18.0","tech":["Nginx:1.18.0","PHP"]}')
    rows = wst.parse_tool("httpx", out, "h", 2, "https://h")
    _assert_shape(rows)
    titles = " ".join(r["fields"]["title"] for r in rows)
    assert "nginx/1.18.0" in titles and "Nginx:1.18.0" in titles
    assert any(r["affected_component"] == "nginx/1.18.0" for r in rows)


def test_wafw00f_detected_and_absent():
    hit = wst.parse_tool("wafw00f",
                         "[+] The site https://h is behind Cloudflare (Cloudflare Inc.) WAF.\n",
                         "h", 3, "https://h")
    _assert_shape(hit)
    assert len(hit) == 1 and "Cloudflare" in hit[0]["fields"]["title"]
    miss = wst.parse_tool("wafw00f", "[-] No WAF detected by the generic detection\n", "h", 3, "https://h")
    _assert_shape(miss)
    assert len(miss) == 1 and miss[0]["fields"]["severity"] == "low"
    assert wst.parse_tool("wafw00f", "totally unrelated output", "h", 3, "https://h") == []


def test_sslscan_weak_proto_and_cipher():
    out = ("  SSLv2     disabled\n  SSLv3     enabled\n  TLSv1.0   enabled\n  TLSv1.2   enabled\n"
           "Accepted  TLSv1.0  112 bits  DES-CBC3-SHA\n"
           "Accepted  TLSv1.2  256 bits  ECDHE-RSA-AES256-GCM-SHA384\n"
           "Preferred TLSv1.0  128 bits  RC4-SHA\n")
    rows = wst.parse_tool("sslscan", out, "h", 4, "https://h")
    _assert_shape(rows)
    titles = [r["fields"]["title"] for r in rows]
    assert any("SSLv3" in t for t in titles) and any("TLSv1.0" in t and "protocol" in t for t in titles)
    assert any("DES-CBC3-SHA" in t for t in titles) and any("RC4-SHA" in t for t in titles)
    # the strong AES256-GCM cipher and the disabled SSLv2 must NOT be flagged
    assert not any("AES256-GCM" in t for t in titles) and not any("SSLv2" in t for t in titles)
    assert all(r["fields"]["severity"] == "medium" for r in rows)


def test_wapiti_injection_findings():
    out = ('BANNER LINE\n{"vulnerabilities": {'
           '"SQL Injection": [{"method":"GET","path":"http://h/artist.php?id=1",'
           '"info":"SQL injection via id","parameter":"id","level":1}], '
           '"Cross Site Scripting": [{"method":"GET","path":"http://h/search.php?q=x",'
           '"info":"XSS reflected","parameter":"q","level":1}], '
           '"Blind SQL Injection": []}, "classifications": {}}')
    rows = wst.parse_tool("wapiti", out, "h", 5, "http://h")
    _assert_shape(rows)
    assert len(rows) == 2                                        # empty Blind-SQLi list contributes nothing
    sqli = next(r for r in rows if "SQL Injection" in r["fields"]["title"])
    assert sqli["fields"]["severity"] == "high" and sqli["affected_component"] == "id"
    assert sqli["affected_url"] == "http://h/artist.php?id=1"
    xss = next(r for r in rows if "Cross Site Scripting" in r["fields"]["title"])
    assert xss["fields"]["severity"] == "high" and xss["affected_component"] == "q"


def test_parsers_never_raise_on_garbage():
    for name in ("whatweb", "httpx", "wafw00f", "sslscan", "wapiti"):
        assert wst.parse_tool(name, "", "h", 1, "http://h") == []
        assert wst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "http://h") == []
    assert wst.parse_tool("does-not-exist", "anything", "h", 1, "http://h") == []


def test_registry_specs_bounded_and_readonly():
    names = {s["name"] for s in wst.WEB_SCAN_TOOLS}
    assert {"whatweb", "httpx", "wafw00f", "sslscan", "wapiti"} <= names
    for spec in wst.WEB_SCAN_TOOLS:
        argv = spec["argv"]("demo.testfire.net", "http://demo.testfire.net")
        assert isinstance(argv, list) and argv and all(isinstance(a, str) for a in argv)
        assert 0 < int(spec["timeout"]) <= 600                  # every tool is time-bounded
        assert callable(spec["parse"])


# ---- wiring into the finder: additive (existing nmap/nuclei rows kept) + honest on missing image --------
def test_finder_appends_arsenal_without_regressing_hexstrike(monkeypatch):
    def fake_run(lane, argv, timeout=0, input_bytes=None, phase="scan", subtype=None):
        tool = argv[0] if argv else ""
        if tool == "nmap":
            return {"stdout": "80/tcp open http", "stderr": "", "rc": 0, "error": None}
        if tool == "nuclei":
            return {"stdout": "[tech-detect] [http] [info] http://h", "stderr": "", "rc": 0, "error": None}
        if tool == "whatweb":
            return {"stdout": "http://h [200 OK] HTTPServer[Apache/2.4.7]", "stderr": "", "rc": 0,
                    "error": None}
        return {"stdout": "", "stderr": "", "rc": 0, "error": None}

    monkeypatch.setattr(svc, "_lane_container_run", fake_run)
    rows = svc._lane_find_container("web", "h", 7)
    slugs = {r["source_slug"] for r in rows}
    assert "hexstrike-arsenal" in slugs                          # existing nmap/nuclei rows preserved
    assert "whatweb" in slugs                                    # arsenal rows added on top
    # internal lane must NOT pull the web arsenal (whatweb never runs there)
    irows = svc._lane_find_container("internal", "h", 7)
    assert "whatweb" not in {r["source_slug"] for r in irows}


def test_finder_web_arsenal_missing_image_is_honest(monkeypatch):
    monkeypatch.setattr(svc, "_lane_container_run", lambda lane, argv, timeout=0, input_bytes=None,
                        phase="scan", subtype=None: {"stdout": "", "stderr": "", "rc": 125,
                                                     "error": f"lane image ava-{lane} not built"})
    assert svc._web_scan_arsenal_rows("h", 7) == []
    assert svc._lane_find_container("web", "h", 7) == []
