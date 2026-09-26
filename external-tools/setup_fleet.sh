#!/usr/bin/env bash
# Set up the AVA MCP fleet in a Linux / WSL (Ubuntu) sandbox.
# INSTALLS toolchains + security binaries + each cloned MCP's deps. It does NOT run any scan or
# exploit — running the tools stays a human-triggered step. Re-runnable; failures don't stop the run.
#
#   Run inside Ubuntu/WSL from this folder:   bash setup_fleet.sh
set -u
cd "$(dirname "$0")"
ok(){ echo "  [ok] $*"; }; skip(){ echo "  [--] $*"; }; hdr(){ echo; echo "== $* =="; }

hdr "toolchains (apt)"
sudo apt-get update -y >/dev/null 2>&1 || true
sudo apt-get install -y python3-venv python3-pip pipx nodejs npm golang-go default-jdk cargo \
     nmap masscan git jq >/dev/null 2>&1 && ok "python/node/go/java/rust/nmap" || skip "apt (check sudo)"
pipx ensurepath >/dev/null 2>&1 || true
command -v uv >/dev/null 2>&1 || (curl -LsSf https://astral.sh/uv/install.sh | sh >/dev/null 2>&1 && ok "uv") || skip "uv"

hdr "FIND-lane binaries (defensive scanners)"
# ProjectDiscovery (Go)
for t in subfinder dnsx naabu httpx katana nuclei; do
  go install "github.com/projectdiscovery/$t/v2/cmd/$t@latest" >/dev/null 2>&1 || \
  go install "github.com/projectdiscovery/$t/cmd/$t@latest" >/dev/null 2>&1 && ok "$t" || skip "$t"
done
pipx install semgrep >/dev/null 2>&1 && ok "semgrep (SAST)" || skip "semgrep"
command -v trivy >/dev/null 2>&1 || (curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin >/dev/null 2>&1 && ok "trivy") || skip "trivy"
pipx install prowler >/dev/null 2>&1 && ok "prowler (CSPM)" || skip "prowler"
# gitleaks
go install github.com/gitleaks/gitleaks/v8@latest >/dev/null 2>&1 && ok "gitleaks" || skip "gitleaks"

hdr "EXPLOIT-lane binaries (offensive — install only; run is gated + your trigger)"
pipx install netexec >/dev/null 2>&1 && ok "netexec (nxc)" || skip "netexec"
pipx install impacket >/dev/null 2>&1 && ok "impacket" || skip "impacket"
echo "  NOTE: sqlmap: 'apt install sqlmap'  ·  hashcat: 'apt install hashcat'"
echo "  NOTE: Metasploit (msfmcpd): install via the official installer:"
echo "        curl https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb | sudo bash"

hdr "per-repo MCP deps"
setup_repo(){ # dir
  local d="$1"; [ -d "$d" ] || return
  if   [ -f "$d/package.json" ]; then (cd "$d" && npm install >/dev/null 2>&1) && ok "npm: $d" || skip "npm: $d"
  elif [ -f "$d/pyproject.toml" ]; then (cd "$d" && python3 -m venv .venv && ./.venv/bin/pip install -e . >/dev/null 2>&1) && ok "py:  $d" || skip "py:  $d"
  elif [ -f "$d/requirements.txt" ]; then (cd "$d" && python3 -m venv .venv && ./.venv/bin/pip install -r requirements.txt >/dev/null 2>&1) && ok "py:  $d" || skip "py:  $d"
  elif [ -f "$d/go.mod" ]; then (cd "$d" && go build ./... >/dev/null 2>&1) && ok "go:  $d" || skip "go:  $d"
  elif ls "$d"/build.gradle* >/dev/null 2>&1; then (cd "$d" && ./gradlew embedProxyJar >/dev/null 2>&1) && ok "gradle: $d" || skip "gradle: $d (needs Burp)"
  fi
}
for lane in external internal-host internal-ad cloud container code _build PentestGPT; do
  [ -d "$lane" ] || continue
  # each lane holds repos under find/ exploit/ _dual/ or directly
  find "$lane" -maxdepth 3 \( -name package.json -o -name pyproject.toml -o -name requirements.txt -o -name go.mod \) \
    -not -path '*/node_modules/*' -not -path '*/.venv/*' 2>/dev/null | while read -r f; do setup_repo "$(dirname "$f")"; done
done

hdr "done"
echo "Fleet deps installed where the toolchain allowed. Start HexStrike on loopback, then the MCP"
echo "bridge, then PentestGPT — and drive scans from the AI Pentest page. Exploit tools stay gated."
