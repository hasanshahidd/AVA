#!/usr/bin/env bash
# Download every OS package CAIVA needs — with ALL dependencies — inside a CLEAN
# ubuntu:24.04 container, so the bundle installs on a box with no internet / no apt
# mirror. Output: <out_dir>/debs/*.deb + Packages.gz (a flat local apt repo).
#   ./onprem/fetch-debs.sh <out_dir>
set -euo pipefail
OUT=${1:?usage: fetch-debs.sh <out_dir>}
mkdir -p "$OUT/debs"
OUT=$(cd "$OUT" && pwd)

# Keep in sync with install.sh (PKGS).
PKGS="postgresql-18 redis-server nginx docker.io nmap openscap-scanner sshpass git openssh-client
      tesseract-ocr python3.11 python3.11-venv python3.11-dev libpq-dev build-essential nodejs zstd
      openssl jq curl ca-certificates"

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
