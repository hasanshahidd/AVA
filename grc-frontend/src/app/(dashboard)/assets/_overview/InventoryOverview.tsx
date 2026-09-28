'use client';

/**
 * IT Asset Inventory — Overview: the executive (C-level) view of the ASSET ESTATE.
 *
 * Same treatment as the Performance dashboard (product tokens, Poppins, the soft 3D
 * card shadow, zoom 0.8, honest empty states) — reuses its kit/charts primitives — but
 * focused on the estate: how big is it, how is it made up, how much is covered/assured,
 * what's exposed, what's ageing out, and what needs attention.
 *
 * Honesty rules mirror Performance: every number is live from an asset endpoint (the
 * scored /assets/inventory-overview aggregate, /assets/dashboard, the register list,
 * risk posture, discovery). Nothing is sampled or invented — a metric with no data shows
 * an empty state, never a fabricated 0/100. Each query is independent so a slow (risk
 * posture scores every asset live) or failing source only affects its own card.
 */
import { useEffect, useMemo, useState, type ReactNode } from 'react';
import Link from 'next/link';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { AlertTriangle, ArrowRight, Boxes, CalendarClock, ClipboardCheck, Gauge as GaugeIcon, Globe, Layers, RefreshCw, ShieldCheck } from 'lucide-react';
import apiClient, { assetsApi, discoveryApi, riskPostureApi } from '@/lib/api';
import { SCORECARD_QUERY_KEYS } from '@/components/dashboard/scorecard-query-keys';
import type { ITAsset } from '@/types';
import {
  BAND, CARD_SHADOW, Card, Empty, Eyebrow, FONT, Figure, Loading, Pill, SEV, Skel, T, Unavailable,
  alpha, nfmt, pctOf, plural, share, toBand, type Tone,
} from '../../dashboard/_components/kit';
import { BarList, Gauge, PartLegend, StackBar, type BarRow, type Part } from '../../dashboard/_components/charts';

/* ---------- API shapes (only the fields this page reads) ---------- */
type Qs<X> = { data?: X | null; isLoading: boolean; isError: boolean; isFetching?: boolean };
const busyOf = (...qs: Qs<unknown>[]) => qs.some((q) => !!q.isFetching && !q.isLoading);
type Metric = { key: string; label: string; score: number | null; numerator: number; denominator: number; weight: number; target: number };
type Section = { key: string; label: string; score: number | null; weight: number; metrics: Metric[]; counts?: Record<string, number> };
type InvOverview = {
  no_data?: boolean;
  counts?: { assets: number; vulnerabilities: number; open_vulnerabilities: number };
  performance?: { score: number | null; grade: string | null; components: { key: string; label: string; score: number | null; weight: number; target: number }[] };
  sections?: Record<string, Section>;
  attention_queue?: { assets_without_owner: number; assets_unassessed: number; open_critical_high_vulns: number; stale_assets: number; internet_facing_unassessed: number; total: number };
};
type RiskAsset = { id: number; name: string; asset_type?: string | null; mode?: string | null; score: number | null; band?: { label: string } };
type RiskDash = { assets: RiskAsset[]; summary: { asset_count: number; scored_count: number; avg_score: number | null; by_band: Record<string, number> } };
type Devices = { devices?: { in_inventory?: boolean; connectable?: boolean }[]; runs?: { finished_at: string | null; is_latest?: boolean }[] };

const KEYS = {
  // Dedicated key + high limit: the register's ['assets'] is capped at 100 by the
  // list endpoint, but estate splits (provenance / environment / EOL / lifecycle)
  // must cover EVERY asset. Separate key so we never clobber the register's cache.
  assets: ['assets', 'overview-all'],
  inv: [...SCORECARD_QUERY_KEYS.assets], // shared with InventoryScorecard + the Performance dashboard
  risk: ['risk-posture.dashboard'],
  devices: ['disc-discovered-devices', 'all'],
};
const ALL_KEYS = Object.values(KEYS);

const titleCase = (s: string) => s.replace(/[_-]/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase());
const isExternal = (a: ITAsset) => (a.origin_source || '').toLowerCase() === 'easm';

// The list response now carries these OS/platform columns (schema-exposed) so the
// estate can be bucketed by OS and device category client-side, scalable to thousands
// (fixed buckets, never a per-asset list). ITAsset's type doesn't declare them yet.
type AssetRow = ITAsset & { os_family?: string | null; os_version?: string | null; os_normalized?: string | null; platform_kind?: string | null; is_internet_facing?: boolean | null };

/* ---- By OS: os_family first, fall back to parsing os_version. No OS = honest "not visible". ---- */
const OS_ORDER = ['Windows', 'Linux', 'macOS', 'Network OS', 'Other OS', 'OS not visible'];
const OS_COLOR: Record<string, string> = { Windows: '#005B96', Linux: '#047857', macOS: '#475569', 'Network OS': '#7A5CA8', 'Other OS': '#B45309', 'OS not visible': '#CBD5E1' };
function osBucketOf(a: AssetRow): string {
  const fam = (a.os_family || '').toLowerCase();
  const ver = (a.os_version || a.os_normalized || '');
  if (!fam && !ver) return 'OS not visible';
  const s = `${fam} ${ver}`.toLowerCase();
  if (/windows|win32|win64|microsoft/.test(s)) return 'Windows';
  if (/ubuntu|debian|cent ?os|rhel|red ?hat|fedora|suse|rocky|alma|amazon linux|oracle linux|\blinux\b/.test(s)) return 'Linux';
  if (/mac ?os|darwin|os x|\bosx\b/.test(s)) return 'macOS';
  if (/nx-?os|ios[ -]?xe|junos|\beos\b|fortios|pan-?os|routeros|comware|aruba|cisco ios/.test(s)) return 'Network OS';
  return 'Other OS';
}

/* ---- By category: platform_kind (the real typed-asset signal) first, then asset_type,
   then OS role, then internet-facing → external. No signal = Unclassified. ---- */
const CAT_ORDER = ['Server', 'Workstation', 'Database', 'Network device', 'Web / App', 'External / internet-facing', 'Unclassified'];
const CAT_COLOR: Record<string, string> = { Server: '#005B96', Workstation: '#0891B2', Database: '#7A5CA8', 'Network device': '#B45309', 'Web / App': '#2563EB', 'External / internet-facing': '#64748B', Unclassified: '#CBD5E1' };
function categoryBucketOf(a: AssetRow): string {
  const pk = (a.platform_kind || '').toLowerCase();
  const at = (a.asset_type || '').toLowerCase();
  const os = osBucketOf(a);
  const inet = !!(a.internet_facing || a.is_internet_facing);
  if (pk === 'database') return 'Database';
  if (pk === 'network') return 'Network device';
  if (pk === 'server' || pk === 'cluster') return 'Server';
  if (pk === 'workstation' || pk === 'desktop' || pk === 'client' || pk === 'endpoint') return 'Workstation';
  if (pk === 'web' || pk === 'app' || pk === 'application') return 'Web / App';
  if (/database|\bdb\b|sql|postgres|mysql|oracle|mssql|mongo/.test(at)) return 'Database';
  if (/network|router|switch|firewall|gateway|\bwlc\b/.test(at) || os === 'Network OS') return 'Network device';
  if (/\bweb\b|application|\bapp\b|http|website/.test(at)) return 'Web / App';
  if (/server/.test(at)) return 'Server';
  if (/workstation|laptop|desktop|endpoint/.test(at)) return 'Workstation';
  if (os === 'Windows') return /server/.test(`${a.os_version || a.os_normalized || ''}`.toLowerCase()) ? 'Server' : 'Workstation';
  if (os === 'macOS') return 'Workstation';
  if (os === 'Linux') return 'Server';
  if (os === 'Network OS') return 'Network device';
  if (inet) return 'External / internet-facing';
  return 'Unclassified';
}

/** Fixed-bucket rows for a breakdown BarList: only non-empty buckets, sorted desc, count + %. */
function bucketRows(map: Record<string, number>, order: string[], color: Record<string, string>, total: number): BarRow[] {
  return order
    .filter((k) => (map[k] || 0) > 0)
    .map((k) => ({ key: k, label: k, n: map[k], c: color[k], value: `${nfmt(map[k])} · ${share(map[k], total) || '0%'}` }))
    .sort((a, b) => (b.n as number) - (a.n as number));
}

export default function InventoryOverview() {
  const qc = useQueryClient();
  const assetsQ = useQuery<ITAsset[]>({ queryKey: KEYS.assets, queryFn: async () => (await assetsApi.getAll({ limit: 100000 })).data });
  const invQ = useQuery<InvOverview | null>({
    queryKey: KEYS.inv,
    queryFn: async () => { try { return (await apiClient.get('/assets/inventory-overview')).data; } catch { return null; } },
  });
  const riskQ = useQuery<RiskDash>({ queryKey: KEYS.risk, queryFn: async () => (await riskPostureApi.dashboard()).data, staleTime: 5 * 60_000, retry: 1 });
  const devicesQ = useQuery<Devices>({ queryKey: KEYS.devices, queryFn: async () => (await discoveryApi.discoveredDevices()).data, retry: 1 });

  const mine = [assetsQ, invQ, riskQ, devicesQ];
  const fetching = mine.some((q) => q.isFetching);
  const failed = mine.filter((q) => q.isError).length + (invQ.isSuccess && invQ.data === null ? 1 : 0);
  const latest = Math.max(0, ...mine.map((q) => q.dataUpdatedAt || 0));
  const [updated, setUpdated] = useState(0);
  useEffect(() => { if (!fetching && latest) setUpdated(latest); }, [fetching, latest]);
  const refresh = () => { ALL_KEYS.forEach((queryKey) => qc.invalidateQueries({ queryKey, refetchType: 'all' })); };

  const inv = invQ.data;
  const A = useMemo<ITAsset[]>(() => assetsQ.data ?? [], [assetsQ.data]);

  // Every estate-size metric derives from ONE source — the managed asset list — so the
  // headline, splits and composition can never disagree. (The list endpoint excludes
  // transient adhoc pentest targets, which the scored aggregate still counts; deriving
  // here keeps total/ext/int/by-type/by-criticality/no-owner/stale mutually consistent.)
  const est = useMemo(() => {
    const now = Date.now();
    const soon = now + 90 * 864e5;
    const staleBefore = now - 30 * 864e5;
    const byEnv: Record<string, number> = {}, byLife: Record<string, number> = {}, byOs: Record<string, number> = {}, byCat: Record<string, number> = {};
    let ext = 0, inet = 0, dmz = 0, envUnset = 0, noOwner = 0, critHigh = 0, stale = 0, eolPast = 0, eolSoon = 0, hasEol = 0;
    for (const a of A as AssetRow[]) {
      if (isExternal(a)) ext++;
      const c = (a.criticality || 'unassigned').toLowerCase();
      if (c === 'critical' || c === 'high') critHigh++;
      const ob = osBucketOf(a); byOs[ob] = (byOs[ob] || 0) + 1;
      const cb = categoryBucketOf(a); byCat[cb] = (byCat[cb] || 0) + 1;
      if (a.internet_facing) inet++;
      if (/dmz/i.test(a.network_segment || '')) dmz++;
      if (!a.owner_id && !a.primary_owner_id) noOwner++;
      const ls = a.last_seen_at ? new Date(a.last_seen_at).getTime() : null;
      if (ls == null || Number.isNaN(ls) || ls < staleBefore) stale++;
      const env = (a.environment || '').trim().toLowerCase();
      if (env) byEnv[env] = (byEnv[env] || 0) + 1; else envUnset++;
      const life = (a.lifecycle_state || a.status || 'unknown').toLowerCase();
      byLife[life] = (byLife[life] || 0) + 1;
      if (a.eol_date) { hasEol++; const te = new Date(a.eol_date).getTime(); if (!Number.isNaN(te)) { if (te < now) eolPast++; else if (te < soon) eolSoon++; } }
    }
    return { total: A.length, ext, int: A.length - ext, inet, dmz, envUnset, noOwner, critHigh, stale, byEnv, byLife, byOs, byCat, eolPast, eolSoon, hasEol };
  }, [A]);

  const total = (assetsQ.data ? est.total : null) ?? inv?.counts?.assets ?? null;
  const perf = inv?.performance;
  const critHigh = assetsQ.data ? est.critHigh : null;
  const scanned = metric(inv, 'scan', 'scanned_recent');
  const cisCov = metric(inv, 'cis', 'scan_coverage');

  return (
    <div data-inv-overview className="mx-auto flex w-full max-w-[1950px] flex-col gap-3 pb-5 text-[#0F172A]" style={{ fontFamily: FONT, zoom: 0.8 }}>
      {/* Flip the (cream) asset-suite canvas to the Performance grey so the white cards lift off it. */}
      <style>{'.asset-suite:has([data-inv-overview]),main:has([data-inv-overview]){background:#EDF0F5}'}</style>

      {/* ── Executive summary ── */}
      <section aria-label="Executive summary" className={`flex flex-wrap items-center gap-x-6 gap-y-2 rounded-[14px] border border-[#E2E5EC] bg-white px-4 py-3 ${CARD_SHADOW}`} style={{ borderLeft: `3px solid ${T.base}` }}>
        <div className="min-w-0 flex-1 basis-[260px]">
          <Eyebrow>Asset estate</Eyebrow>
          <p className="m-0 mt-0.5 text-[13.5px] leading-[1.5] text-[#0F172A]" aria-live="polite">
            {estateSentence({ loading: assetsQ.isLoading, total, ext: est.ext, int: est.int, critHigh, score: perf?.score ?? null, grade: perf?.grade ?? null, noOwner: assetsQ.data ? est.noOwner : null })}
          </p>
        </div>
        <div className="flex items-center gap-3 text-[11.5px] text-[#64748B]">
          <span aria-live="polite">
            {updated ? `Live data · ${new Date(updated).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}` : 'Loading live data…'}
            {!fetching && failed > 0 && <span className="ml-2 inline-flex"><Warn>{plural(failed, 'source')} didn&rsquo;t respond</Warn></span>}
          </span>
          <button type="button" onClick={refresh} disabled={fetching}
            className="inline-flex h-8 items-center gap-1.5 rounded-[9px] border border-[#E2E5EC] bg-white px-3 text-[12px] font-semibold text-[#334155] hover:bg-[#F6F7FB] disabled:cursor-default disabled:opacity-70">
            <RefreshCw size={13} aria-hidden className={fetching ? 'animate-spin' : ''} style={{ color: T.base }} />{fetching ? 'Refreshing' : 'Refresh'}
          </button>
        </div>
      </section>

      {/* ── Hero: inventory health · estate composition ── */}
      <div className="grid grid-cols-1 gap-3 xl:grid-cols-12">
        <HealthHero q={invQ} />
        <CompositionCard assets={assetsQ} est={est} />
      </div>

      {/* ── KPI strip ── */}
      <nav aria-label="Key indicators" className="grid grid-cols-1 gap-2.5 min-[480px]:grid-cols-2 md:grid-cols-3 xl:grid-cols-6">
        <Kpi icon={<Boxes size={15} />} label="Assets under management" href="/assets" loading={assetsQ.isLoading} busy={busyOf(assetsQ)}
          value={nfmt(total)}
          sub={assetsQ.data ? (est.noOwner ? <Warn>{nfmt(est.noOwner)} without an owner</Warn> : 'every asset has an owner') : 'in the IT asset inventory'} />
        <Kpi icon={<GaugeIcon size={15} />} label="Inventory health" href="/risk-posture" loading={invQ.isLoading} busy={busyOf(invQ)}
          value={perf?.score != null ? perf.score.toFixed(1) : '—'}
          sub={perf?.score != null ? <>of 100 · {perf.grade ? titleCase(perf.grade) : 'target 85'}</> : inv ? <Cta>No assets scored yet</Cta> : 'unavailable'} />
        <Kpi icon={<Globe size={15} />} label="External vs internal" href="/assets" loading={assetsQ.isLoading} busy={busyOf(assetsQ)}
          value={est.total ? `${nfmt(est.ext)} / ${nfmt(est.int)}` : '—'}
          sub={est.total ? `${share(est.ext, est.total) || '0%'} external · ${nfmt(est.inet)} internet-facing` : 'no assets yet'} />
        <Kpi icon={<AlertTriangle size={15} />} label="Critical & high assets" href="/assets" loading={assetsQ.isLoading} busy={busyOf(assetsQ)}
          value={nfmt(critHigh)}
          sub={critHigh != null && total ? `${share(critHigh, total) || '0%'} of ${nfmt(total)} assets` : 'unavailable'} />
        <Kpi icon={<ShieldCheck size={15} />} label="Scanned in last 30 days" href="/asset-discovery" loading={invQ.isLoading} busy={busyOf(invQ)}
          value={scanned?.score != null ? `${Math.round(scanned.score)}%` : '—'}
          sub={scanned ? `${nfmt(scanned.numerator)} of ${nfmt(scanned.denominator)} assets` : 'unavailable'} />
        <Kpi icon={<ClipboardCheck size={15} />} label="CIS benchmarked" href="/assets?tab=cis" loading={invQ.isLoading} busy={busyOf(invQ)}
          value={cisCov?.score != null ? `${Math.round(cisCov.score)}%` : '—'}
          sub={cisCov?.score != null ? `${nfmt(cisCov.numerator)} of ${nfmt(cisCov.denominator)} scanned` : inv ? <Cta>No CIS scan yet</Cta> : 'unavailable'} />
      </nav>

      {/* ── Lenses ── rows sum to 12 ── */}
      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-12">
        <CoverageCard q={invQ} />
        <OnboardingCard devices={devicesQ} />
        <ExposureCard assets={assetsQ} est={est} />
        <AttentionCard q={invQ} est={est} />
        <TopRiskCard risk={riskQ} />
        <LifecycleCard assets={assetsQ} est={est} />
      </div>
    </div>
  );
}

/* ---------- helpers ---------- */
function metric(inv: InvOverview | null | undefined, section: string, key: string): Metric | null {
  return inv?.sections?.[section]?.metrics?.find((m) => m.key === key) ?? null;
}

const Warn = ({ children }: { children: ReactNode }) => (
  <span className="inline-flex items-center gap-1"><AlertTriangle size={12} aria-hidden style={{ color: T.warning }} />{children}</span>
);
const Cta = ({ children }: { children: ReactNode }) => <span className="font-semibold text-[#005B96]">{children} →</span>;

function estateSentence({ loading, total, ext, int, critHigh, score, grade, noOwner }: {
  loading: boolean; total: number | null; ext: number; int: number; critHigh: number | null; score: number | null; grade: string | null; noOwner: number | null;
}): ReactNode {
  if (loading) return <Skel h={16} w="80%" className="my-1" />;
  if (!total) return 'No assets are under management yet — adopt discovered devices or import a register to start.';
  const B = ({ children }: { children: ReactNode }) => <b className="font-semibold">{children}</b>;
  const lead = <><B>{nfmt(total)}</B> {total === 1 ? 'asset is' : 'assets are'} under management — <B>{nfmt(ext)}</B> external, <B>{nfmt(int)}</B> internal</>;
  const crit = critHigh != null ? <>; <B>{nfmt(critHigh)}</B> critical or high</> : null;
  const health = score != null ? <>; inventory health <B>{score.toFixed(1)}</B>/100{grade ? ` (${grade})` : ''}</> : null;
  const owner = noOwner ? <>; <B>{nfmt(noOwner)}</B> still without an owner</> : null;
  return <>{lead}{crit}{health}{owner}.</>;
}

/* ---------- KPI tile (mirrors the Performance dashboard tile) ---------- */
function Kpi({ icon, label, value, sub, href, loading, busy }: {
  icon: ReactNode; label: string; value: ReactNode; sub: ReactNode; href: string; loading?: boolean; busy?: boolean;
}) {
  return (
    <Link href={href} aria-busy={busy || undefined} className={`group relative flex min-w-0 flex-col rounded-[12px] border border-[#E2E5EC] bg-white px-3 py-2.5 ${CARD_SHADOW} transition hover:-translate-y-px hover:border-[#C7D2E4] hover:shadow-[0_8px_22px_rgba(16,24,40,.12)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#005B96]`}>
      <span className="flex items-center gap-2 text-[11.5px] font-medium text-[#64748B]">
        <span aria-hidden className="grid h-[26px] w-[26px] shrink-0 place-items-center rounded-[8px]" style={{ background: alpha(T.base, 0.08), color: T.base }}>{icon}</span>
        <span className="flex min-h-[29px] min-w-0 flex-1 items-center pr-3 leading-[1.25]">{label}</span>
      </span>
      <ArrowRight size={13} aria-hidden className="absolute right-2.5 top-3 text-[#CBD5E1] transition group-hover:translate-x-0.5 group-hover:text-[#64748B]" />
      {loading ? (
        <span className="mt-2.5 flex flex-col gap-1.5"><Skel h={24} w="45%" /><span className="text-[11px] text-[#94A3B8]">loading…</span></span>
      ) : (
        <span className={`flex flex-col transition-opacity duration-200 ${busy ? 'opacity-50' : ''}`}>
          <span className="mt-1.5 text-[22px] font-semibold leading-[1.1] text-[#0F172A]">{value}</span>
          <span className="mt-1 text-[11.5px] leading-[1.4] text-[#64748B]">{sub}</span>
        </span>
      )}
    </Link>
  );
}

/* ---------- hero: inventory health (the scorecard) ---------- */
const GRADE_TONE: Record<string, Tone> = {
  excellent: { ...BAND.contained, label: 'Excellent' }, good: { ...BAND.contained, label: 'Good' },
  fair: { ...SEV.medium, label: 'Fair' }, poor: { ...SEV.critical, label: 'Poor' },
};
const vsTarget = (s: number, target: number) => (s >= target ? T.success : s >= 50 ? SEV.medium.c : SEV.critical.c);

function HealthHero({ q }: { q: Qs<InvOverview> }) {
  const d = q.data;
  const p = d?.performance;
  const target = p?.components?.[0]?.target ?? 85;
  const score = p?.score ?? null;
  const tone = score == null ? BAND.unknown : GRADE_TONE[d?.performance?.grade ?? ''] ?? SEV.info;
  let body: ReactNode;
  if (q.isLoading) body = (
    <div className="flex flex-1 flex-wrap items-center gap-6">
      <div className="relative max-w-full shrink-0"><Gauge value={null} color={T.faint} label="Inventory health loading" /></div>
      <div className="min-w-0 flex-1 basis-[220px]"><Loading rows={6} /></div>
    </div>
  );
  else if (!d) body = <Unavailable what="Inventory score" href="/risk-posture" />;
  else if (d.no_data || score == null) body = <Empty icon={<ClipboardCheck size={16} />} title="No assets scored yet" body="Adopt discovered devices or import a register to start scoring the inventory." href="/asset-discovery" cta="Bring assets in" />;
  else body = (
    <div className="flex flex-1 flex-wrap items-stretch gap-x-7 gap-y-4">
      <div className="flex max-w-full shrink-0 flex-col items-center justify-center">
        <div className="relative max-w-full">
          {/* gauge reads 0-100 higher=better here; invert so the coloured arc grows with health */}
          <Gauge value={100 - score} color={vsTarget(score, target)} label={`Inventory health ${score.toFixed(1)} of 100`} />
          <div className="pointer-events-none absolute inset-x-0 bottom-[24px] flex flex-col items-center">
            <span className="text-[30px] font-semibold leading-none text-[#0F172A]">{score.toFixed(1)}</span>
            <span className="mt-1 text-[10.5px] text-[#94A3B8]">health / 100</span>
          </div>
        </div>
        <div className="mt-1 flex items-center gap-2"><Pill tone={tone}>{tone.label}</Pill><span className="text-[11.5px] text-[#64748B]">target {target}</span></div>
      </div>
      <div className="flex min-w-0 flex-1 basis-[250px] flex-col">
        <Eyebrow className="mb-2">Score by domain</Eyebrow>
        <div className="flex flex-1 flex-col">
          <BarList max={100} target={target} labelWidth={150} fill
            rows={(p?.components ?? []).map((c) => ({ key: c.key, label: c.label, n: c.score == null ? null : c.score, c: c.score == null ? undefined : vsTarget(c.score, c.target ?? target), value: c.score == null ? undefined : c.score.toFixed(0), title: `${c.label}: weight ${Math.round(c.weight * 100)}%` }))} />
        </div>
        <p className="m-0 mt-2 flex items-center gap-1.5 text-[10.5px] text-[#94A3B8]"><i aria-hidden className="inline-block h-[10px] w-[2px] rounded-[1px] bg-[#0F172A] opacity-50" />target · green ≥ target, red &lt; 50</p>
      </div>
    </div>
  );
  return (
    <Card title="Inventory health" sub="Scored across hygiene, coverage, exposure & lifecycle · 0–100" href="/risk-posture" cta="Risk posture" busy={busyOf(q)} className="xl:col-span-7">
      {body}
    </Card>
  );
}

/* ---------- hero: estate composition (by OS · by device category) ----------
   Two truthful breakdowns bucketed from the real OS/platform signals on every asset.
   Fixed buckets, sorted desc, count + share — scales to thousands (no per-asset list).
   External/EASM assets carry no host OS, so "OS not visible" dominating is correct. */
function CompositionCard({ assets, est }: { assets: Qs<ITAsset[]>; est: Est }) {
  const osRows = bucketRows(est.byOs, OS_ORDER, OS_COLOR, est.total);
  const catRows = bucketRows(est.byCat, CAT_ORDER, CAT_COLOR, est.total);
  let body: ReactNode;
  if (assets.isLoading) body = <Loading rows={6} />;
  else if (!assets.data) body = <Unavailable what="Asset composition" href="/assets" />;
  else if (!est.total) body = <Empty icon={<Layers size={16} />} title="No assets yet" body="Adopt discovered devices or import a register to populate the inventory." href="/asset-discovery" cta="Bring assets in" />;
  else body = (
    <div className="flex flex-1 flex-col gap-3">
      <div className="flex flex-1 flex-col">
        <div className="mb-2 flex items-baseline justify-between gap-2"><Eyebrow>By operating system</Eyebrow><span className="text-[11.5px] text-[#64748B]">{nfmt(est.total)} assets</span></div>
        <div className="flex-1"><BarList stacked fill labelWidth={140} rows={osRows} /></div>
      </div>
      <div className="flex flex-1 flex-col border-t border-[#F1F3F7] pt-3">
        <Eyebrow className="mb-2">By device category</Eyebrow>
        <div className="flex-1"><BarList stacked fill labelWidth={140} rows={catRows} /></div>
      </div>
    </div>
  );
  return (
    <Card title="Estate composition" sub="What the inventory is made of — by OS &amp; device type" href="/assets" cta="Open register" busy={busyOf(assets)} className="xl:col-span-5">
      {body}
    </Card>
  );
}

/* ---------- coverage & assurance ---------- */
const COVERAGE: { section: string; key: string; label: string }[] = [
  { section: 'scan', key: 'scanned_recent', label: 'Scanned (last 30d)' },
  { section: 'scan', key: 'os_profiled', label: 'OS profiled' },
  { section: 'scan', key: 'monitored', label: 'Reporting a source' },
  { section: 'hygiene', key: 'owner', label: 'Owner assigned' },
  { section: 'hygiene', key: 'classification', label: 'Data classified' },
  { section: 'criticality', key: 'assessed', label: 'Criticality assessed' },
  { section: 'cis', key: 'scan_coverage', label: 'CIS benchmarked' },
];
function CoverageCard({ q }: { q: Qs<InvOverview> }) {
  const d = q.data;
  const rows: BarRow[] = COVERAGE.map(({ section, key, label }) => {
    const m = metric(d, section, key);
    return { key: `${section}.${key}`, label, n: m?.score ?? null, c: m?.score == null ? undefined : vsTarget(m.score, 85), value: m?.score == null ? undefined : `${Math.round(m.score)}%`, title: m ? `${label}: ${nfmt(m.numerator)} of ${nfmt(m.denominator)}` : label };
  });
  const measured = rows.some((r) => r.n != null);
  let body: ReactNode;
  if (q.isLoading) body = <Loading rows={7} />;
  else if (!d) body = <Unavailable what="Coverage metrics" href="/assets" />;
  else if (d.no_data || !measured) body = <Empty icon={<ShieldCheck size={16} />} title="No coverage measured yet" body="Coverage appears once assets are scanned, profiled and assessed." href="/asset-discovery" cta="Start discovery" />;
  else body = (
    <div className="flex flex-1 flex-col">
      <div className="flex-1"><BarList max={100} target={85} labelWidth={150} fill missing="Not measured yet" rows={rows} /></div>
      <p className="m-0 mt-2 flex items-center gap-1.5 text-[10.5px] text-[#94A3B8]"><i aria-hidden className="inline-block h-[10px] w-[2px] rounded-[1px] bg-[#0F172A] opacity-50" />target 85% · a dashed track means that dimension isn&rsquo;t measured yet</p>
    </div>
  );
  return (
    <Card title="Coverage & assurance" sub="Share of the estate covered by each control" href="/assets" cta="Open register" busy={busyOf(q)} className="md:col-span-2 xl:col-span-8">
      {body}
    </Card>
  );
}

/* ---------- onboarding (discovered vs managed) ---------- */
function OnboardingCard({ devices }: { devices: Qs<Devices> }) {
  const devs = devices.data?.devices ?? [];
  const total = devs.length;
  const inInv = devs.filter((x) => x.in_inventory).length;
  const ready = devs.filter((x) => !x.in_inventory && x.connectable).length;
  const parts: Part[] = [
    { key: 'inv', label: 'Onboarded', n: inInv, c: T.base },
    { key: 'ready', label: 'Ready to connect', n: ready, c: '#7FA7C9' },
    { key: 'rest', label: 'Not yet managed', n: total - inInv - ready, c: '#CBD5E1' },
  ];
  let body: ReactNode;
  if (devices.isLoading) body = <Loading rows={4} />;
  else if (!devices.data) body = <Unavailable what="Discovery" href="/asset-discovery" />;
  else if (!total) body = <Empty compact icon={<Boxes size={16} />} title="Nothing discovered yet" body="Run a network sweep or an external scan to map what you can bring under management." href="/asset-discovery" cta="Start discovery" />;
  else body = (
    <div className="flex flex-1 flex-col justify-between">
      <div className="flex flex-wrap items-end gap-x-6 gap-y-2">
        <Figure label="Onboarded" value={`${pctOf(inInv, total)}%`} sub={`${nfmt(inInv)} of ${nfmt(total)} discovered`} />
        <Figure label="Not yet managed" value={nfmt(total - inInv)} sub={ready ? `${nfmt(ready)} ready to connect` : 'none ready to connect'} />
      </div>
      <div className="mt-3"><StackBar parts={parts} label="Discovered devices by onboarding state" /></div>
      <div className="mt-2.5"><PartLegend parts={parts} total={total} /></div>
    </div>
  );
  return (
    <Card title="Onboarding" sub="Discovered vs brought under management" href="/asset-discovery" cta="Open Discovery" busy={busyOf(devices)} className="xl:col-span-4">
      {body}
    </Card>
  );
}

/* ---------- exposure & environment ---------- */
type Est = { total: number; ext: number; int: number; inet: number; dmz: number; envUnset: number; noOwner: number; critHigh: number; stale: number; byEnv: Record<string, number>; byLife: Record<string, number>; byOs: Record<string, number>; byCat: Record<string, number>; eolPast: number; eolSoon: number; hasEol: number };
function ExposureCard({ assets, est }: { assets: Qs<ITAsset[]>; est: Est }) {
  const parts: Part[] = [
    { key: 'ext', label: 'External (EASM-discovered)', n: est.ext, c: T.base },
    { key: 'int', label: 'Internal', n: est.int, c: '#94A3B8' },
  ];
  const envRows: BarRow[] = Object.entries(est.byEnv).sort((a, b) => b[1] - a[1]).slice(0, 4)
    .map(([k, n]): BarRow => ({ key: k, label: titleCase(k), n, value: nfmt(n) }));
  let body: ReactNode;
  if (assets.isLoading) body = <Loading rows={5} />;
  else if (!assets.data) body = <Unavailable what="Asset estate" href="/assets" />;
  else if (!est.total) body = <Empty icon={<Globe size={16} />} title="No assets yet" body="Provenance and exposure appear once assets are in the inventory." href="/asset-discovery" cta="Bring assets in" />;
  else body = (
    <div className="flex flex-1 flex-col">
      <StackBar parts={parts} label="Assets by provenance" />
      <div className="mt-2.5"><PartLegend parts={parts} total={est.total} /></div>
      <div className="mt-3 grid grid-cols-2 gap-3 border-t border-[#F1F3F7] pt-3">
        <Figure label="Internet-facing" value={nfmt(est.inet)} sub={est.total ? `${share(est.inet, est.total) || '0%'} of estate` : undefined} />
        <Figure label="In a DMZ segment" value={nfmt(est.dmz)} sub={est.dmz ? 'network-segment tagged' : 'none tagged'} />
      </div>
      <div className="mt-3 flex flex-1 flex-col border-t border-[#F1F3F7] pt-3">
        <Eyebrow className="mb-2">By environment</Eyebrow>
        {envRows.length ? <div className="flex-1"><BarList color={'#475569'} labelWidth={110} fill rows={envRows} /></div>
          : <p className="m-0 text-[11.5px] text-[#94A3B8]">No asset has an environment set.</p>}
        {est.envUnset > 0 && <p className="m-0 mt-2 text-[11px] text-[#94A3B8]">{nfmt(est.envUnset)} with no environment set</p>}
      </div>
    </div>
  );
  return (
    <Card title="Exposure & environment" sub="Provenance, internet exposure & deployment tier" href="/assets" cta="Open register" busy={busyOf(assets)} className="md:col-span-2 xl:col-span-6">
      {body}
    </Card>
  );
}

/* ---------- attention queue ---------- */
function AttentionCard({ q, est }: { q: Qs<InvOverview>; est: Est }) {
  const aq = q.data?.attention_queue;
  // Owner + stale come from the managed list (same population as the headline); the
  // assessment / vulnerability rows are facts only the scored aggregate knows.
  const loaded = est.total > 0;
  // Clamp the aggregate's assessment rows to the managed population so they can never
  // read higher than the estate total / internet-facing count shown elsewhere (the
  // aggregate also counts transient adhoc targets, which are always unassessed).
  const rows = aq ? [
    { label: 'Assets without an owner', n: loaded ? est.noOwner : aq.assets_without_owner, href: '/assets' },
    { label: 'Not formally assessed', n: loaded ? Math.min(aq.assets_unassessed, est.total) : aq.assets_unassessed, href: '/assets' },
    { label: 'Stale — not seen in 30d+', n: loaded ? est.stale : aq.stale_assets, href: '/assets' },
    { label: 'Internet-facing, unassessed', n: loaded ? Math.min(aq.internet_facing_unassessed, est.inet) : aq.internet_facing_unassessed, href: '/assets' },
    { label: 'Open critical & high vulnerabilities', n: aq.open_critical_high_vulns, href: '/vulnerabilities' },
  ] : [];
  const clean = rows.every((r) => r.n === 0);
  let body: ReactNode;
  if (q.isLoading) body = <Loading rows={5} />;
  else if (!aq) body = <Unavailable what="Attention queue" href="/assets" />;
  else if (q.data?.no_data) body = <Empty icon={<ClipboardCheck size={16} />} title="No assets yet" body="Nothing to action until the inventory has assets." href="/asset-discovery" cta="Bring assets in" />;
  else if (clean) body = <Empty icon={<ShieldCheck size={16} />} title="Nothing needs attention" body="Every asset has an owner, is assessed, fresh and free of open critical/high findings." />;
  else body = (
    <ul className="m-0 flex flex-1 list-none flex-col p-0">
      {rows.map((r) => (
        <li key={r.label} className="border-b border-[#F1F3F7] last:border-0">
          <Link href={r.href} className="flex items-center gap-3 py-[9px] text-[12.5px] hover:text-[#005B96]">
            <span className={`grid h-[26px] w-[26px] shrink-0 place-items-center rounded-full ${r.n ? '' : 'opacity-40'}`} style={{ background: r.n ? SEV.high.bg : T.subtle, color: r.n ? SEV.high.ink : T.faint }}>
              <AlertTriangle size={13} aria-hidden />
            </span>
            <span className="min-w-0 flex-1 truncate text-[#334155]">{r.label}</span>
            <b className="shrink-0 text-[15px] font-semibold tabular-nums" style={{ color: r.n ? T.text : T.faint }}>{nfmt(r.n)}</b>
            <ArrowRight size={13} aria-hidden className="shrink-0 text-[#CBD5E1]" />
          </Link>
        </li>
      ))}
    </ul>
  );
  return (
    <Card title="Needs attention" sub="Gaps to close across the estate" href="/assets" cta="Open register" busy={busyOf(q)} className="md:col-span-2 xl:col-span-6">
      {body}
    </Card>
  );
}

/* ---------- top assets by risk ---------- */
function TopRiskCard({ risk }: { risk: Qs<RiskDash> }) {
  const d = risk.data;
  const top = useMemo(() => (d?.assets ?? []).filter((a) => a.score != null).sort((a, b) => (b.score as number) - (a.score as number)).slice(0, 6), [d]);
  let body: ReactNode;
  if (risk.isLoading) body = <Loading rows={6} note="Scoring every asset live — this takes a few seconds." />;
  else if (!d) body = <Unavailable what="Risk posture" href="/risk-posture" />;
  else if (!d.summary?.scored_count || !top.length) body = <Empty icon={<GaugeIcon size={16} />} title="No asset has a risk score yet" body="Scores appear once assets carry scan, hardening or business-impact data." href="/risk-posture" cta="Open Risk Posture" />;
  else body = (
    <ol className="m-0 flex flex-1 list-none flex-col p-0">
      {top.map((a) => {
        const b = BAND[toBand(a.band?.label, a.score)];
        const ext = a.mode === 'easm' || /external|easm/i.test(a.asset_type || '');
        return (
          <li key={a.id} className="border-b border-[#F1F3F7] last:border-0">
            <Link href={`/risk-posture/asset/${a.id}`} className="flex items-center gap-2.5 py-[9px] text-[12.5px] hover:bg-[#F6F7FB]">
              <span className="min-w-0 flex-1 truncate font-medium text-[#0F172A]" title={a.name}>{a.name}</span>
              <span className="shrink-0 text-[10.5px] font-medium uppercase tracking-[.04em] text-[#94A3B8]">{ext ? 'External' : 'Internal'}</span>
              <b className="w-[34px] shrink-0 text-right font-semibold tabular-nums text-[#0F172A]">{(a.score as number).toFixed(0)}</b>
              <span className="w-[92px] shrink-0 text-right"><Pill tone={b}>{b.label}</Pill></span>
            </Link>
          </li>
        );
      })}
    </ol>
  );
  return (
    <Card title="Highest-risk assets" sub="Worst risk score first · 0–100, higher is worse" href="/risk-posture" cta="Open Risk Posture" busy={busyOf(risk)} className="md:col-span-2 xl:col-span-6">
      {body}
    </Card>
  );
}

/* ---------- lifecycle & obsolescence ---------- */
const LIFE_TONE: Record<string, string> = { active: T.success, maintenance: SEV.low.c, inactive: SEV.medium.c, decommissioned: T.faint, unknown: '#CBD5E1' };
function LifecycleCard({ assets, est }: { assets: Qs<ITAsset[]>; est: Est }) {
  const lifeRows: BarRow[] = Object.entries(est.byLife).sort((a, b) => b[1] - a[1])
    .map(([k, n]): BarRow => ({ key: k, label: titleCase(k), n, c: LIFE_TONE[k] ?? '#CBD5E1', value: nfmt(n) }));
  let body: ReactNode;
  if (assets.isLoading) body = <Loading rows={5} />;
  else if (!assets.data) body = <Unavailable what="Lifecycle" href="/assets" />;
  else if (!est.total) body = <Empty icon={<CalendarClock size={16} />} title="No assets yet" body="Lifecycle and end-of-life tracking begin once assets are in the inventory." href="/asset-discovery" cta="Bring assets in" />;
  else body = (
    <div className="flex flex-1 flex-col">
      <Eyebrow className="mb-2">By lifecycle state</Eyebrow>
      <div className="flex-1"><BarList labelWidth={130} fill rows={lifeRows} /></div>
      <div className="mt-3 border-t border-[#F1F3F7] pt-3">
        <Eyebrow className="mb-2">Obsolescence (end-of-life)</Eyebrow>
        {est.hasEol ? (
          <div className="grid grid-cols-3 gap-3">
            <Figure label="Past EOL" value={<span style={{ color: est.eolPast ? SEV.critical.ink : T.text }}>{nfmt(est.eolPast)}</span>} sub="already ended" />
            <Figure label="Within 90 days" value={<span style={{ color: est.eolSoon ? SEV.high.ink : T.text }}>{nfmt(est.eolSoon)}</span>} sub="nearing EOL" />
            <Figure label="EOL dated" value={nfmt(est.hasEol)} sub={`of ${nfmt(est.total)}`} />
          </div>
        ) : (
          <p className="m-0 rounded-[10px] bg-[#F6F7FB] px-3 py-2 text-[11px] leading-[1.5] text-[#475569]">No asset carries an end-of-life date yet — obsolescence is <b className="font-semibold">unmeasured</b>, not clear. Populate hardware/software EOL to track it.</p>
        )}
      </div>
    </div>
  );
  return (
    <Card title="Lifecycle & obsolescence" sub="Where assets are in their life · end-of-life exposure" href="/assets" cta="Open register" busy={busyOf(assets)} className="md:col-span-2 xl:col-span-6">
      {body}
    </Card>
  );
}
