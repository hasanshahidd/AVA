'use client';

/*
 * Dedicated per-asset change-history page (/assets/[id]/history): full-width
 * filterable timeline of every field-level change plus a summary rail. Shares
 * ChangeHistory with the asset "History" tab. Reached from the inventory
 * register's "Changes" column.
 */

import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, History } from 'lucide-react';
import apiClient from '@/lib/api';
import ChangeHistory from '../_components/change-history/ChangeHistory';

type AssetHead = { name?: string; asset_type?: string; ip_address?: string; host_name?: string; criticality?: string };

export default function AssetHistoryPage() {
  const params = useParams();
  const assetId = Number(params?.id);
  const valid = Number.isInteger(assetId) && assetId > 0;

  const { data: asset } = useQuery({
    queryKey: ['asset', assetId, 'head'],
    queryFn: async () => (await apiClient.get<AssetHead>(`/assets/${assetId}`)).data,
    enabled: valid,
  });
  const facts = [asset?.asset_type, asset?.host_name, asset?.ip_address, asset?.criticality && `${asset.criticality} criticality`]
    .filter(Boolean) as string[];

  return (
    <div className="min-h-full bg-[#F7F9FB] px-4 sm:px-6 py-5 font-['Poppins',system-ui,sans-serif]">
      <div className="mb-4">
        <Link href={`/assets/${assetId}`} className="inline-flex items-center gap-1.5 text-[12.5px] text-slate-500 hover:text-[#005B96]">
          <ArrowLeft className="h-4 w-4" aria-hidden /> Back to asset
        </Link>
        <div className="mt-2 flex items-start gap-3">
          <span className="flex h-10 w-10 items-center justify-center rounded-[11px] flex-none" style={{ background: '#005B9614' }}>
            <History className="h-5 w-5" style={{ color: '#005B96' }} strokeWidth={1.9} aria-hidden />
          </span>
          <div className="min-w-0">
            <h1 className="text-[20px] font-semibold leading-tight text-[#0F1F2B] truncate">
              Change history{asset?.name ? ` · ${asset.name}` : ''}
            </h1>
            {facts.length > 0 && (
              <p className="text-[12.5px] text-slate-500 mt-0.5 truncate">{facts.join(' · ')}</p>
            )}
          </div>
        </div>
      </div>
      {valid
        ? <ChangeHistory assetId={assetId} variant="page" />
        : <p className="text-[13px] text-slate-500">This asset link is not valid.</p>}
    </div>
  );
}
