'use client';

// Scan telemetry in the Add / Edit asset form — the same Hardware / Software / Security
// categories the asset Overview shows, each opening into its fields, rows and sub-fields.
// Edit opens pre-filled from the agent / agentless scan (platform_properties); a category
// the user touches is saved as a manual override until the next scan re-collects it.

import React, { useEffect, useMemo, useState } from 'react';
import { ChevronRight, Plus, X } from 'lucide-react';

// Field templates per category: 's' text, 'n' number, 'b' yes/no; [spec] = rows / list.
// Mirrors what the Windows and Linux collectors emit, so Add asset can show empty categories.
type Spec = 's' | 'n' | 'b' | Spec[] | { [k: string]: Spec };

const WINDOWS: Record<string, Spec> = {
  identity: { hostname: 's', fqdn: 's', domain: 's', workgroup: 's', part_of_domain: 'b', manufacturer: 's', model: 's', serial: 's', bios_serial: 's', uuid: 's' },
  cpu: { manufacturer: 's', model: 's', architecture: 's', clock_mhz: 'n', physical_cores: 'n', logical_processors: 'n', sockets: 'n' },
  memory: { total_gb: 'n', dimms: [{ slot: 's', manufacturer: 's', capacity_gb: 'n', speed_mhz: 'n', type: 's', part_number: 's', serial: 's' }] },
  gpu: { vendor: 's', model: 's', vram_mb: 'n', driver_version: 's', driver_date: 's' },
  storage: { physical_disks: [{ model: 's', serial: 's', size_gb: 'n', media_type: 's', bus_type: 's' }], volumes: [{ drive_letter: 's', filesystem: 's', capacity_gb: 'n', free_gb: 'n' }] },
  network: [{ name: 's', description: 's', mac: 's', status: 's', ipv4: ['s'], ipv6: ['s'], subnet: ['s'], gateway: ['s'], dns: ['s'], dhcp_enabled: 'b', speed_bps: 'n' }],
  firmware: { motherboard: { manufacturer: 's', product: 's', serial: 's' }, bios: { vendor: 's', version: 's', date: 's', mode: 's' } },
  os: { version: 's', edition: 's', build: 's', architecture: 's', install_date: 's', last_boot: 's', uptime_hours: 'n', timezone: 's', domain: 's', part_of_domain: 'b' },
  windows_update: { last_installed: 's', last_hotfix: 's', days_since_last_patch: 'n', hotfix_count: 'n', recent_hotfixes: [{ id: 's', type: 's', installed: 's' }] },
  services: [{ name: 's', display_name: 's', state: 's', start_mode: 's', account: 's', path: 's' }],
  scheduled_tasks: { total: 'n', enabled: 'n' },
  shares: [{ name: 's', path: 's', type: 's', description: 's' }],
  security_products: { edr_present: 'b', antivirus: [{ name: 's', enabled: 'b', up_to_date: 'b' }], edr_xdr: [{ product: 's', type: 's', service: 's', status: 's', running: 'b' }] },
  defender: { antivirus_enabled: 'b', antispyware_enabled: 'b', realtime_protection: 'b', tamper_protected: 'b', signature_version: 's', signature_age_days: 'n', engine_version: 's' },
  firewall: [{ profile: 's', enabled: 'b', default_inbound: 's', default_outbound: 's' }],
  bitlocker: [{ mount_point: 's', volume_status: 's', protection_status: 's', encryption_method: 's', encryption_percentage: 'n' }],
  local_users: [{ name: 's', full_name: 's', sid: 's', disabled: 'b', lockout: 'b' }],
  local_groups: [{ name: 's', description: 's' }],
};

const LINUX: Record<string, Spec> = {
  identity: { hostname: 's', fqdn: 's', distribution: 's', distro_id: 's', distro_version: 's', kernel: 's', architecture: 's', manufacturer: 's', model: 's', bios_vendor: 's', bios_version: 's', bios_date: 's', boot_time: 's', uptime_hours: 'n' },
  cpu: { vendor: 's', model: 's', architecture: 's', cpus: 's', threads_per_core: 's', cores_per_socket: 's', sockets: 's' },
  memory: { total_gb: 'n' },
  gpu: [{ description: 's' }],
  storage: { physical_disks: [{ name: 's', model: 's', serial: 's', size: 's', media_type: 's', interface: 's' }], mounts: [{ mount: 's', filesystem: 's', type: 's', size: 's', used: 's', available: 's', use_pct: 's' }] },
  network: { interfaces: [{ name: 's', mac: 's', state: 's', ipv4: ['s'], ipv6: ['s'] }], gateway: 's', dns: ['s'] },
  packages: { package_manager: 's', installed_count: 'n' },
  security_updates: { update_manager: 's', pending_security_updates: 'n' },
  services: { init_system: 's', services: [{ name: 's', state: 's' }] },
  virtualization: { hypervisor: 's', docker: { present: 'b', running_containers: 's' } },
  firewall: { tool: 's' },
  selinux: 's',
  apparmor: 's',
  users: [{ name: 's', uid: 's', shell: 's' }],
};

const SOFTWARE_SPEC: Spec = [{ name: 's', version: 's', publisher: 's', source: 's' }];
export const SOFTWARE_KEY = '__installed_packages';

// Same domains and order as the Overview (_overview-design.tsx DOMS).
const DOMAINS: { key: string; label: string; sub: string; keys: string[] }[] = [
  { key: 'hardware', label: 'Hardware Telemetry', sub: 'Machine identity, compute, storage, network interfaces & firmware',
    keys: ['identity', 'cpu', 'memory', 'gpu', 'storage', 'storage_disks', 'storage_mounts', 'lvm', 'raid', 'network', 'net_addr', 'net_link', 'net_route', 'dns', 'firmware'] },
  { key: 'software', label: 'Software Telemetry', sub: 'Operating system, updates, services & system configuration',
    keys: ['os', 'operating_system', 'windows_update', 'packages', 'pkg', 'security_updates', 'sec_updates', 'services', 'scheduled_tasks', 'shares', 'virtualization', 'virt', 'docker', 'podman', SOFTWARE_KEY] },
  { key: 'security', label: 'Security Telemetry', sub: 'Endpoint protection, encryption, firewall & accounts',
    keys: ['security_products', 'defender', 'firewall', 'bitlocker', 'selinux', 'apparmor', 'ssh_config', 'sshd', 'local_users', 'local_groups', 'users', 'sudoers'] },
];
const NON_SECTIONS = new Set(['surface', 'fingerprint', 'discovery_classification', 'recon']);
const TITLES: Record<string, string> = {
  identity: 'Machine identity', os: 'Operating system', [SOFTWARE_KEY]: 'Installed packages',
  selinux: 'SELinux', apparmor: 'AppArmor', bitlocker: 'BitLocker', sudoers: 'Sudoers',
};
const PAGE = 10;

const ACRONYMS: Record<string, string> = {
  cpu: 'CPU', gpu: 'GPU', os: 'OS', ip: 'IP', ipv4: 'IPv4', ipv6: 'IPv6', mac: 'MAC', dns: 'DNS', dhcp: 'DHCP', fqdn: 'FQDN',
  mhz: 'MHz', gb: 'GB', mb: 'MB', bps: 'bps', id: 'ID', sid: 'SID', uid: 'UID', uuid: 'UUID', bios: 'BIOS', edr: 'EDR', xdr: 'XDR', ssh: 'SSH',
};
const humanize = (k: string) => TITLES[k] || k.replace(/[_-]+/g, ' ').split(' ')
  .map((w) => ACRONYMS[w.toLowerCase()] || w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
const isSection = (o: any) => o && typeof o === 'object' && 'status' in o && 'data' in o;
const isObj = (v: any) => v && typeof v === 'object' && !Array.isArray(v);

/** Empty value for a spec (what an untouched Add-asset category holds). */
function blank(spec: Spec | undefined): any {
  if (Array.isArray(spec)) return [];
  if (spec && typeof spec === 'object') return Object.fromEntries(Object.entries(spec).map(([k, s]) => [k, blank(s)]));
  return null;
}

/** Drop empty leaves / rows / objects before saving, so the Overview stays free of blanks. */
export function prune(v: any): any {
  if (Array.isArray(v)) {
    const out = v.map(prune).filter((x) => x !== undefined);
    return out;
  }
  if (isObj(v)) {
    const out: any = {};
    for (const [k, x] of Object.entries(v)) {
      const p = prune(x);
      if (p !== undefined && !(Array.isArray(p) && p.length === 0 && !(Array.isArray(x) && x.length))) out[k] = p;
    }
    return Object.keys(out).length ? out : undefined;
  }
  return v === null || v === '' ? undefined : v;
}

/** The asset's summary columns (register, CIS matching, risk), read from the edited telemetry
 *  categories so the form has one place to type them. Only touched categories contribute. */
export function summaryFromTelemetry(edits: Record<string, any>): Record<string, any> {
  const out: Record<string, any> = {};
  const set = (k: string, v: any) => { if (v !== null && v !== undefined && v !== '' && !(Number.isNaN(v))) out[k] = v; };
  const num = (v: any) => (v === null || v === undefined || v === '' ? undefined : Number(v));
  const id = edits.identity;
  if (isObj(id)) {
    set('manufacturer', id.manufacturer); set('model', id.model);
    set('serial_number', id.serial || id.bios_serial); set('fqdn', id.fqdn);
    set('os_version', id.distro_version);   // Linux keeps its OS in identity
  }
  const cpu = edits.cpu;
  if (isObj(cpu)) set('cpu_cores', num(cpu.logical_processors ?? cpu.physical_cores ?? cpu.cpus));
  if (isObj(edits.memory)) set('memory_gb', num(edits.memory.total_gb));
  const disks = isObj(edits.storage) && Array.isArray(edits.storage.physical_disks) ? edits.storage.physical_disks : [];
  const diskGb = disks.reduce((t: number, d: any) => t + (Number(d?.size_gb) || 0), 0);
  if (diskGb) set('storage_gb', Math.round(diskGb));
  const net = edits.network;
  const nics: any[] = Array.isArray(net) ? net : isObj(net) && Array.isArray(net.interfaces) ? net.interfaces : [];
  set('primary_mac', nics.find((n) => n?.mac)?.mac);
  const os = edits.os;
  if (isObj(os)) { set('os_version', os.version); set('os_build', os.build); set('os_edition', os.edition); }
  // AV / EDR: the backend re-derives the posture from the security_products / defender sections.
  return out;
}

const INPUT = 'w-full rounded border border-slate-200 bg-white px-2.5 py-1 text-[13px] text-slate-900 focus:border-blue-500 focus:outline-none';

function Leaf({ label, value, type, onChange }: { label: string; value: any; type: 's' | 'n' | 'b'; onChange: (v: any) => void }) {
  return (
    <label className="block min-w-0">
      <span className="mb-0.5 block truncate text-[11px] font-medium text-slate-500">{label}</span>
      {type === 'b' ? (
        <select value={value == null ? '' : value ? 'yes' : 'no'} onChange={(e) => onChange(e.target.value === '' ? null : e.target.value === 'yes')} className={INPUT}>
          <option value="">—</option><option value="yes">Yes</option><option value="no">No</option>
        </select>
      ) : (
        <input type={type === 'n' ? 'number' : 'text'} value={value ?? ''} placeholder={label}
          onChange={(e) => onChange(e.target.value === '' ? null : type === 'n' ? Number(e.target.value) : e.target.value)} className={INPUT} />
      )}
    </label>
  );
}

/** Comma-separated list. Keeps its own draft so a trailing comma survives while typing. */
function ListInput({ items, onChange }: { items: any[]; onChange: (v: string[]) => void }) {
  const [draft, setDraft] = useState(() => items.join(', '));
  const parse = (s: string) => s.split(',').map((x) => x.trim()).filter(Boolean);
  // Re-sync when the list changes from outside (e.g. a row above was removed).
  const joined = items.join('\u0000');
  useEffect(() => { if (parse(draft).join('\u0000') !== joined) setDraft(items.join(', ')); }, [joined]); // eslint-disable-line react-hooks/exhaustive-deps
  return <input value={draft} placeholder="Comma-separated" className={INPUT}
    onChange={(e) => { setDraft(e.target.value); onChange(parse(e.target.value)); }} />;
}

const leafType = (value: any, spec: Spec | undefined): 's' | 'n' | 'b' =>
  typeof value === 'number' ? 'n' : typeof value === 'boolean' ? 'b' : typeof spec === 'string' ? spec : 's';

const rowTitle = (r: any, i: number) => {
  const pick = ['name', 'display_name', 'product', 'profile', 'mount_point', 'mount', 'drive_letter', 'slot', 'id', 'description', 'model'];
  for (const k of pick) if (r && typeof r[k] === 'string' && r[k].trim()) return r[k];
  return `Row ${i + 1}`;
};

/** A list of objects: paged rows, each opening into its own fields. */
function Rows({ rows, spec, fields, onChange }: { rows: any[]; spec: Spec | undefined; fields?: string[]; onChange: (v: any[]) => void }) {
  const [shown, setShown] = useState(PAGE);
  const [q, setQ] = useState('');
  const itemSpec = Array.isArray(spec) ? spec[0] : undefined;
  const indexed = rows.map((r, i) => [r, i] as const);
  const hits = q ? indexed.filter(([r]) => JSON.stringify(r).toLowerCase().includes(q.toLowerCase())) : indexed;
  const addRow = () => {
    const keys = isObj(itemSpec) ? itemSpec : Object.fromEntries((fields || Object.keys(rows[0] || {})).map((k) => [k, 's' as Spec]));
    onChange([blank(keys), ...rows]);
    setQ('');
  };
  return (
    <div className="space-y-1.5">
      <div className="flex items-center gap-2">
        {rows.length > PAGE && <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={`Search ${rows.length} rows`} className={INPUT + ' max-w-[240px]'} />}
        <span className="text-[11px] text-slate-400">{rows.length} row{rows.length === 1 ? '' : 's'}</span>
        <button type="button" onClick={addRow} className="ml-auto inline-flex items-center gap-1 rounded border border-slate-200 px-2 py-0.5 text-[11px] font-medium text-slate-700 hover:bg-slate-50"><Plus size={12} />Add row</button>
      </div>
      {hits.slice(0, shown).map(([r, i]) => (
        <details key={i} className="group rounded border border-slate-200 bg-slate-50/50">
          <summary className="flex cursor-pointer list-none items-center gap-2 px-2.5 py-1.5">
            <ChevronRight size={12} className="shrink-0 text-slate-400 transition-transform group-open:rotate-90" />
            <span className="min-w-0 flex-1 truncate text-[12px] font-medium text-slate-800">{rowTitle(r, i)}</span>
            <button type="button" aria-label="Remove row" onClick={(e) => { e.preventDefault(); onChange(rows.filter((_, j) => j !== i)); }} className="text-slate-400 hover:text-red-600"><X size={13} /></button>
          </summary>
          <div className="border-t border-slate-200 bg-white p-2.5">
            <Node value={r} spec={itemSpec} fields={fields} onChange={(v) => onChange(rows.map((x, j) => (j === i ? v : x)))} />
          </div>
        </details>
      ))}
      {hits.length > shown && (
        <button type="button" onClick={() => setShown(shown + 25)} className="text-[11px] font-medium text-blue-700 hover:underline">Show {Math.min(25, hits.length - shown)} more of {hits.length - shown}</button>
      )}
    </div>
  );
}

/** Any telemetry value, by shape: fields, sub-groups, lists and rows. */
function Node({ value, spec, fields, onChange }: { value: any; spec: Spec | undefined; fields?: string[]; onChange: (v: any) => void }) {
  const listSpec = Array.isArray(spec) ? spec : undefined;
  if (Array.isArray(value) || listSpec) {
    const arr: any[] = Array.isArray(value) ? value : [];
    const scalarList = arr.length ? arr.every((x) => !isObj(x)) : typeof listSpec?.[0] === 'string';
    if (scalarList) return <ListInput items={arr} onChange={onChange} />;
    return <Rows rows={arr} spec={listSpec} fields={fields} onChange={onChange} />;
  }
  if (isObj(value) || isObj(spec)) {
    const obj = isObj(value) ? value : {};
    const specObj = isObj(spec) ? (spec as Record<string, Spec>) : {};
    const keys = fields || Array.from(new Set([...Object.keys(specObj), ...Object.keys(obj)]));
    const set = (k: string, v: any) => onChange({ ...obj, [k]: v });
    const nested = (k: string) => Array.isArray(obj[k]) || isObj(obj[k]) || Array.isArray(specObj[k]) || isObj(specObj[k]);
    const scalarKeys = keys.filter((k) => !nested(k) || (Array.isArray(obj[k] ?? specObj[k]) && (obj[k] ?? []).every((x: any) => !isObj(x)) && !isObj((specObj[k] as any)?.[0])));
    const groupKeys = keys.filter((k) => !scalarKeys.includes(k));
    return (
      <div className="space-y-3">
        {scalarKeys.length > 0 && (
          <div className="grid grid-cols-3 gap-x-3 gap-y-2">
            {scalarKeys.map((k) => (Array.isArray(obj[k]) || Array.isArray(specObj[k])
              ? <label key={k} className="block min-w-0"><span className="mb-0.5 block truncate text-[11px] font-medium text-slate-500">{humanize(k)}</span><Node value={obj[k]} spec={specObj[k]} onChange={(v) => set(k, v)} /></label>
              : <Leaf key={k} label={humanize(k)} value={obj[k]} type={leafType(obj[k], specObj[k])} onChange={(v) => set(k, v)} />))}
          </div>
        )}
        {groupKeys.map((k) => (
          <div key={k}>
            <div className="mb-1 text-[10.5px] font-semibold uppercase tracking-wide text-slate-600">{humanize(k)}</div>
            <div className="rounded border border-slate-100 p-2"><Node value={obj[k]} spec={specObj[k]} onChange={(v) => set(k, v)} /></div>
          </div>
        ))}
      </div>
    );
  }
  return <Leaf label="Value" value={value} type={leafType(value, spec)} onChange={onChange} />;
}

function summary(v: any): string {
  if (Array.isArray(v)) return `${v.length} row${v.length === 1 ? '' : 's'}`;
  if (isObj(v)) {
    const n = Object.values(v).filter((x) => prune(x) !== undefined && !(Array.isArray(x) && !x.length)).length;
    return n ? `${n} field${n === 1 ? '' : 's'}` : 'empty';
  }
  return v == null || v === '' ? 'empty' : '1 field';
}

export default function TelemetryEditor({ platformProperties, software, osFamily, edits, onEdit }: {
  /** The asset's stored platform_properties (null on Add). */
  platformProperties: any;
  /** The asset's detected_software_json (installed packages). */
  software: any[] | null | undefined;
  osFamily: string;
  /** Touched categories only: section key -> data (SOFTWARE_KEY -> package rows). */
  edits: Record<string, any>;
  onEdit: (key: string, data: any) => void;
}) {
  const pp = isObj(platformProperties) ? platformProperties : {};
  const linux = /linux|ubuntu|debian|rhel|centos|unix/i.test(osFamily || '') || (!osFamily && 'packages' in pp);
  const template = linux ? LINUX : WINDOWS;

  const domains = useMemo(() => {
    const present = Object.keys(pp).filter((k) => !NON_SECTIONS.has(k) && isSection(pp[k]));
    const keys = Array.from(new Set([...present, ...Object.keys(template), SOFTWARE_KEY]));
    const placed = new Set(DOMAINS.flatMap((d) => d.keys));
    return DOMAINS.map((d) => ({
      ...d,
      // Collector sections the Overview files under "Other" read as software configuration.
      secs: [...d.keys.filter((k) => keys.includes(k)), ...(d.key === 'software' ? keys.filter((k) => !placed.has(k)) : [])],
    })).filter((d) => d.secs.length);
  }, [pp, template]);

  const valueOf = (k: string) => {
    if (k in edits) return edits[k];
    if (k === SOFTWARE_KEY) return Array.isArray(software) ? software : [];
    const d = isSection(pp[k]) ? pp[k].data : undefined;
    return d === undefined || d === null ? blank(template[k]) : d;
  };
  const specOf = (k: string): Spec | undefined => (k === SOFTWARE_KEY ? SOFTWARE_SPEC : template[k]);

  return (
    <div className="space-y-3">
      {domains.map((d) => (
        <div key={d.key} className="overflow-hidden rounded-lg border border-slate-200">
          <div className="border-b border-slate-100 bg-slate-50 px-3 py-2">
            <div className="text-[12.5px] font-semibold text-slate-900">{d.label}</div>
            <div className="text-[11px] text-slate-500">{d.sub}</div>
          </div>
          {d.secs.map((k) => {
            const v = valueOf(k);
            const status = isSection(pp[k]) ? pp[k].status : null;
            return (
              <details key={k} className="group border-t border-slate-100 first:border-t-0">
                <summary className="flex cursor-pointer list-none items-center gap-2 px-3 py-1.5 hover:bg-slate-50">
                  <ChevronRight size={12} className="shrink-0 text-slate-400 transition-transform group-open:rotate-90" />
                  <span className="flex-1 text-[12.5px] font-medium text-slate-800">{humanize(k)}</span>
                  {k in edits && <span className="rounded bg-amber-50 px-1.5 text-[10px] font-semibold text-amber-700">edited</span>}
                  {status && status !== 'discovered' && !(k in edits) && <span className="text-[10px] text-slate-400">{humanize(status)}</span>}
                  <span className="text-[11px] text-slate-400">{k === SOFTWARE_KEY ? `${(v || []).length} packages` : summary(v)}</span>
                </summary>
                <div className="px-3 pb-3 pt-1">
                  <Node value={v} spec={specOf(k)} fields={k === SOFTWARE_KEY ? ['name', 'version', 'publisher', 'source'] : undefined}
                    onChange={(next) => onEdit(k, next)} />
                </div>
              </details>
            );
          })}
        </div>
      ))}
    </div>
  );
}
