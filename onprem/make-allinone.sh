#!/usr/bin/env bash
# Combine the core installer and the pentest-lanes file into ONE self-contained installer.
# Runs on any Linux box with ~2.5x the lanes size free (the build host can't hold it):
#   ./make-allinone.sh caiva-installer-<v>.run caiva-lanes-<v>.tar.zst [out_dir]
# Output: <out_dir>/caiva-installer-<v>-full.run
set -euo pipefail
CORE=$(readlink -f "${1:?core .run}"); LANES=$(readlink -f "${2:?lanes .tar.zst}"); OUT=$(readlink -f "${3:-$(dirname "$CORE")}")
HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$(mktemp -d "$OUT/.allinone.XXXX"); trap 'rm -rf "$WORK"' EXIT
need=$(( ( $(stat -c %s "$LANES") + $(stat -c %s "$CORE") ) * 2 / 1073741824 + 5 ))
free=$(df -BG --output=avail "$OUT" | tail -1 | tr -dc 0-9)
[ "$free" -ge "$need" ] || { echo "ABORT: need ${need}G free in $OUT (have ${free}G)"; exit 1; }
[ -f "$LANES.sha256" ] && { (cd "$(dirname "$LANES")" && sha256sum -c --quiet "$(basename "$LANES").sha256") || { echo "ABORT: lanes checksum mismatch"; exit 1; }; }

echo "[allinone] unpacking core installer"
line=$(awk '/^__CAIVA_PAYLOAD__$/{print NR+1; exit}' "$CORE")
tail -n +"$line" "$CORE" | tar -x -C "$WORK"
B=$(ls -d "$WORK"/caiva-onprem-* | head -1)
(cd "$B" && sha256sum -c --quiet SHA256SUMS) || { echo "ABORT: core installer is corrupt"; exit 1; }

echo "[allinone] adding pentest lanes ($(du -h "$LANES" | cut -f1))"
mkdir -p "$B/lanes"; ln "$LANES" "$B/lanes/lanes.tar.zst" 2>/dev/null || cp "$LANES" "$B/lanes/lanes.tar.zst"
echo 'lanes_included="1"' >> "$B/MANIFEST"
(cd "$B" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)

. "$B/MANIFEST"
"$HERE/make-run.sh" "$B" "$OUT/caiva-installer-$caiva_version-full.run"
(cd "$OUT" && sha256sum "caiva-installer-$caiva_version-full.run" > "caiva-installer-$caiva_version-full.run.sha256")
echo "[allinone] DONE → $OUT/caiva-installer-$caiva_version-full.run"
