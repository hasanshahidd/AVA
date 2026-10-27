'use client';

/**
 * ScanWorkspace — the register-owned Plan + Scan running SCREEN (moved wholesale from the
 * AI-Pentest engine). Left: the in-page asset+CVE sidebar. Right, for the selected asset: the
 * plan/recon preview (auto-routed lane + scanner + credential decision, from assess()), a Run-scan
 * control with live progress, and the asset's findings. Two input modes — from-inventory and ad-hoc
 * target — with NO manual lane pick (the engine auto-routes from asset type). Ad-hoc results are
 * stored & viewable here but excluded from the inventory-only dashboard rollup (backend exclude_adhoc).
 *
 * Reuses the backend seam only: vulnManagementApi.scan.* (plan=assess, start/adhoc=start_scan,
 * job=poll) + /pentest/scanned-assets for the rail. No new scanner.
 */
import { useEffect, useMemo, useRef, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { ScanLine, ShieldCheck, Server, Globe, KeyRound, Target, Plus } from 'lucide-react';
import apiClient, { vulnManagementApi } from '@/lib/api';
import { AssetCveSidebar, type SidebarAsset } from '@/components/scan/AssetCveSidebar';
import ScanLauncher from './ScanLauncher';
import { shortenVulnTitle, type Vulnerability } from './lib';

const AC = '#005B96', ACS = '#014A81', ACSOFT = '#EFF5FA', BORDER = '#E8ECEE', INK = '#0F1F2B', MUTED = '#8A95A1', FAINT = '#AEB8C2', SEC = '#3A4653';
const SEVC: Record<string, { c: string; bg: string }> = {
  critical: { c: '#C2453F', bg: '#FBEAEA' }, high: { c: '#C0682F', bg: '#FCEEE2' },
  medium: { c: '#9A6410', bg: '#FBF2DF' }, low: { c: '#1F7A54', bg: '#E7F5EE' }, info: { c: '#6B7787', bg: '#EEF1F3' },
};
const sev = (s?: string) => { const k = (s || 'info').toLowerCase(); return SEVC[k] || SEVC.info; };
const btn: React.CSSProperties = { border: `1px solid #E4E8EC`, background: '#fff', color: SEC, borderRadius: 9, padding: '7px 12px', fontSize: 12, fontWeight: 500, display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer' };
const btnGreen: React.CSSProperties = { ...btn, background: AC, borderColor: AC, color: '#fff', fontWeight: 600 };

type Filter = 'all' | 'inventory' | 'adhoc';
const TERMINAL = new Set(['done', 'failed', 'complete', 'completed', 'error', 'none']);

export function ScanWorkspace({ assetItems = [], vulns = [] }: {
  assetItems?: { value: string; label: string }[];
  vulns?: Vulnerability[];
}) {
  const qc = useQueryClient();
  const [selected, setSelected] = useState<number | null>(null);
  const [filter, setFilter] = useState<Filter>('all');
  const [showLauncher, setShowLauncher] = useState(false);
  const [job, setJob] = useState<{ status?: string; progress?: number; stage?: string; findings_count?: number; error?: string } | null>(null);
  const pollRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  useEffect(() => () => { if (pollRef.current) clearTimeout(pollRef.current); }, []);

  // assets WITH findings (+ ad-hoc flag + count) — the authoritative per-asset count source.
  const { data: scanned } = useQuery<{ assets: { asset_id: number; name: string; host: string; finding_count: number; adhoc: boolean }[] }>({
    queryKey: ['register', 'scanned-assets'],
    queryFn: async () => (await apiClient.get('/pentest/scanned-assets')).data ?? { assets: [] },
    refetchInterval: 8000,
  });
  const countMap = useMemo(() => { const m = new Map<number, number>(); (scanned?.assets ?? []).forEach((a) => m.set(a.asset_id, a.finding_count)); return m; }, [scanned]);
  // CVE chips per asset — derived from the already-fetched register list by linked-asset NAME (cosmetic).
  const cvesByName = useMemo(() => {
    const m = new Map<string, Set<string>>();
    for (const v of vulns) { if (!v.cve_id) continue; for (const n of v.linked_assets || []) { if (!m.has(n)) m.set(n, new Set()); m.get(n)!.add(v.cve_id); } }
    return m;
  }, [vulns]);

  const sidebarAssets = useMemo<SidebarAsset[]>(() => {
    const invIds = new Set(assetItems.map((a) => Number(a.value)));
    const inv: SidebarAsset[] = assetItems.map((a) => ({ id: Number(a.value), label: a.label, findingCount: countMap.get(Number(a.value)) ?? 0, cves: Array.from(cvesByName.get(a.label) ?? []), adhoc: false }));
    const adhoc: SidebarAsset[] = (scanned?.assets ?? []).filter((a) => a.adhoc && !invIds.has(a.asset_id))
      .map((a) => ({ id: a.asset_id, label: a.name || a.host, sub: a.host, findingCount: a.finding_count, cves: Array.from(cvesByName.get(a.name) ?? cvesByName.get(a.host) ?? []), adhoc: true }));
    const all = [...inv, ...adhoc];
    const f = filter === 'inventory' ? all.filter((a) => !a.adhoc) : filter === 'adhoc' ? all.filter((a) => a.adhoc) : all;
    return f.sort((a, b) => (b.findingCount ?? 0) - (a.findingCount ?? 0));
  }, [assetItems, scanned, countMap, cvesByName, filter]);

  // plan/recon preview (assess) for the selected asset — auto-routed lane + scanner + creds + findings.
  const { data: plan, isFetching: planLoading, refetch: refetchPlan } = useQuery<any>({
    queryKey: ['register', 'scan-plan', selected],
    queryFn: async () => (await vulnManagementApi.scan.plan(selected!)).data,
    enabled: selected != null,
  });

  const poll = (jobId: number) => {
    pollRef.current = setTimeout(async () => {
      try {
        const { data } = await vulnManagementApi.scan.job(jobId);
        setJob(data);
        if (TERMINAL.has(String(data?.status))) {
          qc.invalidateQueries({ queryKey: ['register', 'scanned-assets'] });
          qc.invalidateQueries({ queryKey: ['vulnerabilities'] });
          qc.invalidateQueries({ queryKey: ['vuln-dashboard'] });
          refetchPlan();
          return;
        }
        poll(jobId);
      } catch { setJob({ status: 'error', error: 'lost track of the scan job' }); }
    }, 3000);
  };

  // The rich launcher started one or more scans; focus the first scanned asset and poll its job.
  const onLauncherStarted = (assetId: number, jobId: number) => {
    setShowLauncher(false);
    setSelected(assetId);
    setJob({ status: 'queued', stage: 'starting' });
    qc.invalidateQueries({ queryKey: ['register', 'scanned-assets'] });
    poll(jobId);
  };

  const scanning = job != null && !TERMINAL.has(String(job.status));
  const planVulns: any[] = plan?.vulns ?? [];
  const routing = plan?.routing ?? {}; const creds = plan?.credentials ?? {}; const summary = plan?.summary ?? {};
  const selMeta = sidebarAssets.find((a) => a.id === selected);

  const header = (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <button style={{ ...btnGreen, justifyContent: 'center' }} onClick={() => setShowLauncher(true)}><Plus size={14} />New scan</button>
      <div style={{ display: 'inline-flex', background: '#EAEEF1', borderRadius: 9, padding: 3, gap: 2 }}>
        {(['all', 'inventory', 'adhoc'] as Filter[]).map((f) => (
          <button key={f} onClick={() => setFilter(f)} style={{ flex: 1, height: 26, border: 0, borderRadius: 7, background: filter === f ? '#fff' : 'none', color: filter === f ? ACS : '#6B7787', fontSize: 11, fontWeight: 600, cursor: 'pointer', textTransform: 'capitalize' }}>{f === 'adhoc' ? 'Ad-hoc' : f}</button>
        ))}
      </div>
    </div>
  );

  return (
    <div style={{ display: 'flex', gap: 12, height: '100%', minHeight: 0 }}>
      <AssetCveSidebar assets={sidebarAssets} selectedId={selected} onSelect={(id) => { setSelected(id); setJob(null); }} title="Assets & CVEs" emptyText="No assets in this view." headerExtra={header} />
      <div style={{ flex: 1, minWidth: 0, overflowY: 'auto' }}>
        {selected == null ? (
          <div style={{ height: '100%', display: 'grid', placeItems: 'center', color: FAINT, textAlign: 'center' }}>
            <div><ScanLine size={30} style={{ opacity: 0.5 }} /><p style={{ marginTop: 8, fontSize: 13 }}>Select an asset to plan &amp; scan it, or add an ad-hoc target.</p></div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {/* plan / recon preview */}
            <div style={{ background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 14, padding: '13px 16px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10 }}>
                <span style={{ display: 'grid', placeItems: 'center', height: 34, width: 34, borderRadius: 9, background: ACSOFT, color: AC }}>{selMeta?.adhoc ? <Globe size={17} /> : <Server size={17} />}</span>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <h2 style={{ margin: 0, fontSize: 15, fontWeight: 700, color: INK }}>{plan?.asset?.name || selMeta?.label || `Asset ${selected}`}{selMeta?.adhoc && <span style={{ fontSize: 9.5, fontWeight: 700, color: MUTED, background: '#EEF1F3', borderRadius: 5, padding: '2px 6px', marginLeft: 8 }}>AD-HOC</span>}</h2>
                  <div style={{ fontSize: 11, color: MUTED, fontFamily: 'ui-monospace,Consolas,monospace' }}>{[plan?.asset?.ip, plan?.asset?.hostname, plan?.asset?.asset_type].filter(Boolean).join(' · ') || '—'}</div>
                </div>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 10 }}>
                <Meta icon={<Target size={13} />} label="Routed lane" value={routing.lane_label || routing.lane || '—'} />
                <Meta icon={<ScanLine size={13} />} label="Scanner (auto)" value={routing.selected_find || '—'} />
                <Meta icon={<KeyRound size={13} />} label="Credentials" value={creds.action === 'reuse' ? `reuse · ${creds.profile_label || 'saved'}` : creds.action === 'available' ? 'available' : creds.action === 'prompt' ? 'none (required)' : creds.action === 'uncredentialed' ? 'uncredentialed' : (creds.mode || '—')} />
                <Meta icon={<ShieldCheck size={13} />} label="Findings" value={String(summary.total ?? planVulns.length ?? 0)} />
              </div>
              {scanning && (
                <div style={{ marginTop: 11 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: MUTED, marginBottom: 4 }}><span>{job?.stage || job?.status || 'scanning'}…</span><span>{job?.progress != null ? `${job.progress}%` : ''}</span></div>
                  <div style={{ height: 7, borderRadius: 5, background: '#EAEEF1', overflow: 'hidden' }}><div style={{ width: `${job?.progress ?? 10}%`, height: '100%', background: AC, transition: 'width .4s' }} /></div>
                </div>
              )}
              {job && TERMINAL.has(String(job.status)) && (
                <div style={{ marginTop: 11, fontSize: 12, fontWeight: 500, borderRadius: 8, padding: '8px 11px', background: job.status === 'failed' || job.status === 'error' ? '#FBEAEA' : '#E7F5EE', color: job.status === 'failed' || job.status === 'error' ? '#B23A3A' : '#1F7A54' }}>
                  {job.status === 'failed' || job.status === 'error' ? `Scan failed: ${job.error || 'see pentest logs'}.` : `Scan complete — ${job.findings_count ?? summary.total ?? 0} finding(s) in the register.`}
                </div>
              )}
            </div>
            {/* findings */}
            <div style={{ background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 14, overflow: 'hidden' }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '10px 16px', borderBottom: `1px solid ${BORDER}` }}>
                <h3 style={{ margin: 0, fontSize: 13, fontWeight: 700, color: INK }}>Findings</h3>
                <span style={{ fontSize: 11.5, color: MUTED }}>{planLoading ? 'loading…' : `${planVulns.length} shown`}</span>
              </div>
              <div style={{ maxHeight: 460, overflowY: 'auto' }}>
                {planVulns.length === 0 ? (
                  <div style={{ padding: 26, textAlign: 'center', fontSize: 12, color: FAINT }}>{planLoading ? 'Loading…' : 'No findings yet — run a scan.'}</div>
                ) : (
                  <table style={{ width: '100%', borderCollapse: 'collapse' }}>
                    <tbody>
                      {planVulns.map((v) => { const sm = sev(v.severity); return (
                        <tr key={v.id} style={{ borderBottom: `1px solid #F0F3F5` }}>
                          <td style={{ padding: '9px 12px', width: 70 }}><span style={{ fontSize: 10, fontWeight: 600, color: sm.c, background: sm.bg, borderRadius: 999, padding: '2px 8px', textTransform: 'capitalize' }}>{(v.severity || 'info')}</span></td>
                          <td style={{ padding: '9px 8px' }}><div style={{ fontSize: 12, fontWeight: 600, color: INK }}>{shortenVulnTitle(v.title)}</div><div style={{ fontSize: 9.5, color: FAINT, fontFamily: 'ui-monospace,Consolas,monospace' }}>{v.cve_id || v.source} {v.category ? `· ${v.category}` : ''}</div></td>
                          <td style={{ padding: '9px 12px', width: 60, textAlign: 'right', fontFamily: 'ui-monospace,Consolas,monospace', fontSize: 11, color: sm.c }}>{v.cvss ?? '—'}</td>
                        </tr>
                      ); })}
                    </tbody>
                  </table>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
      {showLauncher && <ScanLauncher onClose={() => setShowLauncher(false)} onStarted={onLauncherStarted} />}
    </div>
  );
}

function Meta({ icon, label, value }: { icon: React.ReactNode; label: string; value: string }) {
  return (
    <div style={{ border: `1px solid ${BORDER}`, borderRadius: 9, padding: '8px 10px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 5, fontSize: 10, color: MUTED, textTransform: 'uppercase', letterSpacing: '.04em' }}>{icon}{label}</div>
      <div style={{ fontSize: 12.5, fontWeight: 600, color: INK, marginTop: 3, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{value}</div>
    </div>
  );
}

export default ScanWorkspace;
