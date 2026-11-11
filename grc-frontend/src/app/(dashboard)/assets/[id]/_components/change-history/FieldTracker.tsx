'use client';

/*
 * Field-by-field history: every field of the asset, organised like the asset
 * record (one toggle page per category → Asset record fields, then each
 * telemetry section), each with its own track:
 *   Field · Current value · Last change (or "No change") · count
 * A row opens into that field's changes in plain words ("Installed KB5132061",
 * "Owner: Ali → Sara") with when and which source. Live readings (free space,
 * uptime) are listed but marked as not tracked.
 */

import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ArrowRight, ChevronRight, Search, X } from 'lucide-react';
import { entityExtrasApi } from '@/lib/api';
import { KpiStrip, StateMessage, CARD_STYLE } from './ChangeHistory';
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
const CHANGE_PREVIEW = 15;
const ITEM_PREVIEW = 50;

type View = { track: Track; changes: TrackChange[] };
const catOf = (t: Track) => (CATEGORY_ORDER.includes(t.category) ? t.category : 'other');

function Change({ t, c }: { t: Track; c: TrackChange }) {
  const d = describeChange(t, c);
  return (
    <li className="grid grid-cols-1 sm:grid-cols-[150px_minmax(0,1fr)] gap-x-4 gap-y-0.5 py-1.5 text-[12.5px]">
      <span className="flex flex-wrap items-center gap-1.5" style={{ color: MUTED }}>
        <span className="tabular-nums whitespace-nowrap">{fmtDate(c.at)} · {fmtTime(c.at)}</span>
      </span>
      <span className="flex flex-wrap items-center gap-x-2 gap-y-1 min-w-0">
        <span className="font-medium" style={{ color: INK, overflowWrap: 'anywhere' }}>{d.text}</span>
        {d.from !== undefined && (
          <span style={{ color: DEL, textDecoration: 'line-through', overflowWrap: 'anywhere' }}>{d.from}</span>
        )}
        {d.from !== undefined && d.to !== undefined && (
          <ArrowRight className="h-3.5 w-3.5 flex-none" style={{ color: FAINT }} aria-label="changed to" />
        )}
        {d.to !== undefined && <span style={{ color: ADD, fontWeight: 500, overflowWrap: 'anywhere' }}>{d.to}</span>}
        {d.note && <span className="text-[12px]" style={{ color: MUTED, overflowWrap: 'anywhere' }}>({d.note})</span>}
        <SourceBadge source={c.source} />
        {c.source === 'manual' && <span className="text-[11.5px]" style={{ color: MUTED }}>by {c.actor}</span>}
      </span>
    </li>
  );
}

function Items({ t }: { t: Track }) {
  const items = Array.isArray(t.value) ? (t.value as unknown[]) : [];
  if (!items.length) return null;
  const more = (t.count ?? items.length) - items.length;
  return (
    <div className="pt-1.5">
      <div className="text-[11.5px] font-semibold mb-1" style={{ color: SEC }}>Now ({t.count})</div>
      <div className="flex flex-wrap gap-1">
        {items.slice(0, ITEM_PREVIEW).map((v, i) => (
          <span key={i} className="rounded-[6px] px-1.5 py-[1px] text-[11.5px]"
            style={{ background: '#F4F6F7', border: `1px solid ${BORDER}`, color: SEC, overflowWrap: 'anywhere' }}>{shown(v)}</span>
        ))}
        {more > 0 && <span className="text-[11.5px] px-1" style={{ color: MUTED }}>+ {more} more</span>}
      </div>
    </div>
  );
}

function Row({ v }: { v: View }) {
  const { track: t, changes } = v;
  const [open, setOpen] = useState(false);
  const [all, setAll] = useState(false);
  const cur = currentValue(t);
  const last = changes[0];
  const canOpen = changes.length > 0 || (t.isList && (t.count ?? 0) > 0);
  const lastText = last ? describeChange(t, last) : null;
  const body = (
    <>
      <span className="block text-[12.5px] font-medium" style={{ color: INK, overflowWrap: 'anywhere' }}>
        {t.name}
        {t.kind === 'live' && <span className="ml-1.5 text-[10.5px] font-normal" style={{ color: MUTED }}>live reading</span>}
      </span>
      <span className="block text-[12.5px] min-w-0 truncate" title={cur.text}
        style={{ color: cur.muted ? MUTED : SEC, fontStyle: cur.muted ? 'italic' : undefined }}>{cur.text}</span>
      <span className="block text-[12px] min-w-0 truncate" style={{ color: last ? SEC : MUTED }}>
        {t.kind === 'live' ? 'Not tracked (changes every reading)'
          : last && lastText ? (
            <><b className="font-semibold" style={{ color: '#014A81' }}>{lastText.text}</b>
              {lastText.to !== undefined && <> {lastText.from !== undefined ? `${lastText.from} → ` : ''}{lastText.to}</>}
              {lastText.to === undefined && lastText.from !== undefined && <> (was {lastText.from})</>}
              {lastText.note && <span style={{ color: MUTED }}> ({lastText.note})</span>}
              <span style={{ color: MUTED }}> · {relTime(last.at)}</span></>
          ) : 'No change'}
      </span>
      <span className="flex items-center justify-end gap-1.5 text-[11.5px] tabular-nums" style={{ color: MUTED }}>
        {changes.length > 0 && (
          <span className="rounded-full px-1.5 font-semibold" style={{ background: '#EFF5FA', color: '#005B96' }}>{changes.length}</span>
        )}
        {canOpen && <ChevronRight className={`h-4 w-4 transition-transform ${open ? 'rotate-90' : ''}`} style={{ color: FAINT }} aria-hidden />}
      </span>
    </>
  );
  const cls = `w-full text-left px-3 py-[7px] ${ROW_GRID} flex flex-col gap-0.5`;
  return (
    <li>
      {canOpen ? (
        <button type="button" aria-expanded={open} onClick={() => setOpen((o) => !o)}
          className={`${cls} hover:bg-[#FAFBFC] ${FOCUS}`}>{body}</button>
      ) : <div className={cls}>{body}</div>}
      {open && (
        <div className="px-3 pb-2.5 pt-0.5 md:pl-[calc(12px+min(150px,20%))]" style={{ background: '#FCFDFD' }}>
          {changes.length > 0 && (
            <ul className="divide-y" style={{ borderColor: DIVIDER }}>
              {(all ? changes : changes.slice(0, CHANGE_PREVIEW)).map((c, i) => <Change key={i} t={t} c={c} />)}
            </ul>
          )}
          {changes.length > CHANGE_PREVIEW && !all && (
            <button type="button" onClick={() => setAll(true)} className={`mt-1 text-[12px] font-semibold rounded ${FOCUS}`} style={{ color: '#005B96' }}>
              Show all {changes.length} changes
            </button>
          )}
          {t.isList && <Items t={t} />}
        </div>
      )}
    </li>
  );
}

function Group({ name, views }: { name: string; views: View[] }) {
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
        <span>Field</span><span>Current value</span><span>Last change</span><span className="text-right">Changes</span>
      </div>
      <ul className="divide-y divide-[#F0F3F5]">{views.map((v) => <Row key={v.track.path} v={v} />)}</ul>
    </section>
  );
}

export default function FieldTracker({ assetId, entries }: { assetId: number; entries: ChangeEntry[] }) {
  const [category, setCategory] = useState('');
  const [changedOnly, setChangedOnly] = useState(false);
  const [query, setQuery] = useState('');
  const [period, setPeriod] = useState('all');

  const q = useQuery({
    queryKey: ['asset-fields', assetId],
    queryFn: async () => (await entityExtrasApi.assetFields(assetId)).data.fields as FieldRow[],
  });
  const tracks = useMemo(() => buildTracks(q.data ?? [], entries), [q.data, entries]);
  const views: View[] = useMemo(() => {
    const since = period === 'all' ? null : Date.now() - Number(period) * 86_400_000;
    return tracks.map((t) => ({ track: t, changes: t.changes.filter((c) => inPeriod(c, since)) }));
  }, [tracks, period]);

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
      if (needle && ![t.name, t.group, t.path, currentValue(t).text].join(' ').toLowerCase().includes(needle)) continue;
      out.set(t.group, [...(out.get(t.group) ?? []), v]);
    }
    // Asset record fields first, then telemetry sections in the order the asset reports them.
    return Array.from(out.entries()).sort(([a], [b]) => (a === RECORD_GROUP ? -1 : b === RECORD_GROUP ? 1 : 0));
  }, [views, active, changedOnly, needle]);

  if (q.isLoading) return <StateMessage>Loading fields…</StateMessage>;
  if (q.isError) return <StateMessage tone="error">Could not load this asset&apos;s fields. Refresh the page to try again.</StateMessage>;

  const tracked = views.filter((v) => v.track.kind !== 'live');
  const changed = tracked.filter((v) => v.changes.length);
  const lastAt = changed.map((v) => v.changes[0].at).filter(Boolean).sort().pop();
  const periodLabel = PERIODS.find((p) => p.key === period)?.label.toLowerCase() ?? '';

  return (
    <div className="space-y-2.5">
      <KpiStrip items={[
        { label: 'Fields', value: tracked.length, sub: `${cats.length} categor${cats.length === 1 ? 'y' : 'ies'}` },
        { label: 'Changed', value: changed.length, sub: period === 'all' ? 'All time' : `Last ${periodLabel}` },
        { label: 'No change', value: tracked.length - changed.length },
        { label: 'Last change', value: relTime(lastAt), sub: lastAt ? fmtDate(lastAt) : undefined },
      ]} />
      <div role="tablist" aria-label="Field categories" className="flex gap-5 border-b border-[#e8ecee] overflow-x-auto overflow-y-hidden px-0.5">
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
            placeholder="Search field or value" style={{ fontFamily: 'inherit', color: INK }} />
        </label>
        <div className="segwrap" role="group" aria-label="Which fields">
          {[['all', 'All fields'], ['changed', 'Changed only']].map(([k, l]) => (
            <button key={k} type="button" aria-pressed={changedOnly === (k === 'changed')} onClick={() => setChangedOnly(k === 'changed')}
              className={`${changedOnly === (k === 'changed') ? 'seg on' : 'seg'} ${FOCUS}`} style={{ height: 28, padding: '0 11px', fontSize: 12 }}>{l}</button>
          ))}
        </div>
        <div className="segwrap" role="group" aria-label="Period">
          {PERIODS.map((o) => (
            <button key={o.key} type="button" aria-pressed={period === o.key} onClick={() => setPeriod(o.key)}
              className={`${period === o.key ? 'seg on' : 'seg'} ${FOCUS}`} style={{ height: 28, padding: '0 11px', fontSize: 12 }}>{o.label}</button>
          ))}
        </div>
        {(query || changedOnly) && (
          <button type="button" onClick={() => { setQuery(''); setChangedOnly(false); }}
            className={`inline-flex items-center gap-1 text-[11.5px] font-semibold rounded-[6px] ${FOCUS}`} style={{ color: '#005B96' }}>
            <X className="h-3.5 w-3.5" aria-hidden /> Clear
          </button>
        )}
      </div>
      {(entries.length >= 1000 || entries.some((e) => e.truncated)) && (
        <p className="px-1 text-[12px]" style={{ color: MUTED }}>
          {entries.length >= 1000 ? 'Showing the newest 1,000 recorded changes; older ones are not counted here. ' : ''}
          {entries.some((e) => e.truncated) ? 'Some very large changes (for example a first full inventory) were stored as totals only, so a field marked "No change" may have been set then.' : ''}
        </p>
      )}
      {groups.length
        ? groups.map(([name, vs]) => <Group key={name} name={name} views={vs} />)
        : <StateMessage>{changedOnly ? `No field in ${categoryMeta(active).label} changed in this period.` : 'No fields match this search.'}</StateMessage>}
    </div>
  );
}
