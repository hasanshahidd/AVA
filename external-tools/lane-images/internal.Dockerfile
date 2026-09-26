# syntax=docker/dockerfile:1
# =============================================================================
# ava-internal  —  INTERNAL / AD / HOST pentest lane image
# =============================================================================
# Ephemeral per-job runner. The engine invokes it as:
#   docker run --rm --network host ava-internal <tool> <args...>
# --network host so tools reach the LAN / AD / target hosts directly.
# ENTRYPOINT is cleared and there is NO long-running CMD, so the container
# runs exactly one tool invocation and exits (destroyed by --rm).
# It can also serve as the Metasploit RPC host:  ... ava-internal msfrpcd ...
#
# Build once:  docker build -f external-tools/lane-images/internal.Dockerfile \
#                           -t ava-internal external-tools/lane-images
# =============================================================================
FROM kalilinux/kali-rolling

LABEL org.ava.lane="internal" \
      org.ava.desc="AVA internal/AD/host exploit arsenal (ephemeral runner)"

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    PIP_BREAK_SYSTEM_PACKAGES=1 \
    PATH="/opt/hexstrike/.venv/bin:/root/.local/bin:${PATH}"

# --- Kali metapackages: the bulk internal arsenal -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
      kali-tools-exploitation \
      kali-tools-windows-resources \
      kali-tools-passwords \
      kali-tools-information-gathering \
      kali-tools-post-exploitation \
      kali-tools-vulnerability \
    && rm -rf /var/lib/apt/lists/*

# --- Explicit installs: guarantee every named internal/AD/host tool present ---
# (many overlap the metapackages above; listed so nothing is missing)
RUN apt-get update && apt-get install -y --no-install-recommends \
      # exploitation frameworks
      metasploit-framework \
      # discovery / enumeration
      nmap \
      smbmap smbclient \
      samba-common-bin \
      enum4linux enum4linux-ng \
      ldap-utils \
      nbtscan \
      onesixtyone \
      snmp snmp-mibs-downloader \
      # AD / SMB / WinRM tradecraft
      netexec \
      impacket-scripts \
      evil-winrm \
      responder \
      certipy-ad \
      kerbrute \
      # windows resources (mimikatz, etc.)
      windows-resources \
      # password attacks
      hydra medusa \
      hashcat john \
      # pivoting / tunneling
      chisel ligolo-ng proxychains4 sshuttle \
      # runtime deps for pip/pipx tooling + hexstrike
      python3 python3-pip python3-venv pipx git curl \
    && rm -rf /var/lib/apt/lists/*

# snmp-check ships in the snmp-check pkg on some rolling snapshots; ensure it.
RUN apt-get update && (apt-get install -y --no-install-recommends snmpcheck snmp-check || true) \
    && rm -rf /var/lib/apt/lists/*

# --- Python tools not reliably packaged: install isolated via pipx ------------
# netexec provides `nxc`; add a crackmapexec alias for callers that expect it.
RUN ln -sf "$(command -v nxc || echo /usr/bin/nxc)" /usr/local/bin/crackmapexec || true
RUN pipx install bloodhound.py     || pipx install bloodhound || true
RUN pipx install certipy-ad         || true

# --- HexStrike (~130 finders) — same install as the web lane image ------------
RUN git clone --depth=1 https://github.com/0x4m4/hexstrike-ai.git /opt/hexstrike \
    && python3 -m venv /opt/hexstrike/.venv \
    && /opt/hexstrike/.venv/bin/pip install --no-cache-dir -r /opt/hexstrike/requirements.txt \
    && printf '#!/bin/sh\nexec /opt/hexstrike/.venv/bin/python /opt/hexstrike/hexstrike_server.py "$@"\n' \
         > /usr/local/bin/hexstrike \
    && chmod +x /usr/local/bin/hexstrike

WORKDIR /work

# Cleared entrypoint + no CMD: `docker run --rm ava-internal <tool> <args>`
# runs one tool and exits. `... ava-internal msfrpcd -P <pass> -a 0.0.0.0`
# turns this same image into the MSF RPC host.
ENTRYPOINT []
