'use client';

/**
 * VulnCommandCenter — the Vulnerabilities "Overview" pane: a dense, premium
 * VISUAL ANALYTICS dashboard (not a worklist). It leads with a KPI band and is
 * carried by charts — severity & status distributions, threat-intel bands, a
 * 90-day discovered-vs-resolved trend, an asset criticality × severity heat
 * grid, an SLA gauge + aging, and backlog by assessment type / owner — with a
 * single compact "fix first" card at the end.
 *
 * Distinct by design from the Performance dashboard (risk gauge + lens cards)
 * and the IT Asset Inventory Overview (External/Internal split panels): THIS is
 * the charts-and-metrics surface.
 *
 * Ava product tokens only (#005B96 accent, Poppins, light theme, soft card
 * shadows, grey canvas + separated white cards). Recharts marks are themed to
 * an Ava-mapped palette + a validated categorical ramp — never the GRC
 * blue/multicolor default. Every number is real; sparse signals read as honest
 * "not scored yet" empty states, never "zero risk". No engine/tool names — a
 * finding's source is mapped to an assessment type.
 */

import { useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  PieChart, Pie, Cell, ResponsiveContainer, ComposedChart, Area, Line,
  XAxis, YAxis, CartesianGrid, Tooltip, RadialBarChart, RadialBar, PolarAngleAxis,
} from 'recharts';
import { Flame, Globe, Clock3, ShieldAlert, ArrowRight, Activity, TrendingUp } from 'lucide-react';
import { vulnManagementApi } from '@/lib/api';
import { shortenVulnTitle, assessmentType, type Vulnerability } from './lib';

// ── Ava palette (literal, matching the workspace) ──
const AC = '#005B96', ACS = '#014A81', ACSOFT = '#EFF5FA';
const INK = '#0F1F2B', SEC = '#3A4653', MUTED = '#8A95A1', FAINT = '#AEB8C2', BORDER = '#E8ECEE', BORDER2 = '#F0F3F5';
const MONO = 'ui-monospace,Consolas,monospace';
const TNUM: React.CSSProperties = { fontVariantNumeric: 'tabular-nums' };

// Severity — the product's status-reserved severity tones.
const SEV = {
  critical: { c: '#C2453F', label: 'Critical' },
  high: { c: '#C0682F', label: 'High' },
  medium: { c: '#E0AF33', label: 'Medium' },
  low: { c: '#1F7A54', label: 'Low' },
  info: { c: '#AEB8C2', label: 'Info' },
} as const;
type SevKey = keyof typeof SEV;
const SEV_ORDER: SevKey[] = ['critical', 'high', 'medium', 'low', 'info'];

// Status — Ava-mapped (NOT the GRC recharts palette).
const STATUS: Record<string, { c: string; label: string }> = {
  open: { c: '#C2453F', label: 'Open' },
  in_progress: { c: '#E0AF33', label: 'In progress' },
  remediated: { c: '#4C7A9C', label: 'Remediated' },
  verified: { c: '#1F7A54', label: 'Verified' },
  closed: { c: '#AEB8C2', label: 'Closed' },
  accepted: { c: '#7A5AC9', label: 'Risk accepted' },
  false_positive: { c: '#CBD3DA', label: 'False positive' },
  auto_closed_fixed: { c: '#2E8B6B', label: 'Closed · verified' },
  auto_closed_decommissioned: { c: '#AEB8C2', label: 'Closed · retired' },
};

// Sequential single-hue accent ramp (magnitude → heat grid).
const BLUE_RAMP = ['#EAF2F8', '#C7DDEC', '#9CC3DE', '#5E9AC4', '#2E77AB', '#005B96'];
const rampAt = (t: number) => BLUE_RAMP[Math.max(0, Math.min(BLUE_RAMP.length - 1, Math.round(t * (BLUE_RAMP.length - 1))))];

// Categorical identity (validated CVD/contrast-safe) — assessment types.
const ASMT_COLOR: Record<string, string> = {
  'Vulnerability scan': '#005B96',
  'Web application scan': '#2E8B6B',
  'Penetration test': '#A8640E',
};

// EPSS exploit-likelihood bands (alarm→calm) + the server's key names.
const EPSS_BANDS: { k: string; label: string; c: string }[] = [
  { k: 'very_high', label: '≥ 50%', c: '#C2453F' },
  { k: 'high', label: '10–50%', c: '#C0682F' },
  { k: 'moderate', label: '1–10%', c: '#E0AF33' },
  { k: 'low', label: '0.1–1%', c: '#5E9AC4' },
  { k: 'negligible', label: '< 0.1%', c: '#AEB8C2' },
  { k: 'unscored', label: 'Not scored', c: '#E3E8EC' },
];
const PRIO_BANDS: { k: string; label: string; c: string }[] = [
  { k: 'critical', label: 'Critical', c: '#C2453F' },
  { k: 'high', label: 'High', c: '#C0682F' },
  { k: 'medium', label: 'Medium', c: '#E0AF33' },
  { k: 'low', label: 'Low', c: '#1F7A54' },
  { k: 'unscored', label: 'Unscored', c: '#CBD3DA' },
];

const RESOLVED = new Set(['resolved', 'remediated', 'verified', 'closed', 'accepted', 'false_positive', 'auto_closed_decommissioned', 'auto_closed_fixed']);
const normSev = (s?: string): SevKey => { const k = (s || '').toLowerCase(); return (k in SEV ? k : k === 'informational' ? 'info' : 'info') as SevKey; };
const hasExploit = (v: Vulnerability) => (v.public_exploit_count ?? 0) > 0 || (v.exploitdb_count ?? 0) > 0 || !!v.kev_flag;
const isExposed = (v: Vulnerability) => !!v.internet_facing || !!v.internet_exposed;
const ctx = (v: Vulnerability) => Math.round((v.composite_priority ?? 0) * 10);
const band = (n: number) => (n >= 55 ? { c: '#C2453F', label: 'Urgent' } : n >= 25 ? { c: '#9A6410', label: 'Moderate' } : { c: '#1F7A54', label: 'Low' });
const dueDays = (v: Vulnerability) => (v.due_date ? Math.ceil((new Date(v.due_date).getTime() - Date.now()) / 864e5) : null);
const isOverdue = (v: Vulnerability) => { const d = dueDays(v); return d != null && d < 0; };
const ageDays = (v: Vulnerability) => { const b = v.discovered_at || v.created_at; return b ? Math.floor((Date.now() - new Date(b).getTime()) / 864e5) : null; };

// ── server response shapes (reused from the standalone dashboard) ──
interface ThreatIntel {
  kev_exposure: { kev: number; non_kev: number };
  priority_buckets: { critical: number; high: number; medium: number; low: number; unscored: number };
  epss_bands: { very_high: number; high: number; moderate: number; low: number; negligible: number; unscored: number };
  asset_criticality_matrix: Array<{ asset_criticality: string; critical: number; high: number; medium: number; low: number; info: number }>;
  enrichment_coverage: { total_open: number; enriched: number; kev_count: number; epss_count: number };
}
interface HeatmapRow { asset_id: number; asset_name: string; criticality?: string | null; open_vuln_count: number; kev_count: number; total_priority_sum: number; }
interface Heatmap { assets: HeatmapRow[]; summary: { total_assets: number; total_open_vulns: number } }
interface Trends { buckets: string[]; discovered: { count: number }[]; resolved: { count: number }[]; summary: { total_discovered: number; total_resolved: number; total_status_changes: number } }

interface OverviewDashboard {
  total_vulnerabilities?: number;
  by_severity?: Record<string, number>;
  by_status?: Record<string, number>;
  sla_compliance?: Record<string, { compliance_rate: number }>;
  overdue_count?: number;
  mttr_days?: number | null;
  by_department?: Record<string, number>;
}

const card: React.CSSProperties = { background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 14, boxShadow: '0 1px 2px rgba(16,24,40,.04)' };
const capCss: React.CSSProperties = { fontSize: 10, fontWeight: 700, letterSpacing: '.07em', textTransform: 'uppercase', color: FAINT };

export default function VulnCommandCenter({
  vulns, dashboard, onView,
}: {
  vulns: Vulnerability[];
  dashboard?: OverviewDashboard;
  onView: (v: Vulnerability) => void;
}) {
  // Extra aggregates not already loaded by the page (shared query keys, cached).
  const { data: threat } = useQuery({ queryKey: ['vuln-threat-intel'], queryFn: async () => (await vulnManagementApi.dashboard.getThreatIntel()).data as ThreatIntel, staleTime: 60_000 });
  const { data: heatmap } = useQuery({ queryKey: ['vuln-asset-heatmap'], queryFn: async () => (await vulnManagementApi.dashboard.getAssetRiskHeatmap()).data as Heatmap, staleTime: 60_000 });
  const { data: trends } = useQuery({ queryKey: ['vuln-trends-overview', '90d'], queryFn: async () => (await vulnManagementApi.dashboard.getTrends({ period: '90d' })).data as Trends, staleTime: 60_000 });

  const m = useMemo(() => {
    const all = vulns || [];
    const open = all.filter((v) => !RESOLVED.has((v.status || '').toLowerCase()));
    const totalOpen = open.length;
    const critHigh = open.filter((v) => { const s = normSev(v.severity); return s === 'critical' || s === 'high'; }).length;
    const exploited = open.filter((v) => v.kev_flag || hasExploit(v)).length;
    const exposed = open.filter(isExposed).length;
    const overdue = open.filter(isOverdue).length;

    // Severity distribution of OPEN findings (coherent with the KPI band).
    const sevDist = SEV_ORDER.map((k) => ({ name: SEV[k].label, k, value: open.filter((v) => normSev(v.severity) === k).length, c: SEV[k].c })).filter((d) => d.value > 0);

    // Status breakdown — whole register (server aggregate, else derive).
    const byStatusRaw = dashboard?.by_status ?? all.reduce<Record<string, number>>((a, v) => { const s = (v.status || 'open').toLowerCase(); a[s] = (a[s] || 0) + 1; return a; }, {});
    const statusDist = Object.entries(byStatusRaw).filter(([, n]) => n > 0).map(([k, n]) => ({ k, n, c: STATUS[k]?.c || '#CBD3DA', label: STATUS[k]?.label || k.replace(/_/g, ' ') })).sort((a, b) => b.n - a.n);
    const statusTotal = statusDist.reduce((s, x) => s + x.n, 0) || 1;

    // EPSS bands + composite-priority buckets (threat-intel, else derive from open).
    const epss = EPSS_BANDS.map((b) => ({ ...b, n: (threat?.epss_bands as Record<string, number> | undefined)?.[b.k] ?? (b.k === 'unscored' ? open.filter((v) => v.epss_score == null).length : b.k === 'very_high' ? open.filter((v) => (v.epss_score ?? -1) >= 0.5).length : b.k === 'high' ? open.filter((v) => (v.epss_score ?? -1) >= 0.1 && (v.epss_score as number) < 0.5).length : b.k === 'moderate' ? open.filter((v) => (v.epss_score ?? -1) >= 0.01 && (v.epss_score as number) < 0.1).length : b.k === 'low' ? open.filter((v) => (v.epss_score ?? -1) >= 0.001 && (v.epss_score as number) < 0.01).length : open.filter((v) => v.epss_score != null && (v.epss_score as number) < 0.001).length) }));
    const prio = PRIO_BANDS.map((b) => ({ ...b, n: (threat?.priority_buckets as Record<string, number> | undefined)?.[b.k] ?? (b.k === 'unscored' ? open.filter((v) => v.composite_priority == null).length : b.k === 'critical' ? open.filter((v) => ctx(v) >= 70).length : b.k === 'high' ? open.filter((v) => ctx(v) >= 40 && ctx(v) < 70).length : b.k === 'medium' ? open.filter((v) => ctx(v) >= 20 && ctx(v) < 40).length : open.filter((v) => v.composite_priority != null && ctx(v) < 20).length) }));
    const epssMax = Math.max(1, ...epss.map((e) => e.n));
    const prioMax = Math.max(1, ...prio.map((p) => p.n));

    // KEV exposure + public-exploit.
    const kev = threat?.kev_exposure?.kev ?? open.filter((v) => !!v.kev_flag).length;
    const nonKev = threat?.kev_exposure?.non_kev ?? (totalOpen - kev);
    const publicExploit = open.filter(hasExploit).length;

    // Trends (90d).
    const tb = trends?.buckets ?? [];
    let cum = 0;
    const trendData = tb.map((b, i) => {
      const d = trends!.discovered[i]?.count ?? 0; const r = trends!.resolved[i]?.count ?? 0; cum += d - r;
      const dt = new Date(b); const name = Number.isNaN(dt.getTime()) ? b : dt.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
      return { name, Discovered: d, Resolved: r, 'Net change': cum };
    });
    const trendActive = trendData.some((d) => d.Discovered || d.Resolved);

    // Asset criticality × severity heat grid.
    const matrix = (threat?.asset_criticality_matrix ?? []).filter((r) => (r.critical + r.high + r.medium + r.low + r.info) > 0);
    const matrixMax = Math.max(1, ...matrix.flatMap((r) => [r.critical, r.high, r.medium, r.low, r.info]));

    // Top exposed assets by summed open priority.
    const topAssets = [...(heatmap?.assets ?? [])].sort((a, b) => b.total_priority_sum - a.total_priority_sum).slice(0, 6);
    const assetMax = Math.max(1, ...topAssets.map((a) => a.total_priority_sum));

    // SLA + aging.
    const slaVals = dashboard?.sla_compliance ? Object.entries(dashboard.sla_compliance) : [];
    const slaPct = slaVals.length ? Math.round(slaVals.reduce((s, [, x]) => s + (x.compliance_rate || 0), 0) / slaVals.length) : null;
    const slaBySev = SEV_ORDER.map((k) => ({ k, rate: dashboard?.sla_compliance?.[k]?.compliance_rate })).filter((x) => x.rate != null);
    const agingDefs: [string, (d: number) => boolean][] = [['0–30d', (d) => d <= 30], ['31–90d', (d) => d > 30 && d <= 90], ['91–180d', (d) => d > 90 && d <= 180], ['> 180d', (d) => d > 180]];
    const aging = agingDefs.map(([label, f]) => ({ label, n: open.filter((v) => { const d = ageDays(v); return d != null && f(d); }).length }));
    const agingMax = Math.max(1, ...aging.map((a) => a.n));

    // Backlog by assessment type (de-branded) + by owner/department.
    const asmtMap = new Map<string, number>();
    for (const v of open) { const t = assessmentType(v.source || v.plugin_family); asmtMap.set(t, (asmtMap.get(t) || 0) + 1); }
    const asmt = Array.from(asmtMap.entries()).map(([name, n]) => ({ name, n, c: ASMT_COLOR[name] || AC })).sort((a, b) => b.n - a.n);
    const asmtMax = Math.max(1, ...asmt.map((a) => a.n));
    // Prefer the server aggregate, but fall back to client grouping when it's
    // absent OR empty (an empty {} is truthy, so `??` alone would leave the card blank).
    const deptRaw = (dashboard?.by_department && Object.keys(dashboard.by_department).length)
      ? dashboard.by_department
      : open.reduce<Record<string, number>>((a, v) => { const k = v.assigned_departments?.[0] || v.assignee_name || 'Unassigned'; a[k] = (a[k] || 0) + 1; return a; }, {});
    const dept = Object.entries(deptRaw).map(([name, n]) => ({ name, n })).sort((a, b) => b.n - a.n).slice(0, 6);
    const deptMax = Math.max(1, ...dept.map((d) => d.n));

    // Fix-first (compact) — top open by contextual priority.
    const fixFirst = [...open].sort((a, b) => ctx(b) - ctx(a)).slice(0, 7);

    // Enrichment honesty.
    const cveRows = open.filter((v) => !!v.cve_id).length;
    const ec = threat?.enrichment_coverage;
    const enriched = ec?.enriched ?? open.filter((v) => v.epss_score != null || v.kev_flag != null || v.public_exploit_count != null).length;
    const enrichBase = ec?.total_open ?? totalOpen;
    const enrichPct = enrichBase ? Math.round((enriched / enrichBase) * 100) : 0;

    return {
      totalOpen, critHigh, exploited, exposed, overdue, mttr: dashboard?.mttr_days ?? null,
      sevDist, statusDist, statusTotal, epss, epssMax, prio, prioMax, kev, nonKev, publicExploit,
      trendData, trendActive, trendSummary: trends?.summary, matrix, matrixMax, topAssets, assetMax,
      slaPct, slaBySev, aging, agingMax, asmt, asmtMax, dept, deptMax, fixFirst,
      cveRows, enriched, enrichBase, enrichPct,
    };
  }, [vulns, dashboard, threat, heatmap, trends]);

  const slaColor = m.slaPct == null ? FAINT : m.slaPct >= 80 ? '#1F7A54' : m.slaPct >= 60 ? '#C0682F' : '#C2453F';
  const w = (n: number, max: number) => `${max ? Math.max(n > 0 ? 5 : 0, (n / max) * 100) : 0}%`;

  const kpis: { label: string; value: string; tone?: string; sub: string; Icon?: typeof Flame }[] = [
    { label: 'Open findings', value: String(m.totalOpen), sub: 'active in register' },
    { label: 'Critical + High', value: String(m.critHigh), tone: m.critHigh ? '#C0682F' : INK, sub: 'by raw severity' },
    { label: 'Actively exploited', value: String(m.exploited), tone: m.exploited ? '#C2453F' : INK, sub: 'KEV / public exploit', Icon: Flame },
    { label: 'Internet-exposed', value: String(m.exposed), tone: m.exposed ? '#7A5AC9' : INK, sub: 'reachable from outside', Icon: Globe },
    { label: 'Overdue', value: String(m.overdue), tone: m.overdue ? '#C2453F' : INK, sub: 'past SLA due date', Icon: Clock3 },
    { label: 'MTTR', value: m.mttr != null ? `${m.mttr}d` : '—', sub: 'mean time to remediate' },
    { label: 'SLA on-time', value: m.slaPct != null ? `${m.slaPct}%` : '—', tone: m.slaPct != null && m.slaPct < 80 ? '#C2453F' : INK, sub: 'avg across severities' },
  ];

  return (
    <div style={{ height: '100%', overflowY: 'auto', overflowX: 'hidden', display: 'flex', flexDirection: 'column', gap: 12, color: INK, fontSize: 13.5, paddingBottom: 8 }}>
      {/* ── KPI band ── */}
      <section style={{ ...card, padding: '12px 14px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 10 }}>
          <Activity size={15} color={ACS} /><b style={{ fontSize: 13.5 }}>Open security posture</b>
          <span style={{ fontSize: 11, color: MUTED, marginLeft: 'auto' }}>real-world risk across every open finding</span>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(132px,1fr))', gap: 10 }}>
          {kpis.map((k) => (
            <div key={k.label} style={{ border: `1px solid ${BORDER2}`, borderRadius: 11, padding: '10px 12px', minWidth: 0 }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 5 }}>
                {k.Icon && <k.Icon size={11} color={k.tone && k.tone !== INK ? k.tone : FAINT} />}
                <span style={{ fontSize: 10.5, color: MUTED, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{k.label}</span>
              </div>
              <div style={{ fontSize: 24, fontWeight: 600, color: k.tone || INK, lineHeight: 1.15, marginTop: 3, ...TNUM }}>{k.value}</div>
              <div style={{ fontSize: 10, color: FAINT, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{k.sub}</div>
            </div>
          ))}
        </div>
      </section>

      {/* ── distributions: severity donut + status + threat posture ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(min(300px,100%),1fr))', gap: 12 }}>
        {/* severity donut */}
        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Severity distribution" sub="open findings" />
          {m.sevDist.length === 0 ? <Empty>No open findings.</Empty> : (
            <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 8 }}>
              <div style={{ position: 'relative', width: 132, height: 132, flex: 'none' }}>
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie data={m.sevDist} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={44} outerRadius={62} paddingAngle={2} stroke="#fff" strokeWidth={2}>
                      {m.sevDist.map((d) => <Cell key={d.k} fill={d.c} />)}
                    </Pie>
                    <Tooltip content={<DonutTip total={m.totalOpen} />} />
                  </PieChart>
                </ResponsiveContainer>
                <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', pointerEvents: 'none' }}>
                  <div style={{ textAlign: 'center' }}><div style={{ fontSize: 22, fontWeight: 700, ...TNUM }}>{m.totalOpen}</div><div style={{ fontSize: 9, letterSpacing: '.08em', color: FAINT }}>OPEN</div></div>
                </div>
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                {m.sevDist.map((d) => (
                  <div key={d.k} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '4px 0', borderBottom: `1px solid #F4F6F7`, fontSize: 12 }}>
                    <span style={{ width: 9, height: 9, borderRadius: 2, background: d.c, flex: 'none' }} />
                    <span style={{ color: SEC, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{d.name}</span>
                    <b style={{ marginLeft: 'auto', ...TNUM }}>{d.value}</b>
                    <span style={{ width: 34, textAlign: 'right', fontSize: 11, color: FAINT, ...TNUM }}>{Math.round((d.value / Math.max(1, m.totalOpen)) * 100)}%</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </section>

        {/* status breakdown */}
        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Status breakdown" sub="whole register" />
          <div style={{ marginTop: 12, display: 'flex', height: 12, borderRadius: 999, overflow: 'hidden', background: '#EEF1F3', gap: 2 }}>
            {m.statusDist.map((s) => <i key={s.k} title={`${s.label}: ${s.n}`} style={{ width: `${(s.n / m.statusTotal) * 100}%`, background: s.c }} />)}
          </div>
          <div style={{ marginTop: 10, display: 'grid', gridTemplateColumns: 'repeat(2,minmax(0,1fr))', gap: '4px 14px' }}>
            {m.statusDist.map((s) => (
              <div key={s.k} style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: 11.5, minWidth: 0 }}>
                <span style={{ width: 8, height: 8, borderRadius: 2, background: s.c, flex: 'none' }} />
                <span style={{ color: SEC, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{s.label}</span>
                <b style={{ marginLeft: 'auto', ...TNUM }}>{s.n}</b>
              </div>
            ))}
          </div>
        </section>

        {/* threat posture */}
        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Threat posture" sub="exploited & reachable" />
          <div style={{ display: 'flex', alignItems: 'center', gap: 14, marginTop: 10 }}>
            <Ring value={m.kev} total={Math.max(1, m.kev + m.nonKev)} color="#C2453F" label="KEV" />
            <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 8 }}>
              <PostureStat label="Actively exploited (KEV)" n={m.kev} c="#C2453F" />
              <PostureStat label="Public exploit available" n={m.publicExploit} c="#C0682F" />
              <PostureStat label="Internet-exposed" n={m.exposed} c="#7A5AC9" />
            </div>
          </div>
          <p style={{ fontSize: 10.5, color: FAINT, marginTop: 10, lineHeight: 1.5 }}>Known-exploited &amp; internet-facing findings are what attackers reach first — these jump the queue regardless of raw CVSS.</p>
        </section>
      </div>

      {/* ── threat-intel bands: EPSS + composite priority ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(min(320px,100%),1fr))', gap: 12 }}>
        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Exploit likelihood" sub="EPSS probability bands" />
          <BandBars rows={m.epss.map((e) => ({ label: e.label, n: e.n, c: e.c }))} max={m.epssMax} />
        </section>
        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Contextual priority" sub="CVSS × exploit × exposure × asset" />
          <BandBars rows={m.prio.map((p) => ({ label: p.label, n: p.n, c: p.c }))} max={m.prioMax} />
        </section>
      </div>

      {/* ── trends (90d) ── */}
      <section style={{ ...card, padding: '14px 16px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap', marginBottom: 4 }}>
          <TrendingUp size={15} color={ACS} /><b style={{ fontSize: 13.5 }}>Discovered vs resolved</b>
          <span style={{ fontSize: 11, color: MUTED }}>last 90 days</span>
          <div style={{ display: 'flex', gap: 16, marginLeft: 'auto', flexWrap: 'wrap' }}>
            <LegendDot c="#C0682F" label="Discovered" n={m.trendSummary?.total_discovered} />
            <LegendDot c="#1F7A54" label="Resolved" n={m.trendSummary?.total_resolved} />
            <LegendDot c={AC} label="Net change (cum.)" />
            <span style={{ fontSize: 11, color: MUTED }}>Status changes <b style={{ color: INK, ...TNUM }}>{m.trendSummary?.total_status_changes ?? 0}</b></span>
          </div>
        </div>
        {!m.trendActive ? <Empty>No discovery or remediation activity recorded in the last 90 days.</Empty> : (
          <div style={{ height: 196, marginTop: 6 }}>
            <ResponsiveContainer width="100%" height="100%">
              <ComposedChart data={m.trendData} margin={{ top: 6, right: 8, bottom: 0, left: -14 }}>
                <defs>
                  <linearGradient id="gDisc" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#C0682F" stopOpacity={0.22} /><stop offset="100%" stopColor="#C0682F" stopOpacity={0} /></linearGradient>
                  <linearGradient id="gRes" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#1F7A54" stopOpacity={0.2} /><stop offset="100%" stopColor="#1F7A54" stopOpacity={0} /></linearGradient>
                </defs>
                <CartesianGrid vertical={false} stroke="#F0F3F5" />
                <XAxis dataKey="name" tick={{ fontSize: 10, fill: MUTED }} axisLine={{ stroke: BORDER }} tickLine={false} interval="preserveStartEnd" minTickGap={22} />
                <YAxis tick={{ fontSize: 10, fill: MUTED }} axisLine={false} tickLine={false} width={34} allowDecimals={false} />
                <Tooltip content={<TrendTip />} />
                <Area type="monotone" dataKey="Discovered" stroke="#C0682F" strokeWidth={2} fill="url(#gDisc)" dot={false} activeDot={{ r: 3 }} />
                <Area type="monotone" dataKey="Resolved" stroke="#1F7A54" strokeWidth={2} fill="url(#gRes)" dot={false} activeDot={{ r: 3 }} />
                <Line type="monotone" dataKey="Net change" stroke={AC} strokeWidth={2} dot={false} activeDot={{ r: 3 }} />
              </ComposedChart>
            </ResponsiveContainer>
          </div>
        )}
      </section>

      {/* ── asset risk: heat grid + top exposed ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(min(340px,100%),1fr))', gap: 12 }}>
        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Asset criticality × severity" sub="open findings heat grid" />
          {m.matrix.length === 0 ? <Empty>No findings are linked to a criticality-rated asset yet — link assets to map blast radius.</Empty> : (
            <div style={{ marginTop: 10, overflowX: 'auto' }}>
              <div style={{ display: 'grid', gridTemplateColumns: `96px repeat(5, minmax(42px,1fr))`, gap: 3, minWidth: 320 }}>
                <span />
                {SEV_ORDER.map((k) => <div key={k} style={{ ...capCss, fontSize: 9, textAlign: 'center', paddingBottom: 2 }}>{SEV[k].label}</div>)}
                {m.matrix.map((r) => (
                  <HeatRow key={r.asset_criticality} r={r} max={m.matrixMax} />
                ))}
              </div>
              <p style={{ fontSize: 10, color: FAINT, marginTop: 8 }}>Cell shade = how many open findings of that severity sit on assets of that criticality. Top-left is the danger corner.</p>
            </div>
          )}
        </section>

        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Top exposed assets" sub="by summed open priority" />
          {m.topAssets.length === 0 ? <Empty>No asset-linked open findings yet.</Empty> : (
            <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 7 }}>
              {m.topAssets.map((a) => (
                <div key={a.asset_id} style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) 92px 70px', gap: 10, alignItems: 'center' }}>
                  <span style={{ fontSize: 12, color: SEC, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={a.asset_name}>{a.asset_name}{a.kev_count > 0 && <span style={{ fontSize: 9, fontWeight: 700, color: '#C2453F', background: '#FBEAEA', borderRadius: 999, padding: '1px 5px', marginLeft: 6 }}>KEV</span>}</span>
                  <span style={{ height: 9, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: w(a.total_priority_sum, m.assetMax), background: AC, borderRadius: 4 }} /></span>
                  <span style={{ fontSize: 11, textAlign: 'right', color: MUTED, ...TNUM }}><b style={{ color: INK }}>{a.open_vuln_count}</b> · {Math.round(a.total_priority_sum)}</span>
                </div>
              ))}
              <p style={{ fontSize: 10, color: FAINT, marginTop: 2 }}>open findings · summed contextual priority</p>
            </div>
          )}
        </section>
      </div>

      {/* ── SLA gauge + aging ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(min(300px,100%),1fr))', gap: 12 }}>
        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="SLA compliance" sub="on-time remediation" />
          <div style={{ display: 'flex', alignItems: 'center', gap: 16, marginTop: 6 }}>
            <div style={{ position: 'relative', width: 128, height: 112, flex: 'none' }}>
              <ResponsiveContainer width="100%" height="100%">
                <RadialBarChart innerRadius="70%" outerRadius="100%" data={[{ value: m.slaPct ?? 0 }]} startAngle={216} endAngle={-36}>
                  <PolarAngleAxis type="number" domain={[0, 100]} tick={false} />
                  <RadialBar background={{ fill: '#EEF1F3' }} dataKey="value" cornerRadius={8} fill={slaColor} />
                </RadialBarChart>
              </ResponsiveContainer>
              <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center', pointerEvents: 'none' }}>
                <div style={{ textAlign: 'center' }}><div style={{ fontSize: 24, fontWeight: 700, color: slaColor, ...TNUM }}>{m.slaPct != null ? `${m.slaPct}%` : '—'}</div><div style={{ fontSize: 9, letterSpacing: '.06em', color: FAINT }}>ON-TIME</div></div>
              </div>
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              {m.slaBySev.length === 0 ? <span style={{ fontSize: 11.5, color: FAINT }}>SLA policy not configured yet.</span> : m.slaBySev.map(({ k, rate }) => (
                <div key={k} style={{ display: 'grid', gridTemplateColumns: '58px minmax(0,1fr) 34px', gap: 8, alignItems: 'center', padding: '3px 0' }}>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 11, color: SEC }}><span style={{ width: 8, height: 8, borderRadius: 2, background: SEV[k].c, flex: 'none' }} />{SEV[k].label}</span>
                  <span style={{ height: 7, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: `${Math.round(rate as number)}%`, background: (rate as number) >= 80 ? '#1F7A54' : (rate as number) >= 60 ? '#C0682F' : '#C2453F', borderRadius: 4 }} /></span>
                  <b style={{ fontSize: 11, textAlign: 'right', ...TNUM }}>{Math.round(rate as number)}%</b>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Open backlog age" sub="time since discovery" />
          <div style={{ display: 'flex', gap: 10, marginTop: 14, alignItems: 'flex-end' }}>
            {m.aging.map((a, i) => (
              <div key={a.label} style={{ flex: 1, textAlign: 'center', minWidth: 0 }}>
                <div style={{ height: 76, display: 'flex', alignItems: 'flex-end' }}>
                  <span style={{ width: '100%', background: ['#1F7A54', '#E0AF33', '#C0682F', '#C2453F'][i], height: `${Math.max(a.n > 0 ? 10 : 2, (a.n / m.agingMax) * 100)}%`, borderRadius: '4px 4px 0 0' }} />
                </div>
                <b style={{ fontSize: 14, display: 'block', marginTop: 5, ...TNUM }}>{a.n}</b>
                <span style={{ fontSize: 10, color: MUTED, whiteSpace: 'nowrap' }}>{a.label}</span>
              </div>
            ))}
          </div>
          <p style={{ fontSize: 10.5, color: FAINT, marginTop: 10 }}>Findings older than 180 days are the stubborn backlog — unresolved long past any reasonable window.</p>
        </section>
      </div>

      {/* ── backlog by assessment type + by owner ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(min(320px,100%),1fr))', gap: 12 }}>
        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="By assessment type" sub="how each finding was identified" />
          {m.asmt.length === 0 ? <Empty>No open findings.</Empty> : (
            <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 8 }}>
              {m.asmt.map((a) => (
                <div key={a.name} style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) 100px 30px', gap: 10, alignItems: 'center' }}>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 7, fontSize: 12, color: SEC, minWidth: 0 }}><span style={{ width: 9, height: 9, borderRadius: 2, background: a.c, flex: 'none' }} /><span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.name}</span></span>
                  <span style={{ height: 9, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: w(a.n, m.asmtMax), background: a.c, borderRadius: 4 }} /></span>
                  <b style={{ fontSize: 12, textAlign: 'right', ...TNUM }}>{a.n}</b>
                </div>
              ))}
            </div>
          )}
        </section>

        <section style={{ ...card, padding: '14px 16px' }}>
          <CardHead title="Backlog by owner" sub="open findings per team" />
          {m.dept.length === 0 ? <Empty>No open findings.</Empty> : (
            <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 8 }}>
              {m.dept.map((d) => (
                <div key={d.name} style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) 100px 30px', gap: 10, alignItems: 'center' }}>
                  <span style={{ fontSize: 12, color: d.name === 'Unassigned' ? FAINT : SEC, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={d.name}>{d.name}</span>
                  <span style={{ height: 9, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: w(d.n, m.deptMax), background: d.name === 'Unassigned' ? '#AEB8C2' : AC, borderRadius: 4 }} /></span>
                  <b style={{ fontSize: 12, textAlign: 'right', ...TNUM }}>{d.n}</b>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      {/* ── compact fix-first ── */}
      <section style={{ ...card }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '11px 16px', borderBottom: `1px solid ${BORDER2}` }}>
          <Flame size={15} color="#C2453F" /><b style={{ fontSize: 13.5 }}>Fix these first</b>
          <span style={{ fontSize: 11, color: MUTED, marginLeft: 'auto' }}>top open findings by contextual priority · click to open</span>
        </div>
        {m.fixFirst.length === 0 ? <Empty pad>Nothing open right now.</Empty> : (
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <tbody>
              {m.fixFirst.map((v) => {
                const sc = ctx(v); const bm = band(sc); const assets = v.linked_assets || [];
                return (
                  <tr key={v.id} onClick={() => onView(v)} style={{ cursor: 'pointer' }} className="ccrow">
                    <td style={{ padding: '8px 14px', borderBottom: `1px solid ${BORDER2}`, textAlign: 'right', fontFamily: MONO, fontWeight: 700, color: bm.c, width: 54, ...TNUM }}>{sc}</td>
                    <td style={{ padding: '8px 14px', borderBottom: `1px solid ${BORDER2}`, maxWidth: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 6, overflow: 'hidden' }}>
                        <span style={{ width: 8, height: 8, borderRadius: 2, background: SEV[normSev(v.severity)].c, flex: 'none' }} />
                        <span style={{ fontSize: 12.5, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={v.title}>{shortenVulnTitle(v.title)}</span>
                        {v.kev_flag && <span style={{ fontSize: 9, fontWeight: 700, color: '#C2453F', background: '#FBEAEA', borderRadius: 999, padding: '1px 5px', flex: 'none' }}>KEV</span>}
                      </div>
                    </td>
                    <td style={{ padding: '8px 14px', borderBottom: `1px solid ${BORDER2}`, fontFamily: MONO, fontSize: 10.5, color: FAINT, whiteSpace: 'nowrap' }}>{v.cve_id || `VULN-${v.id}`}</td>
                    <td style={{ padding: '8px 14px', borderBottom: `1px solid ${BORDER2}`, fontSize: 12, color: assets.length ? SEC : FAINT, maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={assets.join(', ')}>{assets.length ? `${assets[0]}${assets.length > 1 ? ` +${assets.length - 1}` : ''}` : '—'}</td>
                    <td style={{ padding: '8px 14px', borderBottom: `1px solid ${BORDER2}`, textAlign: 'right', width: 20 }}><ArrowRight size={13} color={FAINT} /></td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </section>

      {/* ── enrichment honesty strip ── */}
      <section style={{ ...card, padding: '12px 16px', background: ACSOFT, borderColor: '#D7E6F2' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 9, flex: 1, minWidth: 260 }}>
            <span style={{ width: 30, height: 30, borderRadius: 8, background: '#fff', color: ACS, display: 'grid', placeItems: 'center', flex: 'none' }}><ShieldAlert size={16} /></span>
            <div style={{ minWidth: 0 }}>
              <b style={{ fontSize: 12.5, color: ACS }}>Data confidence</b>
              <div style={{ fontSize: 11.5, color: SEC, lineHeight: 1.5, marginTop: 1 }}>
                {m.enrichBase === 0
                  ? <>No open findings to enrich.</>
                  : m.enrichPct === 0
                    ? <>Threat intel is <b>not scored yet</b> for the {m.enrichBase} open finding{m.enrichBase === 1 ? '' : 's'} — the bands above reflect CVSS and context only. Empty KEV/EPSS means &ldquo;unscored&rdquo;, not &ldquo;zero risk&rdquo;.</>
                    : <>Threat intel scored for <b>{m.enriched} of {m.enrichBase}</b> open findings ({m.enrichPct}%). Unscored findings still carry risk — they simply aren&apos;t enriched yet.</>}
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 18, flexWrap: 'wrap' }}>
            <MiniStat label="Open" n={m.enrichBase} />
            <MiniStat label="Enriched" n={m.enriched} tone={ACS} />
            <MiniStat label="With CVE" n={m.cveRows} />
          </div>
        </div>
      </section>

      <style>{`.ccrow:hover{background:#F7FBFA}`}</style>
    </div>
  );
}

// ── small primitives ──
function CardHead({ title, sub }: { title: string; sub?: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, flexWrap: 'wrap' }}>
      <b style={{ fontSize: 13.5 }}>{title}</b>
      {sub && <span style={{ fontSize: 11, color: MUTED }}>{sub}</span>}
    </div>
  );
}
function Empty({ children, pad }: { children: React.ReactNode; pad?: boolean }) {
  return <div style={{ fontSize: 11.5, color: FAINT, marginTop: pad ? 0 : 12, padding: pad ? '18px 16px' : 0, lineHeight: 1.5 }}>{children}</div>;
}
function MiniStat({ label, n, tone = INK }: { label: string; n: number; tone?: string }) {
  return <div style={{ textAlign: 'right' }}><div style={{ fontSize: 10.5, color: MUTED, whiteSpace: 'nowrap' }}>{label}</div><b style={{ fontSize: 17, fontWeight: 600, color: tone, ...TNUM }}>{n}</b></div>;
}
function PostureStat({ label, n, c }: { label: string; n: number; c: string }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 8, fontSize: 12 }}>
      <span style={{ width: 9, height: 9, borderRadius: '50%', background: n > 0 ? c : FAINT, flex: 'none' }} />
      <span style={{ color: SEC, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{label}</span>
      <b style={{ marginLeft: 'auto', color: n > 0 ? c : INK, ...TNUM }}>{n}</b>
    </div>
  );
}
function LegendDot({ c, label, n }: { c: string; label: string; n?: number }) {
  return <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 11, color: SEC }}><span style={{ width: 10, height: 3, borderRadius: 2, background: c, flex: 'none' }} />{label}{n != null && <b style={{ color: INK, ...TNUM }}>{n}</b>}</span>;
}
function BandBars({ rows, max }: { rows: { label: string; n: number; c: string }[]; max: number }) {
  return (
    <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 8 }}>
      {rows.map((r) => (
        <div key={r.label} style={{ display: 'grid', gridTemplateColumns: '78px minmax(0,1fr) 34px', gap: 10, alignItems: 'center' }}>
          <span style={{ fontSize: 11.5, color: SEC, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{r.label}</span>
          <span style={{ height: 11, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: `${max ? Math.max(r.n > 0 ? 5 : 0, (r.n / max) * 100) : 0}%`, background: r.c, borderRadius: 4, transition: 'width .3s' }} /></span>
          <b style={{ fontSize: 12, textAlign: 'right', color: INK, ...TNUM }}>{r.n}</b>
        </div>
      ))}
    </div>
  );
}
function Ring({ value, total, color, label }: { value: number; total: number; color: string; label: string }) {
  const pct = Math.round((value / total) * 100);
  const len = (value / total) * 100;
  return (
    <div style={{ position: 'relative', width: 96, height: 96, flex: 'none' }}>
      <svg width="96" height="96" viewBox="0 0 42 42">
        <circle cx="21" cy="21" r="15.9" fill="none" stroke="#EEF1F3" strokeWidth="5" />
        {value > 0 && <circle cx="21" cy="21" r="15.9" fill="none" stroke={color} strokeWidth="5" strokeLinecap="round" strokeDasharray={`${len} ${100 - len}`} strokeDashoffset="25" />}
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'grid', placeItems: 'center' }}>
        <div style={{ textAlign: 'center' }}><div style={{ fontSize: 18, fontWeight: 700, color: value > 0 ? color : INK, ...TNUM }}>{value}</div><div style={{ fontSize: 8.5, letterSpacing: '.06em', color: FAINT }}>{label} · {pct}%</div></div>
      </div>
    </div>
  );
}
function HeatRow({ r, max }: { r: { asset_criticality: string; critical: number; high: number; medium: number; low: number; info: number }; max: number }) {
  const cells = [r.critical, r.high, r.medium, r.low, r.info];
  return (
    <>
      <div style={{ fontSize: 11, color: SEC, display: 'flex', alignItems: 'center', textTransform: 'capitalize', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={r.asset_criticality}>{r.asset_criticality || 'Unknown'}</div>
      {cells.map((n, i) => {
        const t = n / max; const bg = n === 0 ? '#F7F9FB' : rampAt(t); const fg = t > 0.55 ? '#fff' : n === 0 ? FAINT : INK;
        return <div key={i} style={{ background: bg, color: fg, borderRadius: 5, height: 30, display: 'grid', placeItems: 'center', fontSize: 12, fontWeight: n > 0 ? 600 : 400, ...TNUM }}>{n}</div>;
      })}
    </>
  );
}

// ── recharts tooltips (Ava-styled) ──
const tipBox: React.CSSProperties = { background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 9, boxShadow: '0 4px 14px rgba(16,24,40,.1)', padding: '8px 10px', fontSize: 11.5 };
function DonutTip({ active, payload, total }: any) {
  if (!active || !payload?.length) return null;
  const p = payload[0]; const n = p.value as number;
  return <div style={tipBox}><div style={{ display: 'flex', alignItems: 'center', gap: 6 }}><span style={{ width: 9, height: 9, borderRadius: 2, background: p.payload.c }} /><b>{p.name}</b></div><div style={{ color: SEC, marginTop: 2, ...TNUM }}>{n} · {Math.round((n / Math.max(1, total)) * 100)}% of open</div></div>;
}
function TrendTip({ active, payload, label }: any) {
  if (!active || !payload?.length) return null;
  return (
    <div style={tipBox}>
      <div style={{ fontWeight: 600, marginBottom: 4 }}>{label}</div>
      {payload.map((p: any) => <div key={p.dataKey} style={{ display: 'flex', alignItems: 'center', gap: 6, color: SEC, ...TNUM }}><span style={{ width: 8, height: 8, borderRadius: 2, background: p.stroke }} />{p.dataKey} <b style={{ color: INK, marginLeft: 'auto' }}>{p.value}</b></div>)}
    </div>
  );
}
