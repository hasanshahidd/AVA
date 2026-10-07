'use client';

import { useState } from 'react';
import { useSearchParams } from 'next/navigation';
import { Building2, Users as UsersIcon, ShieldCheck, ScrollText, KeyRound, Lock, UsersRound, Server } from 'lucide-react';
import OrganizationProfilePage from './organization/page';
import UsersManagementPage from './users/page';
import RolesManagementPage from './roles/page';
import TeamsAdminPage from './teams/page';
import AuditLogsPage from './audit-logs/page';
import PasswordPolicyPage from './password-policy/page';
import IntegrationsConnectionsPage from '../integrations/connections/page';
import { IdentityProvidersCard } from '@/components/integrations/IdentityProvidersCard';

type AdminTab = 'company' | 'users' | 'roles' | 'teams' | 'identity' | 'password-policy' | 'integrations' | 'audit';

const VALID_ADMIN_TABS = new Set<AdminTab>([
  'company','users','roles','teams','identity','password-policy',
  'integrations','audit',
]);

export default function AdminPage() {
  const searchParams = useSearchParams();
  // Sidebar Administration popover deep-links via ?tab=<id>. Default
  // landing stays 'company' when no/invalid param is given — preserves
  // existing behavior for anyone hitting /admin without a query string.
  const initialTab = (() => {
    const raw = searchParams?.get('tab');
    if (raw && VALID_ADMIN_TABS.has(raw as AdminTab)) return raw as AdminTab;
    return 'company';
  })();
  const [activeTab, setActiveTab] = useState<AdminTab>(initialTab);

  const adminTabs: { id: AdminTab; label: string; icon: typeof Building2 }[] = [
    { id: 'company', label: 'Company', icon: Building2 },
    { id: 'users', label: 'User Management', icon: UsersIcon },
    { id: 'roles', label: 'Role Management', icon: ShieldCheck },
    // Org teams — used as owning_team dropdown on assets + future ownership chains.
    { id: 'teams', label: 'Teams', icon: UsersRound },
    { id: 'identity', label: 'Identity Providers', icon: KeyRound },
    // Password & session policy — controls complexity, lockout, and idle timeout.
    { id: 'password-policy', label: 'Password Policy', icon: Lock },
    // Vulnerability scanner consoles — Rapid7 Nexpose / Tenable Nessus ingest.
    { id: 'integrations', label: 'Vulnerability Scanners', icon: Server },
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
        {activeTab === 'identity' && <IdentityProvidersCard />}
        {activeTab === 'password-policy' && <PasswordPolicyPage />}
        {activeTab === 'integrations' && <IntegrationsConnectionsPage />}
        {activeTab === 'audit' && <AuditLogsPage />}
      </div>
      </div>
    </div>
  );
}
