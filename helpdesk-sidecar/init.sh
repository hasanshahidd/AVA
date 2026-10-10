#!/bin/bash
# First-boot bench builder for the Frappe Helpdesk sidecar.
# Idempotent: re-runs just `bench start` once the bench exists.
set -e

FRAPPE_BRANCH="${FRAPPE_BRANCH:-version-15}"
HELPDESK_BRANCH="${HELPDESK_BRANCH:-version-15}"

if [ -d "/home/frappe/frappe-bench/apps/frappe" ]; then
    echo "Bench already exists, starting."
    cd /home/frappe/frappe-bench
    bench start
    exit 0
fi

echo "Creating bench (frappe=$FRAPPE_BRANCH, helpdesk=$HELPDESK_BRANCH)..."
cd /home/frappe
bench init --skip-redis-config-generation --version "$FRAPPE_BRANCH" frappe-bench
cd frappe-bench

bench set-mariadb-host mariadb
bench set-redis-cache-host redis://redis:6379
bench set-redis-queue-host redis://redis:6379
bench set-redis-socketio-host redis://redis:6379
sed -i '/redis/d' ./Procfile
sed -i '/watch/d' ./Procfile

bench get-app telephony
bench get-app helpdesk --branch "$HELPDESK_BRANCH"

bench new-site helpdesk.localhost \
  --force --mariadb-root-password 123 --admin-password admin --no-mariadb-socket

bench --site helpdesk.localhost install-app telephony
bench --site helpdesk.localhost install-app helpdesk
bench --site helpdesk.localhost set-config developer_mode 1
bench --site helpdesk.localhost set-config mute_emails 1
bench --site helpdesk.localhost set-config server_script_enabled 1
bench --site helpdesk.localhost clear-cache
bench use helpdesk.localhost

bench start
