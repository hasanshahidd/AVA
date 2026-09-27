'use client';

/**
 * Ava — Performance: the executive (C-level) view across every cyber module.
 *
 * Answers, above the fold: how exposed are we, how bad, where, and is it improving.
 * Module lenses below (vulnerabilities, attack surface, inventory, pentest, risk,
 * CIS, CTEM) each link into their module.
 *
 * Honesty rules: every number is read live from a module endpoint (or the read-only
 * /exec-dashboard/summary aggregate); nothing is sampled, trended or delta'd unless a
 * real series exists. A module with no data shows an empty state + CTA, never a 0 score.
 * Each query is independent, so a slow (risk posture scores every asset live) or failing
 * module only affects its own card. recharts is mocked here → charts are inline SVG/CSS.
 */
import { useMemo, type ReactNode } from 'react';
import Link from 'next/link';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { Activity, AlertTriangle, ArrowRight, Boxes, Bug, ClipboardCheck, Globe, RefreshCw, ShieldAlert } from 'lucide-react';
import apiClient, { compliancePluginsApi, discoveryApi, riskPostureApi } from '@/lib/api';
import { SCORECARD_QUERY_KEYS } from '@/components/dashboard/scorecard-query-keys';
import {
  BAND, BAND_ORDER, Card, Empty, Eyebrow, FONT, Figure, Key, Loading, Pill, Skel, T, Unavailable,
  alpha, nfmt, pctOf, plural, toBand, type Band,
} from './_components/kit';
import { FlowChart, Gauge, NEW_C, PartLegend, RES_C, Sparkline, StackBar, type Part, type Week } from './_components/charts';
import {
  AttackSurface, CisCompliance, CtemProgramme, InventoryHealth, PenTest, RiskDrivers, TopAssets, VulnExposure, isExternalAsset,
  type AssetsDash, type CisOverview, type Ctem, type Devices, type Easm, type ExecSummary, type Inventory, type Qs, type RiskDash,
} from './_components/lenses';

type Trends = {
  buckets?: (string | { date: string })[];
  discovered?: (number | { count: number })[];
  resolved?: (number | { count: number })[];
  summary?: { total_discovered?: number; total_resolved?: number; mttr_days_within_window?: number | null };
};

// Keys shared with the module pages (same fetcher + payload) so their caches, refetches
// and invalidations (e.g. tuning risk weights) flow straight into this view.
const KEYS = {
  summary: ['exec-dashboard.summary'],
  trends: ['exec-dashboard.trends-90d'],
  history: ['exec-dashboard.vuln-open-history'],
  risk: ['risk-posture.dashboard'],
  inv: [...SCORECARD_QUERY_KEYS.assets],
  assets: ['exec-dashboard.assets'],
  cis: ['compliance-plugins.assets-overview'],
  easm: ['exec-dashboard.easm'],
  devices: ['disc-discovered-devices', 'all'],
  ctem: ['exec-dashboard.ctem'],
};
const ALL_KEYS = Object.values(KEYS);
const get = (url: string) => async () => (await apiClient.get(url)).data;

export default function PerformancePage() {
  const qc = useQueryClient();
  const summary = useQuery<ExecSummary>({ queryKey: KEYS.summary, queryFn: get('/exec-dashboard/summary'), retry: 1 });
  const trends = useQuery<Trends>({ queryKey: KEYS.trends, queryFn: get('/vuln-management/dashboard/trends?period=90d'), retry: 1 });
  const history = useQuery<{ series?: { date: string; value: number }[] }>({ queryKey: KEYS.history, queryFn: get('/enriched-dashboard/metric-trend?metric=vuln_open&days=90'), retry: false });
  const risk = useQuery<RiskDash>({ queryKey: KEYS.risk, queryFn: async () => (await riskPostureApi.dashboard()).data, staleTime: 5 * 60_000, retry: 1 });
  const inv = useQuery<Inventory | null>({
    queryKey: KEYS.inv,
    // Same fetcher as InventoryScorecard / InventoryRedesign (null on failure) — the key is shared.
    queryFn: async () => { try { return (await apiClient.get('/assets/inventory-overview')).data; } catch { return null; } },
  });
  const assets = useQuery<AssetsDash>({ queryKey: KEYS.assets, queryFn: get('/assets/dashboard'), retry: 1 });
  const cis = useQuery<CisOverview>({ queryKey: KEYS.cis, queryFn: async () => (await compliancePluginsApi.assetsOverview()).data, retry: 1 });
  const easm = useQuery<Easm>({ queryKey: KEYS.easm, queryFn: async () => (await discoveryApi.easmScorecard()).data, retry: 1 });
  const devices = useQuery<Devices>({ queryKey: KEYS.devices, queryFn: async () => (await discoveryApi.discoveredDevices()).data, retry: 1 });
  const ctem = useQuery<Ctem>({ queryKey: KEYS.ctem, queryFn: get('/erm/ctem/scopes/portfolio'), retry: 1 });
  const mine = [summary, trends, risk, inv, assets, cis, easm, devices, ctem];
  const fetching = mine.some((q) => q.isFetching);

  const F = summary.data?.findings;
  const I = inv.data;
  const assetsN = I?.counts?.assets ?? assets.data?.total_assets ?? null;
  const openN = F?.open ?? I?.counts?.open_vulnerabilities ?? null;
  const critHigh = F ? F.by_severity.critical + F.by_severity.high : I?.attention_queue?.open_critical_high_vulns ?? null;

  /* 90-day flow: daily buckets → weeks ending today (the only always-real series). */
  const flow = useMemo(() => {
    const t = trends.data;
    if (!t?.buckets?.length) return null;
    const cnt = (x: unknown) => (typeof x === 'number' ? x : Number((x as { count?: number })?.count) || 0);
    const dates = t.buckets.map((b) => (typeof b === 'string' ? b : b?.date));
    const weeks: Week[] = [];
    for (let end = dates.length; end > 0; end -= 7) {
      const start = Math.max(0, end - 7);
      let added = 0, resolved = 0;
      for (let i = start; i < end; i++) { added += cnt(t.discovered?.[i]); resolved += cnt(t.resolved?.[i]); }
      weeks.unshift({ from: dates[start], to: dates[end - 1], added, resolved });
    }
    const added = t.summary?.total_discovered ?? weeks.reduce((s, w) => s + w.added, 0);
    const resolved = t.summary?.total_resolved ?? weeks.reduce((s, w) => s + w.resolved, 0);
    return { weeks, added, resolved, mttr: t.summary?.mttr_days_within_window ?? null };
  }, [trends.data]);

  const updated = Math.max(0, ...mine.map((q) => q.dataUpdatedAt || 0));
  const refresh = () => ALL_KEYS.forEach((queryKey) => qc.invalidateQueries({ queryKey }));

  return (
    <div className="mx-auto flex w-full max-w-[1560px] flex-col gap-4 pb-6 text-[#0F172A]" style={{ fontFamily: FONT }}>
      <h1 className="sr-only">Performance — executive cyber posture</h1>

      {/* ── Executive summary ── */}
      <section aria-label="Executive summary" className="flex flex-wrap items-center gap-x-6 gap-y-3 rounded-[14px] border border-[#E2E5EC] bg-white px-[18px] py-[14px] shadow-[0_1px_2px_rgba(16,24,40,.04)]" style={{ borderLeft: `3px solid ${T.base}` }}>
        <div className="min-w-0 flex-1 basis-[260px]">
          <Eyebrow>Executive summary</Eyebrow>
          <p className="m-0 mt-1 text-[15px] leading-[1.55] text-[#0F172A]" aria-live="polite">
            {summarySentence({ loading: inv.isLoading || summary.isLoading || trends.isLoading, assetsN, openN, critHigh, exposed: F?.internet_exposed ?? null, flow })}
          </p>
        </div>
        <div className="flex items-center gap-3 text-[11.5px] text-[#64748B]">
          <span>{updated ? `Live data · ${new Date(updated).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}` : 'Loading live data…'}</span>
          <button type="button" onClick={refresh} disabled={fetching}
            className="inline-flex h-8 items-center gap-1.5 rounded-[9px] border border-[#E2E5EC] bg-white px-3 text-[12px] font-semibold text-[#334155] hover:bg-[#F6F7FB] disabled:cursor-default disabled:opacity-70">
            <RefreshCw size={13} aria-hidden className={fetching ? 'animate-spin' : ''} style={{ color: T.base }} />{fetching ? 'Refreshing' : 'Refresh'}
          </button>
        </div>
      </section>

      {/* ── Hero: risk posture · 90-day flow ── */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-12">
        <PostureHero risk={risk} assetsN={assetsN} />
        <FlowCard q={trends} flow={flow} history={history.data?.series ?? null} historyLoading={history.isLoading} />
      </div>

      {/* ── KPI strip ── */}
      <nav aria-label="Key indicators" className="grid grid-cols-1 gap-3 min-[480px]:grid-cols-2 md:grid-cols-3 xl:grid-cols-6">
        <Kpi icon={<Boxes size={15} />} label="Assets under management" href="/assets" loading={inv.isLoading && assets.isLoading}
          value={nfmt(assetsN)}
          sub={I?.attention_queue ? (I.attention_queue.assets_without_owner ? <Warn>{nfmt(I.attention_queue.assets_without_owner)} without an owner</Warn> : 'every asset has an owner') : 'in the IT asset inventory'} />
        <Kpi icon={<Bug size={15} />} label="Open critical & high" href="/vulnerabilities" loading={summary.isLoading && inv.isLoading}
          value={nfmt(critHigh)}
          sub={F ? `${nfmt(F.by_severity.critical)} critical · ${nfmt(F.by_severity.high)} high` : openN != null ? `of ${nfmt(openN)} open findings` : 'findings unavailable'} />
        <Kpi icon={<Globe size={15} />} label="Internet-exposed findings" href="/vulnerabilities" loading={summary.isLoading}
          value={F ? nfmt(F.internet_exposed) : '—'}
          sub={F ? (F.open ? `${pctOf(F.internet_exposed, F.open)}% of ${nfmt(F.open)} open findings` : 'no open findings') : 'unavailable'} />
        <Kpi icon={<ShieldAlert size={15} />} label="External posture grade" href="/asset-discovery" loading={easm.isLoading}
          value={easm.data?.summary?.graded ? (easm.data.summary.avg_grade ?? '—') : '—'}
          sub={easm.data?.summary?.graded
            ? `avg ${easm.data.summary.avg_score ?? '—'}/100 · ${nfmt(easm.data.summary.graded)} of ${nfmt(easm.data.summary.total)} hosts graded`
            : easm.data ? <Cta>No external scan yet · Run one</Cta> : 'unavailable'} />
        <Kpi icon={<Activity size={15} />} label="Severe & elevated risk" href="/risk-posture" loading={risk.isLoading} loadingNote="scoring assets…"
          value={risk.data?.summary ? nfmt((risk.data.summary.by_band.severe ?? 0) + (risk.data.summary.by_band.elevated ?? 0)) : '—'}
          sub={risk.data?.summary ? `${nfmt(risk.data.summary.by_band.severe ?? 0)} severe · ${nfmt(risk.data.summary.by_band.elevated ?? 0)} elevated of ${nfmt(risk.data.summary.asset_count)}` : 'unavailable'} />
        <Kpi icon={<ClipboardCheck size={15} />} label="CIS benchmark coverage" href="/assets?tab=cis" loading={cis.isLoading}
          value={cis.data?.totals?.scanned ? `${Math.round(cis.data.totals.avg_pass_rate)}%` : '—'}
          sub={cis.data?.totals
            ? (cis.data.totals.scanned ? `pass rate · ${nfmt(cis.data.totals.scanned)} of ${nfmt(cis.data.totals.assets)} assets scanned` : <Cta>No CIS scan yet · Run a CIS scan</Cta>)
            : 'unavailable'} />
      </nav>

      {/* ── Module lenses ── */}
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-12">
        <VulnExposure q={summary} />
        <TopAssets q={summary} risk={risk} />
        <AttackSurface devices={devices} easm={easm} />
        <InventoryHealth inv={inv} assets={assets} />
        <PenTest q={summary} />
        <RiskDrivers risk={risk} />
        <CisCompliance q={cis} />
        <CtemProgramme q={ctem} />
      </div>
    </div>
  );
}

/* ---------- executive sentence (plain template over live numbers) ---------- */
function summarySentence({ loading, assetsN, openN, critHigh, exposed, flow }: {
  loading: boolean; assetsN: number | null; openN: number | null; critHigh: number | null; exposed: number | null;
  flow: { added: number; resolved: number } | null;
}): ReactNode {
  if (loading) return <Skel h={16} w="80%" className="my-1" />;
  if (critHigh == null && openN == null) return 'Live posture data is unavailable right now — module cards below show what did load.';
  const B = ({ children }: { children: ReactNode }) => <b className="font-semibold">{children}</b>;
  const across = assetsN != null ? <> across <B>{nfmt(assetsN)}</B> assets</> : null;
  const lead = critHigh ? <><B>{nfmt(critHigh)}</B> critical or high {critHigh === 1 ? 'finding is' : 'findings are'} open{across}</> : <>No critical or high findings are open{across}</>;
  const exp = exposed != null && openN ? <>; <B>{pctOf(exposed, openN)}%</B> of the {nfmt(openN)} open findings sit on internet-facing assets</> : null;
  let trend: ReactNode = null;
  if (flow) {
    const { added, resolved } = flow;
    trend = !added && !resolved ? <>; nothing was opened or resolved in the last 90 days</>
      : !resolved ? <>; <B>none</B> has been resolved in the last 90 days ({nfmt(added)} new)</>
        : resolved >= added ? <>; the backlog shrank by <B>{nfmt(resolved - added)}</B> over 90 days ({nfmt(resolved)} resolved vs {nfmt(added)} new)</>
          : <>; the backlog grew by <B>{nfmt(added - resolved)}</B> over 90 days ({nfmt(added)} new vs {nfmt(resolved)} resolved)</>;
  }
  return <>{lead}{exp}{trend}.</>;
}

/* ---------- KPI tile ---------- */
const Warn = ({ children }: { children: ReactNode }) => (
  <span className="inline-flex items-center gap-1"><AlertTriangle size={12} aria-hidden style={{ color: T.warning }} />{children}</span>
);
const Cta = ({ children }: { children: ReactNode }) => <span className="font-semibold text-[#005B96]">{children} →</span>;

function Kpi({ icon, label, value, sub, href, loading, loadingNote }: {
  icon: ReactNode; label: string; value: ReactNode; sub: ReactNode; href: string; loading?: boolean; loadingNote?: string;
}) {
  return (
    <Link href={href} className="group flex min-w-0 flex-col rounded-[14px] border border-[#E2E5EC] bg-white px-[14px] py-[12px] shadow-[0_1px_2px_rgba(16,24,40,.04)] transition hover:border-[#C7D2E4] hover:shadow-[0_4px_14px_rgba(16,24,40,.08)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#005B96]">
      <span className="flex items-center gap-2 text-[11.5px] font-medium text-[#64748B]">
        <span aria-hidden className="grid h-[26px] w-[26px] shrink-0 place-items-center rounded-[8px]" style={{ background: alpha(T.base, 0.08), color: T.base }}>{icon}</span>
        <span className="min-w-0 flex-1 leading-[1.25]">{label}</span>
        <ArrowRight size={13} aria-hidden className="shrink-0 text-[#CBD5E1] transition group-hover:translate-x-0.5 group-hover:text-[#64748B]" />
      </span>
      {loading ? (
        <span className="mt-2.5 flex flex-col gap-1.5"><Skel h={24} w="45%" /><span className="text-[11px] text-[#94A3B8]">{loadingNote ?? 'loading…'}</span></span>
      ) : (
        <>
          <span className="mt-2 text-[26px] font-semibold leading-[1.1] text-[#0F172A]">{value}</span>
          <span className="mt-1 text-[11.5px] leading-[1.4] text-[#64748B]">{sub}</span>
        </>
      )}
    </Link>
  );
}

/* ---------- hero: risk posture ---------- */
function PostureHero({ risk, assetsN }: { risk: Qs<RiskDash>; assetsN: number | null }) {
  const d = risk.data;
  const s = d?.summary;
  const x = useMemo(() => {
    if (!d) return null;
    const avg = (xs: typeof d.assets) => {
      const k = xs.filter((a) => a.score != null);
      return k.length ? k.reduce((t, a) => t + (a.score as number), 0) / k.length : null;
    };
    const ext = d.assets.filter(isExternalAsset), int = d.assets.filter((a) => !isExternalAsset(a));
    const top = d.assets.filter((a) => a.score != null).sort((a, b) => (b.score as number) - (a.score as number)).slice(0, 4);
    return { ext: ext.length, extAvg: avg(ext), int: int.length, intAvg: avg(int), top };
  }, [d]);
  const band: Band = toBand(null, s?.avg_score);
  const tone = BAND[band];
  const parts: Part[] = BAND_ORDER.map((k) => ({ key: k, label: BAND[k].label, n: s?.by_band?.[k] ?? 0, c: BAND[k].c }));
  if (s?.by_band?.unknown) parts.push({ key: 'unknown', label: 'Unscored', n: s.by_band.unknown, c: BAND.unknown.c });

  let body: ReactNode;
  if (risk.isLoading) body = (
    <div className="flex flex-wrap items-center gap-6">
      <div className="relative max-w-full shrink-0"><Gauge value={null} color={T.faint} label="Risk posture loading" /></div>
      <div className="min-w-0 flex-1 basis-[220px]"><Loading rows={5} note={`Scoring ${assetsN != null ? plural(assetsN, 'asset') : 'every asset'} live from scan, hardening and business-impact signals — this takes a few seconds.`} /></div>
    </div>
  );
  else if (!d || !s) body = <Unavailable what="Risk posture" href="/risk-posture" />;
  else if (!s.scored_count || s.avg_score == null) body = <Empty icon={<Activity size={16} />} title="No asset has a risk score yet" body="Scores appear once assets carry scan, hardening or business-impact data." href="/risk-posture" cta="Open Risk Posture" />;
  else body = (
    <div className="flex flex-wrap items-start gap-x-7 gap-y-4">
      <div className="flex max-w-full shrink-0 flex-col items-center">
        <div className="relative max-w-full">
          <Gauge value={s.avg_score} color={tone.c} label={`Average asset risk ${s.avg_score.toFixed(1)} of 100, band ${tone.label}`} />
          <div className="pointer-events-none absolute inset-x-0 bottom-[24px] flex flex-col items-center">
            <span className="text-[36px] font-semibold leading-none text-[#0F172A]">{s.avg_score.toFixed(1)}</span>
            <span className="mt-1 text-[10.5px] text-[#94A3B8]">avg risk / 100</span>
          </div>
        </div>
        <div className="mt-1 flex items-center gap-2"><Pill tone={tone} /><span className="text-[11.5px] text-[#64748B]">{tone.desc}</span></div>
        {x && (
          <p className="m-0 mt-2 text-center text-[11px] leading-[1.5] text-[#64748B]">
            External {nfmt(x.ext)} · avg {x.extAvg == null ? '—' : x.extAvg.toFixed(1)}<br />Internal {nfmt(x.int)} · avg {x.intAvg == null ? '—' : x.intAvg.toFixed(1)}
          </p>
        )}
      </div>
      <div className="min-w-0 flex-1 basis-[250px]">
        <div className="mb-2 flex items-baseline justify-between gap-2"><Eyebrow>Assets by risk band</Eyebrow><span className="text-[11.5px] text-[#64748B]">{nfmt(s.scored_count)} of {nfmt(s.asset_count)} scored</span></div>
        <StackBar parts={parts} label="Assets by risk band" height={14} />
        <div className="mt-2.5"><PartLegend parts={parts} total={s.asset_count} cols={2} /></div>
        {x && x.top.length > 0 && (
          <div className="mt-4">
            <Eyebrow className="mb-1.5">Highest risk</Eyebrow>
            <ol className="m-0 flex list-none flex-col p-0">
              {x.top.map((a) => {
                const b = BAND[toBand(a.band?.label, a.score)];
                return (
                  <li key={a.id}>
                    <Link href={`/risk-posture/asset/${a.id}`} className="flex items-center gap-2.5 rounded-[8px] px-1.5 py-[5px] text-[12px] hover:bg-[#F6F7FB]">
                      <span className="min-w-0 flex-1 truncate font-medium text-[#0F172A]" title={a.name}>{a.name}</span>
                      <span className="shrink-0 text-[10.5px] font-medium uppercase tracking-[.04em] text-[#94A3B8]">{isExternalAsset(a) ? 'External' : 'Internal'}</span>
                      <b className="w-[34px] shrink-0 text-right font-semibold tabular-nums text-[#0F172A]">{(a.score as number).toFixed(1)}</b>
                      <span className="w-[74px] shrink-0 text-right"><Pill tone={b} /></span>
                    </Link>
                  </li>
                );
              })}
            </ol>
          </div>
        )}
      </div>
    </div>
  );
  return (
    <Card title="Risk posture" sub="Mean of every asset’s 0–100 risk score — higher is worse" href="/risk-posture" cta="Open Risk Posture" className="xl:col-span-7">
      {body}
    </Card>
  );
}

/* ---------- hero: is it improving? ---------- */
function FlowCard({ q, flow, history, historyLoading }: {
  q: Qs<Trends>; flow: { weeks: Week[]; added: number; resolved: number; mttr: number | null } | null;
  history: { date: string; value: number }[] | null; historyLoading: boolean;
}) {
  const pts = (history ?? []).map((p) => Number(p.value)).filter((n) => Number.isFinite(n));
  let body: ReactNode;
  if (q.isLoading) body = <Loading rows={6} />;
  else if (!flow) body = <Unavailable what="Finding trend" href="/vulnerabilities" />;
  else body = (
    <div className="flex flex-1 flex-col">
      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        <Figure label="New" value={nfmt(flow.added)} sub="first detected" />
        <Figure label="Resolved" value={nfmt(flow.resolved)} sub="closed in window" />
        <Figure label="Net change" value={`${flow.added - flow.resolved > 0 ? '+' : ''}${nfmt(flow.added - flow.resolved)}`} sub="open backlog" />
        <Figure label="MTTR" value={flow.mttr == null ? '—' : `${Math.round(flow.mttr)}d`} sub={flow.mttr == null ? 'nothing resolved yet' : 'mean time to remediate'} />
      </div>
      <FlowChart weeks={flow.weeks} />
      <div className="mt-1 flex flex-wrap items-center gap-x-4 gap-y-1 text-[11.5px] text-[#334155]">
        <span className="inline-flex items-center gap-1.5"><Key c={NEW_C} />New findings</span>
        <span className="inline-flex items-center gap-1.5"><Key c={RES_C} />Resolved</span>
        <span className="ml-auto inline-flex items-center gap-2 text-[11px] text-[#64748B]">
          Open backlog history:
          {historyLoading ? <Skel h={10} w={60} /> : pts.length >= 2
            ? <Sparkline points={pts} width={96} height={22} label={`Open findings over the last ${pts.length} daily snapshots, latest ${pts[pts.length - 1]}`} />
            : <span className="italic text-[#94A3B8]">no daily snapshots yet</span>}
        </span>
      </div>
    </div>
  );
  return (
    <Card title="Is it improving?" sub="Findings opened vs resolved per week, last 90 days" href="/vulnerabilities" cta="Open register" className="xl:col-span-5">
      {body}
    </Card>
  );
}
