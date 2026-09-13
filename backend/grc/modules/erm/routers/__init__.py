"""Ava keeps only the CTEM scopes/cycles router from the ERM module.

The rest of the GRC ERM surface (risks, kris, rcsa, incidents, …) was stripped
for the cyber-only product; only CTEM Phase-3 (exposure scopes + cycles), which
the Vulnerabilities → CTEM Scopes board consumes, is retained here.
"""
from .ctem_scopes import router as ctem_scopes_router

__all__ = ["ctem_scopes_router"]
