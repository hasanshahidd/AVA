"""storage-scan LINKAGE — the ava-storage-scan arsenal registry (storage_scan_tools). STANDALONE: imports ONLY
the new module (NOT service.py). Deterministic + offline: each parser is fed CAPTURED sample tool output and we
assert the normalized finding rows (shape, severity, port/component, source slug). No live scan, no docker.
"""
import grc.modules.pentest.storage_scan_tools as sst


# ---- row shape contract (matches linux_scan_tools._lrow so dedup + ingest consume it unchanged) -----------
def _assert_shape(rows):
    for r in rows:
        assert r["kind"] in ("network", "web")
        assert set(("vid", "source_slug", "title", "affected_url", "fields")) <= set(r)
        f = r["fields"]
        assert f["severity"] in sst._SEV
        assert f["source"].startswith("ai-pentest:") and f["plugin_family"] == "AI Pentest"
        assert f["status"] == "open" and f["title"]
        assert f["affected_host"]


# ---- reused linux parsers reachable through THIS registry ----------------------------------------------
def test_showmount_reused_nfs_exports():
    out = "Export list for 1.2.3.4:\n/srv/nfs/public       *\n/home                 10.0.0.0/8\n"
    rows = sst.parse_tool("showmount", out, "1.2.3.4", 1, "http://1.2.3.4")
    _assert_shape(rows)
    byexp = {r["affected_component"]: r for r in rows}
    assert byexp["/srv/nfs/public"]["fields"]["severity"] == "medium"   # world-readable (*)
    assert byexp["/home"]["fields"]["severity"] == "low"
    assert all(r["affected_port"] == 2049 for r in rows)


def test_rpcinfo_reused_services():
    out = ("   program vers proto   port  service\n"
           "    100000    4   tcp    111  portmapper\n"
           "    100003    3   tcp   2049  nfs\n")
    rows = sst.parse_tool("rpcinfo", out, "h", 2, "http://h")
    _assert_shape(rows)
    assert {r["affected_component"] for r in rows} == {"portmapper", "nfs"}


def test_smbmap_reused_anon_shares():
    out = ("\tpublic                            READ ONLY\tPublic share\n"
           "\tbackups                           READ, WRITE\tBackups\n"
           "\tADMIN$                            NO ACCESS\tRemote Admin\n")
    rows = sst.parse_tool("smbmap", out, "h", 3, "http://h")
    _assert_shape(rows)
    shares = {r["affected_component"]: r for r in rows}
    assert set(shares) == {"public", "backups"}                        # NO ACCESS dropped
    assert shares["public"]["fields"]["severity"] == "low"
    assert shares["backups"]["fields"]["severity"] == "medium"         # writable
    assert all(r["affected_port"] == 445 for r in rows)


def test_smbclient_reused_grepable():
    out = "Disk|public|Public share\nIPC|IPC$|IPC Service\nPrinter|hp|Office printer\n"
    rows = sst.parse_tool("smbclient", out, "h", 4, "http://h")
    _assert_shape(rows)
    shares = {r["affected_component"]: r for r in rows}
    assert set(shares) == {"public", "IPC$", "hp"}
    assert shares["public"]["fields"]["severity"] == "low"
    assert shares["IPC$"]["fields"]["severity"] == "info"


# ---- storage-specific parsers -------------------------------------------------------------------------
def test_nmap_nfs_exports_and_volume():
    out = ("PORT     STATE SERVICE\n"
           "2049/tcp open  nfs\n"
           "| nfs-showmount: \n"
           "|   /export/public  *\n"
           "|_  /srv/home       10.0.0.0/8\n"
           "| nfs-ls: Volume /export/public\n")
    rows = sst.parse_tool("nmap-nfs", out, "1.2.3.4", 5, "http://1.2.3.4")
    _assert_shape(rows)
    by = {r["affected_component"]: r for r in rows}
    assert by["/export/public"]["fields"]["severity"] == "medium"      # world-readable (appears once, deduped)
    assert by["/srv/home"]["fields"]["severity"] == "low"
    vol = next(r for r in rows if "volume" in r["fields"]["title"].lower())
    assert vol["fields"]["severity"] == "medium"
    assert all(r["affected_port"] == 2049 for r in rows)
    # statfs numeric-blocks rows are not mistaken for exports
    statfs = "| nfs-statfs: \n|   /mnt/nfs    1048576  512  1048064  1%  ...\n"
    assert sst.parse_tool("nmap-nfs", statfs, "h", 5, "http://h") == []
    assert sst.parse_tool("nmap-nfs", "", "h", 5, "http://h") == []


def test_nmap_smb_shares_and_os():
    out = ("| smb-enum-shares: \n"
           "|   account_used: guest\n"
           "|   \\\\10.0.0.5\\IPC$: \n"
           "|     Anonymous access: READ\n"
           "|   \\\\10.0.0.5\\data: \n"
           "|     Anonymous access: READ/WRITE\n"
           "|   \\\\10.0.0.5\\reports: \n"
           "|     Anonymous access: READ\n"
           "|   \\\\10.0.0.5\\locked: \n"
           "|     Anonymous access: <none>\n"
           "| smb-os-discovery: \n"
           "|   OS: Windows Server 2016 Standard\n")
    rows = sst.parse_tool("nmap-smb", out, "10.0.0.5", 6, "http://10.0.0.5")
    _assert_shape(rows)
    shares = {r["affected_component"]: r for r in rows if r["affected_component"]}
    assert shares["data"]["fields"]["severity"] == "medium"            # writable non-default
    assert shares["reports"]["fields"]["severity"] == "low"            # readable non-default
    assert shares["IPC$"]["fields"]["severity"] == "info"              # default/admin share
    assert "locked" not in shares                                      # <none> access dropped
    assert any("host OS" in r["fields"]["title"] for r in rows)
    assert all(r["affected_port"] == 445 for r in rows)
    assert sst.parse_tool("nmap-smb", "", "h", 6, "http://h") == []


def test_nmap_iscsi_targets_and_auth():
    out = ("PORT     STATE SERVICE\n"
           "3260/tcp open  iscsi\n"
           "| iscsi-info: \n"
           "|   iqn.2001-04.com.example:storage.lun1: \n"
           "|     Address: 10.0.0.5:3260,1\n"
           "|_    Authentication: NOT required\n")
    rows = sst.parse_tool("nmap-iscsi", out, "10.0.0.5", 7, "http://10.0.0.5")
    _assert_shape(rows)
    assert any(r["fields"]["severity"] == "low" and "target exposed" in r["fields"]["title"] for r in rows)
    noauth = [r for r in rows if r["fields"]["severity"] == "medium"]
    assert noauth and "CHAP not required" in noauth[0]["fields"]["title"]
    assert all(r["affected_port"] == 3260 and "lun1" in r["affected_component"] for r in rows)
    assert sst.parse_tool("nmap-iscsi", "", "h", 7, "http://h") == []


def test_s3_probe_public_bucket_xml():
    out = ('<?xml version="1.0" encoding="UTF-8"?>'
           '<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/">'
           '<Name>acme-backups</Name>'
           '<Contents><Key>db.sql</Key></Contents>'
           '<Contents><Key>secrets.env</Key></Contents></ListBucketResult>')
    rows = sst.parse_tool("s3-probe", out, "acme-backups", 8, "http://acme-backups")
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "high" and rows[0]["affected_port"] == 443
    assert "2 object" in rows[0]["fields"]["title"]
    # aws s3 ls --no-sign-request listing also parses
    ls = "2023-05-01 10:00:00       1024 index.html\n                           PRE backups/\n"
    lsrows = sst.parse_tool("s3-probe", ls, "acme", 8, "http://acme")
    assert len(lsrows) == 1 and lsrows[0]["fields"]["severity"] == "high"
    # AccessDenied / empty -> honest skip (no fabricated finding)
    denied = "<Error><Code>AccessDenied</Code><Message>Access Denied</Message></Error>"
    assert sst.parse_tool("s3-probe", denied, "h", 8, "http://h") == []
    assert sst.parse_tool("s3-probe", "", "h", 8, "http://h") == []


def test_rsync_anonymous_modules():
    out = ("backups        \tBackup share\n"
           "data           \tData files\n")
    rows = sst.parse_tool("rsync", out, "1.2.3.4", 9, "http://1.2.3.4")
    _assert_shape(rows)
    assert {r["affected_component"] for r in rows} == {"backups", "data"}
    assert all(r["fields"]["severity"] == "medium" and r["affected_port"] == 873 for r in rows)
    # @ERROR / connection failure -> honest skip
    assert sst.parse_tool("rsync", "@ERROR: Unknown module 'x'\n", "h", 9, "http://h") == []
    assert sst.parse_tool("rsync", "", "h", 9, "http://h") == []


def test_ftp_anonymous_login():
    out = ("drwxr-xr-x    2 0        0            4096 Jan 01 12:00 pub\n"
           "-rw-r--r--    1 0        0             128 Jan 01 12:00 readme.txt\n")
    rows = sst.parse_tool("ftp", out, "1.2.3.4", 10, "http://1.2.3.4")
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "medium" and rows[0]["affected_port"] == 21
    # 230 banner with no listing still counts
    assert len(sst.parse_tool("ftp", "230 Login successful.\n", "h", 10, "http://h")) == 1
    # 530 denial -> honest skip
    assert sst.parse_tool("ftp", "curl: (67) Access denied: 530 Login incorrect\n", "h", 10, "http://h") == []
    assert sst.parse_tool("ftp", "", "h", 10, "http://h") == []


# ---- registry invariants + honesty --------------------------------------------------------------------
def test_registry_specs_bounded_and_readonly():
    names = {s["name"] for s in sst.STORAGE_SCAN_TOOLS}
    assert {"showmount", "nmap-nfs", "rpcinfo", "smbmap", "smbclient", "nmap-smb", "nmap-iscsi",
            "s3-probe", "rsync", "ftp"} == names
    assert len(names) == len(sst.STORAGE_SCAN_TOOLS)                   # no duplicate spec name
    for spec in sst.STORAGE_SCAN_TOOLS:
        argv = spec["argv"]("1.2.3.4", "https://1.2.3.4")
        assert isinstance(argv, list) and argv and all(isinstance(a, str) for a in argv)
        assert 0 < int(spec["timeout"]) <= 600
        assert callable(spec["parse"])
        joined = " ".join(argv)
        assert not any(bad in joined for bad in (" rm -", "--delete", " -X DELETE", "mkfs",
                                                 " put ", "--remove"))
        # the only write a spec may do is the no-sign-request READ `s3 ls`; no bucket writes
        assert " s3 cp " not in joined and " s3 sync " not in joined


def test_still_unwired_and_missing_are_honest():
    names = {s["name"] for s in sst.STORAGE_SCAN_TOOLS}
    assert not (set(sst._STILL_UNWIRED_STORAGE_SCAN_TOOLS) & names)
    assert not (set(sst._MISSING_FROM_IMAGE) & names)


def test_parsers_never_raise_on_garbage():
    for name in ("showmount", "nmap-nfs", "rpcinfo", "smbmap", "smbclient", "nmap-smb", "nmap-iscsi",
                 "s3-probe", "rsync", "ftp"):
        assert sst.parse_tool(name, "", "h", 1, "http://h") == []                      # empty -> nothing
        assert isinstance(sst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "http://h"), list)  # no raise
    assert sst.parse_tool("does-not-exist", "anything", "h", 1, "http://h") == []
