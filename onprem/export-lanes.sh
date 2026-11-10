#!/usr/bin/env bash
# Stream every pentest lane image (ava-*:latest) as one zstd'd `docker save` to stdout.
# Shared layers are written once. Pipe it straight to the target so nothing is
# staged on the build host's disk:
#   ./onprem/export-lanes.sh | ssh root@vm 'cat > /opt/caiva-bundle/lanes/lanes.tar.zst'
set -euo pipefail
mapfile -t IMAGES < <(docker images --format '{{.Repository}}:{{.Tag}}' | grep -E '^ava-[a-z0-9-]+:latest$' | sort)
[ ${#IMAGES[@]} -gt 0 ] || { echo "no ava-*:latest images found" >&2; exit 1; }
echo "[lanes] ${#IMAGES[@]} images: ${IMAGES[*]}" >&2
docker save "${IMAGES[@]}" | zstd -T0 -q -c
