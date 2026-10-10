"""Guards the connector provider registry after the GRC-leftover purge.

The AVA admin "External Connectors" page renders from PROVIDER_REGISTRY, so
these asserts are the contract for what shows up there.
"""
from grc.modules.connectors.registry import PROVIDER_REGISTRY, list_providers
from grc.modules.connectors.providers.servicenow import META as SN_META

# Pentest/SIEM/ticketing/EASM providers AVA shows on the customer Connectors page.
KEPT = {"servicenow", "splunk", "qradar", "wazuh",
        "metasploit", "shodan", "censys", "securitytrails"}
# GRC-era collab/ITSM/commercial-pentest leftovers that were stripped.
REMOVED = {"bmc_remedy", "core_impact", "zoom", "office365", "msteams", "fireflies"}


def test_only_ava_providers_customer_visible():
    # The Connectors page renders from the NON-internal providers. The Help Desk
    # engine (frappe_helpdesk) is AVA's own infra → registered but internal, so it
    # must never appear here. Customer-visible set must be exactly KEPT.
    visible = {p.provider for p in list_providers() if not p.internal}
    assert visible == KEPT


def test_helpdesk_engine_registered_but_internal():
    meta = PROVIDER_REGISTRY.get("frappe_helpdesk")
    assert meta is not None and meta.internal is True


def test_removed_providers_gone():
    assert REMOVED.isdisjoint(PROVIDER_REGISTRY)


def test_servicenow_keeps_vuln_ticketing_drops_exception_config():
    keys = {f.key for f in SN_META.fields}
    assert "vuln_table" in keys          # vuln ticketing kept
    assert "exception_table" not in keys  # GRC exception-push config stripped
