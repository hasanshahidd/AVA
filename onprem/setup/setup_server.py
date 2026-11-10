#!/usr/bin/env python3
"""CAIVA setup wizard backend — stdlib only (runs on the box's system python3).

Started by the .run installer after `install.sh prepare`:
    python3 setup_server.py --bundle /opt/caiva-installer/caiva-onprem-<v> --port 8443 --token <t>
Serves wizard.html over HTTPS (temporary self-signed cert), drives `install.sh configure`,
and exits on its own after setup completes. Every API call needs the one-time token.
"""
import argparse
import email.parser
import email.policy
import hmac
import json
import os
import re
import shutil
import socket
import ssl
import subprocess
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

STATE = "/var/lib/caiva-setup"
LOG = "/var/log/caiva-install.log"
UPLOAD = os.path.join(STATE, "upload")
CONFIGURE_STEPS = [("database", "Database"), ("config", "Configuration"), ("tenant", "Organization & administrator"),
                   ("tls", "Certificate"), ("services", "Start services"), ("health", "Health check")]
SLUG_RE = re.compile(r"^[a-z][a-z0-9]{1,30}$")
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$")
HOST_RE = re.compile(r"^[a-z0-9.-]{1,253}$")
MAX_BODY = 2 * 1024 * 1024

A = None                 # parsed CLI args
proc = None              # running `install.sh configure`
last_args = None         # for /api/retry
lock = threading.Lock()


def manifest() -> dict:
    out = {}
    for line in open(os.path.join(A.bundle, "MANIFEST"), encoding="utf-8"):
        k, _, v = line.strip().partition("=")
        out[k] = v.strip('"')
    return out


def checks() -> dict:
    osr = dict(l.strip().split("=", 1) for l in open("/etc/os-release") if "=" in l)
    cpu = os.cpu_count() or 0
    ram = round(os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES") / 1024 ** 3)
    disk = shutil.disk_usage("/").free // 1024 ** 3
    warn = []
    if cpu < 8: warn.append(f"{cpu} vCPU — 8 recommended for parallel scans")
    if ram < 31: warn.append(f"{ram} GB RAM — 32 GB recommended for AI pentest lanes")
    if disk < 300: warn.append(f"{disk} GB free disk — 500 GB recommended for scan history")
    ok = cpu >= 4 and ram >= 15 and disk >= 60
    if not ok: warn.insert(0, "Below minimum (4 vCPU, 16 GB RAM) — installation is blocked")
    return {"os": osr.get("PRETTY_NAME", "").strip('"'), "cpu": cpu, "ram_gb": ram, "disk_free_gb": disk, "ok": ok, "warnings": warn}


def lanes_loaded() -> bool:
    return subprocess.run(["docker", "image", "inspect", "ava-internal"], capture_output=True).returncode == 0


def primary_ip() -> str:
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))  # no packet is sent; picks the outbound interface
        return s.getsockname()[0]
    except OSError:
        return "127.0.0.1"
    finally:
        s.close()


def steps_now() -> list:
    path = os.path.join(STATE, "steps")
    if proc is None and not os.path.exists(os.path.join(STATE, "result.json")):
        return [{"key": k, "label": l, "status": "pending"} for k, l in CONFIGURE_STEPS]
    rows = []
    for line in open(path, encoding="utf-8") if os.path.exists(path) else []:
        k, l, s = (line.rstrip("\n").split("|") + ["", "", ""])[:3]
        rows.append({"key": k, "label": l, "status": s or "pending"})
    return rows or [{"key": k, "label": l, "status": "pending"} for k, l in CONFIGURE_STEPS]


def phase() -> str:
    if os.path.exists(os.path.join(STATE, "result.json")):
        return "done"
    if proc is not None and proc.poll() is None:
        return "installing"
    if proc is not None:
        return "failed"
    return "ready"


def state() -> dict:
    ph = phase()
    err = None
    if ph == "failed":
        p = os.path.join(STATE, "error")
        err = open(p, encoding="utf-8").read().strip() if os.path.exists(p) else "Installation failed — see details"
    result = json.load(open(os.path.join(STATE, "result.json"))) if ph == "done" else None
    return {"phase": ph, "version": manifest().get("caiva_version"), "checks": checks(),
            "suggested_host": primary_ip(), "lanes_included": lanes_loaded(),
            "steps": steps_now(), "error": err, "result": result}


def start_configure(args: list) -> None:
    global proc, last_args
    for f in ("result.json", "error"):
        try: os.remove(os.path.join(STATE, f))
        except FileNotFoundError: pass
    last_args = args
    proc = subprocess.Popen([os.path.join(A.bundle, "install.sh"), "configure", *args],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)


def parse_multipart(handler) -> tuple[dict, dict]:
    n = int(handler.headers.get("Content-Length") or 0)
    if n > MAX_BODY: raise ValueError("upload too large (max 2 MB)")
    body = handler.rfile.read(n)
    msg = email.parser.BytesParser(policy=email.policy.HTTP).parsebytes(
        b"Content-Type: " + handler.headers.get("Content-Type", "").encode() + b"\r\n\r\n" + body)
    fields, files = {}, {}
    for part in msg.iter_parts():
        name = part.get_param("name", header="content-disposition")
        if not name: continue
        data = part.get_payload(decode=True) or b""
        if part.get_filename(): files[name] = data
        else: fields[name] = data.decode("utf-8", "replace").strip()
    return fields, files


def build_args(f: dict, files: dict) -> list:
    org, slug = f.get("org", ""), f.get("slug", "").lower()
    host, email_ = f.get("host", "").lower(), f.get("admin_email", "").lower()
    if not org or len(org) > 120: raise ValueError("Organization name is required")
    if not SLUG_RE.match(slug): raise ValueError("Tenant ID: 2–31 lowercase letters/digits, starting with a letter")
    if not HOST_RE.match(host): raise ValueError("Host name / IP is not valid")
    if not EMAIL_RE.match(email_): raise ValueError("Administrator email is not valid")
    for k, v in f.items():
        if "'" in v or "\n" in v: raise ValueError(f"'{k}' may not contain a single quote or line break")
    args = ["--org", org, "--slug", slug, "--host", host, "--admin-email", email_]
    if f.get("cert_mode") == "upload":
        if not files.get("cert") or not files.get("key"): raise ValueError("Upload both the certificate and the private key")
        os.makedirs(UPLOAD, mode=0o700, exist_ok=True)
        for name in ("cert", "key"):
            p = os.path.join(UPLOAD, name + ".pem")
            with open(os.open(p, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600), "wb") as fh:
                fh.write(files[name])
        if b"BEGIN CERTIFICATE" not in files["cert"] or b"PRIVATE KEY" not in files["key"]:
            raise ValueError("Certificate and key must be PEM files")
        args += ["--cert", os.path.join(UPLOAD, "cert.pem"), "--key", os.path.join(UPLOAD, "key.pem")]
    for field, flag in (("openai_key", "--openai-key"), ("exploit_scope", "--exploit-scope"), ("smtp_host", "--smtp-host"),
                        ("smtp_port", "--smtp-port"), ("smtp_user", "--smtp-user"), ("smtp_password", "--smtp-password"),
                        ("smtp_from", "--smtp-from")):
        if f.get(field): args += [flag, f[field]]
    return args


def shutdown_later(server, seconds: int) -> None:
    def _stop():
        time.sleep(seconds)
        server.shutdown()
    threading.Thread(target=_stop, daemon=True).start()


class H(BaseHTTPRequestHandler):
    server_version = "CAIVA-Setup"

    def log_message(self, fmt, *args):  # keep tokens out of the journal
        pass

    def _send(self, code: int, body, ctype="application/json"):
        data = body if isinstance(body, bytes) else (json.dumps(body) if ctype == "application/json" else body).encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype + ("; charset=utf-8" if "text" in ctype or "json" in ctype else ""))
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Frame-Options", "DENY")
        self.send_header("Content-Security-Policy", "default-src 'self' 'unsafe-inline' data:; connect-src 'self'")
        self.end_headers()
        self.wfile.write(data)

    def _authed(self) -> bool:
        tok = self.headers.get("X-Setup-Token", "")
        if hmac.compare_digest(tok.encode(), A.token.encode()):
            return True
        self._send(401, {"error": "Setup link expired or invalid"})
        return False

    def do_GET(self):
        u = urlparse(self.path)
        if u.path in ("/", "/index.html"):
            # the page itself is public; it holds no data — every API call needs the token
            return self._send(200, open(os.path.join(A.bundle, "setup", "wizard.html"), "rb").read(), "text/html")
        if not self._authed(): return
        if u.path == "/api/state":
            with lock:
                return self._send(200, state())
        if u.path == "/api/log":
            n = min(int(parse_qs(u.query).get("lines", ["60"])[0] or 60), 400)
            lines = open(LOG, encoding="utf-8", errors="replace").readlines()[-n:] if os.path.exists(LOG) else []
            return self._send(200, "".join(lines), "text/plain")
        self._send(404, {"error": "not found"})

    def do_POST(self):
        u = urlparse(self.path)
        if not self._authed(): return
        with lock:
            if u.path == "/api/install":
                if phase() in ("installing", "done"):
                    return self._send(409, {"error": "Installation already " + phase()})
                if not checks()["ok"]:
                    return self._send(400, {"error": "This server is below the minimum requirements"})
                try:
                    fields, files = parse_multipart(self)
                    args = build_args(fields, files)
                except ValueError as e:
                    return self._send(400, {"error": str(e)})
                start_configure(args)
                return self._send(202, {"ok": True})
            if u.path == "/api/retry":
                if phase() != "failed" or not last_args:
                    return self._send(409, {"error": "Nothing to retry"})
                start_configure(last_args)
                return self._send(202, {"ok": True})
        self._send(404, {"error": "not found"})


def watch_for_done(server) -> None:
    # After success: keep the page up 15 min so the admin can copy the credentials, then close.
    while not os.path.exists(os.path.join(STATE, "result.json")):
        time.sleep(3)
    shutdown_later(server, 15 * 60)


def main() -> None:
    global A
    ap = argparse.ArgumentParser()
    ap.add_argument("--bundle", required=True)
    ap.add_argument("--port", type=int, default=8443)
    ap.add_argument("--token", required=True)
    A = ap.parse_args()
    os.makedirs(STATE, mode=0o700, exist_ok=True)
    cert, key = os.path.join(STATE, "setup-cert.pem"), os.path.join(STATE, "setup-key.pem")
    if not os.path.exists(cert):
        subprocess.run(["openssl", "req", "-x509", "-nodes", "-newkey", "rsa:2048", "-days", "7", "-subj", "/CN=CAIVA Setup",
                        "-keyout", key, "-out", cert], check=True, capture_output=True)
        os.chmod(key, 0o600)
    server = ThreadingHTTPServer(("0.0.0.0", A.port), H)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.minimum_version = ssl.TLSVersion.TLSv1_2
    ctx.load_cert_chain(cert, key)
    server.socket = ctx.wrap_socket(server.socket, server_side=True)
    threading.Thread(target=watch_for_done, args=(server,), daemon=True).start()
    server.serve_forever()
    for p in (cert, key, os.path.join(STATE, "result.json")):  # credentials leave with the wizard
        try: os.remove(p)
        except FileNotFoundError: pass
    shutil.rmtree(UPLOAD, ignore_errors=True)


if __name__ == "__main__":
    main()
