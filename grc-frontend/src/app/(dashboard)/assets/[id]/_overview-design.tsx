'use client';

/*
 * AssetOverview — asset detail Overview tab.
 * Telemetry is shown as toggle pages (Hardware · Software · Security · Ownership &
 * context for hosts; the kind's own groups for external / database / network /
 * cloud / cluster / directory assets), each a dashboard of cards.
 *
 * Data: `A` from _overview-map.buildOverviewData. Hosts get curated cards built
 * from the raw collector sections (A.raw.pp); every section a curated card does
 * NOT claim — and every leftover field inside a claimed section — still renders
 * through the generic section cards / "More details" rows, so no collected field
 * is dropped. Missing data is shown as an honest muted state, never invented.
 */

import React, { useMemo, useState } from 'react';
import { MONO, CARD, TONE, Card, Row, Muted, Sub, SectionCards, ProvenanceCard, HardwareCards, SoftwareCards, SecurityCards, securityReview, claimedKeys } from './_telemetry-cards';

/* eslint-disable @typescript-eslint/no-explicit-any */

/* ── main ───────────────────────────────────────────────────────────────── */

type SurfaceFingerprint = { osGuess: string | null; product: string | null; sshBanner: string | null; httpServer: string | null; httpTitle: string | null; snmpSysdescr: string | null; confidence: number | null; evidence: string[] | null; hostname: string | null };
type SurfaceFacts = { ip: string | null; mac: string | null; ports: number[] | null; deviceType: string | null; vendor: string | null; internetFacing: boolean; fingerprint?: SurfaceFingerprint | null };

function SurfacePage({ A, surface }: { A: any; surface: SurfaceFacts }) {
  const ports = surface.ports || [];
  const fp = surface.fingerprint || null;
  const cap = (s: string | null) => (s ? s.charAt(0).toUpperCase() + s.slice(1) : '');
  const facts: [string, string, boolean?][] = [['IP address', surface.ip || '—', true], ['MAC', surface.mac || '—', true], ['Device type', surface.deviceType || '—'], ['Vendor', surface.vendor || '—'], ['Internet-facing', surface.internetFacing ? 'Yes' : 'No']];
  if (fp?.osGuess) facts.push(['OS (inferred)', cap(fp.osGuess)]);
  if (fp?.product) facts.push(['Primary product', fp.product]);
  if (fp?.hostname && fp.hostname !== surface.ip) facts.push(['Computer name', fp.hostname]);
  const intel: [string, string][] = [];
  if (fp?.sshBanner) intel.push(['SSH service', fp.sshBanner]);
  if (fp?.httpServer) intel.push(['Web server', fp.httpServer + (fp.httpTitle ? ` — "${fp.httpTitle}"` : '')]);
  else if (fp?.httpTitle) intel.push(['Web page', `"${fp.httpTitle}"`]);
  if (fp?.snmpSysdescr) intel.push(['SNMP sysDescr', fp.snmpSysdescr]);
  if (fp && (fp.confidence != null || (fp.evidence && fp.evidence.length))) intel.push(['Classification', `${surface.deviceType || 'host'}${fp.confidence != null ? ` · ${Math.round(fp.confidence * 100)}% confidence` : ''}${fp.evidence && fp.evidence.length ? ` · via ${fp.evidence.join(', ')}` : ''}`]);
  const gate = (what: string) => (
    <div className="flex items-center gap-3 rounded-xl border border-dashed border-[#dfe4e8] bg-[#fafbfc] px-3.5 py-2.5 lg:col-span-2">
      <span className={'text-[12px] font-bold text-[#0f1f2b] ' + MONO}>{surface.ip || A.header?.name}</span>
      <span className="text-[12px] text-[#6b7787] flex-1">{what}</span>
      <span className="text-[11px] font-semibold text-[#6b7787] bg-[#eef1f3] border border-[#dfe4e8] rounded-md px-2 py-[2px] whitespace-nowrap">Requires credentials</span>
    </div>
  );
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-2.5">
      <Card title="Surface facts" meta="credential-free discovery · agentless">
        {facts.map(([k, v, m]) => <Row key={k} label={k} value={v === '—' ? null : v} mono={m} />)}
        <Sub>Open ports</Sub>
        {ports.length ? <div className="flex flex-wrap gap-1.5">{ports.map((p) => <span key={p} className={'text-[11.5px] font-semibold text-[#28578f] bg-[#e7f0f8] border border-[#cfe0f0] rounded-md px-2 py-0.5 ' + MONO}>{p}</span>)}</div> : <Muted>No open ports recorded</Muted>}
      </Card>
      <Card title="Surface intelligence" meta="inferred, no credentials">
        {intel.length ? intel.map(([k, v]) => <Row key={k} label={k} value={v} mono={k !== 'Classification'} />) : <Muted>No banners or service versions captured by network discovery</Muted>}
      </Card>
      {gate('Hardware · CPU · memory · storage · firmware')}
      {gate('Operating system · installed software · patches · services')}
      {gate('Defender · firewall · disk encryption · local users')}
      <div className="lg:col-span-2 text-[11px] text-[#8a95a1]">Connect this asset with credentials (or install the agent) to collect deep telemetry.</div>
    </div>
  );
}

export default function AssetOverview({ A, surface, riskProfile }: { A: any; surface?: SurfaceFacts | null; riskProfile?: any }) {
  const pp = A.raw?.pp || {};
  const hostCurated = !!A.server && !surface;
  const review = useMemo(() => securityReview(pp), [pp]);
  const claimed = useMemo(() => (hostCurated ? claimedKeys(pp) : new Set<string>()), [pp, hostCurated]);

  // Generic sections per host domain — whatever the curated cards don't claim.
  const hostDoms = useMemo(() => {
    const secsOf = (keys: string[]) => A.deep.filter((g: any) => keys.includes(g.key)).flatMap((g: any) => g.sections || []).filter((s: any) => !claimed.has(s.key));
    const known = ['hardware', 'network', 'system', 'packagesservices', 'security', 'accountsaccess', 'accounts'];
    return {
      hardware: secsOf(['hardware', 'network']),
      software: [...secsOf(['system', 'packagesservices']), ...A.deep.filter((g: any) => !known.includes(g.key)).flatMap((g: any) => g.sections || []).filter((s: any) => !claimed.has(s.key))],
      security: secsOf(['security', 'accountsaccess', 'accounts']),
    };
  }, [A, claimed]);

  const tabs: { key: string; label: string; sub?: string }[] = surface
    ? [{ key: 'surface', label: 'Surface telemetry' }]
    : hostCurated
      ? [{ key: 'hardware', label: 'Hardware telemetry' }, { key: 'software', label: 'Software telemetry' }, { key: 'security', label: 'Security telemetry' }]
      : A.deep.length
        ? A.deep.map((g: any) => ({ key: 'g:' + g.key, label: g.pill || g.label, sub: g.sub }))
        : [{ key: 'telemetry', label: A.external ? 'Outside-in telemetry' : 'Telemetry' }];
  if (A.manual?.length) tabs.push({ key: 'ownership', label: 'Ownership & context' });
  const [tab, setTab] = useState<string>(tabs[0].key);
  const active = tabs.some((t) => t.key === tab) ? tab : tabs[0].key;
  const [openKpi, setOpenKpi] = useState<number | null>(null);
  const [riskView, setRiskView] = useState<'before' | 'after' | null>(null);


  const beforeRows = riskProfile && Array.isArray(riskProfile.before_groups) ? riskProfile.before_groups : [];
  const afterRows = riskProfile && Array.isArray(riskProfile.groups) ? riskProfile.groups.flatMap((g: any) => g.rows || []) : [];
  const riskRows = riskView === 'before' ? beforeRows : riskView === 'after' ? afterRows : [];
  const hasRisk = riskProfile && riskProfile.raw != null;
  const kpiCell = 'flex-1 min-w-[112px] px-3 py-1.5 border-r border-[#f0f3f5] last:border-r-0';

  return (
    <div className="inv2" style={{ fontSize: 13.5 }}>
      {/* toggle pages */}
      <div className="flex gap-5 border-b border-[#e8ecee] mb-2.5 overflow-x-auto overflow-y-hidden px-0.5">
        {tabs.map((t) => (
          <button key={t.key} type="button" title={t.sub} onClick={() => setTab(t.key)}
            className={'text-[12.5px] whitespace-nowrap pb-1.5 -mb-px border-b-2 ' + (active === t.key ? 'font-semibold text-[#014A81] border-[#005B96]' : 'font-medium text-[#6b7787] border-transparent hover:text-[#0f1f2b]')}>
            {t.label}
          </button>
        ))}
      </div>

      {/* KPI + risk strip (one compact row) */}
      {!surface && (
        <div className={CARD + ' mb-2.5 flex flex-wrap'}>
          {A.kpis.map((k: any, i: number) => {
            const openable = Array.isArray(k.breakdown) && k.breakdown.length > 0;
            return (
              <div key={i} onClick={openable ? () => setOpenKpi(openKpi === i ? null : i) : undefined} className={kpiCell + (openable ? ' cursor-pointer hover:bg-[#fafbfc]' : '')}>
                <div className="text-[10px] text-[#8a95a1] whitespace-nowrap">{k.label}{openable && <span className="ml-1 text-[#005B96]">{openKpi === i ? '▴' : '▾'}</span>}</div>
                <div className={'text-[17px] font-bold leading-none mt-0.5 ' + MONO} style={{ color: k.tone ? (k.tone === 'muted' ? '#8a95a1' : TONE[k.tone]) : '#0f1f2b' }}>{k.value}</div>
                <div className="text-[9.5px] mt-0.5" style={{ color: k.tone === 'ok' ? '#1f7a54' : k.tone === 'warn' ? '#9a6410' : '#aeb8c2' }}>{k.sub}</div>
              </div>
            );
          })}
          {hasRisk && (['before', 'after'] as const).map((v) => (
            <div key={v} onClick={() => setRiskView((x) => (x === v ? null : v))} className={kpiCell + ' cursor-pointer hover:bg-[#fafbfc]' + (riskView === v ? ' bg-[#EFF5FA]' : '')}
              title={v === 'before' ? 'Raw CVSS severity averaged across open findings — click for parameters' : 'Scored on this host: exposure, exploitability, KEV and criticality — click for parameters'}>
              <div className="text-[10px] text-[#8a95a1] whitespace-nowrap">Risk {v} context <span className="text-[#005B96]">{riskView === v ? '▴' : '▾'}</span></div>
              <div className="flex items-baseline gap-1 mt-0.5"><span className={'text-[17px] font-bold leading-none ' + MONO} style={{ color: v === 'before' ? TONE.bad : TONE.ok }}>{v === 'before' ? riskProfile.raw : riskProfile.contextual}</span><span className="text-[10px] text-[#aeb8c2]">/ 100</span></div>
              <div className="text-[9.5px] mt-0.5 text-[#aeb8c2]">{v === 'before' ? `raw CVSS · ${riskProfile.count} open finding${riskProfile.count === 1 ? '' : 's'}` : `in context${riskProfile.internet_facing ? ' · internet-facing' : ''}`}</div>
            </div>
          ))}
        </div>
      )}

      {riskView && riskRows.length > 0 && (
        <div className="rounded-xl border border-[#9cc0dd] bg-[#EFF5FA] p-3 mb-2.5">
          <div className="flex items-start justify-between gap-3">
            <div className="text-[12px] font-bold text-[#0f1f2b]">{riskView === 'before' ? `Before — the parameters behind the raw CVSS score, across ${riskProfile.count} open finding${riskProfile.count === 1 ? '' : 's'}` : `After — how this host's context scores the risk, across ${riskProfile.count} open finding${riskProfile.count === 1 ? '' : 's'}`}</div>
            <button onClick={() => setRiskView(null)} className="text-[11.5px] font-semibold text-[#005B96] whitespace-nowrap">Close</button>
          </div>
          <div className="mt-2 grid lg:grid-cols-2 gap-x-6 gap-y-1.5">
            {riskRows.map((r: any, ri: number) => (
              <div key={ri} className="flex items-center gap-3">
                <div className="w-48 flex-none"><div className="text-[12px] font-semibold text-[#0f1f2b]">{r.label}</div><div className="text-[10.5px] text-[#8a95a1]">{r.evidence}</div></div>
                <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-white"><div className="h-full rounded-full bg-[#005B96]" style={{ width: Math.max(2, r.max ? Math.min(100, (r.pts / r.max) * 100) : 0) + '%' }} /></div>
                <div className={'w-16 flex-none text-right text-[12px] font-semibold tabular-nums text-[#0f1f2b] ' + MONO}>{r.pts} / {r.max}</div>
              </div>
            ))}
          </div>
        </div>
      )}

      {openKpi != null && Array.isArray(A.kpis[openKpi]?.breakdown) && (() => {
        const k = A.kpis[openKpi];
        return (
          <div className="rounded-xl border border-[#9cc0dd] bg-[#EFF5FA] p-3 mb-2.5">
            <div className="flex items-start justify-between gap-3">
              <div><div className="text-[12.5px] font-bold text-[#0f1f2b]">{k.breakdownTitle || 'Score breakdown'}</div>{k.breakdownNote && <p className="mt-0.5 text-[11px] text-[#3a4653] max-w-3xl">{k.breakdownNote}</p>}</div>
              <button onClick={() => setOpenKpi(null)} className="text-[11.5px] font-semibold text-[#005B96] whitespace-nowrap">Close ✕</button>
            </div>
            <div className="mt-2 grid lg:grid-cols-2 gap-x-6 gap-y-1.5">
              {k.breakdown.map((r: any, i: number) => {
                const na = r.applicable === false;
                const pct = Math.max(0, Math.min(100, r.pct ?? 0));
                return (
                  <div key={i} className={'flex items-center gap-3' + (na ? ' opacity-60' : '')}>
                    <div className="w-48 flex-none">
                      <div className="flex items-center gap-1.5 text-[12px] font-semibold text-[#0f1f2b]">{r.label}<span className="rounded bg-white px-1.5 py-0.5 text-[10px] font-bold tabular-nums text-[#3a4653]">{r.weightPct != null ? `${r.weightPct}%` : 'N/A'}</span></div>
                      <div className="text-[10.5px] text-[#8a95a1]">{r.value}</div>
                    </div>
                    {na ? <div className="flex-1 text-[10.5px] italic text-[#aeb8c2]">not counted in the score</div>
                      : <div className="h-1.5 flex-1 overflow-hidden rounded-full bg-white"><div className="h-full rounded-full" style={{ width: Math.max(2, pct) + '%', background: r.tone === 'ok' ? '#1f7a54' : r.tone === 'warn' ? '#e2b33c' : '#b23a3a' }} /></div>}
                    <div className={'w-10 flex-none text-right text-[12px] font-semibold tabular-nums text-[#0f1f2b] ' + MONO}>{na ? '—' : pct}</div>
                  </div>
                );
              })}
            </div>
          </div>
        );
      })()}

      {/* access / absence notes — honest, on every telemetry page */}
      {active !== 'ownership' && (A.deepNote?.denied?.length > 0 || A.deepNote?.absent?.length > 0) && (
        <div className="mb-2.5 flex flex-col gap-1">
          {A.deepNote.denied?.length > 0 && <div className="rounded-lg border border-[#ead9ae] bg-[#fbf7ec] px-3 py-1.5 text-[11.5px] text-[#7a6427]"><b>Needs elevated access</b> (root / sudo): {A.deepNote.denied.join(' · ')}.</div>}
          {A.deepNote.absent?.length > 0 && <div className="text-[11px] text-[#8a95a1] px-1">Not present on this host: {A.deepNote.absent.join(' · ')}.</div>}
        </div>
      )}

      {/* pages */}
      {active === 'surface' && surface && <SurfacePage A={A} surface={surface} />}
      {active === 'hardware' && <><HardwareCards A={A} /><SectionCards secs={hostDoms.hardware} /></>}
      {active === 'software' && <><SoftwareCards A={A} /><SectionCards secs={hostDoms.software} /></>}
      {active === 'security' && <><SecurityCards A={A} review={review} /><SectionCards secs={hostDoms.security} /></>}
      {active.startsWith('g:') && <div className="-mt-2.5"><SectionCards secs={(A.deep.find((g: any) => 'g:' + g.key === active) || { sections: [] }).sections} /></div>}
      {active === 'telemetry' && (
        A.external
          ? <div className="rounded-xl border border-[#ead9ae] bg-[#fbf7ec] px-4 py-3 text-[12px] text-[#7a6427]"><b>No outside-in data collected yet.</b> Run <b>Rescan domain</b> to probe DNS, TLS, HTTP posture and email security for this host — telemetry appears here once the crawl completes.</div>
          : <div className={CARD + ' px-4 py-6 text-center'}><div className="text-[13px] font-semibold text-[#6b7787]">No deep inventory collected for this asset yet</div><div className="text-[11.5px] text-[#aeb8c2] mt-1">Connect it with credentials (or a database login for an application) to collect its telemetry.</div></div>
      )}
      {active === 'ownership' && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-2.5">
          {A.manual.map((c: any, i: number) => <ProvenanceCard key={i} card={c} wide={i === 0} />)}
        </div>
      )}
    </div>
  );
}
