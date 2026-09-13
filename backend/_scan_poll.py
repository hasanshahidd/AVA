import time, warnings, urllib3
warnings.filterwarnings("ignore"); urllib3.disable_warnings()
from grc.models import GRCUser, IntegrationConnection
from grc.models._38_database_initialization_functions import open_tenant_session
from grc.routers.auth_router import get_user_tenants
from grc.modules.integrations.services.sync_service import SyncService

db = open_tenant_session("complyverse")
u = db.query(GRCUser).filter(GRCUser.username == "admin").first() or db.query(GRCUser).first()
tids = get_user_tenants(u, db)
conn = db.query(IntegrationConnection).filter(
    IntegrationConnection.tenant_id.in_(tids),
    IntegrationConnection.integration_type == "nessus").first()
adapter = SyncService.build_adapter(conn)
db.close()

for i in range(24):  # ~48 min max
    try:
        scans = adapter.get_scans()
        s = next((x for x in scans if str(x.get("id")) == "5"), scans[0] if scans else None)
        status = s.get("status") if s else "unknown"
    except Exception as e:
        status = f"err:{str(e)[:30]}"
    print(f"[poll {i}] scan status = {status}", flush=True)
    if status not in ("running", "pending"):
        try:
            detail = adapter.get_scan_detail("5")
            hosts = detail.get("hosts") or []
            tot = {k: sum(int(h.get(k, 0) or 0) for h in hosts) for k in ["critical", "high", "medium", "low", "info"]}
        except Exception as e:
            tot = f"err {e}"
        print(f"SCAN COMPLETE -> status={status} severity={tot}", flush=True)
        break
    time.sleep(120)
else:
    print("STILL RUNNING after ~48min — re-check needed", flush=True)
