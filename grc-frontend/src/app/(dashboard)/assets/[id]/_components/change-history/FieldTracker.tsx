'use client';

/*
 * Field-by-field history, organised like the asset record: one toggle page per
 * category → Asset record fields, then each telemetry section. Every field has
 * its own row:  Field · Current value · Last change (or "No change") · count.
 * Clicking a field opens a popup with its whole track in plain words
 * ("Installed KB5132061", "Owner: Ali → Sara"), when, and which source.
 *
 *   default export FieldTracker      — one asset   (GET /asset-fields/{id})
 *   EstateFieldTracker               — all assets  (GET /asset-field-catalog);
 *                                      "current value" = how many assets hold it,
 *                                      each change names its asset.
 * Live readings (free space, uptime) are listed but marked as not tracked.
 */

import { useMemo, useState } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { ArrowRight, ChevronRight, Search, X } from 'lucide-react';
import { entityExtrasApi } from '@/lib/api';
import { AnimatedModal } from '@/components/ui/AnimatedModal';
import { KpiStrip, StateMessage, CARD_STYLE, type Segmented } from './ChangeHistory';
import { SourceBadge } from './ChangeEntryCard';
import {
  ADD, BORDER, CATEGORY_ORDER, DEL, DIVIDER, FAINT, INK, MUTED, PERIODS, SEC, type ChangeEntry, categoryMeta,
  fmtDate, fmtTime, relTime,
} from './model';
import {
  RECORD_GROUP, type FieldRow, type Track, type TrackChange, buildTracks, currentValue, describeChange, inPeriod, shown,
} from './tracks';

const FOCUS = 'focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-[#19A8E6]';
const ROW_GRID = 'md:grid md:grid-cols-[minmax(150px,1fr)_minmax(0,1.25fr)_minmax(0,1.6fr)_74px] md:items-center md:gap-x-4';
const CHANGE_PAGE = 50;
const ITEM_PREVIEW = 50;

type View = { track: Track; changes: TrackChange[] };
const catOf = (t: Track) => (CATEGORY_ORDER.includes(t.category) ? t.category : 'other');

/* ── popup: one field's whole track ───────────────────────────────────── */

function Change({ t, c, estate }: { t: Track; c: TrackChange; estate: boolean }) {
  const d = describeChange(t, c);
  return (
    <li className="grid grid-cols-1 sm:grid-cols-[132px_minmax(0,1fr)] gap-x-4 gap-y-0.5 px-5 py-2 text-[12.5px]">
      <span className="tabular-nums whitespace-nowrap" style={{ color: MUTED }}>{fmtDate(c.at)} · {fmtTime(c.at)}</span>
      <span className="flex flex-wrap items-center gap-x-2 gap-y-1 min-w-0">
        {estate && c.assetId && (
          <Link href={`/assets/${c.assetId}/history`} className={`font-semibold hover:underline rounded ${FOCUS}`} style={{ color: '#005B96' }}>
            {c.assetName || `Asset ${c.assetId}`}
          </Link>
        )}
        <span className="font-medium" style={{ color: INK, overflowWrap: 'anywhere' }}>{d.text}</span>
        {d.from !== undefined && <span style={{ color: DEL, textDecoration: 'line-through', overflowWrap: 'anywhere' }}>{d.from}</span>}
        {d.from !== undefined && d.to !== undefined && <ArrowRight className="h-3.5 w-3.5 flex-none" style={{ color: FAINT }} aria-label="changed to" />}
        {d.to !== undefined && <span style={{ color: ADD, fontWeight: 500, overflowWrap: 'anywhere' }}>{d.to}</span>}
        {d.note && <span className="text-[12px]" style={{ color: MUTED, overflowWrap: 'anywhere' }}>({d.note})</span>}
        <SourceBadge source={c.source} />
        {c.source === 'manual' && <span className="text-[11.5px]" style={{ color: MUTED }}>by {c.actor}</span>}
      </span>
    </li>
  );
}

function Fact({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="min-w-0">
      <div className="text-[11px] font-semibold uppercase tracking-[0.04em]" style={{ color: MUTED }}>{label}</div>
      <div className="text-[13px] mt-0.5" style={{ color: INK, overflowWrap: 'anywhere' }}>{children}</div>
    </div>
  );
}

function FieldPopup({ v, estate, onClose }: { v: View; estate: boolean; onClose: () => void }) {
  const { track: t, changes } = v;
  const [shownN, setShownN] = useState(CHANGE_PAGE);
  // A list's items are shown under "Now" below; the fact box only needs the count.
  const cur = !estate && t.kind === 'list' && t.count
    ? { text: `${t.count} item${t.count === 1 ? '' : 's'}`, muted: false } : currentValue(t, estate);
  const items = !estate && t.isList && Array.isArray(t.value) ? (t.value as unknown[]) : [];
  const assets = new Set(changes.map((c) => c.assetId).filter(Boolean)).size;
  return (
    <AnimatedModal isOpen onClose={onClose} size="xl" title={t.name}
      subtitle={`${categoryMeta(catOf(t)).label} · ${t.group}`}>
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 px-5 py-3 border-b" style={{ borderColor: DIVIDER, background: '#FAFBFC' }}>
        <Fact label={estate ? 'Present on' : 'Current value'}>
          <span style={{ color: cur.muted ? MUTED : INK, fontStyle: cur.muted ? 'italic' : undefined }}>{cur.text}</span>
        </Fact>
        <Fact label="Changes">{changes.length}</Fact>
        {estate ? <Fact label="Assets changed">{assets}</Fact> : <Fact label="First change">{changes.length ? fmtDate(changes[changes.length - 1].at) : '—'}</Fact>}
        <Fact label="Last change">{changes.length ? relTime(changes[0].at) : 'No change'}</Fact>
      </div>
      {t.kind === 'live' && (
        <p className="px-5 py-3 text-[12.5px]" style={{ color: MUTED }}>A live reading that changes on every report, so it is not tracked as a change.</p>
      )}
      {changes.length > 0 ? (
        <ul className="divide-y" style={{ borderColor: DIVIDER }}>
          {changes.slice(0, shownN).map((c, i) => <Change key={i} t={t} c={c} estate={estate} />)}
        </ul>
      ) : t.kind !== 'live' && (
        <p className="px-5 py-6 text-center text-[13px]" style={{ color: MUTED }}>No change recorded for this field{estate ? ' on any asset' : ''} in this period.</p>
      )}
      {changes.length > shownN && (
        <div className="px-5 py-2">
          <button type="button" onClick={() => setShownN((n) => n + CHANGE_PAGE)} className={`text-[12px] font-semibold rounded ${FOCUS}`} style={{ color: '#005B96' }}>
            Show {Math.min(CHANGE_PAGE, changes.length - shownN)} more of {changes.length - shownN}
          </button>
        </div>
      )}
      {items.length > 0 && (
        <div className="px-5 py-3 border-t" style={{ borderColor: DIVIDER }}>
          <div className="text-[11px] font-semibold uppercase tracking-[0.04em] mb-1.5" style={{ color: MUTED }}>Now ({t.count})</div>
          <div className="flex flex-wrap gap-1">
            {items.slice(0, ITEM_PREVIEW).map((x, i) => (
              <span key={i} className="rounded-[6px] px-1.5 py-[1px] text-[11.5px]"
                style={{ background: '#F4F6F7', border: `1px solid ${BORDER}`, color: SEC, overflowWrap: 'anywhere' }}>{shown(x)}</span>
            ))}
            {(t.count ?? 0) > items.length && <span className="text-[11.5px] px-1" style={{ color: MUTED }}>+ {(t.count ?? 0) - items.length} more</span>}
          </div>
        </div>
      )}
    </AnimatedModal>
  );
}

/* ── table ───────────────────────────────────────────────────────────── */

function Row({ v, estate, onOpen }: { v: View; estate: boolean; onOpen: () => void }) {
  const { track: t, changes } = v;
  const cur = currentValue(t, estate);
  const last = changes[0];
  const d = last ? describeChange(t, last) : null;
  return (
    <li>
      <button type="button" onClick={onOpen} aria-haspopup="dialog"
        className={`w-full text-left px-3 py-[7px] ${ROW_GRID} flex flex-col gap-0.5 hover:bg-[#FAFBFC] ${FOCUS}`}>
        <span className="block text-[12.5px] font-medium" style={{ color: INK, overflowWrap: 'anywhere' }}>
          {t.name}
          {t.kind === 'live' && <span className="ml-1.5 text-[10.5px] font-normal" style={{ color: MUTED }}>live reading</span>}
        </span>
        <span className="block text-[12.5px] min-w-0 truncate" title={cur.text}
          style={{ color: cur.muted ? MUTED : SEC, fontStyle: cur.muted ? 'italic' : undefined }}>{cur.text}</span>
        <span className="block text-[12px] min-w-0 truncate" style={{ color: last ? SEC : MUTED }}>
          {t.kind === 'live' ? 'Not tracked (changes every reading)'
            : last && d ? (
              <>{estate && last.assetName && <span style={{ color: INK }}>{last.assetName}: </span>}
                <b className="font-semibold" style={{ color: '#014A81' }}>{d.text}</b>
                {d.to !== undefined && <> {d.from !== undefined ? `${d.from} → ` : ''}{d.to}</>}
                {d.to === undefined && d.from !== undefined && <> (was {d.from})</>}
                {d.note && <span style={{ color: MUTED }}> ({d.note})</span>}
                <span style={{ color: MUTED }}> · {relTime(last.at)}</span></>
            ) : 'No change'}
        </span>
        <span className="flex items-center justify-end gap-1.5 text-[11.5px] tabular-nums" style={{ color: MUTED }}>
          {changes.length > 0 && (
            <span className="rounded-full px-1.5 font-semibold" style={{ background: '#EFF5FA', color: '#005B96' }}>{changes.length}</span>
          )}
          <ChevronRight className="h-4 w-4" style={{ color: FAINT }} aria-hidden />
        </span>
      </button>
    </li>
  );
}

function Group({ name, views, estate, onOpen }: { name: string; views: View[]; estate: boolean; onOpen: (p: string) => void }) {
  const changed = views.filter((v) => v.changes.length).length;
  return (
    <section className="rounded-[12px] bg-white overflow-hidden" style={CARD_STYLE} aria-label={name}>
      <h3 className="flex items-baseline gap-2 px-3 py-2 border-b" style={{ borderColor: DIVIDER, background: '#FAFBFC' }}>
        <span className="text-[13px] font-semibold" style={{ color: INK }}>{name}</span>
        <span className="ml-auto text-[11.5px] tabular-nums" style={{ color: MUTED }}>
          {changed ? <><b style={{ color: '#005B96' }}>{changed}</b> of {views.length} changed</> : `${views.length} field${views.length === 1 ? '' : 's'} · no change`}
        </span>
      </h3>
      <div className={`hidden ${ROW_GRID} px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.04em]`} style={{ color: MUTED }}>
        <span>Field</span><span>{estate ? 'Present on' : 'Current value'}</span><span>Last change</span><span className="text-right">Changes</span>
      </div>
      <ul className="divide-y divide-[#F0F3F5]">
        {views.map((v) => <Row key={v.track.path} v={v} estate={estate} onOpen={() => onOpen(v.track.path)} />)}
      </ul>
    </section>
  );
}

const segBtn = (on: boolean) => `${on ? 'seg on' : 'seg'} ${FOCUS}`;
const SEG_STYLE = { height: 28, padding: '0 11px', fontSize: 12 };

/** Shared body. `period` given → the caller owns the window (estate fetch); else filter changes here. */
function FieldTrackerView({ rows, entries, estate, period, assetCount, capped }: {
  rows: FieldRow[]; entries: ChangeEntry[]; estate: boolean; period?: Segmented; assetCount?: number; capped: boolean;
}) {
  const [category, setCategory] = useState('');
  const [changedOnly, setChangedOnly] = useState(false);
  const [query, setQuery] = useState('');
  const [localPeriod, setLocalPeriod] = useState('all');
  const [open, setOpen] = useState<string | null>(null);

  const tracks = useMemo(() => buildTracks(rows, entries), [rows, entries]);
  const views: View[] = useMemo(() => {
    const since = period || localPeriod === 'all' ? null : Date.now() - Number(localPeriod) * 86_400_000;
    return tracks.map((t) => ({ track: t, changes: t.changes.filter((c) => inPeriod(c, since)) }));
  }, [tracks, period, localPeriod]);

  const cats = useMemo(() => CATEGORY_ORDER.map((c) => {
    const vs = views.filter((v) => catOf(v.track) === c);
    return { c, total: vs.length, changed: vs.filter((v) => v.changes.length).length };
  }).filter((x) => x.total > 0), [views]);
  const active = cats.some((x) => x.c === category) ? category : (cats.find((x) => x.changed)?.c ?? cats[0]?.c ?? '');

  const needle = query.trim().toLowerCase();
  const groups = useMemo(() => {
    const out = new Map<string, View[]>();
    for (const v of views) {
      const t = v.track;
      if (catOf(t) !== active || (changedOnly && !v.changes.length)) continue;
      if (needle && ![t.name, t.group, t.path, currentValue(t, estate).text, ...(estate ? v.changes.map((c) => c.assetName ?? '') : [])]
        .join(' ').toLowerCase().includes(needle)) continue;
      out.set(t.group, [...(out.get(t.group) ?? []), v]);
    }
    // Asset record fields first, then telemetry sections in the order reported.
    return Array.from(out.entries()).sort(([a], [b]) => (a === RECORD_GROUP ? -1 : b === RECORD_GROUP ? 1 : 0));
  }, [views, active, changedOnly, needle, estate]);

  const tracked = views.filter((v) => v.track.kind !== 'live');
  const changed = tracked.filter((v) => v.changes.length);
  const lastAt = changed.map((v) => v.changes[0].at).filter(Boolean).sort().pop();
  const assetsChanged = new Set(entries.map((e) => e.asset_id).filter(Boolean)).size;
  const per = period ?? { label: 'Period', value: localPeriod, options: PERIODS, onChange: setLocalPeriod };
  const perLabel = per.options.find((o) => o.key === per.value)?.label.toLowerCase() ?? '';
  const openView = open ? views.find((v) => v.track.path === open) : undefined;

  return (
    <div className="space-y-2.5">
      <KpiStrip items={[
        { label: 'Fields', value: tracked.length, sub: estate && assetCount !== undefined ? `Across ${assetCount} assets` : `${cats.length} categories` },
        { label: 'Changed', value: changed.length, sub: per.value === 'all' ? 'All time' : `Last ${perLabel}` },
        estate ? { label: 'Assets changed', value: assetsChanged } : { label: 'No change', value: tracked.length - changed.length },
        { label: 'Last change', value: relTime(lastAt), sub: lastAt ? fmtDate(lastAt) : undefined },
      ]} />
      <div role="tablist" aria-label="Field categories" className="flex flex-wrap gap-x-4 gap-y-1 border-b border-[#e8ecee] px-0.5">
        {cats.map(({ c, total, changed: n }) => {
          const on = active === c;
          return (
            <button key={c} type="button" role="tab" aria-selected={on} onClick={() => setCategory(c)}
              className={`text-[12.5px] whitespace-nowrap pb-1.5 -mb-px border-b-2 rounded-t-[4px] ${FOCUS} ${on
                ? 'font-semibold text-[#014A81] border-[#005B96]' : 'font-medium text-[#6b7787] border-transparent hover:text-[#0f1f2b]'}`}>
              {categoryMeta(c).label}
              <span className="ml-1.5 text-[11px] tabular-nums" style={{ color: n ? '#005B96' : MUTED }}
                title={`${n} of ${total} fields changed`}>{n}/{total}</span>
            </button>
          );
        })}
      </div>
      <div className="rounded-[12px] bg-white p-2 flex flex-wrap items-center gap-2" style={CARD_STYLE}>
        <label className="relative flex-1 min-w-[200px] basis-[220px]">
          <span className="sr-only">Search fields</span>
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: MUTED }} aria-hidden />
          <input className="search" value={query} onChange={(e) => setQuery(e.target.value)}
            placeholder={estate ? 'Search field, value or asset' : 'Search field or value'} style={{ fontFamily: 'inherit', color: INK }} />
        </label>
        <div className="segwrap" role="group" aria-label="Which fields">
          <button type="button" aria-pressed={!changedOnly} onClick={() => setChangedOnly(false)} className={segBtn(!changedOnly)} style={SEG_STYLE}>All fields</button>
          <button type="button" aria-pressed={changedOnly} onClick={() => setChangedOnly(true)} className={segBtn(changedOnly)} style={SEG_STYLE}>Changed only</button>
        </div>
        <div className="segwrap" role="group" aria-label={per.label}>
          {per.options.map((o) => (
            <button key={o.key} type="button" aria-pressed={per.value === o.key} onClick={() => per.onChange(o.key)}
              className={segBtn(per.value === o.key)} style={SEG_STYLE}>{o.label}</button>
          ))}
        </div>
        {(query || changedOnly) && (
          <button type="button" onClick={() => { setQuery(''); setChangedOnly(false); }}
            className={`inline-flex items-center gap-1 text-[11.5px] font-semibold rounded-[6px] ${FOCUS}`} style={{ color: '#005B96' }}>
            <X className="h-3.5 w-3.5" aria-hidden /> Clear
          </button>
        )}
      </div>
      {(capped || entries.some((e) => e.truncated)) && (
        <p className="px-1 text-[12px]" style={{ color: MUTED }}>
          {capped ? `Showing the newest ${entries.length.toLocaleString()} recorded changes; older ones are not counted here. ` : ''}
          {entries.some((e) => e.truncated) ? 'Some very large changes (for example a first full inventory) were stored as totals only, so a field marked "No change" may have been set then.' : ''}
        </p>
      )}
      {groups.length
        ? groups.map(([name, vs]) => <Group key={name} name={name} views={vs} estate={estate} onOpen={setOpen} />)
        : <StateMessage>{changedOnly ? `No field in ${categoryMeta(active).label} changed in this period.` : 'No fields match this search.'}</StateMessage>}
      {openView && <FieldPopup key={openView.track.path} v={openView} estate={estate} onClose={() => setOpen(null)} />}
    </div>
  );
}

/** One asset: every field it has now. */
export default function FieldTracker({ assetId, entries }: { assetId: number; entries: ChangeEntry[] }) {
  const q = useQuery({
    queryKey: ['asset-fields', assetId],
    queryFn: async () => (await entityExtrasApi.assetFields(assetId)).data.fields as FieldRow[],
  });
  if (q.isLoading) return <StateMessage>Loading fields…</StateMessage>;
  if (q.isError) return <StateMessage tone="error">Could not load this asset&apos;s fields. Refresh the page to try again.</StateMessage>;
  return <FieldTrackerView rows={q.data ?? []} entries={entries} estate={false} capped={entries.length >= 1000} />;
}

/** All assets: every field found on any asset, each change naming its asset. */
export function EstateFieldTracker({ entries, period, capped }: { entries: ChangeEntry[]; period: Segmented; capped: boolean }) {
  const q = useQuery({
    queryKey: ['asset-field-catalog'],
    queryFn: async () => (await entityExtrasApi.assetFieldCatalog()).data,
    staleTime: 5 * 60_000,
  });
  if (q.isLoading) return <StateMessage>Loading fields…</StateMessage>;
  if (q.isError) return <StateMessage tone="error">Could not load the estate&apos;s fields. Refresh the page to try again.</StateMessage>;
  return <FieldTrackerView rows={(q.data?.fields ?? []) as FieldRow[]} entries={entries} estate
    period={period} assetCount={q.data?.assets} capped={capped} />;
}
