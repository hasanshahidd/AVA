// Pure helpers behind the in-app report preview: which columns to break a dataset down by,
// and the KPI cards derived from those breakdowns. No React, no I/O — self-checked by
// grc-frontend/scripts/reportInsights.selfcheck.mjs (run: node scripts/reportInsights.selfcheck.mjs, Node 22.18+).

export interface Slice { name: string; value: number }
export type Breakdowns = Record<string, Slice[]>;
export interface Kpi { label: string; value: string; tone?: 'danger' | 'warn' | 'good' }

// Columns worth grouping by, per dataset (first two feed the charts). Anything not listed
// falls back to its first badge-typed filterable columns.
const BREAKDOWN_COLS: Record<string, string[]> = {
  vulnerabilities: ['severity', 'status', 'kev_flag'],
  assets: ['origin_source', 'criticality', 'cde_environment'],
  cis_results: ['status'],
  helpdesk_tickets: ['status_category', 'agreement_status'],
};

/** Group-by columns for a dataset, limited to ones the catalog says can be filtered/grouped. */
export function breakdownColumns(dataset: string, filterable: Record<string, string>): string[] {
  const wanted = (BREAKDOWN_COLS[dataset] ?? []).filter((c) => c in filterable);
  if (wanted.length) return wanted;
  return Object.keys(filterable).filter((c) => filterable[c] === 'badge').slice(0, 2);
}

/** Make an aggregate group key readable: null → Unknown, booleans → Yes/No. */
export function sliceName(v: unknown): string {
  if (v === null || v === undefined || v === '') return 'Unknown';
  if (v === true) return 'Yes';
  if (v === false) return 'No';
  return String(v);
}

const sum = (slices: Slice[] | undefined, test: (name: string) => boolean) =>
  (slices ?? []).filter((s) => test(s.name.toLowerCase())).reduce((n, s) => n + s.value, 0);
const is = (...names: string[]) => (n: string) => names.includes(n);
const fmt = (n: number) => n.toLocaleString('en-US');

function vulnKpis(total: number, b: Breakdowns): Kpi[] {
  const sev = b.severity;
  return [
    { label: 'Total findings', value: fmt(total) },
    { label: 'Critical', value: fmt(sum(sev, is('critical'))), tone: 'danger' },
    { label: 'High', value: fmt(sum(sev, is('high'))), tone: 'warn' },
    { label: 'Medium / Low', value: fmt(sum(sev, is('medium', 'low'))) },
    { label: 'Known exploited (KEV)', value: fmt(sum(b.kev_flag, is('yes', 'true'))), tone: 'danger' },
  ];
}

function assetKpis(total: number, b: Breakdowns): Kpi[] {
  const external = sum(b.origin_source, is('easm'));
  return [
    { label: 'Total assets', value: fmt(total) },
    { label: 'External', value: fmt(external) },
    { label: 'Internal', value: fmt(Math.max(0, total - external)) },
    { label: 'PCI scope', value: fmt(sum(b.cde_environment, is('yes', 'true'))) },
  ];
}

function cisKpis(total: number, b: Breakdowns): Kpi[] {
  const pass = sum(b.status, (n) => n.startsWith('pass'));
  const fail = sum(b.status, (n) => n.startsWith('fail'));
  const decided = pass + fail;
  const pct = decided ? Math.round((pass / decided) * 100) : 0;
  return [
    { label: 'Total checks', value: fmt(total) },
    { label: 'Passed', value: fmt(pass), tone: 'good' },
    { label: 'Failed', value: fmt(fail), tone: 'danger' },
    { label: 'Pass rate', value: decided ? `${pct}%` : '—', tone: pct >= 80 ? 'good' : 'warn' },
  ];
}

/** Total + the biggest groups of the first breakdown (helpdesk statuses, or any other dataset). */
function genericKpis(total: number, b: Breakdowns, cols: string[], noun: string): Kpi[] {
  const top = [...(b[cols[0]] ?? [])].sort((x, y) => y.value - x.value).slice(0, 3);
  return [{ label: `Total ${noun}`, value: fmt(total) }, ...top.map((s) => ({ label: s.name, value: fmt(s.value) }))];
}

/** KPI cards for a dataset. `total` is the filtered row count; `b` maps column → grouped counts. */
export function buildKpis(dataset: string, total: number, b: Breakdowns, cols: string[], noun = 'rows'): Kpi[] {
  switch (dataset) {
    case 'vulnerabilities': return vulnKpis(total, b);
    case 'assets': return assetKpis(total, b);
    case 'cis_results': return cisKpis(total, b);
    default: return genericKpis(total, b, cols, noun);
  }
}

/** Largest `n` slices by value; the remainder is folded into one "Other" slice so charts stay readable. */
export function topSlices(slices: Slice[], n = 8): Slice[] {
  const sorted = [...slices].filter((s) => s.value > 0).sort((a, b) => b.value - a.value);
  if (sorted.length <= n) return sorted;
  const rest = sorted.slice(n - 1).reduce((t, s) => t + s.value, 0);
  return [...sorted.slice(0, n - 1), { name: 'Other', value: rest }];
}
