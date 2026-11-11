#!/usr/bin/env bash
# Remove CAIVA from this server — INCLUDING ALL ITS DATA (databases, uploads, certificates).
#   sudo ./uninstall.sh --yes-delete-all-data [--purge-packages] [--keep-lanes]
# --purge-packages also removes the OS packages the installer added (PostgreSQL, Redis,
# nginx, Docker, …) — use only on a server dedicated to CAIVA.
set -uo pipefail
[ "$(id -u)" = 0 ] || { echo "run as root"; exit 1; }
CONFIRM=0 PURGE=0 KEEP_LANES=0
for a in "$@"; do case "$a" in
  --yes-delete-all-data) CONFIRM=1 ;; --purge-packages) PURGE=1 ;; --keep-lanes) KEEP_LANES=1 ;;
  *) echo "unknown arg $a"; exit 2 ;; esac; done
[ $CONFIRM = 1 ] || { sed -n 2,5p "$0"; echo "Refusing without --yes-delete-all-data"; exit 2; }

echo "[uninstall] services"
# one unit at a time: a single missing/transient unit (caiva-setup) aborts a multi-unit call
for u in caiva-backend caiva-worker caiva-scheduler caiva-frontend caiva-setup; do
  systemctl stop "$u" 2>/dev/null; systemctl disable "$u" 2>/dev/null
done
rm -f /etc/systemd/system/caiva-*.service; systemctl daemon-reload
pkill -f '/opt/caiva/' 2>/dev/null || true   # anything still running from the removed tree
if command -v docker >/dev/null; then
  docker rm -f ava-msfrpcd >/dev/null 2>&1
  [ $KEEP_LANES = 1 ] || docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^ava-' | xargs -r docker rmi -f >/dev/null 2>&1
fi

echo "[uninstall] databases"
if command -v psql >/dev/null && systemctl is-active --quiet postgresql; then
  for db in $(sudo -u postgres psql -tA -c "select datname from pg_database where datname like 'cyber\_%'"); do
    sudo -u postgres psql -q -c "drop database \"$db\" with (force)"
  done
  sudo -u postgres psql -q -c "drop role if exists grc_app"
fi

echo "[uninstall] files"
[ -L /root/AVA ] && rm -f /root/AVA
rm -rf /opt/caiva /opt/caiva-installer /var/lib/caiva-setup /etc/caiva /opt/ssg /opt/nuclei-templates /root/wordlists \
       /root/.caiva-secrets /root/caiva-credentials.txt /var/log/caiva-install.log
rm -f /etc/nginx/sites-enabled/caiva /etc/nginx/sites-available/caiva
if [ -f /usr/local/share/ca-certificates/caiva-ca.crt ]; then
  rm -f /usr/local/share/ca-certificates/caiva-ca.crt; update-ca-certificates --fresh >/dev/null
fi
command -v nginx >/dev/null && { nginx -t >/dev/null 2>&1 && systemctl reload nginx 2>/dev/null; }

if [ $PURGE = 1 ]; then
  echo "[uninstall] OS packages"
  export DEBIAN_FRONTEND=noninteractive
  systemctl stop postgresql redis-server nginx docker docker.socket containerd 2>/dev/null
  systemctl disable docker.socket docker 2>/dev/null
  apt-get purge -y -q postgresql-18 'postgresql-client-18' postgresql-common redis-server nginx nginx-common docker.io containerd \
     nmap openscap-scanner sshpass tesseract-ocr python3.11 python3.11-venv python3.11-dev >/dev/null
  apt-get autoremove -y -q --purge >/dev/null
  rm -rf /var/lib/postgresql /var/lib/redis /var/lib/docker /var/lib/containerd /etc/postgresql
fi
rm -f /usr/local/sbin/caiva-uninstall
echo "[uninstall] done — CAIVA removed"
