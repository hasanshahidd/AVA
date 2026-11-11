'use client';

/*
 * Inventory → Asset history → Dashboard (default view): the estate's change
 * journal for the chosen period at a glance, for a security / IT manager.
 *   KPIs → daily volume by source → where (category) / who (source) →
 *   most-changed assets and fields → recent security changes and manual edits.
 * Every day and time is Pakistan time (model.ts helpers only).
 */

import { useMemo, type ReactNode } from 'react';
import Link from 'next/link';
import { useQuery } from '@tanstack/react-query';
import { ArrowRight } from 'lucide-react';
import { Bar, BarChart, CartesianGrid, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { entityExtrasApi } from '@/lib/api';
import { CARD_STYLE, KpiStrip } from '../[id]/_components/change-history/ChangeHistory';
import { SourceBadge } from '../[id]/_components/change-history/ChangeEntryCard';
import {
  ACCENT, ADD, BRAND, CATEGORY_ORDER, DEL, DIVIDER, FAINT, INK, MUTED, SEC, SOURCE_ORDER, TIME_ZONE, TZ_LABEL, type ChangeEntry,
  type Summary, categoryCounts, categoryMeta, dayKey, dayLabel, fmtDate, fmtTime, relTime, sourceMeta, sourceOf, summarise, totalOf,
} from '../[id]/_components/change-history/model';
import { type FieldRow, type Track, type TrackChange, buildTracks, describeChange } from '../[id]/_components/change-history/tracks';

const FOCUS = 'focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-[#19A8E6]';
const HEAD_BG = '#EAF3FA';   // same heading bar as the Fields view
const TRACK_BG = '#EEF2F5';
const TOP_N = 8;
const plural = (n: number, one: string, many = `${one}s`) => `${n.toLocaleString()} ${n === 1 ? one : many}`;

/* ── building blocks ─────────────────────────────────────────────────── */

function Card({ title, meta, className = '', children }: { title: string; meta?: ReactNode; className?: string; children: ReactNode }) {
  return (
    <section className={`rounded-[12px] bg-white overflow-hidden flex flex-col min-w-0 ${className}`} style={CARD_STYLE} aria-label={title}>
      <h3 className="flex items-center gap-2 px-3 py-[7px]" style={{ background: HEAD_BG, boxShadow: `inset 3px 0 0 ${BRAND}` }}>
        <span className="text-[13px] font-semibold" style={{ color: BRAND }}>{title}</span>
        {meta && <span className="ml-auto text-[11.5px] tabular-nums truncate" style={{ color: MUTED }}>{meta}</span>}
      </h3>
      <div className="flex-1 px-3 py-2 min-w-0">{children}</div>
    </section>
  );
}

/** One ranked row: label · bar · count. The count is text, so colour never carries the value alone. */
function BarRow({ label, value, max, color, sub, title, onClick }: {
  label: ReactNode; value: number; max: number; color: string; sub?: string; title?: string; onClick?: () => void;
}) {
  const zero = value === 0;   // listed so the card shows every category / source, but quiet
  const body = (
    <>
      <span className="min-w-0 truncate" style={{ color: zero ? MUTED : INK }}>{label}</span>
      <span className="h-[7px] rounded-full overflow-hidden" style={{ background: TRACK_BG }} aria-hidden>
        {!zero && <span className="block h-full rounded-full" style={{ width: `${Math.max(3, (value / (max || 1)) * 100)}%`, background: color }} />}
      </span>
      <span className="text-right tabular-nums whitespace-nowrap" style={{ color: SEC }}>
        <b className="font-semibold" style={{ color: zero ? MUTED : INK }}>{value.toLocaleString()}</b>
        {sub && <span className="ml-1 text-[11px]" style={{ color: MUTED }}>{sub}</span>}
      </span>
    </>
  );
  const grid = 'grid grid-cols-[minmax(0,1.15fr)_minmax(48px,1fr)_auto] items-center gap-x-2.5 py-[5px] text-[12.5px]';
  return (
    <li title={title}>
      {onClick
        ? <button type="button" onClick={onClick} className={`${grid} w-full text-left rounded-[6px] px-1 -mx-1 hover:bg-[#F0F8FE] ${FOCUS}`}>{body}</button>
        : <div className={grid}>{body}</div>}
    </li>
  );
}

const Dot = ({ color }: { color: string }) => <span className="inline-block h-[8px] w-[8px] rounded-full mr-1.5 align-middle" style={{ background: color }} aria-hidden />;
const None = ({ children }: { children: ReactNode }) => <p className="py-4 text-center text-[12.5px]" style={{ color: MUTED }}>{children}</p>;

/* ── change volume over time ─────────────────────────────────────────── */

type DayRow = { key: string; label: string; title: string; total: number } & Record<string, number | string>;

/** Hour bucket in Pakistan time, e.g. "2026-11-11 17". */
const hourKey = (ms: number) => new Date(ms).toLocaleString('en-CA', {
  timeZone: TIME_ZONE, year: 'numeric', month: '2-digit', day: '2-digit', hour: '2-digit', hour12: false,
});

function VolumeTip({ active, row, sources }: { active?: boolean; row?: DayRow; sources: string[] }) {
  if (!active || !row) return null;
  return (
    <div className="rounded-[8px] bg-white px-2.5 py-2 text-[12px] shadow-md" style={{ border: `1px solid ${DIVIDER}`, color: SEC }}>
      <div className="font-semibold mb-1" style={{ color: INK }}>{row.title}</div>
      {sources.filter((s) => Number(row[s])).map((s) => (
        <div key={s} className="flex items-center gap-3"><span><Dot color={sourceMeta(s).color} />{sourceMeta(s).label}</span>
          <span className="ml-auto tabular-nums font-semibold" style={{ color: INK }}>{row[s]}</span></div>
      ))}
      <div className="flex gap-3 mt-1 pt-1" style={{ borderTop: `1px solid ${DIVIDER}` }}>
        <span>Total</span><span className="ml-auto tabular-nums font-semibold" style={{ color: INK }}>{row.total}</span>
      </div>
    </div>
  );
}

function VolumeChart({ items, summary, days }: { items: ChangeEntry[]; summary: Summary; days: number }) {
  const sources = useMemo(() => [...SOURCE_ORDER, ...summary.bySource.map(([s]) => s).filter((s) => !SOURCE_ORDER.includes(s))]
    .filter((s) => summary.bySource.some(([k]) => k === s)), [summary]);
  // The axis fits the data so the bars fill the chart: hourly when everything is within two days,
  // else daily from the first change to today (not the whole period with one bar at the end).
  const hourly = useMemo(() => {
    const first = summary.first ? Date.parse(summary.first) : Date.now();
    return Date.now() - first <= 2 * 86_400_000;
  }, [summary.first]);
  const rows = useMemo(() => {
    const stepMs = hourly ? 3_600_000 : 86_400_000;
    const keyOf = (ms: number) => (hourly ? hourKey(ms) : dayKey(new Date(ms).toISOString()));
    const first = summary.first ? Date.parse(summary.first) : Date.now();
    const out: DayRow[] = [];
    const idx = new Map<string, number>();
    for (let ms = first; ms <= Date.now() + stepMs - 1; ms += stepMs) {
      const key = keyOf(ms);
      if (idx.has(key)) continue;
      const iso = new Date(ms).toISOString();
      idx.set(key, out.length);
      out.push({ key, label: hourly ? `${fmtTime(iso).slice(0, 2)}:00` : fmtDate(iso).replace(/ \d{4}$/, ''),
        title: hourly ? `${dayLabel(iso).title}, ${fmtTime(iso).slice(0, 2)}:00–${fmtTime(new Date(ms + 3_600_000).toISOString()).slice(0, 2)}:00 ${TZ_LABEL}` : (() => { const d = dayLabel(iso); return d.title === d.date ? d.date : `${d.title}, ${d.date}`; })(),
        total: 0, ...Object.fromEntries(sources.map((s) => [s, 0])) });
    }
    for (const e of items) {
      const i = e.created_at ? idx.get(keyOf(Date.parse(e.created_at))) : undefined;
      if (i === undefined) continue;
      out[i][sourceOf(e)] = Number(out[i][sourceOf(e)] ?? 0) + 1;
      out[i].total += 1;
    }
    return out;
  }, [items, summary.first, sources, hourly]);
  const busiest = rows.reduce<DayRow | null>((b, r) => (!b || r.total > b.total ? r : b), null);
  const inChart = rows.reduce((n, r) => n + r.total, 0);
  const unit = hourly ? 'hour' : 'day';
  const aria = `Changes per ${unit} over the last ${days} days, stacked by source: ${inChart} in total`
    + `${busiest?.total ? `, busiest day ${busiest.label} with ${busiest.total}` : ''}. `
    + sources.map((s) => `${sourceMeta(s).label} ${summary.bySource.find(([k]) => k === s)?.[1] ?? 0}`).join(', ');

  return (
    <Card title="Change volume" className="lg:col-span-2"
      meta={`Per ${unit}, ${TZ_LABEL}${busiest?.total ? ` · busiest ${busiest.label} (${busiest.total})` : ''}`}>
      <ul className="flex flex-wrap gap-x-4 gap-y-1 mb-1 text-[11.5px]" aria-label="Sources" style={{ color: SEC }}>
        {sources.map((s) => <li key={s}><Dot color={sourceMeta(s).color} />{sourceMeta(s).label}</li>)}
      </ul>
      <div role="img" aria-label={aria} className="h-[290px] -ml-2">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={rows} margin={{ top: 6, right: 4, bottom: 0, left: 0 }} barCategoryGap="18%">
            <CartesianGrid vertical={false} stroke={DIVIDER} />
            <XAxis dataKey="label" tick={{ fontSize: 10.5, fill: MUTED }} tickLine={false} axisLine={{ stroke: '#DCE3E8' }}
              interval="preserveStartEnd" minTickGap={18} />
            <YAxis allowDecimals={false} width={32} tick={{ fontSize: 10.5, fill: MUTED }} tickLine={false} axisLine={false} />
            <Tooltip cursor={{ fill: 'rgba(0,91,150,0.06)' }}
              content={({ active, payload }) => <VolumeTip active={active} row={payload?.[0]?.payload as DayRow | undefined} sources={sources} />} />
            {sources.map((s) => (
              <Bar key={s} dataKey={s} name={sourceMeta(s).label} stackId="day" fill={sourceMeta(s).color}
                stroke="#fff" strokeWidth={1} maxBarSize={44} isAnimationActive={false} />
            ))}
          </BarChart>
        </ResponsiveContainer>
      </div>
    </Card>
  );
}

/* ── ranked cards ────────────────────────────────────────────────────── */

function SourceCard({ summary }: { summary: Summary }) {
  const max = summary.bySource[0]?.[1] ?? 0;
  const count = new Map(summary.bySource);
  // Every source, so it is clear which ones made no change (e.g. no manual edits this period).
  const all: [string, number][] = [...SOURCE_ORDER, ...summary.bySource.map(([s]) => s).filter((s) => !SOURCE_ORDER.includes(s))]
    .map((s) => [s, count.get(s) ?? 0]);
  // The three ways an asset changes, at a glance (agentless = credentialed scan + network discovery).
  const groups: [string, number, string][] = [
    ['Agent', count.get('agent') ?? 0, 'Endpoint agent reports'],
    ['Agentless', (count.get('scan') ?? 0) + (count.get('discovery') ?? 0), 'Credentialed scans and network discovery'],
    ['Manual', count.get('manual') ?? 0, 'Edits made by people in CAIVA'],
  ];
  return (
    <Card title="Who made them" meta="Changes by source">
      <div className="grid grid-cols-3 gap-1.5 mb-1.5" aria-label="Agent, agentless and manual changes">
        {groups.map(([label, n, hint]) => (
          <div key={label} className="rounded-[8px] px-2 py-1.5 text-center" title={hint}
            style={{ background: n ? '#EAF3FA' : '#F4F6F7', border: `1px solid ${n ? '#CFE3F2' : DIVIDER}` }}>
            <div className="text-[16px] font-semibold leading-tight tabular-nums" style={{ color: n ? BRAND : MUTED }}>{n}</div>
            <div className="text-[11px]" style={{ color: n ? BRAND : MUTED }}>{label}</div>
          </div>
        ))}
      </div>
      <ul aria-label="Changes by source">
        {all.map(([s, n]) => (
          <BarRow key={s} label={<><Dot color={sourceMeta(s).color} />{sourceMeta(s).label}</>} value={n} max={max}
            color={sourceMeta(s).color} sub={`${Math.round((n / (summary.entries || 1)) * 100)}%`} />
        ))}
      </ul>
      {summary.byActor.length > 0 && (
        <p className="mt-1.5 pt-1.5 text-[11.5px]" style={{ color: MUTED, borderTop: `1px solid ${DIVIDER}` }}>
          {plural(summary.byActor.length, 'contributor')}; most active: <span style={{ color: INK }}>{summary.byActor[0][0]}</span> ({summary.byActor[0][1]})
        </p>
      )}
    </Card>
  );
}

function CategoryCard({ summary, onCategory }: { summary: Summary; onCategory?: (c: string) => void }) {
  const max = Math.max(0, ...summary.byCategory.map(([, n]) => n));
  const count = new Map(summary.byCategory);
  // Every category of the asset record, so the card reads as a full checklist; a click opens its fields.
  const cats = CATEGORY_ORDER.filter((c) => c !== 'other' || count.has(c));
  return (
    <Card title="Where changes happen" meta="Click to see assets">
      <ul aria-label="Fields changed by category">
        {cats.map((c) => (
          <BarRow key={c} label={<><Dot color={categoryMeta(c).color} />{categoryMeta(c).label}</>} value={count.get(c) ?? 0} max={max}
            color={categoryMeta(c).color} title={`${categoryMeta(c).hint} (see the assets that changed here)`}
            onClick={onCategory ? () => onCategory(c) : undefined} />
        ))}
      </ul>
    </Card>
  );
}

type AssetStat = { id: number; name: string; type?: string | null; n: number; fields: number; last?: string; cats: Map<string, number> };

function AssetsCard({ items, totalAssets }: { items: ChangeEntry[]; totalAssets?: number }) {
  const all = useMemo(() => {
    const m = new Map<number, AssetStat>();
    for (const e of items) {                       // newest first, so the first entry seen is the last change
      if (!e.asset_id) continue;
      const a = m.get(e.asset_id) ?? { id: e.asset_id, name: e.asset_name || `Asset ${e.asset_id}`, type: e.asset_type, n: 0, fields: 0, last: e.created_at, cats: new Map() };
      a.n += 1;
      a.fields += totalOf(e);
      for (const [c, n] of Array.from(categoryCounts(e).entries())) a.cats.set(c, (a.cats.get(c) ?? 0) + n);
      m.set(e.asset_id, a);
    }
    return Array.from(m.values()).sort((a, b) => b.n - a.n || b.fields - a.fields);
  }, [items]);
  const top = all.slice(0, TOP_N);
  const unchanged = totalAssets !== undefined ? Math.max(0, totalAssets - all.length) : undefined;
  return (
    <Card title="Most-changed assets" meta="Changes · fields">
      {top.length ? (
        <ul aria-label="Most-changed assets" className="divide-y divide-[#F0F3F5]">
          {top.map((a) => {
            const mix = CATEGORY_ORDER.filter((c) => a.cats.get(c));
            const sum = mix.reduce((n, c) => n + (a.cats.get(c) ?? 0), 0) || 1;
            return (
              <li key={a.id} className="py-1.5">
                <div className="flex items-baseline gap-2 text-[12.5px]">
                  <Link href={`/assets/${a.id}/history`} title={a.type ? `${a.name} (${a.type})` : a.name}
                    className={`font-semibold truncate hover:underline rounded-sm ${FOCUS}`} style={{ color: BRAND }}>{a.name}</Link>
                  <span className="ml-auto tabular-nums whitespace-nowrap" style={{ color: SEC }}>
                    <b style={{ color: INK }}>{a.n}</b> change{a.n === 1 ? '' : 's'} · {a.fields.toLocaleString()} fields
                  </span>
                </div>
                {/* Category mix of this asset's changes: one stacked bar + its legend. */}
                <div className="flex h-[7px] rounded-full overflow-hidden mt-1" style={{ background: TRACK_BG }} aria-hidden>
                  {mix.map((c) => <span key={c} style={{ width: `${((a.cats.get(c) ?? 0) / sum) * 100}%`, background: categoryMeta(c).color }} />)}
                </div>
                <div className="flex flex-wrap gap-x-2.5 mt-1 text-[11.5px]" style={{ color: SEC }}>
                  {mix.map((c) => <span key={c}><Dot color={categoryMeta(c).color} />{categoryMeta(c).label} {a.cats.get(c)}</span>)}
                  <span className="ml-auto" style={{ color: MUTED }}>last {relTime(a.last)}{a.type ? ` · ${a.type}` : ''}</span>
                </div>
              </li>
            );
          })}
        </ul>
      ) : <None>No change names its asset.</None>}
      {unchanged !== undefined && totalAssets ? (
        <div className="mt-2 pt-2 text-[11.5px]" style={{ borderTop: `1px solid ${DIVIDER}`, color: SEC }}>
          <div className="flex h-[8px] rounded-full overflow-hidden" style={{ background: TRACK_BG }} aria-hidden>
            <span style={{ width: `${(all.length / totalAssets) * 100}%`, background: BRAND }} />
          </div>
          <div className="flex mt-1">
            <span><b style={{ color: BRAND }}>{all.length}</b> changed</span>
            <span className="ml-auto"><b style={{ color: INK }}>{unchanged}</b> of {totalAssets} assets with no change</span>
          </div>
        </div>
      ) : null}
    </Card>
  );
}

function FieldsCard({ summary }: { summary: Summary }) {
  const top = summary.topFields;
  return (
    <Card title="Most-changed fields" meta="Field changes">
      {top.length ? (
        <ul aria-label="Most-changed fields">
          {top.map(([f, n]) => <BarRow key={f} label={f} title={f} value={n} max={top[0][1]} color={ACCENT} />)}
        </ul>
      ) : <None>No field-level changes recorded.</None>}
    </Card>
  );
}

/* ── recent security changes and manual edits ───────────────────────── */

const catOf = (t: Track) => (CATEGORY_ORDER.includes(t.category) ? t.category : 'other');

function when(at?: string) {
  const t = dayLabel(at).title;
  return `${t === 'Today' || t === 'Yesterday' ? t : fmtDate(at)}, ${fmtTime(at)}`;
}

function RecentRow({ t, c }: { t: Track; c: TrackChange }) {
  const d = describeChange(t, c);
  return (
    <li className="grid grid-cols-1 md:grid-cols-[150px_minmax(120px,200px)_minmax(0,1fr)_auto] md:items-center gap-x-3 gap-y-0.5 py-[6px] text-[12.5px]">
      <time dateTime={c.at} className="tabular-nums whitespace-nowrap" style={{ color: MUTED }} title={`${fmtDate(c.at)} ${fmtTime(c.at, true)} ${TZ_LABEL}`}>
        {when(c.at)} {TZ_LABEL}
      </time>
      {c.assetId
        ? <Link href={`/assets/${c.assetId}/history`} className={`font-semibold truncate hover:underline rounded-sm ${FOCUS}`} style={{ color: BRAND }}>{c.assetName || `Asset ${c.assetId}`}</Link>
        : <span className="font-semibold truncate" style={{ color: INK }}>{c.assetName || 'Unknown asset'}</span>}
      <span className="flex flex-wrap items-center gap-x-1.5 min-w-0" style={{ color: SEC }}>
        <span className="font-semibold" style={{ color: INK }}><Dot color={categoryMeta(catOf(t)).color} />{t.name}</span>
        {d.text !== 'Changed' && <span style={{ overflowWrap: 'anywhere' }}>{d.text}</span>}
        {d.from !== undefined && <span style={{ color: DEL, textDecoration: 'line-through', overflowWrap: 'anywhere' }}>{d.from}</span>}
        {d.from !== undefined && d.to !== undefined && <ArrowRight className="h-3.5 w-3.5 flex-none" style={{ color: FAINT }} aria-label="changed to" />}
        {d.to !== undefined && <span style={{ color: ADD, fontWeight: 500, overflowWrap: 'anywhere' }}>{d.to}</span>}
        {d.note && <span className="text-[12px]" style={{ color: MUTED, overflowWrap: 'anywhere' }}>({d.note})</span>}
        {c.source === 'manual' && <span className="text-[11.5px]" style={{ color: MUTED }}>by {c.actor}</span>}
      </span>
      <span className="md:justify-self-end"><SourceBadge source={c.source} /></span>
    </li>
  );
}

function RecentCard({ items, rows }: { items: ChangeEntry[]; rows: FieldRow[] }) {
  const recent = useMemo(() => buildTracks(rows, items)
    .flatMap((t) => t.changes.filter((c) => catOf(t) === 'security' || c.source === 'manual').map((c) => ({ t, c })))
    .sort((a, b) => Date.parse(b.c.at ?? '') - Date.parse(a.c.at ?? ''))
    .slice(0, TOP_N), [rows, items]);
  return (
    <Card title="Recent security changes and manual edits" className="lg:col-span-2 xl:col-span-3"
      meta={recent.length ? `Latest ${recent.length}` : undefined}>
      {recent.length ? (
        <ol className="divide-y divide-[#F0F3F5]" aria-label="Recent security changes and manual edits">
          {recent.map(({ t, c }, i) => <RecentRow key={`${c.entry}-${i}`} t={t} c={c} />)}
        </ol>
      ) : <None>No security telemetry changes or manual edits in this period.</None>}
    </Card>
  );
}

/* ── dashboard ───────────────────────────────────────────────────────── */

export default function AssetHistoryDashboard({ items, days, capped, onCategory }: {
  items: ChangeEntry[]; days: number; capped: boolean; /** open the Assets view on a category */ onCategory?: (c: string) => void;
}) {
  // Same query as the Fields view (shared cache): field catalog for plain wording + the estate's asset count.
  const catalog = useQuery({
    queryKey: ['asset-field-catalog'],
    queryFn: async () => (await entityExtrasApi.assetFieldCatalog()).data,
    staleTime: 5 * 60_000,
  });
  const rows = useMemo(() => (catalog.data?.fields ?? []) as FieldRow[], [catalog.data]);
  const totalAssets = catalog.data?.assets;
  const summary = useMemo(() => summarise(items, days), [items, days]);
  const today = useMemo(() => {
    const k = dayKey(new Date().toISOString());
    return items.filter((e) => dayKey(e.created_at) === k).length;
  }, [items]);

  return (
    <div className="space-y-2.5">
      <KpiStrip items={[
        { label: 'Changes', value: summary.entries.toLocaleString(), sub: capped ? `Latest ${items.length.toLocaleString()} shown` : `Last ${days} days` },
        { label: 'Assets changed', value: summary.assets.toLocaleString(), sub: totalAssets ? `of ${totalAssets.toLocaleString()} assets` : undefined },
        { label: 'Fields changed', value: summary.fieldChanges.toLocaleString(), sub: plural(summary.byCategory.length, 'category', 'categories') },
        { label: 'Changes today', value: today.toLocaleString(), sub: `Since midnight ${TZ_LABEL}` },
        { label: 'Last change', value: relTime(summary.last), sub: summary.last ? `${fmtDate(summary.last)}, ${fmtTime(summary.last)} ${TZ_LABEL}` : undefined },
      ]} />
      {capped && (
        <p className="px-1 text-[12px]" style={{ color: MUTED }}>
          Showing the newest {items.length.toLocaleString()} recorded changes; older ones are not counted here.
        </p>
      )}
      <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-2.5">
        <VolumeChart items={items} summary={summary} days={days} />
        <SourceCard summary={summary} />
        <CategoryCard summary={summary} onCategory={onCategory} />
        <AssetsCard items={items} totalAssets={totalAssets} />
        <FieldsCard summary={summary} />
        <RecentCard items={items} rows={rows} />
      </div>
    </div>
  );
}
