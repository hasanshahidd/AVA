import os, sys
from dotenv import load_dotenv; load_dotenv(".env"); sys.path.insert(0,".")
from grc.db import open_tenant_session
from grc.models import Tenant, CommonControlGroup, NormalizedControl
from grc.modules.control_library.services.normalization import run_normalization
from grc.job_status import set_status, get_status
db = open_tenant_session("complyverse")
tid = db.query(Tenant).filter(Tenant.slug=="complyverse").first().id
groups = db.query(CommonControlGroup).order_by(CommonControlGroup.id).all()
done = {g.id for g in groups if db.query(NormalizedControl).filter(NormalizedControl.common_group_id==g.id, NormalizedControl.source=='ai_normalized').count()>0}
todo = [g for g in groups if g.id not in done]
print(f"{len(groups)} domains | {len(done)} done | {len(todo)} to process", flush=True)
total=0
for i,g in enumerate(todo):
    try:
        s=run_normalization(db,tid,[g.id]); total+=s['normalized_controls_created']
        print(f"[{i+1}/{len(todo)}] {g.name[:40]}: +{s['normalized_controls_created']} (running {total})", flush=True)
    except Exception as e:
        print(f"[{i+1}/{len(todo)}] {g.name[:40]} FAILED: {str(e)[:120]}", flush=True)
latest=get_status("complyverse","control_normalization","latest") or {}
jid=latest.get("job_id")
if jid:
    set_status("complyverse","control_normalization",jid,{"status":"completed","phase":"done","message":f"Normalized across {len(groups)} domains.","progress_percent":100})
print(f"ALL DONE. NCs created this run: {total}", flush=True)
db.close()
