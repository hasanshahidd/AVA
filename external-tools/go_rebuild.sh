#!/usr/bin/env bash
# The go module cache got corrupted during the zero-disk window (0-byte files, bad zips).
# Purge it and rebuild the two Go repos cleanly with modern Go.
set -u
L=/tmp/fleet; mkdir -p "$L"
say(){ echo "$(date +%H:%M:%S) $*" | tee -a "$L/SUMMARY"; }
export PATH="$HOME/.local/go1.23.4/go/bin:$PATH"
export GOTOOLCHAIN=auto
ROOT=/mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools

say "go clean -modcache (purging corrupt cache) ..."
go clean -modcache 2>>"$L/go_rebuild.log"
say "C: free before rebuild: $(df -h /mnt/c | awk 'NR==2{print $4}')"

( cd "$ROOT/container/find/trivy-mcp" && go mod download && go build ./... ) >"$L/trivy-mcp.log" 2>&1 \
  && say "OK  go   trivy-mcp" || say "ERR go   trivy-mcp (see $L/trivy-mcp.log)"
( cd "$ROOT/_build/peirates" && go mod download && go build ./... ) >"$L/peirates.log" 2>&1 \
  && say "OK  go   peirates" || say "ERR go   peirates (see $L/peirates.log)"

say "C: free after: $(df -h /mnt/c | awk 'NR==2{print $4}')"
say "==== GO REBUILD DONE ===="
