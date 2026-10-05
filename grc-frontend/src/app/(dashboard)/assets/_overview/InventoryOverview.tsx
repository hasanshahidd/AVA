'use client';

/**
 * IT Asset Inventory — Overview: the inventory-native C-level view of the estate.
 *
 *   1. Estate header — size, health, onboarding and hygiene of the whole estate.
 *   2. External | Internal — two panels, each on its OWN scale, so a 2-asset internal
 *      estate reads as clearly as 243 external names. External: by type + what the
 *      outside-in probe verified. Internal: by infrastructure type + by OS (Windows
 *      Server vs client). Fixed taxonomies, counts + share — same shape at 5 or 5,000.
 *   3. Asset-class matrix — rows = classes, columns = count, share, seen ≤30d, owner,
 *      CIS, criticality mix, end-of-life — beside the needs-attention list.
 *
 * Every number is live: /estate-overview (read-only aggregate that buckets each asset
 * from its own signals; counts only), /assets/inventory-overview (health + assessment
 * facts) and /discovery/discovered-devices (onboarding). Nothing is sampled or invented:
 * a failing source says so, an empty class says "none found", unknowns stay grey.
 */
import { useEffect, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { AlertTriangle, ArrowRight, ChevronRight, Globe, Layers, RefreshCw, Server, ShieldCheck } from 'lucide-react';
import apiClient, { discoveryApi } from '@/lib/api';
import { SCORECARD_QUERY_KEYS } from '@/components/dashboard/scorecard-query-keys';
import {
  BAND, CARD_SHADOW, Empty, FONT, Key, Loading, Pill, SEV, Skel, T, Unavailable,
  alpha, nfmt, pctOf, plural, share, type Tone,
} from '../../dashboard/_components/kit';

/* ---------- API shapes (only the fields this page reads) ---------- */
type Sub = { label: string; n: number; gap: boolean; subtypes?: Sub[] };
type Crit = Record<'critical' | 'high' | 'medium' | 'low' | 'unrated', number>;
type Eol = { past: number; soon: number; known: number };
type Cls = { label: string; n: number; gap: boolean; subtypes: Sub[]; seen_30d: number; owner: number; cis: number | null; crit: Crit; eol: Eol | null };
type Side = { total: number; classes: Cls[]; facets: Record<string, number>; verification?: Sub[]; os?: Sub[] };
type Estate = {
  total: number; external: Side; internal: Side; unidentified: number;
  coverage: { seen_30d: number; owner: number; cis: number }; eol: Eol; lifecycle: { label: string; n: number }[];
};
type InvOverview = {
  no_data?: boolean;
  performance?: { score: number | null; grade: string | null };
  attention_queue?: { assets_unassessed: number; open_critical_high_vulns: number };
};
type Devices = { devices?: { in_inventory?: boolean; connectable?: boolean }[] };
type Q<X> = { data?: X | null; isLoading: boolean; isError: boolean; isFetching?: boolean };
const busy = (q: Q<unknown>) => !!q.isFetching && !q.isLoading;

const KEYS = {
  estate: ['assets', 'estate-overview'], // under ['assets'] so register edits refresh it too
  inv: [...SCORECARD_QUERY_KEYS.assets], // shared with the register scorecard + Performance
  devices: ['disc-discovered-devices', 'all'],
};
const REG = '/assets?tab=inventory';
/** /assets reads ?tab= only when it mounts, so a client-side push to another tab of THIS
    page would change the URL but leave the Overview showing — same-page links navigate for
    real; every other route keeps Next's client-side Link. */
function Go({ href, ...rest }: { href: string; className?: string; title?: string; children: ReactNode }) {
  return href.startsWith('/assets?') ? <a href={href} {...rest} /> : <Link href={href} {...rest} />;
}
/* External / Internal identity: the product's base blue and success green — a validated
   categorical pair (CVD ΔE 14.9, normal 15.5), always shown with its label + icon.
   Unknown buckets (unprobed, unidentified, OS not visible) are neutral grey. */
const SIDE = {
  external: { c: T.base, name: 'External attack surface', blurb: 'Internet-facing names & services, verified outside-in', icon: Globe, view: 'external' },
  internal: { c: T.success, name: 'Internal estate', blurb: 'Hosts & devices on your networks, read with credentials', icon: Server, view: 'internal' },
} as const;
const GREY = '#CBD5E1';
const CRIT: { k: keyof Crit; label: string; c: string }[] = [
  { k: 'critical', label: 'Critical', c: SEV.critical.c }, { k: 'high', label: 'High', c: SEV.high.c },
  { k: 'medium', label: 'Medium', c: SEV.medium.c }, { k: 'low', label: 'Low', c: SEV.low.c },
  { k: 'unrated', label: 'Unrated', c: GREY },
];
// Rows always shown (the taxonomy a reader expects); the rest appear only when present.
const INT_CORE = ['Server', 'Workstation / endpoint', 'Database', 'Network device', 'Unidentified'];
const OS_CORE = ['Windows Server', 'Windows client', 'Linux', 'macOS', 'Network OS'];
const absentNote = (labels: string[]) => (labels.length ? `Also tracked, none found: ${labels.join(' · ')}` : undefined);
/* Page-scope fixes, injected once by the overview:
   1. flip the (cream) asset-suite canvas to the dashboard grey so the white cards lift off it;
   2. the asset page wraps every tab in `.assets-light`, whose global rules paint h2/p/li/span/
      td pure black (td !important) and outrank Tailwind's colour utilities — it flattened every
      muted label here. Inside the overview: inherit by default, re-assert the colours we use. */
const INK = ['#0F172A', '#334155', '#475569', '#64748B', '#94A3B8', '#CBD5E1', '#005B96'];
const SCOPE_CSS = [
  '.asset-suite:has([data-inv-overview]),main:has([data-inv-overview]){background:#EDF0F5}',
  '[data-inv-overview] :is(h1,h2,h3,h4,h5,p,li,label,span){color:inherit}',
  '[data-inv-overview] :is(table,tr,td){color:inherit!important}',
  '[data-inv-overview] td{font-size:inherit}',
  ...INK.map((c) => `[data-inv-overview] [class~="text-[${c}]"]{color:${c}!important}`),
  '[data-inv-overview] [class~="hover:text-[#014A81]"]:hover{color:#014A81!important}',
  '[data-inv-overview] a:hover>span[class~="text-[#334155]"]{color:#005B96!important}',
].join('');

export default function InventoryOverview() {
  const qc = useQueryClient();
  const estateQ = useQuery<Estate>({ queryKey: KEYS.estate, queryFn: async () => (await apiClient.get('/estate-overview')).data });
  const invQ = useQuery<InvOverview | null>({
    queryKey: KEYS.inv,
    queryFn: async () => { try { return (await apiClient.get('/assets/inventory-overview')).data; } catch { return null; } },
  });
  const devicesQ = useQuery<Devices>({ queryKey: KEYS.devices, queryFn: async () => (await discoveryApi.discoveredDevices()).data, retry: 1 });

  const all = [estateQ, invQ, devicesQ];
  const fetching = all.some((q) => q.isFetching);
  const failed = all.filter((q) => q.isError).length + (invQ.isSuccess && invQ.data === null ? 1 : 0);
  const latest = Math.max(0, ...all.map((q) => q.dataUpdatedAt || 0));
  const [updated, setUpdated] = useState(0);
  useEffect(() => { if (!fetching && latest) setUpdated(latest); }, [fetching, latest]);
  const refresh = () => Object.values(KEYS).forEach((queryKey) => qc.invalidateQueries({ queryKey, refetchType: 'all' }));

  const d = estateQ.data;
  return (
    <div data-inv-overview className="mx-auto grid w-full max-w-[1950px] grid-cols-1 gap-3 text-[#0F172A] xl:grid-cols-12" style={{ fontFamily: FONT, zoom: 0.8 }}>
      <style>{SCOPE_CSS}</style>
      <EstateHeader estate={estateQ} inv={invQ} devices={devicesQ} className="xl:col-span-12"
        stamp={
          <div className="flex shrink-0 items-center gap-3 px-5 text-[12px] text-[#64748B]">
            <span aria-live="polite" className="whitespace-nowrap">
              {updated ? `Live · ${new Date(updated).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}` : 'Loading…'}
              {!fetching && failed > 0 && <span className="ml-2 inline-flex items-center gap-1"><AlertTriangle size={12} aria-hidden style={{ color: T.warning }} />{plural(failed, 'source')} didn&rsquo;t respond</span>}
            </span>
            <button type="button" onClick={refresh} disabled={fetching} aria-label="Refresh"
              className="grid h-8 w-8 place-items-center rounded-[9px] border border-[#E2E5EC] bg-white text-[#334155] hover:bg-[#F6F7FB] disabled:cursor-default disabled:opacity-70">
              <RefreshCw size={14} aria-hidden className={fetching ? 'animate-spin' : ''} style={{ color: T.base }} />
            </button>
          </div>
        } />
      <SidePanel kind="external" q={estateQ} className="xl:col-span-6"
        lists={d ? [
          { title: 'By type', rows: d.external.classes.map(asRow) },
          { title: 'Outside-in verification', rows: d.external.verification ?? [] },
        ] : []}
        stats={d ? [
          { label: 'Probed outside-in', value: share(d.external.facets.probed, d.external.total) || '0%', sub: `${nfmt(d.external.facets.probed)} of ${nfmt(d.external.total)} names` },
          { label: 'Behind CDN / WAF', value: nfmt(d.external.facets.cdn_waf), sub: `of ${nfmt(d.external.facets.probed)} probed` },
          { label: 'TLS certificate expired', value: nfmt(d.external.facets.tls_expired), alarm: d.external.facets.tls_expired > 0 },
          { label: 'TLS expiring ≤30 days', value: nfmt(d.external.facets.tls_expiring_30d), alarm: d.external.facets.tls_expiring_30d > 0 },
        ] : []} />
      <SidePanel kind="internal" q={estateQ} className="xl:col-span-6"
        lists={d ? [
          { title: 'By infrastructure type', rows: d.internal.classes.filter((c) => c.n > 0 || INT_CORE.includes(c.label)).map(asRow) },
          { title: 'By operating system', rows: (d.internal.os ?? []).filter((o) => o.n > 0 || OS_CORE.includes(o.label)).map((o) => ({ ...o, suffix: versions(o) })) },
        ] : []}
        note={d ? absentNote(d.internal.classes.filter((c) => !c.n && !INT_CORE.includes(c.label)).map((c) => c.label)) : undefined}
        stats={d ? [
          { label: 'OS profiled', value: share(d.internal.facets.os_profiled, d.internal.total) || '0%', sub: `${nfmt(d.internal.facets.os_profiled)} of ${nfmt(d.internal.total)}` },
          { label: 'CIS benchmarked', value: share(d.coverage.cis, d.internal.total) || '0%', sub: `${nfmt(d.coverage.cis)} of ${nfmt(d.internal.total)}` },
          { label: 'End-of-life dated', value: share(d.eol.known, d.internal.total) || '0%', sub: `${nfmt(d.eol.known)} of ${nfmt(d.internal.total)}` },
          { label: 'Past vendor end-of-life', value: nfmt(d.eol.past), sub: `${nfmt(d.eol.soon)} due ≤90 days`, alarm: d.eol.past > 0 },
        ] : []} />
      <ClassMatrix q={estateQ} className="xl:col-span-8" />
      <AttentionCard estate={estateQ} inv={invQ} className="xl:col-span-4" />
    </div>
  );
}

type Row = { label: string; n: number; gap: boolean; suffix?: string };
const asRow = (c: Cls): Row => ({ label: c.label, n: c.n, gap: c.gap });
/** "11 ×2 · 10 ×1" — the versions behind an OS row, without repeating the family. */
const versions = (o: Sub) => (o.subtypes ?? []).filter((s) => s.label !== o.label)
  .map((s) => `${s.label.replace(/^Windows (Server )?/, '')} ×${nfmt(s.n)}`).slice(0, 3).join(' · ');

/* ---------- shared card chrome (one header style for every surface) ---------- */
function Box({ title, sub, aside, accent, busy: dim, className = '', children }: {
  title: ReactNode; sub?: ReactNode; aside?: ReactNode; accent?: string; busy?: boolean; className?: string; children: ReactNode;
}) {
  return (
    <section aria-busy={dim || undefined}
      className={`flex min-w-0 flex-col rounded-[14px] border border-[#E2E5EC] bg-white px-5 pb-4 pt-4 ${CARD_SHADOW} ${className}`}
      style={accent ? { borderTop: `3px solid ${accent}` } : undefined}>
      <header className="mb-3 flex items-start gap-3">
        <div className="min-w-0 flex-1">
          <h2 className="m-0 truncate font-semibold text-[#0F172A] !text-[14.5px] !leading-[1.3]">{title}</h2>
          {sub && <p className="m-0 mt-0.5 truncate text-[12px] text-[#64748B]">{sub}</p>}
        </div>
        {aside}
      </header>
      <div className={`flex min-h-0 flex-1 flex-col transition-opacity duration-200 ${dim ? 'opacity-50' : ''}`}>{children}</div>
    </section>
  );
}
const MoreLink = ({ href, children }: { href: string; children: ReactNode }) => (
  <Go href={href} className="inline-flex shrink-0 items-center gap-1 whitespace-nowrap rounded-md text-[12px] font-semibold text-[#005B96] hover:text-[#014A81] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#005B96]">
    {children}<ArrowRight size={13} aria-hidden />
  </Go>
);

/* ---------- 1) Estate header ---------- */
const GRADE_TONE: Record<string, Tone> = {
  excellent: { ...BAND.contained, label: 'Excellent' }, good: { ...BAND.contained, label: 'Good' },
  fair: { ...SEV.medium, label: 'Fair' }, poor: { ...SEV.critical, label: 'Poor' },
};

function EstateHeader({ estate, inv, devices, stamp, className }: { estate: Q<Estate>; inv: Q<InvOverview>; devices: Q<Devices>; stamp: ReactNode; className: string }) {
  const d = estate.data;
  const p = inv.data?.performance;
  const devs = devices.data?.devices ?? [];
  const onboarded = devs.filter((x) => x.in_inventory).length;
  const active = d?.lifecycle.find((l) => l.label === 'active')?.n ?? 0;
  const tone = GRADE_TONE[p?.grade ?? ''] ?? BAND.unknown;
  const cells: { key: string; label: string; href: string; loading: boolean; value: ReactNode; sub: ReactNode }[] = [
    { key: 'estate', label: 'Asset estate', href: REG, loading: estate.isLoading,
      value: d ? nfmt(d.total) : '—', sub: d ? <><Dot c={SIDE.external.c} />{nfmt(d.external.total)} external<Dot c={SIDE.internal.c} />{nfmt(d.internal.total)} internal</> : 'unavailable' },
    { key: 'health', label: 'Inventory health', href: '/risk-posture', loading: inv.isLoading,
      value: p?.score != null ? <span className="inline-flex items-baseline gap-2">{p.score.toFixed(1)}<span className="text-[12px] font-medium text-[#64748B]">/ 100</span><Pill tone={tone}>{tone.label}</Pill></span> : '—',
      sub: p?.score != null ? 'target 85 · see Risk posture' : inv.data ? 'not scored yet' : 'unavailable' },
    { key: 'onboarded', label: 'Onboarded from discovery', href: '/asset-discovery', loading: devices.isLoading,
      value: devs.length ? `${pctOf(onboarded, devs.length)}%` : '—', sub: devices.data ? (devs.length ? `${nfmt(onboarded)} of ${nfmt(devs.length)} discovered devices` : 'nothing discovered yet') : 'unavailable' },
    { key: 'seen', label: 'Seen in last 30 days', href: `${REG}&view=stale`, loading: estate.isLoading,
      value: d?.total ? share(d.coverage.seen_30d, d.total) || '0%' : '—', sub: d ? `${nfmt(d.coverage.seen_30d)} of ${nfmt(d.total)} assets` : 'unavailable' },
    { key: 'owner', label: 'Owner assigned', href: `${REG}&view=unowned`, loading: estate.isLoading,
      value: d?.total ? share(d.coverage.owner, d.total) || '0%' : '—', sub: d ? `${nfmt(d.coverage.owner)} of ${nfmt(d.total)} assets` : 'unavailable' },
    { key: 'life', label: 'In active service', href: REG, loading: estate.isLoading,
      value: d?.total ? share(active, d.total) || '0%' : '—', sub: d ? `${nfmt(active)} active · ${nfmt(d.total - active)} other states` : 'unavailable' },
  ];
  return (
    <section aria-label="Estate summary" className={`flex min-w-0 flex-col overflow-hidden rounded-[14px] border border-[#E2E5EC] bg-white lg:flex-row lg:items-stretch ${CARD_SHADOW} ${className}`}>
      <div className="grid min-w-0 flex-1 grid-cols-2 md:grid-cols-3 xl:grid-cols-6">
        {cells.map((c, i) => (
          <Go key={c.key} href={c.href}
            className={`group flex min-w-0 flex-col justify-center px-5 py-2.5 transition hover:bg-[#F6F7FB] focus-visible:outline focus-visible:outline-2 focus-visible:-outline-offset-2 focus-visible:outline-[#005B96] ${i ? 'border-l border-[#EEF1F5]' : ''}`}>
            <span className="flex items-center gap-1 truncate text-[11.5px] font-medium text-[#64748B]">{c.label}<ChevronRight size={12} aria-hidden className="text-[#CBD5E1] transition group-hover:translate-x-0.5 group-hover:text-[#64748B]" /></span>
            {c.loading ? <Skel h={24} w="55%" className="my-1" /> : <span className="mt-0.5 truncate text-[22px] font-semibold leading-[1.2] text-[#0F172A]">{c.value}</span>}
            <span className="truncate text-[11.5px] text-[#64748B]">{c.sub}</span>
          </Go>
        ))}
      </div>
      <div className="flex items-center justify-end border-t border-[#EEF1F5] py-2 lg:border-l lg:border-t-0 lg:py-0">{stamp}</div>
    </section>
  );
}
const Dot = ({ c }: { c: string }) => <i aria-hidden className="ml-2.5 mr-1 inline-block h-[7px] w-[7px] rounded-full align-middle first:ml-0" style={{ background: c }} />;

/* ---------- 2) External | Internal panels ---------- */
type Stat = { label: string; value: string; sub?: string; alarm?: boolean };
function SidePanel({ kind, q, lists, note, stats, className }: {
  kind: keyof typeof SIDE; q: Q<Estate>; lists: { title: string; rows: Row[] }[]; note?: string; stats: Stat[]; className: string;
}) {
  const s = SIDE[kind];
  const d = q.data;
  const side = d?.[kind];
  const Icon = s.icon;
  const title = (
    <span className="flex items-center gap-2.5">
      <span aria-hidden className="grid h-[30px] w-[30px] shrink-0 place-items-center rounded-[9px]" style={{ background: alpha(s.c, 0.1), color: s.c }}><Icon size={16} /></span>
      <span className="min-w-0">
        <span className="block truncate">{s.name}</span>
        <span className="block truncate text-[12px] font-normal text-[#64748B]">{s.blurb}</span>
      </span>
    </span>
  );
  const aside = side ? (
    <div className="flex shrink-0 flex-col items-end">
      <span className="text-[28px] font-semibold leading-none text-[#0F172A]">{nfmt(side.total)}</span>
      <span className="mt-1 flex items-center gap-3 text-[12px] text-[#64748B]">{share(side.total, d!.total) || '0%'} of estate<MoreLink href={`${REG}&view=${s.view}`}>Register</MoreLink></span>
    </div>
  ) : null;
  let body: ReactNode;
  if (q.isLoading) body = <div className="grid flex-1 grid-cols-2 gap-7">{[0, 1].map((i) => <Loading key={i} rows={6} />)}</div>;
  else if (!d || !side) body = <Unavailable what={s.name} />;
  else if (!side.total) body = (
    <Empty icon={kind === 'external' ? <Globe size={16} /> : <Server size={16} />}
      title={kind === 'external' ? 'No external assets yet' : 'No internal assets yet'}
      body={kind === 'external' ? 'Run an external (outside-in) discovery to map your attack surface.' : 'Connect a host from Discovery or import a register to see types and operating systems here.'}
      href="/asset-discovery" cta="Open Discovery" />
  );
  else body = (
    <>
      <div className="grid flex-1 grid-cols-1 gap-x-8 gap-y-4 sm:grid-cols-2">
        {lists.map((l) => <BarList key={l.title} title={l.title} rows={l.rows} total={side.total} color={s.c} where={kind} />)}
      </div>
      {note && <p className="m-0 mt-1.5 truncate text-[11.5px] text-[#94A3B8]" title={note}>{note}</p>}
      <dl className="m-0 mt-3 grid grid-cols-2 border-t border-[#EEF1F5] pt-3 md:grid-cols-4">
        {stats.map((st, i) => (
          <div key={st.label} className={`min-w-0 px-3 first:pl-0 ${i ? 'md:border-l md:border-[#EEF1F5]' : ''}`}>
            <dt className="truncate text-[11.5px] text-[#64748B]">{st.label}</dt>
            <dd className="m-0 mt-0.5 flex min-w-0 items-baseline gap-1.5 text-[18px] font-semibold leading-[1.25]" style={{ color: st.alarm ? SEV.critical.ink : T.text }}>
              {st.alarm && <AlertTriangle size={14} aria-label="Needs attention" className="self-center" />}{st.value}
              {st.sub && <span className="truncate text-[11.5px] font-normal text-[#94A3B8]">{st.sub}</span>}
            </dd>
          </div>
        ))}
      </dl>
    </>
  );
  return <Box title={title} aside={aside} accent={s.c} busy={busy(q)} className={className}>{body}</Box>;
}

/** Fixed-taxonomy bar list on its own scale (the longest bar = this list's largest bucket),
    so a 2-asset side reads as clearly as a 243-asset one. Two-line rows give the label the
    full width (never clipped) and the bar the full track; rows share the panel height. */
function BarList({ title, rows, total, color, where }: { title: string; rows: Row[]; total: number; color: string; where: string }) {
  const max = Math.max(1, ...rows.map((r) => r.n));
  return (
    <div className="flex min-w-0 flex-col">
      <div className="mb-0.5 flex items-baseline gap-2 text-[11px] font-semibold uppercase tracking-[.06em] text-[#94A3B8]">
        <span className="min-w-0 flex-1 truncate">{title}</span><span className="w-[40px] text-right">No.</span><span className="w-[40px] text-right">Share</span>
      </div>
      <ul className="m-0 flex flex-1 list-none flex-col p-0">
        {rows.map((r) => (
          <li key={r.label} title={`${r.label}: ${nfmt(r.n)} · ${share(r.n, total) || '0%'} of ${where}${r.suffix ? ` (${r.suffix})` : ''}`}
            className="flex min-h-[31px] flex-1 flex-col justify-center gap-[4px]">
            <div className="flex items-baseline gap-2">
              <span className={`min-w-0 flex-1 truncate text-[12.5px] ${r.n ? 'text-[#0F172A]' : 'text-[#94A3B8]'}`}>
                {r.label}{r.suffix ? <span className="text-[11.5px] text-[#94A3B8]"> · {r.suffix}</span> : null}
              </span>
              <span className={`w-[40px] text-right text-[13px] font-semibold tabular-nums ${r.n ? 'text-[#0F172A]' : 'text-[#CBD5E1]'}`}>{nfmt(r.n)}</span>
              <span className="w-[40px] text-right text-[12px] tabular-nums text-[#64748B]">{r.n ? share(r.n, total) : '—'}</span>
            </div>
            <div className="h-[6px] rounded-full bg-[#F1F4F8]">
              {r.n > 0 && <div className="h-full min-w-[6px] rounded-full" style={{ width: `${(r.n / max) * 100}%`, background: r.gap ? GREY : color }} />}
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}

/* ---------- 3) Asset-class matrix ---------- */
function ClassMatrix({ q, className }: { q: Q<Estate>; className: string }) {
  const d = q.data;
  let body: ReactNode;
  if (q.isLoading) body = <Loading rows={8} />;
  else if (!d) body = <Unavailable what="Asset-class matrix" />;
  else if (!d.total) body = <Empty icon={<Layers size={16} />} title="No asset classes yet" body="Coverage by class appears once assets are in the inventory." href="/asset-discovery" cta="Bring assets in" />;
  else body = (
    <div className="-mx-1 overflow-x-auto px-1">
      <table className="w-full min-w-[820px] table-fixed border-collapse text-[12.5px]">
        <colgroup><col /><col className="w-[62px]" /><col className="w-[56px]" /><col className="w-[94px]" /><col className="w-[94px]" /><col className="w-[94px]" /><col className="w-[136px]" /><col className="w-[104px]" /></colgroup>
        <thead>
          <tr className="text-[11px] font-semibold uppercase tracking-[.05em] text-[#94A3B8]">
            <th className="pb-2 pl-3 text-left font-semibold">Asset class</th>
            <th className="pb-2 text-right font-semibold">Assets</th>
            <th className="pb-2 text-right font-semibold">Share</th>
            <th className="pb-2 text-right font-semibold" title="Seen by a scan or collector in the last 30 days">Seen ≤30d</th>
            <th className="pb-2 text-right font-semibold" title="Has an owner assigned">Owner</th>
            <th className="pb-2 text-right font-semibold" title="Has a CIS benchmark scan (host assets only)">CIS scan</th>
            <th className="pb-2 pl-4 text-left font-semibold">Criticality</th>
            <th className="pb-2 pr-3 text-right font-semibold" title="Vendor end-of-support of the detected OS, or the register's EOL date">End-of-life</th>
          </tr>
        </thead>
        <SideRows kind="external" side={d.external} estate={d.total} />
        <SideRows kind="internal" side={d.internal} estate={d.total} />
      </table>
    </div>
  );
  return (
    <Box title="Asset-class matrix" sub="Coverage and assurance for every class — the register, summarised" busy={busy(q)} className={className}
      aside={<div className="flex shrink-0 items-center gap-4">
        {d?.total ? <span className="hidden items-center gap-2.5 text-[11px] text-[#64748B] 2xl:inline-flex">{CRIT.map((x) => <span key={x.k} className="inline-flex items-center gap-1"><Key c={x.c} />{x.label}</span>)}</span> : null}
        <MoreLink href={REG}>Open register</MoreLink>
      </div>}>
      {body}
    </Box>
  );
}

const sumCrit = (cs: Cls[]): Crit => cs.reduce((acc, c) => { CRIT.forEach(({ k }) => { acc[k] += c.crit[k]; }); return acc; },
  { critical: 0, high: 0, medium: 0, low: 0, unrated: 0 } as Crit);

function SideRows({ kind, side, estate }: { kind: keyof typeof SIDE; side: Side; estate: number }) {
  const s = SIDE[kind];
  const external = kind === 'external';
  const present = side.classes.filter((c) => c.n > 0);
  const none = side.classes.filter((c) => c.n === 0).map((c) => c.label);
  const sum = (k: 'seen_30d' | 'owner') => present.reduce((acc, c) => acc + c[k], 0);
  const eol = external ? null : present.reduce((acc, c) => ({ past: acc.past + (c.eol?.past ?? 0), soon: acc.soon + (c.eol?.soon ?? 0), known: acc.known + (c.eol?.known ?? 0) }), { past: 0, soon: 0, known: 0 });
  const cell = 'py-2';
  return (
    <tbody>
      <tr className="font-semibold" style={{ background: alpha(s.c, 0.06) }}>
        <td className={`${cell} rounded-l-[8px] pl-3`} style={{ boxShadow: `inset 4px 0 0 ${s.c}` }}>
          <span className="flex items-center gap-2 text-[12px] uppercase tracking-[.06em] text-[#0F172A]">
            <s.icon size={13} aria-hidden style={{ color: s.c }} />{external ? 'External' : 'Internal'}
            {none.length > 0 && <span className="truncate text-[11px] font-normal normal-case tracking-normal text-[#94A3B8]" title={`None found: ${none.join(', ')}`}>· {none.length} of {side.classes.length} classes empty</span>}
          </span>
        </td>
        <td className={`${cell} text-right tabular-nums`}>{nfmt(side.total)}</td>
        <td className={`${cell} text-right tabular-nums text-[#64748B]`}>{share(side.total, estate) || '0%'}</td>
        <td className={cell}><Pct n={sum('seen_30d')} d={side.total} /></td>
        <td className={cell}><Pct n={sum('owner')} d={side.total} /></td>
        <td className={cell}><Pct n={external ? null : present.reduce((acc, c) => acc + (c.cis ?? 0), 0)} d={side.total} /></td>
        <td className={`${cell} pl-4`}><CritMix c={sumCrit(present)} /></td>
        <td className={`${cell} rounded-r-[8px] pr-3 text-right`}><EolCell e={eol} n={side.total} /></td>
      </tr>
      {present.map((c) => (
        <tr key={c.label} className="border-b border-[#F1F3F7]">
          <td className="py-1.5 pl-3 pr-3">
            <span className={`block truncate font-medium ${c.gap ? 'text-[#64748B]' : 'text-[#0F172A]'}`}>{c.label}</span>
            {/* One line of whole subtype chips: any that don't fit wrap onto a hidden second
                line (never cut mid-word); the full breakdown is in the tooltip. */}
            <span className="mt-0.5 flex h-[17px] flex-wrap gap-x-1.5 overflow-hidden text-[11.5px] leading-[17px] text-[#94A3B8]" title={c.subtypes.map((x) => `${x.label}: ${nfmt(x.n)}`).join(' · ')}>
              {c.subtypes.map((x, i) => <span key={x.label} className="whitespace-nowrap">{i > 0 && '· '}{x.label} <b className="font-semibold text-[#64748B]">{nfmt(x.n)}</b></span>)}
            </span>
          </td>
          <td className="py-1.5 text-right font-semibold tabular-nums">{nfmt(c.n)}</td>
          <td className="py-1.5 text-right tabular-nums text-[#64748B]">{share(c.n, side.total)}</td>
          <td className="py-1.5"><Pct n={c.seen_30d} d={c.n} /></td>
          <td className="py-1.5"><Pct n={c.owner} d={c.n} /></td>
          <td className="py-1.5"><Pct n={c.cis} d={c.n} /></td>
          <td className="py-1.5 pl-4"><CritMix c={c.crit} /></td>
          <td className="py-1.5 pr-3 text-right"><EolCell e={c.eol} n={c.n} /></td>
        </tr>
      ))}
    </tbody>
  );
}

function Pct({ n, d }: { n: number | null; d: number }) {
  if (n == null) return <span className="block text-right text-[12px] text-[#94A3B8]" title="Host benchmarks don't apply to outside-in assets">n/a</span>;
  if (!d) return <span className="block text-right text-[#CBD5E1]">—</span>;
  return (
    <span className="flex items-center justify-end gap-2" title={`${nfmt(n)} of ${nfmt(d)}`}>
      <span className="h-[5px] w-[40px] rounded-full bg-[#EEF1F5]"><span className="block h-full rounded-full" style={{ width: `${pctOf(n, d)}%`, background: T.base }} /></span>
      <span className="w-[38px] text-right tabular-nums">{share(n, d) || '0%'}</span>
    </span>
  );
}

function CritMix({ c }: { c: Crit }) {
  const parts = CRIT.filter((x) => c[x.k] > 0);
  if (!parts.length) return <span className="text-[#CBD5E1]">—</span>;
  const top = [...parts].sort((a, b) => c[b.k] - c[a.k])[0];
  return (
    <span className="flex items-center gap-2" title={parts.map((x) => `${x.label} ${nfmt(c[x.k])}`).join(' · ')}>
      <span className="flex h-[8px] w-[48px] shrink-0 gap-[2px]">
        {parts.map((x) => <span key={x.k} className="min-w-[3px] rounded-[2px]" style={{ flex: `${c[x.k]} 1 0px`, background: x.c }} />)}
      </span>
      <span className="truncate text-[12px] text-[#475569]">{top.label}{parts.length > 1 ? ` +${parts.length - 1}` : ''}</span>
    </span>
  );
}

function EolCell({ e, n }: { e: Eol | null; n: number }) {
  if (!e) return <span className="text-[12px] text-[#94A3B8]" title="OS end-of-life isn't observable from outside">n/a</span>;
  if (!n) return <span className="text-[#CBD5E1]">—</span>;
  if (!e.known) return <span className="text-[12px] text-[#94A3B8]" title="No EOL date on the register and no OS the vendor table covers">not tracked</span>;
  if (!e.past && !e.soon) return <span className="text-[12px] text-[#475569]" title={`End-of-life known for ${nfmt(e.known)} of ${nfmt(n)} — none past or due within 90 days`}>In support</span>;
  return (
    <span className="whitespace-nowrap text-[12px]" title={`End-of-life known for ${nfmt(e.known)} of ${nfmt(n)}`}>
      {e.past > 0 && <b className="font-semibold" style={{ color: SEV.critical.ink }}>{nfmt(e.past)} past</b>}
      {e.past > 0 && e.soon > 0 && ' · '}
      {e.soon > 0 && <b className="font-semibold" style={{ color: SEV.high.ink }}>{nfmt(e.soon)} ≤90d</b>}
    </span>
  );
}

/* ---------- needs attention ---------- */
function AttentionCard({ estate, inv, className }: { estate: Q<Estate>; inv: Q<InvOverview>; className: string }) {
  const d = estate.data;
  const aq = inv.data?.attention_queue;
  const rows = d ? [
    { label: 'Assets without an owner', n: d.total - d.coverage.owner, href: `${REG}&view=unowned` },
    { label: 'External names never probed', n: d.external.total - d.external.facets.probed, href: '/asset-discovery' },
    { label: 'Not formally assessed', n: aq ? Math.min(aq.assets_unassessed, d.total) : null, href: REG },
    { label: 'Open critical & high vulnerabilities', n: aq ? aq.open_critical_high_vulns : null, href: '/vulnerabilities' },
    { label: 'TLS certificates expired or ≤30 days', n: d.external.facets.tls_expired + d.external.facets.tls_expiring_30d, href: `${REG}&view=external` },
    { label: 'Past vendor end-of-life', n: d.eol.past, href: `${REG}&view=internal` },
    { label: 'Not seen in 30+ days', n: d.total - d.coverage.seen_30d, href: `${REG}&view=stale` },
    { label: 'Unidentified assets', n: d.unidentified, href: REG },
  ].sort((a, b) => (b.n ?? -1) - (a.n ?? -1)) : [];
  let body: ReactNode;
  if (estate.isLoading) body = <Loading rows={8} />;
  else if (!d) body = <Unavailable what="Attention list" />;
  else if (!d.total) body = <Empty icon={<ShieldCheck size={16} />} title="Nothing to action yet" body="Gaps appear once the inventory has assets." />;
  else body = (
    <ul className="m-0 flex flex-1 list-none flex-col p-0">
      {rows.map((r) => (
        <li key={r.label} className="flex flex-1 border-b border-[#F1F3F7] last:border-0">
          <Go href={r.href} className="group flex min-h-[30px] flex-1 items-center gap-3 text-[12.5px] hover:text-[#005B96]">
            <span aria-hidden className="h-[8px] w-[8px] shrink-0 rounded-full" style={{ background: r.n ? SEV.high.c : GREY }} />
            <span className={`min-w-0 flex-1 truncate ${r.n ? 'text-[#334155]' : 'text-[#94A3B8]'}`}>{r.label}</span>
            <b className="w-[48px] shrink-0 text-right text-[14px] font-semibold tabular-nums" style={{ color: r.n ? T.text : GREY }} title={r.n == null ? 'Source unavailable' : undefined}>{nfmt(r.n)}</b>
            <ChevronRight size={14} aria-hidden className="shrink-0 text-[#CBD5E1] transition group-hover:translate-x-0.5 group-hover:text-[#64748B]" />
          </Go>
        </li>
      ))}
    </ul>
  );
  return <Box title="Needs attention" sub="Largest gaps first — each opens the matching list" busy={busy(estate)} className={className}>{body}</Box>;
}
