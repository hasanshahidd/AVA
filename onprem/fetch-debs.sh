#!/usr/bin/env bash
# Download every OS package CAIVA needs — with ALL dependencies — inside a CLEAN
# ubuntu:24.04 container, so the bundle installs on a box with no internet / no apt
# mirror. Output: <out_dir>/debs/*.deb + Packages.gz (a flat local apt repo).
#   ./onprem/fetch-debs.sh <out_dir>
set -euo pipefail
OUT=${1:?usage: fetch-debs.sh <out_dir>}
mkdir -p "$OUT/debs"
OUT=$(cd "$OUT" && pwd)

# Keep in sync with install.sh (PKGS) — full cloud-host parity minus base-OS/kernel/DO-agent/VPN/firefox-snap.
PKGS="postgresql-18 redis-server nginx docker.io nmap openscap-scanner openscap-utils sshpass git
      openssh-client openssh-server openssh-sftp-server tesseract-ocr
      python3.11 python3.11-venv python3.11-dev python3-pip python3-venv python3-babel python3-certbot-nginx
      python3-jinja2 python3-json-pointer python3-jsonpatch python3-jsonschema python3-markupsafe
      python3-pyrsistent python3-serial python3-tz python-babel-localedata
      build-essential golang-go libffi-dev libpq-dev nodejs zstd openssl jq curl ca-certificates gnupg gnupg2
      unzip sqlite3 pv tmux apt-transport-https apt-utils eatmydata openjdk-17-jre-headless certbot
      xvfb gnome-keyring fonts-freefont-ttf fonts-ipafont-gothic fonts-liberation fonts-noto-color-emoji
      fonts-tlwg-loma-otf fonts-unifont fonts-wqy-zenhei xfonts-cyrillic xfonts-scalable
      libasound2t64 libatk-bridge2.0-0t64 libatk1.0-0t64 libatspi2.0-0t64 libcairo2 libcups2t64 libdbus-1-3
      libdrm2 libfontconfig1 libfreetype6 libgbm1 libglib2.0-0t64 libnspr4 libnss3 libpango-1.0-0 libwrap0
      libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 libxfixes3 libxkbcommon0 libxrandr2"

docker run --rm -v "$OUT/debs:/out" ubuntu:24.04 bash -euo pipefail -c "
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -q && apt-get install -y -q ca-certificates curl gnupg software-properties-common >/dev/null
  install -d /usr/share/postgresql-common/pgdg
  curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc
  echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt noble-pgdg main' > /etc/apt/sources.list.d/pgdg.list
  add-apt-repository -y ppa:deadsnakes/ppa >/dev/null
  apt-get update -q
  # download-only into an EMPTY cache = the full dependency closure of a minimal 24.04 box
  apt-get clean
  apt-get install -y -q --download-only $(echo $PKGS)
  cp /var/cache/apt/archives/*.deb /out/
  # index AFTER downloading, so dpkg-dev itself isn't mistaken for a dependency
  apt-get install -y -q dpkg-dev >/dev/null
  cd /out && dpkg-scanpackages -m . /dev/null 2>/dev/null | gzip -9 > Packages.gz
"
echo "[debs] $(ls "$OUT/debs"/*.deb | wc -l) packages, $(du -sh "$OUT/debs" | cut -f1)"
