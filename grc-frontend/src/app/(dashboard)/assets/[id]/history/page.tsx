'use client';

/*
 * Dedicated per-asset change-history page (/assets/[id]/history): asset header,
 * then the full ChangeHistory (KPI strip, filters, timeline, Insights). Shares
 * ChangeHistory with the asset "History" tab. Reached from the inventory
 * register's "Changes" column and from Inventory → Asset history.
 */

import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { ArrowLeft, History } from 'lucide-react';
import apiClient from '@/lib/api';
import ChangeHistory from '../_components/change-history/ChangeHistory';

type AssetHead = { name?: string; asset_type?: string; ip_address?: string; host_name?: string; criticality?: string };

const CRIT: Record<string, [string, string]> = {
  critical: ['#FBEAEA', '#A32B2B'], high: ['#FBF2DF', '#8A5A0C'], medium: ['#EFF5FA', '#014A81'], low: ['#E7F5EE', '#186A49'],
};
const MONO = "font-['IBM_Plex_Mono',ui-monospace,monospace]";

function Fact({ children, mono }: { children: React.ReactNode; mono?: boolean }) {
  return (
    <span className={`inline-flex items-center h-[24px] rounded-[7px] px-2 text-[11.5px] bg-white ${mono ? MONO : 'capitalize'}`}
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

  return (
    <div className="min-h-full bg-[#F4F6F7] px-4 sm:px-6 py-5 font-['Poppins',system-ui,sans-serif]">
      <div className="max-w-[1320px] mx-auto">
        <Link href={`/assets/${assetId}`}
          className="inline-flex items-center gap-1.5 text-[12.5px] rounded-[6px] text-[#5F6A76] hover:text-[#005B96] focus-visible:outline focus-visible:outline-2 focus-visible:outline-[#19A8E6]">
          <ArrowLeft className="h-4 w-4" aria-hidden /> Back to asset
        </Link>
        <header className="mt-2 mb-4 flex items-start gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-[12px] flex-none bg-white"
            style={{ border: '1px solid #E8ECEE' }}>
            <History className="h-5 w-5" style={{ color: '#005B96' }} strokeWidth={1.9} aria-hidden />
          </span>
          <div className="min-w-0">
            <p className="text-[12px] text-[#5F6A76]">Change history</p>
            <h1 className="text-[20px] font-semibold leading-tight tracking-[-0.015em] text-[#0F1F2B] break-words">
              {asset?.name || (valid ? `Asset ${assetId}` : 'Asset')}
            </h1>
            <div className="mt-1.5 flex flex-wrap gap-1.5">
              {asset?.asset_type && <Fact>{asset.asset_type}</Fact>}
              {asset?.host_name && <Fact mono>{asset.host_name}</Fact>}
              {asset?.ip_address && <Fact mono>{asset.ip_address}</Fact>}
              {crit && (
                <span className="inline-flex items-center h-[24px] rounded-[7px] px-2 text-[11.5px] font-semibold"
                  style={{ background: CRIT[crit]?.[0] ?? '#F1F4F6', color: CRIT[crit]?.[1] ?? '#3A4653' }}>
                  {crit[0].toUpperCase() + crit.slice(1)} criticality
                </span>
              )}
            </div>
          </div>
        </header>
        {valid
          ? <ChangeHistory assetId={assetId} variant="page" />
          : <p className="text-[13px] text-[#5F6A76]">This asset link is not valid.</p>}
      </div>
    </div>
  );
}
