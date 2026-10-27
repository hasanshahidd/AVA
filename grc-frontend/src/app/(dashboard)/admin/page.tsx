'use client';

import { useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { Building2, Users as UsersIcon, ShieldCheck, ScrollText, Lock, UsersRound, Plug } from 'lucide-react';
import OrganizationProfilePage from './organization/page';
import UsersManagementPage from './users/page';
import RolesManagementPage from './roles/page';
import TeamsAdminPage from './teams/page';
import DepartmentsAdminPage from './departments/page';
import AuditLogsPage from './audit-logs/page';
import PasswordPolicyPage from './password-policy/page';
import ConnectorsHub, { type ConnectorCategory } from './_connectors-hub';

type AdminTab = 'company' | 'users' | 'roles' | 'teams' | 'departments' | 'connectors' | 'password-policy' | 'audit';

// Legacy deep-links resolve to the unified Connectors tab with the matching
// category preselected. ?tab=identity → External Connectors (Entra/Okta live
// there); ?tab=integrations (cloud-connectors back-links) → Vulnerability Scanners.
const LEGACY_TAB_CATEGORY: Record<string, ConnectorCategory> = { identity: 'external', integrations: 'scanners' };

const VALID_ADMIN_TABS = new Set<AdminTab>([
  'company','users','roles','teams','departments','connectors','password-policy','audit',
]);

export default function AdminPage() {
  const searchParams = useSearchParams();
  // Sidebar Administration popover deep-links via ?tab=<id>. Default
  // landing stays 'company' when no/invalid param is given — preserves
  // existing behavior for anyone hitting /admin without a query string.
  const rawTab = searchParams?.get('tab') ?? '';
  const initialTab = (() => {
    if (rawTab in LEGACY_TAB_CATEGORY) return 'connectors' as AdminTab;
    if (rawTab && VALID_ADMIN_TABS.has(rawTab as AdminTab)) return rawTab as AdminTab;
    return 'company';
  })();
  const [activeTab, setActiveTab] = useState<AdminTab>(initialTab);
  const connectorsInitialCategory: ConnectorCategory = LEGACY_TAB_CATEGORY[rawTab] ?? 'external';

  const adminTabs: { id: AdminTab; label: string; icon: typeof Building2 }[] = [
    { id: 'company', label: 'Company', icon: Building2 },
    { id: 'users', label: 'User Management', icon: UsersIcon },
    { id: 'roles', label: 'Role Management', icon: ShieldCheck },
    // Org teams — used as owning_team dropdown on assets + future ownership chains.
    { id: 'teams', label: 'Teams', icon: UsersRound },
    // Help-Desk service-desk departments, surfaced in Admin (also visible in HD).
    { id: 'departments', label: 'Departments', icon: Building2 },
    // Password & session policy — controls complexity, lockout, and idle timeout.
    { id: 'password-policy', label: 'Password Policy', icon: Lock },
    // Unified connectors — External Connectors, Vulnerability Scanners, Cloud,
    // Discovery Hosts and Identity/SSO as categories on one page.
    { id: 'connectors', label: 'Connectors', icon: Plug },
    // Tenant-scoped activity trail — who did what, when (audit_log middleware).
    { id: 'audit', label: 'Audit Logs', icon: ScrollText },
  ];

  return (
    <div className="-m-4 lg:-m-5 text-slate-900">
      {/* zoom:0.85 — same density knob the dashboards use; scales the tab bar
          AND every tab's content uniformly so admin cards aren't oversized.
          Kept off the negative-margin wrapper so edge alignment stays exact. */}
      <div style={{ zoom: 0.85 }}>
      <div className="border-b border-slate-200 px-3 sm:px-6 pt-3 overflow-x-auto">
        <div className="flex items-center gap-0 min-w-max">
          {adminTabs.map(({ id, label, icon: Icon }) => {
            const isActive = activeTab === id;
            return (
              <button
                key={id}
                type="button"
                onClick={() => setActiveTab(id)}
                className={`inline-flex items-center gap-1.5 px-3 sm:px-4 py-2.5 text-sm font-medium border-b-2 transition-colors -mb-px whitespace-nowrap ${
                  isActive
                    ? 'border-primary-600 text-primary-700'
                    : 'border-transparent text-slate-500 hover:text-slate-700 hover:border-slate-300'
                }`}
              >
                <Icon size={14} />
                {label}
              </button>
            );
          })}
        </div>
      </div>

      <div className="px-4 sm:px-6 py-4 sm:py-5 space-y-4 sm:space-y-6">
        {activeTab === 'company' && <OrganizationProfilePage />}
        {activeTab === 'users' && <UsersManagementPage />}
        {activeTab === 'roles' && <RolesManagementPage />}
        {activeTab === 'teams' && <TeamsAdminPage />}
        {activeTab === 'departments' && <DepartmentsAdminPage />}
        {activeTab === 'password-policy' && <PasswordPolicyPage />}
        {activeTab === 'connectors' && <ConnectorsHub initialCategory={connectorsInitialCategory} />}
        {activeTab === 'audit' && <AuditLogsPage />}
      </div>
      </div>
    </div>
  );
}
