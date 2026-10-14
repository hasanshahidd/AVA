'use client';

/**
 * CIS Benchmark — compliance dashboard (executive / analyst view).
 *
 * The second of the two CIS pages in the IT-asset area (the first is the
 * CisHierarchy rule browser). That page browses the rule *library*; this one
 * scores actual hardening across the whole asset estate.
 *
 * Visual language follows the Performance exec dashboard (dashboard/_components):
 * white cards on a light canvas, brand accent #005B96, coverage ring, 100%
 * stacked bars, honest per-card empty states — charts are inline SVG/CSS
 * (recharts is mocked in this repo, so it is never used here). The card, bar,
 * legend, figure and empty-state primitives are reused from that dashboard's
 * kit so the two surfaces stay pixel-consistent.
 *
 * Every figure is read live; nothing is fabricated. Data sources:
 *   GET /compliance-plugins/assets-overview       (compliancePluginsApi.assetsOverview)
 *       → per-asset passed/failed/errored, OS family, matched benchmark, last scan.
 *         Backs: compliance score, scan coverage, pass-rate by OS family & by
 *         benchmark, and the assets-needing-attention leaderboard.
 *   GET /compliance-plugins/per-asset-coverage?asset_id=N  (perAssetCoverage), fanned
 *       out over the assets that have >=1 failing check → rule-level failures with
 *       severity. Backs: remediation-by-severity and top-failing-controls.
 *
 * A panel with no backing data shows an empty state, never a zero dressed up as a
 * score (mirrors _cis-overview and the Performance dashboard honesty rules).
 */

import { useMemo } from 'react';
import Link from 'next/link';
import { useQuery, useQueries } from '@tanstack/react-query';
import { ClipboardCheck, ServerCog, ShieldCheck } from 'lucide-react';
import { compliancePluginsApi } from '@/lib/api';
import {
  T, SEV, SEV_ORDER, type Sev, type Tone, FONT,
  Card, Empty, Loading, Unavailable, Figure, Pill,
  nfmt, pctOf, plural,
} from '../../dashboard/_components/kit';
import { StackBar, PartLegend, BarList, type Part, type BarRow } from '../../dashboard/_components/charts';

/* ---------- API shapes (only the fields this page reads) ---------- */
type AssetRow = {
  id: number; name: string; host_name?: string | null; ip_address?: string | null;
  os_family?: string | null; matched_benchmark?: string | null; last_scan_at?: string | null;
  scanned_rules?: number; passed?: number; failed?: number; errored?: number; criticality?: string | null;
};
type Group = { os_family: string; label: string; count: number; assets: AssetRow[] };
type Overview = {
  groups?: Group[];
  totals?: { assets: number; scanned: number; unscanned: number; avg_pass_rate: number; total_rules: number };
};
type CoverageRule = { plugin_id: number; rule_id: string; title: string; severity: string | null; benchmark: string; status: string };
type Coverage = { rules?: CoverageRule[] };
type FlatAsset = AssetRow & { _groupLabel: string; _family: string };

/* ---------- small helpers ---------- */
/** Canonical CIS pass rate = passed / (passed + failed); errors/skips excluded
 *  (same definition the scanner, residual and full-posture views agree on). */
const rate = (passed: number, failed: number): number | null =>
  passed + failed > 0 ? Math.round((passed / (passed + failed)) * 100) : null;
const rateHex = (r: number | null): string =>
  r == null ? T.faint : r >= 85 ? T.success : r >= 55 ? SEV.medium.c : SEV.critical.c;
function rateTone(r: number | null): Tone {
  if (r == null) return { ...SEV.info, label: 'N/S' };
  if (r >= 85) return { label: `${r}%`, c: T.success, ink: T.success, bg: '#E7F5EE' };
  if (r >= 55) return { ...SEV.medium, label: `${r}%` };
  return { ...SEV.critical, label: `${r}%` };
}
const normSev = (s?: string | null): Sev => {
  const k = (s || '').toLowerCase();
  return (SEV_ORDER as string[]).includes(k) ? (k as Sev) : 'info';
};
const toMs = (iso?: string | null): number => {
  if (!iso) return 0;
  const t = new Date(/[zZ]$|[+-]\d\d:?\d\d$/.test(iso) ? iso : `${iso}Z`).getTime();
  return Number.isNaN(t) ? 0 : t;
};
function fmtAgo(ms: number): string {
  if (!ms) return 'never';
  const s = Math.max(0, Math.floor((Date.now() - ms) / 1000));
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60); if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60); if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}
/** CIS_Microsoft_Windows_11_Enterprise_Benchmark_v5.0.1 → "Microsoft Windows 11 Enterprise v5.0.1" */
function prettyBenchmark(raw?: string | null): string {
  if (!raw) return '—';
  const s = raw.replace(/^CIS_/, '').replace(/_Benchmark_/, ' ').replace(/_/g, ' ').trim();
  return s.length > 46 ? s.slice(0, 46) + '…' : s;
}

/* ---------- pass-rate ring (compliance reads green-high, so it is its own
   mark — the kit Gauge is a risk gauge whose zones are green-low/red-high) ---------- */
function Ring({ pct, size = 108 }: { pct: number | null; size?: number }) {
  const C = 2 * Math.PI * 52;
  const off = pct == null ? C : C * (1 - Math.min(100, Math.max(0, pct)) / 100);
  return (
    <div style={{ width: size, height: size, position: 'relative', flex: 'none' }}>
      <svg viewBox="0 0 120 120" style={{ width: '100%', height: '100%', transform: 'rotate(-90deg)' }}
        role="img" aria-label={pct == null ? 'Not scanned yet' : `Overall CIS pass rate ${pct}%`}>
        <circle cx="60" cy="60" r="52" fill="none" stroke={T.track} strokeWidth="12" />
        {pct != null && (
          <circle cx="60" cy="60" r="52" fill="none" stroke={rateHex(pct)} strokeWidth="12" strokeLinecap="round"
            strokeDasharray={C} strokeDashoffset={off} style={{ transition: 'stroke-dashoffset 1s cubic-bezier(.3,.8,.3,1)' }} />
        )}
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', lineHeight: 1 }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: Math.round(size * 0.26), fontWeight: 700, color: pct == null ? T.faint : T.text }}>{pct == null ? 'N/S' : `${pct}%`}</div>
          <div style={{ fontSize: 10.5, color: T.muted, marginTop: 2 }}>{pct == null ? 'not scanned' : 'checks passing'}</div>
        </div>
      </div>
    </div>
  );
}

/* ---------- tables ---------- */
const thCell: React.CSSProperties = { padding: '7px 10px', fontSize: 10.5, fontWeight: 600, letterSpacing: '.04em', textTransform: 'uppercase', color: T.muted, background: T.subtle, borderBottom: `1px solid ${T.border}`, whiteSpace: 'nowrap', textAlign: 'left' };
const tdCell: React.CSSProperties = { padding: '8px 10px', fontSize: 12, color: T.text, borderBottom: '1px solid #F1F3F7', verticalAlign: 'middle' };

type FailRule = { rule_id: string; title: string; severity: Sev; benchmark: string; assets: number };

function TopFailTable({ rows }: { rows: FailRule[] }) {
  return (
    <div style={{ overflowX: 'auto', margin: '-2px -4px -6px' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 440 }}>
        <thead><tr>
          <th scope="col" style={thCell}>Control</th>
          <th scope="col" style={thCell}>Severity</th>
          <th scope="col" style={{ ...thCell, textAlign: 'right' }}>Assets failing</th>
        </tr></thead>
        <tbody>
          {rows.map((r, i) => (
            <tr key={`${r.rule_id}·${r.benchmark}·${i}`}>
              <td style={tdCell}>
                <span style={{ display: 'block', fontWeight: 600, color: T.text, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 420 }} title={r.title}>
                  <span style={{ fontFamily: 'ui-monospace,Consolas,monospace', color: T.muted, marginRight: 6 }}>{r.rule_id}</span>{r.title}
                </span>
                <span style={{ display: 'block', fontSize: 10.5, color: T.faint, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 420 }} title={r.benchmark}>{prettyBenchmark(r.benchmark)}</span>
              </td>
              <td style={tdCell}><Pill tone={SEV[r.severity]} /></td>
              <td style={{ ...tdCell, textAlign: 'right', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{nfmt(r.assets)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function WorstTable({ rows }: { rows: { a: FlatAsset; r: number | null }[] }) {
  return (
    <div style={{ overflowX: 'auto', margin: '-2px -4px -6px' }}>
      <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 300 }}>
        <thead><tr>
          <th scope="col" style={thCell}>Asset</th>
          <th scope="col" style={{ ...thCell, textAlign: 'right' }}>Failed</th>
          <th scope="col" style={{ ...thCell, textAlign: 'right' }}>Pass rate</th>
        </tr></thead>
        <tbody>
          {rows.map(({ a, r }) => (
            <tr key={a.id}>
              <td style={tdCell}>
                <Link href={`/assets/${a.id}`} style={{ display: 'block', fontWeight: 600, color: T.text, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', maxWidth: 220 }} title={a.name}>{a.name}</Link>
                <span style={{ fontSize: 10.5, color: T.faint }}>{a._groupLabel || a.os_family || '—'}{a.host_name ? ` · ${a.host_name}` : ''}</span>
              </td>
              <td style={{ ...tdCell, textAlign: 'right', fontVariantNumeric: 'tabular-nums', color: (a.failed || 0) > 0 ? SEV.critical.ink : T.muted }}>{nfmt(a.failed || 0)}</td>
              <td style={{ ...tdCell, textAlign: 'right' }}><Pill tone={rateTone(r)} /></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

/* ---------- dashboard ---------- */
export default function CisDashboard() {
  const overviewQ = useQuery({
    queryKey: ['cis-dash.assets-overview'],
    queryFn: async () => (await compliancePluginsApi.assetsOverview()).data as Overview,
    staleTime: 60_000,
  });

  const groups = overviewQ.data?.groups ?? [];
  const allAssets: FlatAsset[] = useMemo(
    () => groups.flatMap((g) => (g.assets ?? []).map((a) => ({ ...a, _groupLabel: g.label, _family: g.os_family }))),
    [groups],
  );

  // Estate roll-up (checks = rule instances summed across assets).
  const roll = useMemo(() => {
    let passed = 0, failed = 0, errored = 0, scannedAssets = 0, withBenchmark = 0, lastScan = 0;
    for (const a of allAssets) {
      passed += a.passed || 0; failed += a.failed || 0; errored += a.errored || 0;
      if ((a.scanned_rules || 0) > 0) scannedAssets += 1;
      if (a.matched_benchmark) withBenchmark += 1;
      lastScan = Math.max(lastScan, toMs(a.last_scan_at));
    }
    const total = allAssets.length;
    return {
      passed, failed, errored, scannedAssets, withBenchmark, total, lastScan,
      checks: passed + failed + errored,
      awaiting: Math.max(0, withBenchmark - scannedAssets),
      unmapped: Math.max(0, total - withBenchmark),
      passRate: rate(passed, failed),
    };
  }, [allAssets]);

  // Rule-level failures: per-asset-coverage, fetched ONLY for assets that have a
  // failing check (the only assets that can feed the two rule-level panels).
  // ponytail: one request per failing asset — fine for this product's estate size;
  // if scanned estates grow into the hundreds, add a server-side aggregate endpoint.
  const failingIds = useMemo(() => allAssets.filter((a) => (a.failed || 0) > 0).map((a) => a.id), [allAssets]);
  const coverageQs = useQueries({
    queries: failingIds.map((id) => ({
      queryKey: ['cis-dash.coverage', id],
      queryFn: async (): Promise<Coverage> => (await compliancePluginsApi.perAssetCoverage(id)).data as Coverage,
      staleTime: 60_000,
      retry: 1,
    })),
  });
  // Fold the fan-out into severity + top-failing aggregates. Fingerprint the
  // per-query status/timestamps so this recomputes only when a query settles.
  const covFp = coverageQs.map((q) => `${q.status}:${q.dataUpdatedAt || 0}`).join('|');
  const fail = useMemo(() => {
    const loading = coverageQs.length > 0 && coverageQs.some((q) => q.isLoading);
    const settled = coverageQs.filter((q) => q.data);
    const bySev: Record<string, number> = {};
    const byRule = new Map<number, FailRule>();
    let total = 0;
    for (const q of settled) {
      for (const r of (q.data as Coverage).rules || []) {
        if (r.status !== 'failed') continue;
        total += 1;
        const sv = normSev(r.severity);
        bySev[sv] = (bySev[sv] || 0) + 1;
        const cur = byRule.get(r.plugin_id) || { rule_id: r.rule_id, title: r.title, severity: sv, benchmark: r.benchmark, assets: 0 };
        cur.assets += 1;
        byRule.set(r.plugin_id, cur);
      }
    }
    const top = Array.from(byRule.values()).sort((a, b) => b.assets - a.assets || a.rule_id.localeCompare(b.rule_id)).slice(0, 12);
    return { loading, haveData: settled.length > 0, total, bySev, top };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [covFp]);

  // Pass rate by OS family (weakest first; unscanned families sort last).
  const familyRows: BarRow[] = useMemo(() => groups.map((g) => {
    let p = 0, f = 0, sc = 0;
    for (const a of g.assets ?? []) { p += a.passed || 0; f += a.failed || 0; if ((a.scanned_rules || 0) > 0) sc += 1; }
    const r = rate(p, f);
    return { key: g.os_family, label: g.label, n: r, c: rateHex(r), value: r == null ? undefined : `${r}%`, title: `${g.label}: ${sc} of ${g.count} scanned · ${nfmt(p)} pass · ${nfmt(f)} fail` };
  }).sort((a, b) => (a.n ?? 101) - (b.n ?? 101)), [groups]);

  // Pass rate by matched benchmark (assets without a benchmark are excluded).
  const benchRows: BarRow[] = useMemo(() => {
    const m = new Map<string, { p: number; f: number; n: number }>();
    for (const a of allAssets) {
      if (!a.matched_benchmark) continue;
      const cur = m.get(a.matched_benchmark) || { p: 0, f: 0, n: 0 };
      cur.p += a.passed || 0; cur.f += a.failed || 0; cur.n += 1;
      m.set(a.matched_benchmark, cur);
    }
    return Array.from(m.entries()).map(([b, v]) => {
      const r = rate(v.p, v.f);
      return { key: b, label: prettyBenchmark(b), n: r, c: rateHex(r), value: r == null ? undefined : `${r}%`, title: `${prettyBenchmark(b)}: ${plural(v.n, 'asset')} · ${nfmt(v.p)} pass · ${nfmt(v.f)} fail` };
    }).sort((a, b) => (a.n ?? 101) - (b.n ?? 101));
  }, [allAssets]);

  // Worst assets (lowest pass rate first) — only assets with evaluated checks.
  const worst = useMemo(() => allAssets
    .map((a) => ({ a, r: rate(a.passed || 0, a.failed || 0) }))
    .filter((x) => x.r != null)
    .sort((x, y) => (x.r as number) - (y.r as number))
    .slice(0, 8), [allAssets]);

  const checkParts: Part[] = [
    { key: 'passed', label: 'Passed', n: roll.passed, c: T.success },
    { key: 'failed', label: 'Failed', n: roll.failed, c: SEV.critical.c },
    { key: 'errored', label: 'Errored', n: roll.errored, c: SEV.info.c },
  ];
  const covParts: Part[] = [
    { key: 'scanned', label: 'Scanned', n: roll.scannedAssets, c: T.base },
    { key: 'awaiting', label: 'Awaiting scan', n: roll.awaiting, c: SEV.medium.c },
    { key: 'unmapped', label: 'No benchmark mapped', n: roll.unmapped, c: '#CBD5E1' },
  ];
  const sevParts: Part[] = SEV_ORDER.map((s) => ({ key: s, label: SEV[s].label, n: fail.bySev[s] || 0, c: SEV[s].c })).filter((p) => p.n > 0);

  const scanned = roll.scannedAssets > 0;
  const grid = 'grid grid-cols-1 gap-3 xl:grid-cols-12';

  return (
    <div style={{ background: '#F4F6F7', padding: '20px 22px', minHeight: 'calc(100vh - 46px)', fontFamily: FONT }}>
      {/* header */}
      <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-between', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <div>
          <h2 style={{ fontSize: 17, letterSpacing: '-.02em', margin: 0, color: T.text }}>CIS Benchmark compliance</h2>
          <p style={{ fontSize: 12, color: T.muted, marginTop: 3, maxWidth: 640 }}>
            How hardened the estate is against its matched CIS benchmarks — pass rate, scan coverage, the controls that fail most, and the assets that need attention. Every figure is read from live scan results.
          </p>
        </div>
        <div style={{ fontSize: 11.5, color: T.muted, textAlign: 'right' }}>
          {overviewQ.isLoading ? 'Loading…' : (
            <>
              <b style={{ color: T.text }}>{nfmt(roll.scannedAssets)}</b> of {nfmt(roll.total)} assets scanned<br />
              {roll.lastScan ? `last scan ${fmtAgo(roll.lastScan)}` : 'no scans yet'}
              {overviewQ.data?.totals?.total_rules ? ` · ${nfmt(overviewQ.data.totals.total_rules)} rules in library` : ''}
            </>
          )}
        </div>
      </div>

      {overviewQ.isLoading ? (
        <Loading rows={6} note="Loading CIS scan results across the estate…" />
      ) : overviewQ.isError ? (
        <Unavailable what="CIS compliance" href="/admin/agents" />
      ) : roll.total === 0 ? (
        <Empty icon={<ServerCog size={18} />} title="No assets in inventory yet" body="Discover or import assets, connect a scanner, then run a CIS benchmark scan to see hardening across the estate." href="/asset-discovery" cta="Bring assets in" />
      ) : !scanned ? (
        // Mapped-but-unscanned: one honest CTA plus the coverage breakdown, not five empty panels.
        <div className={grid}>
          <Card title="Scan coverage" sub="Assets ready vs scanned" className="xl:col-span-5">
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px 22px', marginBottom: 6 }}>
              <Figure label="Matched & ready" value={nfmt(roll.withBenchmark)} sub={`of ${nfmt(roll.total)} assets`} />
              <Figure label="No benchmark yet" value={nfmt(roll.unmapped)} sub="need an OS profile" />
            </div>
            <div style={{ marginTop: 'auto', paddingTop: 10 }}><StackBar parts={covParts} label="Scan coverage" /></div>
            <div style={{ marginTop: 10 }}><PartLegend parts={covParts} total={roll.total} /></div>
          </Card>
          <div className="xl:col-span-7">
            <Empty icon={<ClipboardCheck size={18} />} title="No CIS scan has run yet"
              body={<>{nfmt(roll.total)} assets in inventory{roll.withBenchmark ? <>, {nfmt(roll.withBenchmark)} already matched to a benchmark and ready to scan</> : null}. Hardening is <b>unmeasured</b>, not passing — run a scan to populate this dashboard.</>}
              href="/admin/agents" cta="Connect a scanner" />
          </div>
        </div>
      ) : (
        <div className="flex flex-col gap-3">
          {/* Row A — score · coverage · remediation */}
          <div className={grid}>
            <Card title="Overall CIS compliance" sub="Passed ÷ (passed + failed)" href="/assets?tab=cis" cta="Details" busy={overviewQ.isFetching} className="xl:col-span-4">
              <div style={{ display: 'flex', alignItems: 'center', gap: 18, flexWrap: 'wrap' }}>
                <Ring pct={roll.passRate} />
                <div style={{ flex: 1, minWidth: 130 }}>
                  <StackBar parts={checkParts} label="Checks passed, failed, errored" />
                  <div style={{ marginTop: 10 }}><PartLegend parts={checkParts} total={roll.checks} /></div>
                </div>
              </div>
            </Card>

            <Card title="Scan coverage" sub="Assets scanned vs awaiting" href="/assets?tab=cis" cta="Details" className="xl:col-span-4">
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '6px 22px', marginBottom: 6 }}>
                <Figure label="Scanned" value={`${nfmt(roll.scannedAssets)} / ${nfmt(roll.total)}`} sub={`${pctOf(roll.scannedAssets, roll.total)}% of the estate`} />
                <Figure label="Checks run" value={nfmt(roll.checks)} sub={`${nfmt(roll.errored)} couldn't evaluate`} />
              </div>
              <div style={{ marginTop: 'auto', paddingTop: 10 }}><StackBar parts={covParts} label="Scan coverage" /></div>
              <div style={{ marginTop: 10 }}><PartLegend parts={covParts} total={roll.total} /></div>
            </Card>

            <Card title="Remediation by severity" sub="Failed checks across scanned assets" href="/vulnerabilities" cta="Plan work" className="xl:col-span-4">
              {fail.loading && !fail.haveData ? <Loading rows={3} note="Reading per-asset rule results…" />
                : fail.total === 0 ? <Empty compact icon={<ShieldCheck size={16} />} title="No failing checks" body="Every evaluated check on every scanned asset passed." />
                  : (
                    <div className="flex flex-1 flex-col">
                      <Figure label="Failing checks" value={nfmt(fail.total)} sub={`across ${plural(failingIds.length, 'asset')}`} />
                      <div style={{ marginTop: 'auto', paddingTop: 12 }}><StackBar parts={sevParts} label="Failed checks by severity" /></div>
                      <div style={{ marginTop: 10 }}><PartLegend parts={sevParts} total={fail.total} cols={2} /></div>
                    </div>
                  )}
            </Card>
          </div>

          {/* Row B — pass rate by OS family · by benchmark */}
          <div className={grid}>
            <Card title="Pass rate by OS family" sub="Weakest hardening first" className="xl:col-span-6">
              {familyRows.some((r) => r.n != null)
                ? <BarList rows={familyRows} max={100} labelWidth={150} missing="Not scanned" fill />
                : <Empty compact title="Nothing measured yet" body="Scan an asset in any category to compare families." />}
            </Card>
            <Card title="Pass rate by benchmark" sub="Matched CIS benchmarks" className="xl:col-span-6">
              {benchRows.some((r) => r.n != null)
                ? <BarList rows={benchRows} max={100} labelWidth={210} missing="Not scanned" fill />
                : <Empty compact title="No benchmark measured yet" body="Assets need an OS profile before a CIS benchmark is matched and scanned." />}
            </Card>
          </div>

          {/* Row C — top failing controls · assets needing attention */}
          <div className={grid}>
            <Card title="Top failing controls" sub="CIS rules failing on the most assets" className="xl:col-span-7">
              {fail.loading && !fail.haveData ? <Loading rows={5} note="Reading per-asset rule results…" />
                : fail.top.length === 0 ? <Empty compact icon={<ShieldCheck size={16} />} title="No failing controls" body="No evaluated CIS rule is currently failing on any scanned asset." />
                  : <TopFailTable rows={fail.top} />}
            </Card>
            <Card title="Assets needing attention" sub="Lowest pass rate first" href="/assets?tab=cis" cta="All assets" className="xl:col-span-5">
              {worst.length === 0 ? <Empty compact title="No scored assets yet" body="Pass rates appear once an asset has evaluated checks." />
                : <WorstTable rows={worst} />}
            </Card>
          </div>
        </div>
      )}
    </div>
  );
}
