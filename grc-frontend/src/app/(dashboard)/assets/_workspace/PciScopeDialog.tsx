'use client';

/**
 * Opened when an asset is ticked into PCI scope from the register: captures the
 * same PCI DSS attributes the asset's Edit form shows (shared PciAttributesFields),
 * so marking an asset in scope and describing its cardholder data happen together.
 */

import React, { useState } from 'react';
import { Loader2, X } from 'lucide-react';
import PciAttributesFields from '@/components/assets/PciAttributesFields';
import { ITAsset } from '@/types';

export default function PciScopeDialog({
  asset,
  onClose,
  onSave,
  isSaving,
}: {
  asset: ITAsset;
  onClose: () => void;
  onSave: (pciDss: Record<string, string>) => void;
  isSaving: boolean;
}) {
  const [pci, setPci] = useState<Record<string, string>>(((asset as any).pci_dss || {}) as Record<string, string>);

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4" onClick={onClose}>
      <div className="w-full max-w-xl rounded-xl bg-white shadow-2xl" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between border-b border-slate-200 px-5 py-3">
          <div>
            <h2 className="text-sm font-semibold text-slate-900">Mark in PCI scope</h2>
            <p className="text-xs text-slate-500">{asset.name}</p>
          </div>
          <button type="button" onClick={onClose} className="text-slate-500 hover:text-slate-900" aria-label="Close">
            <X size={18} />
          </button>
        </div>
        <div className="px-5 py-4">
          <PciAttributesFields value={pci} onChange={(patch) => setPci({ ...pci, ...patch } as Record<string, string>)} />
        </div>
        <div className="flex justify-end gap-2 border-t border-slate-200 px-5 py-3">
          <button type="button" onClick={onClose} className="rounded-lg border border-slate-200 px-4 py-2 text-sm text-slate-700 hover:bg-slate-50">
            Cancel
          </button>
          <button
            type="button"
            disabled={isSaving}
            onClick={() => onSave(pci)}
            className="flex items-center gap-2 rounded-lg bg-blue-600 px-4 py-2 text-sm text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {isSaving && <Loader2 className="h-4 w-4 animate-spin" />}
            Save PCI scope
          </button>
        </div>
      </div>
    </div>
  );
}
