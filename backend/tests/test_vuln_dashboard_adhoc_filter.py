"""The Vulnerability dashboard excludes ad-hoc pentest-target findings.

Locks the shared `exclude_adhoc` filter: a finding on a managed-inventory asset
(or with no asset link) is kept; a finding whose asset is tagged
status='adhoc' OR last_seen_source='pentest-adhoc' is dropped. Those two tags
are exactly what the pentest engine stamps on its transient external targets.
"""
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from grc.models import ITAsset, Vulnerability, VulnerabilityAssetLink
from grc.modules.vuln_management._adhoc_filter import exclude_adhoc
from grc.modules.pentest.service import ADHOC_STATUS, ADHOC_SOURCE

TENANT = 1


@pytest.fixture
def db():
    engine = create_engine("sqlite://")
    for m in (ITAsset, Vulnerability, VulnerabilityAssetLink):
        m.__table__.create(engine)
    s = sessionmaker(bind=engine)()
    _seed(s)
    yield s
    s.close()


def _seed(db):
    db.add_all([
        ITAsset(id=1, tenant_id=TENANT, name="managed-01", asset_type="server", status="active"),
        # Tagged by status (the pentest engine sets both; test status alone here)
        ITAsset(id=2, tenant_id=TENANT, name="ginandjuice.shop", asset_type="server",
                status=ADHOC_STATUS, last_seen_source=ADHOC_SOURCE),
        # Tagged by last_seen_source only (defensive: either tag must drop it)
        ITAsset(id=3, tenant_id=TENANT, name="demo.testfire.net", asset_type="server",
                status="active", last_seen_source=ADHOC_SOURCE),
    ])
    db.add_all([
        Vulnerability(id=10, tenant_id=TENANT, vuln_id="V-10", title="managed", severity="high", status="open"),
        Vulnerability(id=20, tenant_id=TENANT, vuln_id="V-20", title="adhoc-status", severity="high", status="open"),
        Vulnerability(id=30, tenant_id=TENANT, vuln_id="V-30", title="adhoc-source", severity="high", status="open"),
        # No asset link at all → must be kept (manual/imported finding).
        Vulnerability(id=40, tenant_id=TENANT, vuln_id="V-40", title="unlinked", severity="low", status="open"),
    ])
    db.add_all([
        VulnerabilityAssetLink(vulnerability_id=10, asset_id=1),
        VulnerabilityAssetLink(vulnerability_id=20, asset_id=2),
        VulnerabilityAssetLink(vulnerability_id=30, asset_id=3),
    ])
    db.commit()


def test_excludes_adhoc_keeps_managed_and_unlinked(db):
    kept = {
        v.id for v in db.query(Vulnerability).filter(exclude_adhoc(db)).all()
    }
    assert kept == {10, 40}, kept
