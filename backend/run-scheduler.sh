#!/usr/bin/env bash
# caiva-scheduler: the ONE worker+beat for grc.celery_app — the periodic jobs
# (KEV/EPSS daily refresh, exception expiry, cloud/connector/CMDB sync, scheduled
# network discovery, zombie-scan reconcile). These live on the `parsing` queue and
# were never run before: the only worker (run-worker.sh) serves grc.modules.pentest.tasks.
# Embedded beat (-B) is correct here because exactly ONE such service runs per deployment;
# never start a second instance or the schedule double-fires.
set -euo pipefail
cd "$(dirname "$0")"
set -a; . ./.env 2>/dev/null || true; set +a
exec venv/bin/celery -A grc.celery_app:celery_app worker -B \
  --pool=prefork -c "${AVA_SCHEDULER_CONCURRENCY:-1}" -Q parsing,celery -n caiva-scheduler@%h
