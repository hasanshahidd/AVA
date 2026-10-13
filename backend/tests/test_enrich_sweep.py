"""Background enrichment sweep: scope query + best-effort loop.

Locks the two properties that keep the automatic sweep safe:
  * `unenriched_register_query` selects ONLY un-enriched register CVE rows — an
    already-enriched row, a non-CVE row, and an ad-hoc-only / unlinked row (via
    the shared `exclude_adhoc`) are all excluded.
  * a per-CVE enrich failure does NOT abort the drain (best-effort), and an
    enrich that leaves the row un-synced can't spin forever.
Offline: sqlite, `ensure_cve_enriched` spied. Mirrors test_vuln_dashboard_adhoc_filter.
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from grc.models import ITAsset, Vulnerability, VulnerabilityAssetLink
from grc.modules.pentest.service import ADHOC_STATUS, ADHOC_SOURCE
from grc.modules.vuln_management.enrichment import sweep as sweep_mod

TENANT = 1


def _db():
    eng = create_engine("sqlite://", connect_args={"check_same_thread": False}, poolclass=StaticPool)
    for m in (ITAsset, Vulnerability, VulnerabilityAssetLink):
        m.__table__.create(eng, checkfirst=True)
    db = sessionmaker(bind=eng)()
    _seed(db)
    return db


def _seed(db):
    db.add_all([
        ITAsset(id=1, tenant_id=TENANT, name="managed-01", asset_type="server", status="active"),
        ITAsset(id=2, tenant_id=TENANT, name="adhoc", asset_type="server",
                status=ADHOC_STATUS, last_seen_source=ADHOC_SOURCE),
    ])
    db.add_all([
        # KEEP: managed-linked, real CVE, never synced.
        Vulnerability(id=10, tenant_id=TENANT, vuln_id="V-10", title="t", severity="high",
                      cve_id="CVE-2024-0001", nvd_last_synced_at=None),
        # DROP: already enriched.
        Vulnerability(id=20, tenant_id=TENANT, vuln_id="V-20", title="t", severity="high",
                      cve_id="CVE-2024-0002", nvd_last_synced_at=__import__("datetime").datetime.utcnow()),
        # DROP: not a CVE.
        Vulnerability(id=30, tenant_id=TENANT, vuln_id="V-30", title="t", severity="high",
                      cve_id="GHSA-xxxx-yyyy-zzzz", nvd_last_synced_at=None),
        # DROP: ad-hoc-only link.
        Vulnerability(id=40, tenant_id=TENANT, vuln_id="V-40", title="t", severity="high",
                      cve_id="CVE-2024-0004", nvd_last_synced_at=None),
        # DROP: no asset link at all.
        Vulnerability(id=50, tenant_id=TENANT, vuln_id="V-50", title="t", severity="high",
                      cve_id="CVE-2024-0005", nvd_last_synced_at=None),
    ])
    db.add_all([
        VulnerabilityAssetLink(vulnerability_id=10, asset_id=1),
        VulnerabilityAssetLink(vulnerability_id=20, asset_id=1),
        VulnerabilityAssetLink(vulnerability_id=30, asset_id=1),
        VulnerabilityAssetLink(vulnerability_id=40, asset_id=2),  # ad-hoc only
    ])
    db.commit()


def test_query_selects_only_unenriched_register_cves():
    db = _db()
    ids = {v.id for v in sweep_mod.unenriched_register_query(db).all()}
    assert ids == {10}  # enriched(20), non-CVE(30), ad-hoc(40), unlinked(50) all excluded


def test_per_cve_failure_does_not_abort_and_does_not_spin(monkeypatch):
    db = _db()
    # Add a second eligible row so "continues past a failure" is observable.
    db.add(Vulnerability(id=11, tenant_id=TENANT, vuln_id="V-11", title="t", severity="high",
                         cve_id="CVE-2024-0011", nvd_last_synced_at=None))
    db.add(VulnerabilityAssetLink(vulnerability_id=11, asset_id=1))
    db.commit()

    seen_rows = []

    def _fake_ensure(d, v):
        seen_rows.append(v.id)
        if v.id == 10:
            return False  # transient failure: row left un-synced (would re-select)
        v.nvd_last_synced_at = __import__("datetime").datetime.utcnow()  # success stamps it
        d.commit()
        return True

    monkeypatch.setattr(sweep_mod, "ensure_cve_enriched", _fake_ensure)
    enriched = sweep_mod.sweep_tenant(db, slug="t", seen=set(), delay=0.0)

    assert 11 in seen_rows          # did not abort on row 10's failure
    assert enriched == 1            # only the row that actually synced is counted
    assert len(seen_rows) < 50      # progress-guard broke the loop; no infinite spin
