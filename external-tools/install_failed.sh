#!/usr/bin/env bash
# Parallel installer for the failed/pending MCP repos, each with its root-cause fix.
# Per-repo logs in /tmp/fleet/<name>.log; live summary appended to /tmp/fleet/SUMMARY.
cd /mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools || exit 1
L=/tmp/fleet; mkdir -p "$L"; : > "$L/SUMMARY"
say(){ echo "$(date +%H:%M:%S) $*" | tee -a "$L/SUMMARY"; }

have(){ command -v "$1" >/dev/null 2>&1; }
say "toolchains: python3=$(have python3&&echo y||echo N) node=$(have node&&echo y||echo N) npm=$(have npm&&echo y||echo N) go=$(have go&&echo y||echo N) cargo=$(have cargo&&echo y||echo N)"

pyinstall(){ # dir  extra-pip-args...
  local d="$1"; shift; local n; n=$(basename "$d")
  { python3 -m venv "$d/.venv" && "$d/.venv/bin/pip" -q install -U pip && "$d/.venv/bin/pip" install "$@"; } \
    >"$L/$n.log" 2>&1 && say "OK  py   $d" || say "ERR py   $d  (see $L/$n.log)"
}
npminstall(){ # dir
  local d="$1"; local n; n=$(basename "$d")
  ( cd "$d" && npm install && { [ -f package.json ] && grep -q '"build"' package.json && npm run build || true; } ) \
    >"$L/$n.log" 2>&1 && say "OK  npm  $d" || say "ERR npm  $d  (see $L/$n.log)"
}
goinstall(){ # dir
  local d="$1"; local n; n=$(basename "$d")
  have go || { say "SKIP go   $d (no go toolchain)"; return; }
  ( cd "$d" && go build ./... ) >"$L/$n.log" 2>&1 && say "OK  go   $d" || say "ERR go   $d  (see $L/$n.log)"
}

# ---- launch all in parallel ----
# 1. semgrep-mcp (py, editable)
pyinstall code/find/semgrep-mcp -e code/find/semgrep-mcp &

# 2. steampipe-mcp (npm)
npminstall cloud/find/steampipe-mcp &

# 3. adstrike (py) — FIX: drop the pyasn1 pin so impacket resolves it
( d=internal-ad/exploit/adstrike; grep -v '^pyasn1' "$d/requirements.txt" > /tmp/adstrike.req 2>/dev/null
  python3 -m venv "$d/.venv" && "$d/.venv/bin/pip" -q install -U pip && "$d/.venv/bin/pip" install -r /tmp/adstrike.req
) >"$L/adstrike.log" 2>&1 && say "OK  py   internal-ad/exploit/adstrike (pyasn1 pin dropped)" || say "ERR py   adstrike (see $L/adstrike.log)" &

# 4. roadtx (py) — the Entra token tool inside roadtools
pyinstall _build/roadtools ./_build/roadtools/roadlib ./_build/roadtools/roadtx &

# 5. pacu (py)
pyinstall _build/pacu ./_build/pacu &

# (go/rust repos — trivy, peirates, openvas — are handled by toolchain_fix.sh with modern toolchains)

# 8. mcp-for-security — 23 sub-MCPs, npm install each (capped concurrency)
( cd external/_dual/mcp-for-security
  ok=0; err=0
  for sub in */ ; do
    [ -f "$sub/package.json" ] || continue
    ( cd "$sub" && npm install >/dev/null 2>&1 && { grep -q '"build"' package.json && npm run build >/dev/null 2>&1 || true; } ) \
      && ok=$((ok+1)) || err=$((err+1))
    # cap: no more than 6 concurrent npm
    while [ "$(jobs -rp | wc -l)" -ge 6 ]; do wait -n; done
  done
  wait
  echo "mcp-for-security subdirs: ok=$ok err=$err"
) >"$L/mcp-for-security.log" 2>&1 && say "DONE mcp-for-security ($(tail -1 $L/mcp-for-security.log))" || say "ERR mcp-for-security (see $L/mcp-for-security.log)" &

wait
say "==== ALL PARALLEL INSTALLS FINISHED ===="
