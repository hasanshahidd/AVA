#!/usr/bin/env bash
# CAIVA on-prem engine — Ubuntu 24.04 LTS x86_64, root, fully OFFLINE (no internet,
# no apt mirror, no pip/npm/docker pull). Driven by caiva-installer.run + the setup
# wizard, or by hand:
#
#   ./install.sh prepare                      # packages, app, tools, lanes (no questions)
#   ./install.sh configure --org "JS Bank" --slug jsbl --host caiva.jsbank.local \
#        --admin-email admin@jsbank.com.pk [--cert f.pem --key k.pem] [--openai-key ..]
#        [--smtp-host .. --smtp-port .. --smtp-user .. --smtp-password .. --smtp-from ..]
#        [--exploit-scope "10.0.0.0/24 ..."]
#   ./install.sh all  <configure args>        # both, unattended
#
# Progress for the wizard: one line per step in $STATE/steps ("key|label|status").
set -euo pipefail

B=$(cd "$(dirname "$0")" && pwd)          # unpacked bundle
DEST=/opt/caiva
STATE=/var/lib/caiva-setup
LOG=/var/log/caiva-install.log
mkdir -p "$STATE"; touch "$LOG"; chmod 600 "$LOG"
exec > >(tee -a "$LOG") 2>&1

STEPS_FILE=$STATE/steps
CUR=""
die() { [ -n "$CUR" ] && mark "$CUR" failed; echo "FAILED: $*"; echo "$*" > "$STATE/error"; exit 1; }
mark() { # key status — rewrite that step's line
  local k=$1 s=$2; [ -f "$STEPS_FILE" ] || return 0
  awk -F'|' -v k="$k" -v s="$s" 'BEGIN{OFS="|"} $1==k{$3=s} {print}' "$STEPS_FILE" > "$STEPS_FILE.tmp" && mv "$STEPS_FILE.tmp" "$STEPS_FILE"
}
step() { [ -n "$CUR" ] && mark "$CUR" done; CUR=$1; mark "$1" running; echo; echo "=== [$(date +%T)] $2"; }
plan() { : > "$STEPS_FILE"; for s in "$@"; do echo "$s|pending" >> "$STEPS_FILE"; done; rm -f "$STATE/error"; }
finish() { [ -n "$CUR" ] && mark "$CUR" done; CUR=""; }

PKGS="postgresql-18 redis-server nginx docker.io nmap openscap-scanner sshpass git openssh-client
      tesseract-ocr python3.11 python3.11-venv python3.11-dev libpq-dev build-essential nodejs zstd
      openssl jq curl ca-certificates"

# ═════════════════════════════ prepare ═════════════════════════════════════
prepare() {
  plan "checks|System check" "packages|Operating-system packages" "app|CAIVA application" \
       "python|Python runtime" "frontend|Web interface" "tools|Scanning content & tools" "lanes|Pentest lanes"
  step checks "preflight"
  [ "$(id -u)" = 0 ] || die "run as root (sudo)"
  . /etc/os-release
  [ "$ID" = ubuntu ] && [ "$VERSION_ID" = 24.04 ] || die "Ubuntu 24.04 required (found $PRETTY_NAME)"
  [ "$(uname -m)" = x86_64 ] || die "x86_64 required"
  local disk; disk=$(df -BG --output=avail / | tail -1 | tr -dc 0-9)
  [ "$disk" -ge 100 ] || die "need >=100 GB free on / (found ${disk} GB)"
  (cd "$B" && sha256sum -c --quiet SHA256SUMS) || die "bundle checksum mismatch — re-copy the installer"

  step packages "OS packages from the bundle (offline)"
  export DEBIAN_FRONTEND=noninteractive
  # The bundle IS the apt repository; no network sources are consulted.
  echo "deb [trusted=yes] file:$B/debs ./" > /etc/apt/sources.list.d/caiva-offline.list
  local LOCAL=(-o Dir::Etc::sourcelist=sources.list.d/caiva-offline.list -o Dir::Etc::sourceparts=- -o APT::Get::List-Cleanup=0)
  apt-get update -q "${LOCAL[@]}" || die "bundled package index unreadable"
  # shellcheck disable=SC2086
  apt-get install -y -q "${LOCAL[@]}" $PKGS || die "OS package install failed"
  rm -f /etc/apt/sources.list.d/caiva-offline.list
  node -e 'process.exit(+process.versions.node.split(".")[0] >= 18 ? 0 : 1)' || die "Node.js >= 18 required"
  systemctl enable --now postgresql redis-server docker nginx

  step app "application → $DEST"
  mkdir -p "$DEST"
  cp -a "$B/app/." "$DEST/"
  mkdir -p "$DEST/onprem" "$DEST/scan-ingest" "$DEST/backend/uploads"
  cp "$B/onprem_init.py" "$DEST/onprem/"
  install -m 755 "$B/uninstall.sh" /usr/local/sbin/caiva-uninstall
  rm -rf "$DEST/agent-dist"; cp -a "$B/artifacts/agent-dist" "$DEST/agent-dist"
  [ -e /root/AVA ] || ln -s "$DEST" /root/AVA       # some modules still use the prod path

  step python "Python environment (offline wheels)"
  [ -x "$DEST/backend/venv/bin/python" ] || python3.11 -m venv "$DEST/backend/venv"
  "$DEST/backend/venv/bin/pip" install -q --no-index --find-links "$B/artifacts/wheels" \
      -r "$B/artifacts/requirements.lock" || die "python packages failed to install"

  step frontend "web interface (pre-built)"
  rm -rf "$DEST/grc-frontend/.next" "$DEST/grc-frontend/node_modules"
  zstd -dc "$B/artifacts/frontend.tar.zst" | tar -x -C "$DEST/grc-frontend"
  cp "$B/templates/frontend.env.tpl" "$DEST/grc-frontend/.env.production.local"

  step tools "CIS content, nuclei templates, wordlists"
  for t in ssg nuclei-templates; do
    [ -f "$B/artifacts/$t.tar.zst" ] && { rm -rf "/opt/$t"; zstd -dc "$B/artifacts/$t.tar.zst" | tar -x -C /opt; }
  done
  [ -d /opt/ssg ] || die "Linux CIS content (/opt/ssg) missing from bundle"
  if [ -f "$B/artifacts/wordlists.tar.zst" ] && [ ! -d /root/wordlists ]; then zstd -dc "$B/artifacts/wordlists.tar.zst" | tar -x -C /root; fi

  step lanes "pentest lane images"
  # caiva-lanes-<ver>.tar.zst ships as a separate file next to the .run (tens of GB)
  local LANES=${CAIVA_LANES:-}
  if [ -n "$LANES" ] && [ -s "$LANES" ]; then
    [ -f "$LANES.sha256" ] && { (cd "$(dirname "$LANES")" && sha256sum -c --quiet "$(basename "$LANES").sha256") || die "lane file checksum mismatch"; }
    zstd -dc "$LANES" | docker load || die "lane images failed to load"
  else echo "no lane file next to the installer — discovery, inventory, CIS and vulnerabilities work; AI pentest lanes stay off"; fi
  finish
  touch "$STATE/prepared"
}

# ═════════════════════════════ configure ═══════════════════════════════════
ORG= SLUG= HOST= ADMIN_EMAIL= CERT= KEY= OPENAI_KEY= EXPLOIT_SCOPE=
SMTP_HOST= SMTP_PORT=587 SMTP_USER= SMTP_PASSWORD= SMTP_FROM=
parse() {
  while [ $# -gt 0 ]; do
    case "$1" in
      --org) ORG=$2 ;; --slug) SLUG=$2 ;; --host) HOST=$2 ;; --admin-email) ADMIN_EMAIL=$2 ;;
      --cert) CERT=$2 ;; --key) KEY=$2 ;; --openai-key) OPENAI_KEY=$2 ;; --exploit-scope) EXPLOIT_SCOPE=$2 ;;
      --smtp-host) SMTP_HOST=$2 ;; --smtp-port) SMTP_PORT=$2 ;; --smtp-user) SMTP_USER=$2 ;;
      --smtp-password) SMTP_PASSWORD=$2 ;; --smtp-from) SMTP_FROM=$2 ;;
      *) echo "unknown arg: $1"; exit 2 ;;
    esac; shift 2
  done
  # free-text values are single-quoted in .env (read by systemd, python-dotenv AND bash)
  for v in "$ORG" "$OPENAI_KEY" "$EXPLOIT_SCOPE" "$SMTP_HOST" "$SMTP_USER" "$SMTP_PASSWORD" "$SMTP_FROM"; do
    case "$v" in *"'"*|*$'\n'*) die "values may not contain a single quote or a line break" ;; esac
  done
  [[ "$SMTP_PORT" =~ ^[0-9]{1,5}$ ]] || die "SMTP port must be a number"
  ADMIN_EMAIL=$(echo "$ADMIN_EMAIL" | tr 'A-Z' 'a-z')
  HOST=$(echo "$HOST" | tr 'A-Z' 'a-z')
  [ -n "$ORG" ] && [ -n "$SLUG" ] && [ -n "$HOST" ] && [ -n "$ADMIN_EMAIL" ] || { sed -n 6,10p "$0"; exit 2; }
  [[ "$ADMIN_EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[a-z]{2,}$ ]] || die "invalid admin email"
  [[ "$HOST" =~ ^[a-z0-9.-]+$ ]] || die "invalid host name"
  # The login page reads the tenant from the FIRST label of a 3+-label host name, so on
  # such hosts the tenant must be that label (caiva.jsbank.local → tenant "caiva").
  SUB=""
  if ! [[ "$HOST" =~ ^[0-9.]+$ ]] && [ "$(echo "$HOST" | tr -cd . | wc -c)" -ge 2 ]; then
    SUB=${HOST%%.*}
    [ "$SLUG" = "$SUB" ] || { echo "note: tenant id set to '$SUB' (first label of $HOST)"; SLUG=$SUB; }
  fi
  [[ "$SLUG" =~ ^[a-z][a-z0-9]{1,30}$ ]] || die "tenant id must be 2-31 lowercase letters/digits starting with a letter (got '$SLUG')"
}

configure() {
  parse "$@"
  [ -f "$STATE/prepared" ] || die "run '$0 prepare' first"
  plan "database|Database" "config|Configuration" "tenant|Organization & administrator" \
       "tls|Certificate" "services|Start services" "health|Health check"
  local SECRETS=/root/.caiva-secrets
  umask 077
  [ -f $SECRETS ] || {
    echo "DB_PW=$(openssl rand -hex 24)"; echo "SESSION_SECRET=$(openssl rand -hex 32)"
    echo "CONNECTOR_KEY=$(openssl rand -base64 32 | tr -d '\n')"; echo "MSF_PW=$(openssl rand -hex 16)"
    echo "SALT=$(openssl rand -hex 16)"
    echo "ADMIN_PW=Caiva-$(openssl rand -base64 18 | tr -dc A-Za-z0-9 | head -c 12)-1"
  } > $SECRETS
  # shellcheck disable=SC1090
  . $SECRETS

  step database "database"
  pg() { sudo -u postgres psql -v ON_ERROR_STOP=1 -tA "$@"; }
  [ -n "$(pg -c "select 1 from pg_roles where rolname='grc_app'")" ] || pg -c "create role grc_app login createdb password '$DB_PW'"
  pg -c "alter role grc_app password '$DB_PW'" >/dev/null
  restore() {  # db dump
    if [ -n "$(pg -c "select 1 from pg_database where datname='$1'")" ]; then echo "$1 exists — kept"; return; fi
    pg -c "create database $1 owner grc_app"
    install -m 644 "$2" /tmp/caiva-restore.dump
    sudo -u postgres pg_restore --no-owner --role=grc_app -d "$1" /tmp/caiva-restore.dump \
      || { rm -f /tmp/caiva-restore.dump; pg -c "drop database $1"; die "restore of $1 failed"; }
    rm -f /tmp/caiva-restore.dump
    pg -d "$1" -c "grant all on all tables in schema public to grc_app; grant all on all sequences in schema public to grc_app" >/dev/null
  }
  restore cyber_master "$B/seed/master.dump"
  restore "cyber_$SLUG" "$B/seed/tenant.dump"

  step config "configuration"
  esc() { printf '%s' "$1" | sed -e 's/[|&\\]/\\&/g'; }
  sed -e "s|__DB_PW__|$DB_PW|g" -e "s|__SESSION_SECRET__|$SESSION_SECRET|g" -e "s|__CONNECTOR_KEY__|$(esc "$CONNECTOR_KEY")|g" \
      -e "s|__MSF_PW__|$MSF_PW|g" -e "s|__SALT__|$SALT|g" \
      -e "s|__HOST__|$HOST|g" -e "s|__SLUG__|$SLUG|g" -e "s|__OPENAI_KEY__|$(esc "$OPENAI_KEY")|g" \
      -e "s|__EXPLOIT_SCOPE__|$(esc "$EXPLOIT_SCOPE")|g" \
      -e "s|__SMTP_HOST__|$(esc "$SMTP_HOST")|g" -e "s|__SMTP_PORT__|$(esc "$SMTP_PORT")|g" \
      -e "s|__SMTP_USER__|$(esc "$SMTP_USER")|g" -e "s|__SMTP_PASSWORD__|$(esc "$SMTP_PASSWORD")|g" \
      -e "s|__SMTP_FROM__|$(esc "$SMTP_FROM")|g" \
      "$B/templates/backend.env.tpl" > "$DEST/backend/.env"
  chmod 600 "$DEST/backend/.env"

  step tenant "organization + administrator"
  if [ -f "$STATE/initialized" ]; then
    echo "tenant already initialized — identity and users left untouched"
  else
    printf '%s' "$ADMIN_PW" > /root/.caiva-admin-pw
    (cd "$DEST/backend" && venv/bin/python "$DEST/onprem/onprem_init.py" --slug "$SLUG" --org "$ORG" \
       --subdomain "$SUB" --admin-email "$ADMIN_EMAIL" --password-file /root/.caiva-admin-pw) || { rm -f /root/.caiva-admin-pw; die "tenant init failed"; }
    rm -f /root/.caiva-admin-pw
    touch "$STATE/initialized"
  fi

  step tls "certificate"
  install -d -m 755 /etc/caiva/tls
  if [ -n "$CERT" ] && [ -n "$KEY" ]; then
    install -m 644 "$CERT" /etc/caiva/tls/fullchain.pem; install -m 600 "$KEY" /etc/caiva/tls/privkey.pem
    openssl x509 -noout -in /etc/caiva/tls/fullchain.pem || die "certificate is not valid PEM"
  elif [ ! -f /etc/caiva/tls/fullchain.pem ]; then
    # A local CA (not a bare self-signed cert): agents only trust system roots, so the bank
    # pushes caiva-ca.crt to endpoints (GPO / config mgmt) once, then agents enroll over TLS.
    local SAN="DNS:$HOST"; [[ "$HOST" =~ ^[0-9.]+$ ]] && SAN="IP:$HOST"
    openssl req -x509 -nodes -newkey rsa:3072 -days 3650 -subj "/CN=CAIVA Local CA ($ORG)" \
      -keyout /etc/caiva/tls/ca.key -out /etc/caiva/tls/caiva-ca.crt 2>/dev/null
    openssl req -nodes -newkey rsa:2048 -subj "/CN=$HOST" -keyout /etc/caiva/tls/privkey.pem -out /tmp/caiva.csr 2>/dev/null
    printf 'subjectAltName=%s\nextendedKeyUsage=serverAuth\n' "$SAN" > /tmp/caiva.ext
    openssl x509 -req -in /tmp/caiva.csr -CA /etc/caiva/tls/caiva-ca.crt -CAkey /etc/caiva/tls/ca.key -CAcreateserial \
      -days 825 -extfile /tmp/caiva.ext -out /etc/caiva/tls/fullchain.pem 2>/dev/null
    rm -f /tmp/caiva.csr /tmp/caiva.ext; chmod 600 /etc/caiva/tls/ca.key /etc/caiva/tls/privkey.pem
    cp /etc/caiva/tls/caiva-ca.crt /usr/local/share/ca-certificates/caiva-ca.crt && update-ca-certificates >/dev/null
  fi
  sed "s|__HOST__|$HOST|g" "$B/templates/nginx-caiva.conf" > /etc/nginx/sites-available/caiva
  rm -f /etc/nginx/sites-enabled/default; ln -sf /etc/nginx/sites-available/caiva /etc/nginx/sites-enabled/caiva
  nginx -t || die "nginx config invalid"

  step services "starting services"
  cp "$B"/templates/caiva-*.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable caiva-backend caiva-worker caiva-frontend
  systemctl restart caiva-backend caiva-worker caiva-frontend
  systemctl reload nginx
  # Metasploit RPC for exploit validation — the backend only starts it in a hook that
  # doesn't run in the web process, so the installer owns it (restarts with the box).
  if docker image inspect ava-internal >/dev/null 2>&1; then
    docker rm -f ava-msfrpcd >/dev/null 2>&1 || true
    docker run -d --restart unless-stopped --network host --name ava-msfrpcd --entrypoint bash \
      -e MSF_RPC_PASSWORD="$MSF_PW" ava-internal -lc 'msfrpcd -P "$MSF_RPC_PASSWORD" -S -a 127.0.0.1 -p 55553; sleep infinity' >/dev/null
  fi

  step health "health check"
  local ok=0 b f
  for _ in $(seq 1 60); do
    b=$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:4000/grc/health || true)
    f=$(curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1/login -H "Host: $HOST" || true)
    [ "$b" = 200 ] && [ "$f" = 200 ] && { ok=1; break; }; sleep 5
  done
  [ $ok = 1 ] || die "services did not come up (backend=$b web=$f) — journalctl -u caiva-backend -u caiva-frontend"
  # same request the browser makes (incl. the tenant header the login page derives from the host)
  local hdr=(); [ -n "$SUB" ] && hdr=(-H "X-Tenant-Slug: $SUB")
  local code; code=$(curl -sk -o /dev/null -w '%{http_code}' -H "Host: $HOST" "${hdr[@]}" -H 'Content-Type: application/json' \
    --data "$(jq -nc --arg u "$ADMIN_EMAIL" --arg p "$ADMIN_PW" '{username:$u,password:$p}')" https://127.0.0.1/api/auth/login || true)
  [ "$code" = 200 ] || die "administrator login test returned HTTP $code"
  finish

  local CRED=/root/caiva-credentials.txt
  printf 'CAIVA on-prem — %s\nURL:      https://%s\nAdmin:    %s\nPassword: %s\n%s(change it after first sign-in; root-only file)\n' \
    "$ORG" "$HOST" "$ADMIN_EMAIL" "$ADMIN_PW" \
    "$([ -f /etc/caiva/tls/caiva-ca.crt ] && echo "Local CA: /etc/caiva/tls/caiva-ca.crt — push to endpoints before rolling out agents
")" > $CRED
  chmod 600 $CRED
  jq -n --arg url "https://$HOST" --arg e "$ADMIN_EMAIL" --arg p "$ADMIN_PW" --argjson ca "$([ -f /etc/caiva/tls/caiva-ca.crt ] && echo true || echo false)"     '{url:$url,admin_email:$e,admin_password:$p,local_ca:$ca}' > "$STATE/result.json"
  chmod 600 "$STATE/result.json"
  echo "=== DONE — CAIVA is running at https://$HOST (credentials: $CRED)"
}

case "${1:-}" in
  prepare) prepare ;;
  configure) shift; configure "$@" ;;
  all) shift; prepare; configure "$@" ;;
  *) sed -n 2,13p "$0"; exit 2 ;;
esac
