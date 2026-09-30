"""P0b win-scan LINKAGE — the ava-win-scan arsenal registry (win_scan_tools) — Windows/AD host discovery
+ unauthenticated null-session enumeration.

Deterministic + offline: each parser is fed CAPTURED sample tool output (real formats/schemas confirmed
read-only against the ava-win-scan image) and we assert the normalized finding rows (shape, severity,
component, port, corroboration-ready source slug). No live scan, no docker. Rows use the same shape as
web_scan_tools._row (kind="network" for host findings, asset_type="windows" for per-type dedup) so
_dedup_findings + _write_rows consume them unchanged. Garbage-safety + registry bounded/read-only asserted.
"""
import grc.modules.pentest.win_scan_tools as wst


# ---- row shape contract (matches service._hexstrike_rows so dedup + ingest consume it unchanged) --------
def _assert_shape(rows):
    for r in rows:
        assert r["kind"] == "network"
        assert r["asset_type"] == "windows"
        assert set(("vid", "source_slug", "title", "fields")) <= set(r)
        f = r["fields"]
        assert f["severity"] in wst._SEV
        assert f["source"].startswith("ai-pentest:") and f["plugin_family"] == "AI Pentest"
        assert f["status"] == "open" and f["title"] and f["asset_type"] == "windows"


def test_netexec_host_signing_and_smbv1():
    out = ("SMB         10.10.10.5      445    DC01             [*] Windows Server 2019 Build 17763 x64 "
           "(name:DC01) (domain:corp.local) (signing:False) (SMBv1:True)")
    rows = wst.parse_tool("netexec", out, "10.10.10.5", 1, "http://10.10.10.5")
    _assert_shape(rows)
    titles = [r["fields"]["title"] for r in rows]
    assert any("SMB host" in t and "corp.local" in t for t in titles)
    signing = next(r for r in rows if "signing not required" in r["fields"]["title"])
    assert signing["fields"]["severity"] == "medium" and signing["affected_port"] == 445
    smbv1 = next(r for r in rows if "SMBv1" in r["fields"]["title"])
    assert smbv1["fields"]["severity"] == "high"
    assert all(r["source_slug"] == "netexec" for r in rows)


def test_netexec_hardened_host_only_info():
    out = ("SMB         10.0.0.9        445    SRV02            [*] Windows Server 2022 Build 20348 x64 "
           "(name:SRV02) (domain:corp.local) (signing:True) (SMBv1:False)")
    rows = wst.parse_tool("netexec", out, "10.0.0.9", 2, "http://10.0.0.9")
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "info"   # no signing/SMBv1 finding


def test_nbtscan_netbios_names():
    out = ("Doing NBT name scan for addresses from 10.0.0.5\n\n"
           "IP address       NetBIOS Name     Server    User             MAC address      \n"
           "------------------------------------------------------------------------------\n"
           "10.0.0.5         DC01             <server>  <unknown>        00:0c:29:ab:cd:ef\n")
    rows = wst.parse_tool("nbtscan", out, "10.0.0.5", 3, "http://10.0.0.5")
    _assert_shape(rows)
    assert len(rows) == 1
    assert rows[0]["fields"]["title"] == "NetBIOS name: DC01 (10.0.0.5)"
    assert rows[0]["affected_component"] == "DC01" and rows[0]["affected_port"] == 137
    assert "00:0c:29:ab:cd:ef" in rows[0]["fields"]["evidence"]


def test_smbmap_writable_readable_default_shares():
    out = ("[+] IP: 10.10.10.5:445\tName: dc01.corp.local\tStatus: Guest session\n"
           "\tDisk                    Permissions\tComment\n"
           "\t----                    -----------\t-------\n"
           "\tADMIN$                  NO ACCESS\tRemote Admin\n"
           "\tIPC$                    READ ONLY\tRemote IPC\n"
           "\tbackups                 READ, WRITE\tNightly backups\n"
           "\tpublic                  READ ONLY\tPublic files\n")
    rows = wst.parse_tool("smbmap", out, "10.10.10.5", 4, "http://10.10.10.5")
    _assert_shape(rows)
    host = next(r for r in rows if "SMB accessible" in r["fields"]["title"])
    assert host["fields"]["severity"] == "info"
    backups = next(r for r in rows if r["affected_component"] == "backups")
    assert backups["fields"]["severity"] == "high"                       # writable non-default = high
    public = next(r for r in rows if r["affected_component"] == "public")
    assert public["fields"]["severity"] == "low"                         # readable non-default = low
    ipc = next(r for r in rows if r["affected_component"] == "IPC$")
    assert ipc["fields"]["severity"] == "info"                           # default share = info
    # NO ACCESS shares are not surfaced
    assert not any(r["affected_component"] == "ADMIN$" for r in rows)


def test_ldapsearch_anonymous_rootdse():
    out = ("dn:\n"
           "domainFunctionality: 7\n"
           "defaultNamingContext: DC=corp,DC=local\n"
           "rootDomainNamingContext: DC=corp,DC=local\n"
           "dnsHostName: DC01.corp.local\n"
           "ldapServiceName: corp.local:dc01$@CORP.LOCAL\n"
           "supportedLDAPVersion: 3\n")
    rows = wst.parse_tool("ldapsearch", out, "10.10.10.5", 5, "http://10.10.10.5")
    _assert_shape(rows)
    anon = next(r for r in rows if "Anonymous LDAP bind" in r["fields"]["title"])
    assert anon["fields"]["severity"] == "medium" and anon["affected_port"] == 389
    assert any("DC=corp,DC=local" in r["fields"]["title"] for r in rows)
    assert "DC01.corp.local" in anon["fields"]["evidence"]


def test_snmpcheck_default_community():
    out = ("snmp-check v1.9 - SNMP enumerator\n\n"
           "[+] Try to connect to 10.0.0.7:161 using SNMPv1 and community 'public'\n\n"
           "[*] System information:\n\n"
           "  Hostname                      : WIN-SRV\n"
           "  Description                   : Hardware: Intel64 - Software: Windows Version 10.0\n"
           "  Uptime system                 : 3 days, 04:12:55.00\n")
    rows = wst.parse_tool("snmpcheck", out, "10.0.0.7", 6, "http://10.0.0.7")
    _assert_shape(rows)
    pub = next(r for r in rows if "default community" in r["fields"]["title"])
    assert pub["fields"]["severity"] == "low" and pub["affected_port"] == 161
    assert "WIN-SRV" in pub["fields"]["evidence"]
    # a timed-out host produces nothing (honest skip)
    miss = ("[+] Try to connect to 10.0.0.7:161 using SNMPv1 and community 'public'\n\n"
            "[!] 10.0.0.7:161 SNMP request timeout\n")
    assert wst.parse_tool("snmpcheck", miss, "10.0.0.7", 6, "http://10.0.0.7") == []


def test_enum4linux_null_session_full():
    doc = {
        "target": {"host": "10.10.10.5"},
        "credentials": {"auth_method": "null", "user": "", "password": ""},
        "listeners": {"LDAP": {"port": 389, "accessible": True},
                      "SMB": {"port": 445, "accessible": True},
                      "SMB over NetBIOS": {"port": 139, "accessible": False}},
        "smb_dialects": {"Supported dialects": {"SMB 1.0": True, "SMB 2.02": True, "SMB 3.0": True},
                         "Preferred dialect": "SMB 3.0", "SMB signing required": False},
        "sessions": {"Null session possible": True},
        "os_info": {"OS": "Windows Server 2019", "OS version": "10.0", "Server type string": "DC"},
        "smb_domain_info": {"NetBIOS computer name": "DC01", "NetBIOS domain name": "CORP",
                            "DNS domain": "corp.local", "FQDN": "DC01.corp.local",
                            "Derived membership": "domain member"},
        "users": {"1000": {"username": "alice"}, "1001": {"username": "bob"}},
        "groups": {"512": {"groupname": "Domain Admins"}},
        "shares": {"IPC$": {"access": {"mapping": "ok", "listing": "denied"}, "comment": "Remote IPC"},
                   "data": {"access": {"mapping": "ok", "listing": "ok"}, "comment": "Data"},
                   "secret": {"access": {"mapping": "denied", "listing": "denied"}, "comment": ""}},
        "policy": {"Minimum password length": 5, "Account lockout threshold": None},
    }
    import json as _j
    rows = wst.parse_tool("enum4linux", "BANNER\n" + _j.dumps(doc) + "\ntrailing", "10.10.10.5", 7,
                          "http://10.10.10.5")
    _assert_shape(rows)
    titles = [r["fields"]["title"] for r in rows]
    assert any("SMBv1" in t for t in titles)
    smbv1 = next(r for r in rows if "SMBv1" in r["fields"]["title"])
    assert smbv1["fields"]["severity"] == "high"
    assert any("signing not required" in t for t in titles)
    assert any("Null SMB session permitted" in t for t in titles)
    users = next(r for r in rows if "users enumerable" in r["fields"]["title"])
    assert users["fields"]["severity"] == "medium" and "2" in users["fields"]["title"]
    assert "alice" in users["fields"]["evidence"] and "bob" in users["fields"]["evidence"]
    # readable non-default share = low; default IPC$ = info; denied share not surfaced
    data = next(r for r in rows if r["affected_component"] == "data")
    assert data["fields"]["severity"] == "low"
    ipc = next(r for r in rows if r["affected_component"] == "IPC$")
    assert ipc["fields"]["severity"] == "info"
    assert not any(r["affected_component"] == "secret" for r in rows)
    assert any("Reachable Windows services" in t for t in titles)
    assert any(r["fields"]["title"].startswith("Password policy") for r in rows)


def test_enum4linux_dead_host_json_is_honest():
    # the exact JSON enum4linux-ng writes for an unreachable target (confirmed live) -> no findings
    dead = ('{"target":{"host":"127.0.0.1"},"credentials":{"auth_method":"null"},'
            '"listeners":{"LDAP":{"port":389,"accessible":false},"SMB":{"port":445,"accessible":false}},'
            '"domain":null,"nmblookup":null,'
            '"errors":{"listeners":{"enum_listeners":["Could not connect"]}}}')
    assert wst.parse_tool("enum4linux", dead, "127.0.0.1", 8, "http://127.0.0.1") == []


def test_rpcclient_null_session_users_groups_domain():
    out = ("\tDC01           Wk Sv PDC Tim NT   \n"
           "\tplatform_id     :\t500\n"
           "\tos version      :\t10.0\n"
           "Domain: CORP  Server: DC01\n"
           "user:[Administrator] rid:[0x1f4]\n"
           "user:[alice] rid:[0x3e8]\n"
           "group:[Domain Admins] rid:[0x200]\n")
    rows = wst.parse_tool("rpcclient", out, "10.10.10.5", 1, "http://10.10.10.5")
    _assert_shape(rows)
    users = next(r for r in rows if "users enumerable via null RPC" in r["fields"]["title"])
    assert users["fields"]["severity"] == "medium" and "2" in users["fields"]["title"]
    assert "alice" in users["fields"]["evidence"] and users["affected_port"] == 445
    assert any("Domain information" in r["fields"]["title"] and "CORP" in r["fields"]["title"] for r in rows)
    assert any(r["fields"]["title"].startswith("SMB/RPC host OS") for r in rows)
    assert any("groups enumerable" in r["fields"]["title"] for r in rows)
    # access-denied null session yields nothing
    assert wst.parse_tool("rpcclient", "Cannot connect: NT_STATUS_ACCESS_DENIED\n", "h", 1, "http://h") == []


def test_nmblookup_name_and_domain():
    out = ("Looking up status of 10.0.0.5\n"
           "\tDC01            <00> -         B <ACTIVE>\n"
           "\tCORP            <1c> - <GROUP> B <ACTIVE>\n"
           "\tCORP            <00> - <GROUP> B <ACTIVE>\n"
           "\n\tMAC Address = 00:0C:29:AB:CD:EF\n")
    rows = wst.parse_tool("nmblookup", out, "10.0.0.5", 2, "http://10.0.0.5")
    _assert_shape(rows)
    host = next(r for r in rows if r["fields"]["title"] == "NetBIOS name: DC01")
    assert host["affected_component"] == "DC01" and host["affected_port"] == 137
    assert "00:0C:29:AB:CD:EF" in host["fields"]["evidence"]
    assert any("NetBIOS/AD domain: CORP" in r["fields"]["title"] for r in rows)
    assert wst.parse_tool("nmblookup", "No reply from 10.0.0.5\n", "h", 2, "http://h") == []


def test_smbclient_null_share_listing():
    out = ("\n\tSharename       Type      Comment\n"
           "\t---------       ----      -------\n"
           "\tIPC$            IPC       Remote IPC\n"
           "\tdata            Disk      Data share\n"
           "\tNETLOGON        Disk      Logon server share\n")
    rows = wst.parse_tool("smbclient", out, "10.10.10.5", 3, "http://10.10.10.5")
    _assert_shape(rows)
    data = next(r for r in rows if r["affected_component"] == "data")
    assert data["fields"]["severity"] == "low" and data["affected_port"] == 445
    ipc = next(r for r in rows if r["affected_component"] == "IPC$")
    assert ipc["fields"]["severity"] == "info"
    netlogon = next(r for r in rows if r["affected_component"] == "NETLOGON")
    assert netlogon["fields"]["severity"] == "info"                      # default share
    # denied with no share table -> nothing
    assert wst.parse_tool("smbclient", "session setup failed: NT_STATUS_ACCESS_DENIED\n",
                          "h", 3, "http://h") == []


def test_snmpwalk_default_community():
    out = ("SNMPv2-MIB::sysDescr.0 = STRING: Hardware: Intel64 Family - Windows Version 10.0\n"
           "SNMPv2-MIB::sysName.0 = STRING: WIN-SRV\n")
    rows = wst.parse_tool("snmpwalk", out, "10.0.0.7", 4, "http://10.0.0.7")
    _assert_shape(rows)
    pub = next(r for r in rows if "default community" in r["fields"]["title"])
    assert pub["fields"]["severity"] == "low" and pub["affected_port"] == 161
    assert "WIN-SRV" in pub["fields"]["evidence"]
    assert wst.parse_tool("snmpwalk", "Timeout: No Response from 10.0.0.7\n", "h", 4, "http://h") == []


def test_onesixtyone_community_spray():
    out = ("10.0.0.7 [public] Hardware: Intel64 - Windows\n"
           "10.0.0.7 [secret123] Hardware: Intel64 - Windows\n")
    rows = wst.parse_tool("onesixtyone", out, "10.0.0.7", 5, "http://10.0.0.7")
    _assert_shape(rows)
    pub = next(r for r in rows if r["affected_component"] == "public")
    assert pub["fields"]["severity"] == "low" and pub["affected_port"] == 161
    guessed = next(r for r in rows if r["affected_component"] == "secret123")
    assert guessed["fields"]["severity"] == "medium"                     # non-default community = medium
    assert wst.parse_tool("onesixtyone", "", "h", 5, "http://h") == []


def test_braa_snmp_walk():
    out = ("10.0.0.7:.1.3.6.1.2.1.1.1.0:Hardware: Intel64 - Windows\n"
           "10.0.0.7:.1.3.6.1.2.1.1.5.0:WIN-SRV\n")
    rows = wst.parse_tool("braa", out, "10.0.0.7", 6, "http://10.0.0.7")
    _assert_shape(rows)
    assert any("SNMP readable via braa" in r["fields"]["title"] for r in rows)
    assert all(r["affected_port"] == 161 for r in rows)
    assert wst.parse_tool("braa", "no response\n", "h", 6, "http://h") == []


def test_lookupsid_anonymous_rid_cycling():
    out = ("[*] Brute forcing SIDs at 10.10.10.5\n"
           "[*] Domain SID is: S-1-5-21-1111111111-2222222222-3333333333\n"
           "500: CORP\\Administrator (SidTypeUser)\n"
           "1000: CORP\\alice (SidTypeUser)\n"
           "512: CORP\\Domain Admins (SidTypeGroup)\n")
    rows = wst.parse_tool("lookupsid", out, "10.10.10.5", 7, "http://10.10.10.5")
    _assert_shape(rows)
    users = next(r for r in rows if "users enumerable via anonymous RID" in r["fields"]["title"])
    assert users["fields"]["severity"] == "medium" and users["affected_port"] == 445
    assert "Administrator" in users["fields"]["evidence"] and "alice" in users["fields"]["evidence"]
    assert any("Domain SID disclosed" in r["fields"]["title"] for r in rows)
    assert wst.parse_tool("lookupsid", "[-] STATUS_ACCESS_DENIED\n", "h", 7, "http://h") == []


def test_samrdump_anonymous_users():
    out = ("[*] Retrieving endpoint list from 10.10.10.5\n"
           "Found domain(s):\n"
           " . CORP\n"
           " . Builtin\n"
           "[*] Looking up users in domain CORP\n"
           "Found user: Administrator, uid = 500\n"
           "Found user: bob, uid = 1001\n")
    rows = wst.parse_tool("samrdump", out, "10.10.10.5", 8, "http://10.10.10.5")
    _assert_shape(rows)
    users = next(r for r in rows if "users enumerable via anonymous SAMR" in r["fields"]["title"])
    assert users["fields"]["severity"] == "medium" and "bob" in users["fields"]["evidence"]
    assert any("SAMR domain(s)" in r["fields"]["title"] and "CORP" in r["fields"]["title"] for r in rows)
    assert wst.parse_tool("samrdump", "[-] SMB SessionError: STATUS_ACCESS_DENIED\n", "h", 8, "http://h") == []


def test_rpcdump_anonymous_epm():
    out = ("[*] Retrieving endpoint list from 10.10.10.5\n"
           "Protocol: [MS-RPRN]: Print System Remote Protocol\n"
           "UUID    : 12345678-1234-abcd-ef00-0123456789ab v1.0\n"
           "Protocol: [MS-SCMR]: Service Control Manager\n"
           "UUID    : 367abb81-9844-35f1-ad32-98f038001003 v2.0\n")
    rows = wst.parse_tool("rpcdump", out, "10.10.10.5", 9, "http://10.10.10.5")
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["affected_port"] == 135
    assert "RPC endpoints enumerable" in rows[0]["fields"]["title"]
    assert wst.parse_tool("rpcdump", "[-] Connection refused\n", "h", 9, "http://h") == []


def test_parsers_never_raise_on_garbage():
    everyone = ("netexec", "nbtscan", "smbmap", "ldapsearch", "snmpcheck", "enum4linux",
                "rpcclient", "nmblookup", "smbclient", "snmpwalk", "onesixtyone", "braa",
                "lookupsid", "samrdump", "rpcdump")
    for name in everyone:
        assert wst.parse_tool(name, "", "h", 1, "http://h") == []            # empty -> nothing
        assert isinstance(wst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "http://h"), list)  # no raise
    # the JSON-driven parser rejects non-JSON garbage outright (never a fabricated finding)
    assert wst.parse_tool("enum4linux", "\x00 not\n valid {[", "h", 1, "http://h") == []
    assert wst.parse_tool("does-not-exist", "anything", "h", 1, "http://h") == []


def test_registry_specs_bounded_and_readonly():
    names = {s["name"] for s in wst.WIN_SCAN_TOOLS}
    assert {"netexec", "nbtscan", "smbmap", "ldapsearch", "snmpcheck", "enum4linux",
            "rpcclient", "nmblookup", "smbclient", "snmpwalk", "onesixtyone", "braa",
            "lookupsid", "samrdump", "rpcdump"} <= names
    assert len(names) == len(wst.WIN_SCAN_TOOLS)                             # no duplicate spec name
    for spec in wst.WIN_SCAN_TOOLS:
        argv = spec["argv"]("10.10.10.5", "http://10.10.10.5")
        assert isinstance(argv, list) and argv and all(isinstance(a, str) for a in argv)
        assert 0 < int(spec["timeout"]) <= 600                              # every tool is time-bounded
        assert callable(spec["parse"])
        joined = " ".join(argv)
        # unauthenticated + read-only: no creds, no destructive/writey flags leaked into any argv
        assert not any(bad in joined for bad in (" rm -", "--delete", " -X DELETE", "mkfs", "-u admin",
                                                 "--password", "put "))
        # the host/IP is always present in the argv (tool actually targets something)
        assert "10.10.10.5" in joined
