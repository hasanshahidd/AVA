'use client';

/*
 * Insights card beside the timeline: 30-day activity, where changes come from
 * (each source is a filter toggle) and the most-changed fields (each one
 * searches the timeline). One quiet card, not a stack of bar panels; the
 * headline numbers live in the KPI strip above.
 */

import type { ReactNode } from 'react';
import {
  BRAND, DIVIDER, INK, MUTED, SEC, type Filters, type Summary, sourceMeta,
} from './model';

function Block({ title, meta, children, first }: { title: string; meta?: string; children: ReactNode; first?: boolean }) {
  return (
    <section className={first ? '' : 'pt-3 mt-3'} style={first ? undefined : { borderTop: `1px solid ${DIVIDER}` }}>
      <div className="flex items-baseline justify-between gap-2 mb-1.5">
        <h3 className="text-[12.5px] font-semibold" style={{ color: INK }}>{title}</h3>
        {meta && <span className="text-[11px]" style={{ color: MUTED }}>{meta}</span>}
      </div>
      {children}
    </section>
  );
}

function ListButton({ on, dot, label, count, onClick }: {
  on?: boolean; dot?: string; label: string; count: number; onClick: () => void;
}) {
  return (
    <li>
      <button type="button" onClick={onClick} aria-pressed={on}
        className="w-full flex items-center gap-2 rounded-[8px] px-2 py-[5px] -mx-2 text-left text-[12px] transition-colors hover:bg-[#F4F6F7] focus-visible:outline focus-visible:outline-2 focus-visible:outline-[#19A8E6]"
        style={on ? { background: '#EFF5FA', color: '#014A81', fontWeight: 600 } : { color: SEC }}>
        {dot && <span className="h-[7px] w-[7px] rounded-full flex-none" style={{ background: dot }} aria-hidden />}
        <span className="truncate flex-1 min-w-0">{label}</span>
        <span className="tabular-nums font-semibold" style={{ color: on ? '#014A81' : INK }}>{count}</span>
      </button>
    </li>
  );
}

export default function SummaryRail({ summary, filters, onFilter }: {
  summary: Summary; filters: Filters; onFilter: (patch: Partial<Filters>) => void;
}) {
  const s = summary;
  const max = Math.max(1, ...s.daily.map((d) => d.count));
  const active = s.daily.filter((d) => d.count).length;
  return (
    <div className="rounded-[14px] bg-white p-4" style={{ border: '1px solid #E8ECEE', boxShadow: '0 1px 2px rgba(16,24,40,.04)' }}>
      <Block first title="Activity" meta="Last 30 days">
        <div className="flex items-end gap-[2px] h-[40px]" role="img"
          aria-label={`Changes on ${active} of the last ${s.daily.length} days`}>
          {s.daily.map((d) => (
            <div key={d.key} className="flex-1 rounded-[2px]" title={`${d.label}: ${d.count}`}
              style={{ height: `${d.count ? Math.max(14, (d.count / max) * 100) : 6}%`, background: d.count ? BRAND : '#E6EBEF' }} />
          ))}
        </div>
        <div className="flex justify-between text-[10.5px] mt-1" style={{ color: MUTED }}>
          <span>{s.daily[0]?.label}</span><span>Today</span>
        </div>
      </Block>
      <Block title="Sources">
        <ul>
          {s.bySource.map(([k, n]) => (
            <ListButton key={k} on={filters.source === k} dot={sourceMeta(k).color} label={sourceMeta(k).label} count={n}
              onClick={() => onFilter({ source: filters.source === k ? 'all' : k })} />
          ))}
        </ul>
      </Block>
      {s.topFields.length > 0 && (
        <Block title="Most changed">
          <ul>
            {s.topFields.slice(0, 5).map(([k, n]) => (
              <ListButton key={k} on={filters.query === k} label={k} count={n}
                onClick={() => onFilter({ query: filters.query === k ? '' : k })} />
            ))}
          </ul>
        </Block>
      )}
    </div>
  );
}
