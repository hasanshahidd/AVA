"""P0b linux-scan LINKAGE — the ava-linux-scan arsenal registry (linux_scan_tools) + its wiring into the
finder via the convention dispatcher (_SCAN_ARSENAL_KEY[("internal","linux")] == "linux").

Deterministic + offline: each parser is fed CAPTURED sample tool output and we assert the normalized finding
rows (shape, severity, port/component, corroboration-ready source slug). No live scan, no docker. Also
asserts the dispatcher loads THIS module by convention and honest-skips an unmapped sub-lane.
"""
import grc.modules.pentest.linux_scan_tools as lst
import grc.modules.pentest.service as svc


# ---- row shape contract (matches service._nikto_rows so dedup + ingest consume it unchanged) -----------
def _assert_shape(rows):
    for r in rows:
        assert r["kind"] in ("network", "web")          # linux host rows = network; reused web/TLS = web
        assert set(("vid", "source_slug", "title", "affected_url", "fields")) <= set(r)
        f = r["fields"]
        assert f["severity"] in lst._SEV
        assert f["source"].startswith("ai-pentest:") and f["plugin_family"] == "AI Pentest"
        assert f["status"] == "open" and f["title"]
        assert f["affected_host"]                        # a host-lane finding always names its host


def test_nmap_ports_and_vulners_cves():
    out = ("PORT     STATE SERVICE VERSION\n"
           "22/tcp   open  ssh     OpenSSH 7.4 (protocol 2.0)\n"
           "80/tcp   open  http    Apache httpd 2.4.6 ((CentOS))\n"
           "| vulners:\n"
           "|   cpe:/a:apache:http_server:2.4.6:\n"
           "|       CVE-2017-7679   7.5   https://vulners.com/cve/CVE-2017-7679\n"
           "|       CVE-2018-1312   6.8   https://vulners.com/cve/CVE-2018-1312\n"
           "|_      CVE-2019-0211   7.2   https://vulners.com/cve/CVE-2019-0211\n")
    rows = lst.parse_tool("nmap", out, "1.2.3.4", 1, "http://1.2.3.4")
    _assert_shape(rows)
    ports = [r for r in rows if not r["cve_id"]]
    cves = {r["cve_id"]: r for r in rows if r["cve_id"]}
    assert {r["affected_port"] for r in ports} == {22, 80}
    assert all(r["fields"]["severity"] == "info" for r in ports)
    assert cves["CVE-2017-7679"]["fields"]["severity"] == "high"      # 7.5
    assert cves["CVE-2018-1312"]["fields"]["severity"] == "medium"    # 6.8
    assert cves["CVE-2019-0211"]["fields"]["severity"] == "high"      # 7.2
    assert all(r["affected_port"] == 80 for r in cves.values())       # attached to the port they follow
    assert all(r["source_slug"] == "nmap" for r in rows)


def test_masscan_open_ports_dedup():
    out = ("Starting masscan 1.3.2\n"
           "Discovered open port 80/tcp on 1.2.3.4\n"
           "Discovered open port 22/tcp on 1.2.3.4\n"
           "Discovered open port 80/tcp on 1.2.3.4\n")
    rows = lst.parse_tool("masscan", out, "1.2.3.4", 2, "http://1.2.3.4")
    _assert_shape(rows)
    assert {r["affected_port"] for r in rows} == {80, 22}             # dupe 80 collapsed
    assert len(rows) == 2


def test_naabu_open_port_summary():
    rows = lst.parse_tool("naabu", "1.2.3.4:22\n1.2.3.4:80\n1.2.3.4:22\n", "1.2.3.4", 2, "http://1.2.3.4")
    _assert_shape(rows)
    assert len(rows) == 1 and "2 open port" in rows[0]["fields"]["title"]


def test_ssh_audit_cves_and_weak_algos():
    out = ('{"banner":{"raw":"SSH-2.0-OpenSSH_7.4","software":"OpenSSH_7.4"},'
           '"cves":[{"name":"CVE-2018-15473","cvssv2":5.0,"description":"username enumeration"},'
           '{"name":"CVE-2016-10012","cvssv2":7.2,"description":"privilege escalation"}],'
           '"recommendations":{"critical":{"del":{"kex":[{"name":"diffie-hellman-group1-sha1"}]}},'
           '"warning":{"del":{"enc":[{"name":"3des-cbc"}]}}}}')
    rows = lst.parse_tool("ssh-audit", out, "h", 3, "http://h")
    _assert_shape(rows)
    assert all(r["affected_port"] == 22 for r in rows)
    cves = {r["cve_id"]: r for r in rows if r["cve_id"]}
    assert cves["CVE-2018-15473"]["fields"]["severity"] == "medium"   # 5.0
    assert cves["CVE-2016-10012"]["fields"]["severity"] == "high"     # 7.2
    algos = {r["affected_component"]: r for r in rows if not r["cve_id"]}
    assert algos["diffie-hellman-group1-sha1"]["fields"]["severity"] == "high"   # critical rec
    assert algos["3des-cbc"]["fields"]["severity"] == "medium"                   # warning rec
    assert len(rows) == 4


def test_showmount_nfs_exports():
    out = "Export list for 1.2.3.4:\n/srv/nfs/public       *\n/home                 10.0.0.0/8\n"
    rows = lst.parse_tool("showmount", out, "1.2.3.4", 4, "http://1.2.3.4")
    _assert_shape(rows)
    assert len(rows) == 2
    byexp = {r["affected_component"]: r for r in rows}
    assert byexp["/srv/nfs/public"]["fields"]["severity"] == "medium"   # world-readable (*)
    assert byexp["/home"]["fields"]["severity"] == "low"                # restricted
    assert all(r["affected_port"] == 2049 for r in rows)


def test_rpcinfo_services_dedup():
    out = ("   program vers proto   port  service\n"
           "    100000    4   tcp    111  portmapper\n"
           "    100003    3   tcp   2049  nfs\n"
           "    100003    4   tcp   2049  nfs\n")
    rows = lst.parse_tool("rpcinfo", out, "h", 5, "http://h")
    _assert_shape(rows)
    assert {r["affected_component"] for r in rows} == {"portmapper", "nfs"}   # header skipped, nfs deduped
    nfs = next(r for r in rows if r["affected_component"] == "nfs")
    assert nfs["affected_port"] == 2049


def test_smbmap_anon_shares():
    out = ("[+] IP: 1.2.3.4:445\tName: host\n"
           "\tDisk                              Permissions\tComment\n"
           "\t----                              -----------\t-------\n"
           "\tADMIN$                            NO ACCESS\tRemote Admin\n"
           "\tpublic                            READ ONLY\tPublic share\n"
           "\tbackups                           READ, WRITE\tBackups\n")
    rows = lst.parse_tool("smbmap", out, "h", 6, "http://h")
    _assert_shape(rows)
    shares = {r["affected_component"]: r for r in rows}
    assert set(shares) == {"public", "backups"}                        # NO ACCESS + header/sep dropped
    assert shares["public"]["fields"]["severity"] == "low"
    assert shares["backups"]["fields"]["severity"] == "medium"         # writable
    assert all(r["affected_port"] == 445 for r in rows)


def test_onesixtyone_default_community():
    out = "Scanning 1 hosts, 1 communities\n1.2.3.4 [public] Linux host 3.10.0-1127.el7\n"
    rows = lst.parse_tool("onesixtyone", out, "1.2.3.4", 7, "http://1.2.3.4")
    _assert_shape(rows)
    assert len(rows) == 1
    assert rows[0]["fields"]["severity"] == "medium" and rows[0]["affected_port"] == 161
    assert "public" in rows[0]["fields"]["title"]


def test_ldapsearch_anonymous_bind():
    ctx = ("dn:\nnamingContexts: dc=example,dc=com\nnamingContexts: dc=corp,dc=example,dc=com\n\n"
           "search: 2\nresult: 0 Success\n")
    rows = lst.parse_tool("ldapsearch", ctx, "h", 8, "http://h")
    _assert_shape(rows)
    assert {r["affected_component"] for r in rows} == {"dc=example,dc=com", "dc=corp,dc=example,dc=com"}
    assert all(r["fields"]["severity"] == "medium" and r["affected_port"] == 389 for r in rows)
    # anon bind succeeds but no contexts -> single generic medium row
    only = lst.parse_tool("ldapsearch", "dn:\n\nsearch: 2\nresult: 0 Success\n", "h", 8, "http://h")
    assert len(only) == 1 and only[0]["fields"]["severity"] == "medium"
    # failed bind (non-zero result, no contexts) -> honest nothing
    assert lst.parse_tool("ldapsearch", "result: 32 No such object\n", "h", 8, "http://h") == []


def test_nbtscan_netbios_name():
    out = ("Doing NBT name scan for addresses from 1.2.3.4\n\n"
           "IP address       NetBIOS Name     Server    User\n"
           "-------------------------------------------------------\n"
           "1.2.3.4          HOSTNAME         <server>  HOSTNAME         00:11:22:33:44:55\n")
    rows = lst.parse_tool("nbtscan", out, "1.2.3.4", 9, "http://1.2.3.4")
    _assert_shape(rows)
    assert len(rows) == 1
    assert rows[0]["affected_component"] == "HOSTNAME" and rows[0]["affected_port"] == 139


def test_reused_web_and_tls_parsers_reachable():
    # the web-lane parsers are reused wholesale — reachable via THIS registry, producing kind="web" rows
    rows = lst.parse_tool("whatweb", "http://h [200 OK] HTTPServer[Apache/2.4.7], PHP[5.5.9]", "h", 1,
                          "http://h")
    _assert_shape(rows)
    assert rows and all(r["kind"] == "web" for r in rows)
    ssl = lst.parse_tool("sslscan", "  SSLv3     enabled\n", "h", 1, "https://h")
    _assert_shape(ssl)
    assert any("SSLv3" in r["fields"]["title"] for r in ssl)
    for n in ("sslscan", "testssl", "sslyze", "whatweb", "httpx", "wafw00f"):
        assert lst.parse_tool(n, "", "h", 1, "http://h") == []       # empty -> honest skip


def test_parsers_never_raise_on_garbage():
    everyone = ("nmap", "masscan", "naabu", "ssh-audit", "showmount", "rpcinfo", "smbmap", "onesixtyone",
                "ldapsearch", "nbtscan", "sslscan", "testssl", "sslyze", "whatweb", "httpx", "wafw00f")
    for name in everyone:
        assert lst.parse_tool(name, "", "h", 1, "http://h") == []                     # empty -> nothing
        assert isinstance(lst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "http://h"), list)  # no raise
    # JSON-driven parsers must reject non-JSON garbage outright (never a fabricated finding)
    for name in ("ssh-audit", "testssl", "sslyze", "httpx"):
        assert lst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "http://h") == []
    assert lst.parse_tool("does-not-exist", "anything", "h", 1, "http://h") == []


def test_registry_specs_bounded_and_readonly():
    names = {s["name"] for s in lst.LINUX_SCAN_TOOLS}
    assert {"nmap", "naabu", "masscan", "ssh-audit", "showmount", "rpcinfo", "smbmap", "onesixtyone",
            "ldapsearch", "nbtscan", "sslscan", "testssl", "sslyze", "whatweb", "httpx",
            "wafw00f"} <= names
    assert len(names) == len(lst.LINUX_SCAN_TOOLS)                    # no duplicate spec name
    # brute-force / already-wired tools must NOT have leaked into the read-only find registry
    assert not ({"hydra", "medusa", "netexec", "nuclei", "nikto", "swaks"} & names)
    for spec in lst.LINUX_SCAN_TOOLS:
        argv = spec["argv"]("1.2.3.4", "https://1.2.3.4")
        assert isinstance(argv, list) and argv and all(isinstance(a, str) for a in argv)
        assert 0 < int(spec["timeout"]) <= 600                       # every tool is time-bounded
        assert callable(spec["parse"])
        joined = " ".join(argv)
        assert not any(bad in joined for bad in (" rm -", "--delete", " -X DELETE", "mkfs", " -w ", "--write"))


# ---- wiring: the convention dispatcher loads THIS module for (internal, linux) + honest on unmapped ------
def test_dispatcher_loads_linux_module_by_convention(monkeypatch):
    def fake_run(lane, argv, timeout=0, input_bytes=None, phase="scan", subtype=None):
        if argv and argv[0] == "showmount":
            return {"stdout": "Export list for h:\n/data *\n", "stderr": "", "rc": 0, "error": None}
        return {"stdout": "", "stderr": "", "rc": 0, "error": None}

    monkeypatch.setattr(svc, "_lane_container_run", fake_run)
    rows = svc._lane_scan_arsenal_rows("internal", "linux", "h", 1, "http://h")
    assert any(r["source_slug"] == "showmount" for r in rows)        # module loaded + parsed by convention
    # an unmapped sub-lane -> honest [] (no run, no rows)
    assert svc._lane_scan_arsenal_rows("internal", "bogus", "h", 1, "http://h") == []
