"""Shared filter: drop vulnerabilities that belong to ad-hoc pentest targets.

The AI-pentest engine scans arbitrary external URLs/IPs (ginandjuice.shop,
demo.testfire.net, metasploitable, ...) WITHOUT adding them to the managed
inventory. For each it creates a transient ITAsset tagged
``status='adhoc'`` + ``last_seen_source='pentest-adhoc'`` and links the
findings to it. Those findings are NOT the owner's real inventory, so the
Vulnerability dashboard (cards, severity counts, charts AND the finding list)
excludes them. Managed-inventory findings — and findings with no asset link at
all — are kept.

One helper, applied at every Vulnerability query site, so every number on the
dashboard reconciles against the same definition of "ad-hoc".
"""
from sqlalchemy import or_
from sqlalchemy.orm import Session

from ...models import Vulnerability, VulnerabilityAssetLink, ITAsset


def exclude_adhoc(db: Session):
    """A SQLAlchemy filter condition dropping vulnerabilities linked to an
    ad-hoc pentest-target asset. Apply with ``.filter(exclude_adhoc(db))`` on
    any query that selects or joins ``Vulnerability``.

    ponytail: re-runs the ``NOT IN`` sub-select per query (register sizes are
    hundreds–thousands of rows, well within budget); push to a cached id set
    if a tenant's register ever grows large enough to matter.
    """
    # Reuse the EXACT tags the pentest engine stamps — imported lazily so this
    # module never pulls the heavy pentest.service at import time / risks a cycle.
    from ..pentest.service import ADHOC_STATUS, ADHOC_SOURCE

    adhoc_vuln_ids = (
        db.query(VulnerabilityAssetLink.vulnerability_id)
        .join(ITAsset, ITAsset.id == VulnerabilityAssetLink.asset_id)
        .filter(or_(
            ITAsset.status == ADHOC_STATUS,
            ITAsset.last_seen_source == ADHOC_SOURCE,
        ))
    )
    # vulnerability_id is a non-null FK, so NOT IN has no NULL-row surprise.
    return Vulnerability.id.notin_(adhoc_vuln_ids)
