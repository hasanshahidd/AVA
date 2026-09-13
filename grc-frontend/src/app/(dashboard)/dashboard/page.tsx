'use client';

/**
 * Ava — Performance Overview.
 * Redesign visual (hero score ring, KPI strip, funnel, cards) from the approved mock,
 * wired to LIVE tenant data — no sample/mock numbers, no fabricated people.
 *
 * Two lenses:
 *  - Administrator: org-wide exposure index (derived), KPIs, EPSS, new-findings trend,
 *    needs-attention (ranked by exploitability), exposure funnel, severity mix, by-domain.
 *  - Team: ownership & workload from real assignee data.
 *
 * Anything with no honest backing in this tenant (MTTR, SLA-achievement %, per-user "my"
 * queue, resolved-trend, month-over-month deltas, score history) is intentionally NOT shown.
 * recharts is mocked in this repo, so charts are hand-rolled inline SVG/CSS.
 */
import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import apiClient, { vulnManagementApi } from '@/lib/api';
import {
  ShieldCheck, Users, Download, ChevronRight, Flame, Bug, Globe, Activity,
  ShieldAlert, Server, Clock, CheckCircle2,
} from 'lucide-react';

/* ---------------- palette (styles/tokens.css) ---------------- */
const AC = '#005B96';
const SEC = '#334155';
const TRACK = '#F1F3F9';
// c = vivid (bars/dots), bg = tint (pill background), text = AA-safe pill text (>=4.5:1 on bg)
const SEV: Record<string, { c: string; bg: string; text: string }> = {
  Critical: { c: '#B91C1C', bg: '#FDECEC', text: '#B91C1C' },
  High: { c: '#EA580C', bg: '#FFF1E7', text: '#9A3412' },
  Medium: { c: '#D97706', bg: '#FEF4E4', text: '#B45309' },
  Low: { c: '#2563EB', bg: '#E9F0FE', text: '#2563EB' },
  Info: { c: '#64748B', bg: '#F1F5F9', text: '#475569' },
};
const SEV_ORDER = ['Critical', 'High', 'Medium', 'Low', 'Info'] as const;

/* ---------------- data helpers ---------------- */
const CANON: Record<string, string> = { critical: 'Critical', high: 'High', medium: 'Medium', low: 'Low', info: 'Info', informational: 'Info' };
const normSev = (s?: string) => CANON[(s || '').toLowerCase()] || 'Info';
const hasExploit = (v: any) => !!(v.kev_flag || v.is_kev || v.exploit_available || (v.public_exploit_count ?? 0) > 0 || (typeof v.epss_score === 'number' && v.epss_score >= 0.1));
const isKev = (v: any) => !!(v.kev_flag || v.is_kev);
const ownerOf = (v: any) => ((v.assignee_name || v.owner || '').trim()) || 'Unassigned';
const isClosed = (v: any) => ['remediated', 'verified', 'closed', 'resolved'].includes((v.status || '').toLowerCase().replace(/\s+/g, '_'));
const seenDate = (v: any) => v.first_seen || v.first_detected || v.created_at || v.detected_at || v.last_seen || null;
const daysSince = (d?: string | null) => (d ? Math.max(0, Math.floor((Date.now() - new Date(d).getTime()) / 86400000)) : null);
const nfmt = (n: number) => n.toLocaleString();
const pct = (num: number, den: number) => (den > 0 ? Math.round((num / den) * 100) : 0);

/* ---------------- shared bits ---------------- */
const cardCls = 'rounded-2xl border border-[#E2E5EC] bg-white px-5 py-[18px] shadow-[0_1px_2px_rgba(16,24,40,.04)]';

function CardTitle({ title, desc }: { title: string; desc?: string }) {
  return (
    <>
      <h3 className="m-0 text-[13.5px] font-semibold text-slate-900">{title}</h3>
      {desc && <p className="mb-3 mt-0.5 text-[11.5px] text-slate-500">{desc}</p>}
    </>
  );
}

function Ring({ pct: p, size, stroke, color, children }: { pct: number; size: number; stroke: number; color: string; children: React.ReactNode }) {
  const r = size / 2 - stroke / 2 - 2, C = 2 * Math.PI * r, c = size / 2;
  const clamped = Math.max(0, Math.min(100, p));
  return (
    <div className="relative" style={{ width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: 'rotate(-90deg)' }}>
        <circle cx={c} cy={c} r={r} fill="none" stroke="#EFF5FA" strokeWidth={stroke} />
        <circle cx={c} cy={c} r={r} fill="none" stroke={color} strokeWidth={stroke} strokeLinecap="round" strokeDasharray={`${(clamped / 100) * C} ${C}`} />
      </svg>
      <div className="absolute inset-0 flex flex-col items-center justify-center">{children}</div>
    </div>
  );
}

function Donut({ rows, total, size }: { rows: { label: string; n: number }[]; total: number; size: number }) {
  let acc = 0;
  const grad = total > 0
    ? `conic-gradient(${rows.filter((s) => s.n > 0).map((s) => { const from = acc; acc += (s.n / total) * 360; return `${SEV[s.label].c} ${from.toFixed(1)}deg ${acc.toFixed(1)}deg`; }).join(',')})`
    : TRACK;
  return (
    <div className="relative shrink-0" style={{ width: size, height: size }}>
      <div className="rounded-full" style={{ width: size, height: size, background: grad }} />
      <div className="absolute flex flex-col items-center justify-center rounded-full bg-white" style={{ inset: size * 0.14 }}>
        <b className="text-[20px] text-slate-900">{nfmt(total)}</b>
        <span className="text-[10px] text-slate-500">open</span>
      </div>
    </div>
  );
}

function HBars({ rows }: { rows: { label: string; n: number; color: string; sub?: string }[] }) {
  const max = Math.max(1, ...rows.map((r) => r.n));
  return (
    <div className="flex flex-col gap-2">
      {rows.map((r) => (
        <div key={r.label} className="flex items-center gap-2.5 text-[12.5px]">
          <span className="w-32 shrink-0 truncate text-slate-700" title={r.label}>{r.label}</span>
          <span className="block h-2.5 flex-1 overflow-hidden rounded-md" style={{ background: TRACK }}>
            <i className="block h-full rounded-md" style={{ width: `${(r.n / max) * 100}%`, background: r.color }} />
          </span>
          <b className="w-8 text-right tabular-nums text-slate-900">{nfmt(r.n)}</b>
        </div>
      ))}
    </div>
  );
}

/* weekly new-findings bars — dynamic max, no hardcoded divisor */
function WeeklyBars({ weeks }: { weeks: { label: string; n: number }[] }) {
  const max = Math.max(1, ...weeks.map((w) => w.n));
  return (
    <div className="flex min-h-[110px] flex-1 items-end gap-1.5">
      {weeks.map((w, i) => (
        <div key={i} className="flex h-full min-w-0 flex-1 flex-col justify-end">
          <div className="mb-[3px] text-center text-[9px] tabular-nums text-slate-400">{w.n || ''}</div>
          <div className="flex min-h-[80px] items-end">
            <i className="block w-full rounded-t-[3px]" style={{ height: `${(w.n / max) * 100}%`, minHeight: w.n > 0 ? 3 : 0, background: i === weeks.length - 1 ? AC : '#B3CDE0' }} />
          </div>
          <div className="mt-1 h-3 truncate text-center text-[9px] text-slate-400">{w.label}</div>
        </div>
      ))}
    </div>
  );
}

function healthColor(h: string) { return h === 'At risk' ? '#B91C1C' : h === 'Watch' ? '#D97706' : '#047857'; }

/* ================= page ================= */
export default function PerformanceOverview() {
  const [view, setView] = useState<'admin' | 'team'>('admin');
  const isAdmin = view === 'admin';

  const { data: vulns = [], isLoading, dataUpdatedAt } = useQuery({
    queryKey: ['perf-vulns'],
    queryFn: async () => {
      const r = await vulnManagementApi.vulnerabilities.getAll({ include_closed: true, limit: 1000 });
      return (Array.isArray(r.data) ? r.data : (r.data as any)?.items || []) as any[];
    },
  });
  const { data: assets = [] } = useQuery({
    queryKey: ['perf-assets'],
    queryFn: async () => {
      const r = await apiClient.get('/assets', { params: { limit: 1000 } });
      return (Array.isArray(r.data) ? r.data : (r.data as any)?.items || []) as any[];
    },
  });
  const { data: domainAgg } = useQuery({
    queryKey: ['perf-domains'],
    queryFn: async () => (await vulnManagementApi.vulnerabilities.getDomains({ include_closed: false })).data as {
      domains: Array<{ family: string; total: number; worst_severity: string }>;
    },
  });

  const m = useMemo(() => {
    const open = vulns.filter((v) => !isClosed(v));
    const sev: Record<string, number> = { Critical: 0, High: 0, Medium: 0, Low: 0, Info: 0 };
    open.forEach((v) => { sev[normSev(v.severity)]++; });
    const kev = open.filter(isKev).length;
    const exploitable = open.filter(hasExploit).length;
    const withCve = open.filter((v) => v.cve_id).length;
    const internetAssets = assets.filter((a) => a.internet_facing || a.is_internet_facing || a.external).length;
    const cvss = open.map((v) => Number(v.cvss_score)).filter((n) => !isNaN(n) && n > 0);
    const avgCvss = cvss.length ? cvss.reduce((a, b) => a + b, 0) / cvss.length : 0;
    const agingOld = open.filter((v) => (daysSince(seenDate(v)) ?? 0) > 30).length;
    const resolved = vulns.length - open.length;

    // weekly new-findings (last 12 weeks) from first_seen
    const wk = 7 * 86400000, now = Date.now();
    const weeks = Array.from({ length: 12 }, (_, i) => {
      const end = now - (11 - i) * wk;
      const d = new Date(end);
      return { label: `${d.getMonth() + 1}/${d.getDate()}`, start: end - wk, end, n: 0 };
    });
    vulns.forEach((v) => { const s = seenDate(v); if (!s) return; const t = new Date(s).getTime(); const b = weeks.find((w) => t > w.start && t <= w.end); if (b) b.n++; });

    // exposure funnel
    const funnel = [
      { label: 'All open findings', n: open.length, color: '#94A3B8' },
      { label: 'With a CVE', n: withCve, color: '#3279A3' },
      { label: 'Exploitable', n: exploitable, color: '#EA580C' },
      { label: 'Actively exploited', n: kev, color: '#B91C1C' },
    ];

    // EPSS buckets
    const epss = [
      { label: '≥ 50%', n: open.filter((v) => (v.epss_score ?? 0) >= 0.5).length, color: SEV.Critical.c },
      { label: '10–50%', n: open.filter((v) => (v.epss_score ?? 0) >= 0.1 && (v.epss_score ?? 0) < 0.5).length, color: SEV.High.c },
      { label: '1–10%', n: open.filter((v) => (v.epss_score ?? 0) >= 0.01 && (v.epss_score ?? 0) < 0.1).length, color: SEV.Medium.c },
      { label: '< 1%', n: open.filter((v) => (v.epss_score ?? 0) < 0.01).length, color: SEV.Low.c },
    ];

    // needs attention — real, ranked by KEV then EPSS then CVSS, no owners
    const attention = [...open]
      .sort((a, b) => (Number(isKev(b)) - Number(isKev(a))) || ((b.epss_score ?? 0) - (a.epss_score ?? 0)) || (Number(b.cvss_score || 0) - Number(a.cvss_score || 0)))
      .slice(0, 6)
      .map((v) => {
        const s = normSev(v.severity);
        const bits = [s, v.cvss_score ? `CVSS ${Number(v.cvss_score).toFixed(1)}` : null,
          typeof v.epss_score === 'number' ? `EPSS ${Math.round(v.epss_score * 100)}%` : null,
          isKev(v) ? 'CISA KEV' : null].filter(Boolean);
        return { id: v.id, dot: SEV[s].c, title: [v.cve_id, v.title].filter(Boolean).join(' — ') || 'Finding', sub: bits.join(' · ') };
      });

    // by domain (server aggregate, worst-severity coloured)
    const byDomain = (domainAgg?.domains?.length
      ? domainAgg.domains.slice(0, 7).map((d) => ({ label: d.family, n: d.total, color: SEV[normSev(d.worst_severity)].c }))
      : Object.entries(open.reduce((acc: Record<string, number>, v) => { const d = v.family || v.domain || v.category || 'General'; acc[d] = (acc[d] || 0) + 1; return acc; }, {}))
          .map(([label, n]) => ({ label, n: n as number, color: AC })).sort((a, b) => b.n - a.n).slice(0, 7));

    // ownership (real assignee)
    const owners: Record<string, { open: number; critical: number; oldest: number }> = {};
    open.forEach((v) => { const o = ownerOf(v); owners[o] = owners[o] || { open: 0, critical: 0, oldest: 0 }; owners[o].open++; if (normSev(v.severity) === 'Critical') owners[o].critical++; const d = daysSince(seenDate(v)) ?? 0; if (d > owners[o].oldest) owners[o].oldest = d; });
    const team = Object.entries(owners).map(([name, s]) => ({ name, ...s })).sort((a, b) => b.open - a.open);
    const unassigned = owners['Unassigned']?.open || 0;
    const oldest = Math.max(0, ...team.map((t) => t.oldest));

    // derived exposure index (0-100, higher=better). SLA weight dropped (no remediation data).
    const oc = open.length || 1;
    const drivers = [
      { label: 'Publicly exploitable', n: exploitable, ratio: exploitable / oc, w: 0.4, color: SEV.High.c },
      { label: 'Actively exploited (KEV)', n: kev, ratio: kev / oc, w: 0.3, color: SEV.Critical.c },
      { label: 'Aging > 30 days', n: agingOld, ratio: agingOld / oc, w: 0.3, color: SEV.Medium.c },
    ];
    const penalty = drivers.reduce((a, d) => a + d.w * d.ratio, 0) * 100;
    const index = Math.max(0, Math.min(100, Math.round(100 - penalty)));
    const grade = index >= 85 ? 'A' : index >= 70 ? 'B' : index >= 55 ? 'C' : index >= 40 ? 'D' : 'E';

    return { open: open.length, sev, kev, exploitable, withCve, internetAssets, avgCvss, agingOld, resolved,
      weeks: weeks.map(({ label, n }) => ({ label, n })), funnel, epss, attention, byDomain, team, unassigned, oldest, index, grade, drivers, total: vulns.length };
  }, [vulns, assets, domainAgg]);

  const exportCsv = () => {
    const head = ['ID', 'Title', 'CVE', 'Severity', 'CVSS', 'EPSS', 'KEV', 'Status', 'Owner'];
    const body = vulns.map((v) => [v.id, v.title, v.cve_id, v.severity, v.cvss_score, v.epss_score, isKev(v) ? 'yes' : '', v.status, ownerOf(v)]);
    const csv = [head, ...body].map((r) => r.map((x) => `"${String(x ?? '').replace(/"/g, '""')}"`).join(',')).join('\n');
    const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
    const a = document.createElement('a'); a.href = url; a.download = 'ava-findings.csv'; a.click(); URL.revokeObjectURL(url);
  };

  const gradeColor = m.index >= 70 ? '#047857' : m.index >= 40 ? '#B45309' : '#B91C1C';

  return (
    <div className="mx-auto flex max-w-[1320px] flex-col gap-4 py-1 text-slate-900" style={{ fontFamily: "var(--font-poppins), 'Poppins', system-ui, sans-serif" }}>
      {/* head row */}
      <div className="mb-1 flex flex-wrap items-start justify-between gap-4">
        <div>
          <h1 className="m-0 text-[20px] font-semibold tracking-[-.02em]">Performance</h1>
          <div className="mt-0.5 text-[12.5px] text-slate-500">
            {isAdmin
              ? `Organisation-wide cyber posture · ${nfmt(m.open)} open findings · ${nfmt(assets.length)} assets`
              : `Ownership & workload · ${m.team.length} owner${m.team.length === 1 ? '' : 's'} · ${nfmt(m.unassigned)} unassigned`}
          </div>
        </div>
        <div className="flex flex-wrap items-center gap-2.5">
          <div className="inline-flex gap-0.5 rounded-[11px] bg-[#EAEBF3] p-[3px]">
            {(['admin', 'team'] as const).map((k) => (
              <button
                key={k}
                onClick={() => setView(k)}
                aria-pressed={view === k}
                className="inline-flex h-[34px] items-center gap-1.5 rounded-[9px] border-0 px-4 text-[12.5px] font-semibold"
                style={{ background: view === k ? '#fff' : 'transparent', color: view === k ? AC : '#6B7280', boxShadow: view === k ? '0 1px 2px rgba(16,24,40,.08)' : 'none' }}
              >
                {k === 'admin' ? <ShieldCheck size={15} /> : <Users size={15} />}
                {k === 'admin' ? 'Administrator' : 'Team'}
              </button>
            ))}
          </div>
          <button onClick={exportCsv} className="inline-flex h-9 items-center gap-1.5 rounded-[9px] border border-[#E2E5EC] bg-white px-3.5 text-[12.5px] font-semibold text-slate-700 shadow-[0_1px_2px_rgba(16,24,40,.04)] hover:bg-[#F6F7FB]">
            <Download size={15} color={AC} />Export findings (CSV)
          </button>
        </div>
      </div>

      {isLoading ? (
        <div className="grid h-80 place-items-center text-slate-500">Loading live performance data…</div>
      ) : isAdmin ? (
        <div className="flex flex-col gap-4">
          {/* hero — derived exposure index */}
          <div className={`${cardCls} flex flex-wrap items-center gap-8 !px-5 !py-4`}>
            <div className="flex flex-col items-center gap-2">
              <div className="text-[10.5px] font-semibold uppercase tracking-[.06em] text-slate-500">Exposure index</div>
              <Ring pct={m.index} size={128} stroke={11} color={gradeColor}>
                <span className="text-[32px] font-bold leading-none">{m.index}</span>
                <span className="mt-0.5 text-[10.5px] text-slate-400">out of 100</span>
              </Ring>
              <span className="rounded-full px-2.5 py-0.5 text-[11px] font-semibold" style={{ background: 'rgba(0,91,150,.10)', color: AC }}>Grade {m.grade} · derived</span>
            </div>
            <div className="flex min-w-[300px] flex-1 flex-col gap-2.5">
              <div className="text-[10.5px] font-semibold uppercase tracking-[.06em] text-slate-500">What drives it · share of open findings</div>
              {m.drivers.map((d) => (
                <div key={d.label} className="flex items-center gap-4">
                  <span className="w-[190px] shrink-0 text-[12.5px] text-slate-700">
                    {d.label} <span className="text-[10px] text-slate-400">· {Math.round(d.w * 100)}%</span>
                  </span>
                  <span className="block h-2 flex-1 overflow-hidden rounded-[5px]" style={{ background: TRACK }}>
                    <i className="block h-full rounded-[5px]" style={{ width: `${Math.round(d.ratio * 100)}%`, background: d.color }} />
                  </span>
                  <b className="w-16 text-right text-[12px] tabular-nums text-slate-700">{nfmt(d.n)} <span className="text-slate-400">({Math.round(d.ratio * 100)}%)</span></b>
                </div>
              ))}
            </div>
            <div className="flex min-w-[230px] flex-1 basis-[230px] flex-col justify-center gap-1.5">
              <div className="text-[10.5px] font-semibold uppercase tracking-[.06em] text-slate-500">How to read this</div>
              <p className="m-0 text-[11.5px] leading-relaxed text-slate-500">
                A <b className="text-slate-700">derived</b> index (100 = clean) computed live from exploitability, active exploitation and aging of your {nfmt(m.open)} open findings. Remediation-SLA weighting is excluded until findings start getting resolved.
              </p>
            </div>
          </div>

          {/* KPI strip */}
          <div className="grid gap-4" style={{ gridTemplateColumns: 'repeat(auto-fit,minmax(150px,1fr))' }}>
            {[
              { label: 'Open findings', value: nfmt(m.open), sub: `${nfmt(m.resolved)} resolved all-time`, icon: <Bug size={13} />, color: AC },
              { label: 'Critical open', value: nfmt(m.sev.Critical), sub: `${nfmt(m.sev.High)} high`, icon: <Flame size={13} />, color: SEV.Critical.c },
              { label: 'Actively exploited', value: nfmt(m.kev), sub: 'on the CISA KEV list', icon: <Flame size={13} />, color: SEV.Critical.c },
              { label: 'Publicly exploitable', value: nfmt(m.exploitable), sub: 'KEV or EPSS ≥ 10%', icon: <ShieldAlert size={13} />, color: SEV.High.c },
              { label: 'Internet-facing', value: nfmt(m.internetAssets), sub: `of ${nfmt(assets.length)} assets`, icon: <Globe size={13} />, color: AC },
              { label: 'Avg CVSS', value: m.avgCvss.toFixed(1), sub: 'open findings', icon: <Activity size={13} />, color: '#3279A3' },
            ].map((k) => (
              <div key={k.label} className="relative min-w-0 overflow-hidden rounded-xl border border-[#E2E5EC] bg-white px-3.5 py-[11px] shadow-[0_1px_2px_rgba(16,24,40,.04)]">
                <span className="absolute bottom-3 left-0 top-3 w-[3px] rounded-r" style={{ background: k.color }} />
                <div className="flex items-center gap-1.5 text-[10.5px] font-semibold uppercase tracking-[.05em] text-slate-500"><span style={{ color: k.color }}>{k.icon}</span>{k.label}</div>
                <div className="mt-1 text-[22px] font-bold tabular-nums text-slate-900">{k.value}</div>
                <div className="mt-0.5 text-[11.5px] text-slate-400">{k.sub}</div>
              </div>
            ))}
          </div>

          {/* EPSS · trend · attention */}
          <div className="flex flex-wrap gap-4">
            <div className={`${cardCls} min-w-0 flex-1 basis-[340px]`}>
              <CardTitle title="Exploit probability (EPSS)" desc="Open findings by first-party exploit-likelihood score" />
              <HBars rows={m.epss.map((e) => ({ label: e.label, n: e.n, color: e.color }))} />
            </div>

            <div className={`${cardCls} flex min-w-0 flex-1 basis-[340px] flex-col`}>
              <CardTitle title="New findings — weekly" desc="First-seen date, last 12 weeks (resolution history not yet available)" />
              <WeeklyBars weeks={m.weeks} />
            </div>

            <div className={`${cardCls} flex min-w-0 flex-1 basis-80 flex-col`}>
              <CardTitle title="Needs attention" desc="Ranked by active exploitation, EPSS and CVSS" />
              {m.attention.length === 0 ? (
                <div className="flex flex-1 items-center justify-center py-6 text-[12px] text-slate-400">No open findings.</div>
              ) : (
                <div className="flex flex-1 flex-col justify-around">
                  {m.attention.map((a) => (
                    <Link key={a.id} href={`/vulnerabilities/${a.id}`} className="flex items-start gap-2.5 rounded-[10px] px-2 py-[7px] text-inherit hover:bg-[#F6F7FB]">
                      <i className="mt-1.5 block h-2 w-2 shrink-0 rounded-full" style={{ background: a.dot }} />
                      <span className="min-w-0 flex-1">
                        <span className="block text-[12.5px] font-semibold text-slate-900">{a.title}</span>
                        <span className="mt-px block text-[11.5px] text-slate-500">{a.sub}</span>
                      </span>
                      <ChevronRight size={14} className="mt-1 shrink-0 text-slate-400" />
                    </Link>
                  ))}
                </div>
              )}
              {m.unassigned > 0 && <div className="mt-2 rounded-lg bg-[#F1F5F9] px-3 py-1.5 text-[11.5px] text-slate-600">{nfmt(m.unassigned)} open findings have no owner — route them to a queue.</div>}
            </div>
          </div>

          {/* funnel + severity mix */}
          <div className="flex flex-wrap gap-4">
            <div className={`${cardCls} min-w-0 flex-1 basis-[380px]`}>
              <CardTitle title="Exposure funnel" desc={`How ${nfmt(m.open)} open findings narrow to what actually matters`} />
              <div className="flex flex-col gap-2">
                {m.funnel.map((f, i) => (
                  <div key={f.label} className="flex items-center gap-2.5">
                    <span className="w-32 shrink-0 text-[12px] text-slate-700">{f.label}</span>
                    <span className="flex flex-1 items-center gap-2">
                      <span className="flex h-[26px] items-center rounded-[7px] pl-2.5 text-[12px] font-semibold tabular-nums text-white" style={{ width: `${Math.max(9, pct(f.n, m.funnel[0].n))}%`, background: f.color }}>{nfmt(f.n)}</span>
                      {i > 0 && <span className="text-[10.5px] text-slate-400">{pct(f.n, m.funnel[i - 1].n)}%</span>}
                    </span>
                  </div>
                ))}
              </div>
              {m.kev > 0 && <div className="mt-3 text-[11.5px] text-slate-500">Only <b className="text-[#B91C1C]">{nfmt(m.kev)} findings</b> are on the CISA KEV list — fixing those first removes the highest-probability attack paths.</div>}
            </div>

            <div className={`${cardCls} min-w-0 flex-1 basis-[380px]`}>
              <CardTitle title="Severity mix" desc={`${nfmt(m.open)} open findings by severity`} />
              <div className="flex flex-wrap items-center gap-5">
                <Donut rows={SEV_ORDER.map((l) => ({ label: l, n: m.sev[l] }))} total={m.open} size={132} />
                <div className="flex min-w-[150px] max-w-[280px] flex-1 flex-col gap-1.5 text-[12px]">
                  {SEV_ORDER.map((l) => (
                    <span key={l} className="flex items-center gap-2">
                      <i className="inline-block h-2 w-2 rounded-[3px]" style={{ background: SEV[l].c }} />
                      <span className="text-slate-700">{l}</span>
                      <b className="ml-auto tabular-nums text-slate-900">{nfmt(m.sev[l])}</b>
                      <span className="w-9 text-right text-[11px] text-slate-400">{pct(m.sev[l], m.open)}%</span>
                    </span>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* by domain */}
          <div className={cardCls}>
            <CardTitle title="Where risk concentrates — by domain" desc="Scanner plugin-family, worst-severity coloured" />
            {m.byDomain.length ? <HBars rows={m.byDomain} /> : <div className="py-4 text-[12px] text-slate-400">No domain data.</div>}
          </div>
        </div>
      ) : (
        /* ===== TEAM / OWNERSHIP ===== */
        <div className="flex flex-col gap-4">
          <div className="grid gap-4" style={{ gridTemplateColumns: 'repeat(auto-fit,minmax(150px,1fr))' }}>
            {[
              { label: 'Open (team)', value: nfmt(m.open), sub: `${m.team.length} owner${m.team.length === 1 ? '' : 's'}`, color: AC, icon: <Bug size={13} /> },
              { label: 'Unassigned', value: nfmt(m.unassigned), sub: 'need an owner', color: SEV.High.c, icon: <Users size={13} /> },
              { label: 'Resolved', value: nfmt(m.resolved), sub: 'all-time', color: '#047857', icon: <CheckCircle2 size={13} /> },
              { label: 'Critical open', value: nfmt(m.sev.Critical), sub: 'need triage', color: SEV.Critical.c, icon: <Flame size={13} /> },
              { label: 'Oldest open', value: `${m.oldest}d`, sub: 'since first seen', color: SEV.Medium.c, icon: <Clock size={13} /> },
            ].map((k) => (
              <div key={k.label} className="relative min-w-0 overflow-hidden rounded-xl border border-[#E2E5EC] bg-white px-3.5 py-[11px] shadow-[0_1px_2px_rgba(16,24,40,.04)]">
                <span className="absolute bottom-3 left-0 top-3 w-[3px] rounded-r" style={{ background: k.color }} />
                <div className="flex items-center gap-1.5 text-[10.5px] font-semibold uppercase tracking-[.05em] text-slate-500"><span style={{ color: k.color }}>{k.icon}</span>{k.label}</div>
                <div className="mt-1 text-[22px] font-bold tabular-nums text-slate-900">{k.value}</div>
                <div className="mt-0.5 text-[11.5px] text-slate-400">{k.sub}</div>
              </div>
            ))}
          </div>

          <div className="flex flex-wrap gap-4">
            <div className={`${cardCls} min-w-0 flex-1 basis-[380px]`}>
              <CardTitle title="Workload by owner" desc="Open findings per owner" />
              <HBars rows={m.team.slice(0, 8).map((t, i) => ({ label: t.name, n: t.open, color: t.name === 'Unassigned' ? '#94A3B8' : i === 0 ? AC : '#3279A3' }))} />
            </div>
            <div className={`${cardCls} flex min-w-0 flex-1 basis-[380px] flex-col`}>
              <CardTitle title="New findings — weekly" desc="Findings landing on the team, last 12 weeks" />
              <WeeklyBars weeks={m.weeks} />
            </div>
          </div>

          <div className={cardCls}>
            <CardTitle title="Ownership" desc="Per-owner queue health — open load, criticals, and the oldest untouched finding" />
            <div className="overflow-x-auto">
              <table className="w-full min-w-[520px] border-collapse">
                <thead>
                  <tr>
                    {['Owner', 'Open', 'Critical', 'Oldest open', 'Health'].map((h, i) => (
                      <th key={h} className={`border-b border-[#E2E5EC] px-2.5 py-[7px] text-[10.5px] font-semibold uppercase tracking-[.05em] text-slate-500 ${i >= 1 && i <= 3 ? 'text-right' : 'text-left'}`}>{h}</th>
                    ))}
                  </tr>
                </thead>
                <tbody>
                  {m.team.map((t) => {
                    const health = t.critical > 0 || t.oldest > 30 ? 'At risk' : t.oldest > 14 ? 'Watch' : 'Healthy';
                    return (
                      <tr key={t.name}>
                        <td className="border-b border-[#F6F7FB] px-2.5 py-[7px] text-[12.5px] font-semibold text-slate-900">{t.name}</td>
                        <td className="border-b border-[#F6F7FB] px-2.5 py-[7px] text-right text-[12.5px] font-semibold tabular-nums text-slate-900">{nfmt(t.open)}</td>
                        <td className="border-b border-[#F6F7FB] px-2.5 py-[7px] text-right text-[12.5px] font-semibold tabular-nums" style={{ color: t.critical > 0 ? '#B91C1C' : SEC }}>{t.critical || '—'}</td>
                        <td className="border-b border-[#F6F7FB] px-2.5 py-[7px] text-right text-[12.5px] tabular-nums text-slate-700">{t.oldest ? `${t.oldest}d` : '—'}</td>
                        <td className="border-b border-[#F6F7FB] px-2.5 py-[7px] text-[12px]">
                          <span className="inline-flex items-center gap-1.5 font-semibold" style={{ color: healthColor(health) }}>
                            <i className="inline-block h-[7px] w-[7px] rounded-full" style={{ background: healthColor(health) }} />{health}
                          </span>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      <div className="pb-1 text-[11px] text-slate-400">
        Computed live from your vulnerability register &amp; asset inventory{dataUpdatedAt ? ` · updated ${new Date(dataUpdatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}` : ''} · Drill in from <Link href="/vulnerabilities" className="text-[#005B96]">Vulnerabilities →</Link>
      </div>
    </div>
  );
}
