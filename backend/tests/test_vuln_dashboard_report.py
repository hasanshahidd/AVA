from grc.modules.vuln_management.routers.dashboard import _styled_kv_table


def test_styled_kv_table_builds_without_module_level_inch():
    t = _styled_kv_table([["Severity", "Count"], ["Critical", "3"]], "#005B96", "#E6F0F7", bold_last=True)
    assert t is not None
