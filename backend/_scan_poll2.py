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

ACTIVE = {"running", "pending", "paused", "stopping", "resuming"}


def status_of():
    for attempt in range(2):
        try:
            scans = adapter.get_scans()
            s = next((x for x in scans if str(x.get("id")) == "5"), None)
            return s.get("status") if s else "notfound"
        except Exception as e:
            if "401" in str(e) and attempt == 0:   # token expired -> force re-login
                adapter._token = None
                adapter.session.headers.pop("X-Cookie", None)
                continue
            return f"err:{str(e)[:30]}"


for i in range(60):  # up to ~2h
    st = status_of()
    print(f"[poll {i}] scan status = {st}", flush=True)
    if st in ACTIVE or str(st).startswith("err"):
        time.sleep(120)
        continue
    # terminal (completed/canceled/aborted/imported/empty)
    try:
        detail = adapter.get_scan_detail("5")
        hosts = detail.get("hosts") or []
        tot = {k: sum(int(h.get(k, 0) or 0) for h in hosts) for k in ["critical", "high", "medium", "low", "info"]}
    except Exception as e:
        tot = f"err {e}"
    print(f"SCAN DONE -> status={st} severity={tot}", flush=True)
    break
else:
    print("STILL RUNNING after ~2h — re-check needed", flush=True)
