"""Hand-entered scan telemetry from the Add / Edit asset form.

platform_properties holds one ``{"status", "data"}`` envelope per collector section
(cpu, storage, network, services, firewall, ...). The form edits those sections' data;
a manual section is stamped ``source="manual"`` and stands until the next scan
re-collects that section and overwrites it.
"""
import json
from datetime import datetime
from typing import Any, Dict, Optional

# Non-section keys owned by discovery / recon — never writable from the form.
RESERVED_KEYS = {"surface", "fingerprint", "discovery_classification", "recon"}
MAX_SECTION_BYTES = 2_000_000
MAX_SECTIONS = 60


def _valid_key(key: Any) -> bool:
    return isinstance(key, str) and 0 < len(key) <= 64 and key not in RESERVED_KEYS \
        and key.replace("_", "").isalnum()


def merge_manual_telemetry(existing: Optional[dict], sections: Optional[Dict[str, Any]]) -> dict:
    """Return a NEW platform_properties dict with ``sections`` (key -> data) written as
    manual envelopes. Untouched sections and reserved keys are kept as they were.
    Raises ValueError on an invalid key or an oversized section."""
    merged = dict(existing) if isinstance(existing, dict) else {}
    if not sections:
        return merged
    if len(sections) > MAX_SECTIONS:
        raise ValueError(f"too many telemetry sections (max {MAX_SECTIONS})")
    stamp = datetime.utcnow().isoformat()
    for key, data in sections.items():
        if not _valid_key(key):
            raise ValueError(f"invalid telemetry section '{key}'")
        if data is not None and not isinstance(data, (dict, list, str, int, float, bool)):
            raise ValueError(f"telemetry section '{key}' has an unsupported value")
        if len(json.dumps(data, default=str)) > MAX_SECTION_BYTES:
            raise ValueError(f"telemetry section '{key}' is too large")
        merged[key] = {"status": "discovered", "data": data, "source": "manual", "edited_at": stamp}
    return merged
