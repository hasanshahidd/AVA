#!/usr/bin/env bash
# After a clean WSL restart: bring HexStrike back on loopback, then enumerate the slow servers
# with a generous timeout (hexstrike + semgrep have heavy startup).
HS=/mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools/external/_dual/hexstrike-ai
cd "$HS" || exit 1
HEXSTRIKE_HOST=127.0.0.1 setsid nohup ./.venv/bin/python hexstrike_server.py >/tmp/hexstrike_server.log 2>&1 &
sleep 14
ss -ltn 2>/dev/null | grep -q 8888 && echo "hexstrike backend: UP (loopback)" || echo "hexstrike backend: NOT UP"
cd /mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/ava-pentest-engine || exit 1
echo "=== enumeration (45s timeout) ==="
PYTHONPATH=. python3 tools/verify_fleet.py 45 2>&1 | grep -E "^  (hexstrike|semgrep|hashcat|roadrecon) " | sed -E 's/ bin:.*//'
