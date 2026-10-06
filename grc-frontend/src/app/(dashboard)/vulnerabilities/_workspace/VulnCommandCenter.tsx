'use client';

/**
 * VulnCommandCenter — the Vulnerabilities "Overview" pane: a remediation /
 * act-now OPERATIONS console, not another chart gallery. It answers "what do I
 * fix first, who owns it, and is it late?" from the register the workspace
 * already loaded + the server dashboard aggregates.
 *
 * Distinct by design from the Performance dashboard (risk gauge + lenses) and
 * the Inventory Overview (External/Internal split + asset-class matrix): this is
 * a worklist surface — a hero act-now queue, an exploitability funnel, an SLA
 * band, ownership/blast-radius lists, and an enrichment-honesty strip.
 *
 * Ava product tokens only (#005B96 accent, light theme, soft shadows), matching
 * VulnsWorkspace / FindingDetail. Everything is derived from real fields; where a
 * signal is absent locally it reads as an honest empty state, never "zero risk".
 */

import { useMemo } from 'react';
import { ShieldAlert, Flame, Globe, Clock3, Users2, Boxes, ArrowRight } from 'lucide-react';
import { shortenVulnTitle, type Vulnerability } from './lib';

// ── Ava palette (literal, matching the workspace) ──
const AC = '#005B96', ACS = '#014A81', ACSOFT = '#EFF5FA';
const INK = '#0F1F2B', SEC = '#3A4653', MUTED = '#8A95A1', FAINT = '#AEB8C2', BORDER = '#E8ECEE', BORDER2 = '#F0F3F5';
const MONO = 'ui-monospace,Consolas,monospace';
const TNUM: React.CSSProperties = { fontVariantNumeric: 'tabular-nums' };
const SEV = {
  critical: { c: '#C2453F', bg: '#FBEAEA', label: 'Critical' },
  high: { c: '#C0682F', bg: '#FCEEE2', label: 'High' },
  medium: { c: '#9A6410', bg: '#FBF2DF', label: 'Medium' },
  low: { c: '#1F7A54', bg: '#E7F5EE', label: 'Low' },
  info: { c: '#6B7787', bg: '#EEF1F3', label: 'Info' },
} as const;
type SevKey = keyof typeof SEV;

const RESOLVED = new Set(['resolved', 'remediated', 'verified', 'closed', 'accepted', 'false_positive', 'auto_closed_decommissioned', 'auto_closed_fixed']);
const normSev = (s?: string): SevKey => { const k = (s || '').toLowerCase(); return (k in SEV ? k : 'info') as SevKey; };
const ctx = (v: Vulnerability) => Math.round((v.composite_priority ?? 0) * 10);
const band = (n: number) => (n >= 55 ? { c: '#C2453F', label: 'Urgent' } : n >= 25 ? { c: '#9A6410', label: 'Moderate' } : { c: '#1F7A54', label: 'Low' });
const hasExploit = (v: Vulnerability) => (v.public_exploit_count ?? 0) > 0 || (v.exploitdb_count ?? 0) > 0 || !!v.kev_flag;
const isExposed = (v: Vulnerability) => !!v.internet_facing || !!v.internet_exposed;
const dueDays = (v: Vulnerability) => (v.due_date ? Math.ceil((new Date(v.due_date).getTime() - Date.now()) / 864e5) : null);
const isOverdue = (v: Vulnerability) => { const d = dueDays(v); return d != null && d < 0; };
const ageDays = (v: Vulnerability) => { const b = v.discovered_at || v.created_at; return b ? Math.floor((Date.now() - new Date(b).getTime()) / 864e5) : null; };
const groupKey = (v: Vulnerability) => (v.assigned_departments?.[0]) || v.assignee_name || 'Unassigned';

interface CmdDashboard { mttr_days?: number; sla_compliance?: Record<string, { compliance_rate: number }>; }

const card: React.CSSProperties = { background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 14, boxShadow: '0 1px 2px rgba(16,24,40,.04)' };
const capCss: React.CSSProperties = { fontSize: 10, fontWeight: 700, letterSpacing: '.07em', textTransform: 'uppercase', color: FAINT };

function SevDot({ s }: { s?: string }) { const m = SEV[normSev(s)]; return <span style={{ width: 8, height: 8, borderRadius: 2, background: m.c, flex: 'none' }} title={m.label} />; }
function Chip({ label, c, bg }: { label: string; c: string; bg: string }) {
  return <span style={{ fontSize: 9.5, fontWeight: 700, letterSpacing: '.02em', padding: '1px 6px', borderRadius: 999, color: c, background: bg, whiteSpace: 'nowrap' }}>{label}</span>;
}

export default function VulnCommandCenter({ vulns, dashboard, onView }: { vulns: Vulnerability[]; dashboard?: CmdDashboard; onView: (v: Vulnerability) => void }) {
  const m = useMemo(() => {
    const open = (vulns || []).filter((v) => !RESOLVED.has((v.status || '').toLowerCase()));
    const totalOpen = open.length;

    const reasons = (v: Vulnerability) => {
      const r: { label: string; c: string; bg: string }[] = [];
      if (v.kev_flag) r.push({ label: 'EXPLOITED', c: '#C2453F', bg: '#FBEAEA' });
      else if (hasExploit(v)) r.push({ label: 'EXPLOIT', c: '#C0682F', bg: '#FCEEE2' });
      if (isExposed(v)) r.push({ label: 'EXPOSED', c: '#6A54C9', bg: '#EEEBFA' });
      if (isOverdue(v)) r.push({ label: 'OVERDUE', c: '#B23A3A', bg: '#FBEAEA' });
      return r;
    };
    const actNow = open
      .filter((v) => v.kev_flag || hasExploit(v) || isExposed(v) || isOverdue(v))
      .sort((a, b) => ctx(b) - ctx(a));

    // Funnel — raw severity ≠ real priority.
    const withCve = open.filter((v) => !!v.cve_id).length;
    const exploitable = open.filter(hasExploit).length;
    const exposed = open.filter(isExposed).length;
    const overdue = open.filter(isOverdue).length;
    const critHigh = open.filter((v) => { const s = normSev(v.severity); return s === 'critical' || s === 'high'; }).length;

    // SLA band.
    const overdueList = open.filter(isOverdue);
    const overdueBySev = (['critical', 'high', 'medium', 'low', 'info'] as SevKey[]).map((k) => ({ k, n: overdueList.filter((v) => normSev(v.severity) === k).length })).filter((x) => x.n);
    const dueSoon = open.filter((v) => { const d = dueDays(v); return d != null && d >= 0 && d <= 7; }).length;
    const agingDefs: [string, (d: number) => boolean][] = [['≤ 30d', (d) => d <= 30], ['31–90d', (d) => d > 30 && d <= 90], ['91–180d', (d) => d > 90 && d <= 180], ['> 180d', (d) => d > 180]];
    const aging = agingDefs.map(([label, f]) => ({ label, n: open.filter((v) => { const d = ageDays(v); return d != null && f(d); }).length }));

    // Ownership backlog + blast radius.
    const backlogMap = new Map<string, { count: number; pri: number }>();
    for (const v of open) { const k = groupKey(v); const e = backlogMap.get(k) || { count: 0, pri: 0 }; e.count++; e.pri += ctx(v); backlogMap.set(k, e); }
    const backlog = Array.from(backlogMap.entries()).map(([name, e]) => ({ name, ...e })).sort((a, b) => b.count - a.count).slice(0, 6);

    const assetMap = new Map<string, { count: number; pri: number }>();
    for (const v of open) for (const a of (v.linked_assets || [])) { const e = assetMap.get(a) || { count: 0, pri: 0 }; e.count++; e.pri += ctx(v); assetMap.set(a, e); }
    const topAssets = Array.from(assetMap.entries()).map(([name, e]) => ({ name, ...e })).sort((a, b) => b.pri - a.pri).slice(0, 6);

    // Enrichment honesty.
    const enrichedOf = (v: Vulnerability) => v.epss_score != null || v.kev_flag != null || (v.public_exploit_count != null);
    const cveRows = open.filter((v) => !!v.cve_id);
    const enrichedCve = cveRows.filter(enrichedOf).length;
    const noCve = totalOpen - cveRows.length;
    const enrichPct = cveRows.length ? Math.round((enrichedCve / cveRows.length) * 100) : 0;

    const slaRate = dashboard?.sla_compliance
      ? Math.round(Object.values(dashboard.sla_compliance).reduce((s, x) => s + (x.compliance_rate || 0), 0) / Math.max(1, Object.values(dashboard.sla_compliance).length))
      : null;

    return { open, totalOpen, actNow, reasons, withCve, exploitable, exposed, overdue, critHigh, overdueBySev, dueSoon, aging, backlog, topAssets, cveRows: cveRows.length, enrichedCve, noCve, enrichPct, slaRate, mttr: dashboard?.mttr_days ?? null };
  }, [vulns, dashboard]);

  const pct = (n: number) => `${(m.totalOpen ? (n / m.totalOpen) * 100 : 0).toFixed(0)}%`;
  const w = (n: number, max: number) => `${max ? Math.max(n > 0 ? 6 : 0, (n / max) * 100) : 0}%`;
  const backlogMax = Math.max(1, ...m.backlog.map((b) => b.count));
  const assetMax = Math.max(1, ...m.topAssets.map((a) => a.pri));
  const agingMax = Math.max(1, ...m.aging.map((a) => a.n));

  const funnel: { key: string; label: string; n: number; c: string; Icon: typeof Flame }[] = [
    { key: 'open', label: 'Open findings', n: m.totalOpen, c: '#8A95A1', Icon: Boxes },
    { key: 'cve', label: 'Carry a CVE', n: m.withCve, c: '#2E63A8', Icon: ShieldAlert },
    { key: 'exp', label: 'Exploit available / exploited', n: m.exploitable, c: '#C0682F', Icon: Flame },
    { key: 'net', label: 'Internet-exposed', n: m.exposed, c: '#6A54C9', Icon: Globe },
    { key: 'due', label: 'Past due', n: m.overdue, c: '#B23A3A', Icon: Clock3 },
  ];

  const HERON = 12;

  return (
    <div style={{ height: '100%', overflowY: 'auto', overflowX: 'hidden', display: 'flex', flexDirection: 'column', gap: 12, fontSize: 13.5, color: INK, paddingBottom: 6 }}>
      {/* title */}
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap', flexShrink: 0 }}>
        <div>
          <h2 style={{ fontSize: 16, letterSpacing: '-.02em', margin: 0 }}>Remediation command center</h2>
          <div style={{ fontSize: 12, color: MUTED, marginTop: 2 }}>act on what truly matters first — exploited, exposed, or overdue, by real-world priority</div>
        </div>
        <div style={{ display: 'flex', gap: 18, flexWrap: 'wrap' }}>
          <HeadStat label="Need action now" n={m.actNow.length} tone={m.actNow.length > 0 ? '#B23A3A' : INK} />
          <HeadStat label="Open findings" n={m.totalOpen} />
          <HeadStat label="MTTR" text={m.mttr != null ? `${m.mttr}d` : '—'} />
          <HeadStat label="SLA on-time" text={m.slaRate != null ? `${m.slaRate}%` : '—'} tone={m.slaRate != null && m.slaRate < 80 ? '#B23A3A' : INK} />
        </div>
      </div>

      {/* ── HERO: act-now queue ── */}
      <section style={{ ...card, display: 'flex', flexDirection: 'column', minHeight: 0, flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '11px 16px', borderBottom: `1px solid ${BORDER2}`, flexWrap: 'wrap' }}>
          <span style={{ width: 28, height: 28, borderRadius: 8, background: '#FBEAEA', color: '#C2453F', display: 'grid', placeItems: 'center', flex: 'none' }}><Flame size={16} /></span>
          <div style={{ flex: 1, minWidth: 0 }}>
            <b style={{ fontSize: 14 }}>Fix these first</b>
            <div style={{ fontSize: 11.5, color: MUTED }}>findings that are actively exploited, carry a public exploit, face the internet, or are past due</div>
          </div>
          <span style={{ ...capCss }}>{m.actNow.length} in queue</span>
        </div>
        {m.actNow.length === 0 ? (
          <div style={{ padding: '22px 16px', fontSize: 12.5, color: SEC, display: 'flex', alignItems: 'center', gap: 10 }}>
            <span style={{ width: 24, height: 24, borderRadius: '50%', background: '#E7F5EE', color: '#1F7A54', display: 'grid', placeItems: 'center', flex: 'none' }}>✓</span>
            Nothing is actively exploited, internet-exposed, or overdue right now. The full register is one click away on the Register tab.
          </div>
        ) : (
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: 760 }}>
              <thead><tr>{['Priority', 'Finding', 'Sev', 'Asset', 'Owner / Dept', 'Why now', 'SLA'].map((h) => (
                <th key={h} style={{ textAlign: h === 'Priority' || h === 'SLA' ? 'right' : 'left', fontSize: 9.5, letterSpacing: '.05em', textTransform: 'uppercase', color: FAINT, fontWeight: 600, padding: '8px 14px', borderBottom: `1px solid ${BORDER2}`, whiteSpace: 'nowrap' }}>{h}</th>
              ))}</tr></thead>
              <tbody>
                {m.actNow.slice(0, HERON).map((v) => {
                  const sc = ctx(v); const bm = band(sc); const assets = v.linked_assets || []; const owner = groupKey(v);
                  const d = dueDays(v);
                  const sla = isOverdue(v) ? { t: `${-(d as number)}d over`, c: '#B23A3A' } : d != null && d <= 7 ? { t: `${d}d left`, c: '#9A6410' } : d != null ? { t: `${d}d`, c: SEC } : { t: 'no due', c: FAINT };
                  return (
                    <tr key={v.id} onClick={() => onView(v)} style={{ cursor: 'pointer' }} className="ccrow">
                      <td style={{ padding: '9px 14px', borderBottom: `1px solid ${BORDER2}`, textAlign: 'right', fontFamily: MONO, fontWeight: 700, color: bm.c, ...TNUM }}>{sc}</td>
                      <td style={{ padding: '9px 14px', borderBottom: `1px solid ${BORDER2}`, maxWidth: 320 }}>
                        <div style={{ fontSize: 12.5, fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={v.title}>{shortenVulnTitle(v.title)}</div>
                        <div style={{ fontFamily: MONO, fontSize: 10.5, color: FAINT }}>{v.cve_id || `VULN-${v.id}`}</div>
                      </td>
                      <td style={{ padding: '9px 14px', borderBottom: `1px solid ${BORDER2}` }}><SevDot s={v.severity} /></td>
                      <td style={{ padding: '9px 14px', borderBottom: `1px solid ${BORDER2}`, maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: 12, color: assets.length ? SEC : FAINT }} title={assets.join(', ')}>{assets.length ? `${assets[0]}${assets.length > 1 ? ` +${assets.length - 1}` : ''}` : '—'}</td>
                      <td style={{ padding: '9px 14px', borderBottom: `1px solid ${BORDER2}`, maxWidth: 150, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', fontSize: 12, color: owner === 'Unassigned' ? FAINT : SEC }}>{owner}</td>
                      <td style={{ padding: '9px 14px', borderBottom: `1px solid ${BORDER2}` }}><span style={{ display: 'inline-flex', gap: 4, flexWrap: 'wrap' }}>{m.reasons(v).map((r) => <Chip key={r.label} {...r} />)}</span></td>
                      <td style={{ padding: '9px 14px', borderBottom: `1px solid ${BORDER2}`, textAlign: 'right', fontSize: 12, fontWeight: 600, color: sla.c, whiteSpace: 'nowrap', ...TNUM }}>{sla.t}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
            {m.actNow.length > HERON && <div style={{ padding: '8px 16px', fontSize: 11.5, color: MUTED }}>+{m.actNow.length - HERON} more in the queue — open the Register tab to see them all.</div>}
          </div>
        )}
      </section>

      {/* ── funnel + SLA band ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(min(360px,100%),1fr))', gap: 12, flexShrink: 0 }}>
        {/* funnel */}
        <section style={{ ...card, padding: '14px 16px' }}>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, flexWrap: 'wrap' }}>
            <b style={{ fontSize: 13.5 }}>Exploitability funnel</b>
            <span style={{ fontSize: 11, color: MUTED }}>raw severity ≠ real priority</span>
          </div>
          <div style={{ marginTop: 12, display: 'flex', flexDirection: 'column', gap: 9 }}>
            {funnel.map((f) => {
              const FIcon = f.Icon;
              return (
                <div key={f.key} style={{ display: 'grid', gridTemplateColumns: '150px minmax(0,1fr) 36px', gap: 10, alignItems: 'center' }}>
                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 7, fontSize: 12, color: SEC, minWidth: 0 }}><FIcon size={13} color={f.c} /><span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{f.label}</span></span>
                  <span style={{ height: 14, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: w(f.n, m.totalOpen), background: f.c, borderRadius: 4, transition: 'width .3s' }} /></span>
                  <b style={{ fontSize: 12.5, textAlign: 'right', color: INK, ...TNUM }}>{f.n}</b>
                </div>
              );
            })}
          </div>
          <p style={{ fontSize: 11, color: MUTED, marginTop: 11, lineHeight: 1.5, borderTop: `1px solid ${BORDER2}`, paddingTop: 10 }}>
            {m.critHigh} findings read Critical/High on raw severity; <b style={{ color: '#B23A3A' }}>{m.actNow.length}</b> are act-now once exploit, exposure &amp; overdue are weighed — a different set. Width is share of {m.totalOpen} open.
          </p>
        </section>

        {/* SLA band */}
        <section style={{ ...card, padding: '14px 16px' }}>
          <b style={{ fontSize: 13.5 }}>SLA &amp; remediation</b>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3,1fr)', gap: 8, margin: '12px 0 4px' }}>
            <Tile label="Overdue" n={m.overdue} tone={m.overdue > 0 ? '#B23A3A' : INK} />
            <Tile label="Due ≤ 7d" n={m.dueSoon} tone={m.dueSoon > 0 ? '#9A6410' : INK} />
            <Tile label="MTTR" text={m.mttr != null ? `${m.mttr}d` : '—'} />
          </div>
          {m.overdueBySev.length > 0 ? (
            <div style={{ marginTop: 10 }}>
              <div style={{ ...capCss, marginBottom: 6 }}>Overdue by severity</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 5 }}>
                {m.overdueBySev.map(({ k, n }) => (
                  <div key={k} style={{ display: 'grid', gridTemplateColumns: '70px minmax(0,1fr) 28px', gap: 10, alignItems: 'center' }}>
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, fontSize: 11.5, color: SEC }}><SevDot s={k} />{SEV[k].label}</span>
                    <span style={{ height: 9, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: w(n, m.overdue), background: SEV[k].c, borderRadius: 4 }} /></span>
                    <b style={{ fontSize: 11.5, textAlign: 'right', ...TNUM }}>{n}</b>
                  </div>
                ))}
              </div>
            </div>
          ) : (
            <div style={{ marginTop: 10, fontSize: 11.5, color: '#1F7A54' }}>No overdue findings — everything open is within its SLA window.</div>
          )}
          <div style={{ marginTop: 12 }}>
            <div style={{ ...capCss, marginBottom: 6 }}>Open backlog age</div>
            <div style={{ display: 'flex', gap: 8 }}>
              {m.aging.map((a) => (
                <div key={a.label} style={{ flex: 1, textAlign: 'center' }}>
                  <div style={{ height: 40, display: 'flex', alignItems: 'flex-end' }}><span style={{ width: '100%', background: a.label === '> 180d' ? '#C0682F' : AC, opacity: a.label === '> 180d' ? 1 : 0.35 + 0.65 * (a.n / agingMax), height: `${Math.max(a.n > 0 ? 14 : 2, (a.n / agingMax) * 100)}%`, borderRadius: '4px 4px 0 0' }} /></div>
                  <b style={{ fontSize: 11.5, display: 'block', marginTop: 3, ...TNUM }}>{a.n}</b>
                  <span style={{ fontSize: 10, color: MUTED }}>{a.label}</span>
                </div>
              ))}
            </div>
          </div>
        </section>
      </div>

      {/* ── ownership + blast radius ── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(min(360px,100%),1fr))', gap: 12, flexShrink: 0 }}>
        <section style={{ ...card, padding: '14px 16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><Users2 size={15} color={ACS} /><b style={{ fontSize: 13.5 }}>Backlog by owner</b><span style={{ fontSize: 11, color: MUTED, marginLeft: 'auto' }}>open findings</span></div>
          <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {m.backlog.length === 0 ? <div style={{ fontSize: 11.5, color: FAINT }}>No open findings.</div> : m.backlog.map((b) => (
              <div key={b.name} style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) 90px 30px', gap: 10, alignItems: 'center' }}>
                <span style={{ fontSize: 12, color: b.name === 'Unassigned' ? FAINT : SEC, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={b.name}>{b.name}</span>
                <span style={{ height: 9, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: w(b.count, backlogMax), background: b.name === 'Unassigned' ? '#AEB8C2' : AC, borderRadius: 4 }} /></span>
                <b style={{ fontSize: 12, textAlign: 'right', ...TNUM }}>{b.count}</b>
              </div>
            ))}
          </div>
        </section>

        <section style={{ ...card, padding: '14px 16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><Boxes size={15} color={ACS} /><b style={{ fontSize: 13.5 }}>Top exposed assets</b><span style={{ fontSize: 11, color: MUTED, marginLeft: 'auto' }}>by priority load</span></div>
          <div style={{ marginTop: 10, display: 'flex', flexDirection: 'column', gap: 6 }}>
            {m.topAssets.length === 0 ? <div style={{ fontSize: 11.5, color: FAINT }}>No findings are linked to an asset yet — link assets to see blast radius.</div> : m.topAssets.map((a) => (
              <div key={a.name} style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) 90px 54px', gap: 10, alignItems: 'center' }}>
                <span style={{ fontSize: 12, color: SEC, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }} title={a.name}>{a.name}</span>
                <span style={{ height: 9, background: '#F0F3F5', borderRadius: 4, overflow: 'hidden' }}><i style={{ display: 'block', height: '100%', width: w(a.pri, assetMax), background: '#6A54C9', borderRadius: 4 }} /></span>
                <span style={{ fontSize: 11, textAlign: 'right', color: MUTED, ...TNUM }}><b style={{ color: INK }}>{a.count}</b> · {a.pri}</span>
              </div>
            ))}
          </div>
          {m.topAssets.length > 0 && <p style={{ fontSize: 10.5, color: FAINT, marginTop: 9 }}>count · summed contextual priority across the asset&apos;s open findings</p>}
        </section>
      </div>

      {/* ── enrichment honesty strip ── */}
      <section style={{ ...card, padding: '12px 16px', background: ACSOFT, borderColor: '#D7E6F2', flexShrink: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, flexWrap: 'wrap' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 9, flex: 1, minWidth: 260 }}>
            <span style={{ width: 30, height: 30, borderRadius: 8, background: '#fff', color: ACS, display: 'grid', placeItems: 'center', flex: 'none' }}><ShieldAlert size={16} /></span>
            <div style={{ minWidth: 0 }}>
              <b style={{ fontSize: 12.5, color: ACS }}>Data confidence</b>
              <div style={{ fontSize: 11.5, color: SEC, lineHeight: 1.5, marginTop: 1 }}>
                {m.cveRows === 0
                  ? <>None of the {m.totalOpen} open findings carry a CVE — these are informational results with no external threat intel to score. Priority reflects CVSS and context only, not &ldquo;zero risk&rdquo;.</>
                  : m.enrichPct === 0
                    ? <>Threat intel is <b>not scored yet</b> for the {m.cveRows} CVE-bearing finding{m.cveRows === 1 ? '' : 's'} — priority reflects CVSS and context only until enrichment runs.{m.noCve > 0 && <> {m.noCve} finding{m.noCve === 1 ? '' : 's'} carry no CVE (informational).</>}</>
                    : <>Threat intel scored for <b>{m.enrichedCve} of {m.cveRows}</b> findings with a CVE ({m.enrichPct}%).{m.noCve > 0 && <> {m.noCve} finding{m.noCve === 1 ? '' : 's'} carry no CVE (informational) — nothing to enrich.</>}</>}
              </div>
            </div>
          </div>
          <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
            <HeadStat label="With CVE" n={m.cveRows} />
            <HeadStat label="Scored" n={m.enrichedCve} tone={ACS} />
            <HeadStat label="No CVE" n={m.noCve} />
          </div>
        </div>
      </section>

      <div style={{ fontSize: 10.5, color: FAINT, textAlign: 'right', paddingRight: 2, display: 'flex', alignItems: 'center', gap: 4, justifyContent: 'flex-end' }}>
        Priority is the contextual composite (0–100): CVSS weighed with exploitability, exposure &amp; asset criticality. Row <ArrowRight size={11} /> finding detail.
      </div>
      <style>{`.ccrow:hover{background:#F7FBFA}`}</style>
    </div>
  );
}

function HeadStat({ label, n, text, tone = INK }: { label: string; n?: number; text?: string; tone?: string }) {
  return (
    <div style={{ textAlign: 'right' }}>
      <div style={{ fontSize: 10.5, color: MUTED, whiteSpace: 'nowrap' }}>{label}</div>
      <b style={{ fontSize: 17, fontWeight: 600, color: tone, ...TNUM }}>{text ?? n ?? 0}</b>
    </div>
  );
}

function Tile({ label, n, text, tone = INK }: { label: string; n?: number; text?: string; tone?: string }) {
  return (
    <div style={{ border: `1px solid ${BORDER2}`, borderRadius: 10, padding: '9px 10px', textAlign: 'center' }}>
      <b style={{ fontSize: 19, fontWeight: 600, color: tone, ...TNUM }}>{text ?? n ?? 0}</b>
      <div style={{ fontSize: 10.5, color: MUTED, marginTop: 1 }}>{label}</div>
    </div>
  );
}
