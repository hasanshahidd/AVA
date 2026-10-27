'use client';

// One Connectors page with category filter-tabs. Each tab reuses the existing
// screen for that connector type — the fragmentation (separate Identity
// Providers / Vulnerability Scanners admin tabs + standalone connectors/cloud
// pages) collapses into a single entry point. SSO stays a distinct category
// (it's sign-in config, not a data connector) but lives here like the rest.
import { useState } from 'react';
import { Plug, Server, Cloud, Network, KeyRound, type LucideIcon } from 'lucide-react';
import ConnectorsPage from './connectors/page';
import IntegrationsConnectionsPage from '../integrations/connections/page';
import CloudConnectorsPage from './cloud-connectors/page';
import ConnectWizardPage from './integrations/connect/page';
import { IdentityProvidersCard } from '@/components/integrations/IdentityProvidersCard';

export type ConnectorCategory = 'external' | 'scanners' | 'cloud' | 'hosts' | 'identity';

const CATEGORIES: { id: ConnectorCategory; label: string; icon: LucideIcon }[] = [
  { id: 'external', label: 'External Connectors', icon: Plug },
  { id: 'scanners', label: 'Vulnerability Scanners', icon: Server },
  { id: 'cloud', label: 'Cloud', icon: Cloud },
  { id: 'hosts', label: 'Discovery Hosts', icon: Network },
  { id: 'identity', label: 'Identity / SSO', icon: KeyRound },
];

export default function ConnectorsHub({ initialCategory = 'external' }: { initialCategory?: ConnectorCategory }) {
  const [cat, setCat] = useState<ConnectorCategory>(initialCategory);
  return (
    <div className="space-y-4">
      <div>
        <h1 className="text-xl font-semibold text-slate-900">Connectors</h1>
        <p className="mt-0.5 text-sm text-slate-500">Every integration in one place — pick a category to connect or manage.</p>
      </div>
      {/* category filter */}
      <div className="flex flex-wrap items-center gap-1.5 border-b border-slate-200 pb-3">
        {CATEGORIES.map(({ id, label, icon: Icon }) => {
          const active = cat === id;
          return (
            <button
              key={id}
              type="button"
              onClick={() => setCat(id)}
              className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-medium transition ${
                active
                  ? 'border-primary-600 bg-primary-50 text-primary-700'
                  : 'border-slate-200 text-slate-600 hover:bg-slate-50'
              }`}
            >
              <Icon size={13} />
              {label}
            </button>
          );
        })}
      </div>
      <div>
        {cat === 'external' && <ConnectorsPage />}
        {cat === 'scanners' && <IntegrationsConnectionsPage />}
        {cat === 'cloud' && <CloudConnectorsPage />}
        {cat === 'hosts' && <ConnectWizardPage embedded />}
        {cat === 'identity' && <IdentityProvidersCard />}
      </div>
    </div>
  );
}
