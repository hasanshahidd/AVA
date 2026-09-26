#!/usr/bin/env bash
# Install modern Go + Rust (apt's are too old) and rebuild the toolchain-blocked repos.
set -u
L=/tmp/fleet; mkdir -p "$L"
say(){ echo "$(date +%H:%M:%S) $*" | tee -a "$L/SUMMARY"; }
ROOT=/mnt/c/Users/HP/OneDrive/Desktop/CyberAssurance/external-tools

# ---- modern Go (tarball, no sudo) ----
GOV=go1.23.4
if [ ! -x "$HOME/.local/$GOV/go/bin/go" ]; then
  say "downloading $GOV ..."
  mkdir -p "$HOME/.local/$GOV"
  curl -fsSL "https://go.dev/dl/$GOV.linux-amd64.tar.gz" -o /tmp/$GOV.tgz \
    && tar -C "$HOME/.local/$GOV" -xzf /tmp/$GOV.tgz || say "go download FAILED"
fi
export PATH="$HOME/.local/$GOV/go/bin:$PATH"
export GOTOOLCHAIN=auto   # auto-fetch newer (e.g. peirates wants 1.27)
say "go now: $(go version 2>&1)"

( cd "$ROOT/container/find/trivy-mcp" && go build ./... ) >"$L/trivy-mcp.log" 2>&1 \
  && say "OK  go   trivy-mcp" || say "ERR go   trivy-mcp (see $L/trivy-mcp.log)"
( cd "$ROOT/_build/peirates" && go build ./... ) >"$L/peirates.log" 2>&1 \
  && say "OK  go   peirates" || say "ERR go   peirates (see $L/peirates.log)"

# ---- modern Rust via rustup (apt cargo lacks edition2024) ----
if [ ! -x "$HOME/.cargo/bin/cargo" ]; then
  say "installing rustup + stable ..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal >>"$L/rustup.log" 2>&1 || say "rustup install FAILED"
fi
export PATH="$HOME/.cargo/bin:$PATH"
say "cargo now: $(cargo --version 2>&1)"
( cd "$ROOT/internal-host/find/openvas-mcp-server" && cargo build --release ) >"$L/openvas.log" 2>&1 \
  && say "OK  rust openvas-mcp-server" || say "ERR rust openvas (see $L/openvas.log)"

say "==== TOOLCHAIN FIX DONE ===="
