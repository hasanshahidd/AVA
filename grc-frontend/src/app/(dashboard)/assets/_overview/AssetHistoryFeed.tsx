'use client';

/*
 * Inventory → Asset history (/assets?tab=history): estate-wide change journal,
 * three views:
 *   Dashboard (default) — KPIs, daily volume, categories, sources, most-changed
 *            assets / fields and recent security changes (AssetHistoryDashboard).
 *   Fields   — every field found on any asset, by category; each row
 *            says on how many assets it is set and its last change; a click
 *            opens the field's changes across assets (EstateFieldTracker).
 *   Activity — KPI strip, filters and a day-grouped feed; each item names its
 *            asset and uses the same ChangeEntryCard as the per-asset history.
 */

import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { entityExtrasApi } from '@/lib/api';
import { EstateFieldTracker } from '../[id]/_components/change-history/FieldTracker';
import AssetHistoryDashboard from './AssetHistoryDashboard';
import {
  CategoryTabs, EmptyCard, FilterBar, KpiStrip, StateMessage, Timeline, csvOf, download, pickCategory,
} from '../[id]/_components/change-history/ChangeHistory';
import {
  NO_FILTERS, SEC, withUtc, type ChangeEntry, type Filters, applyFilters, fmtDate, relTime, summarise,
} from '../[id]/_components/change-history/model';

const WINDOWS = [{ key: '7', label: '7 days' }, { key: '30', label: '30 days' }, { key: '90', label: '90 days' }];
const LIMIT = 300;          // Activity feed
const FIELDS_LIMIT = 1000;  // Dashboard and Fields views count changes per field, so it reads the most the API returns
const FOCUS = 'focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-[#19A8E6]';

export default function AssetHistoryFeed() {
  const [days, setDays] = useState('30');
  const [mode, setMode] = useState<'dashboard' | 'fields' | 'activity'>('dashboard');
  const limit = mode === 'activity' ? LIMIT : FIELDS_LIMIT;
  const [filters, setFilters] = useState<Filters>(NO_FILTERS);
  const patch = (p: Partial<Filters>) => setFilters((f) => ({ ...f, ...p }));

  const q = useQuery({
    queryKey: ['asset-change-log', Number(days), limit],
    queryFn: async () => withUtc((await entityExtrasApi.assetChangeLog(Number(days), limit)).data as ChangeEntry[]),
  });
  const items = useMemo(() => q.data ?? [], [q.data]);
  const summary = useMemo(() => summarise(items), [items]);
  const view = useMemo(() => ({ ...filters, category: pickCategory(summary, filters.category) }), [filters, summary]);
  const shown = useMemo(() => applyFilters(items, view), [items, view]);

  const switcher = (
    <div className="segwrap" role="group" aria-label="History view">
      {([['dashboard', 'Dashboard'], ['fields', 'Fields'], ['activity', 'Activity']] as const).map(([k, l]) => (
        <button key={k} type="button" aria-pressed={mode === k} onClick={() => setMode(k)}
          className={`${mode === k ? 'seg on' : 'seg'} ${FOCUS}`} style={{ height: 28, padding: '0 12px', fontSize: 12.5 }}>{l}</button>
      ))}
    </div>
  );
  const period = { label: 'Period', value: days, options: WINDOWS, onChange: setDays };

  if (mode === 'dashboard') {
    return (
      <div className="inv2 space-y-2.5" style={{ color: SEC }}>
        <div className="flex flex-wrap items-center gap-2">
          {switcher}
          <div className="segwrap" role="group" aria-label={period.label}>
            {WINDOWS.map((o) => (
              <button key={o.key} type="button" aria-pressed={days === o.key} onClick={() => setDays(o.key)}
                className={`${days === o.key ? 'seg on' : 'seg'} ${FOCUS}`} style={{ height: 28, padding: '0 11px', fontSize: 12 }}>{o.label}</button>
            ))}
          </div>
        </div>
        {q.isLoading ? <StateMessage>Loading asset history…</StateMessage>
          : q.isError ? <StateMessage tone="error">Could not load asset history. Refresh the page to try again.</StateMessage>
            : !items.length ? (
              <EmptyCard title={`No asset changes in the last ${days} days`}>
                Edits, scans, network discovery, connector syncs, agent reports and imports that change an asset appear here. Try a longer period.
              </EmptyCard>
            ) : <AssetHistoryDashboard items={items} days={Number(days)} capped={items.length >= FIELDS_LIMIT} />}
      </div>
    );
  }

  if (mode === 'fields') {
    return (
      <div className="inv2 space-y-2.5" style={{ color: SEC }}>
        {switcher}
        {q.isLoading ? <StateMessage>Loading asset history…</StateMessage>
          : q.isError ? <StateMessage tone="error">Could not load asset history. Refresh the page to try again.</StateMessage>
            : <EstateFieldTracker entries={items} period={period} capped={items.length >= FIELDS_LIMIT} />}
      </div>
    );
  }

  let body;
  if (q.isLoading) body = <StateMessage>Loading asset history…</StateMessage>;
  else if (q.isError) body = <StateMessage tone="error">Could not load asset history. Refresh the page to try again.</StateMessage>;
  else if (!items.length) {
    body = (
      <EmptyCard title={`No asset changes in the last ${days} days`}>
        Edits, scans, network discovery, connector syncs, agent reports and imports that change an asset appear here. Try a longer period.
      </EmptyCard>
    );
  } else {
    body = shown.length
      ? <Timeline items={shown} preview={3} showAsset />
      : <StateMessage>No changes match these filters.</StateMessage>;
  }

  return (
    <div className="inv2 space-y-2.5" style={{ color: SEC }}>
      {switcher}
      <KpiStrip items={[
        { label: 'Changes', value: summary.entries, sub: items.length >= limit ? `Latest ${limit} shown` : `Last ${days} days` },
        { label: 'Assets changed', value: summary.assets },
        { label: 'Fields changed', value: summary.fieldChanges, sub: `${summary.bySource.length} source${summary.bySource.length === 1 ? '' : 's'}` },
        { label: 'Last change', value: relTime(summary.last), sub: summary.last ? fmtDate(summary.last) : undefined },
      ]} />
      <CategoryTabs summary={summary} value={view.category} onChange={(c) => patch({ category: c })} />
      <FilterBar filters={view} patch={patch} summary={summary} showActor={false}
        placeholder="Search asset, field or value"
        period={period}
        shown={shown.length} total={items.length}
        onExport={() => download(`asset-history-${days}d.csv`, csvOf(shown, true))} />
      {body}
    </div>
  );
}
