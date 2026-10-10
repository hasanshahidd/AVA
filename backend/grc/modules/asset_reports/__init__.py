"""IT asset-inventory reporting — the second entry in the Reports module.

Sits beside sbp_inventory (the first report). Pulls the real IT asset estate
(grc_it_assets) and renders professional asset-inventory reports in the
standard downloadable formats (PDF / XLSX / CSV / HTML). Each generated report
is persisted (grc_generated_asset_reports) so it can be re-downloaded as the
point-in-time artifact it was.
"""
