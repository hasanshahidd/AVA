'use client';

import { PageLoader } from '@/components/ui';
import { useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { advisoriesApi } from '@/lib/api';
import {
  AlertCircle, Upload, Loader2, RefreshCw, ExternalLink, ShieldAlert,
  Database, X, ChevronDown, ChevronRight, Server, Play, History,
} from 'lucide-react';
import {
  AdvisoryView, AdvisoryListResponse, MatchReportData, MatchTarget,
  SeverityBadge, StatusBadge, RichText, VulnCard, RegionPicker,
  MatchPanel, MatchReport, MatchHistory, HistoryTimeline, FlowStrip,
} from './_components/ui';

interface AdvisorySource {
  key: string;
  name: string;
  region?: string;
  kind: string;
}

interface Flash {
  text: string;
  ok: boolean;
}

interface AffectedAsset {
  asset_id: number;
  asset_name: string;
  host?: string | null;
  items: { advisory_id: number; advisory_title: string; cve_id: string }[];
}

const ALL = 'all';
// Multinational buckets sort first, then countries alphabetically, Unclassified last.
const REGION_ORDER = ['US', 'EU', 'UK', 'Global'];

function FilterSelect({ label, value, options, onChange }: {
  label: string; value: string; options: string[]; onChange: (v: string) => void;
}) {
  return (
    <label className="flex flex-col gap-1">
      <span className="text-[11px] font-semibold uppercase tracking-wider cw-text-muted">{label}</span>
      <select value={value} onChange={(e) => onChange(e.target.value)}
        className="min-w-[7rem] rounded-md border border-[var(--color-border)] bg-transparent px-2.5 py-1.5 text-xs cw-text-default">
        <option value={ALL}>All</option>
        {options.map((o) => <option key={o} value={o}>{o}</option>)}
      </select>
    </label>
  );
}

function regionRank(region: string): number {
  if (region === 'Unclassified') return REGION_ORDER.length + 1;  // always last
  const i = REGION_ORDER.indexOf(region);
  return i < 0 ? REGION_ORDER.length : i;  // known buckets first, then countries A–Z
}

// Absolute date with year (publication / processing dates); '—' when absent.
function fmtDate(at?: string | null): string {
  if (!at) return '—';
  const dt = new Date(at);
  return isNaN(dt.getTime()) ? '—' : dt.toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

// Display source for grouping/filter. An uploaded advisory is labelled by the
// issuer we parsed (the external_id's leading code, e.g. 'NCA-17.240826' → 'NCA')
// instead of a generic 'Uploaded document'; falls back to the full id/title.
function sourceLabel(a: AdvisoryView): string {
  if (a.origin === 'upload') {
    const ext = (a.external_id || '').trim();
    const issuer = ext.replace(/\d.*$/, '').replace(/[-_.:\s]+$/, '').trim();
    return issuer || ext || 'Uploaded document';
  }
  return a.source_name || 'Unknown source';
}

export default function AdvisoriesPage() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [sourcesOpen, setSourcesOpen] = useState(false);
  const [affectedOpen, setAffectedOpen] = useState(false);
  const [syncMsg, setSyncMsg] = useState<Flash | null>(null);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [collapsed, setCollapsed] = useState<Set<string>>(new Set());
  const [feedKeys, setFeedKeys] = useState<Set<string>>(new Set());
  // Match selection + right-panel mode (detail | match | report | history).
  const [selAdv, setSelAdv] = useState<Set<number>>(new Set());
  const [selCve, setSelCve] = useState<Set<number>>(new Set());
  const [panelMode, setPanelMode] = useState<'detail' | 'match' | 'report' | 'history'>('detail');
  const [report, setReport] = useState<MatchReportData | null>(null);
  const [reportTitle, setReportTitle] = useState<string>('Match report');
  const [reportSessionId, setReportSessionId] = useState<number | null>(null);

  const [fRegion, setFRegion] = useState(ALL);
  const [fOrigin, setFOrigin] = useState(ALL);
  const [fSource, setFSource] = useState(ALL);
  const [fSeverity, setFSeverity] = useState(ALL);
  const [fStatus, setFStatus] = useState(ALL);

  const { data, isLoading, error } = useQuery({
    queryKey: ['advisories'],
    queryFn: async () => (await advisoriesApi.getAll()).data as AdvisoryListResponse,
  });

  const advisories = useMemo(() => data?.advisories ?? [], [data]);

  const { data: detail } = useQuery({
    queryKey: ['advisory', selectedId],
    queryFn: async () => (await advisoriesApi.getById(selectedId as number)).data as AdvisoryView,
    enabled: selectedId !== null,
  });

  const { data: sourcesData } = useQuery({
    queryKey: ['advisory-sources'],
    queryFn: async () => (await advisoriesApi.listSources()).data as { sources: AdvisorySource[] },
  });

  const { data: affectedData } = useQuery({
    queryKey: ['advisory-affected-assets'],
    queryFn: async () => (await advisoriesApi.affectedAssets()).data as { assets: AffectedAsset[]; total: number },
    enabled: affectedOpen,
  });

  const uploadMutation = useMutation({
    mutationFn: (fd: FormData) => advisoriesApi.upload(fd),
    onSuccess: (res) => {
      queryClient.invalidateQueries({ queryKey: ['advisories'] });
      setUploading(false);
      const id = res.data?.advisory?.id;
      if (id) router.push(`/advisories/${id}`);
    },
    onError: () => setUploading(false),
  });

  const syncMutation = useMutation({
    // Sync each selected feed (reuses the single-source endpoint) and aggregate the result.
    mutationFn: async (keys: string[]) => {
      const out = [];
      for (const k of keys) out.push((await advisoriesApi.syncSource(k)).data);
      return out;
    },
    onSuccess: (results) => {
      queryClient.invalidateQueries({ queryKey: ['advisories'] });
      const created = results.reduce((n, d) => n + (d.created || 0), 0);
      const failed = results.filter((d) => d.ok === false);
      setSyncMsg(failed.length
        ? { text: `${created} new; ${failed.length} feed(s) unreachable: ${failed.map((f) => f.source).join(', ')}`, ok: created > 0 }
        : { text: `${created} new advisor${created === 1 ? 'y' : 'ies'} from ${results.length} feed${results.length > 1 ? 's' : ''}`, ok: true });
    },
    onError: () => setSyncMsg({ text: 'Sync failed — check the sources are reachable', ok: false }),
  });

  const matchMutation = useMutation({
    mutationFn: (target: MatchTarget) => advisoriesApi.match({
      advisory_ids: Array.from(selAdv),
      cve_ids: Array.from(selCve),
      mode: target.mode,
      asset_ids: target.asset_ids,
    }),
    onSuccess: (res) => {
      queryClient.invalidateQueries({ queryKey: ['advisories'] });
      queryClient.invalidateQueries({ queryKey: ['advisory-affected-assets'] });
      queryClient.invalidateQueries({ queryKey: ['advisory-match-sessions'] });
      if (selectedId !== null) queryClient.invalidateQueries({ queryKey: ['advisory', selectedId] });
      setReport(res.data.report as MatchReportData);
      setReportSessionId(res.data.session_id ?? null);
      setReportTitle('Match report');
      setPanelMode('report');
    },
  });

  const handleUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    setUploading(true);
    const fd = new FormData();
    fd.append('file', file);
    uploadMutation.mutate(fd);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  const regionOptions = useMemo(
    () => Array.from(new Set(advisories.map((a) => a.region).filter(Boolean) as string[])).sort(),
    [advisories]);
  const sourceOptions = useMemo(
    () => Array.from(new Set(advisories.map((a) => sourceLabel(a)).filter(Boolean) as string[])).sort(),
    [advisories]);

  const filtered = useMemo(() => advisories.filter((a) =>
    (fRegion === ALL || a.region === fRegion) &&
    (fOrigin === ALL || (fOrigin === 'synced' ? a.origin === 'sync' : a.origin !== 'sync')) &&
    (fSource === ALL || sourceLabel(a) === fSource) &&
    (fSeverity === ALL || (a.severity || '').toLowerCase() === fSeverity) &&
    (fStatus === ALL || a.status === fStatus)
  ), [advisories, fRegion, fOrigin, fSource, fSeverity, fStatus]);

  // Group the filtered list hierarchically: region → source → advisories.
  // Region order = REGION_ORDER then name; sources A–Z within a region.
  const grouped = useMemo(() => {
    const byRegion: Record<string, Record<string, AdvisoryView[]>> = {};
    for (const a of filtered) {
      const r = a.region || 'Other';
      const s = sourceLabel(a);
      ((byRegion[r] ||= {})[s] ||= []).push(a);
    }
    return Object.keys(byRegion)
      .sort((x, y) => regionRank(x) - regionRank(y) || x.localeCompare(y))
      .map((region) => {
        const sources = Object.keys(byRegion[region]).sort()
          .map((source) => ({ source, items: byRegion[region][source] }));
        const items = sources.flatMap((s) => s.items);
        return { region, sources, items };
      });
  }, [filtered]);

  // Clear the selection if the chosen advisory is filtered out — never auto-open one.
  useEffect(() => {
    if (selectedId !== null && !filtered.some((a) => a.id === selectedId)) {
      setSelectedId(null);
    }
  }, [filtered, selectedId]);

  const toggleKey = (key: string) =>
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key); else next.add(key);
      return next;
    });
  const srcKey = (region: string, source: string) => `${region}\u0000${source}`;

  const toggleAdv = (id: number) => setSelAdv((p) => {
    const n = new Set(p); if (n.has(id)) n.delete(id); else n.add(id); return n;
  });
  const toggleCve = (id: number) => setSelCve((p) => {
    const n = new Set(p); if (n.has(id)) n.delete(id); else n.add(id); return n;
  });
  const toggleRegionSel = (items: AdvisoryView[]) => setSelAdv((p) => {
    const n = new Set(p);
    const all = items.every((a) => n.has(a.id));
    items.forEach((a) => (all ? n.delete(a.id) : n.add(a.id)));
    return n;
  });
  const clearSel = () => { setSelAdv(new Set()); setSelCve(new Set()); };
  const selCveTotal = useMemo(
    () => advisories.filter((a) => selAdv.has(a.id)).reduce((n, a) => n + (a.cve_count || 0), 0) + selCve.size,
    [advisories, selAdv, selCve]);

  const openSession = async (id: number) => {
    try {
      const res = await advisoriesApi.getMatchSession(id);
      setReport(res.data.report as MatchReportData);
      setReportSessionId(id);
      setReportTitle(res.data.label || `Match #${id}`);
      setPanelMode('report');
    } catch { /* ignore */ }
  };
  const downloadReport = async (fmt: 'csv' | 'json') => {
    if (reportSessionId === null) return;
    try {
      const res = await advisoriesApi.downloadMatchSession(reportSessionId, fmt);
      const url = URL.createObjectURL(new Blob([res.data]));
      const a = document.createElement('a');
      a.href = url; a.download = `match-session-${reportSessionId}.${fmt}`; a.click();
      URL.revokeObjectURL(url);
    } catch { /* ignore */ }
  };

  if (isLoading) {
    return <div className="flex h-64 items-center justify-center"><PageLoader size="md" /></div>;
  }
  if (error) {
    return (
      <div className="rounded-xl border border-red-700 bg-red-900/20 p-6 text-center">
        <AlertCircle className="mx-auto h-8 w-8 text-red-600" />
        <p className="mt-2 text-red-600">Failed to load advisories</p>
      </div>
    );
  }

  const summary = data?.summary ?? {};
  const affectedTotal = advisories.reduce((n, a) => n + (a.asset_affected_count || 0), 0);
  const apiSources = sourcesData?.sources ?? [];
  const sourceCount = apiSources.length;
  const uploadedDocs = advisories.filter((a) => a.origin === 'upload');

  return (
    <div className="space-y-3">
      {/* Title lives in the global app bar (PAGE_TITLES['/advisories']); here we keep just the actions.
          No viewport lock: the page flows as one column and the dashboard <main> owns the scroll. */}
      <div className="flex justify-end gap-2">
        <input ref={fileInputRef} type="file" accept=".pdf" onChange={handleUpload} className="hidden" />
        <button onClick={() => setSourcesOpen(true)} className="btn-secondary flex items-center gap-2 text-sm">
          <Database size={15} /> Sources
        </button>
        <button onClick={() => fileInputRef.current?.click()} disabled={uploading} className="btn-primary flex items-center gap-2 text-sm">
          {uploading ? <Loader2 size={15} className="animate-spin" /> : <Upload size={15} />} Upload advisory
        </button>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {[
          { l: 'Advisories', v: summary.total ?? advisories.length, hint: 'Show all',
            onClick: () => { setFStatus(ALL); setFRegion(ALL); setFSource(ALL); setFSeverity(ALL); setFOrigin(ALL); } },
          { l: 'Open', v: summary.open ?? 0, hint: 'Filter open', onClick: () => setFStatus('open') },
          { l: 'Assets affected', v: affectedTotal, hint: 'See which', onClick: () => setAffectedOpen(true) },
          { l: 'Sources', v: sourceCount, hint: 'Manage', onClick: () => setSourcesOpen(true) },
        ].map((k) => (
          <button key={k.l} onClick={k.onClick}
            className="cw-card group p-3 text-left transition-colors hover:border-[var(--color-primary)]">
            <p className="text-[11px] font-medium cw-text-muted">{k.l}</p>
            <p className="mt-1 text-2xl font-semibold leading-none cw-text-default">{k.v}</p>
            <p className="mt-1.5 text-[11px] font-medium text-[var(--color-primary)]">{k.hint} →</p>
          </button>
        ))}
      </div>

      {panelMode === 'history' ? (
        <div className="cw-card p-3">
          <MatchHistory onOpen={openSession} onBack={() => setPanelMode('detail')} />
        </div>
      ) : (
      <>
      <div className="cw-card p-3">
        <div className="flex flex-wrap items-center justify-between gap-x-4 gap-y-2">
          <div className="flex flex-wrap items-center gap-2.5">
            <button onClick={() => setPanelMode('match')} disabled={selCveTotal === 0}
              className="btn-primary flex shrink-0 items-center gap-2 text-sm disabled:cursor-not-allowed disabled:opacity-50">
              <Play size={15} /> Match{selCveTotal > 0 ? ` ${selCveTotal} CVE${selCveTotal === 1 ? '' : 's'}` : ''}
            </button>
            {(selAdv.size > 0 || selCve.size > 0) && (
              <span className="flex shrink-0 items-center gap-2 text-xs cw-text-default">
                <span><span className="font-semibold">{selAdv.size}</span> advisor{selAdv.size === 1 ? 'y' : 'ies'}
                  {selCve.size > 0 ? <> · <span className="font-semibold">{selCve.size}</span> extra CVE{selCve.size === 1 ? '' : 's'}</> : null} selected</span>
                <button onClick={clearSel} className="font-medium text-[var(--color-primary)] hover:underline">Clear</button>
              </span>
            )}
          </div>
          <button onClick={() => setPanelMode('history')}
            className="btn-secondary flex shrink-0 items-center gap-1.5 text-sm">
            <History size={15} /> History
          </button>
        </div>

        <div className="mt-3 flex flex-wrap items-end gap-x-5 gap-y-3 border-t border-[var(--color-border)] pt-3">
          <FilterSelect label="Origin" value={fOrigin} options={['uploaded', 'synced']} onChange={setFOrigin} />
          <FilterSelect label="Region" value={fRegion} options={regionOptions} onChange={setFRegion} />
          <FilterSelect label="Source" value={fSource} options={sourceOptions} onChange={setFSource} />
          <FilterSelect label="Severity" value={fSeverity} options={['critical', 'high', 'medium', 'low']} onChange={setFSeverity} />
          <FilterSelect label="Status" value={fStatus} options={['pending', 'open', 'resolved', 'not_applicable']} onChange={setFStatus} />
          <span className="ml-auto pb-1.5 text-[11px] cw-text-muted">
            Showing <span className="font-semibold cw-text-default">{filtered.length}</span> of {advisories.length}
          </span>
        </div>
      </div>

      <div className="grid grid-cols-1 items-start gap-3 lg:grid-cols-[360px_1fr]">
        <div className="cw-card overflow-hidden">
          {filtered.length === 0 ? (
            <div className="px-4 py-10 text-center cw-text-muted">
              <ShieldAlert className="mx-auto mb-2 h-8 w-8" />
              <p className="text-xs">No advisories match these filters.</p>
            </div>
          ) : (
            grouped.map(({ region, sources, items }, ri) => {
              const regionCollapsed = collapsed.has(region);
              return (
                <div key={region} className="first:border-t-0">
                  <div className="flex w-full items-center gap-2 border-t border-[var(--color-border)] bg-[var(--color-subtle)] px-3 py-2">
                    <input type="checkbox" className="shrink-0" title="Select all in region"
                      checked={items.length > 0 && items.every((a) => selAdv.has(a.id))}
                      onChange={() => toggleRegionSel(items)} />
                    <button onClick={() => toggleKey(region)} className="flex flex-1 items-center gap-2 text-left">
                      {regionCollapsed ? <ChevronRight size={14} /> : <ChevronDown size={14} />}
                      <span className="text-[11px] font-bold uppercase tracking-wider cw-text-default">{region}</span>
                      <span className="rounded bg-[var(--color-surface)] px-1.5 py-0.5 text-[10px] font-medium cw-text-muted">{sources.length} source{sources.length === 1 ? '' : 's'}</span>
                      <span className="ml-auto text-xs font-semibold cw-text-muted">{items.length}</span>
                    </button>
                  </div>
                  {!regionCollapsed && sources.map(({ source, items: sItems }, si) => {
                    const key = srcKey(region, source);
                    const srcCollapsed = collapsed.has(key);
                    return (
                      <div key={key}>
                        <div className="flex w-full items-center gap-2 border-t border-[var(--color-border)] py-1.5 pl-7 pr-3">
                          <input type="checkbox" className="shrink-0" title="Select all from this source"
                            checked={sItems.length > 0 && sItems.every((a) => selAdv.has(a.id))}
                            onChange={() => toggleRegionSel(sItems)} />
                          <button onClick={() => toggleKey(key)} className="flex flex-1 items-center gap-1.5 text-left">
                            {srcCollapsed ? <ChevronRight size={12} /> : <ChevronDown size={12} />}
                            <span className="min-w-0 flex-1 truncate text-[11px] font-medium cw-text-default">{source}</span>
                            <span className="ml-auto text-[11px] cw-text-muted">{sItems.length}</span>
                          </button>
                        </div>
                        {!srcCollapsed && sItems.map((a, ai) => (
                          <div key={a.id}
                            className={`flex w-full items-center gap-2 border-t border-[var(--color-border)] py-2 pl-10 pr-3 transition-colors ${selectedId === a.id ? 'bg-[var(--color-base-soft)]' : 'hover:bg-[var(--color-hover)]'}`}>
                            <input type="checkbox" className="shrink-0"
                              checked={selAdv.has(a.id)} onChange={() => toggleAdv(a.id)} />
                            <button onClick={() => { setSelectedId(a.id); setPanelMode('detail'); }}
                              className="flex min-w-0 flex-1 items-center gap-2 text-left transition-colors hover:text-[var(--color-primary)]">
                              <p className="min-w-0 flex-1 truncate text-xs font-medium cw-text-default">{a.title}</p>
                              <div className="ml-auto flex shrink-0 items-center gap-1.5">
                                {a.status === 'pending' ? (
                                  <span className="rounded-md bg-yellow-50 px-1.5 py-0.5 text-[10px] font-medium text-yellow-700">review</span>
                                ) : a.asset_affected_count > 0 ? (
                                  <span className="rounded-md bg-red-50 px-1.5 py-0.5 text-[10px] font-semibold text-red-600">{a.asset_affected_count} affected</span>
                                ) : null}
                                <SeverityBadge severity={a.severity} />
                              </div>
                            </button>
                          </div>
                        ))}
                      </div>
                    );
                  })}
                </div>
              );
            })
          )}
        </div>

        <div className="cw-card p-3">
          {panelMode === 'match' ? (
            <MatchPanel selection={{ advisories: selAdv.size, cves: selCveTotal }}
              onRun={(t) => matchMutation.mutate(t)} onCancel={() => setPanelMode('detail')}
              isPending={matchMutation.isPending} />
          ) : panelMode === 'report' && report ? (
            <MatchReport report={report} title={reportTitle}
              onBack={() => setPanelMode('detail')}
              onDownload={reportSessionId !== null ? downloadReport : undefined} />
          ) : !detail ? (
            <div className="flex flex-col items-center justify-center px-4 py-14 text-center cw-text-muted">
              <ShieldAlert className="mb-2 h-8 w-8" />
              <p className="text-xs">Select an advisory to see its details and CVEs,</p>
              <p className="text-xs">or tick advisories and CVEs, then click Match.</p>
            </div>
          ) : (
            <>
              <div className="flex flex-wrap items-start justify-between gap-2">
                <div className="min-w-0">
                  <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--color-primary)]">
                    Advisory{detail.region && detail.region !== 'Unclassified' ? ` · ${detail.region}` : ''}
                  </p>
                  {detail.region === 'Unclassified' && (
                    <div className="mt-1 flex flex-wrap items-center gap-2">
                      <span className="text-[11px] text-yellow-700">Region not detected —</span>
                      <RegionPicker advisoryId={detail.id} current={detail.region} />
                    </div>
                  )}
                  <h2 className="mt-1 text-base font-semibold leading-snug cw-text-default">{detail.title}</h2>
                  <div className="mt-2 flex flex-wrap items-center gap-2">
                    <SeverityBadge severity={detail.severity} />
                    <StatusBadge status={detail.status} />
                    {detail.url && (
                      <a href={detail.url} target="_blank" rel="noopener noreferrer"
                        className="inline-flex items-center gap-1 text-[11px] font-medium text-[var(--color-primary)] hover:underline">
                        <ExternalLink size={12} /> Source
                      </a>
                    )}
                  </div>
                </div>
                {detail.status === 'pending' && (
                  <button onClick={() => router.push(`/advisories/${detail.id}`)} className="btn-primary flex shrink-0 items-center gap-2 text-sm">
                    Review &amp; confirm
                  </button>
                )}
              </div>

              {detail.summary && <div className="mt-3"><RichText text={detail.summary} /></div>}

              <section className="mt-3">
                <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
                  <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-subtle)] px-3 py-2"
                    title="Assets found to run the affected software (or confirmed by a scan), and how many were affected.">
                    <p className="text-xl font-semibold leading-tight cw-text-default">{detail.asset_affected_count}<span className="text-sm cw-text-muted"> / {detail.asset_total_count}</span></p>
                    <p className="mt-0.5 text-[11px] cw-text-muted">Assets affected / checked</p>
                  </div>
                  <div className="rounded-lg border border-[var(--color-border)] bg-[var(--color-subtle)] px-3 py-2">
                    <p className="text-xl font-semibold leading-tight cw-text-default">{detail.cve_count}</p>
                    <p className="mt-0.5 text-[11px] cw-text-muted">CVEs</p>
                  </div>
                </div>
              </section>

              <section className="mt-3">
                <h3 className="mb-2 text-sm font-semibold cw-text-default">Details</h3>
                <div className="overflow-hidden rounded-lg border border-[var(--color-border)]">
                  <table className="w-full text-xs">
                    <tbody>
                      {([
                        ['Published', fmtDate(detail.published_at), detail.origin === 'upload' && !detail.published_at ? 'No date stated in the document' : ''],
                        ['Last updated', fmtDate(detail.updated_at), ''],
                        [detail.origin === 'upload' ? 'Uploaded' : 'Ingested', fmtDate(detail.created_at), ''],
                        ['External ID', detail.external_id || '—', ''],
                        ['Source', sourceLabel(detail), ''],
                        ['Region', detail.region || 'Unclassified', ''],
                      ] as [string, string, string][]).map(([k, v, hint]) => (
                        <tr key={k} className="border-b border-[var(--color-border)] last:border-0">
                          <th scope="row" className="w-32 bg-[var(--color-primary)] px-3 py-1.5 text-left font-bold text-white">{k}</th>
                          <td className="px-3 py-1.5 cw-text-default">{hint || v}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </section>

              {detail.flow && (
                <section className="mt-3">
                  <h3 className="mb-2 text-sm font-semibold cw-text-default">Lifecycle</h3>
                  <FlowStrip flow={detail.flow} />
                </section>
              )}

              {/* Timeline sits high — right under Lifecycle — so it is reachable
                  without scrolling past the (possibly long) CVE list below. */}
              {detail.history && detail.history.length > 0 && (
                <section className="mt-3"><HistoryTimeline events={detail.history} /></section>
              )}

              {detail.status === 'pending' && (
                <p className="mt-3 rounded-lg bg-yellow-50 px-3 py-2 text-xs text-yellow-700">
                  Extracted and awaiting review — open <span className="font-medium">Review &amp; confirm</span> to check the CVEs and the parsing report before it is tracked.
                </p>
              )}

              {detail.status !== 'pending' && (
                <section className="mt-3">
                  <h3 className="text-sm font-semibold cw-text-default">Vulnerabilities in this advisory</h3>
                  <p className="mb-2 mt-0.5 text-[11px] cw-text-muted">
                    Tick any CVEs to add them to the match selection, or click a CVE for its full register details.
                  </p>
                  <div className="space-y-2">
                    {(detail.cves ?? []).length === 0
                      ? <p className="text-xs cw-text-muted">No CVEs on this advisory.</p>
                      : (detail.cves ?? []).map((cve) => (
                        <VulnCard key={cve.id} cve={cve}
                          selected={selCve.has(cve.id)} onToggleSelect={() => toggleCve(cve.id)} />
                      ))}
                  </div>
                </section>
              )}
            </>
          )}
        </div>
      </div>
      </>
      )}

      {sourcesOpen && (
        <div className="fixed inset-0 z-50 flex justify-end">
          <div className="absolute inset-0 bg-black/30" onClick={() => setSourcesOpen(false)} />
          <div className="relative flex h-full w-full max-w-md flex-col overflow-hidden bg-[var(--color-surface)] shadow-xl">
            <div className="flex items-center justify-between bg-[var(--color-primary)] px-5 py-4 text-white">
              <h2 className="flex items-center gap-2 text-base font-bold"><Database size={18} /> Sources</h2>
              <button onClick={() => setSourcesOpen(false)} className="rounded p-1 hover:bg-white/20"><X size={18} /></button>
            </div>

            <div className="flex-1 overflow-y-auto p-5">
              <div>
                <h3 className="text-base font-bold cw-text-default">Sync public feeds</h3>
                <p className="mt-0.5 mb-3 text-xs cw-text-muted">
                  Pick one or more feeds and sync their latest advisories — no upload needed.
                </p>
                <div className="space-y-1.5">
                  {apiSources.map((s) => {
                    const on = feedKeys.has(s.key);
                    return (
                      <label key={s.key}
                        className="flex cursor-pointer items-center gap-2 rounded-md border border-[var(--color-border)] px-3 py-2 text-sm hover:bg-[var(--color-hover)]">
                        <input type="checkbox" checked={on}
                          onChange={() => setFeedKeys((prev) => {
                            const n = new Set(prev);
                            if (on) n.delete(s.key); else n.add(s.key);
                            return n;
                          })} />
                        <span className="min-w-0 flex-1 truncate cw-text-default">{s.name}</span>
                        {s.region && <span className="shrink-0 text-xs cw-text-muted">{s.region}</span>}
                      </label>
                    );
                  })}
                </div>
                <button onClick={() => syncMutation.mutate(Array.from(feedKeys))}
                  disabled={syncMutation.isPending || feedKeys.size === 0}
                  className="btn-secondary mt-3 flex items-center gap-1.5">
                  {syncMutation.isPending ? <Loader2 size={14} className="animate-spin" /> : <RefreshCw size={14} />}
                  Sync{feedKeys.size > 0 ? ` (${feedKeys.size})` : ''}
                </button>
                {syncMsg && <p className={`mt-2 text-xs ${syncMsg.ok ? 'text-green-700' : 'text-yellow-700'}`}>{syncMsg.text}</p>}
              </div>

              <div className="mt-5">
                <h3 className="text-base font-bold cw-text-default">Upload a PDF</h3>
                <p className="mt-0.5 text-xs cw-text-muted">
                  For an advisory with no public feed — any CERT or vendor, any country. Same parser; it auto-detects the region.
                </p>
                {uploadedDocs.length > 0 && (
                  <div className="mt-3">
                    <p className="mb-1 text-[11px] font-semibold uppercase tracking-wider cw-text-muted">Your uploads ({uploadedDocs.length})</p>
                    <div className="max-h-56 space-y-1 overflow-y-auto">
                      {uploadedDocs.map((a) => (
                        <button key={a.id} onClick={() => { setSelectedId(a.id); setSourcesOpen(false); }}
                          className="flex w-full items-center gap-2 rounded-md border border-[var(--color-border)] px-2.5 py-1.5 text-left text-xs hover:bg-[var(--color-hover)]">
                          <span className="min-w-0 flex-1 truncate cw-text-default">{a.title}</span>
                          <span className="shrink-0 cw-text-muted">{a.region}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            </div>

            <div className="border-t border-[var(--color-border)] p-4">
              <button onClick={() => { setSourcesOpen(false); fileInputRef.current?.click(); }}
                className="btn-primary flex w-full items-center justify-center gap-2">
                <Upload size={16} /> Upload advisory PDF
              </button>
            </div>
          </div>
        </div>
      )}

      {affectedOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          <div className="absolute inset-0 bg-black/30" onClick={() => setAffectedOpen(false)} />
          <div className="relative flex max-h-[80vh] w-full max-w-2xl flex-col overflow-hidden rounded-xl bg-[var(--color-surface)] shadow-xl">
            <div className="flex items-center justify-between bg-[var(--color-primary)] px-5 py-4 text-white">
              <h2 className="flex items-center gap-2 text-base font-bold"><Server size={18} /> Affected assets</h2>
              <button onClick={() => setAffectedOpen(false)} className="rounded p-1 hover:bg-white/20"><X size={18} /></button>
            </div>
            <div className="flex-1 overflow-y-auto p-5">
              {!affectedData ? (
                <div className="flex justify-center py-10"><Loader2 className="animate-spin cw-text-muted" /></div>
              ) : affectedData.assets.length === 0 ? (
                <div className="py-10 text-center cw-text-muted">
                  <Server className="mx-auto mb-3 h-10 w-10" />
                  <p>No assets are affected yet.</p>
                  <p className="mt-1 text-xs">Advisories match against your inventory on re-check; affected assets show up here.</p>
                </div>
              ) : (
                <ul className="space-y-3">
                  {affectedData.assets.map((a) => (
                    <li key={a.asset_id} className="rounded-lg border border-[var(--color-border)] p-4">
                      <div className="flex items-center justify-between gap-2">
                        <p className="font-medium cw-text-default">{a.asset_name}{a.host ? <span className="cw-text-muted"> · {a.host}</span> : null}</p>
                        <span className="text-xs cw-text-muted">{a.items.length} finding{a.items.length === 1 ? '' : 's'}</span>
                      </div>
                      <div className="mt-2 flex flex-wrap gap-1.5">
                        {a.items.map((it, i) => (
                          <button key={i} onClick={() => { setAffectedOpen(false); router.push(`/advisories/${it.advisory_id}`); }}
                            title={it.advisory_title}
                            className="inline-flex items-center rounded-md bg-red-50 px-2 py-0.5 text-xs font-medium text-red-600 hover:bg-red-100">
                            {it.cve_id}
                          </button>
                        ))}
                      </div>
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
