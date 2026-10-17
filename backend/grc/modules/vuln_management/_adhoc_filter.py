"""Shared filter: the register is MANAGED-INVENTORY findings only.

A vulnerability is part of the Vulnerability register ONLY if it is linked to a
managed inventory asset. Two kinds of finding are therefore NOT in the register:

  * findings with NO asset link at all; and
  * findings linked ONLY to an ad-hoc pentest target — the transient ITAsset the
    AI-pentest engine creates for arbitrary external URLs/IPs it scans without
    adding to inventory (ginandjuice.shop, demo.testfire.net, metasploitable, …),
    tagged ``status='adhoc'`` + ``last_seen_source='pentest-adhoc'``.

A finding linked to at least one managed asset is KEPT even if it is ALSO linked
to an ad-hoc target. One helper, applied at every Vulnerability query site, so
the register list, the dashboard counts and every finding list reconcile against
the same definition of "in the register".
"""
from sqlalchemy import func
from sqlalchemy.orm import Session

from ...models import Vulnerability, VulnerabilityAssetLink, ITAsset


def inventory_assets_only(A=ITAsset):
    """Filter conditions (a tuple - splat into ``.filter(*...)``) keeping only
    INVENTORY ``ITAsset`` rows, i.e. NOT a transient AI-pentest ad-hoc target.
    Same predicate as the asset register (assets_router.list_assets),
    estate_overview and license_management: status != 'adhoc' AND
    last_seen_source != 'pentest-adhoc', NULL-safe via coalesce. ``A`` may be an
    ``aliased(ITAsset)``.
    """
    return (
        func.coalesce(A.status, "") != "adhoc",
        func.coalesce(A.last_seen_source, "") != "pentest-adhoc",
    )


def exclude_adhoc(db: Session):
    """A SQLAlchemy filter condition keeping ONLY vulnerabilities linked to a
    managed inventory asset (drops unlinked findings AND ad-hoc-only findings).
    Apply with ``.filter(exclude_adhoc(db))`` on any query that selects or joins
    ``Vulnerability``.

    ponytail: re-runs the ``IN`` sub-select per query (register sizes are
    hundreds–thousands of rows, well within budget); push to a cached id set
    if a tenant's register ever grows large enough to matter.
    """
    # Reuse the EXACT tags the pentest engine stamps — imported lazily so this
    # module never pulls the heavy pentest.service at import time / risks a cycle.
    from ..pentest.service import ADHOC_STATUS, ADHOC_SOURCE

    # Vulns with a link to a MANAGED asset — one that carries NEITHER ad-hoc tag.
    # coalesce() keeps the comparison NULL-safe: a managed asset whose status /
    # source is NULL must still read "not ad-hoc" (and be kept), not drop out.
    managed_vuln_ids = (
        db.query(VulnerabilityAssetLink.vulnerability_id)
        .join(ITAsset, ITAsset.id == VulnerabilityAssetLink.asset_id)
        .filter(
            func.coalesce(ITAsset.status, "") != ADHOC_STATUS,
            func.coalesce(ITAsset.last_seen_source, "") != ADHOC_SOURCE,
        )
    )
    return Vulnerability.id.in_(managed_vuln_ids)
