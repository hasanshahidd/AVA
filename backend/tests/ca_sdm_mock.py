"""Strict mock of CA Service Desk Manager REST Web Services (/caisd-rest), for
end-to-end proof of the Broadcom Service Desk + Broadcom CMDB connectors.

Mirrors the documented wire contract (see connectors/providers/_ca_sdm.py) and
is deliberately strict where the real server is: no X-AccessKey → 401; an
unknown attribute in X-Obj-Attrs → 400; an incident without `customer` → 400;
updates only via PUT; SRELs only as {"@COMMON_NAME"}/{"@id"}/{"@REL_ATTR"};
collections wrapped as collection_<obj> with @COUNT/@START/@TOTAL_COUNT and
paged by start/size. Keys expire on demand (expire_keys()) to prove re-login.

Run standalone (for a live demo):  python tests/ca_sdm_mock.py 8050
Login: servicedesk / Demo-Pass-1 (mock only).
"""
from __future__ import annotations

import base64
import json
import re
import sys
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any, Dict, List, Optional
from urllib.parse import parse_qs, unquote, urlparse

USER, PASSWORD = "servicedesk", "Demo-Pass-1"

ATTRS = {
    "in": {"ref_num", "summary", "description", "priority", "customer", "status", "group", "category"},
    "cnt": {"userid", "last_name", "first_name"},
    "nr": {"name", "system_name", "dns_name", "alarm_id", "mac_address", "serial_number", "manufacturer",
           "model", "location", "class", "family", "status", "delete_flag", "is_ci"},
    "alg": {"call_req_id", "type", "description"},
}
SREL = {"priority", "customer", "status", "group", "category", "manufacturer", "model", "location",
        "class", "family", "call_req_id", "type"}


class State:
    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.keys: set = set()
        self.next_key = 1534147117
        self.next_id = 400001
        self.next_ref = 1001
        self.objs: Dict[str, List[Dict[str, Any]]] = {"in": [], "cnt": [], "nr": [], "alg": []}
        self.logins = 0
        self.max_size = 500                 # server-side cap on `size`, like CA SDM
        self.requests: List[str] = []
        self.add("cnt", {"userid": USER, "last_name": "Desk", "first_name": "Service"}, cn="Desk, Service")

    def add(self, obj: str, rec: Dict[str, Any], cn: Optional[str] = None) -> Dict[str, Any]:
        rid = str(self.next_id)
        self.next_id += 1
        row = {"@id": rid, "@REL_ATTR": rid, "@COMMON_NAME": cn or rec.get("name") or rid, **rec}
        self.objs[obj].append(row)
        return row

    def expire_keys(self) -> None:
        self.keys.clear()


def _ref(v: Any) -> Dict[str, Any]:
    """Echo an SREL the way CA SDM serialises it on read."""
    return v if isinstance(v, dict) else {"@COMMON_NAME": str(v)}


_CLAUSE = re.compile(r"^\s*(\w+)\s*=\s*('(?:[^']|'')*'|\d+)\s*$")


def _where(rows: List[Dict[str, Any]], wc: Optional[str]) -> List[Dict[str, Any]]:
    """Supports `a='x' OR a='y'` and `a=0 AND b=1` (the forms the adapters use)."""
    if not wc:
        return rows
    def match(row, clause):
        m = _CLAUSE.match(clause)
        if not m:
            raise ValueError(f"unsupported WC clause: {clause}")
        k, v = m.group(1), m.group(2)
        v = v[1:-1].replace("''", "'") if v.startswith("'") else v
        cur = row.get(k)
        cur = cur.get("@COMMON_NAME") if isinstance(cur, dict) else cur
        return str(cur if cur is not None else "") == v
    if " OR " in wc:
        parts = wc.split(" OR ")
        return [r for r in rows if any(match(r, p) for p in parts)]
    parts = wc.split(" AND ")
    return [r for r in rows if all(match(r, p) for p in parts)]


def make_handler(state: State):
    class H(BaseHTTPRequestHandler):
        def log_message(self, *a):  # quiet
            pass

        def _send(self, code: int, body: Any = None) -> None:
            data = json.dumps(body).encode() if body is not None else b""
            self.send_response(code)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)

        def _body(self) -> Dict[str, Any]:
            return self._payload

        def _drain(self) -> None:
            # Read the whole request body before any reply: answering early (e.g. 401)
            # with unread bytes makes Windows reset the connection (WinError 10053).
            n = int(self.headers.get("Content-Length") or 0)
            raw = self.rfile.read(n) if n else b""
            try:
                self._payload = json.loads(raw or b"{}")
            except ValueError:
                self._payload = {}

        def _route(self):
            u = urlparse(self.path)
            parts = [p for p in u.path.split("/") if p]
            if not parts or parts[0] != "caisd-rest":
                return None, None, {}
            return parts[1] if len(parts) > 1 else None, (unquote(parts[2]) if len(parts) > 2 else None), parse_qs(u.query)

        def _authed(self) -> bool:
            if self.headers.get("X-AccessKey") not in state.keys:
                self._send(401, {"error": "invalid or expired access key"})
                return False
            return True

        def _attrs(self, obj: str) -> Optional[List[str]]:
            raw = self.headers.get("X-Obj-Attrs")
            if not raw:
                return []
            want = [a.strip() for a in raw.split(",") if a.strip()]
            bad = [a for a in want if a not in ATTRS[obj]]
            if bad:
                self._send(400, {"error": f"AHD04205: unknown attribute(s) {bad} for {obj}"})
                return None
            return want

        @staticmethod
        def _view(row: Dict[str, Any], attrs: List[str]) -> Dict[str, Any]:
            out = {k: row[k] for k in ("@id", "@REL_ATTR", "@COMMON_NAME")}
            for a in attrs:
                v = row.get(a)
                out[a] = _ref(v) if (a in SREL and v is not None) else v
            return out

        def _find(self, obj: str, key: str) -> Optional[Dict[str, Any]]:
            rows = state.objs[obj]
            if key.startswith("COMMON_NAME-"):
                cn = key[len("COMMON_NAME-"):]
                return next((r for r in rows if r["@COMMON_NAME"] == cn), None)
            return next((r for r in rows if r["@id"] == key), None)

        def do_POST(self):  # noqa: N802
            self._drain()
            obj, key, _q = self._route()
            state.requests.append(f"POST {obj}")
            if obj == "rest_access":
                auth = self.headers.get("Authorization", "")
                ok = auth.startswith("Basic ") and base64.b64decode(auth[6:]).decode() == f"{USER}:{PASSWORD}"
                if not ok:
                    return self._send(401, {"error": "AHD03053: bad userid or password"})
                with state.lock:
                    k = state.next_key
                    state.next_key += 1
                    state.keys.add(str(k))
                    state.logins += 1
                return self._send(201, {"rest_access": {"@id": k, "access_key": k, "expiration_date": 1999999999}})
            if obj not in ATTRS or key:
                return self._send(405 if key else 404, {"error": "use PUT to update"} if key else {"error": "no such object"})
            if not self._authed():
                return
            attrs = self._attrs(obj)
            if attrs is None:
                return
            rec = self._body().get(obj)
            if not isinstance(rec, dict):
                return self._send(400, {"error": f"body must be {{\"{obj}\": {{...}}}}"})
            unknown = [k for k in rec if k not in ATTRS[obj]]
            bad_srel = [k for k in rec if k in SREL and not (isinstance(rec[k], dict) and
                        set(rec[k]) & {"@COMMON_NAME", "@id", "@REL_ATTR"})]
            if unknown or bad_srel:
                return self._send(400, {"error": f"AHD03053: bad attributes {unknown or bad_srel}"})
            with state.lock:
                if obj == "in":
                    if "customer" not in rec:
                        return self._send(400, {"error": "AHD03053: Missing required field: Affected End User"})
                    ref = str(state.next_ref)
                    state.next_ref += 1
                    rec = {"status": {"@COMMON_NAME": "Open"}, **rec, "ref_num": ref}
                    row = state.add("in", rec, cn=ref)
                elif obj == "nr":
                    if "name" not in rec or "class" not in rec:
                        return self._send(400, {"error": "AHD03053: Missing required field: name/class"})
                    row = state.add("nr", {"delete_flag": 0, "is_ci": 1, **rec})
                else:
                    row = state.add(obj, rec)
            return self._send(201, {obj: self._view(row, attrs)})

        def do_PUT(self):  # noqa: N802
            self._drain()
            obj, key, _q = self._route()
            state.requests.append(f"PUT {obj}/{key}")
            if not self._authed():
                return
            row = self._find(obj, key or "")
            if row is None:
                return self._send(404, {"error": "not found"})
            rec = self._body().get(obj) or {}
            if any(k not in ATTRS[obj] for k in rec):
                return self._send(400, {"error": "AHD03053: bad attributes"})
            with state.lock:
                row.update(rec)
            return self._send(200, {obj: self._view(row, [])})

        def do_GET(self):  # noqa: N802
            self._drain()
            obj, key, q = self._route()
            state.requests.append(f"GET {obj}")
            if obj not in ATTRS:
                return self._send(404, {"error": "no such object"})
            if not self._authed():
                return
            attrs = self._attrs(obj)
            if attrs is None:
                return
            if key:
                row = self._find(obj, key)
                return self._send(200, {obj: self._view(row, attrs)}) if row else self._send(404, {"error": "not found"})
            try:
                rows = _where(state.objs[obj], (q.get("WC") or [None])[0])
            except ValueError as exc:
                return self._send(400, {"error": str(exc)})
            start = int((q.get("start") or ["1"])[0])
            size = min(int((q.get("size") or ["25"])[0]), state.max_size)
            page = rows[start - 1:start - 1 + size]
            items = [self._view(r, attrs) for r in page]
            return self._send(200, {f"collection_{obj}": {
                "@COUNT": len(items), "@START": start, "@TOTAL_COUNT": len(rows),
                obj: items[0] if len(items) == 1 else items}})

    return H


def serve(port: int = 0):
    """Start in a background thread → (server, state, base_url)."""
    state = State()
    srv = ThreadingHTTPServer(("127.0.0.1", port), make_handler(state))
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv, state, f"http://127.0.0.1:{srv.server_address[1]}"


if __name__ == "__main__":
    # python tests/ca_sdm_mock.py [port] [ci_seed.json]  — seed: list of nr attribute dicts
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8050
    srv, state, url = serve(port)
    if len(sys.argv) > 2:
        for rec in json.load(open(sys.argv[2], encoding="utf-8")):
            state.add("nr", {"delete_flag": 0, "is_ci": 1, **rec})
    print(f"CA SDM mock on {url}/caisd-rest  (login {USER})")
    threading.Event().wait()
