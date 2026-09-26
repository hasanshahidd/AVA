#!/usr/bin/env bash
# Stop any lingering serial installer + its children, then probe the unknown repos.
cd /mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools || exit 1

echo "=== killing lingering setup_fleet + install children ==="
# match the full path so this script's own cmdline (bash _stopprobe.sh) never matches
for p in $(pgrep -f "external-tools/setup_fleet.sh"); do echo "kill setup_fleet pid $p"; kill "$p" 2>/dev/null; done
sleep 1
for p in $(pgrep -f "external-tools/setup_fleet.sh"); do kill -9 "$p" 2>/dev/null; done
echo "remaining install procs (pip/npm/go build):"
pgrep -af "pip install|npm install|go build" | grep external-tools || echo "  none"

echo; echo "=== unknown-manifest repos: what ARE they? ==="
for d in external/_dual/mcp-for-security internal-host/find/openvas-mcp-server _build/roadtools cloud/find/prowler _build/graphrunner; do
  echo "--- $d ---"
  ls -1 "$d" 2>/dev/null | head -15
  echo "  installers: $(ls "$d"/setup.py "$d"/pyproject.toml "$d"/poetry.lock "$d"/package.json "$d"/*.psd1 "$d"/Makefile 2>/dev/null | xargs -n1 basename 2>/dev/null | tr '\n' ' ')"
  echo "  sub-package.json: $(find "$d" -maxdepth 2 -name package.json -not -path '*/node_modules/*' 2>/dev/null | wc -l)"
  echo "  sub-pyproject:    $(find "$d" -maxdepth 2 -name pyproject.toml 2>/dev/null | wc -l)"
done

echo; echo "=== adstrike FAILED install — real error ==="
cd internal-ad/exploit/adstrike || exit 0
echo "requirements head:"; head -8 requirements*.txt 2>/dev/null
echo "retry (first error only):"
python3 -m venv .venv 2>/dev/null
./.venv/bin/pip install -r requirements.txt 2>&1 | grep -iE "error|fail|could not|no matching|ERROR:" | head -6
