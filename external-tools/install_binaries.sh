#!/usr/bin/env bash
# trivy + peirates via official prebuilt binaries (source build blocked by post-crash ext4
# mmap corruption). Binaries land in their repo dirs on /mnt/c; exec works from drvfs.
set -u
L=/tmp/fleet; say(){ echo "$(date +%H:%M:%S) $*" | tee -a "$L/SUMMARY"; }
ROOT=/mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools
T="$ROOT/container/find/trivy-mcp"
P="$ROOT/_build/peirates"

# --- trivy CLI (official installer -> single binary) ---
say "installing trivy binary ..."
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b "$T" >"$L/trivy-bin.log" 2>&1
if "$T/trivy" --version >/dev/null 2>&1; then say "OK  trivy binary: $("$T"/trivy --version 2>/dev/null | head -1)"; else say "ERR trivy binary (see $L/trivy-bin.log)"; fi

# --- peirates (latest GitHub release binary) ---
say "installing peirates binary ..."
TAG=$(curl -sf https://api.github.com/repos/inguardians/peirates/releases/latest 2>/dev/null | grep -oP '"tag_name":\s*"\K[^"]+' | head -1)
if [ -n "$TAG" ]; then
  rm -rf /tmp/pxd && mkdir -p /tmp/pxd
  curl -sfL "https://github.com/inguardians/peirates/releases/download/${TAG}/peirates-linux-amd64.tar.xz" -o /tmp/pxd/p.tar.xz 2>>"$L/peirates-bin.log" \
    && tar -C /tmp/pxd -xf /tmp/pxd/p.tar.xz 2>/dev/null
  BIN=$(find /tmp/pxd -name peirates -type f 2>/dev/null | head -1)
  if [ -n "$BIN" ]; then cp "$BIN" "$P/peirates" && chmod +x "$P/peirates"; fi
  if [ -x "$P/peirates" ]; then say "OK  peirates binary ($TAG)"; else say "ERR peirates binary (see $L/peirates-bin.log)"; fi
else
  say "ERR peirates: could not resolve latest release tag (see $L/peirates-bin.log)"
fi
say "==== BINARIES DONE ===="
