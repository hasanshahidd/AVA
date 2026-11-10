'use client';

/*
 * Asset change history: filter bar (search / category / source / contributor),
 * a day-grouped timeline of full field-level entries, and a summary rail.
 * variant="page" → two columns (timeline + rail), one column on narrow screens.
 * variant="tab"  → single column with a compact stat strip (asset History tab).
 */

import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Download, Search, X } from 'lucide-react';
import { entityExtrasApi } from '@/lib/api';
import { GuideMarker } from '@/components/guide';
import ChangeEntryCard from './ChangeEntryCard';
import SummaryRail from './SummaryRail';
import {
  BORDER, CATEGORY_ORDER, FAINT, INK, MUTED, SEC, NO_FILTERS, SOURCE_ORDER, type ChangeEntry, type Filters,
  actorOf, applyFilters, categoryMeta, categoryOfField, dayKey, dayLabel, fieldLabel, fieldsOf, fmtValue, isTelemetry,
  sectionLabel, sectionOf, sourceMeta, sourceOf, summarise,
} from './model';

function Chip({ on, color, label, count, onClick }: {
  on: boolean; color: string; label: string; count: number; onClick: () => void;
}) {
  return (
    <button type="button" onClick={onClick} aria-pressed={on}
      className="inline-flex items-center gap-1.5 h-[27px] px-2.5 rounded-full text-[11.5px] font-semibold whitespace-nowrap transition-colors"
      style={on
        ? { background: color, color: '#fff', border: `1px solid ${color}` }
        : { background: '#fff', color: SEC, border: `1px solid ${BORDER}` }}>
      {!on && <span className="h-[7px] w-[7px] rounded-full" style={{ background: color }} aria-hidden />}
      {label}
      <span className="tabular-nums" style={{ color: on ? 'rgba(255,255,255,.8)' : FAINT }}>{count}</span>
    </button>
  );
}

function csvOf(items: ChangeEntry[]): string {
  // Values come from scans/connectors/agents; a leading = + - @ would run as a spreadsheet formula.
  const esc = (v: unknown) => {
    const s = String(v ?? '');
    return `"${(/^\s*[=+\-@]|^[\t\r]/.test(s) ? `'${s}` : s).replace(/"/g, '""')}"`;
  };
  const rows = [['Date', 'Time', 'Who', 'Source', 'Category', 'Section', 'Field', 'Change', 'Before', 'After']];
  for (const e of items) {
    const d = e.created_at ? new Date(e.created_at) : null;
    const base = [d ? d.toISOString().slice(0, 10) : '', d ? d.toISOString().slice(11, 19) + 'Z' : '',
      actorOf(e), sourceMeta(sourceOf(e)).label];
    const fs = fieldsOf(e);
    if (!fs.length) rows.push([...base, '', '', e.action, '', '', e.detail ?? '']);
    for (const f of fs) {
      rows.push([...base, categoryMeta(categoryOfField(f)).label, isTelemetry(f) ? sectionLabel(sectionOf(f)) : '',
        fieldLabel(f), f.change || 'changed', fmtValue(f.old, f.old_label), fmtValue(f.new, f.new_label)]);
    }
  }
  return rows.map((r) => r.map(esc).join(',')).join('\n');
}

function download(name: string, text: string) {
  const url = URL.createObjectURL(new Blob([text], { type: 'text/csv;charset=utf-8' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  a.click();
  URL.revokeObjectURL(url);
}

export default function ChangeHistory({ assetId, variant }: { assetId: number; variant: 'page' | 'tab' }) {
  const [filters, setFilters] = useState<Filters>(NO_FILTERS);
  const patch = (p: Partial<Filters>) => setFilters((f) => ({ ...f, ...p }));

  const q = useQuery({
    queryKey: ['entity-history', 'asset', assetId],
    queryFn: async () => (await entityExtrasApi.history('asset', assetId)).data as ChangeEntry[],
  });
  const items = useMemo(() => q.data ?? [], [q.data]);
  const summary = useMemo(() => summarise(items), [items]);
  const shown = useMemo(() => applyFilters(items, filters), [items, filters]);

  const days = useMemo(() => {
    const out: { key: string; label: string; entries: ChangeEntry[] }[] = [];
    for (const e of shown) {
      const key = dayKey(e.created_at);
      const last = out[out.length - 1];
      if (last && last.key === key) last.entries.push(e);
      else out.push({ key, label: dayLabel(e.created_at), entries: [e] });
    }
    return out;
  }, [shown]);

  const catCounts = new Map(summary.byCategory);
  const srcCounts = new Map(summary.bySource);
  const filtered = filters.category !== 'all' || filters.source !== 'all' || filters.actor !== 'all' || !!filters.query.trim();

  const toolbar = (
    <div className="rounded-[12px] bg-white p-3 space-y-2.5" style={{ border: `1px solid ${BORDER}` }}>
      <div className="flex flex-wrap items-center gap-2">
        <label className="relative flex-1 min-w-[200px]">
          <span className="sr-only">Search changes</span>
          <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: FAINT }} aria-hidden />
          <input value={filters.query} onChange={(e) => patch({ query: e.target.value })}
            placeholder="Search field, value or person…"
            className="w-full h-[34px] rounded-[9px] pl-8 pr-3 text-[12.5px] outline-none focus:ring-2 focus:ring-[#19A8E6]/40"
            style={{ border: `1px solid ${BORDER}`, color: INK }} />
        </label>
        {summary.byActor.length > 1 && (
          <select value={filters.actor} onChange={(e) => patch({ actor: e.target.value })} aria-label="Filter by contributor"
            className="h-[34px] rounded-[9px] px-2.5 text-[12.5px] bg-white" style={{ border: `1px solid ${BORDER}`, color: SEC }}>
            <option value="all">All contributors</option>
            {summary.byActor.map(([a, n]) => <option key={a} value={a}>{a} ({n})</option>)}
          </select>
        )}
        <button type="button" onClick={() => download(`asset-${assetId}-change-history.csv`, csvOf(shown))}
          disabled={!shown.length}
          className="inline-flex items-center gap-1.5 h-[34px] px-3 rounded-[9px] text-[12.5px] font-semibold text-white disabled:opacity-40"
          style={{ background: '#005B96' }}>
          <Download className="h-4 w-4" aria-hidden /> Export CSV
        </button>
      </div>
      <div className="flex flex-wrap items-center gap-1.5">
        <span className="text-[10px] font-bold uppercase tracking-[0.06em] w-[64px]" style={{ color: FAINT }}>Category</span>
        <Chip on={filters.category === 'all'} color={INK} label="All" count={summary.fieldChanges} onClick={() => patch({ category: 'all' })} />
        {CATEGORY_ORDER.filter((c) => catCounts.has(c)).map((c) => (
          <Chip key={c} on={filters.category === c} color={categoryMeta(c).color} label={categoryMeta(c).label}
            count={catCounts.get(c) ?? 0} onClick={() => patch({ category: filters.category === c ? 'all' : c })} />
        ))}
      </div>
      <div className="flex flex-wrap items-center gap-1.5">
        <span className="text-[10px] font-bold uppercase tracking-[0.06em] w-[64px]" style={{ color: FAINT }}>Source</span>
        <Chip on={filters.source === 'all'} color={INK} label="All" count={summary.entries} onClick={() => patch({ source: 'all' })} />
        {[...SOURCE_ORDER, ...Array.from(srcCounts.keys()).filter((s) => !SOURCE_ORDER.includes(s))]
          .filter((s) => srcCounts.has(s)).map((s) => (
            <Chip key={s} on={filters.source === s} color={sourceMeta(s).color} label={sourceMeta(s).label}
              count={srcCounts.get(s) ?? 0} onClick={() => patch({ source: filters.source === s ? 'all' : s })} />
          ))}
      </div>
      <div className="flex items-center justify-between text-[11.5px]" style={{ color: MUTED }}>
        <span>Showing <b style={{ color: INK }}>{shown.length}</b> of {items.length} change{items.length === 1 ? '' : 's'}</span>
        {filtered && (
          <button type="button" onClick={() => setFilters(NO_FILTERS)} className="inline-flex items-center gap-1 font-semibold" style={{ color: '#005B96' }}>
            <X className="h-3.5 w-3.5" aria-hidden /> Clear filters
          </button>
        )}
      </div>
    </div>
  );

  const timeline = (
    <div className="relative">
      <div className="absolute left-[7px] top-2 bottom-2 w-[2px]" style={{ background: BORDER }} aria-hidden />
      {days.map((d) => (
        <section key={d.key} className="relative pl-6 pb-2">
          <h3 className="sticky top-0 z-[2] -ml-6 pl-6 py-2 text-[11px] font-bold uppercase tracking-[0.06em] bg-[#F7F9FB]"
            style={{ color: SEC }}>
            <span className="absolute left-[2px] top-1/2 -translate-y-1/2 h-3 w-3 rounded-full bg-white"
              style={{ border: '2px solid #005B96' }} aria-hidden />
            {d.label}
            <span className="ml-2 font-semibold normal-case tracking-normal" style={{ color: FAINT }}>
              {d.entries.length} change{d.entries.length === 1 ? '' : 's'}
            </span>
          </h3>
          <div className="space-y-2.5">
            {d.entries.map((e) => <ChangeEntryCard key={e.id} entry={e} />)}
          </div>
        </section>
      ))}
    </div>
  );

  const header = (
    <div className="flex items-center gap-1.5 text-[11px]" style={{ color: MUTED }}>
      Immutable journal of every field change — manual edits, scans, network discovery, connectors, agents and imports.
      <GuideMarker id="asset.historyWhy" n={1} />
      <GuideMarker id="asset.historyActor" n={2} />
      <GuideMarker id="asset.historyImmutable" n={3} />
      <GuideMarker id="asset.historyAudit" n={4} />
    </div>
  );

  let body;
  if (q.isLoading) body = <p className="py-10 text-center text-[13px]" style={{ color: FAINT }}>Loading change history…</p>;
  else if (q.isError) body = <p className="py-10 text-center text-[13px]" style={{ color: '#B23A3A' }}>Could not load change history. Try again shortly.</p>;
  else if (!items.length) {
    body = (
      <div className="rounded-[12px] bg-white py-12 px-6 text-center" style={{ border: `1px dashed ${BORDER}` }}>
        <p className="text-[14px] font-semibold" style={{ color: INK }}>No changes recorded yet</p>
        <p className="text-[12.5px] mt-1" style={{ color: MUTED }}>
          Every change from here on, whether an edit, scan, network discovery, connector sync, agent report or import, appears here with before and after values.
        </p>
      </div>
    );
  } else {
    body = shown.length ? timeline : (
      <p className="py-10 text-center text-[13px]" style={{ color: FAINT }}>No changes match these filters.</p>
    );
  }

  if (variant === 'tab') {
    return (
      <div className="space-y-3">
        {header}
        {items.length > 0 && (
          <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
            {[['Changes', summary.entries], ['Field edits', summary.fieldChanges],
              ['Contributors', summary.byActor.length], ['Sources', summary.bySource.length]].map(([l, v]) => (
              <div key={l as string} className="rounded-[10px] bg-white px-3 py-2" style={{ border: `1px solid ${BORDER}` }}>
                <div className="text-[10px] font-semibold uppercase tracking-[0.05em]" style={{ color: MUTED }}>{l}</div>
                <div className="text-[18px] font-semibold" style={{ color: INK }}>{v}</div>
              </div>
            ))}
          </div>
        )}
        {items.length > 0 && toolbar}
        {body}
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {header}
      <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_320px] gap-4 items-start">
        <div className="space-y-3 min-w-0">
          {items.length > 0 && toolbar}
          {body}
        </div>
        {items.length > 0 && (
          <aside className="lg:sticky lg:top-3" aria-label="Change summary">
            <SummaryRail summary={summary} filters={filters} onFilter={patch} />
          </aside>
        )}
      </div>
    </div>
  );
}
