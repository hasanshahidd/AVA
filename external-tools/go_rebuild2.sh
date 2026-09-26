#!/usr/bin/env bash
# Build the two Go repos on EXT4 (not /mnt/c 9p) with a fresh cache, serially.
# Same lesson as adstrike: 9p breaks writes; do the build entirely on the native FS.
set -u
L=/tmp/fleet; mkdir -p "$L"
say(){ echo "$(date +%H:%M:%S) $*" | tee -a "$L/SUMMARY"; }
export PATH="$HOME/.local/go1.23.4/go/bin:$PATH"
export GOTOOLCHAIN=auto
SRC=/mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools

say "go clean -modcache (fresh) ..."; go clean -modcache 2>/dev/null
rm -rf ~/gobuild; mkdir -p ~/gobuild
cp -r "$SRC/container/find/trivy-mcp" ~/gobuild/trivy-mcp
cp -r "$SRC/_build/peirates"          ~/gobuild/peirates

for r in trivy-mcp peirates; do
  say "building $r on ext4 (serial) ..."
  ( cd ~/gobuild/$r && go mod download && go build -o ./_bin ./... ) >"$L/$r.log" 2>&1 \
    && say "OK  go   $r  -> ~/gobuild/$r/_bin" \
    || { say "ERR go   $r"; tail -3 "$L/$r.log" | sed 's/^/     /'; }
  echo "   C: free: $(df -h /mnt/c | awk 'NR==2{print $4}')"
done
say "==== GO REBUILD (ext4) DONE ===="
ls -la ~/gobuild/*/_bin 2>/dev/null
