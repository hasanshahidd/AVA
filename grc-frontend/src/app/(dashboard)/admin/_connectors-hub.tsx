'use client';

// One Connectors page with category filter-tabs. Each tab reuses the existing
// screen for that connector type.
//
// Scope (verified against the connector registry to avoid duplication):
//  • External Connectors already carries Identity (Entra, Okta), SIEM, EDR,
//    Ticketing, Pen-test, Collab, Transcription, EASM — so there is NO separate
//    "Identity / SSO" category here (that was a duplicate of the identity one).
//  • Cloud (AWS/Azure/GCP) and Vulnerability Scanners (Nessus/Nexpose) have no
//    providers in External Connectors, so they are genuine, non-duplicated tabs.
//  • Discovery Hosts (SSH/WinRM/SNMP) is the IT Asset Discovery → Connections
//    flow — it lives there, not on this admin page.
import { useState } from 'react';
import { Plug, Server, Cloud, type LucideIcon } from 'lucide-react';
import ConnectorsPage from './connectors/page';
import IntegrationsConnectionsPage from '../integrations/connections/page';
import CloudConnectorsPage from './cloud-connectors/page';

export type ConnectorCategory = 'external' | 'scanners' | 'cloud';

const CATEGORIES: { id: ConnectorCategory; label: string; icon: LucideIcon }[] = [
  { id: 'external', label: 'External Connectors', icon: Plug },
  { id: 'scanners', label: 'Vulnerability Scanners', icon: Server },
  { id: 'cloud', label: 'Cloud', icon: Cloud },
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
      </div>
    </div>
  );
}
