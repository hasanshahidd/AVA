"""P0b kubernetes-scan LINKAGE — the ava-kubernetes-scan arsenal registry (kubernetes_scan_tools) parsed over
CAPTURED sample tool output. STANDALONE: imports ONLY the new module (not service.py). Deterministic + offline;
no live scan, no docker, no cluster. Asserts the normalized finding rows (shape, severity, port/component,
corroboration-ready source slug), the credential-gating flags on the cluster-posture tools, and honest skips.
"""
import grc.modules.pentest.kubernetes_scan_tools as kst


# ---- row shape contract (matches linux/cloud _row so dedup + ingest consume it unchanged) --------------
def _assert_shape(rows):
    for r in rows:
        assert r["kind"] in ("network", "cloud")         # own k8s rows = network; reused posture = cloud
        assert set(("vid", "source_slug", "title", "affected_url", "fields")) <= set(r)
        f = r["fields"]
        assert f["severity"] in kst._SEV
        assert f["source"].startswith("ai-pentest:") and f["plugin_family"] == "AI Pentest"
        assert f["status"] == "open" and f["title"]
        assert f["affected_host"]                         # a k8s-lane finding always names its cluster host


# ---- nmap (reused linux parser) — exposed control/data-plane ports + vulners CVEs ----------------------
def test_nmap_k8s_ports_and_cves():
    out = ("PORT      STATE SERVICE   VERSION\n"
           "6443/tcp  open  ssl/sun-sr-https\n"
           "10250/tcp open  http      Golang net/http server\n"
           "| vulners:\n"
           "|   cpe:/a:golang:go:\n"
           "|_      CVE-2021-44716  7.5   https://vulners.com/cve/CVE-2021-44716\n")
    rows = kst.parse_tool("nmap", out, "1.2.3.4", 1, "https://1.2.3.4")
    _assert_shape(rows)
    ports = {r["affected_port"] for r in rows if not r["cve_id"]}
    assert {6443, 10250} <= ports
    cves = {r["cve_id"]: r for r in rows if r["cve_id"]}
    assert cves["CVE-2021-44716"]["fields"]["severity"] == "high"       # 7.5
    assert all(r["source_slug"] == "nmap" and r["kind"] == "network" for r in rows)


# ---- kube-hunter — remote unauth hunt (vulnerabilities + exposed services) -----------------------------
def test_kube_hunter_vulns_and_services():
    out = ('{"nodes":[{"type":"Node/Master","location":"1.2.3.4"}],'
           '"services":[{"service":"Kubelet API","location":"1.2.3.4:10250",'
           '"description":"The kubelet is the main component in every Node"}],'
           '"vulnerabilities":[{"location":"1.2.3.4:10250","category":"Remote Code Execution",'
           '"severity":"high","vulnerability":"Anonymous Authentication","description":"The kubelet is '
           'misconfigured","evidence":"pods","vid":"KHV004"},'
           '{"location":"1.2.3.4:6443","category":"Information Disclosure","severity":"medium",'
           '"vulnerability":"K8s Version Disclosure","vid":"KHV002"}]}')
    rows = kst.parse_tool("kube-hunter", out, "1.2.3.4", 1, "https://1.2.3.4")
    _assert_shape(rows)
    vulns = {r["affected_component"]: r for r in rows if r["fields"]["severity"] != "info"}
    assert vulns["KHV004"]["fields"]["severity"] == "high" and vulns["KHV004"]["affected_port"] == 10250
    assert vulns["KHV002"]["fields"]["severity"] == "medium" and vulns["KHV002"]["affected_port"] == 6443
    svc = [r for r in rows if r["fields"]["severity"] == "info"]
    assert svc and svc[0]["affected_component"] == "Kubelet API" and svc[0]["affected_port"] == 10250
    assert all(r["source_slug"] == "kube-hunter" for r in rows)
    assert kst.parse_tool("kube-hunter", "not json", "h", 1, "https://h") == []


# ---- kubectl — anonymous apiserver probe (critical anon-read / secured skip / version disclosure) -------
def test_kubectl_anonymous_api_read_critical():
    out = ('Client Version: v1.28.3\nServer Version: v1.28.3\n'
           '{"kind":"NamespaceList","apiVersion":"v1","items":[{"metadata":{"name":"default"}}]}')
    rows = kst.parse_tool("kubectl", out, "1.2.3.4", 1, "https://1.2.3.4")
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "critical"
    assert rows[0]["affected_port"] == 6443 and "ANONYMOUS" in rows[0]["fields"]["title"]


def test_kubectl_secured_cluster_honest_skip():
    out = ('Client Version: v1.28.3\nServer Version: v1.28.3\n'
           'error: You must be logged in to the server (Unauthorized)')
    assert kst.parse_tool("kubectl", out, "h", 1, "https://h") == []


def test_kubectl_anonymous_version_disclosure_low():
    out = 'Client Version: v1.28.3\nServer Version: v1.29.1\n'   # /version anon, but list not attempted/denied
    rows = kst.parse_tool("kubectl", out, "h", 1, "https://h")
    _assert_shape(rows)
    assert len(rows) == 1 and rows[0]["fields"]["severity"] == "low"
    assert "v1.29.1" in rows[0]["fields"]["title"] and rows[0]["affected_port"] == 6443
    assert kst.parse_tool("kubectl", "", "h", 1, "https://h") == []


# ---- kubeaudit — workload audit JSONL (error->high, warning->medium) -----------------------------------
def test_kubeaudit_jsonl_levels():
    out = ('{"level":"error","msg":"privileged set to true","AuditResultName":"CapabilityAdded",'
           '"ResourceKind":"Deployment","ResourceName":"nginx","ResourceNamespace":"default"}\n'
           '{"level":"warning","msg":"runAsNonRoot not set","AuditResultName":"RunAsNonRootPSCNilCSCNil",'
           '"ResourceKind":"Deployment","ResourceName":"nginx","ResourceNamespace":"default"}\n'
           '{"level":"info","msg":"all good","AuditResultName":"Ok"}\n')
    rows = kst.parse_tool("kubeaudit", out, "cluster", 1, "https://cluster")
    _assert_shape(rows)
    byname = {r["fields"]["evidence"].split()[1]: r for r in rows}
    assert byname["CapabilityAdded"]["fields"]["severity"] == "high"
    assert byname["RunAsNonRootPSCNilCSCNil"]["fields"]["severity"] == "medium"
    assert byname["Ok"]["fields"]["severity"] == "info"
    assert all(r["source_slug"] == "kubeaudit" for r in rows)
    assert kst.parse_tool("kubeaudit", "", "h", 1, "https://h") == []


# ---- trivy k8s — misconfigurations (KSV*) + image CVEs -------------------------------------------------
def test_trivy_k8s_misconfig_and_cve():
    out = ('{"ClusterName":"minikube","Resources":[{"Namespace":"default","Kind":"Deployment","Name":"app",'
           '"Results":[{"Target":"Deployment/app","Class":"config","Misconfigurations":['
           '{"ID":"KSV001","Title":"Process can elevate its own privileges","Severity":"HIGH",'
           '"Description":"No default"}],'
           '"Vulnerabilities":[{"VulnerabilityID":"CVE-2023-1234","PkgName":"openssl",'
           '"InstalledVersion":"1.1.1","Severity":"CRITICAL"}]}]}]}')
    rows = kst.parse_tool("trivy", out, "cluster", 1, "https://cluster")
    _assert_shape(rows)
    mc = next(r for r in rows if r["affected_component"] == "KSV001")
    assert mc["fields"]["severity"] == "high" and "default/Deployment/app" in mc["fields"]["evidence"]
    cve = next(r for r in rows if r["cve_id"] == "CVE-2023-1234")
    assert cve["fields"]["severity"] == "critical" and cve["affected_component"] == "openssl"
    assert all(r["source_slug"] == "trivy" for r in rows)
    assert kst.parse_tool("trivy", "{}", "h", 1, "https://h") == []
    assert kst.parse_tool("trivy", "not json", "h", 1, "https://h") == []


# ---- reused cloud posture parsers reachable via THIS registry (kind="cloud") ---------------------------
def test_reused_kubescape_and_kube_bench():
    ks = ('{"summaryDetails":{"controls":{"C-0016":{"controlID":"C-0016","name":"Allow privilege '
          'escalation","scoreFactor":8.0,"ResourceCounters":{"failedResources":3,"passedResources":1}}}}}')
    rows = kst.parse_tool("kubescape", ks, "cluster", 1, "https://cluster")
    _assert_shape(rows)
    assert rows and rows[0]["kind"] == "cloud" and rows[0]["fields"]["severity"] == "high"
    assert rows[0]["source_slug"] == "kubescape"

    kb = ('{"Controls":[{"tests":[{"results":[{"test_number":"1.2.1","test_desc":"Ensure anonymous-auth is '
          'false","status":"FAIL","remediation":"set --anonymous-auth=false"}]}]}]}')
    bench = kst.parse_tool("kube-bench", kb, "cluster", 1, "https://cluster")
    _assert_shape(bench)
    assert bench and bench[0]["fields"]["severity"] == "high" and bench[0]["source_slug"] == "kube-bench"
    for n in ("kubescape", "kube-bench"):
        assert kst.parse_tool(n, "", "h", 1, "https://h") == []


# ---- credential gating: the cluster-posture tools are needs_creds + self-gate in argv ------------------
def test_cluster_posture_tools_are_creds_gated():
    gated = {s["name"]: s for s in kst.KUBERNETES_SCAN_TOOLS if s.get("needs_creds")}
    assert set(gated) == {"kube-bench", "kubescape", "kubeaudit", "trivy"}
    for name, spec in gated.items():
        joined = " ".join(spec["argv"]("1.2.3.4", "https://1.2.3.4"))
        # each self-gates on a kubeconfig / node config, exiting 0 (honest []) when none is present
        assert ("KUBECONFIG" in joined or "/input/kubeconfig" in joined
                or "/var/lib/kubelet" in joined) and "exit 0" in joined
    # the credential-free probes are NOT gated (they fire now against a bare endpoint)
    free = {s["name"] for s in kst.KUBERNETES_SCAN_TOOLS if not s.get("needs_creds")}
    assert free == {"nmap", "kube-hunter", "kubectl"}


# ---- honesty: still-unwired / missing recorded, and no overlap with wired names -----------------------
def test_still_unwired_and_missing_are_honest():
    names = {s["name"] for s in kst.KUBERNETES_SCAN_TOOLS}
    assert not (set(kst._STILL_UNWIRED_KUBERNETES_SCAN_TOOLS) & names)
    assert not (set(kst._MISSING_FROM_IMAGE) & names)
    # peirates is the exploit-lane escalation tool — correctly NOT in the read-only scan registry
    assert "peirates" in kst._STILL_UNWIRED_KUBERNETES_SCAN_TOOLS


# ---- parsers never raise on garbage + unknown tool is honest [] ---------------------------------------
def test_parsers_never_raise_on_garbage():
    everyone = ("nmap", "kube-hunter", "kubectl", "kube-bench", "kubescape", "kubeaudit", "trivy")
    for name in everyone:
        assert kst.parse_tool(name, "", "h", 1, "https://h") == []                     # empty -> nothing
        assert isinstance(kst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "https://h"), list)  # no raise
    # JSON-driven parsers must reject non-JSON garbage outright (never a fabricated finding)
    for name in ("kube-hunter", "kubeaudit", "trivy", "kube-bench", "kubescape"):
        assert kst.parse_tool(name, "\x00 not\n valid {[", "h", 1, "https://h") == []
    assert kst.parse_tool("does-not-exist", "anything", "h", 1, "https://h") == []


# ---- registry is bounded + read-only -----------------------------------------------------------------
def test_registry_specs_bounded_and_readonly():
    names = {s["name"] for s in kst.KUBERNETES_SCAN_TOOLS}
    assert {"nmap", "kube-hunter", "kubectl", "kube-bench", "kubescape", "kubeaudit", "trivy"} == names
    assert len(names) == len(kst.KUBERNETES_SCAN_TOOLS)               # no duplicate spec name
    for spec in kst.KUBERNETES_SCAN_TOOLS:
        argv = spec["argv"]("1.2.3.4", "https://1.2.3.4")
        assert isinstance(argv, list) and argv and all(isinstance(a, str) for a in argv)
        assert 0 < int(spec["timeout"]) <= 600                       # every tool is time-bounded
        assert callable(spec["parse"])
        joined = " ".join(argv)
        # no destructive / write-mutating flags leak into the read-only find sweep
        assert not any(bad in joined for bad in (" rm -", "--delete", " -X DELETE", "mkfs",
                                                 "exec ", "apply ", "--force"))
