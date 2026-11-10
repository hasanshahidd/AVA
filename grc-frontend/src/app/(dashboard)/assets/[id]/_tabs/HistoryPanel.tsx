'use client';

/*
 * Asset-detail "History" tab. Same change journal and query key as the full
 * /assets/[id]/history page, in its single-column tab layout.
 */

import Link from 'next/link';
import { ExternalLink } from 'lucide-react';
import ChangeHistory from '../_components/change-history/ChangeHistory';

export default function HistoryPanel({ entityId }: { entityType: 'asset'; entityId: number }) {
  return (
    <div className="font-['Poppins',system-ui,sans-serif] space-y-2">
      <div className="flex justify-end">
        <Link href={`/assets/${entityId}/history`}
          className="inline-flex items-center gap-1 text-[12px] font-semibold text-[#005B96] hover:underline">
          Open full history <ExternalLink className="h-3.5 w-3.5" aria-hidden />
        </Link>
      </div>
      <ChangeHistory assetId={entityId} variant="tab" />
    </div>
  );
}
