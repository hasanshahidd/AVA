#!/usr/bin/env bash
# Build the CAIVA on-prem installer FROM a working CAIVA host (Ubuntu 24.04, prod layout:
# /root/AVA, backend/venv on python3.11, built grc-frontend/.next, docker with lane images).
# Read-only towards the running services. Produces, in <out_dir>:
#
#   caiva-installer-<sha>.run      self-extracting installer (everything except pentest lanes)
#   caiva-lanes-<sha>.tar.zst      pentest lane images (optional; put next to the .run)
#
#   ./onprem/build-bundle.sh <out_dir> [--seed-slug obeikan] [--no-lanes] [--no-wordlists]
#
# Lanes are tens of GB: <out_dir> must be on a disk with room (NOT prod's root disk —
# check `df`); or build without lanes and stream them: export-lanes.sh | ssh host 'cat > f'.
set -euo pipefail

OUT=${1:?usage: build-bundle.sh <out_dir> [--seed-slug SLUG] [--no-lanes] [--no-wordlists]}; shift
SEED=obeikan; LANES=1; WORDLISTS=1
while [ $# -gt 0 ]; do
  case "$1" in
    --seed-slug) SEED=$2; shift ;;
    --no-lanes) LANES=0 ;;
    --no-wordlists) WORDLISTS=0 ;;
    *) echo "unknown arg $1"; exit 2 ;;
  esac; shift
done

SRC=${CAIVA_SRC:-/root/AVA}
HERE=$(cd "$(dirname "$0")" && pwd)
SHA=$(git -C "$SRC" rev-parse --short HEAD)
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
B="$OUT/caiva-onprem-$SHA"
log() { echo "[bundle $(date +%T)] $*"; }
pgq() { sudo -u postgres psql -tA -d "$1" -c "$2"; }

# ── guards ────────────────────────────────────────────────────────────────
[ "$(wc -c < "$SRC/grc-frontend/postcss.config.js")" -eq 83 ] || { echo "ABORT: postcss.config.js is not 83 bytes (supply-chain guard)"; exit 1; }
[ -d "$SRC/grc-frontend/.next" ] || { echo "ABORT: frontend not built"; exit 1; }
[ -z "$(git -C "$SRC" status --porcelain --untracked-files=no)" ] || { echo "ABORT: $SRC has uncommitted tracked changes"; exit 1; }
for t in zstd docker; do command -v $t >/dev/null || { echo "ABORT: $t missing"; exit 1; }; done
[ "$(pgq "cyber_$SEED" "select count(*) from grc_it_assets")" = 0 ] && [ "$(pgq "cyber_$SEED" "select count(*) from grc_users")" = 1 ] \
  || { echo "ABORT: seed cyber_$SEED is not clean (must have 0 assets, 1 user)"; exit 1; }
LOCAL_ID=$(pgq "cyber_$SEED" "select id from grc_tenants")
MASTER_ID=$(pgq cyber_master "select id from grc_tenants where slug='$SEED'")
[ -n "$LOCAL_ID" ] && [ "$LOCAL_ID" = "$MASTER_ID" ] || { echo "ABORT: seed tenant id mismatch (local=$LOCAL_ID master=$MASTER_ID)"; exit 1; }
need=8; [ $LANES = 1 ] && need=70
free=$(df -BG --output=avail "$OUT" | tail -1 | tr -dc 0-9)
[ "$free" -ge $need ] || { echo "ABORT: need ${need}G free in $OUT (have ${free}G)"; exit 1; }

rm -rf "$B"; mkdir -p "$B"/{app,seed,artifacts,lanes,debs}

log "1/8 code @ $SHA"
git -C "$SRC" archive HEAD | tar -x -C "$B/app"

log "1b/8 strip dev files + compile our Python to bytecode (ship .pyc, no source)"
A="$B/app"; PYBIN="$SRC/backend/venv/bin/python"
# developer-only material that never runs the product (pure IP leakage)
rm -rf "$A/_archive_old_control_library" "$A/_deferred_stage5_attack_pipeline" "$A/ai-pentest-eval" "$A/docs"
find "$A" -maxdepth 1 -type f \( -name '*.md' -o -name '*.html' -o -name '*.png' -o -name '*.jpg' -o -name '*.JPG' -o -name '*.csv' \) -delete
find "$A" -type d \( -name tests -o -name __pycache__ \) -prune -exec rm -rf {} + 2>/dev/null || true
# compile OUR code (NOT venv — third-party public libs, created on target from wheels)
for d in backend ava-pentest-engine; do
  [ -d "$A/$d" ] || continue
  "$PYBIN" -m compileall -b -q -j 0 -x '(/venv/|/node_modules/)' "$A/$d"     || { echo "ABORT: bytecode compile failed in $d"; exit 1; }
done
# compileall above ran with || ABORT, so every .py now has a .pyc beside it — drop all source
find "$A/backend" "$A/ava-pentest-engine" -name '*.py' -not -path '*/venv/*' -delete
# sanity: the app entrypoints must exist as bytecode and no source must remain in our tree
[ -f "$A/backend/grc/main.pyc" ] || { echo "ABORT: grc/main not compiled"; exit 1; }
n=$(find "$A/backend/grc" "$A/ava-pentest-engine" -name '*.py' -not -path '*/venv/*' | wc -l)
[ "$n" -eq 0 ] || { echo "ABORT: $n source .py still present after compile"; exit 1; }

log "2/8 web interface (pre-built on this OS)"
tar -C "$SRC/grc-frontend" -cf - .next node_modules | zstd -T0 -q -o "$B/artifacts/frontend.tar.zst"

log "3/8 python wheels (exactly what prod's venv runs)"
"$SRC/backend/venv/bin/pip" freeze --exclude-editable | grep -vE '^(-e |.* @ file:)' > "$B/artifacts/requirements.lock"
# `pip wheel` builds any sdist here, so the customer box never needs build tools / internet
"$SRC/backend/venv/bin/pip" wheel -q -r "$B/artifacts/requirements.lock" -w "$B/artifacts/wheels"

log "4/8 OS packages (clean ubuntu:24.04 dependency closure)"
# CAIVA_DEBS_FROM=<dir>: reuse a verified debs/ from an earlier build when Launchpad/PPA mirrors are down
if [ -n "${CAIVA_DEBS_FROM:-}" ]; then cp -a "$CAIVA_DEBS_FROM"/. "$B/debs/"; else "$HERE/fetch-debs.sh" "$B"; fi
[ -s "$B/debs/Packages.gz" ] || { echo "ABORT: package index not built"; exit 1; }

log "5/8 agents, Linux CIS content, nuclei templates, wordlists"
cp -r "$SRC/agent-dist" "$B/artifacts/agent-dist"
tar -C /opt -cf - ssg | zstd -T0 -q -o "$B/artifacts/ssg.tar.zst"
[ -d /opt/nuclei-templates ] && tar -C /opt -cf - nuclei-templates | zstd -T0 -q -o "$B/artifacts/nuclei-templates.tar.zst"
[ $WORDLISTS = 1 ] && [ -d /root/wordlists ] && tar -C /root -cf - wordlists | zstd -T0 -q -o "$B/artifacts/wordlists.tar.zst"

log "6/8 seed databases (clean tenant cyber_$SEED, id $LOCAL_ID)"
sudo -u postgres pg_dump -Fc --no-owner --no-acl "cyber_$SEED" > "$B/seed/tenant.dump"
sudo -u postgres pg_dump -Fc --no-owner --no-acl --schema-only cyber_master > "$B/seed/master.dump"

log "7/8 installer, setup wizard, manifest"
cp "$HERE"/install.sh "$HERE"/uninstall.sh "$HERE"/onprem_init.py "$B/"
cp -r "$HERE/templates" "$HERE/setup" "$B/"
cat > "$B/MANIFEST" <<EOF
caiva_version="$SHA"
built_at="$(date -u +%FT%TZ)"
seed_slug="$SEED"
python="$("$SRC/backend/venv/bin/python" --version 2>&1)"
EOF
(cd "$B" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
"$HERE/make-run.sh" "$B" "$OUT/caiva-installer-$SHA.run"
rm -rf "$B"

if [ $LANES = 1 ]; then
  log "8/8 pentest lanes (slow)"
  "$HERE/export-lanes.sh" > "$OUT/caiva-lanes-$SHA.tar.zst"
  (cd "$OUT" && sha256sum "caiva-lanes-$SHA.tar.zst" > "caiva-lanes-$SHA.tar.zst.sha256")
fi
log "DONE"; ls -lh "$OUT"/caiva-*"$SHA"*
