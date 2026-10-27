// Ava Compliance Agent — a single static binary that runs on a customer host,
// collects the up-front discovery inventory LOCALLY (OS, software, network,
// basic hardware) and sends it to the cloud. For machines we can't reach over
// the network or where the client won't share credentials.
//
// stdlib ONLY (no modules) so it cross-compiles for Windows, Linux and macOS
// with no network fetch and runs with zero deps on the target.
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
	rb, code, err := post(base()+"/api/agents/enroll", "", map[string]any{
		"enrollment_token": tok, "hostname": host, "os_family": runtime.GOOS,
		"agent_version": agentVersion, "ip_address": ip,
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
type cisJob struct {
	RunID      int       `json:"run_id"`
	RuleID     string    `json:"rule_id"`
	RunnerType string    `json:"runner_type"`
	Oscap      *cisOscap `json:"oscap"`
}
type cisResult struct {
	RunID     int            `json:"run_id"`
	Status    string         `json:"status"`
	Summary   string         `json:"summary"`
	RawOutput map[string]any `json:"raw_output,omitempty"`
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
	if runtime.GOOS != "linux" {
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
	// Group by (datastream, profile): oscap evaluates the whole profile once and
	// returns every rule's verdict, so we never run it per-rule.
	type key struct{ ds, prof string }
	groups := map[key][]cisJob{}
	for _, j := range jr.Jobs {
		if j.Oscap == nil || j.Oscap.Datastream == "" {
			continue
		}
		k := key{j.Oscap.Datastream, j.Oscap.Profile}
		groups[k] = append(groups[k], j)
	}
	var results []cisResult
	for k, jobs := range groups {
		verdicts := runOscap(apiToken, k.ds, k.prof)
		for _, j := range jobs {
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
	if len(results) > 0 {
		if _, c, _ := post(base()+"/api/agents/jobs/results", apiToken,
			map[string]any{"results": results}); c == 200 {
			fmt.Printf("CIS: reported %d rule result(s)\n", len(results))
		}
	}
}

func main() {
	if base() == "" {
		fmt.Fprintln(os.Stderr, "AVA_URL is required")
		os.Exit(2)
	}
	st := loadState()
	if st.APIToken == "" {
		tok, err := enroll()
		if err != nil {
			fmt.Fprintln(os.Stderr, "enroll error:", err)
			os.Exit(1)
		}
		st.APIToken = tok
		if err := saveState(st); err != nil {
			fmt.Fprintln(os.Stderr, "warning: could not persist token:", err)
		}
		fmt.Println("enrolled OK")
	}
	if err := report(st.APIToken); err != nil {
		fmt.Fprintln(os.Stderr, "report error:", err)
	} else {
		fmt.Println("reported inventory OK")
	}
	cisRun(st.APIToken) // run any pending CIS rules now
	if os.Getenv("AVA_ONCE") == "1" {
		return
	}
	// Service loop: heartbeat + pick up pending CIS jobs every 5 min, full
	// inventory re-report hourly.
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	elapsed := 0
	for range ticker.C {
		heartbeat(st.APIToken)
		cisRun(st.APIToken)
		elapsed += 5
		if elapsed >= 60 {
			elapsed = 0
			if err := report(st.APIToken); err != nil {
				fmt.Fprintln(os.Stderr, "periodic report error:", err)
			}
		}
	}
}
