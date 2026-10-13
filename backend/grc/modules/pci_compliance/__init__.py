"""PCI-DSS 4.0.1 compliance module — real requirements from the SCF crosswalk,
per-requirement coverage tracked by assessment + evidence (auditor-defensible).

The requirement catalogue is derived live from grc_scf_mapping (source_slug
'pci_dss_401') joined to grc_scf_control — no hand-authored control list. Only
the assessment state (status/note/evidence per requirement) is stored, in one
dedicated tenant-scoped table created by create_all (no per-tenant ALTER).
"""
