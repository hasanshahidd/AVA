"""The Vulnerability register is MANAGED-INVENTORY findings only.

Locks the shared `exclude_adhoc` filter: a finding is KEPT only if it is linked
to a managed inventory asset. A finding with NO asset link is dropped, and a
finding linked ONLY to an ad-hoc pentest target (asset tagged status='adhoc' OR
last_seen_source='pentest-adhoc' — exactly what the pentest engine stamps on its
transient external targets) is dropped. A finding linked to a managed asset is
kept even when it is ALSO linked to an ad-hoc target.
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
        # No asset link at all → NOT part of the register (inventory-linked only).
        Vulnerability(id=40, tenant_id=TENANT, vuln_id="V-40", title="unlinked", severity="low", status="open"),
        # Linked to BOTH a managed asset and an ad-hoc target → kept (has a managed link).
        Vulnerability(id=50, tenant_id=TENANT, vuln_id="V-50", title="managed+adhoc", severity="high", status="open"),
    ])
    db.add_all([
        VulnerabilityAssetLink(vulnerability_id=10, asset_id=1),
        VulnerabilityAssetLink(vulnerability_id=20, asset_id=2),
        VulnerabilityAssetLink(vulnerability_id=30, asset_id=3),
        VulnerabilityAssetLink(vulnerability_id=50, asset_id=1),
        VulnerabilityAssetLink(vulnerability_id=50, asset_id=2),
    ])
    db.commit()


def test_register_is_managed_inventory_only(db):
    # Kept: 10 (managed), 50 (managed + ad-hoc). Dropped: 20/30 (ad-hoc only),
    # 40 (no link at all).
    kept = {
        v.id for v in db.query(Vulnerability).filter(exclude_adhoc(db)).all()
    }
    assert kept == {10, 50}, kept
