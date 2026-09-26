# ava-web — web-lane tool image for AVA (defensive cyber-assurance)
#
# Pinned, per-lane arsenal. Built ONCE by the operator; tools run in ephemeral
# per-job containers:  docker run --rm --network host ava-web <tool> <args>
# ENTRYPOINT is cleared and there is NO CMD, so argv passed to `docker run`
# is executed directly.
#
# Breadth = kali-tools-web metapackage (100+ web tools) + the explicit named
# arsenal below (guarantees presence even if the metapackage drops one) +
# HexStrike (~130 finders) + XSStrike, both from git.
#
# ponytail: single pinned tag, not a digest — operators who need a reproducible
# base should re-pin to a kalilinux/kali-rolling@sha256 digest here.
FROM kalilinux/kali-rolling

LABEL org.opencontainers.image.title="ava-web" \
      org.opencontainers.image.description="AVA web-lane recon+exploit arsenal (Kali + HexStrike + XSStrike)"

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    LANG=C.UTF-8

# Base OS + toolchain needed to fetch/build the git tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl wget git python3 python3-pip python3-venv \
      golang-go ruby build-essential libssl-dev libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Breadth: the whole Kali web metapackage (~100+ tools).
RUN apt-get update && apt-get install -y --no-install-recommends \
      kali-tools-web \
    && rm -rf /var/lib/apt/lists/*

# Explicit web recon + exploit arsenal (named so nothing silently goes missing).
# Grouped by function; one group per layer for cache + clear failure attribution.
RUN apt-get update && apt-get install -y --no-install-recommends \
      sqlmap commix wpscan nikto nuclei joomscan davtest cadaver skipfish \
      whatweb wafw00f dalfox \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends \
      ffuf gobuster feroxbuster dirb dirbuster wfuzz arjun \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends \
      sslscan sslyze testssl.sh \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends \
      httpx-toolkit katana gau waybackurls \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends \
      subfinder amass assetfinder dnsenum dnsrecon fierce sublist3r dnsutils \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends \
      hydra medusa patator \
    && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends \
      seclists wordlists \
    && rm -rf /var/lib/apt/lists/*

# nuclei signature templates (data the nuclei binary reads at scan time).
RUN nuclei -update-templates || true

# XSStrike (git) — advanced XSS discovery/exploitation.
RUN git clone --depth 1 https://github.com/s0md3v/XSStrike /opt/XSStrike \
    && pip install --no-cache-dir -r /opt/XSStrike/requirements.txt \
    && printf '#!/bin/sh\nexec python3 /opt/XSStrike/xsstrike.py "$@"\n' > /usr/local/bin/xsstrike \
    && chmod +x /usr/local/bin/xsstrike

# HexStrike — bundles its ~130 finders so they run inside THIS image.
RUN git clone --depth 1 https://github.com/0x4m4/hexstrike-ai /opt/hexstrike \
    && ( [ -f /opt/hexstrike/requirements.txt ] \
         && pip install --no-cache-dir -r /opt/hexstrike/requirements.txt \
         || true )
ENV HEXSTRIKE_HOME=/opt/hexstrike

# Ephemeral-run contract: no entrypoint wrapper, no default command.
# `docker run --rm --network host ava-web <tool> <args>` runs <tool> directly.
ENTRYPOINT []
