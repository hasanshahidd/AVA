#!/usr/bin/env bash
# Install CURRENT nuclei (the installed ~/go/bin one is too old — rejects -u that HexStrike uses).
set -u
echo "disk: $(df -h /mnt/c | awk 'NR==2{print $4}') free"
cd /tmp || exit 1
TAG=$(curl -sf https://api.github.com/repos/projectdiscovery/nuclei/releases/latest 2>/dev/null | grep -oP '"tag_name":\s*"\K[^"]+' | head -1)
[ -n "$TAG" ] || { echo "could not resolve nuclei release"; exit 1; }
VER=${TAG#v}
echo "latest nuclei: $TAG"
curl -sfL "https://github.com/projectdiscovery/nuclei/releases/download/${TAG}/nuclei_${VER}_linux_amd64.zip" -o /tmp/nuclei.zip || { echo "download failed"; exit 1; }
rm -rf /tmp/nucleibin && mkdir -p /tmp/nucleibin
unzip -o /tmp/nuclei.zip nuclei -d /tmp/nucleibin >/dev/null 2>&1
mkdir -p ~/go/bin
cp /tmp/nucleibin/nuclei ~/go/bin/nuclei && chmod +x ~/go/bin/nuclei
sudo ln -sf ~/go/bin/nuclei /usr/local/bin/nuclei 2>/dev/null || true
echo "installed: $(~/go/bin/nuclei -version 2>&1 | grep -iE 'version|current' | head -1)"
# pre-fetch templates so the first real scan isn't slow/interactive
~/go/bin/nuclei -update-templates 2>&1 | tail -1
