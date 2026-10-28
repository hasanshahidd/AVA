'use client';

import { PageLoader } from '@/components/ui';
import { useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { advisoriesApi } from '@/lib/api';
import {
  AlertCircle, Upload, Loader2, RefreshCw, ExternalLink, ShieldAlert,
  Database, X, ChevronDown, ChevronRight, Server,
} from 'lucide-react';
import {
  AdvisoryView, AdvisoryListResponse,
  SeverityBadge, StatusBadge, RichText, VulnCard, MatchScopeControl, RecheckScope, RegionPicker,
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
    <label className="flex items-center gap-1.5 text-xs cw-text-muted">
      {label}
      <select value={value} onChange={(e) => onChange(e.target.value)}
        className="rounded-md border border-[var(--color-border)] bg-transparent px-2 py-1 text-xs cw-text-default">
        <option value={ALL}>all</option>
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

  const recheckMutation = useMutation({
    mutationFn: (scope: RecheckScope) => advisoriesApi.recheck(selectedId as number, scope),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['advisory', selectedId] });
      queryClient.invalidateQueries({ queryKey: ['advisories'] });
      queryClient.invalidateQueries({ queryKey: ['advisory-affected-assets'] });
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
    () => Array.from(new Set(advisories.map((a) => a.source_name).filter(Boolean) as string[])).sort(),
    [advisories]);

  const filtered = useMemo(() => advisories.filter((a) =>
    (fRegion === ALL || a.region === fRegion) &&
    (fOrigin === ALL || (fOrigin === 'synced' ? a.origin === 'sync' : a.origin !== 'sync')) &&
    (fSource === ALL || a.source_name === fSource) &&
    (fSeverity === ALL || (a.severity || '').toLowerCase() === fSeverity) &&
    (fStatus === ALL || a.status === fStatus)
  ), [advisories, fRegion, fOrigin, fSource, fSeverity, fStatus]);

  // Group the filtered list by region, ordered by REGION_ORDER then name.
  const grouped = useMemo(() => {
    const map: Record<string, AdvisoryView[]> = {};
    for (const a of filtered) (map[a.region || 'Other'] ||= []).push(a);
    return Object.keys(map)
      .sort((x, y) => regionRank(x) - regionRank(y) || x.localeCompare(y))
      .map((region) => ({ region, items: map[region] }));
  }, [filtered]);

  // Keep the detail panel on a visible advisory.
  useEffect(() => {
    if (filtered.length === 0) return;
    if (selectedId === null || !filtered.some((a) => a.id === selectedId)) {
      setSelectedId(filtered[0].id);
    }
  }, [filtered, selectedId]);

  const toggleRegion = (region: string) =>
    setCollapsed((prev) => {
      const next = new Set(prev);
      if (next.has(region)) next.delete(region); else next.add(region);
      return next;
    });

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
      <div className="flex items-center justify-between gap-3">
        <div className="min-w-0">
          <h1 className="text-lg font-bold cw-text-default">Security advisories</h1>
          <p className="truncate text-xs cw-text-muted">CERT/vendor bulletins — each names the CVEs to check against your assets.</p>
        </div>
        <div className="flex shrink-0 gap-2">
          <input ref={fileInputRef} type="file" accept=".pdf" onChange={handleUpload} className="hidden" />
          <button onClick={() => setSourcesOpen(true)} className="btn-secondary flex items-center gap-2 text-sm">
            <Database size={15} /> Sources
          </button>
          <button onClick={() => fileInputRef.current?.click()} disabled={uploading} className="btn-primary flex items-center gap-2 text-sm">
            {uploading ? <Loader2 size={15} className="animate-spin" /> : <Upload size={15} />} Upload advisory
          </button>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {[
          { l: 'Advisories', v: summary.total ?? advisories.length, hint: 'show all',
            onClick: () => { setFStatus(ALL); setFRegion(ALL); setFSource(ALL); setFSeverity(ALL); setFOrigin(ALL); } },
          { l: 'Open', v: summary.open ?? 0, hint: 'filter open', onClick: () => setFStatus('open') },
          { l: 'Assets affected', v: affectedTotal, hint: 'see which', onClick: () => setAffectedOpen(true) },
          { l: 'Sources', v: sourceCount, hint: 'manage', onClick: () => setSourcesOpen(true) },
        ].map((k) => (
          <button key={k.l} onClick={k.onClick}
            className="cw-card p-3 text-left transition-colors hover:border-[var(--color-primary)]">
            <p className="text-xs cw-text-muted">{k.l}</p>
            <p className="mt-0.5 text-xl font-bold cw-text-default">{k.v}</p>
            <p className="mt-0.5 text-[11px] font-medium text-[var(--color-primary)]">{k.hint} →</p>
          </button>
        ))}
      </div>

      <div className="cw-card flex flex-wrap items-center gap-x-4 gap-y-2 p-3">
        <FilterSelect label="Origin" value={fOrigin} options={['uploaded', 'synced']} onChange={setFOrigin} />
        <FilterSelect label="Region" value={fRegion} options={regionOptions} onChange={setFRegion} />
        <FilterSelect label="Source" value={fSource} options={sourceOptions} onChange={setFSource} />
        <FilterSelect label="Severity" value={fSeverity} options={['critical', 'high', 'medium', 'low']} onChange={setFSeverity} />
        <FilterSelect label="Status" value={fStatus} options={['pending', 'open', 'resolved', 'not_applicable']} onChange={setFStatus} />
        <span className="ml-auto text-xs cw-text-muted">showing {filtered.length} of {advisories.length}</span>
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-[380px_1fr]">
        <div className="cw-card overflow-hidden">
          <p className="px-4 py-3 text-xs font-semibold uppercase tracking-wider cw-text-muted">By region</p>
          {filtered.length === 0 ? (
            <div className="px-4 py-12 text-center cw-text-muted">
              <ShieldAlert className="mx-auto mb-3 h-10 w-10" />
              <p>No advisories match these filters</p>
            </div>
          ) : (
            grouped.map(({ region, items }) => {
              const isCollapsed = collapsed.has(region);
              return (
                <div key={region}>
                  <button onClick={() => toggleRegion(region)}
                    className="flex w-full items-center gap-2 border-t border-[var(--color-border)] bg-[var(--color-subtle)] px-4 py-2 text-left">
                    {isCollapsed ? <ChevronRight size={14} /> : <ChevronDown size={14} />}
                    <span className="text-xs font-semibold uppercase tracking-wider cw-text-default">{region}</span>
                    <span className="ml-auto text-xs cw-text-muted">{items.length}</span>
                  </button>
                  {!isCollapsed && items.map((a) => (
                    <button key={a.id} onClick={() => setSelectedId(a.id)}
                      className={`flex w-full items-center gap-2 border-t border-[var(--color-border)] px-4 py-2.5 text-left transition-colors hover:bg-[var(--color-hover)] ${selectedId === a.id ? 'bg-[var(--color-subtle)]' : ''}`}>
                      <p className="min-w-0 flex-1 truncate text-sm font-medium cw-text-default">{a.title}</p>
                      <div className="ml-auto flex shrink-0 items-center gap-1.5">
                        {a.status === 'pending' ? (
                          <span className="rounded-md bg-yellow-50 px-1.5 py-0.5 text-[11px] font-medium text-yellow-700">review</span>
                        ) : a.asset_affected_count > 0 ? (
                          <span className="rounded-md bg-red-50 px-1.5 py-0.5 text-[11px] font-semibold text-red-600">{a.asset_affected_count} affected</span>
                        ) : null}
                        <SeverityBadge severity={a.severity} />
                      </div>
                    </button>
                  ))}
                </div>
              );
            })
          )}
        </div>

        <div className="cw-card p-4">
          {!detail ? (
            <p className="text-sm cw-text-muted">Select an advisory to see which assets are affected.</p>
          ) : (
            <>
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--color-primary)]">
                    Advisory{detail.region && detail.region !== 'Unclassified' ? ` · ${detail.region}` : ''}
                  </p>
                  {detail.region === 'Unclassified' && (
                    <div className="mt-1 flex flex-wrap items-center gap-2">
                      <span className="text-xs text-yellow-700">Region not detected —</span>
                      <RegionPicker advisoryId={detail.id} current={detail.region} />
                    </div>
                  )}
                  <div className="mt-0.5 flex flex-wrap items-center gap-2">
                    <h2 className="text-lg font-bold cw-text-default">{detail.title}</h2>
                    <SeverityBadge severity={detail.severity} />
                    <StatusBadge status={detail.status} />
                  </div>
                  <p className="mt-1 text-xs cw-text-muted">
                    {detail.external_id || '—'}{detail.source_name ? ` · ${detail.source_name}` : ''}
                  </p>
                </div>
                {detail.status === 'pending' && (
                  <button onClick={() => router.push(`/advisories/${detail.id}`)} className="btn-primary flex items-center gap-2">
                    Review &amp; confirm
                  </button>
                )}
              </div>

              {detail.summary && <div className="mt-3"><RichText text={detail.summary} /></div>}

              <div className="mt-4 flex flex-wrap items-end gap-8">
                <div title="Assets found to run the affected software (or confirmed by a scan), and how many were affected.">
                  <p className="text-xl font-bold cw-text-default">{detail.asset_affected_count}<span className="text-sm cw-text-muted"> / {detail.asset_total_count}</span></p>
                  <p className="text-xs cw-text-muted">assets affected / checked</p>
                </div>
                <div>
                  <p className="text-xl font-bold cw-text-default">{detail.cve_count}</p>
                  <p className="text-xs cw-text-muted">CVEs</p>
                </div>
                {detail.url && (
                  <a href={detail.url} target="_blank" rel="noopener noreferrer"
                    className="flex items-center gap-1 text-sm text-[var(--color-primary)] hover:underline">
                    <ExternalLink size={14} /> Source
                  </a>
                )}
              </div>

              {detail.status === 'pending' && (
                <p className="mt-4 rounded-lg bg-yellow-50 px-3 py-2 text-xs text-yellow-700">
                  Extracted and awaiting review — open <span className="font-medium">Review &amp; confirm</span> to check the CVEs and the parsing report before it is tracked.
                </p>
              )}

              {detail.status !== 'pending' && (
                <div className="mt-4">
                  <MatchScopeControl onRecheck={(s) => recheckMutation.mutate(s)} isPending={recheckMutation.isPending} />
                </div>
              )}

              {detail.status !== 'pending' && (
                <div className="mt-5">
                  <h3 className="text-sm font-semibold cw-text-default">Vulnerabilities in this advisory</h3>
                  <p className="mb-2 text-xs cw-text-muted">
                    The CVEs this advisory warns about. Each is tracked in your vulnerability register and matched against your assets — click one for its full details.
                  </p>
                  <div className="space-y-2">
                    {(detail.cves ?? []).length === 0
                      ? <p className="text-sm cw-text-muted">No CVEs on this advisory.</p>
                      : (detail.cves ?? []).map((cve) => <VulnCard key={cve.id} cve={cve} />)}
                  </div>
                </div>
              )}
            </>
          )}
        </div>
      </div>

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
                <button onClick={() => syncMutation.mutate([...feedKeys])}
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
