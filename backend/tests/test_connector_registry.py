"""Guards the connector provider registry after the GRC-leftover purge.

The AVA admin "External Connectors" page renders from PROVIDER_REGISTRY, so
these asserts are the contract for what shows up there.
"""
from grc.modules.connectors.registry import PROVIDER_REGISTRY
from grc.modules.connectors.providers.servicenow import META as SN_META

# Pentest/SIEM/ticketing/EASM providers AVA keeps.
KEPT = {"servicenow", "splunk", "qradar", "wazuh",
        "metasploit", "shodan", "censys", "securitytrails"}
# GRC-era collab/ITSM/commercial-pentest leftovers that were stripped.
REMOVED = {"bmc_remedy", "core_impact", "zoom", "office365", "msteams", "fireflies"}


def test_only_ava_providers_registered():
    assert set(PROVIDER_REGISTRY) == KEPT


def test_removed_providers_gone():
    assert REMOVED.isdisjoint(PROVIDER_REGISTRY)


def test_servicenow_keeps_vuln_ticketing_drops_exception_config():
    keys = {f.key for f in SN_META.fields}
    assert "vuln_table" in keys          # vuln ticketing kept
    assert "exception_table" not in keys  # GRC exception-push config stripped
