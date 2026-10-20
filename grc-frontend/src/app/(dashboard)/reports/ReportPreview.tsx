'use client';

// In-app visual report: header, KPI stat cards, two breakdown charts and the data table for
// the definition the Report Builder holds. Counts come from /reporting/aggregate (exact, whole
// filtered set); the table is the first PREVIEW_ROWS rows from /reporting/query. "Download PDF"
// prints just this block through the browser, so no server-side chart rendering is needed.
import React, { useRef } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Loader2, AlertCircle, Printer, X, BarChart3 } from 'lucide-react';
import { PieChart, Pie, Cell, Tooltip as RTooltip, ResponsiveContainer } from 'recharts';
import { SegmentedMixCard } from '@/components/charts/MixCharts';
import { reportingApi, type ReportFilter } from '@/lib/api';
import { labelize } from './shared';
import {
  breakdownColumns, buildKpis, sliceName, topSlices, type Breakdowns, type Kpi, type Slice,
} from './reportInsights';

const PREVIEW_ROWS = 100;
const PALETTE = ['#005B96', '#0ea5e9', '#14b8a6', '#f59e0b', '#8b5cf6', '#ef4444', '#64748b', '#84cc16'];
const NAMED_COLORS: Record<string, string> = {
  critical: '#dc2626', high: '#ea580c', medium: '#d97706', low: '#2563eb', info: '#64748b',
  passed: '#16a34a', failed: '#dc2626', error: '#d97706', other: '#94a3b8', unknown: '#94a3b8',
};
const TONE_COLOR: Record<NonNullable<Kpi['tone']>, string> = {
  danger: '#dc2626', warn: '#d97706', good: '#16a34a',
};

export interface PreviewRequest {
  dataset: string;
  label: string;
  columns: string[];
  filters: ReportFilter[];
  logic: 'AND' | 'OR';
  assetCategories?: string[];
}

interface PreviewData { total: number; rows: Record<string, unknown>[]; breakdowns: Breakdowns; cols: string[] }

async function loadPreview(req: PreviewRequest, filterable: Record<string, string>): Promise<PreviewData> {
  const cols = breakdownColumns(req.dataset, filterable);
  const base = {
    dataset: req.dataset, filters: req.filters, logic: req.logic, asset_categories: req.assetCategories,
  };
  const [q, ...counts] = await Promise.all([
    reportingApi.query({ ...base, limit: PREVIEW_ROWS }),
    // A failed breakdown just drops that chart; it must not blank the whole preview.
    ...cols.map((c) => reportingApi.countBy({ ...base, group_by: [c] }).catch(() => null)),
  ]);
  const breakdowns: Breakdowns = {};
  cols.forEach((c, i) => {
    const res = counts[i]?.data;
    if (!res || res.warnings?.skipped_group_by?.includes(c)) return;
    breakdowns[c] = res.rows.map((r) => ({ name: sliceName(r[c]), value: Number(r.m_n) || 0 }));
  });
  return { total: q.data.total, rows: q.data.rows, breakdowns, cols: cols.filter((c) => c in breakdowns) };
}

const sliceColor = (s: Slice, i: number) => NAMED_COLORS[s.name.toLowerCase()] ?? PALETTE[i % PALETTE.length];

function cellText(v: unknown): string {
  if (v === null || v === undefined || v === '') return '—';
  if (typeof v === 'boolean') return v ? 'Yes' : 'No';
  return typeof v === 'object' ? JSON.stringify(v) : String(v);
}

function filterSummary(req: PreviewRequest): string {
  if (!req.filters.length) return 'No filters — every row';
  const parts = req.filters.map((f) => `${labelize(f.col)} ${f.op} ${f.value ?? ''}`.trim());
  return parts.join(req.logic === 'OR' ? '  OR  ' : '  AND  ');
}

function KpiCards({ kpis }: { kpis: Kpi[] }) {
  return (
    <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
      {kpis.map((k) => (
        <div key={k.label} className="rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] px-4 py-3">
          <div className="text-2xl font-bold leading-none" style={{ color: k.tone ? TONE_COLOR[k.tone] : 'var(--color-text)' }}>
            {k.value}
          </div>
          <div className="mt-1.5 truncate text-xs font-medium text-[var(--color-muted)]">{k.label}</div>
        </div>
      ))}
    </div>
  );
}

function DonutCard({ title, slices }: { title: string; slices: Slice[] }) {
  const data = topSlices(slices);
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-3 shadow-card">
      <h3 className="text-sm font-semibold text-slate-800">{title}</h3>
      {data.length === 0 ? (
        <p className="py-10 text-center text-xs text-slate-400">No data</p>
      ) : (
        <div className="flex items-center gap-3">
          <div className="h-40 w-40 flex-none">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={data} dataKey="value" nameKey="name" innerRadius={38} outerRadius={64} paddingAngle={2}>
                  {data.map((s, i) => <Cell key={s.name} fill={sliceColor(s, i)} />)}
                </Pie>
                <RTooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <ul className="min-w-0 flex-1 space-y-1 text-[11px]">
            {data.map((s, i) => (
              <li key={s.name} className="flex items-center gap-1.5">
                <span className="h-2 w-2 flex-none rounded-full" style={{ background: sliceColor(s, i) }} />
                <span className="min-w-0 flex-1 truncate capitalize text-slate-600">{s.name}</span>
                <span className="font-semibold text-slate-800">{s.value.toLocaleString('en-US')}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

function PreviewTable({ columns, rows }: { columns: string[]; rows: Record<string, unknown>[] }) {
  return (
    <div className="overflow-x-auto rounded-xl border border-[var(--color-border)]">
      <table className="w-full border-collapse text-[12px]">
        <thead>
          <tr>
            {columns.map((c) => (
              <th key={c} className="whitespace-nowrap bg-slate-800 px-2.5 py-2 text-left font-semibold text-white">{labelize(c)}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.length === 0 && (
            <tr><td colSpan={Math.max(1, columns.length)} className="px-3 py-6 text-center text-[var(--color-muted)]">No rows match the selected filters.</td></tr>
          )}
          {rows.map((r, i) => (
            <tr key={i} className={i % 2 ? 'bg-slate-50' : 'bg-white'}>
              {columns.map((c) => (
                <td key={c} className="max-w-[260px] truncate border-t border-slate-100 px-2.5 py-1.5 text-slate-800">{cellText(r[c])}</td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// Print only the report block: copy it (plus the page's stylesheets) into a hidden iframe and
// print that. shortcut: relies on the app's CSS being re-fetchable by the iframe; if a deploy
// ever inlines styles differently, switch to a dedicated /reports/print route.
function printReport(el: HTMLElement, title: string) {
  const frame = document.createElement('iframe');
  frame.style.cssText = 'position:fixed;right:0;bottom:0;width:0;height:0;border:0';
  document.body.appendChild(frame);
  const doc = frame.contentDocument;
  const win = frame.contentWindow;
  if (!doc || !win) { frame.remove(); return; }
  const styles = Array.from(document.querySelectorAll('link[rel="stylesheet"], style'))
    .map((n) => (n instanceof HTMLLinkElement ? `<link rel="stylesheet" href="${n.href}">` : n.outerHTML))
    .join('');
  const safeTitle = title.replace(/[<>&"]/g, '');
  frame.onload = () => {
    win.focus();
    win.print();
    setTimeout(() => frame.remove(), 1500);
  };
  doc.open();
  doc.write(
    `<!doctype html><html><head><meta charset="utf-8"><title>${safeTitle}</title>${styles}` +
    '<style>@page{size:A4 landscape;margin:10mm}body{background:#fff;margin:0;padding:12px;-webkit-print-color-adjust:exact;print-color-adjust:exact}' +
    'svg{max-width:100%;height:auto}.no-print{display:none!important}.overflow-x-auto{overflow:visible!important}' +
    'tr,.break-inside-avoid{break-inside:avoid}</style></head>' +
    `<body>${el.outerHTML}</body></html>`,
  );
  doc.close();
}

export default function ReportPreview({
  req, filterable, onClose,
}: { req: PreviewRequest; filterable: Record<string, string>; onClose: () => void }) {
  const rootRef = useRef<HTMLDivElement>(null);
  const { data, isLoading, isError } = useQuery({
    queryKey: ['report-preview', req, filterable],
    queryFn: () => loadPreview(req, filterable),
    staleTime: 0,
  });

  const kpis = data ? buildKpis(req.dataset, data.total, data.breakdowns, data.cols, 'rows') : [];
  const [c1, c2] = data?.cols ?? [];
  const when = new Date().toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' });

  return (
    <div className="space-y-4 border-t border-[var(--color-border)] pt-5">
      <div className="no-print flex items-center justify-between gap-2">
        <span className="inline-flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-[var(--color-muted)]">
          <BarChart3 size={14} /> Report preview
        </span>
        <div className="flex items-center gap-2">
          <button
            onClick={() => rootRef.current && printReport(rootRef.current, `${req.label} report`)}
            disabled={!data}
            className="inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-semibold text-[var(--color-on-base)] disabled:opacity-60"
            style={{ background: 'var(--color-base)' }}
          >
            <Printer size={14} /> Download PDF
          </button>
          <button onClick={onClose} aria-label="Close preview"
            className="rounded-lg p-1.5 text-[var(--color-muted)] hover:bg-[var(--color-subtle)]"><X size={15} /></button>
        </div>
      </div>

      {isLoading && (
        <div className="flex items-center gap-2 text-sm text-[var(--color-muted)]">
          <Loader2 size={15} className="animate-spin" /> Building preview…
        </div>
      )}
      {isError && (
        <div className="flex items-center gap-2 text-sm text-[var(--color-danger)]">
          <AlertCircle size={15} /> Could not build the preview — check your filters and try again.
        </div>
      )}

      {data && (
        <div ref={rootRef} className="space-y-4">
          <div>
            <h3 className="text-lg font-semibold text-[var(--color-text)]">{req.label} report</h3>
            <p className="mt-0.5 text-xs text-[var(--color-muted)]">
              {data.total.toLocaleString('en-US')} row{data.total === 1 ? '' : 's'} · {filterSummary(req)} · Generated {when}
            </p>
          </div>
          <KpiCards kpis={kpis} />
          {c1 && (
            <div className="grid gap-3 md:grid-cols-2 break-inside-avoid">
              <DonutCard title={`By ${labelize(c1)}`} slices={data.breakdowns[c1]} />
              <SegmentedMixCard
                totalLabel={`by ${labelize(c2 ?? c1)}`}
                data={topSlices(data.breakdowns[c2 ?? c1]).map((s, i) => ({ ...s, color: sliceColor(s, i) }))}
              />
            </div>
          )}
          <PreviewTable columns={req.columns} rows={data.rows} />
          {data.total > data.rows.length && (
            <p className="text-[11px] text-[var(--color-muted)]">
              Showing the first {data.rows.length.toLocaleString('en-US')} of {data.total.toLocaleString('en-US')} rows — export CSV / XLSX for the full set.
            </p>
          )}
        </div>
      )}
    </div>
  );
}
