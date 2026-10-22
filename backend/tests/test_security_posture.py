"""Software classification + endpoint security posture.

Guards that the classifier recognises real AV/EDR/software families and that the
posture rollup answers the operator question "does this host have antivirus / an
EDR, and what does it run". DB-free.
"""
import pytest

from grc.modules.compliance_plugins.services.security_classifier import (
    classify, summarize_posture, apply_posture,
)


def sw(name, key=None):
    return {"name": name, "software_key": key or name.lower().replace(" ", "-")}


@pytest.mark.parametrize("name,expected", [
    ("CrowdStrike Falcon Sensor", "edr"),
    ("SentinelOne Agent", "edr"),
    ("Cortex XDR", "edr"),
    ("Microsoft Defender Antivirus", "antivirus"),
    ("McAfee Endpoint Security", "antivirus"),
    ("Sophos Anti-Virus", "antivirus"),
    ("ClamAV", "antivirus"),
    ("Veeam Backup & Replication", "backup"),
    ("TeamViewer", "remote_access"),
    ("OpenVPN Connect", "vpn"),
    ("PostgreSQL 15", "database"),
    ("nginx", "web_server"),
    ("Docker Desktop", "container"),
    ("Splunk Universal Forwarder", "monitoring"),
])
def test_classify_known_families(name, expected):
    assert classify(sw(name)) == expected


def test_ordinary_application_is_unclassified():
    assert classify(sw("Google Chrome")) is None
    assert classify(sw("7-Zip")) is None


def test_edr_wins_over_antivirus_when_both_could_match():
    # Sophos ships both an AV and Intercept X (EDR); the EDR label is stronger.
    assert classify(sw("Sophos Intercept X")) == "edr"


def test_posture_reports_antivirus_and_edr_presence():
    inv = [sw("Microsoft Defender Antivirus"), sw("CrowdStrike Falcon Sensor"),
           sw("Google Chrome"), sw("PostgreSQL 15")]
    p = summarize_posture(inv)
    assert p["has_antivirus"] is True
    assert p["has_edr"] is True
    assert p["endpoint_protected"] is True
    assert "Microsoft Defender Antivirus" in p["antivirus_products"]
    assert "CrowdStrike Falcon Sensor" in p["edr_products"]
    assert p["categories"]["database"] == 1
    assert p["categories"]["application"] == 1  # Chrome counted as an app
    assert p["software_total"] == 4


def test_posture_flags_an_unprotected_host():
    p = summarize_posture([sw("Google Chrome"), sw("nginx")])
    assert p["has_antivirus"] is False
    assert p["has_edr"] is False
    assert p["endpoint_protected"] is False


def test_posture_handles_empty_and_junk():
    assert summarize_posture(None)["endpoint_protected"] is False
    assert summarize_posture([])["software_total"] == 0
    # a malformed (non-dict) entry must not blow up the rollup
    p = summarize_posture(["not-a-dict", sw("ESET Endpoint Antivirus")])
    assert p["has_antivirus"] is True


def test_products_are_deduplicated():
    p = summarize_posture([sw("McAfee Endpoint Security"), sw("McAfee Endpoint Security")])
    assert p["antivirus_products"] == ["McAfee Endpoint Security"]


def test_deep_scan_security_read_feeds_the_posture():
    # Asset 296's real shape: Defender on (OS component, not in the software
    # list), MDE sensor installed but its Sense service stopped.
    def pp(edr, av=({"name": "Windows Defender", "enabled": True},), defender=True):
        return {"defender": {"status": "discovered", "data": {"antivirus_enabled": defender}},
                "security_products": {"status": "discovered", "data": {"antivirus": list(av), "edr_xdr": edr}}}
    mde_stopped = [{"product": "Microsoft Defender for Endpoint", "service": "Sense", "running": False}]
    p = summarize_posture([sw("Google Chrome")], pp(mde_stopped))
    assert p["has_antivirus"] and p["antivirus_products"] == ["Windows Defender"]
    assert not p["has_edr"] and p["edr_stopped"] == ["Microsoft Defender for Endpoint"]
    assert p["endpoint_protected"] and p["software_total"] == 1
    # Defender enabled but no SecurityCenter2 entry (Windows Server) → still AV.
    assert summarize_posture([], pp([], av=()))["antivirus_products"] == ["Microsoft Defender Antivirus"]
    # A disabled AV and Defender off → nothing.
    assert not summarize_posture([], pp([], av=({"name": "Sophos", "enabled": False},), defender=False))["has_antivirus"]
    # Stopped EDR overrides the software-list hit for the SAME product...
    cs = [{"product": "CrowdStrike Falcon", "service": "CSFalconService", "running": False}]
    assert not summarize_posture([sw("CrowdStrike Windows Sensor")], pp(cs))["has_edr"]
    # ...running counts; an EDR the deep scan doesn't know still counts via software.
    assert summarize_posture([], pp([dict(cs[0], running=True)]))["edr_products"] == ["CrowdStrike Falcon"]
    assert summarize_posture([sw("Huntress Agent")], pp(mde_stopped))["edr_products"] == ["Huntress Agent"]


class _Asset:
    detected_software_json = None
    security_posture = None


def test_apply_posture_writes_to_the_asset():
    a = _Asset()
    a.detected_software_json = [sw("CrowdStrike Falcon Sensor")]
    out = apply_posture(a)
    assert a.security_posture is out
    assert a.security_posture["has_edr"] is True


def test_asset_model_has_security_posture_column():
    from grc.models import ITAsset
    assert "security_posture" in ITAsset.__table__.columns
