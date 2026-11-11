/*
 * Change-history view model: categories, sources, field/section labels and the
 * summary maths shared by the asset History tab and /assets/[id]/history.
 * Categories mirror the asset record (Identity & network · Hardware / Software /
 * Security telemetry · Ownership · Business & risk context · Procurement & cost ·
 * Lifecycle & status · Platform telemetry) and are assigned by the backend
 * journal (services/asset_change_log.py); this file owns presentation only.
 */

export type ChangeField = {
  field: string; section?: string; category?: string; change?: 'changed' | 'added' | 'removed' | 'updated';  // updated = older row, values not recorded
  old: unknown; new: unknown; old_label?: string | null; new_label?: string | null;
};
export type SectionTotals = { category: string; added: number; removed: number; changed: number };
export type ChangeEntry = {
  id: number; action: string; detail?: string; actor_name?: string; created_at?: string;
  source?: string; fields?: ChangeField[]; sections?: Record<string, SectionTotals> | null;
  total_fields?: number | null; truncated?: number | null;
  // Estate-wide feed (/asset-change-log) only: which asset the entry belongs to.
  asset_id?: number | null; asset_name?: string | null; asset_type?: string | null;
};

export const BRAND = '#005B96';
export const ACCENT = '#19A8E6';
export const INK = '#0F1F2B';
export const SEC = '#3A4653';
export const MUTED = '#6B7785';     // smallest text colour that still passes 4.5:1 on white
export const FAINT = '#9AA5B1';     // icons / arrows only, never body text
export const BORDER = '#E8ECEE';
export const DIVIDER = '#F0F3F5';
export const SOFT = '#FAFBFC';
export const ADD = '#1F7A54';
export const DEL = '#B23A3A';

export const CATEGORY_META: Record<string, { label: string; color: string; hint: string }> = {
  identity: { label: 'Identity & network', color: '#005B96', hint: 'Name, type, hostname, IP, MAC, DNS, exposure' },
  hardware: { label: 'Hardware telemetry', color: '#0E7C86', hint: 'Make, model, serial, CPU, memory, disks, firmware' },
  software: { label: 'Software telemetry', color: '#7A4FD0', hint: 'OS, build, packages, services, agent, containers' },
  security: { label: 'Security telemetry', color: '#B23A3A', hint: 'AV/EDR, Defender, firewall, encryption, accounts, updates' },
  ownership: { label: 'Ownership', color: '#1F7A54', hint: 'Owners, team, custodian, department, location' },
  business: { label: 'Business & risk context', color: '#A86A0C', hint: 'Criticality, CIA, data class, scope, business impact' },
  procurement: { label: 'Procurement & cost', color: '#B4508A', hint: 'Vendor, cost, purchase, warranty, end of life' },
  lifecycle: { label: 'Lifecycle & status', color: '#4A6A85', hint: 'Status, lifecycle, discovery state, record source' },
  platform: { label: 'Platform telemetry', color: '#19A8E6', hint: 'Database, network-device, cloud, cluster, directory data' },
  other: { label: 'Other', color: '#6B7785', hint: 'Other recorded activity' },
};
export const CATEGORY_ORDER = ['identity', 'hardware', 'software', 'security', 'ownership', 'business',
  'procurement', 'lifecycle', 'platform', 'other'];

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

const LABELS: Record<string, string> = {
  // columns
  ip_address: 'IP address', primary_mac: 'MAC address', fqdn: 'FQDN', host_name: 'Hostname', known_ips: 'Known IPs',
  dns_aliases: 'DNS aliases', internet_facing: 'Internet-facing', is_internet_facing: 'Internet-facing (flag)',
  cloud_resource_id: 'Cloud resource ID', parent_asset_id: 'Parent asset', asset_type: 'Asset type',
  os_family: 'OS family', os_version: 'OS version', os_build: 'OS build', os_edition: 'OS edition',
  os_normalized: 'Benchmark OS key', cpu_cores: 'vCPU', memory_gb: 'Memory (GB)', storage_gb: 'Storage (GB)',
  serial_number: 'Serial number', agent_version: 'Agent version', detected_software_json: 'Detected software',
  app_attributes_json: 'Application attributes', security_posture: 'Security posture',
  credential_profile_id: 'Scan credential', owner_id: 'Owner (user)', owner_name: 'Owner',
  primary_owner_id: 'Primary owner', secondary_owner_id: 'Secondary owner', business_owner_id: 'Business owner',
  escalation_contact_id: 'Escalation contact', owning_team_id: 'Owning team (ID)',
  criticality_manual_override: 'Criticality override', criticality_override_reason: 'Override reason',
  criticality_score: 'Criticality score', confidentiality_rating: 'Confidentiality', integrity_rating: 'Integrity',
  availability_rating: 'Availability', cde_environment: 'PCI scope (CDE)', pci_dss: 'PCI DSS',
  ephi_environment: 'HIPAA scope (ePHI)', hipaa: 'HIPAA', is_customer_facing: 'Customer-facing',
  op_dep_business_impact: 'Business impact', business_impact_notes: 'Business impact notes',
  eol_date: 'End of life', purchase_cost: 'Purchase cost', replacement_asset_id: 'Replacement asset',
  // telemetry sections
  cpu: 'CPU', gpu: 'GPU', memory: 'Memory', firmware: 'Firmware', storage: 'Storage', storage_disks: 'Disks',
  storage_mounts: 'Mounts', lvm: 'LVM', raid: 'RAID', identity: 'System identity', network: 'Network adapters',
  net_addr: 'Addresses', net_link: 'Links', net_route: 'Routes', dns: 'DNS', os: 'Operating system',
  operating_system: 'Operating system', packages: 'Packages', pkg: 'Packages', services: 'Services',
  scheduled_tasks: 'Scheduled tasks', shares: 'Shares', virt: 'Virtualization', virtualization: 'Virtualization',
  agent: 'Agent', software: 'Installed software', hotfixes: 'Hotfixes', security_products: 'Antivirus & EDR',
  defender: 'Defender', firewall: 'Host firewall', bitlocker: 'Disk encryption (BitLocker)', selinux: 'SELinux',
  apparmor: 'AppArmor', sshd: 'SSH daemon', ssh_config: 'SSH config', local_users: 'Local users',
  local_groups: 'Local groups', sudoers: 'Sudoers', windows_update: 'Windows Update', sec_updates: 'Security updates',
  security_updates: 'Security updates', cmdb: 'CMDB link', surface: 'Surface facts', recon: 'Recon',
  discovery_classification: 'Discovery classification', fingerprint: 'Fingerprint', external_probe: 'External probe',
  status: 'Status',
};

export function titleCase(s: string) {
  const t = s.replace(/[_.-]+/g, ' ').trim();
  return t ? t[0].toUpperCase() + t.slice(1) : s;
}
const UNIT = /_(gb|mb|kb|tb|mhz|ghz|pct|percentage)$/i;
export const label = (k: string) => LABELS[k] ?? (UNIT.test(k)
  ? `${titleCase(k.replace(UNIT, ''))} (${k.match(UNIT)![1].replace(/pct|percentage/i, '%').toUpperCase()})`
  : titleCase(k));
export const sectionOf = (f: ChangeField) => f.section || f.field;
export const isTelemetry = (f: ChangeField) => sectionOf(f) !== f.field;
export const sectionLabel = (s: string) => label(s);

/** Row label. Columns → their name; telemetry paths → the part below the section,
 * e.g. "packages.data.items[openssl].version" → "openssl › Version". */
export function fieldLabel(f: ChangeField): string {
  if (!isTelemetry(f)) return label(f.field);
  const rest = f.field.slice(sectionOf(f).length).replace(/^\.data\b/, '').replace(/^\.items\b/, '');
  const parts: string[] = [];
  for (const [kind, tok] of splitPath(rest)) {
    if (kind === 'item') parts.push(itemName(tok));
    else if (tok !== 'data' && tok !== 'items') parts.push(tok === 'status' ? 'Collection status' : label(tok));
  }
  return parts.length ? parts.join(' › ') : 'Section data';
}

/** ".a.b[key].c" → [['key','a'],['key','b'],['item','key'],['key','c']]; [..] may hold JSON with its own brackets/quotes. */
export function splitPath(p: string): ['key' | 'item', string][] {
  const out: ['key' | 'item', string][] = [];
  let i = 0;
  while (i < p.length) {
    if (p[i] === '.') {
      let j = i + 1;
      while (j < p.length && p[j] !== '.' && p[j] !== '[') j++;
      if (j > i + 1) out.push(['key', p.slice(i + 1, j)]);
      i = j;
    } else if (p[i] === '[') {
      const j = itemEnd(p, i);
      out.push(['item', p.slice(i + 1, j)]);
      i = j + 1;
    } else i++;
  }
  return out;
}

/** Index of the "]" closing the item key opened at i. A JSON key ({…}) is scanned
 * bracket- and string-aware; a plain key (a name, which may hold a stray " or [)
 * ends at the first "]" followed by ".", "[" or the end of the path. */
export function itemEnd(p: string, i: number): number {
  if (p[i + 1] === '{') {
    let depth = 0, inStr = false;
    for (let j = i; j < p.length; j++) {
      const ch = p[j];
      if (inStr) { if (ch === '\\') j++; else if (ch === '"') inStr = false; continue; }
      if (ch === '"') inStr = true;
      else if (ch === '[' || ch === '{') depth++;
      else if ((ch === ']' || ch === '}') && --depth === 0) return j;
    }
    return p.length;
  }
  for (let j = i + 1; j < p.length; j++) {
    if (p[j] === ']' && (j + 1 === p.length || p[j + 1] === '.' || p[j + 1] === '[')) return j;
  }
  return p.length;
}

/** An item key recorded as raw JSON (no natural name) reads as its name / description / MAC / port. */
export function itemName(tok: string): string {
  if (!tok.startsWith('{')) return tok;
  try {
    const o = JSON.parse(tok) as Record<string, unknown>;
    const v = o.name ?? o.display_name ?? o.description ?? o.mac ?? o.mac_address
      ?? (o.port != null ? `${o.port}/${o.proto ?? o.protocol ?? 'tcp'}` : null);
    return v != null && v !== '' ? String(v) : 'Item';
  } catch {
    // Older keys were cut at 120 chars, so the JSON is incomplete: read the fields straight from the text.
    const m = /"(?:name|display_name|description|mac|mac_address)":\s*"([^"]+)"/.exec(tok);
    return m ? m[1] : 'Item';
  }
}
export const isEmpty = (v: unknown) => v === null || v === undefined || v === '';

const ISO_DATE = /^\d{4}-\d{2}-\d{2}(T[\d:.]+)?/;
export function fmtValue(v: unknown, labelText?: string | null): string {
  if (labelText) return labelText;
  if (isEmpty(v)) return 'empty';
  if (typeof v === 'boolean') return v ? 'Yes' : 'No';
  if (typeof v === 'object') return JSON.stringify(v);
  const s = String(v);
  if (ISO_DATE.test(s) && !Number.isNaN(Date.parse(s))) {
    return new Date(s).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
  }
  return s;
}

export function fieldsOf(e: ChangeEntry): ChangeField[] {
  return Array.isArray(e.fields) ? e.fields : [];
}
export const categoryOfField = (f: ChangeField) => (f.category && CATEGORY_META[f.category] ? f.category : 'other');
export function categoriesOf(e: ChangeEntry): string[] {
  const fs = fieldsOf(e);
  const fromSections = e.sections ? Object.values(e.sections).map((s) => s.category) : [];
  const cats = new Set([...fs.map(categoryOfField), ...fromSections]);
  return cats.size ? Array.from(cats) : ['other'];
}
export const totalOf = (e: ChangeEntry) => e.total_fields ?? fieldsOf(e).length;

/* Times: the journal stores UTC without a zone mark ("2026-11-11T12:07:08"), which a browser
 * would read as its own local time. Entries are normalised to UTC on fetch (withUtc) and every
 * date / time is shown in Pakistan time, whatever the viewer's computer is set to. */
export const TIME_ZONE = 'Asia/Karachi';
export const TZ_LABEL = 'PKT';
const HAS_ZONE = /(Z|[+-]\d{2}:?\d{2})$/i;
export const asUtc = (iso?: string | null) => (iso && !HAS_ZONE.test(iso) ? `${iso}Z` : iso ?? undefined);
export function withUtc<T extends { created_at?: string }>(items: T[]): T[] {
  return items.map((e) => (e.created_at && !HAS_ZONE.test(e.created_at) ? { ...e, created_at: `${e.created_at}Z` } : e));
}

export function fmtDate(iso?: string) {
  return iso ? new Date(iso).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric', timeZone: TIME_ZONE }) : '—';
}
export function fmtTime(iso?: string, seconds = false) {
  return iso ? new Date(iso).toLocaleTimeString('en-GB', {
    hour: '2-digit', minute: '2-digit', ...(seconds ? { second: '2-digit' } : {}), timeZone: TIME_ZONE,
  }) : '';
}
/** "just now", "5 min ago", "3 h ago", "2 days ago", else the date. */
export function relTime(iso?: string) {
  if (!iso) return '—';
  const mins = Math.round((Date.now() - Date.parse(iso)) / 60_000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  if (mins < 24 * 60) return `${Math.round(mins / 60)} h ago`;
  const d = Math.round(mins / 1440);
  return d < 14 ? `${d} day${d === 1 ? '' : 's'} ago` : fmtDate(iso);
}
/** Calendar day in Pakistan time, e.g. "2026-11-11". */
const pkDay = (d: Date) => d.toLocaleDateString('en-CA', { timeZone: TIME_ZONE });
export function dayKey(iso?: string) {
  return iso ? pkDay(new Date(iso)) : 'undated';
}
/** Day heading: { title: "Today" | "Monday", date: "9 November 2026" }. */
export function dayLabel(iso?: string): { title: string; date: string } {
  if (!iso) return { title: 'Undated', date: '' };
  const d = new Date(iso);
  const date = d.toLocaleDateString('en-GB', { day: 'numeric', month: 'long', year: 'numeric', timeZone: TIME_ZONE });
  const day = pkDay(d);
  if (day === pkDay(new Date())) return { title: 'Today', date };
  if (day === pkDay(new Date(Date.now() - 86_400_000))) return { title: 'Yesterday', date };
  return { title: d.toLocaleDateString('en-GB', { weekday: 'long', timeZone: TIME_ZONE }), date };
}
export type DayGroup = { key: string; title: string; date: string; entries: ChangeEntry[] };
/** Entries arrive newest first; consecutive same-day entries share a group. */
export function groupByDay(items: ChangeEntry[]): DayGroup[] {
  const out: DayGroup[] = [];
  for (const e of items) {
    const key = dayKey(e.created_at);
    const last = out[out.length - 1];
    if (last && last.key === key) last.entries.push(e);
    else out.push({ key, ...dayLabel(e.created_at), entries: [e] });
  }
  return out;
}

/** One-line summary, e.g. "changed 3 fields in Hardware telemetry and Security telemetry". */
export function entrySummary(e: ChangeEntry): string {
  const fs = fieldsOf(e);
  const n = totalOf(e);
  if (!n) return e.detail || titleCase(e.action);
  const legacy = fs.length > 0 && fs.every((f) => f.change === 'updated');
  const cats = CATEGORY_ORDER.filter((c) => categoriesOf(e).includes(c)).map((c) => categoryMeta(c).label);
  const where = cats.length <= 2 ? cats.join(' and ') : `${cats.slice(0, 2).join(', ')} and ${cats.length - 2} more`;
  return `${legacy ? 'updated' : 'changed'} ${n} field${n === 1 ? '' : 's'} in ${where}`;
}

export type Filters = { category: string; source: string; actor: string; query: string; period: string };
export const NO_FILTERS: Filters = { category: 'all', source: 'all', actor: 'all', query: '', period: 'all' };
export const PERIODS: { key: string; label: string }[] = [
  { key: 'all', label: 'All time' }, { key: '90', label: '90 days' }, { key: '30', label: '30 days' }, { key: '7', label: '7 days' },
];

/** Entries matching the filters; with a category filter, only that category's fields are kept. */
export function applyFilters(items: ChangeEntry[], f: Filters): ChangeEntry[] {
  const q = f.query.trim().toLowerCase();
  const out: ChangeEntry[] = [];
  const since = f.period !== 'all' ? Date.now() - Number(f.period) * 86_400_000 : null;
  for (const e of items) {
    if (since !== null && (!e.created_at || Date.parse(e.created_at) < since)) continue;
    if (f.source !== 'all' && sourceOf(e) !== f.source) continue;
    if (f.actor !== 'all' && actorOf(e) !== f.actor) continue;
    let fields = fieldsOf(e);
    if (f.category !== 'all') {
      if (!categoriesOf(e).includes(f.category)) continue;
      fields = fields.filter((x) => categoryOfField(x) === f.category);
    }
    if (q) {
      const hay = [e.detail, e.action, actorOf(e), e.asset_name, ...fields.flatMap((x) => [
        fieldLabel(x), x.field, sectionLabel(sectionOf(x)), fmtValue(x.old, x.old_label), fmtValue(x.new, x.new_label)])]
        .join(' ').toLowerCase();
      if (!hay.includes(q)) continue;
      // Narrow to matching rows; if only the entry itself matched (asset, actor, detail), keep them all.
      const hit = fields.filter((x) => [fieldLabel(x), x.field, sectionLabel(sectionOf(x)),
        fmtValue(x.old, x.old_label), fmtValue(x.new, x.new_label)].join(' ').toLowerCase().includes(q));
      if (hit.length) fields = hit;
    }
    out.push(fields === e.fields ? e : { ...e, fields });
  }
  return out;
}

export type Summary = {
  entries: number; fieldChanges: number; assets: number; first?: string; last?: string;
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
    fieldChanges += totalOf(e);
    if (e.sections && Object.keys(e.sections).length) {
      // Section totals are complete even when stored rows were capped.
      for (const [sec, t] of Object.entries(e.sections)) {
        const n = t.added + t.removed + t.changed;
        bump(byCategory, CATEGORY_META[t.category] ? t.category : 'other', n);
        bump(byField, sectionLabel(sec), n);   // a column is its own section
      }
    } else {
      if (!fs.length) bump(byCategory, 'other');
      for (const f of fs) {
        bump(byCategory, categoryOfField(f));
        bump(byField, fieldLabel(f));
      }
    }
  }
  const dated = items.map((e) => e.created_at).filter(Boolean).sort() as string[];
  const daily: Summary['daily'] = [];
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86_400_000);
    daily.push({ key: dayKey(d.toISOString()), label: d.toLocaleDateString('en-GB', { day: 'numeric', month: 'short', timeZone: TIME_ZONE }), count: 0 });
  }
  const idx = new Map(daily.map((d, i) => [d.key, i]));
  for (const e of items) {
    const i = idx.get(dayKey(e.created_at));
    if (i !== undefined) daily[i].count += 1;
  }
  return {
    entries: items.length, fieldChanges, assets: new Set(items.map((e) => e.asset_id).filter(Boolean)).size, first: dated[0], last: dated[dated.length - 1],
    bySource: ranked(bySource),
    byCategory: ranked(byCategory).sort((a, b) => CATEGORY_ORDER.indexOf(a[0]) - CATEGORY_ORDER.indexOf(b[0])),
    byActor: ranked(byActor), topFields: ranked(byField).slice(0, 8), daily,
  };
}
