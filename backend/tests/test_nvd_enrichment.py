"""Phase 1 — real-tenant enrichment inputs.

Guards the gap that made every real tenant map generically: the NVD client never
read `cve.weaknesses[]`, so `vuln.cwe_id` stayed null and the engine fell back to
the assumed-generic chain. These lock the CWE extraction (Primary first, NVD
placeholders dropped, whole list kept) and that the selector reads the full list
without regressing the single-CWE path. DB- and network-free (pure functions).
"""
from datetime import datetime

from grc.modules.vuln_management.attack.selection import select_techniques
from grc.modules.vuln_management.enrichment import nvd_client
from grc.modules.vuln_management.enrichment import kev_cache
from grc.modules.vuln_management.enrichment.nvd_client import (
    _extract_payload, cve_exists, confirmed_absent_cves,
)


def _nvd_raw(weaknesses):
    """Minimal NVD 2.0 response shape carrying just the weaknesses block."""
    return {"vulnerabilities": [{"cve": {
        "id": "CVE-2024-9999",
        "descriptions": [{"lang": "en", "value": "test"}],
        "weaknesses": weaknesses,
    }}]}


def test_nvd_extracts_cwes_primary_first():
    r = _extract_payload(_nvd_raw([
        {"type": "Secondary", "description": [{"lang": "en", "value": "CWE-79"}]},
        {"type": "Primary", "description": [{"lang": "en", "value": "CWE-89"}]},
    ]), "CVE-2024-9999")
    assert r.cwe_ids == ["CWE-89", "CWE-79"]  # Primary leads, so cwe_ids[0] is the Primary


def test_nvd_skips_placeholder_weaknesses():
    r = _extract_payload(_nvd_raw([
        {"type": "Primary", "description": [{"lang": "en", "value": "NVD-CWE-noinfo"}]},
        {"type": "Secondary", "description": [{"lang": "en", "value": "NVD-CWE-Other"}]},
        {"type": "Secondary", "description": [{"lang": "en", "value": "CWE-22"}]},
    ]), "CVE-2024-9999")
    assert r.cwe_ids == ["CWE-22"]  # the two placeholders carry no CWE and are dropped


def test_nvd_no_weaknesses_is_empty_list():
    assert _extract_payload(_nvd_raw([]), "CVE-2024-9999").cwe_ids == []


def test_nvd_dedupes_repeated_cwe():
    r = _extract_payload(_nvd_raw([
        {"type": "Primary", "description": [{"lang": "en", "value": "CWE-89"}]},
        {"type": "Secondary", "description": [{"lang": "en", "value": "CWE-89"}]},
    ]), "CVE-2024-9999")
    assert r.cwe_ids == ["CWE-89"]


def test_selector_reads_full_cwe_list_without_regressing_single():
    # More CWEs = more input, never less: the multi-CWE result is a superset of the
    # single-CWE result. This is why storing the whole list beats keeping only one.
    one = {t["technique_id"] for t in select_techniques("CWE-89", None)}
    many = {t["technique_id"] for t in select_techniques(["CWE-89", "CWE-79", "CWE-22"], None)}
    assert one <= many
    assert len(many) >= len(one)


def test_selector_scalar_and_singleton_list_are_equivalent():
    # Back-compat: the old single-string call and a one-element list must match.
    a = {t["technique_id"] for t in select_techniques("CWE-89", None)}
    b = {t["technique_id"] for t in select_techniques(["CWE-89"], None)}
    assert a == b


# -------------------------------------------------------------------------------------------------
# NVD existence filter — drops reserved/synthetic CVE ids that NVD does not know. Network- and
# cache-free: _redis_client is stubbed to None and requests.get is faked per-case.
# -------------------------------------------------------------------------------------------------
_CUR_YEAR = datetime.utcnow().year
_REAL_CVE = f"CVE-{_CUR_YEAR}-1111"      # current-year so confirmed_absent_cves actually checks it
_SYNTH_CVE = f"CVE-{_CUR_YEAR}-59999"    # reserved/synthetic block the nmap-vulners feed emits


class _Resp:
    def __init__(self, status, payload=None):
        self.status_code = status
        self._payload = payload or {}

    def json(self):
        return self._payload


def _nmap_vuln_payload():
    return {"vulnerabilities": [{"cve": {"id": _REAL_CVE, "descriptions": [], "weaknesses": []}}]}


def _patch(monkeypatch, get):
    monkeypatch.setattr(nvd_client, "_redis_client", lambda: None)        # no cache: exercise the live path
    monkeypatch.setattr(kev_cache, "is_kev", lambda _cve: False)          # not in KEV: fall through to NVD
    monkeypatch.setattr(nvd_client.requests, "get", get)


def test_existence_real_cve_passes(monkeypatch):
    _patch(monkeypatch, lambda *a, **k: _Resp(200, _nmap_vuln_payload()))
    assert cve_exists(_REAL_CVE) is True
    assert confirmed_absent_cves([_REAL_CVE]) == set()  # real id survives


def test_existence_synthetic_cve_dropped(monkeypatch):
    # NVD positively reports "no such CVE" — both the 404 and the empty-200 shapes.
    _patch(monkeypatch, lambda *a, **k: _Resp(404))
    assert cve_exists(_SYNTH_CVE) is False
    assert confirmed_absent_cves([_SYNTH_CVE]) == {_SYNTH_CVE}

    _patch(monkeypatch, lambda *a, **k: _Resp(200, {"vulnerabilities": []}))
    assert cve_exists(_SYNTH_CVE) is False


def test_existence_nvd_error_keeps_finding(monkeypatch):
    # A network blip must never drop a CVE — fail open.
    def _boom(*a, **k):
        raise RuntimeError("NVD unreachable")
    _patch(monkeypatch, _boom)
    assert cve_exists(_SYNTH_CVE) is None
    assert confirmed_absent_cves([_SYNTH_CVE]) == set()  # kept

    # A non-404 HTTP error (e.g. 503 / rate-limit) is also "unknown" → kept.
    _patch(monkeypatch, lambda *a, **k: _Resp(503))
    assert cve_exists(_SYNTH_CVE) is None
    assert confirmed_absent_cves([_SYNTH_CVE]) == set()


def test_existence_historical_cve_not_looked_up(monkeypatch):
    # Pre-current-year ids are trusted without a lookup, so a real old CVE survives even
    # if NVD would 404 — and the hot path pays no network for historical findings.
    def _fail(*a, **k):
        raise AssertionError("historical CVE must not trigger an NVD call")
    _patch(monkeypatch, _fail)
    assert confirmed_absent_cves(["CVE-2024-6387"]) == set()
