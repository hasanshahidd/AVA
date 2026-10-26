// Ava Compliance Agent — a single static binary that runs on a customer host,
// collects the up-front discovery inventory LOCALLY (OS, software, network,
// basic hardware) and sends it to the cloud. For machines we can't reach over
// the network or where the client won't share credentials.
//
// stdlib ONLY (no modules) so it cross-compiles for Windows+Linux with no
// network fetch and runs with zero deps on the target.
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
	"encoding/json"
	"fmt"
	"io"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
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

var httpc = &http.Client{Timeout: 30 * time.Second}

func post(url, bearer string, payload any) ([]byte, int, error) {
	body, _ := json.Marshal(payload)
	req, err := http.NewRequest("POST", url, bytes.NewReader(body))
	if err != nil {
		return nil, 0, err
	}
	req.Header.Set("Content-Type", "application/json")
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
	rb, code, err := post(base()+"/grc/agents/enroll", "", map[string]any{
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
	rb, code, err := post(base()+"/grc/agents/report", apiToken, map[string]any{
		"hostname": host, "os_name": osName(), "os_family": runtime.GOOS,
		"ip_address": ip, "agent_version": agentVersion,
		"software": software(), "inventory": inv,
	})
	if err != nil {
		return err
	}
	if code != 200 {
		return fmt.Errorf("report failed (%d): %s", code, string(rb))
	}
	return nil
}

func heartbeat(apiToken string) {
	_, _, _ = post(base()+"/grc/agents/heartbeat", apiToken, map[string]any{})
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
	if os.Getenv("AVA_ONCE") == "1" {
		return
	}
	// Service loop: heartbeat every 5 min, full re-report hourly.
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()
	elapsed := 0
	for range ticker.C {
		heartbeat(st.APIToken)
		elapsed += 5
		if elapsed >= 60 {
			elapsed = 0
			if err := report(st.APIToken); err != nil {
				fmt.Fprintln(os.Stderr, "periodic report error:", err)
			}
		}
	}
}
