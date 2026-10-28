// Ava Compliance Agent — a single static binary that runs on a customer host,
// collects the up-front discovery inventory LOCALLY (OS, software, network,
// basic hardware) and sends it to the cloud. For machines we can't reach over
// the network or where the client won't share credentials.
//
// stdlib only, except golang.org/x/sys/windows/svc (Windows-only, so the binary
// can run as a real auto-restarting Windows service). Still cross-compiles for
// Windows, Linux and macOS and runs with zero runtime deps on the target.
//
// Config (baked in by the per-download installer, or passed as env):
//
//	AVA_URL     cloud base, e.g. https://app.caiva.io   (required)
//	AVA_ENROLL  one-time enrollment token               (first run only)
//	AVA_ONCE    "1" => collect+report once and exit (no service loop)
//
// State (the long-lived api_token, after enrollment) persists at:
//
//	linux:   /etc/ava-agent/agent.json
//	windows: %ProgramData%\AvaAgent\agent.json
package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"encoding/xml"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"
)

const agentVersion = "1.0.0"

type state struct {
	APIToken string `json:"api_token"`
}

func statePath() string {
	if runtime.GOOS == "windows" {
		base := os.Getenv("ProgramData")
		if base == "" {
			base = `C:\ProgramData`
		}
		return filepath.Join(base, "AvaAgent", "agent.json")
	}
	return "/etc/ava-agent/agent.json"
}

func loadState() state {
	var s state
	b, err := os.ReadFile(statePath())
	if err == nil {
		_ = json.Unmarshal(b, &s)
	}
	return s
}

func saveState(s state) error {
	p := statePath()
	if err := os.MkdirAll(filepath.Dir(p), 0o700); err != nil {
		return err
	}
	b, _ := json.MarshalIndent(s, "", "  ")
	return os.WriteFile(p, b, 0o600)
}

// loadConfig reads url/tenant/enroll the installer wrote next to the state file
// and puts them in the process env (only when not already set). A Windows SERVICE
// does NOT reliably inherit Machine env vars set just before it is started, so the
// config file — not the registry — is the dependable source. No-op when absent
// (Linux systemd / macOS launchd bake the env into the unit/plist).
func loadConfig() {
	b, err := os.ReadFile(filepath.Join(filepath.Dir(statePath()), "config.json"))
	if err != nil {
		return
	}
	var c struct{ URL, Tenant, Enroll string }
	if json.Unmarshal(b, &c) != nil {
		return
	}
	setenvIfEmpty("AVA_URL", c.URL)
	setenvIfEmpty("AVA_TENANT", c.Tenant)
	setenvIfEmpty("AVA_ENROLL", c.Enroll)
}

func setenvIfEmpty(k, v string) {
	if v != "" && os.Getenv(k) == "" {
		_ = os.Setenv(k, v)
	}
}

var httpc = &http.Client{Timeout: 180 * time.Second} // generous for multi-MB datastream downloads

func post(url, bearer string, payload any) ([]byte, int, error) {
	body, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", url, bytes.NewReader(body))
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("Content-Type", "application/json")
	// Per-tenant DB routing: the backend resolves which tenant database to use
	// from this header (baked into the installer from the console's tenant).
	if t := os.Getenv("AVA_TENANT"); t != "" {
		req.Header.Set("X-Tenant-Slug", t)
	}
	if bearer != "" {
		req.Header.Set("Authorization", "Bearer "+bearer)
	}
	resp, err := httpc.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	rb, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	return rb, resp.StatusCode, nil
}

func get(url, bearer string) ([]byte, int, error) {
	req, err := http.NewRequest("GET", url, nil)
	if err != nil {
		return nil, 0, err
	}
	if t := os.Getenv("AVA_TENANT"); t != "" {
		req.Header.Set("X-Tenant-Slug", t)
	}
	if bearer != "" {
		req.Header.Set("Authorization", "Bearer "+bearer)
	}
	resp, err := httpc.Do(req)
	if err != nil {
		return nil, 0, err
	}
	defer resp.Body.Close()
	rb, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	return rb, resp.StatusCode, nil
}

// run executes a command best-effort; "" on any failure (never fatal).
func run(name string, args ...string) string {
	var out bytes.Buffer
	cmd := exec.Command(name, args...)
	cmd.Stdout = &out
	cmd.Stderr = io.Discard
	if err := cmd.Run(); err != nil {
		return ""
	}
	return strings.TrimSpace(out.String())
}

func osName() string {
	if runtime.GOOS == "windows" {
		if v := run("powershell", "-NoProfile", "-Command",
			"(Get-CimInstance Win32_OperatingSystem).Caption"); v != "" {
			return v
		}
		return run("cmd", "/c", "ver")
	}
	if runtime.GOOS == "darwin" {
		name := run("sw_vers", "-productName")   // "macOS"
		ver := run("sw_vers", "-productVersion") // "14.5"
		if name != "" {
			return strings.TrimSpace(name + " " + ver)
		}
		return "macOS"
	}
	// Linux: PRETTY_NAME from /etc/os-release
	if f, err := os.Open("/etc/os-release"); err == nil {
		defer f.Close()
		sc := bufio.NewScanner(f)
		for sc.Scan() {
			line := sc.Text()
			if strings.HasPrefix(line, "PRETTY_NAME=") {
				return strings.Trim(strings.TrimPrefix(line, "PRETTY_NAME="), `"`)
			}
		}
	}
	return runtime.GOOS
}

// detectDomain reports the machine's AD/DNS domain and whether it is actually
// domain-joined. The backend uses this to refuse enrollment of a PC that isn't
// on the required domain (a leaked install command run on a WORKGROUP/home PC).
func detectDomain() (string, bool) {
	switch runtime.GOOS {
	case "windows":
		// Win32_ComputerSystem.Domain is the AD DNS domain when joined, else the
		// workgroup name; PartOfDomain is the authoritative join flag.
		out := run("powershell", "-NoProfile", "-Command",
			"$cs=Get-CimInstance Win32_ComputerSystem; Write-Output ($cs.Domain + '|' + $cs.PartOfDomain)")
		p := strings.SplitN(out, "|", 2)
		joined := len(p) == 2 && strings.EqualFold(strings.TrimSpace(p[1]), "True")
		return strings.TrimSpace(p[0]), joined
	case "linux":
		// Only an actual realm/AD join counts as part-of-domain.
		if r := run("realm", "list", "--name-only"); r != "" {
			return strings.TrimSpace(strings.Split(r, "\n")[0]), true
		}
		return "", false
	case "darwin":
		// dsconfigad prints the bound AD domain when the Mac is AD-joined.
		for _, line := range strings.Split(run("dsconfigad", "-show"), "\n") {
			if i := strings.Index(line, "="); i >= 0 && strings.Contains(strings.ToLower(line), "domain") {
				if v := strings.TrimSpace(line[i+1:]); v != "" {
					return v, true
				}
			}
		}
		return "", false
	}
	return "", false
}

type sw struct {
	Name    string `json:"name"`
	Version string `json:"version"`
}

func software() []sw {
	var list []sw
	if runtime.GOOS == "windows" {
		// Installed programs from the uninstall registry keys.
		out := run("powershell", "-NoProfile", "-Command",
			`Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*,`+
				`HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* `+
				`| Where-Object {$_.DisplayName} | Select-Object DisplayName,DisplayVersion `+
				`| ForEach-Object {"$($_.DisplayName)|$($_.DisplayVersion)"}`)
		for _, line := range strings.Split(out, "\n") {
			line = strings.TrimSpace(line)
			if line == "" {
				continue
			}
			p := strings.SplitN(line, "|", 2)
			s := sw{Name: p[0]}
			if len(p) == 2 {
				s.Version = p[1]
			}
			list = append(list, s)
		}
		return list
	}
	if runtime.GOOS == "darwin" {
		// Best-effort: Homebrew formulae+casks. No brew → empty list (inventory
		// still reports OS/hardware/network); macOS app enumeration is heavier
		// and left for later.
		if out := run("brew", "list", "--versions"); out != "" {
			for _, line := range strings.Split(out, "\n") {
				line = strings.TrimSpace(line)
				if line == "" {
					continue
				}
				p := strings.SplitN(line, " ", 2)
				s := sw{Name: p[0]}
				if len(p) == 2 {
					s.Version = strings.TrimSpace(p[1])
				}
				list = append(list, s)
			}
		}
		return list
	}
	// Linux: dpkg then rpm.
	if out := run("dpkg-query", "-W", "-f=${Package}\t${Version}\n"); out != "" {
		for _, line := range strings.Split(out, "\n") {
			p := strings.SplitN(line, "\t", 2)
			if p[0] == "" {
				continue
			}
			s := sw{Name: p[0]}
			if len(p) == 2 {
				s.Version = p[1]
			}
			list = append(list, s)
		}
		return list
	}
	if out := run("rpm", "-qa", "--qf", "%{NAME}\t%{VERSION}\n"); out != "" {
		for _, line := range strings.Split(out, "\n") {
			p := strings.SplitN(line, "\t", 2)
			if p[0] == "" {
				continue
			}
			s := sw{Name: p[0]}
			if len(p) == 2 {
				s.Version = p[1]
			}
			list = append(list, s)
		}
	}
	return list
}

// primaryIP returns the first non-loopback IPv4, plus all MACs seen.
func netInfo() (string, []string) {
	ip := ""
	var macs []string
	ifaces, _ := net.Interfaces()
	for _, i := range ifaces {
		if i.Flags&net.FlagLoopback != 0 || i.HardwareAddr.String() == "" {
			continue
		}
		macs = append(macs, i.HardwareAddr.String())
		if ip == "" {
			addrs, _ := i.Addrs()
			for _, a := range addrs {
				if ipn, ok := a.(*net.IPNet); ok && ipn.IP.To4() != nil && !ipn.IP.IsLoopback() {
					ip = ipn.IP.String()
					break
				}
			}
		}
	}
	return ip, macs
}

func collectInventory() (map[string]any, string, string) {
	host, _ := os.Hostname()
	ip, macs := netInfo()
	inv := map[string]any{
		"os": map[string]any{"family": runtime.GOOS, "name": osName(), "arch": runtime.GOARCH},
		"hardware": map[string]any{
			"cpu_count": runtime.NumCPU(),
			"memory":    memInfo(),
		},
		"network": map[string]any{"primary_ip": ip, "macs": macs},
	}
	return inv, host, ip
}

func memInfo() string {
	if runtime.GOOS == "windows" {
		return run("powershell", "-NoProfile", "-Command",
			"[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB,1).ToString()+' GB'")
	}
	if runtime.GOOS == "darwin" {
		if b := run("sysctl", "-n", "hw.memsize"); b != "" {
			if n, err := strconv.ParseInt(strings.TrimSpace(b), 10, 64); err == nil && n > 0 {
				return fmt.Sprintf("%.1f GB", float64(n)/(1<<30))
			}
		}
		return ""
	}
	if f, err := os.Open("/proc/meminfo"); err == nil {
		defer f.Close()
		sc := bufio.NewScanner(f)
		for sc.Scan() {
			if strings.HasPrefix(sc.Text(), "MemTotal:") {
				return strings.TrimSpace(strings.TrimPrefix(sc.Text(), "MemTotal:"))
			}
		}
	}
	return ""
}

func base() string { return strings.TrimRight(os.Getenv("AVA_URL"), "/") }

func enroll() (string, error) {
	tok := os.Getenv("AVA_ENROLL")
	if tok == "" {
		return "", fmt.Errorf("no AVA_ENROLL token and no saved api_token — nothing to authenticate with")
	}
	host, _ := os.Hostname()
	ip, _ := netInfo()
	dom, joined := detectDomain()
	rb, code, err := post(base()+"/api/agents/enroll", "", map[string]any{
		"enrollment_token": tok, "hostname": host, "os_family": runtime.GOOS,
		"agent_version": agentVersion, "ip_address": ip,
		"domain": dom, "part_of_domain": joined,
	})
	if err != nil {
		return "", err
	}
	if code != 200 {
		return "", fmt.Errorf("enroll failed (%d): %s", code, string(rb))
	}
	var r struct {
		APIToken string `json:"api_token"`
	}
	if err := json.Unmarshal(rb, &r); err != nil || r.APIToken == "" {
		return "", fmt.Errorf("enroll: bad response: %s", string(rb))
	}
	return r.APIToken, nil
}

func report(apiToken string) error {
	inv, host, ip := collectInventory()
	rb, code, err := post(base()+"/api/agents/report", apiToken, map[string]any{
		"hostname": host, "os_name": osName(), "os_family": runtime.GOOS,
		"ip_address": ip, "agent_version": agentVersion,
		"software": software(), "inventory": inv,
		"deep": deepCollect(apiToken),
	})
	if err != nil {
		return err
	}
	if code != 200 {
		return fmt.Errorf("report failed (%d): %s", code, string(rb))
	}
	return nil
}

// deepCollect runs the server's deep inventory probe LOCALLY and returns its raw
// stdout (JSON on Windows, sectioned text on Linux). It is the SAME script the
// agentless credentialed path uses, but here it runs as LocalSystem/root, so no
// credentials are needed for the hardware/security telemetry. Best-effort: any
// failure returns "" and the report still carries the basic inventory.
func deepCollect(apiToken string) string {
	if runtime.GOOS != "windows" && runtime.GOOS != "linux" {
		return "" // no deep probe for darwin yet
	}
	body, code, err := get(base()+"/api/agents/collect-script/"+runtime.GOOS, apiToken)
	if err != nil || code != 200 || len(body) == 0 {
		return ""
	}
	ext := ".sh"
	if runtime.GOOS == "windows" {
		ext = ".ps1"
	}
	f, err := os.CreateTemp("", "ava-deep-*"+ext)
	if err != nil {
		return ""
	}
	tmp := f.Name()
	defer os.Remove(tmp)
	if _, err := f.Write(body); err != nil {
		f.Close()
		return ""
	}
	f.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 120*time.Second)
	defer cancel()
	var cmd *exec.Cmd
	if runtime.GOOS == "windows" {
		cmd = exec.CommandContext(ctx, "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", tmp)
	} else {
		cmd = exec.CommandContext(ctx, "sh", tmp)
	}
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = io.Discard
	_ = cmd.Run() // partial output is fine — the server-side parser degrades gracefully
	return strings.TrimSpace(out.String())
}

func heartbeat(apiToken string) {
	_, _, _ = post(base()+"/api/agents/heartbeat", apiToken, map[string]any{})
}

// ─────────────────────────── CIS / compliance (local) ───────────────────────
type cisOscap struct {
	RuleID     string `json:"rule_id"`
	Datastream string `json:"datastream"`
	Profile    string `json:"profile"`
}
type cisWin struct {
	Shell   string `json:"shell"`
	Command string `json:"command"`
	Timeout int    `json:"timeout"`
}
type cisJob struct {
	RunID      int       `json:"run_id"`
	RuleID     string    `json:"rule_id"`
	RunnerType string    `json:"runner_type"`
	Oscap      *cisOscap `json:"oscap"`
	Win        *cisWin   `json:"win"` // windows: run the check locally, ship raw stdout
}
type cisResult struct {
	RunID     int            `json:"run_id"`
	Status    string         `json:"status,omitempty"`
	Summary   string         `json:"summary,omitempty"`
	RawOutput map[string]any `json:"raw_output,omitempty"`
	// Windows: raw command output — the server scores it (no local verdict).
	Stdout     string `json:"stdout,omitempty"`
	ExitStatus *int   `json:"exit_status,omitempty"`
	Stderr     string `json:"stderr,omitempty"`
}

// mapOscap mirrors oscap_runner._STATUS_MAP exactly so agent verdicts score
// identically to the agentless path.
func mapOscap(r string) string {
	switch r {
	case "pass", "fixed":
		return "passed"
	case "fail":
		return "failed"
	case "notapplicable", "notchecked", "notselected", "informational":
		return "skipped"
	default: // error, unknown, notreported, ""
		return "error"
	}
}

// fetchDatastream downloads the server's SCAP datastream to a temp file so the
// agent runs oscap against the exact same content the cloud uses (rule IDs
// align). Streams straight to disk — datastreams are multi-MB.
func fetchDatastream(apiToken, dsPath string) (string, bool) {
	req, err := http.NewRequest("GET", base()+"/api/agents/datastream?p="+url.QueryEscape(dsPath), nil)
	if err != nil {
		return "", false
	}
	if t := os.Getenv("AVA_TENANT"); t != "" {
		req.Header.Set("X-Tenant-Slug", t)
	}
	req.Header.Set("Authorization", "Bearer "+apiToken)
	resp, err := httpc.Do(req)
	if err != nil {
		return "", false
	}
	defer resp.Body.Close()
	if resp.StatusCode != 200 {
		return "", false
	}
	tmp, err := os.CreateTemp("", "ds-*.xml")
	if err != nil {
		return "", false
	}
	n, err := io.Copy(tmp, io.LimitReader(resp.Body, 128<<20))
	tmp.Close()
	if err != nil || n < 1000 {
		os.Remove(tmp.Name())
		return "", false
	}
	return tmp.Name(), true
}

// runOscap fetches the (server-side) datastream, runs one `oscap xccdf eval` for
// a (datastream, profile), and returns {rule-idref: xccdf-result}. oscap exits
// non-zero when any rule fails — normal, so the exit code is ignored; only the
// results XML matters.
func runOscap(apiToken, datastream, profile string) map[string]string {
	out := map[string]string{}
	localDS, ok := fetchDatastream(apiToken, datastream)
	if !ok {
		return out // no content → caller marks these rules "error"
	}
	defer os.Remove(localDS)
	tmp, err := os.CreateTemp("", "oscap-*.xml")
	if err != nil {
		return out
	}
	tmp.Close()
	defer os.Remove(tmp.Name())
	args := []string{"xccdf", "eval", "--profile", profile, "--results", tmp.Name(), localDS}
	_ = exec.Command("oscap", args...).Run()
	data, err := os.ReadFile(tmp.Name())
	if err != nil || len(data) == 0 {
		return out
	}
	type ruleResult struct {
		Idref  string `xml:"idref,attr"`
		Result string `xml:"result"`
	}
	dec := xml.NewDecoder(bytes.NewReader(data))
	for {
		tok, err := dec.Token()
		if err != nil {
			break
		}
		if se, ok := tok.(xml.StartElement); ok && se.Name.Local == "rule-result" {
			var rr ruleResult
			if dec.DecodeElement(&rr, &se) == nil && rr.Idref != "" {
				out[rr.Idref] = strings.TrimSpace(rr.Result)
			}
		}
	}
	return out
}

// cisRun pulls this agent's pending CIS rules, runs the benchmark locally with
// oscap, and posts verdicts back. Linux only for now (Windows CIS is WinRM-based).
func cisRun(apiToken string) {
	if runtime.GOOS != "linux" && runtime.GOOS != "windows" {
		return
	}
	rb, code, err := get(base()+"/api/agents/jobs", apiToken)
	if err != nil || code != 200 {
		return
	}
	var jr struct {
		Jobs []cisJob `json:"jobs"`
	}
	if json.Unmarshal(rb, &jr) != nil || len(jr.Jobs) == 0 {
		return
	}
	if runtime.GOOS == "windows" {
		runWindowsChecks(apiToken, jr.Jobs) // posts in batches as it goes
	} else {
		postResults(apiToken, runLinuxOscap(apiToken, jr.Jobs)) // oscap is one shot
	}
}

// postResults ships a batch of verdicts; the server scores + finalizes them.
func postResults(apiToken string, results []cisResult) {
	if len(results) == 0 {
		return
	}
	if _, c, _ := post(base()+"/api/agents/jobs/results", apiToken,
		map[string]any{"results": results}); c == 200 {
		fmt.Printf("CIS: reported %d rule result(s)\n", len(results))
	}
}

// runWindowsChecks runs each job's CIS check locally (the command was already
// read-only-safety-gated server-side) and ships RAW output in BATCHES as it goes.
// Batching means a big benchmark shows live progress, the agent heartbeats between
// batches so it never goes STALE mid-grind, results already sent survive a crash,
// and the next poll resumes ONLY the still-pending rules (the server's /jobs returns
// pending only). The server scores each batch, so the agent never duplicates verdicts.
func runWindowsChecks(apiToken string, jobs []cisJob) {
	cut := func(s string, n int) string {
		if len(s) > n {
			return s[:n]
		}
		return s
	}
	const batchN = 25
	var batch []cisResult
	flush := func() {
		if len(batch) == 0 {
			return
		}
		postResults(apiToken, batch)
		batch = batch[:0]
		heartbeat(apiToken) // stay alive + advance liveness during a long grind
	}
	for _, j := range jobs {
		if j.Win == nil || j.Win.Command == "" {
			continue
		}
		to := j.Win.Timeout
		if to <= 0 {
			to = 60
		}
		ctx, cancel := context.WithTimeout(context.Background(), time.Duration(to)*time.Second)
		var cmd *exec.Cmd
		if strings.EqualFold(j.Win.Shell, "cmd") {
			cmd = exec.CommandContext(ctx, "cmd", "/c", j.Win.Command)
		} else {
			cmd = exec.CommandContext(ctx, "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", j.Win.Command)
		}
		var stdout, stderr bytes.Buffer
		cmd.Stdout = &stdout
		cmd.Stderr = &stderr
		err := cmd.Run()
		cancel()
		rc := 0
		if err != nil {
			if ee, ok := err.(*exec.ExitError); ok {
				rc = ee.ExitCode()
			} else {
				rc = -1 // couldn't start / timed out — server treats as no-evidence
			}
		}
		rcCopy := rc
		batch = append(batch, cisResult{
			RunID: j.RunID, ExitStatus: &rcCopy,
			Stdout: cut(stdout.String(), 65536), Stderr: cut(stderr.String(), 8192),
		})
		if len(batch) >= batchN {
			flush()
		}
	}
	flush() // remainder
}

// runLinuxOscap groups jobs by (datastream, profile) — oscap evaluates the whole
// profile once and returns every rule's verdict, so we never run it per-rule.
func runLinuxOscap(apiToken string, jobs []cisJob) []cisResult {
	type key struct{ ds, prof string }
	groups := map[key][]cisJob{}
	for _, j := range jobs {
		if j.Oscap == nil || j.Oscap.Datastream == "" {
			continue
		}
		k := key{j.Oscap.Datastream, j.Oscap.Profile}
		groups[k] = append(groups[k], j)
	}
	var results []cisResult
	for k, js := range groups {
		verdicts := runOscap(apiToken, k.ds, k.prof)
		for _, j := range js {
			v, ok := verdicts[j.Oscap.RuleID]
			st := mapOscap(v)
			if !ok {
				st, v = "error", "rule not present in oscap results"
			}
			results = append(results, cisResult{
				RunID: j.RunID, Status: st, Summary: "oscap: " + v,
				RawOutput: map[string]any{"engine": "agent-oscap", "rule_id": j.Oscap.RuleID,
					"xccdf_result": v, "profile": k.prof},
			})
		}
	}
	return results
}

// reEnroll swaps a revoked/invalid api_token for a fresh one using AVA_ENROLL
// (set by the installer, so it's present after a re-install) — lets a revoked
// agent recover when it's re-installed with a new token. Returns true on success.
func reEnroll(st *state) bool {
	if os.Getenv("AVA_ENROLL") == "" {
		return false
	}
	tok, err := enroll()
	if err != nil {
		return false
	}
	st.APIToken = tok
	_ = saveState(*st)
	fmt.Println("re-enrolled OK")
	return true
}

func main() {
	loadConfig()
	// On Windows, when the SCM launches us as a service, run under its control so
	// Stop/Shutdown are handled and the SCM's failure action can restart us on a
	// crash. Interactively (first install), or on Linux/macOS, run the loop direct.
	if runtime.GOOS == "windows" && isWindowsService() {
		runService()
		return
	}
	runAgent(nil)
}

// runAgent enrolls (first run), reports once, then loops: heartbeat + pending CIS
// every 5 min and a full inventory re-report hourly. It returns when `stop` is
// closed (a Windows service Stop); a nil `stop` runs forever (interactive /
// systemd / launchd, where the supervisor owns the lifecycle).
func runAgent(stop <-chan struct{}) {
	if base() == "" {
		fmt.Fprintln(os.Stderr, "AVA_URL is required")
		return
	}
	st := loadState()
	if st.APIToken == "" {
		tok, err := enroll()
		if err != nil {
			fmt.Fprintln(os.Stderr, "enroll error:", err)
			return
		}
		st.APIToken = tok
		if err := saveState(st); err != nil {
			fmt.Fprintln(os.Stderr, "warning: could not persist token:", err)
		}
		fmt.Println("enrolled OK")
	}
	if err := report(st.APIToken); err != nil {
		if strings.Contains(err.Error(), "(401)") && reEnroll(&st) {
			_ = report(st.APIToken)
			fmt.Println("reported inventory OK")
		} else {
			fmt.Fprintln(os.Stderr, "report error:", err)
		}
	} else {
		fmt.Println("reported inventory OK")
	}
	cisRun(st.APIToken) // run any pending CIS rules now
	if os.Getenv("AVA_ONCE") == "1" {
		return
	}
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	elapsed := 0
	for {
		select {
		case <-stop:
			return
		case <-ticker.C:
			heartbeat(st.APIToken)
			cisRun(st.APIToken)
			elapsed += 5
			if elapsed >= 60 {
				elapsed = 0
				if err := report(st.APIToken); err != nil {
					if strings.Contains(err.Error(), "(401)") && reEnroll(&st) {
						_ = report(st.APIToken)
					} else {
						fmt.Fprintln(os.Stderr, "periodic report error:", err)
					}
				}
			}
		}
	}
}
