"""Lane-manifest / lane-image resolution — offline, no docker/network/LLM.

Covers the v2 HIERARCHY: web is FLAT (one scan / one exploit / one monolith-fallback image); internal
BRANCHES by subtype (windows / linux / network), each sub-lane with its OWN split images and tool lists.
Everything resolves through the YAML manifest (`_lane_manifest_node` -> `_lane_image`) with a HARD monolith
fallback and NO faked run (unknown lane -> None). The exploit LANE-LOCK (`_lane_toolset` with no phase) is
CODE-DERIVED and decoupled from the seed manifest, while the phase-aware toolset (`_lane_toolset` with a
phase) reads the manifest and can NEVER widen beyond it. The deterministic internal OS-subtype resolver
(`_internal_subtype`) carries the LLM seam. Every docker touch is monkeypatched: `_image_built` (does a
split image exist?) and, where a missing/empty manifest is exercised, `load_lane_manifest` / `Path` are
swapped so nothing reads the real file or shells out.
"""
import pathlib

import pytest

import grc.modules.pentest.service as svc


@pytest.fixture(autouse=True)
def _hermetic():
    """The manifest loader is lru_cached and _image_built caches its YESes — clear both around every test so
    real-file reads and monkeypatched runs never leak."""
    svc.load_lane_manifest.cache_clear()
    svc._SPLIT_IMAGE_BUILT_CACHE.clear()
    yield
    svc.load_lane_manifest.cache_clear()
    svc._SPLIT_IMAGE_BUILT_CACHE.clear()


# ── (1) the real lanes.yaml parses the web (FLAT) split images ───────────────

def test_manifest_parses_web_split_images():
    web = svc.load_lane_manifest()["web"]
    assert web["scan_image"] == "ava-web-scan"
    assert web["exploit_image"] == "ava-web-exploit"
    assert web["fallback_image"] == "ava-web"


# ── (2) the real lanes.yaml BRANCHES internal into windows/linux/network ─────

def test_manifest_parses_internal_subtypes():
    internal = svc.load_lane_manifest()["internal"]
    subs = internal["subtypes"]
    assert set(subs) >= {"windows", "linux", "network"}
    assert subs["windows"]["exploit_image"] == "ava-win-exploit"
    assert subs["linux"]["scan_image"] == "ava-linux-scan"
    assert subs["network"]["exploit_image"] == "ava-netdev-exploit"
    # internal itself carries NO flat images — they live per subtype (each falling back to ava-internal).
    assert "exploit_image" not in internal and "scan_image" not in internal
    assert all(subs[s]["fallback_image"] == "ava-internal" for s in ("windows", "linux", "network"))


# ── (3) built split image wins its phase — web FLAT ──────────────────────────

def test_web_lane_image_uses_split_when_built(monkeypatch):
    monkeypatch.setattr(svc, "_image_built", lambda _img: True)
    assert svc._lane_image("web", "scan") == "ava-web-scan"
    assert svc._lane_image("web", "exploit") == "ava-web-exploit"


# ── (4) built split image wins its (subtype, phase) — internal BRANCHED ──────

def test_internal_subtypes_resolve_their_own_images(monkeypatch):
    monkeypatch.setattr(svc, "_image_built", lambda _img: True)
    assert svc._lane_image("internal", "scan", "windows") == "ava-win-scan"
    assert svc._lane_image("internal", "exploit", "windows") == "ava-win-exploit"
    assert svc._lane_image("internal", "scan", "linux") == "ava-linux-scan"
    assert svc._lane_image("internal", "exploit", "linux") == "ava-linux-exploit"
    assert svc._lane_image("internal", "scan", "network") == "ava-netdev-scan"
    assert svc._lane_image("internal", "exploit", "network") == "ava-netdev-exploit"


# ── (5) FALLBACK: split not built -> the monolith (web + every internal subtype)

def test_split_falls_back_to_monolith_when_not_built(monkeypatch):
    monkeypatch.setattr(svc, "_image_built", lambda _img: False)
    assert svc._lane_image("web", "scan") == svc._LANE_IMAGE["web"]
    assert svc._lane_image("web", "exploit") == svc._LANE_IMAGE["web"]
    for st in ("windows", "linux", "network"):
        assert svc._lane_image("internal", "scan", st) == svc._LANE_IMAGE["internal"]
        assert svc._lane_image("internal", "exploit", st) == svc._LANE_IMAGE["internal"]


# ── (6) internal WITHOUT a subtype -> the monolith (today's live flow, unchanged)

def test_internal_no_subtype_is_monolith(monkeypatch):
    monkeypatch.setattr(svc, "_image_built", lambda _img: True)   # even so: no FLAT internal split image exists
    assert svc._lane_image("internal", "exploit") == svc._LANE_IMAGE["internal"]
    assert svc._lane_image("internal", "scan") == svc._LANE_IMAGE["internal"]


# ── (7) empty / missing manifest -> monolith, never a crash ──────────────────

def test_lane_image_falls_back_when_manifest_empty(monkeypatch):
    monkeypatch.setattr(svc, "load_lane_manifest", lambda: {})
    monkeypatch.setattr(svc, "_image_built", lambda _img: True)   # irrelevant: nothing is named
    assert svc._lane_image("web", "exploit") == svc._LANE_IMAGE["web"]
    assert svc._lane_image("internal", "exploit") == svc._LANE_IMAGE["internal"]
    assert svc._lane_image("internal", "exploit", "windows") == svc._LANE_IMAGE["internal"]


def test_loader_tolerates_missing_file(monkeypatch):
    monkeypatch.setattr(svc, "Path", lambda _f: pathlib.Path("C:/__ava_no_such_dir__/x"))
    assert svc.load_lane_manifest() == {}


# ── (8) unknown lane -> None (unarmed); unknown subtype -> monolith (safe) ────

def test_unknown_lane_and_subtype_are_safe(monkeypatch):
    monkeypatch.setattr(svc, "_image_built", lambda _img: True)
    assert svc._lane_image("bogus", "exploit") is None                # no fallback at all -> honestly unarmed
    assert svc._lane_image("bogus", "exploit", "windows") is None
    # an unknown internal subtype has no split image -> the internal monolith, never a crash / never None.
    assert svc._lane_image("internal", "exploit", "bogus") == svc._LANE_IMAGE["internal"]


# ── lane-lock (no phase): CODE-DERIVED, decoupled from the seed manifest ──────

def test_lane_lock_is_code_derived_and_cannot_be_widened(monkeypatch):
    assert svc._lane_toolset("web") == svc._lane_toolset_hardcoded("web")
    assert svc._lane_toolset("internal") == svc._lane_toolset_hardcoded("internal")
    assert "netexec" not in svc._lane_toolset("web")          # a host tool never leaks into the web lock
    # a rogue manifest can neither widen NOR narrow the hard lock — the lock ignores the file entirely.
    monkeypatch.setattr(svc, "load_lane_manifest",
                        lambda: {"web": {"exploit_tools": ["sqlmap", "netexec", "not-a-tool"]}})
    assert svc._lane_toolset("web") == svc._lane_toolset_hardcoded("web")
    assert "netexec" not in svc._lane_toolset("web")


# ── phase-aware toolset: reads the manifest, CANNOT widen beyond it ───────────

def test_phase_toolset_reads_manifest_and_cannot_widen(monkeypatch):
    # real manifest: web (flat) + each internal subtype declare non-empty scan/exploit lists.
    assert "sqlmap" in svc._lane_toolset("web", "exploit")
    assert "nikto" in svc._lane_toolset("web", "scan")
    assert "nmap" in svc._lane_toolset("internal", "scan", "windows")
    assert svc._lane_toolset("internal", "exploit", "network")
    # a rogue/narrow manifest: the returned list is EXACTLY the file's list — never more (rogue-proof).
    monkeypatch.setattr(
        svc, "load_lane_manifest",
        lambda: {"internal": {"subtypes": {"windows": {"exploit_tools": ["netexec", "evil-winrm"]}}}})
    assert svc._lane_toolset("internal", "exploit", "windows") == ["netexec", "evil-winrm"]
    assert svc._lane_toolset("internal", "scan", "windows") == []     # phase not declared -> []
    assert svc._lane_toolset("internal", "exploit", "linux") == []    # subtype absent -> []
    assert svc._lane_toolset("web", "exploit") == []                  # lane absent -> []
    assert svc._lane_toolset("bogus", "scan") == []                   # unknown lane -> []


# ── internal OS-subtype resolver (deterministic) + the LLM classifier seam ────

def test_internal_subtype_resolver_and_llm_seam():
    assert svc._internal_subtype({"os_family": "Windows Server 2019"}) == "windows"
    assert svc._internal_subtype({"os_family": "Ubuntu 22.04 LTS"}) == "linux"
    assert svc._internal_subtype({"os_family": "Debian", "asset_type": "infrastructure"}) == "linux"
    assert svc._internal_subtype({"platform_kind": "switch", "asset_type": "infrastructure"}) == "network"
    assert svc._internal_subtype({"os_family": "Cisco IOS XE"}) == "network"
    assert svc._internal_subtype({}) == "windows"                     # truly unknown -> safest default
    assert svc._internal_subtype({"asset_type": "infrastructure"}) == "windows"   # ambiguous -> default
    # SEAM: a VALID llm pick wins; an invalid pick falls back to the deterministic read.
    assert svc._internal_subtype({"os_family": "Ubuntu"}, llm_pick="network") == "network"
    assert svc._internal_subtype({"os_family": "Ubuntu"}, llm_pick="nonsense") == "linux"
    assert svc._internal_subtype({"os_family": "Ubuntu"}, llm_pick=None) == "linux"


# ── NEW internal sub-lanes: cloud / kubernetes / repos resolve their own split images ────────────

_NEW_SUBTYPE_IMAGES = {
    "cloud":      ("ava-cloud-scan", "ava-cloud-exploit"),
    "kubernetes": ("ava-k8s-scan",   "ava-k8s-exploit"),
    "repos":      ("ava-repo-scan",  "ava-repo-exploit"),
}


def test_new_internal_subtypes_resolve_their_own_images(monkeypatch):
    # (c) treat every split image as BUILT -> each new sub-lane runs its OWN scan/exploit image.
    monkeypatch.setattr(svc, "_image_built", lambda _img: True)
    for st, (scan, exploit) in _NEW_SUBTYPE_IMAGES.items():
        assert svc._lane_image("internal", "scan", st) == scan
        assert svc._lane_image("internal", "exploit", st) == exploit


def test_new_internal_subtypes_fall_back_to_monolith_when_not_built(monkeypatch):
    # (c) NOT built -> the ava-internal monolith fallback, exactly like windows/linux/network.
    monkeypatch.setattr(svc, "_image_built", lambda _img: False)
    for st in _NEW_SUBTYPE_IMAGES:
        assert svc._lane_image("internal", "scan", st) == svc._LANE_IMAGE["internal"]
        assert svc._lane_image("internal", "exploit", st) == svc._LANE_IMAGE["internal"]


# ── (d) DRIFT-GUARD: the hard lane-lock is an exact set and is subtype-independent ────────────────

def test_lane_lock_hardcoded_exact_sets_and_subtype_independent():
    # The lane-lock floor, pinned to its exact expected membership: a change to the runner tables (a tool
    # added/removed) trips this, and no manifest subtype may ever widen or narrow it.
    assert svc._lane_toolset_hardcoded("web") == {
        "sqlmap", "commix", "xsstrike", "dalfox", "nuclei-web",
        "webcheck-lfi", "webcheck-openredirect", "webcheck-ssrf", "webcheck-xxe", "webcheck-deser"}
    assert svc._lane_toolset_hardcoded("internal") == {
        "netexec", "impacket", "pacu", "peirates", "metasploit"}
    # subtype-independent: _lane_toolset with NO phase is the code-derived lock, unchanged for any sub-lane
    # (including the three new ones) — the lock has no subtype axis.
    for st in ("windows", "linux", "network", "cloud", "kubernetes", "repos"):
        assert svc._lane_toolset("internal", subtype=st) == svc._lane_toolset_hardcoded("internal")
        assert svc._lane_toolset("web", subtype=st) == svc._lane_toolset_hardcoded("web")
