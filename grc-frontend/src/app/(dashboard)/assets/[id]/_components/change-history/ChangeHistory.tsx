'use client';

/*
 * Asset change history, two views:
 *   Fields   (default) — every field of the asset by category, each with its
 *            own track: current value, last change or "No change" (FieldTracker).
 *   Activity — KPI strip → filter bar → day-grouped timeline (+ Insights card
 *            on the full page).
 *   variant="page" → timeline + Insights column (stacked on narrow screens).
 *   variant="tab"  → single column for the asset record's History tab.
 * KpiStrip / FilterBar / Timeline / csvOf are shared with the estate-wide
 * Inventory → Asset history feed (assets/_overview/AssetHistoryFeed.tsx).
 */

import { useMemo, useState, type ReactNode } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Download, Search, X } from 'lucide-react';
import { entityExtrasApi } from '@/lib/api';
import { GuideMarker } from '@/components/guide';
import { FilterSelect } from '../../../_workspace/FilterSelect';
import '../../../inventory-redesign.css';   // .inv2 tokens: .seg / .btn / .search / .fsel
import ChangeEntryCard from './ChangeEntryCard';
import FieldTracker from './FieldTracker';
import SummaryRail from './SummaryRail';
import {
  BORDER, CATEGORY_ORDER, DIVIDER, INK, MUTED, NO_FILTERS, PERIODS, SEC, SOURCE_ORDER, type ChangeEntry, type Filters,
  type Summary, withUtc, actorOf, applyFilters, categoryMeta, categoryOfField, fieldLabel, fieldsOf, fmtDate, fmtValue,
  dayKey, fmtTime, groupByDay, isTelemetry, relTime, sectionLabel, sectionOf, sourceMeta, sourceOf, summarise,
} from './model';

export const CARD_STYLE = { border: `1px solid ${BORDER}`, boxShadow: '0 1px 2px rgba(16,24,40,.04)' };
const FOCUS = 'focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-[#19A8E6]';

/* ── CSV ─────────────────────────────────────────────────────────────── */

export function csvOf(items: ChangeEntry[], withAsset = false): string {
  // Values come from scans/connectors/agents; a leading = + - @ would run as a spreadsheet formula.
  const esc = (v: unknown) => {
    const s = String(v ?? '');
    return `"${(/^\s*[=+\-@]|^[\t\r]/.test(s) ? `'${s}` : s).replace(/"/g, '""')}"`;
  };
  const head = ['Date (PKT)', 'Time (PKT)', ...(withAsset ? ['Asset'] : []), 'Who', 'Source', 'Category', 'Section', 'Field', 'Change', 'Before', 'After'];
  const rows = [head];
  for (const e of items) {
    const base = [e.created_at ? dayKey(e.created_at) : '', fmtTime(e.created_at, true),
      ...(withAsset ? [e.asset_name ?? ''] : []), actorOf(e), sourceMeta(sourceOf(e)).label];
    const fs = fieldsOf(e);
    if (!fs.length) rows.push([...base, '', '', e.action, '', '', e.detail ?? '']);
    for (const f of fs) {
      const notRecorded = f.change === 'updated';
      rows.push([...base, categoryMeta(categoryOfField(f)).label, isTelemetry(f) ? sectionLabel(sectionOf(f)) : '',
        fieldLabel(f), f.change || 'changed',
        notRecorded ? 'not recorded' : fmtValue(f.old, f.old_label), notRecorded ? 'not recorded' : fmtValue(f.new, f.new_label)]);
    }
  }
  return rows.map((r) => r.map(esc).join(',')).join('\n');
}

export function download(name: string, text: string) {
  const url = URL.createObjectURL(new Blob([text], { type: 'text/csv;charset=utf-8' }));
  const a = document.createElement('a');
  a.href = url;
  a.download = name;
  a.click();
  URL.revokeObjectURL(url);
}

/* ── KPI strip ───────────────────────────────────────────────────────── */

export function KpiStrip({ items }: { items: { label: string; value: ReactNode; sub?: string }[] }) {
  return (
    <div className={`rounded-[12px] bg-white grid grid-cols-2 ${items.length === 5 ? 'md:grid-cols-5' : 'md:grid-cols-4'} overflow-hidden`} style={CARD_STYLE}>
      {items.map((k, i) => (
        <div key={k.label} className={`px-3.5 py-2 min-w-0 ${i % 2 ? 'border-l' : ''} ${i > 1 ? 'border-t md:border-t-0' : ''} ${i > 0 && i % 2 === 0 ? 'md:border-l' : ''}`}
          style={{ borderColor: DIVIDER }}>
          <div className="text-[11.5px]" style={{ color: MUTED }}>{k.label}</div>
          <div className="text-[17px] font-semibold leading-tight tabular-nums truncate" style={{ color: INK }}>{k.value}</div>
          {k.sub && <div className="text-[11px] truncate" style={{ color: MUTED }}>{k.sub}</div>}
        </div>
      ))}
    </div>
  );
}

/* ── Category toggle pages ───────────────────────────────────────────── */

/** The category page to show: the requested one if it has changes, else the first that does. */
export function pickCategory(summary: Summary, requested: string): string {
  const cats = CATEGORY_ORDER.filter((c) => summary.byCategory.some(([k]) => k === c));
  return cats.includes(requested) ? requested : (cats[0] ?? 'all');
}

/** One toggle page per category (same underline tabs as the asset Overview), never one long mixed page. */
export function CategoryTabs({ summary, value, onChange }: { summary: Summary; value: string; onChange: (c: string) => void }) {
  const count = new Map(summary.byCategory);
  const cats = CATEGORY_ORDER.filter((c) => count.has(c));
  if (!cats.length) return null;
  return (
    <div role="tablist" aria-label="Change categories"
      className="flex gap-5 border-b border-[#e8ecee] overflow-x-auto overflow-y-hidden px-0.5">
      {cats.map((c) => {
        const on = value === c;
        return (
          <button key={c} type="button" role="tab" aria-selected={on} onClick={() => onChange(c)}
            className={`text-[12.5px] whitespace-nowrap pb-1.5 -mb-px border-b-2 rounded-t-[4px] ${FOCUS} ${on
              ? 'font-semibold text-[#014A81] border-[#005B96]' : 'font-medium text-[#6b7787] border-transparent hover:text-[#0f1f2b]'}`}>
            {categoryMeta(c).label}
            <span className="ml-1.5 text-[11px] tabular-nums" style={{ color: on ? '#005B96' : MUTED }}>{count.get(c)}</span>
          </button>
        );
      })}
    </div>
  );
}

/* ── Filter bar ──────────────────────────────────────────────────────── */

export type Segmented = { value: string; options: { key: string; label: string }[]; onChange: (v: string) => void; label: string };

export function FilterBar({ filters, patch, summary, showActor = true, period, placeholder, shown, total, onExport }: {
  filters: Filters; patch: (p: Partial<Filters>) => void; summary: Summary; showActor?: boolean;
  period: Segmented; placeholder: string; shown: number; total: number; onExport: () => void;
}) {
  const srcs = [...SOURCE_ORDER, ...summary.bySource.map(([s]) => s).filter((s) => !SOURCE_ORDER.includes(s))]
    .filter((s) => summary.bySource.some(([k]) => k === s));
  const srcCount = new Map(summary.bySource);
  // Category is chosen by the toggle pages above the bar, so it isn't a filter here.
  const filtered = filters.source !== 'all' || filters.actor !== 'all' || !!filters.query.trim();
  return (
    <div className="rounded-[12px] bg-white p-2" style={CARD_STYLE}>
      <div className="flex flex-wrap items-center gap-2">
        <label className="relative flex-1 min-w-[200px] basis-[220px]">
          <span className="sr-only">Search changes</span>
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: MUTED }} aria-hidden />
          <input className="search" value={filters.query} onChange={(e) => patch({ query: e.target.value })}
            placeholder={placeholder} style={{ fontFamily: 'inherit', color: INK }} />
        </label>
        <FilterSelect title="Source" value={filters.source} onChange={(v) => patch({ source: v })} minWidth={190}
          options={[{ value: 'all', label: 'All sources' },
            ...srcs.map((s) => ({ value: s, label: `${sourceMeta(s).label} (${srcCount.get(s)})` }))]} />
        {showActor && summary.byActor.length > 1 && (
          <FilterSelect title="Contributor" value={filters.actor} onChange={(v) => patch({ actor: v })} minWidth={190}
            options={[{ value: 'all', label: 'All contributors' }, ...summary.byActor.map(([a, n]) => ({ value: a, label: `${a} (${n})` }))]} />
        )}
        <div className="segwrap" role="group" aria-label={period.label}>
          {period.options.map((o) => (
            <button key={o.key} type="button" aria-pressed={period.value === o.key} onClick={() => period.onChange(o.key)}
              className={`${period.value === o.key ? 'seg on' : 'seg'} ${FOCUS}`} style={{ height: 28, padding: '0 11px', fontSize: 12 }}>
              {o.label}
            </button>
          ))}
        </div>
        <span className="text-[11.5px] whitespace-nowrap px-1" style={{ color: MUTED }} aria-live="polite">
          <b className="tabular-nums" style={{ color: INK }}>{shown}</b> of {total}
        </span>
        {filtered && (
          <button type="button" onClick={() => patch({ ...NO_FILTERS, period: filters.period, category: filters.category })}
            className={`inline-flex items-center gap-1 text-[11.5px] font-semibold rounded-[6px] ${FOCUS}`} style={{ color: '#005B96' }}>
            <X className="h-3.5 w-3.5" aria-hidden /> Clear
          </button>
        )}
        <button type="button" className={`btn ${FOCUS}`} onClick={onExport} disabled={!shown}
          style={{ height: 30, opacity: shown ? 1 : 0.45 }}>
          <Download className="h-4 w-4" aria-hidden /> Export CSV
        </button>
      </div>
    </div>
  );
}

/* ── Timeline ────────────────────────────────────────────────────────── */

export function Timeline({ items, preview, showAsset }: { items: ChangeEntry[]; preview?: number; showAsset?: boolean }) {
  const days = useMemo(() => groupByDay(items), [items]);
  return (
    <div className="space-y-3">
      {days.map((d) => (
        <section key={d.key} aria-label={`${d.title} ${d.date}`}>
          <h3 className="flex items-baseline gap-2 px-1 mb-1">
            <span className="text-[13px] font-semibold" style={{ color: INK }}>{d.title}</span>
            <span className="text-[12px]" style={{ color: MUTED }}>{d.date}</span>
            <span className="ml-auto text-[11.5px] tabular-nums" style={{ color: MUTED }}>
              {d.entries.length} change{d.entries.length === 1 ? '' : 's'}
            </span>
          </h3>
          <div className="rounded-[12px] bg-white divide-y divide-[#F0F3F5]" style={CARD_STYLE}>
            {d.entries.map((e) => <ChangeEntryCard key={e.id} entry={e} preview={preview} showAsset={showAsset} />)}
          </div>
        </section>
      ))}
    </div>
  );
}

export function StateMessage({ tone = 'muted', children }: { tone?: 'muted' | 'error'; children: ReactNode }) {
  return (
    <p className="py-10 text-center text-[13px]" style={{ color: tone === 'error' ? '#B23A3A' : MUTED }}>{children}</p>
  );
}

export function EmptyCard({ title, children }: { title: string; children: ReactNode }) {
  return (
    <div className="rounded-[14px] bg-white py-12 px-6 text-center" style={{ border: `1px dashed ${BORDER}` }}>
      <p className="text-[14px] font-semibold" style={{ color: INK }}>{title}</p>
      <p className="text-[12.5px] mt-1 max-w-[560px] mx-auto" style={{ color: MUTED }}>{children}</p>
    </div>
  );
}

/* ── Per-asset history ───────────────────────────────────────────────── */

export default function ChangeHistory({ assetId, variant, action }: {
  assetId: number; variant: 'page' | 'tab'; /** e.g. the tab's "Open full history" link, shown beside the intro. */ action?: ReactNode;
}) {
  const [filters, setFilters] = useState<Filters>(NO_FILTERS);
  const [mode, setMode] = useState<'fields' | 'activity'>('fields');
  const patch = (p: Partial<Filters>) => setFilters((f) => ({ ...f, ...p }));

  const q = useQuery({
    queryKey: ['entity-history', 'asset', assetId],
    queryFn: async () => withUtc((await entityExtrasApi.history('asset', assetId)).data as ChangeEntry[]),
  });
  const items = useMemo(() => q.data ?? [], [q.data]);
  const summary = useMemo(() => summarise(items), [items]);
  const view = useMemo(() => ({ ...filters, category: pickCategory(summary, filters.category) }), [filters, summary]);
  const shown = useMemo(() => applyFilters(items, view), [items, view]);

  // No explanatory paragraph: it cost a row of space on every visit. Guide markers stay for the guided tour.
  const intro = (
    <div className="flex items-center gap-1.5">
      <div className="segwrap mr-auto" role="group" aria-label="History view">
        {([['fields', 'Fields'], ['activity', 'Activity']] as const).map(([k, l]) => (
          <button key={k} type="button" aria-pressed={mode === k} onClick={() => setMode(k)}
            className={`${mode === k ? 'seg on' : 'seg'} ${FOCUS}`} style={{ height: 28, padding: '0 12px', fontSize: 12.5 }}>{l}</button>
        ))}
      </div>
      <GuideMarker id="asset.historyWhy" n={1} />
      <GuideMarker id="asset.historyActor" n={2} />
      <GuideMarker id="asset.historyImmutable" n={3} />
      <GuideMarker id="asset.historyAudit" n={4} />
      {action}
    </div>
  );

  let body: ReactNode;
  if (q.isLoading) body = <StateMessage>Loading change history…</StateMessage>;
  else if (q.isError) body = <StateMessage tone="error">Could not load change history. Refresh the page to try again.</StateMessage>;
  else if (!items.length) {
    body = (
      <EmptyCard title="No changes recorded yet">
        Every change from now on, whether an edit, scan, network discovery, connector sync, agent report or import, appears here with its before and after values.
      </EmptyCard>
    );
  } else {
    body = shown.length
      ? <Timeline items={shown} preview={variant === 'tab' ? 4 : 6} />
      : <StateMessage>No changes match these filters.</StateMessage>;
  }

  if (mode === 'fields') {
    return (
      <div className="inv2 space-y-2.5" style={{ color: SEC }}>
        {intro}
        {q.isLoading ? <StateMessage>Loading change history…</StateMessage>
          : q.isError ? <StateMessage tone="error">Could not load change history. Refresh the page to try again.</StateMessage>
            : <FieldTracker assetId={assetId} entries={items} />}
      </div>
    );
  }

  const ready = !q.isLoading && !q.isError && items.length > 0;
  const top = ready && (
    <>
      <KpiStrip items={[
        { label: 'Changes', value: summary.entries, sub: summary.first ? `Since ${fmtDate(summary.first)}` : undefined },
        { label: 'Fields changed', value: summary.fieldChanges, sub: `${summary.byCategory.length} categor${summary.byCategory.length === 1 ? 'y' : 'ies'}` },
        { label: 'Contributors', value: summary.byActor.length, sub: `${summary.bySource.length} source${summary.bySource.length === 1 ? '' : 's'}` },
        { label: 'Last change', value: relTime(summary.last), sub: fmtDate(summary.last) },
      ]} />
      <CategoryTabs summary={summary} value={view.category} onChange={(c) => patch({ category: c })} />
      <FilterBar filters={view} patch={patch} summary={summary} placeholder="Search field, value or person"
        period={{ label: 'Period', value: filters.period, options: PERIODS, onChange: (v) => patch({ period: v }) }}
        shown={shown.length} total={items.length}
        onExport={() => download(`asset-${assetId}-change-history.csv`, csvOf(shown))} />
    </>
  );

  if (variant === 'tab') {
    return <div className="inv2 space-y-2.5" style={{ color: SEC }}>{intro}{top}{body}</div>;
  }
  return (
    <div className="inv2 space-y-2.5" style={{ color: SEC }}>
      {intro}
      {top}
      <div className="grid grid-cols-1 lg:grid-cols-[minmax(0,1fr)_256px] gap-3 items-start">
        <div className="min-w-0">{body}</div>
        {ready && (
          <aside className="lg:sticky lg:top-3" aria-label="Insights">
            <SummaryRail summary={summary} filters={view} onFilter={patch} />
          </aside>
        )}
      </div>
    </div>
  );
}
