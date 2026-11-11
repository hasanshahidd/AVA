'use client';

/*
 * Inventory → Asset history (/assets?tab=history): estate-wide change journal.
 * KPI strip, filters (asset / field search, source, category, period) and a
 * day-grouped feed. Each item names its asset (linking to that asset's own
 * history page) with a one-line summary; the field diffs are the same
 * ChangeEntryCard the per-asset history uses.
 */

import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { entityExtrasApi } from '@/lib/api';
import {
  EmptyCard, FilterBar, KpiStrip, StateMessage, Timeline, csvOf, download,
} from '../[id]/_components/change-history/ChangeHistory';
import {
  MUTED, NO_FILTERS, SEC, type ChangeEntry, type Filters, applyFilters, fmtDate, relTime, summarise,
} from '../[id]/_components/change-history/model';

const WINDOWS = [{ key: '7', label: '7 days' }, { key: '30', label: '30 days' }, { key: '90', label: '90 days' }];
const LIMIT = 300;

export default function AssetHistoryFeed() {
  const [days, setDays] = useState('30');
  const [filters, setFilters] = useState<Filters>(NO_FILTERS);
  const patch = (p: Partial<Filters>) => setFilters((f) => ({ ...f, ...p }));

  const q = useQuery({
    queryKey: ['asset-change-log', Number(days), LIMIT],
    queryFn: async () => (await entityExtrasApi.assetChangeLog(Number(days), LIMIT)).data as ChangeEntry[],
  });
  const items = useMemo(() => q.data ?? [], [q.data]);
  const summary = useMemo(() => summarise(items), [items]);
  const shown = useMemo(() => applyFilters(items, filters), [items, filters]);

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
    <div className="inv2 space-y-3" style={{ color: SEC }}>
      <p className="text-[12px] px-0.5" style={{ color: MUTED }}>
        Every change to every asset across the estate, newest first. Open an asset to see its full history.
      </p>
      <KpiStrip items={[
        { label: 'Changes', value: summary.entries, sub: items.length >= LIMIT ? `Latest ${LIMIT} shown` : `Last ${days} days` },
        { label: 'Assets changed', value: summary.assets },
        { label: 'Fields changed', value: summary.fieldChanges, sub: `${summary.bySource.length} source${summary.bySource.length === 1 ? '' : 's'}` },
        { label: 'Last change', value: relTime(summary.last), sub: summary.last ? fmtDate(summary.last) : undefined },
      ]} />
      <FilterBar filters={filters} patch={patch} summary={summary} showActor={false}
        placeholder="Search asset, field or value"
        period={{ label: 'Period', value: days, options: WINDOWS, onChange: setDays }}
        shown={shown.length} total={items.length}
        onExport={() => download(`asset-history-${days}d.csv`, csvOf(shown, true))} />
      {body}
    </div>
  );
}
