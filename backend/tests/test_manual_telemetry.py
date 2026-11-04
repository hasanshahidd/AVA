import pytest

from grc.services.manual_telemetry import merge_manual_telemetry


def test_writes_manual_envelope_and_keeps_untouched_sections():
    existing = {
        "cpu": {"status": "discovered", "data": {"model": "old"}},
        "memory": {"status": "discovered", "data": {"total_gb": 16}},
        "surface": {"ports": [22]},
    }
    merged = merge_manual_telemetry(existing, {"cpu": {"model": "Xeon", "sockets": 2}})

    assert merged["cpu"]["data"] == {"model": "Xeon", "sockets": 2}
    assert merged["cpu"]["status"] == "discovered" and merged["cpu"]["source"] == "manual"
    assert merged["memory"] == existing["memory"]
    assert merged["surface"] == {"ports": [22]}
    assert existing["cpu"]["data"] == {"model": "old"}  # input not mutated


def test_creates_from_nothing():
    merged = merge_manual_telemetry(None, {"network": [{"name": "eth0", "ipv4": ["10.0.0.5"]}]})
    assert merged["network"]["data"][0]["name"] == "eth0"


@pytest.mark.parametrize("key", ["surface", "fingerprint", "recon", "discovery_classification", "bad key", "", "x" * 65])
def test_rejects_reserved_or_malformed_keys(key):
    with pytest.raises(ValueError):
        merge_manual_telemetry({}, {key: {"a": 1}})


def test_rejects_oversized_section():
    with pytest.raises(ValueError):
        merge_manual_telemetry({}, {"services": ["x" * 1000] * 3000})
