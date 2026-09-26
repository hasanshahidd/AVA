#!/usr/bin/env bash
# Fix the py MCP servers: pull missing git submodules, then capture each server's real
# startup error (run briefly, feed one initialize, show stderr head).
cd /mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools || exit 1
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}'

test_server(){  # label  dir  launch...
  local label="$1" dir="$2"; shift 2
  echo "==================== $label ===================="
  if [ -f "$dir/.gitmodules" ]; then
    echo "-- submodules: updating --"; ( cd "$dir" && git submodule update --init --recursive 2>&1 | tail -2 )
  fi
  echo "-- startup test --"
  printf '%s\n' "$INIT" | timeout 12 "$@" 2>/tmp/srv.err >/tmp/srv.out
  if grep -q '"result"' /tmp/srv.out 2>/dev/null; then
    echo "  ENUMERATES: got initialize result ✅"
  else
    echo "  FAILED — stderr:"; grep -iE "error|no module|traceback|import|not found" /tmp/srv.err | head -4
  fi
}

test_server semgrep    code/find/semgrep-mcp                 code/find/semgrep-mcp/.venv/bin/semgrep-mcp
test_server netexec    internal-host/exploit/netexec-mcp     internal-host/exploit/netexec-mcp/.venv/bin/netexec-mcp
test_server bloodhound internal-ad/find/bloodhound-mcp-ai    internal-ad/find/bloodhound-mcp-ai/.venv/bin/python internal-ad/find/bloodhound-mcp-ai/BloodHound-MCP.py
test_server hashcat    internal-ad/exploit/hashcat-mcp       internal-ad/exploit/hashcat-mcp/.venv/bin/python internal-ad/exploit/hashcat-mcp/hashcat_mcp_server.py
test_server roadrecon  cloud/find/roadrecon-mcp              cloud/find/roadrecon-mcp/.venv/bin/python cloud/find/roadrecon-mcp/roadrecon_mcp_server.py
