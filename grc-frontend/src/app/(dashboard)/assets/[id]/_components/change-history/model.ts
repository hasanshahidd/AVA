/*
 * Change-history view model: categories, sources, field labels and the
 * summary maths shared by the asset History tab and /assets/[id]/history.
 * Categories come from the backend journal (asset_change_log.FIELD_CATEGORIES);
 * this file only owns presentation (labels, colours, order).
 */

export type ChangeField = { field: string; category?: string; old: unknown; new: unknown };
export type ChangeEntry = {
  id: number; action: string; detail?: string; actor_name?: string; created_at?: string;
  source?: string; fields?: ChangeField[];
};

export const BRAND = '#005B96';
export const ACCENT = '#19A8E6';
export const INK = '#0F1F2B';
export const SEC = '#3A4653';
export const MUTED = '#6B7785';
export const FAINT = '#9AA5B1';
export const BORDER = '#E3E8EC';
export const SOFT = '#F5F8FA';

export const CATEGORY_META: Record<string, { label: string; color: string; hint: string }> = {
  identity: { label: 'Identity', color: '#005B96', hint: 'Name, type, hostname, IP, MAC, serial' },
  classification: { label: 'Classification', color: '#7A4FD0', hint: 'Criticality, CIA ratings, data class' },
  ownership: { label: 'Ownership', color: '#1F7A54', hint: 'Owner, team, custodian, location' },
  platform: { label: 'Platform', color: '#0E7C86', hint: 'OS, hardware, vendor, agent' },
  lifecycle: { label: 'Lifecycle', color: '#A86A0C', hint: 'Status, lifecycle, warranty, EOL' },
  exposure: { label: 'Exposure', color: '#B23A3A', hint: 'Internet-facing, network segment' },
  other: { label: 'Other', color: '#6B7785', hint: 'Other recorded activity' },
};
export const CATEGORY_ORDER = ['identity', 'classification', 'ownership', 'platform', 'lifecycle', 'exposure', 'other'];

export const SOURCE_META: Record<string, { label: string; color: string; actor: string }> = {
  manual: { label: 'Manual edit', color: '#005B96', actor: 'User' },
  scan: { label: 'Credentialed scan', color: '#7A4FD0', actor: 'Scanner' },
  discovery: { label: 'Network discovery', color: '#0E7C86', actor: 'Network discovery' },
  connector: { label: 'Connector sync', color: '#A86A0C', actor: 'Connector' },
  agent: { label: 'Agent report', color: '#1F7A54', actor: 'Endpoint agent' },
  import: { label: 'Import', color: '#B4508A', actor: 'File import' },
  system: { label: 'System', color: '#6B7785', actor: 'System' },
};
export const SOURCE_ORDER = ['manual', 'scan', 'discovery', 'connector', 'agent', 'import', 'system'];

export const sourceOf = (e: ChangeEntry) => e.source || 'manual';
export const sourceMeta = (s: string) => SOURCE_META[s] ?? { label: titleCase(s), color: MUTED, actor: titleCase(s) };
export const categoryMeta = (c: string) => CATEGORY_META[c] ?? CATEGORY_META.other;
export const actorOf = (e: ChangeEntry) => e.actor_name || sourceMeta(sourceOf(e)).actor;

const FIELD_LABELS: Record<string, string> = {
  ip_address: 'IP address', primary_mac: 'MAC address', fqdn: 'FQDN', host_name: 'Hostname',
  os_family: 'OS family', os_version: 'OS version', os_build: 'OS build', os_edition: 'OS edition',
  criticality_manual_override: 'Criticality override', confidentiality_rating: 'Confidentiality',
  integrity_rating: 'Integrity', availability_rating: 'Availability', eol_date: 'End of life',
  internet_facing: 'Internet-facing', owner_id: 'Owner (user)', owner_name: 'Owner',
  asset_type: 'Asset type', serial_number: 'Serial number', agent_version: 'Agent version',
};

export function titleCase(s: string) {
  const t = s.replace(/[_.-]+/g, ' ').trim();
  return t ? t[0].toUpperCase() + t.slice(1) : s;
}
export const fieldLabel = (f: string) => FIELD_LABELS[f] ?? titleCase(f);
export const isEmpty = (v: unknown) => v === null || v === undefined || v === '';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}(T[\d:.]+)?/;
export function fmtValue(v: unknown): string {
  if (isEmpty(v)) return 'empty';
  if (typeof v === 'boolean') return v ? 'Yes' : 'No';
  const s = String(v);
  if (ISO_DATE.test(s) && !Number.isNaN(Date.parse(s))) {
    return new Date(s).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
  }
  return s;
}

export function fieldsOf(e: ChangeEntry): ChangeField[] {
  return Array.isArray(e.fields) ? e.fields : [];
}
export const categoryOfField = (f: ChangeField) => f.category || 'other';
export function categoriesOf(e: ChangeEntry): string[] {
  const fs = fieldsOf(e);
  return fs.length ? Array.from(new Set(fs.map(categoryOfField))) : ['other'];
}

export function fmtDate(iso?: string) {
  return iso ? new Date(iso).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';
}
export function fmtTime(iso?: string) {
  return iso ? new Date(iso).toLocaleTimeString('en-GB', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) : '';
}
function sameDay(a: Date, b: Date) {
  return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
}
export function dayKey(iso?: string) {
  if (!iso) return 'undated';
  const d = new Date(iso);
  return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
}
export function dayLabel(iso?: string) {
  if (!iso) return 'Undated';
  const d = new Date(iso);
  const full = d.toLocaleDateString('en-GB', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' });
  const now = new Date();
  const yest = new Date(now);
  yest.setDate(now.getDate() - 1);
  if (sameDay(d, now)) return `Today · ${full}`;
  if (sameDay(d, yest)) return `Yesterday · ${full}`;
  return full;
}

export type Filters = { category: string; source: string; actor: string; query: string };
export const NO_FILTERS: Filters = { category: 'all', source: 'all', actor: 'all', query: '' };

/** Entries matching the filters; with a category filter, only that category's fields are kept. */
export function applyFilters(items: ChangeEntry[], f: Filters): ChangeEntry[] {
  const q = f.query.trim().toLowerCase();
  const out: ChangeEntry[] = [];
  for (const e of items) {
    if (f.source !== 'all' && sourceOf(e) !== f.source) continue;
    if (f.actor !== 'all' && actorOf(e) !== f.actor) continue;
    let fields = fieldsOf(e);
    if (f.category !== 'all') {
      if (!categoriesOf(e).includes(f.category)) continue;
      fields = fields.filter((x) => categoryOfField(x) === f.category);
    }
    if (q) {
      const hay = [e.detail, e.action, actorOf(e), ...fields.flatMap((x) => [fieldLabel(x.field), x.field, fmtValue(x.old), fmtValue(x.new)])]
        .join(' ').toLowerCase();
      if (!hay.includes(q)) continue;
    }
    out.push(fields === e.fields ? e : { ...e, fields });
  }
  return out;
}

export type Summary = {
  entries: number; fieldChanges: number; first?: string; last?: string;
  bySource: [string, number][]; byCategory: [string, number][];
  byActor: [string, number][]; topFields: [string, number][];
  daily: { key: string; label: string; count: number }[];
};

function ranked(m: Map<string, number>): [string, number][] {
  return Array.from(m.entries()).sort((a, b) => b[1] - a[1]);
}
const bump = (m: Map<string, number>, k: string, n = 1) => m.set(k, (m.get(k) ?? 0) + n);

export function summarise(items: ChangeEntry[], days = 30): Summary {
  const bySource = new Map<string, number>();
  const byCategory = new Map<string, number>();
  const byActor = new Map<string, number>();
  const byField = new Map<string, number>();
  let fieldChanges = 0;
  for (const e of items) {
    bump(bySource, sourceOf(e));
    bump(byActor, actorOf(e));
    const fs = fieldsOf(e);
    fieldChanges += fs.length;
    if (!fs.length) bump(byCategory, 'other');
    for (const f of fs) {
      bump(byCategory, categoryOfField(f));
      bump(byField, f.field);
    }
  }
  const dated = items.map((e) => e.created_at).filter(Boolean).sort() as string[];
  const daily: Summary['daily'] = [];
  const today = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(today);
    d.setDate(today.getDate() - i);
    const key = dayKey(d.toISOString());
    daily.push({ key, label: d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short' }), count: 0 });
  }
  const idx = new Map(daily.map((d, i) => [d.key, i]));
  for (const e of items) {
    const i = idx.get(dayKey(e.created_at));
    if (i !== undefined) daily[i].count += 1;
  }
  return {
    entries: items.length, fieldChanges, first: dated[0], last: dated[dated.length - 1],
    bySource: ranked(bySource),
    byCategory: ranked(byCategory).sort((a, b) => CATEGORY_ORDER.indexOf(a[0]) - CATEGORY_ORDER.indexOf(b[0])),
    byActor: ranked(byActor), topFields: ranked(byField).slice(0, 6), daily,
  };
}
