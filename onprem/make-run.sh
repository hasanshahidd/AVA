#!/usr/bin/env bash
# Wrap an assembled bundle directory into ONE self-extracting installer file.
#   ./onprem/make-run.sh <bundle_dir> <out.run>
set -euo pipefail
SRC=${1:?bundle dir}; OUT=${2:?output .run}
# shellcheck disable=SC1091
. "$SRC/MANIFEST"
NAME=$(basename "$SRC")

sed -e "s|__VERSION__|$caiva_version|g" -e "s|__NAME__|$NAME|g" > "$OUT" <<'HEADER'
#!/usr/bin/env bash
# CAIVA on-prem installer __VERSION__ — self-extracting. Ubuntu 24.04 LTS x86_64, run as root.
#
#   sudo ./caiva-installer-__VERSION__.run                    # then finish in the browser
#   sudo ./caiva-installer-__VERSION__.run --unattended --org "JS Bank" --slug jsbl \
#        --host caiva.bank.local --admin-email admin@bank.com  # no browser (automation)
#
# Optional: put caiva-lanes-__VERSION__.tar.zst in the same folder to include AI pentest lanes.
set -euo pipefail
B='\033[1;38;2;0;91;150m'; C='\033[38;2;25;168;230m'; D='\033[2m'; R='\033[0m'
printf "\n${B}   ▄▀▀ ▄▀▄ █ █ █ ▄▀▄${R}\n${B}   ▀▄▄ █▀█ █ ▀▄▀ █▀█${R}   ${C}Cyber Assurance — on-prem installer __VERSION__${R}\n\n"
[ "$(id -u)" = 0 ] || { echo "Run as root: sudo $0"; exit 1; }
. /etc/os-release; [ "$ID" = ubuntu ] && [ "$VERSION_ID" = 24.04 ] || { echo "Ubuntu 24.04 LTS required (found $PRETTY_NAME)"; exit 1; }

SELF=$(readlink -f "$0"); HERE=$(dirname "$SELF")
DIR=/opt/caiva-installer; BUNDLE=$DIR/__NAME__
# room for: unpacked copy of this file + installed platform (and loaded lane images if inside)
need=$(( 100 + $(stat -c %s "$SELF") * 3 / 1073741824 ))
free=$(df -BG --output=avail / | tail -1 | tr -dc 0-9); [ "$free" -ge "$need" ] || { echo "Need >=${need} GB free on / (have ${free} GB)"; exit 1; }
if [ ! -f "$BUNDLE/.unpacked" ]; then
  echo -e "${D}unpacking…${R}"
  mkdir -p "$DIR"; rm -rf "$BUNDLE"
  line=$(awk '/^__CAIVA_PAYLOAD__$/{print NR+1; exit}' "$SELF")
  tail -n +"$line" "$SELF" | tar -x -C "$DIR"
  touch "$BUNDLE/.unpacked"
fi
export CAIVA_LANES=$(ls "$HERE"/caiva-lanes-*.tar.zst 2>/dev/null | head -1 || true)

if [ "${1:-}" = --unattended ]; then shift; exec "$BUNDLE/install.sh" all "$@"; fi

"$BUNDLE/install.sh" prepare
TOKEN=$(head -c 18 /dev/urandom | base64 | tr -dc A-Za-z0-9)
systemctl stop caiva-setup 2>/dev/null || true
systemd-run --unit caiva-setup --collect --quiet /usr/bin/python3 "$BUNDLE/setup/setup_server.py" \
  --bundle "$BUNDLE" --port 8443 --token "$TOKEN"
IP=$(hostname -I | awk '{print $1}')
printf "\n${B}Almost done.${R} Open this link in a browser to finish setup:\n\n   ${C}https://%s:8443/?token=%s${R}\n\n" "$IP" "$TOKEN"
printf "${D}(The setup page uses a temporary certificate — accept the browser warning. It closes itself when setup completes.)${R}\n\n"
exit 0
__CAIVA_PAYLOAD__
HEADER
# plain tar: the big parts are already compressed, and unpacking then needs nothing
# that a fresh Ubuntu server might lack (zstd is installed later from the bundle)
tar -C "$(dirname "$SRC")" -cf - "$NAME" >> "$OUT"
chmod +x "$OUT"
echo "[run] $OUT ($(du -h "$OUT" | cut -f1))"
