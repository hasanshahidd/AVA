'use client';

/*
 * At-a-glance summary of an asset's change journal: totals, date span,
 * 30-day activity, and breakdowns by source / category / contributor / field.
 * Breakdown rows are buttons that set the matching filter.
 */

import type { ReactNode } from 'react';
import {
  ACCENT, BORDER, BRAND, FAINT, INK, MUTED, SEC, type Filters, type Summary,
  categoryMeta, fieldLabel, fmtDate, sourceMeta,
} from './model';

const CARD = 'rounded-[12px] bg-white';
const cardStyle = { border: `1px solid ${BORDER}`, boxShadow: '0 1px 2px rgba(16,24,40,.04)' };

function Panel({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className={`${CARD} p-3.5`} style={cardStyle}>
      <h3 className="text-[10.5px] font-bold uppercase tracking-[0.06em] mb-2.5" style={{ color: FAINT }}>{title}</h3>
      {children}
    </section>
  );
}

function Stat({ label, value, sub }: { label: string; value: ReactNode; sub?: string }) {
  return (
    <div className="rounded-[10px] px-3 py-2.5" style={{ background: '#F5F8FA', border: `1px solid ${BORDER}` }}>
      <div className="text-[10px] font-semibold uppercase tracking-[0.05em]" style={{ color: MUTED }}>{label}</div>
      <div className="text-[19px] font-semibold leading-tight mt-0.5" style={{ color: INK }}>{value}</div>
      {sub && <div className="text-[10.5px] mt-0.5 truncate" style={{ color: MUTED }}>{sub}</div>}
    </div>
  );
}

function Bars({ rows, max, active, onPick }: {
  rows: { key: string; label: string; color: string; count: number }[];
  max: number; active: string; onPick?: (key: string) => void;
}) {
  if (!rows.length) return <p className="text-[12px]" style={{ color: FAINT }}>Nothing yet.</p>;
  return (
    <ul className="space-y-1">
      {rows.map((r) => {
        const on = active === r.key;
        const Tag = onPick ? 'button' : 'div';
        return (
          <li key={r.key}>
            <Tag {...(onPick ? { type: 'button' as const, onClick: () => onPick(on ? 'all' : r.key), 'aria-pressed': on } : {})}
              className={`w-full text-left rounded-[8px] px-2 py-1.5 ${onPick ? 'transition-colors hover:bg-[#F5F8FA]' : ''}`}
              style={on ? { background: `${r.color}12`, outline: `1px solid ${r.color}55` } : undefined}>
              <div className="flex items-center justify-between gap-2 text-[12px]">
                <span className="flex items-center gap-1.5 min-w-0" style={{ color: SEC }}>
                  <span className="h-[7px] w-[7px] rounded-full flex-none" style={{ background: r.color }} aria-hidden />
                  <span className="truncate">{r.label}</span>
                </span>
                <span className="font-semibold tabular-nums" style={{ color: INK }}>{r.count}</span>
              </div>
              <div className="h-[4px] rounded-full mt-1" style={{ background: '#EDF1F4' }}>
                <div className="h-full rounded-full" style={{ width: `${Math.max(4, (r.count / max) * 100)}%`, background: r.color }} />
              </div>
            </Tag>
          </li>
        );
      })}
    </ul>
  );
}

function Activity({ daily }: { daily: Summary['daily'] }) {
  const max = Math.max(1, ...daily.map((d) => d.count));
  return (
    <div>
      <div className="flex items-end gap-[2px] h-[54px]" role="img"
        aria-label={`Changes per day over the last ${daily.length} days`}>
        {daily.map((d) => (
          <div key={d.key} className="flex-1 rounded-t-[2px]" title={`${d.label}: ${d.count}`}
            style={{ height: `${d.count ? Math.max(8, (d.count / max) * 100) : 4}%`, background: d.count ? BRAND : '#E6EBEF' }} />
        ))}
      </div>
      <div className="flex justify-between text-[10px] mt-1" style={{ color: FAINT }}>
        <span>{daily[0]?.label}</span><span>Today</span>
      </div>
    </div>
  );
}

export default function SummaryRail({ summary, filters, onFilter }: {
  summary: Summary; filters: Filters; onFilter: (patch: Partial<Filters>) => void;
}) {
  const s = summary;
  const srcMax = Math.max(1, ...s.bySource.map((x) => x[1]));
  const catMax = Math.max(1, ...s.byCategory.map((x) => x[1]));
  const actMax = Math.max(1, ...s.byActor.map((x) => x[1]));
  const fldMax = Math.max(1, ...s.topFields.map((x) => x[1]));
  return (
    <div className="space-y-3">
      <div className="grid grid-cols-2 gap-2">
        <Stat label="Changes" value={s.entries} sub={`${s.fieldChanges} field edits`} />
        <Stat label="Contributors" value={s.byActor.length} sub={`${s.bySource.length} source${s.bySource.length === 1 ? '' : 's'}`} />
        <Stat label="First change" value={<span className="text-[14px]">{fmtDate(s.first)}</span>} />
        <Stat label="Latest change" value={<span className="text-[14px]">{fmtDate(s.last)}</span>} />
      </div>
      <Panel title="Activity · last 30 days"><Activity daily={s.daily} /></Panel>
      <Panel title="By source">
        <Bars max={srcMax} active={filters.source} onPick={(k) => onFilter({ source: k })}
          rows={s.bySource.map(([k, n]) => ({ key: k, label: sourceMeta(k).label, color: sourceMeta(k).color, count: n }))} />
      </Panel>
      <Panel title="By category (field edits)">
        <Bars max={catMax} active={filters.category} onPick={(k) => onFilter({ category: k })}
          rows={s.byCategory.map(([k, n]) => ({ key: k, label: categoryMeta(k).label, color: categoryMeta(k).color, count: n }))} />
      </Panel>
      <Panel title="Contributors">
        <Bars max={actMax} active={filters.actor} onPick={(k) => onFilter({ actor: k })}
          rows={s.byActor.slice(0, 8).map(([k, n]) => ({ key: k, label: k, color: '#4A6A85', count: n }))} />
      </Panel>
      <Panel title="Most-changed fields">
        <Bars max={fldMax} active="" rows={s.topFields.map(([k, n]) => ({ key: k, label: fieldLabel(k), color: ACCENT, count: n }))} />
      </Panel>
    </div>
  );
}
