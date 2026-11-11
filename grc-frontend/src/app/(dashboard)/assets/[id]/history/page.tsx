'use client';

/*
 * Dedicated per-asset change-history page (/assets/[id]/history). Same page
 * edges as the rest of the app (no own background, no max-width box) and a
 * one-line header, so the history fills the screen. Body = ChangeHistory
 * (KPI strip, category toggle pages, filters, timeline, Insights), shared with
 * the asset "History" tab. Reached from the inventory "Changes" column and
 * Inventory → Asset history.
 */

import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft } from 'lucide-react';
import apiClient from '@/lib/api';
import ChangeHistory from '../_components/change-history/ChangeHistory';

type AssetHead = { name?: string; asset_type?: string; ip_address?: string; host_name?: string; criticality?: string };

const CRIT: Record<string, [string, string]> = {
  critical: ['#FBEAEA', '#A32B2B'], high: ['#FBF2DF', '#8A5A0C'], medium: ['#EFF5FA', '#014A81'], low: ['#E7F5EE', '#186A49'],
};
const MONO = "font-['IBM_Plex_Mono',ui-monospace,monospace]";

function Fact({ children, mono }: { children: React.ReactNode; mono?: boolean }) {
  return (
    <span className={`inline-flex items-center h-[22px] rounded-[6px] px-2 text-[11.5px] bg-white ${mono ? MONO : 'capitalize'}`}
      style={{ border: '1px solid #E8ECEE', color: '#3A4653' }}>{children}</span>
  );
}

export default function AssetHistoryPage() {
  const params = useParams();
  const assetId = Number(params?.id);
  const valid = Number.isInteger(assetId) && assetId > 0;

  const { data: asset } = useQuery({
    queryKey: ['asset', assetId, 'head'],
    queryFn: async () => (await apiClient.get<AssetHead>(`/assets/${assetId}`)).data,
    enabled: valid,
  });
  const crit = asset?.criticality?.toLowerCase();
  // The host name often repeats the asset name; show it only when it adds something.
  const host = asset?.host_name && asset.host_name !== asset.name ? asset.host_name : null;

  return (
    <div className="px-3 sm:px-4 pt-1 pb-4 font-['Poppins',system-ui,sans-serif]">
      <header className="mb-2.5 flex flex-wrap items-center gap-x-2.5 gap-y-1.5 min-w-0">
        <Link href={`/assets/${assetId}`} aria-label="Back to asset" title="Back to asset"
          className="flex h-7 w-7 items-center justify-center rounded-[8px] text-[#5F6A76] hover:bg-white hover:text-[#005B96] focus-visible:outline focus-visible:outline-2 focus-visible:outline-[#19A8E6]">
          <ArrowLeft className="h-4 w-4" aria-hidden />
        </Link>
        <h1 className="text-[18px] font-semibold leading-tight tracking-[-0.015em] text-[#0F1F2B] break-words min-w-0">
          <span className="font-normal text-[#5F6A76]">Change history · </span>
          {asset?.name || (valid ? `Asset ${assetId}` : 'Asset')}
        </h1>
        <div className="flex flex-wrap items-center gap-1.5">
          {asset?.asset_type && <Fact>{asset.asset_type}</Fact>}
          {host && <Fact mono>{host}</Fact>}
          {asset?.ip_address && <Fact mono>{asset.ip_address}</Fact>}
          {crit && (
            <span className="inline-flex items-center h-[22px] rounded-[6px] px-2 text-[11.5px] font-semibold"
              style={{ background: CRIT[crit]?.[0] ?? '#F1F4F6', color: CRIT[crit]?.[1] ?? '#3A4653' }}>
              {crit[0].toUpperCase() + crit.slice(1)} criticality
            </span>
          )}
        </div>
      </header>
      {valid
        ? <ChangeHistory assetId={assetId} variant="page" />
        : <p className="text-[13px] text-[#5F6A76]">This asset link is not valid.</p>}
    </div>
  );
}
