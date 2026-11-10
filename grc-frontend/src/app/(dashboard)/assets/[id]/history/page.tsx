'use client';

/*
 * Dedicated per-asset change-history page (/assets/[id]/history).
 *
 * Full-width field-level change timeline for one asset: what changed, old→new,
 * when, who, and the source (manual edit / scan / network discovery / connector
 * / agent). Reuses the same HistoryPanel that backs the asset "History" tab, so
 * there is one timeline implementation, not two. Reached from the inventory
 * register's "Changes" column and from the asset page.
 */

import { useParams, useRouter } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, Clock } from 'lucide-react';
import apiClient from '@/lib/api';
import HistoryPanel from '../_tabs/HistoryPanel';

export default function AssetHistoryPage() {
  const params = useParams();
  const router = useRouter();
  const assetId = Number(params?.id);
  const valid = Number.isFinite(assetId);

  const { data: asset } = useQuery({
    queryKey: ['asset', assetId, 'name'],
    queryFn: async () => {
      try { return (await apiClient.get<{ name?: string }>(`/assets/${assetId}`)).data; }
      catch { return null; }
    },
    enabled: valid,
  });
  const name = asset?.name || `Asset #${assetId}`;

  return (
    <div className="mx-auto max-w-4xl px-4 py-6 space-y-4">
      <button
        type="button"
        onClick={() => router.push(`/assets/${assetId}`)}
        className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-[#005B96]"
      >
        <ArrowLeft className="h-4 w-4" /> Back to asset
      </button>

      <div className="flex items-start gap-2.5">
        <Clock className="h-5 w-5 mt-0.5 shrink-0" style={{ color: '#005B96' }} strokeWidth={1.8} />
        <div className="min-w-0">
          <h1 className="text-lg font-semibold" style={{ color: '#0F1F2B' }}>Change history</h1>
          <p className="text-xs text-slate-500 truncate">
            {name} — every field-level change, who made it, and the source.
          </p>
        </div>
      </div>

      {valid && <HistoryPanel entityType="asset" entityId={assetId} />}
    </div>
  );
}
