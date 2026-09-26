#!/usr/bin/env bash
# Clone the verified fleet into lane/role folders. SOURCE ONLY — never runs an installer.
# Drops (unsafe/redundant) are intentionally skipped; see manifest.yaml.
set -u
cd "$(dirname "$0")"   # external-tools/

echo "== reorganize external/ into _dual (dual-use) + find =="
mkdir -p external/_dual external/find external/exploit
[ -d external/hexstrike-ai ]     && mv external/hexstrike-ai     external/_dual/ 2>/dev/null
[ -d external/mcp-for-security ] && mv external/mcp-for-security external/_dual/ 2>/dev/null
[ -d external/burp-mcp ]         && mv external/burp-mcp         external/find/   2>/dev/null

echo "== find/exploit subfolders per lane =="
mkdir -p internal-host/find internal-host/exploit internal-ad/find internal-ad/exploit \
         cloud/find cloud/exploit container/find code/find _build

clone() { # url dest
  if [ -d "$2/.git" ]; then echo "  skip (exists): $2"; return; fi
  printf "  clone %-42s -> %s ... " "$(basename "$1")" "$2"
  if git clone --depth 1 "$1" "$2" >/dev/null 2>&1; then echo "ok"; else echo "FAIL"; fi
}

echo "== internal-host =="
clone https://github.com/Cyreslab-AI/nessus-mcp-server   internal-host/find/nessus-mcp-server
clone https://github.com/greenbone-hive/openvas-mcp-server internal-host/find/openvas-mcp-server
clone https://github.com/mpgn/NetExec-mcp                 internal-host/exploit/netexec-mcp

echo "== internal-ad =="
clone https://github.com/MorDavid/BloodHound-MCP-AI       internal-ad/find/bloodhound-mcp-ai
clone https://github.com/capture0x/AdStrike               internal-ad/exploit/adstrike
clone https://github.com/MorDavid/Hashcat-MCP             internal-ad/exploit/hashcat-mcp

echo "== cloud =="
clone https://github.com/turbot/steampipe-mcp            cloud/find/steampipe-mcp
clone https://github.com/atomicchonk/roadrecon_mcp_server cloud/find/roadrecon-mcp
clone https://github.com/prowler-cloud/prowler           cloud/find/prowler

echo "== container + code =="
clone https://github.com/aquasecurity/trivy-mcp          container/find/trivy-mcp
clone https://github.com/semgrep/mcp                     code/find/semgrep-mcp

echo "== _build (underlying tools we wrap; no MCP exists yet) =="
clone https://github.com/RhinoSecurityLabs/pacu          _build/pacu
clone https://github.com/dirkjanm/ROADtools              _build/roadtools
clone https://github.com/dafthack/GraphRunner            _build/graphrunner
clone https://github.com/inguardians/peirates            _build/peirates

echo "== Metasploit (msfmcpd ships inside it; LARGE — last on purpose) =="
clone https://github.com/rapid7/metasploit-framework     internal-host/exploit/metasploit-framework

echo ""; echo "== DONE — tree (depth 3): =="
find . -maxdepth 3 -type d -not -path '*/.git*' -not -path '*/node_modules*' | sort
echo ""; echo "== disk usage per lane: =="
du -sh */ 2>/dev/null | sort -h
