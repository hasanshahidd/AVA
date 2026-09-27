'use client';

// SBP Offsite IT Asset Inventory — the State Bank of Pakistan 52-field regulatory
// return, as a tab on the asset. NOT a separate store: it reads the SAME asset
// data (discovery + credentialed connect + vuln/pentest scans + vendor patch
// feeds) and lays it into the bank's exact format; anything can be corrected
// here and is kept in a small side-table. Backend: grc/modules/sbp_inventory.
import React, { useMemo, useState } from 'react';
import Link from 'next/link';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Loader2, Save, Download, CheckCircle2, Sparkles, Landmark, Fingerprint, Cpu,
  Database, ShieldCheck, Clock, Plug, Bug, Crosshair, FileText, ChevronDown, RefreshCw,
  ArrowUpRight,
} from 'lucide-react';
import apiClient from '@/lib/api';

type Field = {
  key: string; letter: string; label: string; group: string;
  src: string; editable: boolean; value: any; auto_value: any; overridden: boolean;
};
type Sources = {
  va_findings: number; va_lanes: Record<string, number>; pt_findings: number;
  exploit_runs: number; exploits_confirmed: number; synced_at: string;
};

const GROUP_ICON: Record<string, any> = {
  'Identity': Fingerprint, 'OS & Patching': Cpu, 'Database': Database,
  'Security Controls': ShieldCheck, 'Obsolescence': Clock, 'Integration': Plug,
  'Vulnerability Assessment': Bug, 'Penetration Testing': Crosshair,
  'Justifications': FileText,
};
const IND = '#4F46E5';
// VA / PT run later and get re-run, so each carries its own Sync: the API
// section it re-pulls and the source counts that belong to it
const SYNC: Record<string, { section: 'va' | 'pt'; keys: (keyof Sources)[] }> = {
  'Vulnerability Assessment': { section: 'va', keys: ['va_findings', 'va_lanes'] },
  'Penetration Testing': { section: 'pt', keys: ['pt_findings', 'exploit_runs', 'exploits_confirmed'] },
};
const hhmm = (iso: string) => new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
const isYesNo = (l: string) => /yes\s*\/\s*no/i.test(l);
// "(Yes/No/NA)" and "If Database" columns can legitimately be Not Applicable
const ynOpts = (l: string) => /not applicable|n\/a|\bna\b|if database/i.test(l) ? ['', 'Yes', 'No', 'Not Applicable'] : ['', 'Yes', 'No'];
const filledVal = (v: any) => v !== '' && v !== null && v !== undefined;

function Badge({ kind }: { kind: 'auto' | 'edited' }) {
  const auto = kind === 'auto';
  return (
    <span title={auto ? "Auto-filled by Ava from this asset's scans and vendor feeds" : 'Changed by an analyst — overrides the auto value'}
      className="flex-none rounded px-1.5 py-0.5 text-[9px] font-bold uppercase tracking-wide"
      style={auto ? { background: '#EEF0FF', color: IND } : { background: '#FEF3C7', color: '#92400E' }}>
      {auto ? 'auto' : 'edited'}
    </span>
  );
}

export default function SbpInventoryPanel({ assetId }: { assetId: number }) {
  const qc = useQueryClient();
  const [edits, setEdits] = useState<Record<string, string>>({});
  const [saved, setSaved] = useState(false);
  const [exporting, setExporting] = useState(false);
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({});
  const [sync, setSync] = useState<Record<string, 'busy' | 'failed'>>({});
  const [syncedAt, setSyncedAt] = useState<Record<string, string>>({});

  const { data, isLoading, error } = useQuery({
    queryKey: ['sbp-asset', assetId],
    queryFn: async () => (await apiClient.get(`/sbp-inventory/asset/${assetId}`)).data as
      { asset_id: number; asset_name: string; fields: Field[]; sources?: Sources },
  });

  const save = useMutation({
    mutationFn: async () => (await apiClient.patch(`/sbp-inventory/asset/${assetId}`, edits)).data,
    onSuccess: () => {
      setEdits({}); setSaved(true); setTimeout(() => setSaved(false), 2500);
      qc.invalidateQueries({ queryKey: ['sbp-asset', assetId] });
    },
  });

  // re-pull ONE section — its fields + its own source counts; the rest of the row is untouched
  const syncSection = async (group: string) => {
    const { section, keys } = SYNC[group];
    setSync((s) => ({ ...s, [group]: 'busy' }));
    try {
      const r = (await apiClient.get(`/sbp-inventory/asset/${assetId}`, { params: { section } })).data as
        { fields: Field[]; sources: Sources };
      const fresh = new Map(r.fields.map((f) => [f.key, f]));
      qc.setQueryData(['sbp-asset', assetId], (old: any) => old && {
        ...old,
        fields: old.fields.map((f: Field) => fresh.get(f.key) ?? f),
        sources: { ...old.sources, ...Object.fromEntries(keys.map((k) => [k, r.sources[k]])) },
      });
      setSyncedAt((s) => ({ ...s, [group]: r.sources.synced_at }));
      setSync((s) => { const n = { ...s }; delete n[group]; return n; });
    } catch {
      setSync((s) => ({ ...s, [group]: 'failed' }));
    }
  };

  const exportXlsx = async () => {
    setExporting(true);
    try {
      const res = await apiClient.get('/sbp-inventory/export.xlsx', { responseType: 'blob' });
      const url = URL.createObjectURL(res.data as Blob);
      const a = document.createElement('a');
      a.href = url; a.download = 'SBP_Asset_Inventory.xlsx'; a.click();
      URL.revokeObjectURL(url);
    } finally { setExporting(false); }
  };

  const fields = data?.fields || [];
  const src = data?.sources;
  const curVal = (f: Field) => (edits[f.key] ?? (f.value ?? ''));
  // a field typed back to its saved (or auto) value is no longer an edit — drop
  // it, so Save, its count and the EDITED badge all return to rest
  const setEdit = (f: Field, v: string) => setEdits((e) => {
    const next = { ...e };
    if (v === String(f.value ?? '')) delete next[f.key]; else next[f.key] = v;
    return next;
  });

  const groups = useMemo(() => {
    const g: Record<string, Field[]> = {};
    fields.forEach((f) => { (g[f.group] ||= []).push(f); });
    return g;
  }, [fields]);

  const stats = useMemo(() => {
    const filled = fields.filter((f) => filledVal(curVal(f))).length;
    const auto = fields.filter((f) => filledVal(f.value) && !f.overridden).length;
    const total = fields.length || 52;
    return { filled, auto, total, pct: total ? Math.round((filled / total) * 100) : 0 };
  }, [fields, edits]);

  if (isLoading) return <div className="flex items-center gap-2 p-8 text-sm text-gray-500"><Loader2 className="h-4 w-4 animate-spin" /> Loading SBP inventory…</div>;
  if (error) return <div className="p-8 text-sm text-red-600">Could not load the SBP inventory for this asset.</div>;

  const dirty = Object.keys(edits).length > 0;
  const lanes = src ? Object.entries(src.va_lanes).map(([k, n]) => `${k} ${n}`).join(', ') : '';

  // where the VA / PT columns come from, shown on those two sections ("none
  // yet" when nothing ran — never "synced from 0 findings")
  const groupSource: Record<string, React.ReactNode> = src ? {
    'Vulnerability Assessment': (
      <>{src.va_findings
          ? <>Synced from <b>{src.va_findings}</b> scanner finding{src.va_findings === 1 ? '' : 's'}{lanes ? ` (${lanes})` : ''}</>
          : 'No scans yet'}
        {' · '}<Link href={`/assets/${assetId}?tab=vulnerabilities`} className="inline-flex items-center gap-0.5 font-semibold" style={{ color: IND }}>View findings<ArrowUpRight size={11} /></Link></>
    ),
    'Penetration Testing': (
      <>{src.pt_findings || src.exploit_runs
          ? <>Synced from <b>{src.pt_findings}</b> PentestGPT finding{src.pt_findings === 1 ? '' : 's'} + <b>{src.exploit_runs}</b> exploit run{src.exploit_runs === 1 ? '' : 's'} ({src.exploits_confirmed} confirmed)</>
          : 'No pentests yet'}
        {' · '}<Link href="/pentest" className="inline-flex items-center gap-0.5 font-semibold" style={{ color: IND }}>Open AI Pentest<ArrowUpRight size={11} /></Link></>
    ),
  } : {};

  return (
    <div className="space-y-4">
      {/* ── header: title + completion + actions ── */}
      <div className="rounded-2xl border border-gray-200 bg-gradient-to-br from-indigo-50/70 to-white p-5">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div className="flex items-start gap-3">
            <div className="flex h-11 w-11 flex-none items-center justify-center rounded-xl text-white" style={{ background: IND }}>
              <Landmark size={22} />
            </div>
            <div>
              <h3 className="text-[15px] font-semibold text-gray-900">SBP Offsite IT Asset Inventory</h3>
              <p className="mt-0.5 text-xs text-gray-500">State Bank of Pakistan · 52-field regulatory return · <Sparkles size={11} className="mb-0.5 inline" style={{ color: IND }} /> auto-filled from this asset's scans and vendor patch feeds — correct anything, then Save. Export gives the bank's exact file.</p>
            </div>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <button onClick={exportXlsx} disabled={exporting}
              className="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50">
              {exporting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Download size={15} />} Export
            </button>
            <button onClick={() => save.mutate()} disabled={!dirty || save.isPending}
              title={dirty ? 'Save your corrections' : 'Nothing to save — change any field first'}
              className="inline-flex items-center gap-1.5 rounded-lg px-3.5 py-2 text-sm font-semibold text-white disabled:opacity-50" style={{ background: IND }}>
              {save.isPending ? <Loader2 className="h-4 w-4 animate-spin" /> : saved ? <CheckCircle2 size={15} /> : <Save size={15} />}
              {saved ? 'Saved' : `Save${dirty ? ` (${Object.keys(edits).length})` : ''}`}
            </button>
          </div>
        </div>
        {/* completion meter */}
        <div className="mt-4">
          <div className="mb-1.5 flex flex-wrap items-center justify-between gap-2 text-xs">
            <span className="font-medium text-gray-700">{stats.filled} of {stats.total} fields filled</span>
            <span className="text-gray-500">
              <b style={{ color: IND }}>{stats.auto}</b> auto-filled · {stats.total - stats.filled} blank
              {!dirty && <> · Save activates when you change a field</>}
            </span>
          </div>
          <div className="h-2 w-full overflow-hidden rounded-full bg-gray-200">
            <div className="h-full rounded-full transition-all" style={{ width: `${stats.pct}%`, background: IND }} />
          </div>
        </div>
      </div>

      {/* ── grouped section cards ── */}
      {Object.entries(groups).map(([group, gf]) => {
        const Icon = GROUP_ICON[group] || FileText;
        const gFilled = gf.filter((f) => filledVal(curVal(f))).length;
        const isOpen = !collapsed[group];
        // latest of this section's own Sync and the last full load (ISO strings sort by time)
        const at = (syncedAt[group] || '') > (src?.synced_at || '') ? syncedAt[group] : src?.synced_at;
        return (
          <div key={group} className="overflow-hidden rounded-2xl border border-gray-200 bg-white">
            <button onClick={() => setCollapsed((c) => ({ ...c, [group]: !c[group] }))}
              className="flex w-full items-center justify-between gap-3 px-5 py-3 text-left hover:bg-gray-50">
              <div className="flex items-center gap-2.5">
                <Icon size={16} style={{ color: IND }} />
                <span className="text-sm font-semibold text-gray-800">{group}</span>
                <span className="rounded-full bg-gray-100 px-2 py-0.5 text-[11px] font-medium text-gray-500">{gFilled}/{gf.length}</span>
              </div>
              <ChevronDown size={16} className={`text-gray-400 transition-transform ${isOpen ? '' : '-rotate-90'}`} />
            </button>
            {isOpen && groupSource[group] && (
              // VA / PT run later and get re-run — so these two sections carry
              // their own Sync: it re-pulls only that section's records.
              <div className="flex flex-wrap items-center justify-between gap-2 border-t border-gray-100 bg-indigo-50/40 px-5 py-2 text-[11.5px] text-gray-600">
                <span>
                  {groupSource[group]}
                  {at && <> · synced {hhmm(at)}</>}
                  {sync[group] === 'failed' && <span className="text-red-600"> · sync failed — try again</span>}
                </span>
                <button onClick={() => syncSection(group)} disabled={sync[group] === 'busy'}
                  title={`Pull the latest ${group === 'Penetration Testing' ? 'AI-pentest findings and exploit runs' : 'vulnerability-scan findings'} for this asset`}
                  className="inline-flex items-center gap-1 rounded-md border border-indigo-200 bg-white px-2.5 py-1 text-[11.5px] font-semibold disabled:opacity-50"
                  style={{ color: IND }}>
                  <RefreshCw size={12} className={sync[group] === 'busy' ? 'animate-spin' : ''} />
                  {sync[group] === 'busy' ? 'Syncing…' : 'Sync'}
                </button>
              </div>
            )}
            {isOpen && (
              <div className="divide-y divide-gray-100 border-t border-gray-100">
                {gf.map((f) => {
                  const v = curVal(f);
                  const blankEditable = f.editable && !filledVal(v);
                  const edited = f.overridden || f.key in edits;
                  const badge = edited ? <Badge kind="edited" /> : filledVal(f.value) ? <Badge kind="auto" /> : null;
                  return (
                    <div key={f.key} className="grid grid-cols-[minmax(0,1fr)_minmax(0,1.2fr)] items-center gap-4 px-5 py-2.5">
                      <div className="flex items-baseline gap-2 text-sm text-gray-600">
                        <span className="text-[10px] font-semibold uppercase text-gray-300">{f.letter}</span>
                        <span>{f.label}</span>
                      </div>
                      <div>
                        {f.editable ? (
                          <div className="flex items-center gap-2">
                            {isYesNo(f.label) ? (
                              <select value={v} onChange={(e) => setEdit(f, e.target.value)}
                                className={`w-full max-w-[240px] rounded-lg border px-2.5 py-1.5 text-sm ${blankEditable ? 'border-amber-300 bg-amber-50/40 text-gray-500' : 'border-gray-300 text-gray-900'}`}>
                                {ynOpts(f.label).map((o) => <option key={o} value={o}>{o || '— select —'}</option>)}
                              </select>
                            ) : (
                              <input value={v} onChange={(e) => setEdit(f, e.target.value)}
                                placeholder={filledVal(f.auto_value) ? String(f.auto_value) : '— add —'}
                                className={`w-full rounded-lg border px-2.5 py-1.5 text-sm ${blankEditable ? 'border-amber-300 bg-amber-50/40' : 'border-gray-300 text-gray-900'}`} />
                            )}
                            {badge}
                          </div>
                        ) : (
                          <span className="inline-flex items-center gap-2">
                            {filledVal(f.value)
                              ? <span className="text-sm font-medium text-gray-900">{String(f.value)}</span>
                              : <span className="text-sm text-gray-300">—</span>}
                            {badge}
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        );
      })}
    </div>
  );
}
