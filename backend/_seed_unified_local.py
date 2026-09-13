"""Seed the LOCKED unified library (3,419 controls, 426 sets + 1,906 standalone)
into the LOCAL grc_complyverse DB as a new, reversible NormalizationRun.

Safe: creates a NEW run (is_baseline=True so the product shows it); the existing
baseline (run 25) is untouched and restored by deleting this run. Idempotent:
re-running deletes any prior run with the same label first.
"""
import os, json, re
from datetime import datetime
from dotenv import load_dotenv; load_dotenv(".env")
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from grc.models import (NormalizationRun, CommonControlGroup, NormalizedControl,
                        NormalizedControlLink, CommonControlGroupMapping,
                        ParsedFrameworkControl, UploadedFramework)

LABEL = "Unified Library (locked, 3419 controls)"
TENANT = 1
def nk(s): return re.sub(r"\s+", " ", re.sub(r"[^a-z0-9 ]", " ", (s or "").lower())).strip()
def fsf(f): return (f or "").split("(")[0].strip()

base = os.environ["POSTGRES_ADMIN_URL"].rsplit("/", 1)[0]
db = sessionmaker(bind=create_engine(base + "/grc_complyverse"))()
D = json.load(open("grc/seed_data/stage4_all_domains.json", encoding="utf-8"))["domains"]

# ---- parsed-control lookup (framework_short, control_id, nk(title)) -> id ----
pc = {}
fw_ids = {}
for pid, fname, cid, title, fwid in db.execute(text(
        "select p.id, f.name, p.control_id, p.title, f.id "
        "from grc_parsed_framework_controls p join grc_uploaded_frameworks f "
        "on p.uploaded_framework_id=f.id")):
    pc[(fsf(fname), str(cid), nk(title))] = pid
    fw_ids[fsf(fname)] = fwid

# ---- idempotent: drop any prior run with this label ----
prior = db.query(NormalizationRun).filter(NormalizationRun.tenant_id == TENANT,
                                          NormalizationRun.label == LABEL).all()
for r in prior:
    db.execute(text("delete from grc_common_control_group_mappings where group_id in "
                    "(select id from grc_common_control_groups where run_id=:r)"), {"r": r.id})
    db.execute(text("delete from grc_common_control_groups where run_id=:r"), {"r": r.id})
    db.execute(text("delete from grc_normalized_control_links where normalized_control_id in "
                    "(select id from grc_normalized_controls where run_id=:r)"), {"r": r.id})
    db.execute(text("delete from grc_normalized_controls where run_id=:r"), {"r": r.id})
    db.execute(text("delete from grc_normalization_runs where id=:r"), {"r": r.id})
db.commit()
if prior:
    print("removed %d prior run(s) with same label" % len(prior))

now = datetime.utcnow()
run = NormalizationRun(tenant_id=TENANT, label=LABEL, scope="full",
                       framework_ids=sorted(set(fw_ids.values())), status="completed",
                       is_baseline=True, created_by=1, started_at=now, completed_at=now,
                       summary={"controls": 3419, "sets": 426, "standalone": 1906, "source": "stage4_all_domains locked"})
db.add(run); db.flush()
print("created run id", run.id)

seq = 0; nc_total = 0; link_total = 0; map_total = 0; miss = 0
for di, dm in enumerate(D):
    grp = CommonControlGroup(tenant_id=TENANT, run_id=run.id, code="ULV2-D%02d" % di,
                             name=dm["domain"], description=dm["domain"], category="control-type",
                             domain=dm["domain"], keywords=[], created_by=1)
    db.add(grp); db.flush()
    for s in dm["sets"]:
        seq += 1
        ev = [e["name"] for e in s.get("normalized_evidence", [])]
        nc = NormalizedControl(code="ULV2-%05d" % seq, name=s["normalized_title"],
                               statement=s["normalized_title"], domain=dm["domain"],
                               source="ai_normalized", common_group_id=grp.id,
                               recommended_evidence=ev, run_id=run.id,
                               review_status="approved", created_at=now)
        db.add(nc); db.flush(); nc_total += 1
        for m in s["members"]:
            pid = pc.get((fsf(m["framework"]), str(m["control_id"]), nk(m["original_title"])))
            if pid is None:
                miss += 1; continue
            db.add(NormalizedControlLink(normalized_control_id=nc.id, parsed_control_id=pid,
                                         mapping_type="member")); link_total += 1
        db.add(CommonControlGroupMapping(group_id=grp.id, normalized_control_id=nc.id,
                                         mapping_source=("standalone" if s["member_count"] == 1 else "unified"),
                                         mapping_confidence=1.0)); map_total += 1

db.commit()
print("groups=20 | normalized_controls=%d | links=%d | group_mappings=%d | unmatched_members=%d"
      % (nc_total, link_total, map_total, miss))

# ---- verify via the product's own selection + render path ----
from grc.modules.control_library.services.scoped_session import get_baseline_run
b = get_baseline_run(db, TENANT)
shown_nc = db.query(NormalizedControl).filter(NormalizedControl.run_id == b.id).count()
print("ACTIVE baseline now: run %d '%s' | normalized_controls it renders=%d" % (b.id, b.label, shown_nc))
assert b.id == run.id, "new run is not the active baseline!"
assert nc_total == 2332 and miss == 0, "count/match mismatch"
# spot-check one set's members render
sample = db.query(NormalizedControl).filter(NormalizedControl.run_id == run.id,
         NormalizedControl.name.like("Conduct a security risk assessment%")).first()
if sample:
    mem = db.query(NormalizedControlLink).filter(NormalizedControlLink.normalized_control_id == sample.id).count()
    print("spot-check '%s' -> %d members" % (sample.name[:48], mem))
print("SEED OK (local, reversible: delete run %d to restore prior baseline)" % run.id)
db.close()
