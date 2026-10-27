'use client';

import { PageLoader } from '@/components/ui';
import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { advisoriesApi } from '@/lib/api';
import {
  AlertCircle, ArrowLeft, ExternalLink, Loader2, Plus, Trash2, CheckCircle2,
} from 'lucide-react';
import {
  AdvisoryView,
  SeverityBadge,
  StatusBadge,
  ExtractionPipeline,
  FlowStrip,
  HistoryTimeline,
  RichText,
  VulnCard,
  MatchScopeControl,
  RecheckScope,
  RegionPicker,
} from '../_components/ui';

interface EditableCve {
  cve_id: string;
  affected_product: string;
  affected_versions: string;
}

const SEVERITIES = ['critical', 'high', 'medium', 'low', 'info'];

export default function AdvisoryDetailPage() {
  const params = useParams();
  const router = useRouter();
  const queryClient = useQueryClient();
  const id = Number(params?.id);

  const { data: advisory, isLoading, error } = useQuery({
    queryKey: ['advisory', id],
    queryFn: async () => {
      const response = await advisoriesApi.getById(id);
      return response.data as AdvisoryView;
    },
    enabled: Number.isFinite(id),
  });

  const isPending = advisory?.status === 'pending';

  const [reviewCves, setReviewCves] = useState<EditableCve[]>([]);
  const [severity, setSeverity] = useState('critical');

  // Seed the review editor from the extracted CVEs once the pending advisory loads.
  useEffect(() => {
    if (advisory && isPending) {
      setReviewCves(
        (advisory.cves ?? []).map((c) => ({
          cve_id: c.cve_id,
          affected_product: c.affected_product ?? '',
          affected_versions: c.affected_versions ?? '',
        })),
      );
      setSeverity(advisory.severity || 'critical');
    }
  }, [advisory, isPending]);

  const recheckMutation = useMutation({
    mutationFn: (scope: RecheckScope) => advisoriesApi.recheck(id, scope),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['advisory', id] });
      queryClient.invalidateQueries({ queryKey: ['advisories'] });
    },
  });

  const confirmMutation = useMutation({
    mutationFn: () =>
      advisoriesApi.confirm(id, {
        severity,
        cves: reviewCves
          .filter((c) => c.cve_id.trim())
          .map((c) => ({
            cve_id: c.cve_id.trim(),
            affected_product: c.affected_product.trim() || undefined,
            affected_versions: c.affected_versions.trim() || undefined,
          })),
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['advisory', id] });
      queryClient.invalidateQueries({ queryKey: ['advisories'] });
    },
  });

  const updateCve = (idx: number, field: keyof EditableCve, value: string) => {
    setReviewCves((prev) => prev.map((c, i) => (i === idx ? { ...c, [field]: value } : c)));
  };

  if (isLoading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <PageLoader size="md" />
      </div>
    );
  }

  if (error || !advisory) {
    return (
      <div className="rounded-xl border border-red-700 bg-red-900/20 p-6 text-center">
        <AlertCircle className="mx-auto h-8 w-8 text-red-600" />
        <p className="mt-2 text-red-600">Advisory not found</p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <button
        onClick={() => router.push('/advisories')}
        className="flex items-center gap-1 text-sm cw-text-muted hover:cw-text-default"
      >
        <ArrowLeft size={16} /> Advisories
      </button>

      <div className="cw-card p-5">
        <div className="flex flex-wrap items-start justify-between gap-3">
          <div>
            <p className="text-[11px] font-semibold uppercase tracking-wider text-[var(--color-primary)]">
              Advisory{advisory.region && advisory.region !== 'Unclassified' ? ` · ${advisory.region}` : ''}
            </p>
            {advisory.region === 'Unclassified' && (
              <div className="mt-1 flex flex-wrap items-center gap-2">
                <span className="text-xs text-yellow-700">Region not detected —</span>
                <RegionPicker advisoryId={advisory.id} current={advisory.region} />
              </div>
            )}
            <div className="mt-0.5 flex flex-wrap items-center gap-2">
              <h1 className="text-xl font-bold cw-text-default">{advisory.title}</h1>
              <SeverityBadge severity={advisory.severity} />
              <StatusBadge status={advisory.status} />
            </div>
            <p className="text-xs cw-text-muted mt-1">
              {advisory.external_id || '—'}
              {advisory.source_name ? ` · ${advisory.source_name}` : ''}
            </p>
            {advisory.flow && <div className="mt-3"><FlowStrip flow={advisory.flow} /></div>}
          </div>
        </div>

        {advisory.summary && <div className="mt-3"><RichText text={advisory.summary} /></div>}

        {!isPending && (
          <div className="mt-4 flex flex-wrap items-center gap-6">
            <div>
              <p className="text-2xl font-bold cw-text-default">
                {advisory.asset_affected_count}
                <span className="text-sm cw-text-muted"> / {advisory.asset_total_count}</span>
              </p>
              <p className="text-xs cw-text-muted">assets affected (of those running the software)</p>
            </div>
            <div>
              <p className="text-2xl font-bold cw-text-default">{advisory.cve_count}</p>
              <p className="text-xs cw-text-muted">CVEs</p>
            </div>
            {advisory.url && (
              <a href={advisory.url} target="_blank" rel="noopener noreferrer"
                className="flex items-center gap-1 text-sm text-[var(--color-primary)] hover:underline">
                <ExternalLink size={14} /> Source
              </a>
            )}
          </div>
        )}
      </div>

      {advisory.extraction && <ExtractionPipeline report={advisory.extraction} />}

      {isPending ? (
        <div className="cw-card p-5 space-y-3">
          <div className="flex items-center gap-2">
            <AlertCircle size={18} className="text-yellow-600" />
            <h2 className="text-sm font-semibold cw-text-default">Review extracted CVEs</h2>
          </div>
          <p className="text-xs cw-text-muted">
            These CVEs were read from the document by the multi-stage parser (see the pipeline above —
            the vision stage recovers CVEs the text layer misses in tables). Check them, fill in product
            and versions, then confirm to start tracking and matching against your assets.
          </p>

          <div className="flex items-center gap-3">
            <label className="text-xs font-semibold cw-text-muted">Severity</label>
            <select
              value={severity}
              onChange={(e) => setSeverity(e.target.value)}
              className="rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-1.5 text-sm cw-text-default"
            >
              {SEVERITIES.map((s) => (<option key={s} value={s}>{s}</option>))}
            </select>
          </div>

          <div className="space-y-2">
            {reviewCves.map((c, idx) => (
              <div key={idx} className="flex items-center gap-2">
                <input
                  value={c.cve_id}
                  onChange={(e) => updateCve(idx, 'cve_id', e.target.value)}
                  placeholder="CVE-0000-0000"
                  className="w-48 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2 text-sm font-mono cw-text-default"
                />
                <input
                  value={c.affected_product}
                  onChange={(e) => updateCve(idx, 'affected_product', e.target.value)}
                  placeholder="product (e.g. php)"
                  className="flex-1 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2 text-sm cw-text-default"
                />
                <input
                  value={c.affected_versions}
                  onChange={(e) => updateCve(idx, 'affected_versions', e.target.value)}
                  placeholder="versions (e.g. < 8.2.35)"
                  className="flex-1 rounded-lg border border-[var(--color-border)] bg-[var(--color-surface)] px-3 py-2 text-sm cw-text-default"
                />
                <button
                  onClick={() => setReviewCves((prev) => prev.filter((_, i) => i !== idx))}
                  className="p-2 rounded-lg cw-text-muted hover:text-red-600 hover:bg-[var(--color-hover)]"
                  title="Remove"
                >
                  <Trash2 size={16} />
                </button>
              </div>
            ))}
            <button
              onClick={() => setReviewCves((prev) => [...prev, { cve_id: '', affected_product: '', affected_versions: '' }])}
              className="btn-secondary flex items-center gap-1 text-xs"
            >
              <Plus size={14} /> Add CVE
            </button>
          </div>

          <div className="flex justify-end pt-2">
            <button
              onClick={() => confirmMutation.mutate()}
              disabled={confirmMutation.isPending || !reviewCves.some((c) => c.cve_id.trim())}
              className="btn-primary flex items-center gap-2"
            >
              {confirmMutation.isPending ? <Loader2 size={16} className="animate-spin" /> : <CheckCircle2 size={16} />}
              Confirm &amp; track
            </button>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          <MatchScopeControl onRecheck={(s) => recheckMutation.mutate(s)} isPending={recheckMutation.isPending} />
          <div>
            <h2 className="text-sm font-semibold cw-text-default">Vulnerabilities in this advisory</h2>
            <p className="text-xs cw-text-muted">
              The CVEs this advisory warns about — each is tracked in your vulnerability register and matched against your assets. Click one for its full details.
            </p>
          </div>
          {(advisory.cves ?? []).length === 0 ? (
            <p className="text-sm cw-text-muted">No CVEs on this advisory.</p>
          ) : (
            (advisory.cves ?? []).map((cve) => <VulnCard key={cve.id} cve={cve} />)
          )}
        </div>
      )}

      {advisory.history && advisory.history.length > 0 && (
        <HistoryTimeline events={advisory.history} />
      )}
    </div>
  );
}
