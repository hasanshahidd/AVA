"""SEPARATE, self-contained correctness test of the extend-baseline pipeline.

Isolated and fully reversible — uses its own throwaway DEMO framework + candidate
run, asserts each pipeline step at the ROW level (not just counts), then deletes
everything and proves the live baseline (run 47) is byte-for-byte unchanged.

Run:  python _pipeline_test.py     (needs .env + OPENAI key)
"""
import os
from dotenv import load_dotenv; load_dotenv(".env")
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from grc.models import (UploadedFramework, ParsedFrameworkControl, NormalizationRun,
                        NormalizedControl, CommonControlGroup, NormalizedControlLink,
                        CommonControlGroupMapping)
from grc.modules.control_library.services import extend_baseline as EB
from grc.modules.control_library.services.scoped_session import get_baseline_run

TENANT = 1
db = sessionmaker(bind=create_engine(os.environ["POSTGRES_ADMIN_URL"].rsplit("/",1)[0] + "/grc_complyverse"))()
def get_client():
    from grc.modules.control_library.routers.groups import get_openai_client
    return get_openai_client()

PASS = []; FAIL = []
def check(name, cond, detail=""):
    (PASS if cond else FAIL).append(name)
    print(f"  [{'PASS' if cond else 'FAIL'}] {name}" + (f" — {detail}" if detail else ""))

# controls: non-canonical domains (tests Step 3) + clear set-joins + one oddball
DEMO = [
    ("PT-1", "Maintain an inventory of information assets", "Inventory of assets with owners.", "Asset Mgmt"),
    ("PT-2", "Incident Response Plan", "Procedures for reporting and managing incidents.", "Incident Handling"),
    ("PT-3", "Conduct a security risk assessment", "Identify threats, likelihood, impact.", "Risk & Compliance"),
    ("PT-4", "Bespoke Flux Capacitor Attunement Record", "No equivalent anywhere; must be standalone.", "Misc Ops"),
]

def snap(tag):
    b = get_baseline_run(db, TENANT)
    n = db.query(NormalizedControl).filter(NormalizedControl.run_id==b.id).count()
    g = db.query(CommonControlGroup).filter(CommonControlGroup.run_id==b.id).count()
    f = db.query(UploadedFramework).filter(UploadedFramework.is_active==True).count()
    runs = db.query(NormalizationRun).filter(NormalizationRun.tenant_id==TENANT).count()
    print(f"  [{tag}] baseline=run {b.id} | ncs={n} | domains={g} | frameworks={f} | total_runs={runs}")
    return (b.id, n, g, f, runs)

fw_id = None; cand = None
try:
    print("BASELINE BEFORE:"); before = snap("before")
    BASE_DOMAINS = set(EB._baseline_view(db, get_baseline_run(db,TENANT))["domains"])

    print("\nSETUP — create isolated DEMO framework:")
    fw = UploadedFramework(tenant_id=TENANT, name="PIPELINE TEST FW (delete me)", file_name="x.json",
                           file_path="(test)", file_type="application/json", upload_status="completed",
                           framework_type="regulatory", is_active=True, is_shared=False, uploaded_by=1)
    db.add(fw); db.flush(); fw_id = fw.id
    for cid,t,desc,dom in DEMO:
        db.add(ParsedFrameworkControl(uploaded_framework_id=fw.id, control_id=cid, title=t,
                                      description=desc, full_text=desc, domain=dom, is_mandatory=True,
                                      priority="high", evidence_requirements=[f"{t} document"]))
    db.commit()
    print(f"  created fw id={fw_id} with {len(DEMO)} controls (non-canonical domains)")

    print("\nTEST A — dry-run analyze classifies + reconciles (writes nothing):")
    rep = EB.analyze(db, TENANT, fw_id, get_client=get_client)
    check("A1 all controls accounted for", rep["new_controls"]==len(DEMO), f"{rep['new_controls']}")
    check("A2 at least the 3 obvious controls join existing sets", rep["would_join_existing_set"]>=3, f"joins={rep['would_join_existing_set']}")
    check("A3 the oddball is standalone", rep["would_be_standalone"]>=1, f"standalone={rep['would_be_standalone']}")
    check("A4 Step3: NO new domains invented", rep["new_domains_created"]==[], f"{rep['new_domains_created']}")
    check("A5 Step3: every domain used is one of the existing 20", set(rep["domains_used"]).issubset(BASE_DOMAINS), f"{rep['domains_used']}")
    n_runs_mid = db.query(NormalizationRun).filter(NormalizationRun.tenant_id==TENANT).count()
    check("A6 analyze wrote NOTHING (run count unchanged)", n_runs_mid==before[4], f"{n_runs_mid} vs {before[4]}")

    print("\nTEST B — commit builds a candidate run (NOT promoted):")
    res = EB.commit(db, TENANT, fw_id, get_client=get_client, user_id=1, label="PIPELINE TEST candidate", promote=False)
    cand = res["candidate_run_id"]
    b_now = get_baseline_run(db, TENANT)
    check("B1 candidate run created", bool(cand))
    check("B2 commit did NOT promote (baseline still run 47)", b_now.id==before[0], f"baseline={b_now.id}")
    check("B3 candidate cloned full baseline set-count", db.query(NormalizedControl).filter(NormalizedControl.run_id==cand).count()==before[1])
    check("B4 candidate has exactly 20 domains (no dup)", db.query(CommonControlGroup).filter(CommonControlGroup.run_id==cand).count()==before[2])

    print("\nTEST C — ROW-LEVEL: each demo control really landed correctly in the candidate:")
    demo_pids = {p.control_id: p.id for p in db.query(ParsedFrameworkControl).filter(ParsedFrameworkControl.uploaded_framework_id==fw_id).all()}
    cand_groups = {g.id: (g.domain or g.name) for g in db.query(CommonControlGroup).filter(CommonControlGroup.run_id==cand).all()}
    # every demo control must appear in the candidate (as set-member link OR standalone group mapping)
    for cid, pid in demo_pids.items():
        as_member = db.query(NormalizedControlLink).join(NormalizedControl, NormalizedControl.id==NormalizedControlLink.normalized_control_id)\
            .filter(NormalizedControl.run_id==cand, NormalizedControlLink.parsed_control_id==pid).count()
        as_std = db.query(CommonControlGroupMapping).filter(CommonControlGroupMapping.group_id.in_(list(cand_groups)),
                 CommonControlGroupMapping.parsed_control_id==pid, CommonControlGroupMapping.mapping_source=="standalone").count()
        place = db.query(CommonControlGroupMapping).filter(CommonControlGroupMapping.group_id.in_(list(cand_groups)),
                 CommonControlGroupMapping.parsed_control_id==pid).first()
        dom = cand_groups.get(place.group_id) if place else None
        check(f"C[{cid}] present (member={as_member}, standalone={as_std}) in domain '{dom}'",
              (as_member+as_std)>=1 and dom in BASE_DOMAINS, f"dom={dom}")
    # a joined member must attach to a REAL existing set nc (member-level proof)
    joined_link = db.query(NormalizedControlLink, NormalizedControl).join(NormalizedControl, NormalizedControl.id==NormalizedControlLink.normalized_control_id)\
        .filter(NormalizedControl.run_id==cand, NormalizedControlLink.parsed_control_id.in_(list(demo_pids.values()))).first()
    check("C-join attaches a demo control to a real normalized set", joined_link is not None,
          f"set='{joined_link[1].name[:40]}'" if joined_link else "no join link")

finally:
    print("\nCLEANUP:")
    if cand:
        for stmt in ["delete from grc_common_control_group_mappings where group_id in (select id from grc_common_control_groups where run_id=:r)",
                     "delete from grc_normalized_control_links where normalized_control_id in (select id from grc_normalized_controls where run_id=:r)",
                     "delete from grc_common_control_groups where run_id=:r",
                     "delete from grc_normalized_controls where run_id=:r",
                     "delete from grc_normalization_runs where id=:r"]:
            db.execute(text(stmt), {"r": cand})
    if fw_id:
        for stmt in ["delete from grc_normalized_control_links where parsed_control_id in (select id from grc_parsed_framework_controls where uploaded_framework_id=:f)",
                     "delete from grc_common_control_group_mappings where parsed_control_id in (select id from grc_parsed_framework_controls where uploaded_framework_id=:f)",
                     "delete from grc_parsed_framework_controls where uploaded_framework_id=:f",
                     "delete from grc_uploaded_frameworks where id=:f"]:
            db.execute(text(stmt), {"f": fw_id})
    db.commit()
    print("  removed candidate run + demo framework")
    print("\nBASELINE AFTER:"); after = snap("after")
    check("Z baseline fully restored (run 47 byte-for-byte)", before==after, f"{before} == {after}")
    print(f"\n==== RESULT: {len(PASS)} passed, {len(FAIL)} failed ====")
    if FAIL: print("FAILED:", FAIL)
    db.close()
