#!python
# -*- coding: utf-8 -*-
"""Seed a verification room: Windows host (room) + PostgreSQL chair.

Idempotent. Creates, in tenant `complyverse`:
  - an ITAsset "VERIFY PostgreSQL 16 (chair)" co-located (same ip_address) with
    the existing Windows asset, os_normalized=postgresql-16 so it resolves the
    CIS PostgreSQL 16 benchmark (runner_type=linux_ssh — deliberately a
    DIFFERENT protocol than the room's windows_winrm);
  - its OWN linux_ssh connection whose console_url matches the chair host_name.

Run with `--remove` to delete the seeded rows again.
"""
from __future__ import annotations
import os, sys
from dotenv import load_dotenv
HERE = os.path.dirname(os.path.abspath(__file__))
load_dotenv(os.path.join(HERE, ".env"))
sys.path.insert(0, HERE)

from grc.db import open_tenant_session
from grc.models import ITAsset, Tenant, IntegrationConnection

SLUG = os.environ.get("VERIFY_SLUG", "complyverse")
CHAIR_NAME = "VERIFY PostgreSQL 16 (chair)"
CHAIR_HOST = "pg-chair-host"
CONN_NAME = "VERIFY PG chair SSH"


def main(remove: bool):
    db = open_tenant_session(SLUG)
    try:
        tid = db.query(Tenant).filter(Tenant.slug == SLUG).first().id
        room_host = db.query(ITAsset).filter(
            ITAsset.tenant_id == tid, ITAsset.ip_address.isnot(None),
        ).order_by(ITAsset.id).first()
        if not room_host:
            print("No asset with an IP to use as the room. Abort.")
            return
        ip = room_host.ip_address
        print(f"Room host = {room_host.name!r} (id={room_host.id}) ip={ip}")

        chair = db.query(ITAsset).filter(
            ITAsset.tenant_id == tid, ITAsset.name == CHAIR_NAME,
        ).first()
        conn = db.query(IntegrationConnection).filter(
            IntegrationConnection.tenant_id == tid,
            IntegrationConnection.connection_name == CONN_NAME,
        ).first()

        if remove:
            from grc.models import CompliancePluginRun
            if chair:
                n = db.query(CompliancePluginRun).filter(
                    CompliancePluginRun.asset_id == chair.id).delete()
                print(f"  deleted {n} plugin runs for the chair")
                db.delete(chair)
            if conn:
                db.delete(conn)
            db.commit()
            print("Removed seeded chair + connection (+ its runs).")
            return

        if not chair:
            chair = ITAsset(
                tenant_id=tid,
                name=CHAIR_NAME,
                asset_type="data",
                os_family="linux",
                os_normalized="postgresql-16",
                os_version="PostgreSQL 16",
                ip_address=ip,             # same IP → same room as the Windows host
                host_name=CHAIR_HOST,      # matches the connection console_url below
                criticality="high",
                status="active",
            )
            db.add(chair)
            db.flush()
            print(f"  created chair asset id={chair.id}")
        else:
            print(f"  chair asset already exists id={chair.id}")

        if not conn:
            conn = IntegrationConnection(
                tenant_id=tid,
                integration_type="linux_ssh",   # the protocol the PG benchmark needs
                category="compliance",
                connection_name=CONN_NAME,
                console_url=CHAIR_HOST,          # matches chair.host_name
                console_port=22,
                auth_method="basic",
                username="verify",
                is_active=True,
                status="connected",
                credentials_extra_json={
                    "ssh_host": "127.0.0.1", "ssh_port": 22,
                    "ssh_username": "verify",
                },
            )
            db.add(conn)
            db.flush()
            print(f"  created connection id={conn.id} (linux_ssh, console_url={CHAIR_HOST})")
        else:
            print(f"  connection already exists id={conn.id}")

        db.commit()
        print("\nSeed complete. Room now has:")
        for a in db.query(ITAsset).filter(ITAsset.tenant_id == tid,
                                          ITAsset.ip_address == ip).all():
            print(f"  - id={a.id:<4} {a.name!r:<34} os={a.os_normalized!r:<16} "
                  f"host_name={a.host_name!r}")
    finally:
        db.close()


if __name__ == "__main__":
    main(remove="--remove" in sys.argv)
