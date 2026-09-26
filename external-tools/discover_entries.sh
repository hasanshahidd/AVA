#!/usr/bin/env bash
# Read-only: find each installed MCP-server's launch entry (pyproject scripts / package.json / module).
cd /mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools || exit 1
for d in \
  code/find/semgrep-mcp \
  internal-host/exploit/netexec-mcp \
  internal-ad/find/bloodhound-mcp-ai \
  internal-ad/exploit/hashcat-mcp \
  cloud/find/roadrecon-mcp \
  internal-host/find/nessus-mcp-server ; do
  echo "==================== $d ===================="
  if [ -f "$d/pyproject.toml" ]; then
    echo "-- [project.scripts] --"; sed -n '/\[project.scripts\]/,/^\[/p' "$d/pyproject.toml" | grep -v '^\[' | grep -v '^$' | head -6
    echo "-- name --"; grep -m1 '^name' "$d/pyproject.toml"
  fi
  if [ -f "$d/package.json" ]; then
    echo "-- node main/bin --"; grep -E '"(main|bin|module|type)"' "$d/package.json" | head -5
    echo "-- built entry? --"; ls "$d"/build/index.js "$d"/dist/index.js 2>/dev/null
  fi
  echo "-- __main__ / server modules --"; find "$d" -maxdepth 3 -name "__main__.py" -o -maxdepth 3 -name "server.py" 2>/dev/null | grep -vE "/.venv/|/node_modules/" | head -4
  echo "-- README run hint --"; grep -ioE "(python -m [a-z_.]+|uvx [a-z_-]+|npx [a-z@/_-]+|node [a-z/._-]*index[a-z.]*|fastmcp run [a-z/._]+)" "$d/README.md" 2>/dev/null | sort -u | head -3
  echo
done
