'use client';

/*
 * Inventory → Asset history → Assets: every asset in the estate with what changed on
 * it in the period (changes, fields, per-category mix, sources, last change), most
 * changed first and unchanged assets marked "No change". Picking an asset opens its
 * own field-by-field history (ChangeHistory) right here, with a way back.
 */

import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, ChevronRight, Search, X } from 'lucide-react';
import { assetsApi } from '@/lib/api';
import ChangeHistory, { CARD_STYLE, StateMessage } from '../[id]/_components/change-history/ChangeHistory';
import {
  BRAND, CATEGORY_ORDER, DIVIDER, INK, MUTED, SEC, TZ_LABEL, type ChangeEntry, categoryCounts, categoryMeta, fmtDate, fmtTime,
  relTime, sourceMeta, sourceOf, totalOf,
} from '../[id]/_components/change-history/model';

const FOCUS = 'focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-1 focus-visible:outline-[#19A8E6]';
const ROW = 'md:grid md:grid-cols-[minmax(180px,1.3fr)_88px_88px_minmax(0,2.2fr)_minmax(110px,0.9fr)_minmax(120px,0.9fr)_20px] md:items-center md:gap-x-3';
const MONO = "font-['IBM_Plex_Mono',ui-monospace,monospace] text-[11.5px]";

type Asset = { id: number; name: string; asset_type?: string; ip_address?: string; host_name?: string; criticality?: string };
type Stat = { n: number; fields: number; last?: string; cats: Map<string, number>; sources: Map<string, number> };

function statsByAsset(items: ChangeEntry[]): Map<number, Stat> {
  const m = new Map<number, Stat>();
  for (const e of items) {                 // newest first: the first entry seen is the last change
    if (!e.asset_id) continue;
    const s = m.get(e.asset_id) ?? { n: 0, fields: 0, last: e.created_at, cats: new Map(), sources: new Map() };
    s.n += 1;
    s.fields += totalOf(e);
    s.sources.set(sourceOf(e), (s.sources.get(sourceOf(e)) ?? 0) + 1);
    for (const [c, n] of Array.from(categoryCounts(e).entries())) s.cats.set(c, (s.cats.get(c) ?? 0) + n);
    m.set(e.asset_id, s);
  }
  return m;
}

function AssetRow({ a, s, onOpen }: { a: Asset; s?: Stat; onOpen: () => void }) {
  const hit = !!s;
  const mix = s ? CATEGORY_ORDER.filter((c) => s.cats.get(c)) : [];
  return (
    <li>
      <button type="button" onClick={onOpen}
        className={`w-full text-left px-3 py-2 flex flex-col gap-1 ${ROW} ${FOCUS} ${hit ? 'hover:bg-[#E3F1FB]' : 'hover:bg-[#FAFBFC]'}`}
        style={hit ? { background: '#F0F8FE', boxShadow: 'inset 3px 0 0 #19A8E6' } : undefined}>
        <span className="min-w-0">
          <span className="block truncate text-[12.5px] font-semibold" style={{ color: hit ? BRAND : INK }}>{a.name}</span>
          <span className="block truncate text-[11px]" style={{ color: MUTED }}>
            <span className="capitalize">{a.asset_type || 'asset'}</span>
            {a.ip_address && <> · <span className={MONO}>{a.ip_address}</span></>}
          </span>
        </span>
        <span className="text-[12.5px] tabular-nums" style={{ color: hit ? INK : MUTED }}>
          <b className="font-semibold">{s?.n ?? 0}</b><span className="md:hidden"> changes</span>
        </span>
        <span className="text-[12.5px] tabular-nums" style={{ color: hit ? INK : MUTED }}>
          <b className="font-semibold">{s?.fields ?? 0}</b><span className="md:hidden"> fields</span>
        </span>
        <span className="flex flex-wrap gap-1 min-w-0">
          {mix.length ? mix.map((c) => (
            <span key={c} className="inline-flex items-center gap-1 rounded-full px-1.5 py-[1px] text-[11px] font-medium whitespace-nowrap"
              style={{ background: `${categoryMeta(c).color}14`, color: categoryMeta(c).color, border: `1px solid ${categoryMeta(c).color}33` }}>
              {categoryMeta(c).label} <b>{s!.cats.get(c)}</b>
            </span>
          )) : <span className="text-[12px]" style={{ color: MUTED }}>No change</span>}
        </span>
        <span className="flex flex-wrap gap-x-2 text-[11.5px]" style={{ color: SEC }}>
          {s ? Array.from(s.sources.entries()).map(([src, n]) => (
            <span key={src} className="whitespace-nowrap">
              <span className="inline-block h-[7px] w-[7px] rounded-full mr-1" style={{ background: sourceMeta(src).color }} aria-hidden />
              {sourceMeta(src).label} {n}
            </span>
          )) : <span style={{ color: MUTED }}>—</span>}
        </span>
        <span className="text-[11.5px]" style={{ color: s ? SEC : MUTED }} title={s?.last ? `${fmtDate(s.last)} ${fmtTime(s.last)} ${TZ_LABEL}` : undefined}>
          {s?.last ? <>{relTime(s.last)}<span className="block" style={{ color: MUTED }}>{fmtDate(s.last)}, {fmtTime(s.last)} {TZ_LABEL}</span></> : 'No change'}
        </span>
        <ChevronRight className="hidden md:block h-4 w-4" style={{ color: hit ? BRAND : '#9AA5B1' }} aria-hidden />
      </button>
    </li>
  );
}

export default function AssetChangesOverview({ items, initialCategory, periodLabel }: {
  items: ChangeEntry[]; initialCategory?: string; periodLabel: string;
}) {
  const [open, setOpen] = useState<Asset | null>(null);
  const [category, setCategory] = useState(initialCategory ?? 'all');
  const [changedOnly, setChangedOnly] = useState(!!initialCategory);
  const [query, setQuery] = useState('');

  // Same query as the inventory register (shared cache): every managed asset.
  const q = useQuery({
    queryKey: ['assets'],
    queryFn: async () => (await assetsApi.getAll({ limit: 100000 })).data,
  });
  const stats = useMemo(() => statsByAsset(items), [items]);
  const assets = useMemo(() => ((q.data ?? []) as unknown as Asset[]), [q.data]);
  const catCount = useMemo(() => {
    const m = new Map<string, number>();
    for (const s of Array.from(stats.values())) for (const c of Array.from(s.cats.keys())) m.set(c, (m.get(c) ?? 0) + 1);
    return m;
  }, [stats]);

  const needle = query.trim().toLowerCase();
  const rows = useMemo(() => assets
    .filter((a) => {
      const s = stats.get(a.id);
      if ((changedOnly || category !== 'all') && !s) return false;
      if (category !== 'all' && !s?.cats.get(category)) return false;
      return !needle || [a.name, a.ip_address, a.host_name, a.asset_type].join(' ').toLowerCase().includes(needle);
    })
    .sort((x, y) => (stats.get(y.id)?.n ?? 0) - (stats.get(x.id)?.n ?? 0) || x.name.localeCompare(y.name)),
  [assets, stats, changedOnly, category, needle]);

  if (open) {
    return (
      <div className="space-y-2">
        <div className="flex flex-wrap items-center gap-2">
          <button type="button" onClick={() => setOpen(null)}
            className={`inline-flex items-center gap-1.5 h-8 rounded-[8px] px-2.5 text-[12.5px] font-semibold ${FOCUS}`}
            style={{ color: BRAND, background: '#EAF3FA', border: '1px solid #CFE3F2' }}>
            <ArrowLeft className="h-4 w-4" aria-hidden /> All assets
          </button>
          <h2 className="text-[16px] font-semibold" style={{ color: INK }}>
            <span className="font-normal" style={{ color: MUTED }}>Change history · </span>{open.name}
          </h2>
          {open.ip_address && <span className={`${MONO} rounded-[6px] px-2 py-[2px] bg-white`} style={{ border: `1px solid ${DIVIDER}`, color: SEC }}>{open.ip_address}</span>}
        </div>
        <ChangeHistory assetId={open.id} variant="tab" />
      </div>
    );
  }

  if (q.isLoading) return <StateMessage>Loading assets…</StateMessage>;
  if (q.isError) return <StateMessage tone="error">Could not load the asset list. Refresh the page to try again.</StateMessage>;

  const changedAssets = stats.size;
  const cats = CATEGORY_ORDER.filter((c) => catCount.get(c));
  return (
    <div className="space-y-2.5">
      <div className="rounded-[12px] bg-white p-2 flex flex-wrap items-center gap-2" style={CARD_STYLE}>
        <label className="relative flex-1 min-w-[200px] basis-[220px]">
          <span className="sr-only">Search assets</span>
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4" style={{ color: MUTED }} aria-hidden />
          <input className="search" value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search asset, IP or type"
            style={{ fontFamily: 'inherit', color: INK }} />
        </label>
        <div className="segwrap" role="group" aria-label="Which assets">
          {([[false, `All assets (${assets.length})`], [true, `Changed only (${changedAssets})`]] as const).map(([v, l]) => (
            <button key={String(v)} type="button" aria-pressed={changedOnly === v} onClick={() => setChangedOnly(v)}
              className={`${changedOnly === v ? 'seg on' : 'seg'} ${FOCUS}`} style={{ height: 28, padding: '0 11px', fontSize: 12 }}>{l}</button>
          ))}
        </div>
        {(query || category !== 'all') && (
          <button type="button" onClick={() => { setQuery(''); setCategory('all'); }}
            className={`inline-flex items-center gap-1 text-[11.5px] font-semibold rounded-[6px] ${FOCUS}`} style={{ color: BRAND }}>
            <X className="h-3.5 w-3.5" aria-hidden /> Clear
          </button>
        )}
      </div>
      {cats.length > 0 && (
        <div className="flex flex-wrap items-center gap-1.5" role="group" aria-label="Filter by category changed">
          <span className="text-[11.5px] mr-1" style={{ color: MUTED }}>Changed in</span>
          {['all', ...cats].map((c) => {
            const on = category === c;
            const color = c === 'all' ? BRAND : categoryMeta(c).color;
            return (
              <button key={c} type="button" aria-pressed={on} onClick={() => setCategory(c)}
                className={`inline-flex items-center gap-1 rounded-full px-2.5 h-[26px] text-[12px] font-medium ${FOCUS}`}
                style={on ? { background: color, color: '#fff', border: `1px solid ${color}` } : { background: '#fff', color, border: `1px solid ${color}55` }}>
                {c === 'all' ? 'Any category' : categoryMeta(c).label}
                {c !== 'all' && <span className="tabular-nums opacity-80">{catCount.get(c)}</span>}
              </button>
            );
          })}
        </div>
      )}
      <section className="rounded-[12px] bg-white overflow-hidden" style={CARD_STYLE} aria-label="Assets and their changes">
        <h3 className="flex items-center gap-2 px-3 py-2" style={{ background: '#EAF3FA', boxShadow: `inset 3px 0 0 ${BRAND}` }}>
          <span className="text-[13.5px] font-semibold" style={{ color: BRAND }}>Assets</span>
          <span className="ml-auto text-[11.5px]" style={{ color: MUTED }}>
            <span className="inline-flex items-center rounded-full px-2 py-[1px] font-semibold" style={{ background: BRAND, color: '#fff' }}>
              {changedAssets} of {assets.length} changed
            </span>
            <span className="ml-2">{periodLabel} · click an asset to see its fields</span>
          </span>
        </h3>
        <div className={`hidden ${ROW} px-3 py-1.5 text-[11px] font-semibold uppercase tracking-[0.05em] border-y`}
          style={{ color: '#014A81', background: '#F7FAFD', borderColor: '#DCE9F3' }}>
          <span>Asset</span><span>Changes</span><span>Fields</span><span>What changed (by category)</span><span>Source</span><span>Last change</span><span />
        </div>
        {rows.length ? (
          <ul className="divide-y divide-[#F0F3F5]">
            {rows.map((a) => <AssetRow key={a.id} a={a} s={stats.get(a.id)} onOpen={() => setOpen(a)} />)}
          </ul>
        ) : <StateMessage>No assets match.</StateMessage>}
      </section>
    </div>
  );
}
