'use client';

/**
 * CIS Benchmark — the two CIS pages behind the IT Asset Inventory "CIS Benchmark"
 * tab, as a sub-toggle:
 *   • Dashboard          — rich, estate-wide CIS compliance dashboard (CisDashboard)
 *   • Benchmark Hierarchy — the hierarchical rule library the owner maintains
 *                           (family → product → build → benchmark → section → rule)
 * Each view is a self-contained panel (own background + data fetching); this
 * container only owns the toggle.
 */

import { useState, type ReactNode } from 'react';
import { LayoutDashboard, ListTree } from 'lucide-react';
import CisDashboard from './CisDashboard';
import CisHierarchy from './CisHierarchy';

type CisView = 'dashboard' | 'hierarchy';

export default function CisBenchmark() {
  const [view, setView] = useState<CisView>('dashboard');
  return (
    <div>
      <div className="mb-3 flex items-center gap-1.5">
        <SubTab active={view === 'dashboard'} onClick={() => setView('dashboard')} icon={<LayoutDashboard size={14} />}>
          Dashboard
        </SubTab>
        <SubTab active={view === 'hierarchy'} onClick={() => setView('hierarchy')} icon={<ListTree size={14} />}>
          Benchmark Hierarchy
        </SubTab>
      </div>
      {view === 'dashboard' ? <CisDashboard /> : <CisHierarchy />}
    </div>
  );
}

function SubTab({
  active,
  onClick,
  icon,
  children,
}: {
  active: boolean;
  onClick: () => void;
  icon: ReactNode;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-[13px] font-medium transition-colors ${
        active
          ? 'bg-[var(--color-base)] text-white'
          : 'border border-slate-200 bg-white text-slate-600 hover:bg-slate-50'
      }`}
    >
      {icon}
      {children}
    </button>
  );
}
