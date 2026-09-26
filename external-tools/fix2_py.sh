#!/usr/bin/env bash
# Pin mcp<2 for the servers written against the old FastMCP API, then retest enumeration.
cd /mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools || exit 1
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"t","version":"1"}}}'

for d in internal-ad/find/bloodhound-mcp-ai internal-ad/exploit/hashcat-mcp cloud/find/roadrecon-mcp; do
  echo "=== pin mcp<2 in $d ==="
  "$d/.venv/bin/pip" install -q "mcp<2" 2>&1 | tail -1
done

retest(){  # label  launch...
  local label="$1"; shift
  printf '%s\n' "$INIT" | timeout 15 "$@" 2>/tmp/r.err >/tmp/r.out
  if grep -q '"result"' /tmp/r.out 2>/dev/null; then
    echo "  $label: ENUMERATES ✅ ($(grep -oE '"name":"[^"]+"' /tmp/r.out | wc -l) fields in result)"
  else
    echo "  $label: still failing — $(grep -iE 'error|no module|not found' /tmp/r.err | head -1)"
  fi
}
echo "=== retest ==="
retest semgrep    code/find/semgrep-mcp/.venv/bin/semgrep-mcp
retest bloodhound internal-ad/find/bloodhound-mcp-ai/.venv/bin/python internal-ad/find/bloodhound-mcp-ai/BloodHound-MCP.py
retest hashcat    internal-ad/exploit/hashcat-mcp/.venv/bin/python internal-ad/exploit/hashcat-mcp/hashcat_mcp_server.py
retest roadrecon  cloud/find/roadrecon-mcp/.venv/bin/python cloud/find/roadrecon-mcp/roadrecon_mcp_server.py
