#!python
# -*- coding: utf-8 -*-
"""READ-ONLY dry-run of the room-scan connection fix.

Executes NOTHING. For every IP-group (room) in the tenant it replays the
connection-resolution logic of `_do_scan_all` both ways:

  OLD: every chair's plugins forced through the HOST's single connection;
       a chair whose runner_type != host connection type is SKIPPED.
  NEW: each chair's plugins resolved to the chair's OWN connection (or any
       in-room connection of the matching protocol); skipped only if none.

It prints, per chair, how many plugin runs the OLD path would have produced
vs the NEW path — so you can see the database chairs go from 0 → N without
firing a single real check.
"""
from __future__ import annotations
import os, sys
from collections import defaultdict
from dotenv import load_dotenv
HERE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(HERE, ".env"))
sys.path.insert(0, HERE)

from grc.db import open_tenant_session
from grc.models import ITAsset, Tenant, CompliancePlugin, IntegrationConnection
from grc.modules.compliance_plugins.services.strict_matcher import pick_benchmark_for_os
from grc.modules.compliance_plugins.services.software_normaliser import benchmark_for_software_key

SLUG = os.environ.get("VERIFY_SLUG", "complyverse")


def resolve_benchmark(db, tid, os_norm):
    if not os_norm:
        return None
    m = pick_benchmark_for_os(db, tid, os_norm)
    if m:
        return m.benchmark_name
    return benchmark_for_software_key(db, os_norm)


def main():
    db = open_tenant_session(SLUG)
    try:
        trow = db.query(Tenant).filter(Tenant.slug == SLUG).first()
        if not trow:
            print(f"No tenant with slug={SLUG!r}. Set VERIFY_SLUG.")
            return
        tid = trow.id

        # Active connections, indexed by console_url and by integration_type.
        conns = db.query(IntegrationConnection).filter(
            IntegrationConnection.tenant_id == tid,
            IntegrationConnection.is_active.is_(True),
        ).all()
        conn_by_console = {}
        conn_by_type = {}
        for c in conns:
            cu = (c.console_url or "").lower().strip()
            if cu and cu not in conn_by_console:
                conn_by_console[cu] = c
            if c.integration_type and c.integration_type not in conn_by_type:
                conn_by_type[c.integration_type] = c
        print(f"=== Tenant {SLUG} (id={tid}) — {len(conns)} active connections ===")
        for c in conns:
            print(f"  conn id={c.id:<4} type={c.integration_type:<14} console_url={c.console_url!r}")

        # Plugin counts per (benchmark) and the runner_type(s) each benchmark uses.
        plugins = db.query(CompliancePlugin).filter(
            (CompliancePlugin.tenant_id.is_(None)) | (CompliancePlugin.tenant_id == tid),
            CompliancePlugin.enabled.is_(True),
            CompliancePlugin.review_status.in_(["approved", "auto_approved"]),
        ).all()
        plugins_by_bench = defaultdict(list)
        for p in plugins:
            plugins_by_bench[p.benchmark].append(p)

        # Group assets by IP.
        assets = db.query(ITAsset).filter(ITAsset.tenant_id == tid).all()
        by_ip = defaultdict(list)
        for a in assets:
            if a.ip_address:
                by_ip[a.ip_address].append(a)

        rooms = {ip: grp for ip, grp in by_ip.items() if len(grp) > 1}
        if not rooms:
            print("\nNo multi-asset IP groups (rooms) found in this tenant.")
            print("All assets / their IPs:")
            for a in assets:
                print(f"  id={a.id:<4} {a.name!r:<34} ip={a.ip_address!r:<16} "
                      f"os={a.os_normalized!r:<22} host_name={a.host_name!r}")
            return

        for ip, grp in rooms.items():
            print(f"\n{'='*78}\n=== ROOM ip={ip}  ({len(grp)} assets) ===")
            # Pick the host = an asset whose host_name matches a connection.
            host = next(
                (a for a in grp
                 if (a.host_name or "").lower().strip() in conn_by_console),
                None,
            )
            host_conn = conn_by_console.get((host.host_name or "").lower().strip()) if host else None
            print(f"  host = {host.name if host else '(none with a connection)'}"
                  f"   host_conn_type = {host_conn.integration_type if host_conn else None}")

            for a in grp:
                bench = resolve_benchmark(db, tid, a.os_normalized)
                bplugins = plugins_by_bench.get(bench, []) if bench else []
                if not bench or not bplugins:
                    print(f"  - {a.name!r:<34} os={a.os_normalized!r:<20} "
                          f"-> no benchmark/plugins (nothing to scan)")
                    continue
                # runner types this chair's plugins need
                rtypes = sorted({p.runner_type for p in bplugins if p.runner_type})
                own_conn = conn_by_console.get((a.host_name or "").lower().strip())

                # OLD: forced through host connection.
                old_ok = 0
                for p in bplugins:
                    c = host_conn
                    if c and p.runner_type and c.integration_type != p.runner_type:
                        continue  # skipped (the bug)
                    if c is None and p.runner_type:
                        continue
                    old_ok += 1

                # NEW: chair's own connection, else in-room by runner_type.
                new_ok = 0
                for p in bplugins:
                    c = own_conn
                    if c is None or (p.runner_type and c.integration_type != p.runner_type):
                        c = conn_by_type.get(p.runner_type) if p.runner_type else (c or host_conn)
                    if p.runner_type and (c is None or c.integration_type != p.runner_type):
                        continue  # genuinely no usable connection
                    new_ok += 1

                flag = "  <-- FIXED" if new_ok > old_ok else ""
                print(f"  - {a.name!r:<34} bench={bench!r}")
                print(f"      rules={len(bplugins):<4} runner_types={rtypes} "
                      f"own_conn={own_conn.integration_type if own_conn else None}")
                print(f"      OLD would run {old_ok:<4} NEW would run {new_ok:<4}{flag}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
