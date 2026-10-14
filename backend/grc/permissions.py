PERMISSION_MATRIX = [
    {
        "module": "dashboard",
        "display_name": "Dashboard",
        "submodules": [
            {
                "name": "overview",
                "display_name": "Dashboard Overview",
                "actions": ["view"]
            },
            {
                "name": "ai_insights",
                "display_name": "ComplyChat",
                "actions": ["view"]
            }
        ]
    },
    {
        "module": "risks",
        "display_name": "Risk Management",
        "submodules": [
            {
                "name": "risk_register",
                "display_name": "Risk Register",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "risk_assessment",
                "display_name": "Risk Assessment",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "risk_treatment",
                "display_name": "Risk Treatment",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "risk_appetite",
                "display_name": "Risk Appetite",
                "actions": ["view", "create", "edit", "delete"]
            }
        ]
    },
    {
        "module": "erm",
        "display_name": "Enterprise Risk Management",
        "submodules": [
            {
                "name": "risks",
                "display_name": "ERM Risks",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "incidents",
                "display_name": "Incidents",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "internal_controls",
                "display_name": "Internal Controls",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "rcsa",
                "display_name": "RCSA",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "kris",
                "display_name": "Key Risk Indicators",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "mitigation_actions",
                "display_name": "Mitigation Actions",
                "actions": ["view", "create", "edit", "delete"]
            }
        ]
    },
    {
        "module": "controls",
        "display_name": "Control Library",
        "submodules": [
            {
                "name": "control_library",
                "display_name": "Control Library",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "control_testing",
                "display_name": "Control Testing",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "control_mapping",
                "display_name": "Control Mapping",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "gap_analysis",
                "display_name": "Gap Analysis",
                "actions": ["view", "create", "edit"]
            }
        ]
    },
    {
        "module": "compliance",
        "display_name": "Compliance",
        "submodules": [
            {
                "name": "assessments",
                "display_name": "Compliance Assessments",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "statements",
                "display_name": "Compliance Statements",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "frameworks",
                "display_name": "Frameworks",
                "actions": ["view", "create", "edit", "delete"]
            },
            # CIS integration: three scanning permissions gated by the
            # `Scanning Admin` preset role. Administrators auto-bypass; any
            # other role needs the explicit grant. Names match exactly what
            # the new module routers check via require_tenant_permission(...).
            {
                "name": "scan",
                "display_name": "Compliance Scans (CIS)",
                "actions": ["execute"]
            },
            {
                "name": "agents",
                "display_name": "Compliance Agents",
                "actions": ["manage"]
            },
            {
                "name": "discover",
                "display_name": "Bulk Host Discovery",
                "actions": ["execute"]
            }
        ]
    },
    {
        "module": "vulnerabilities",
        "display_name": "Vulnerability Management",
        "submodules": [
            {
                "name": "vulnerability_register",
                "display_name": "Vulnerability Register",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "remediation",
                "display_name": "Remediation",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "sla_management",
                "display_name": "SLA Management",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "reports",
                "display_name": "Reports",
                "actions": ["view", "create"]
            }
        ]
    },
    {
        # AVA AI-Pentest. Write-endpoints are gated in
        # backend/grc/modules/pentest/router.py via _require_scan
        # (pentest:scan:execute) and _require_exploit (pentest:exploit:execute).
        # Those two dependencies FAIL OPEN until any pentest:* permission exists
        # in the tenant, so adding this module never locks out existing users;
        # Administrator + primary-contact bypass as everywhere. run:execute /
        # gate:approve / view are declared here for finer-grained role design and
        # appear in the Admin > Roles matrix.
        "module": "pentest",
        "display_name": "AI Pentest (AVA)",
        "submodules": [
            {"name": "scan", "display_name": "Run Scans", "actions": ["execute"]},
            {"name": "exploit", "display_name": "Run Exploits", "actions": ["execute"]},
            {"name": "run", "display_name": "Batch Runs", "actions": ["execute"]},
            {"name": "gate", "display_name": "Approve Exploit Gate", "actions": ["approve"]},
            {"name": "workspace", "display_name": "Pentest Workspace", "actions": ["view"]},
        ]
    },
    {
        "module": "assets",
        "display_name": "Asset Management",
        "submodules": [
            {
                "name": "asset_inventory",
                "display_name": "Asset Inventory",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "asset_classification",
                "display_name": "Asset Classification",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                # Criticality Assessments (ISCA + IACA per the bank
                # templates). `approve_ciso` is the dedicated tier-3
                # sign-off permission — keep it distinct from `edit` so
                # business owners can act at tier 2 without doubling as
                # the CISO.
                "name": "criticality_assessments",
                "display_name": "Criticality Assessments",
                "actions": ["view", "create", "edit", "delete", "approve_ciso"]
            }
        ]
    },
    {
        "module": "workflow_engine",
        "display_name": "Workflow Automation Engine",
        "submodules": [
            {
                "name": "definitions",
                "display_name": "Workflow Definitions",
                "actions": ["view", "create", "edit", "delete", "publish"]
            },
            {
                "name": "templates",
                "display_name": "Workflow Templates",
                "actions": ["view", "create", "edit", "delete", "publish"]
            },
            {
                "name": "executions",
                "display_name": "Workflow Executions",
                "actions": ["view", "create", "edit", "approve", "cancel"]
            },
            {
                "name": "integrations",
                "display_name": "Workflow Integrations",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "analytics",
                "display_name": "Workflow Analytics",
                "actions": ["view", "export"]
            },
            {
                "name": "ai",
                "display_name": "Workflow AI",
                "actions": ["view", "create", "edit"]
            }
        ]
    },
    {
        "module": "reports",
        "display_name": "Reports & Analytics",
        "submodules": [
            {
                "name": "dashboards",
                "display_name": "Dashboards",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "reports",
                "display_name": "Reports",
                "actions": ["view", "create", "edit", "delete", "export"]
            },
            {
                "name": "analytics",
                "display_name": "Analytics",
                "actions": ["view"]
            }
        ]
    },
    {
        "module": "admin",
        "display_name": "Administration",
        "submodules": [
            {
                "name": "organization",
                "display_name": "Organization Profile",
                "actions": ["view", "edit"]
            },
            {
                "name": "users",
                "display_name": "User Management",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "roles",
                "display_name": "Role Management",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "permissions",
                "display_name": "Permission Management",
                "actions": ["view", "assign"]
            },
            {
                "name": "audit_logs",
                "display_name": "Audit Logs",
                "actions": ["view"]
            },
            {
                "name": "settings",
                "display_name": "Settings",
                "actions": ["view", "edit"]
            },
            {
                "name": "integrations_sso",
                "display_name": "Identity Providers (SSO)",
                "actions": ["view", "manage"]
            }
        ]
    },
    {
        "module": "integrations",
        "display_name": "Integrations",
        "submodules": [
            {
                "name": "connections",
                "display_name": "Scanner Connections",
                "actions": ["view", "create", "edit", "delete"]
            },
            {
                "name": "exceptions",
                "display_name": "Vulnerability Exceptions",
                "actions": ["view", "create", "edit", "delete", "approve", "reject"]
            },
            {
                "name": "sync",
                "display_name": "Sync Management",
                "actions": ["view", "trigger"]
            },
            {
                "name": "analytics",
                "display_name": "Integration Analytics",
                "actions": ["view"]
            }
        ]
    },
    {
        # Help Desk (AVA-native ITSM). Agent gates (helpdesk:tickets:view/edit)
        # are already enforced across the HD routers via common.require_view /
        # require_edit; this block makes the module grantable in the Admin > Roles
        # matrix and adds the end-user `requests` scope (raise + track-own + KB)
        # so a tenant can give employees a requester-only view, not the full
        # agent console. Administrator + primary-contact bypass as everywhere.
        # Preset roles seeded per-tenant by helpdesk_native.itsm_seed.seed_hd_roles.
        "module": "helpdesk",
        "display_name": "Help Desk",
        "submodules": [
            {"name": "requests", "display_name": "My Requests (end user)",
             "actions": ["create", "view_own"]},
            {"name": "tickets", "display_name": "Tickets (agent queue)",
             "actions": ["view", "create", "edit", "delete", "assign"]},
            {"name": "processes", "display_name": "Incidents / Problems / Changes / Service Requests",
             "actions": ["view", "manage"]},
            {"name": "kb", "display_name": "Knowledge Base",
             "actions": ["view", "author"]},
            {"name": "settings", "display_name": "Help Desk Settings & SLA",
             "actions": ["view", "manage"]},
        ]
    }
]


def get_all_permissions() -> list:
    permissions = []
    for module_data in PERMISSION_MATRIX:
        module = module_data["module"]
        module_display = module_data["display_name"]
        for submodule_data in module_data.get("submodules", []):
            submodule = submodule_data["name"]
            submodule_display = submodule_data["display_name"]
            for action in submodule_data.get("actions", []):
                perm_name = f"{module}:{submodule}:{action}"
                permissions.append({
                    "name": perm_name,
                    "module": module,
                    "module_display": module_display,
                    "submodule": submodule,
                    "submodule_display": submodule_display,
                    "action": action,
                    "description": f"{action.replace('_', ' ').title()} {submodule_display}"
                })
    return permissions


def get_permission_matrix_for_ui() -> list:
    result = []
    for module_data in PERMISSION_MATRIX:
        module_item = {
            "module": module_data["module"],
            "display_name": module_data["display_name"],
            "submodules": []
        }
        for submodule_data in module_data.get("submodules", []):
            submodule_item = {
                "name": submodule_data["name"],
                "display_name": submodule_data["display_name"],
                "actions": submodule_data.get("actions", [])
            }
            module_item["submodules"].append(submodule_item)
        result.append(module_item)
    return result
