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


# ---- P0b pass 2: TLS auditors (testssl, sslyze), header/param (humble, arjun), enum tools -------------
def test_testssl_flat_json_severity_mapped():
    out = ('[ {"id":"engine_problem","ip":"/","port":"443","severity":"WARN","finding":"no engine"},'
           '{"id":"TLS1","ip":"h/1.2.3.4","port":"443","severity":"LOW","finding":"offered (deprecated)"},'
           '{"id":"cipherlist_3DES_IDEA","ip":"h/1.2.3.4","port":"443","severity":"MEDIUM","cwe":"CWE-310",'
           '"finding":"offered"},'
           '{"id":"cert_keyUsage","ip":"h/1.2.3.4","port":"443","severity":"HIGH",'
           '"finding":"Certificate incorrectly used"} ]')
    rows = wst.parse_tool("testssl", out, "h", 4, "https://h")
    _assert_shape(rows)
    sevs = {r["fields"]["title"].split(":")[1].split("—")[0].strip(): r["fields"]["severity"] for r in rows}
    assert len(rows) == 3                                        # WARN dropped, LOW/MEDIUM/HIGH kept
    assert sevs["TLS1"] == "low" and sevs["cipherlist_3DES_IDEA"] == "medium"
    assert sevs["cert_keyUsage"] == "high"
    assert all(r["source_slug"] == "testssl" for r in rows)


def test_sslyze_weak_proto_cipher_and_vuln():
    out = ('{"server_scan_results":[{"scan_result":{'
           '"ssl_2_0_cipher_suites":{"result":{"accepted_cipher_suites":[]}},'
           '"tls_1_0_cipher_suites":{"result":{"accepted_cipher_suites":[{"cipher_suite":'
           '{"name":"TLS_RSA_WITH_3DES_EDE_CBC_SHA","openssl_name":"DES-CBC3-SHA","key_size":112,'
           '"is_anonymous":false}}]}},'
           '"tls_1_2_cipher_suites":{"result":{"accepted_cipher_suites":[{"cipher_suite":'
           '{"name":"TLS_RSA_WITH_AES_256_GCM_SHA384","openssl_name":"AES256-GCM-SHA384","key_size":256,'
           '"is_anonymous":false}}]}},'
           '"heartbleed":{"result":{"is_vulnerable_to_heartbleed":true}}}}]}')
    rows = wst.parse_tool("sslyze", out, "h", 5, "https://h")
    _assert_shape(rows)
    titles = [r["fields"]["title"] for r in rows]
    assert any("TLSv1.0" in t and "protocol" in t for t in titles)
    assert any("DES-CBC3-SHA" in t for t in titles)
    assert any("Heartbleed" in t for t in titles)
    assert not any("AES256-GCM" in t for t in titles)           # strong cipher not flagged
    assert not any("SSLv2" in t for t in titles)                # empty accepted list not flagged
    hb = next(r for r in rows if "Heartbleed" in r["fields"]["title"])
    assert hb["fields"]["severity"] == "critical"


def test_humble_missing_and_deprecated_headers():
    out = ('{"[0. Info]":{"URL":"https://h"},'
           '"[1. Enabled HTTP Security Headers]":[{"Header":"Content-Type","Value":"text/html"}],'
           '"[2. Missing HTTP Security Headers]":[{"Header":"Content-Security-Policy","Details":"XSS"},'
           '{"Header":"Strict-Transport-Security","Details":"HSTS"}],'
           '"[4. Deprecated HTTP Response Headers/Protocols and Insecure Values]":'
           '[{"Header":"X-XSS-Protection","Details":"deprecated"}]}')
    rows = wst.parse_tool("humble", out, "h", 6, "https://h")
    _assert_shape(rows)
    assert len(rows) == 3                                        # 2 missing + 1 deprecated; enabled ignored
    csp = next(r for r in rows if "Content-Security-Policy" in r["fields"]["title"])
    assert csp["fields"]["severity"] == "low" and csp["affected_component"] == "Content-Security-Policy"
    dep = next(r for r in rows if "X-XSS-Protection" in r["fields"]["title"])
    assert dep["fields"]["severity"] == "medium"


def test_arjun_hidden_params():
    out = '{"https://h/search.php": {"params": ["id", "q"], "method": "GET", "headers": {}}}'
    rows = wst.parse_tool("arjun", out, "h", 7, "https://h")
    _assert_shape(rows)
    assert len(rows) == 2
    assert {r["affected_component"] for r in rows} == {"id", "q"}
    assert all(r["affected_url"] == "https://h/search.php" for r in rows)


def test_enum_tools_summarize_surface():
    # crawlers/harvesters -> one URL-count summary row
    for slug in ("katana", "gospider", "hakrawler", "cariddi", "gau", "waybackurls", "urlfinder"):
        rows = wst.parse_tool(slug, "https://h/a\nhttps://h/b\nhttps://h/a\nnoise line", "h", 8, "https://h")
        _assert_shape(rows)
        assert len(rows) == 1 and rows[0]["fields"]["severity"] == "info"
        assert "2 " in rows[0]["fields"]["title"]                # 2 unique URLs, dupe collapsed
        assert rows[0]["source_slug"] == slug
    # subfinder -> subdomain count
    rows = wst.parse_tool("subfinder", "a.example.com\nb.example.com\n", "example.com", 8, "http://example.com")
    assert len(rows) == 1 and "2 subdomain" in rows[0]["fields"]["title"]
    # naabu -> open-port count
    rows = wst.parse_tool("naabu", "example.com:80\nexample.com:443\n", "example.com", 8, "http://example.com")
    assert len(rows) == 1 and "2 open port" in rows[0]["fields"]["title"]
    # empty output -> nothing (honest skip)
    for slug in ("katana", "subfinder", "naabu", "dnsx"):
        assert wst.parse_tool(slug, "", "h", 8, "http://h") == []


def test_parsers_never_raise_on_garbage():
    everyone = ("whatweb", "httpx", "wafw00f", "sslscan", "wapiti", "testssl", "sslyze", "humble", "arjun",
                "katana", "gospider", "hakrawler", "cariddi", "gau", "waybackurls", "urlfinder",
                "subfinder", "dnsx", "naabu")
    for name in everyone:
        assert wst.parse_tool(name, "", "h", 1, "http://h") == []        # empty -> nothing, every tool
        assert isinstance(wst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "http://h"), list)  # no raise
    # the JSON-driven parsers must reject non-JSON garbage outright (never a fabricated finding)
    for name in ("testssl", "sslyze", "humble", "arjun", "wapiti", "httpx"):
        assert wst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "http://h") == []
    assert wst.parse_tool("does-not-exist", "anything", "h", 1, "http://h") == []


def test_registry_specs_bounded_and_readonly():
    names = {s["name"] for s in wst.WEB_SCAN_TOOLS}
    # pass-1 (5) + pass-2 (14) all present and reachable
    assert {"whatweb", "httpx", "wafw00f", "sslscan", "wapiti", "testssl", "sslyze", "humble", "arjun",
            "katana", "gospider", "hakrawler", "cariddi", "gau", "waybackurls", "urlfinder", "subfinder",
            "dnsx", "naabu"} <= names
    assert len(names) == len(wst.WEB_SCAN_TOOLS)                 # no duplicate spec name
    for spec in wst.WEB_SCAN_TOOLS:
        argv = spec["argv"]("demo.testfire.net", "https://demo.testfire.net")
        assert isinstance(argv, list) and argv and all(isinstance(a, str) for a in argv)
        assert 0 < int(spec["timeout"]) <= 600                  # every tool is time-bounded
        assert callable(spec["parse"])
        # no destructive/writey flags leaked into any argv
        joined = " ".join(argv)
        assert not any(bad in joined for bad in (" rm -", "--delete", " -X DELETE", "mkfs"))


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


# ---- P0b pass 3: content discovery + fingerprint/screenshot/endpoint/param/secret/DAST -----------------
def test_content_discovery_summaries():
    ferox = wst.parse_tool("feroxbuster", "200      GET http://h/admin\n200      GET http://h/login\n"
                           "200      GET http://h/admin\n", "h", 1, "http://h")
    _assert_shape(ferox)
    assert len(ferox) == 1 and "2 path" in ferox[0]["fields"]["title"]      # dupe collapsed
    gob = wst.parse_tool("gobuster", "/admin (Status: 200) [Size: 10]\n/config (Status: 301)\n",
                         "h", 1, "http://h")
    assert len(gob) == 1 and "2 path" in gob[0]["fields"]["title"]
    assert "/admin" in gob[0]["fields"]["evidence"]
    dirb = wst.parse_tool("dirb", "+ http://h/backup (CODE:200|SIZE:5)\n==> DIRECTORY: http://h/js/\n",
                          "h", 1, "http://h")
    assert len(dirb) == 1 and "2 path" in dirb[0]["fields"]["title"]
    wf = wst.parse_tool("wfuzz", '000000042:   C=200      5 L\t12 W\t100 Ch\t"admin"\n'
                        '000000043:   C=301      0 L\t2 W\t10 Ch\t"config"\n', "h", 1, "http://h")
    assert len(wf) == 1 and "2 path" in wf[0]["fields"]["title"]
    # the wordlist path itself must never be reported as a discovered path
    assert wst.parse_tool("gobuster", "scanning /wordlists/Discovery/Web-Content/common.txt\n",
                          "h", 1, "http://h") == []


def test_webanalyze_json_tech():
    out = ('{"Hostname":"http://h","Matches":[{"AppName":"Apache","Version":"2.4.7"},'
           '{"AppName":"jQuery","Version":""},{"AppName":"Apache","Version":"2.4.7"}]}')
    rows = wst.parse_tool("webanalyze", out, "h", 1, "http://h")
    _assert_shape(rows)
    comps = {r["affected_component"] for r in rows}
    assert comps == {"Apache", "jQuery"}                                    # dedup by name
    assert any("2.4.7" in r["fields"]["title"] for r in rows)


def test_gowitness_screenshot_artifact():
    rows = wst.parse_tool("gowitness", "http---h.jpeg\nsome.log\n", "h", 1, "http://h")
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "info"
    assert "http---h.jpeg" in rows[0]["fields"]["evidence"]
    assert wst.parse_tool("gowitness", "no image here\n", "h", 1, "http://h") == []


def test_secretfinder_findings():
    out = ("[ + ] URL: http://h\n"
           "aws_access_key\t->\tAKIAIOSFODNN7EXAMPLE\n"
           "google_api\t->\tAIzaSyA-EXAMPLEKEY\n"
           "aws_access_key\t->\tAKIAIOSFODNN7EXAMPLE\n")
    rows = wst.parse_tool("secretfinder", out, "h", 1, "http://h")
    _assert_shape(rows)
    assert len(rows) == 2                                                    # url line skipped, dupe collapsed
    assert all(r["fields"]["severity"] == "medium" for r in rows)
    assert {r["affected_component"] for r in rows} == {"aws_access_key", "google_api"}


def test_jaeles_vuln_markers():
    out = ("[verbose] scanning http://h\n"
           "[VULN][High] - [sqli/generic-error] - http://h/item?id=1\n"
           "[Vulnerable][medium] - [xss/reflected] - http://h/search?q=x\n"
           "[info] nothing here http://h/ok\n")
    rows = wst.parse_tool("jaeles", out, "h", 1, "http://h")
    _assert_shape(rows)
    assert len(rows) == 2
    hi = next(r for r in rows if "sqli/generic-error" in r["fields"]["title"])
    assert hi["fields"]["severity"] == "high" and hi["affected_url"] == "http://h/item?id=1"


def test_linkfinder_and_url_harvest_enum():
    lf = wst.parse_tool("linkfinder", "/api/v1/users\n/api/v1/login\nhttps://h/static/app.js\n",
                        "h", 1, "http://h")
    assert len(lf) == 1 and "3 endpoint" in lf[0]["fields"]["title"]
    for slug, unit in (("paramspider", "URL"), ("waymore", "URL")):
        rows = wst.parse_tool(slug, "http://h/a?x=1\nhttp://h/b?y=2\n", "h", 1, "http://h")
        assert len(rows) == 1 and f"2 {unit}" in rows[0]["fields"]["title"]


def test_new_tools_registered_and_use_wordlist():
    names = {s["name"] for s in wst.WEB_SCAN_TOOLS}
    newly = {"feroxbuster", "gobuster", "dirb", "dirsearch", "wfuzz", "webanalyze", "gowitness",
             "linkfinder", "paramspider", "secretfinder", "waymore", "jaeles"}
    assert newly <= names
    # every content-discovery tool must reference the mounted wordlist in its argv
    for spec in wst.WEB_SCAN_TOOLS:
        if spec["name"] in ("feroxbuster", "gobuster", "dirb", "dirsearch", "wfuzz"):
            assert "/wordlists/" in " ".join(spec["argv"]("h", "http://h"))
    # all new parsers survive garbage without raising or fabricating
    for name in newly:
        assert wst.parse_tool(name, "", "h", 1, "http://h") == []
        assert isinstance(wst.parse_tool(name, "\x00 junk {[", "h", 1, "http://h"), list)


def test_wordlists_mount_added_to_docker_argv(monkeypatch):
    monkeypatch.setattr(svc.os.path, "isdir", lambda p: True)
    assert svc._wordlists_mount() == ["-v", "/root/wordlists:/wordlists:ro"]
    monkeypatch.setattr(svc.os.path, "isdir", lambda p: False)
    assert svc._wordlists_mount() == []


def test_unwired_accounting_is_accurate():
    """graphw00f + kiterunner are ABSENT from the deployed ava-web-scan image (verified read-only
    2026-09-30 on d0eb2aca410a — only paramspider/waymore in pipx, `kr`/graphw00f/x8/ffuf/wpscan all
    MISSING). They must be recorded as still-unwired (missing-from-image), never fabricated as working
    specs — the module's contract is never-fabricate."""
    wired = {s["name"] for s in wst.WEB_SCAN_TOOLS}
    unwired = wst._STILL_UNWIRED_WEB_SCAN_TOOLS
    # accurately listed as unwired...
    for t in ("graphw00f", "kiterunner", "ffuf", "x8", "wpscan", "joomscan", "amass", "trufflehog"):
        assert t in unwired and "missing" in unwired[t] or "installed" in unwired[t]
    assert "missing-from-image" in unwired["graphw00f"]
    assert "missing-from-image" in unwired["kiterunner"]
    # ...and NOT masquerading as a working, wired tool
    assert not ({"graphw00f", "kiterunner"} & wired)
    # a wired/unwired name can never appear in both accountings
    assert not (wired & set(unwired))
