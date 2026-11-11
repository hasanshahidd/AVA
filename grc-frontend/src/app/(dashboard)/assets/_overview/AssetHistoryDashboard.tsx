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
  ACCENT, ADD, BRAND, CATEGORY_ORDER, DEL, DIVIDER, FAINT, INK, MUTED, SEC, SOURCE_ORDER, TZ_LABEL, type ChangeEntry,
  type Summary, categoryMeta, dayKey, dayLabel, fmtDate, fmtTime, relTime, sourceMeta, sourceOf, summarise, totalOf,
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
function BarRow({ label, value, max, color, sub, title }: {
  label: ReactNode; value: number; max: number; color: string; sub?: string; title?: string;
}) {
  return (
    <li className="grid grid-cols-[minmax(0,1.15fr)_minmax(48px,1fr)_auto] items-center gap-x-2.5 py-[5px] text-[12.5px]" title={title}>
      <span className="min-w-0 truncate" style={{ color: INK }}>{label}</span>
      <span className="h-[7px] rounded-full overflow-hidden" style={{ background: TRACK_BG }} aria-hidden>
        <span className="block h-full rounded-full" style={{ width: `${Math.max(3, (value / (max || 1)) * 100)}%`, background: color }} />
      </span>
      <span className="text-right tabular-nums whitespace-nowrap" style={{ color: SEC }}>
        <b className="font-semibold" style={{ color: INK }}>{value.toLocaleString()}</b>
        {sub && <span className="ml-1 text-[11px]" style={{ color: MUTED }}>{sub}</span>}
      </span>
    </li>
  );
}

const Dot = ({ color }: { color: string }) => <span className="inline-block h-[8px] w-[8px] rounded-full mr-1.5 align-middle" style={{ background: color }} aria-hidden />;
const None = ({ children }: { children: ReactNode }) => <p className="py-4 text-center text-[12.5px]" style={{ color: MUTED }}>{children}</p>;

/* ── change volume over time ─────────────────────────────────────────── */

type DayRow = { key: string; label: string; total: number } & Record<string, number | string>;

function VolumeTip({ active, row, sources }: { active?: boolean; row?: DayRow; sources: string[] }) {
  if (!active || !row) return null;
  const date = dayLabel(`${row.key}T12:00:00+05:00`);
  return (
    <div className="rounded-[8px] bg-white px-2.5 py-2 text-[12px] shadow-md" style={{ border: `1px solid ${DIVIDER}`, color: SEC }}>
      <div className="font-semibold mb-1" style={{ color: INK }}>{date.title === date.date ? date.date : `${date.title}, ${date.date}`}</div>
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
  const rows = useMemo(() => {
    const out: DayRow[] = summary.daily.map((d) => ({ key: d.key, label: d.label, total: d.count, ...Object.fromEntries(sources.map((s) => [s, 0])) }));
    const idx = new Map(out.map((r, i) => [r.key, i]));
    for (const e of items) {
      const i = idx.get(dayKey(e.created_at));
      if (i !== undefined) out[i][sourceOf(e)] = Number(out[i][sourceOf(e)] ?? 0) + 1;
    }
    return out;
  }, [items, summary, sources]);
  const busiest = rows.reduce<DayRow | null>((b, r) => (!b || r.total > b.total ? r : b), null);
  const inChart = rows.reduce((n, r) => n + r.total, 0);
  const aria = `Changes per day over the last ${days} days, stacked by source: ${inChart} in total`
    + `${busiest?.total ? `, busiest day ${busiest.label} with ${busiest.total}` : ''}. `
    + sources.map((s) => `${sourceMeta(s).label} ${summary.bySource.find(([k]) => k === s)?.[1] ?? 0}`).join(', ');

  return (
    <Card title="Change volume" className="lg:col-span-2"
      meta={`Per day, ${TZ_LABEL}${busiest?.total ? ` · busiest ${busiest.label} (${busiest.total})` : ''}`}>
      <ul className="flex flex-wrap gap-x-4 gap-y-1 mb-1 text-[11.5px]" aria-label="Sources" style={{ color: SEC }}>
        {sources.map((s) => <li key={s}><Dot color={sourceMeta(s).color} />{sourceMeta(s).label}</li>)}
      </ul>
      <div role="img" aria-label={aria} className="h-[210px] -ml-2">
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
                stroke="#fff" strokeWidth={1} maxBarSize={22} isAnimationActive={false} />
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
  return (
    <Card title="Who made them" meta="Changes by source">
      <ul aria-label="Changes by source">
        {summary.bySource.map(([s, n]) => (
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

function CategoryCard({ summary }: { summary: Summary }) {
  const max = Math.max(0, ...summary.byCategory.map(([, n]) => n));
  return (
    <Card title="Where changes happen" meta="Fields changed by category">
      <ul aria-label="Fields changed by category">
        {summary.byCategory.map(([c, n]) => (
          <BarRow key={c} label={<><Dot color={categoryMeta(c).color} />{categoryMeta(c).label}</>} value={n} max={max}
            color={categoryMeta(c).color} title={categoryMeta(c).hint} />
        ))}
      </ul>
    </Card>
  );
}

function AssetsCard({ items }: { items: ChangeEntry[] }) {
  const top = useMemo(() => {
    const m = new Map<number, { id: number; name: string; type?: string | null; n: number; fields: number }>();
    for (const e of items) {
      if (!e.asset_id) continue;
      const a = m.get(e.asset_id) ?? { id: e.asset_id, name: e.asset_name || `Asset ${e.asset_id}`, type: e.asset_type, n: 0, fields: 0 };
      m.set(e.asset_id, { ...a, n: a.n + 1, fields: a.fields + totalOf(e) });
    }
    return Array.from(m.values()).sort((a, b) => b.n - a.n || b.fields - a.fields).slice(0, TOP_N);
  }, [items]);
  return (
    <Card title="Most-changed assets" meta="Changes · fields">
      {top.length ? (
        <ul aria-label="Most-changed assets">
          {top.map((a) => (
            <BarRow key={a.id} value={a.n} max={top[0].n} color={BRAND} sub={`· ${a.fields.toLocaleString()}`}
              label={<Link href={`/assets/${a.id}/history`} title={a.type ? `${a.name} (${a.type})` : a.name}
                className={`font-semibold hover:underline rounded-sm ${FOCUS}`} style={{ color: BRAND }}>{a.name}</Link>} />
          ))}
        </ul>
      ) : <None>No change names its asset.</None>}
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

export default function AssetHistoryDashboard({ items, days, capped }: { items: ChangeEntry[]; days: number; capped: boolean }) {
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
        <CategoryCard summary={summary} />
        <AssetsCard items={items} />
        <FieldsCard summary={summary} />
        <RecentCard items={items} rows={rows} />
      </div>
    </div>
  );
}
