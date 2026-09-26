#!/usr/bin/env bash
# Bring the EXTERNAL lane online on Ubuntu: HexStrike backend (loopback) + MCP bridge.
# This only STARTS the server; it fires nothing — the deterministic gateway + human gate control
# what actually runs. NEVER expose :8888 (unauth RCE, CVE-2026-90620) — loopback only.
set -u
HS="$(dirname "$0")/external/_dual/hexstrike-ai"
cd "$HS" || { echo "hexstrike-ai not found at $HS"; exit 1; }

# 1. deps once (Python venv)
if [ ! -d .venv ]; then
  echo "[setup] creating venv + installing HexStrike deps…"
  python3 -m venv .venv && ./.venv/bin/pip install -q -r requirements.txt || { echo "dep install failed"; exit 1; }
fi

# 2. backend on 127.0.0.1:8888 ONLY
echo "[start] HexStrike backend on 127.0.0.1:8888 (loopback)…"
HEXSTRIKE_HOST=127.0.0.1 ./.venv/bin/python hexstrike_server.py >/tmp/hexstrike_server.log 2>&1 &
echo $! > /tmp/hexstrike_server.pid
sleep 6

# 3. health check
if curl -s -m 3 http://127.0.0.1:8888/health >/dev/null 2>&1; then
  echo "[ok] backend healthy on 127.0.0.1:8888"
else
  echo "[warn] backend not answering /health yet — check /tmp/hexstrike_server.log"
fi

echo
echo "MCP bridge command PentestGPT connects to (stdio):"
echo "  $HS/.venv/bin/python $HS/hexstrike_mcp.py --server http://127.0.0.1:8888"
echo "Next: wire that command into PentestGPT — see ava-pentest-engine/WIRING.md"
