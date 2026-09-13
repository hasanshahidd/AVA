#!python
# -*- coding: utf-8 -*-
"""REAL end-to-end proof of the room-scan fix, anchored on the Windows room.

Scenario (exactly what the UI does): open the Windows asset (the room) and
tick the PostgreSQL chair, then press Scan now. The chair's CIS rules use
linux_ssh — a DIFFERENT protocol than the room's windows_winrm — which is
the case the old code silently dropped.

This actually calls `_do_scan_all`, so real (read-only) checks are attempted.
There is no live SSH/Oracle target here, so the runs come back status=error
("connection refused") — but that is exactly the point: the chair now gets
RUN ROWS attributed to it (proving it is no longer skipped). Before the fix
the chair got ZERO rows.
"""
from __future__ import annotations
import os, sys, importlib
from dotenv import load_dotenv
HERE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(HERE, ".env"))
sys.path.insert(0, HERE)

from sqlalchemy import text
from grc.db import open_tenant_session
from grc.models import ITAsset, Tenant, CompliancePluginRun, GRCUser
cp_router = importlib.import_module("grc.modules.compliance_plugins.router")

SLUG = os.environ.get("VERIFY_SLUG", "complyverse")
CHAIR_NAME = "VERIFY PostgreSQL 16 (chair)"


def runs_for(db, aid):
    return db.query(CompliancePluginRun).filter(
        CompliancePluginRun.asset_id == aid,
        CompliancePluginRun.triggered_by == "scan_all",
    ).count()


def main():
    db = open_tenant_session(SLUG)
    try:
        tid = db.query(Tenant).filter(Tenant.slug == SLUG).first().id
        room = db.query(ITAsset).filter(
            ITAsset.tenant_id == tid, ITAsset.os_normalized.like("windows%"),
        ).order_by(ITAsset.id).first()
        chair = db.query(ITAsset).filter(
            ITAsset.tenant_id == tid, ITAsset.name == CHAIR_NAME,
        ).first()
        user = db.query(GRCUser).first()
        if not (room and chair and user):
            print(f"Missing room/chair/user: room={room and room.name} chair={chair and chair.name} user={bool(user)}")
            return

        print(f"Room  = {room.name!r} (id={room.id}, {room.os_normalized})")
        print(f"Chair = {chair.name!r} (id={chair.id}, {chair.os_normalized})")
        base_room = runs_for(db, room.id)
        base_chair = runs_for(db, chair.id)
        print(f"\nBaseline scan_all runs:  room={base_room}  chair={base_chair}")

        print(f"\n=== _do_scan_all(asset_id=room({room.id}), include_peer_asset_ids=[chair({chair.id})]) ===")
        cp_router._do_scan_all(
            db, tid, room.id, user,
            benchmark=None, runner_type=None, connection_id=None,
            include_peer_asset_ids=[chair.id],
        )
        print("  scan returned")

        new_room = runs_for(db, room.id)
        new_chair = runs_for(db, chair.id)
        print(f"\nAfter scan:  room={new_room} (+{new_room-base_room})  "
              f"chair={new_chair} (+{new_chair-base_chair})")

        # Per-asset breakdown by benchmark + status for the chair.
        print("\n=== Chair runs by benchmark/status (this proves attribution) ===")
        rows = db.execute(text("""
            SELECT p.benchmark, r.status, count(*)
            FROM grc_compliance_plugin_runs r
            JOIN grc_compliance_plugins p ON p.id = r.plugin_id
            WHERE r.asset_id = :aid AND r.triggered_by = 'scan_all'
            GROUP BY p.benchmark, r.status ORDER BY 3 DESC
        """), {"aid": chair.id}).fetchall()
        for b, s, c in rows:
            print(f"  {b:<42} {s:<10} {c}")

        delta_chair = new_chair - base_chair
        print()
        if delta_chair > 0:
            print(f"=== PASS: the chair received {delta_chair} run rows attributed to asset_id={chair.id}. ===")
            print("    Before the fix this was 0 (linux_ssh plugins skipped under the")
            print("    room's windows_winrm connection). Status=error is expected here —")
            print("    there is no live SSH target — but the chair is now SCANNED, not dropped.")
        else:
            print("=== FAIL: chair got 0 new runs — fix not effective in this path. ===")
    finally:
        db.close()


if __name__ == "__main__":
    main()
