'use client';

/*
 * Telemetry card kit for the asset Overview toggle pages (_overview-design.tsx):
 * atoms (Card / Row / Pill / Bar), the generic section-card renderer every
 * uncurated collector section falls back to, and the curated host cards
 * (Hardware / Software / Security). Curated cards always end with <Rest>, which
 * renders any field of the section they did not place explicitly — so a collector
 * adding a field can never make it silently disappear.
 */

import React, { useState } from 'react';
import { toItems, blocksFor } from './_overview-map';

/* eslint-disable @typescript-eslint/no-explicit-any */

const LAYOUT: Record<string, 'half' | 'full'> = { 'Network Adapters': 'full', 'Local Users': 'full', 'Local Groups': 'full', Services: 'full', Shares: 'full' };

export const MONO = "font-['IBM_Plex_Mono',ui-monospace,monospace]";
const SHADOW = 'shadow-[0_1px_2px_rgba(16,24,40,0.04)]';
export const CARD = `bg-white border border-[#e8ecee] rounded-xl overflow-hidden ${SHADOW}`;
export const TONE: Record<string, string> = { ok: '#014A81', warn: '#9a6410', bad: '#b23a3a', muted: '#8a95a1' };
const TH = 'text-left sticky top-0 bg-[#fafbfc] text-[#3a4653] font-bold text-[10px] tracking-[0.04em] uppercase px-3 py-2 border-b border-[#e8ecee]';
const TD = 'px-3 py-2 border-b border-[#f0f3f5] align-top';

export const isObj = (v: any) => v && typeof v === 'object' && !Array.isArray(v);
const has = (v: any) => !(v === null || v === undefined || v === '' || (Array.isArray(v) && v.length === 0));
export const sec = (pp: any, k: string) => (pp && isObj(pp[k]) && 'status' in pp[k] && 'data' in pp[k] ? pp[k] : null);
export const dataOf = (pp: any, k: string) => sec(pp, k)?.data;
const num = (v: any) => (typeof v === 'number' ? v.toLocaleString() : v);
const day = (s: any) => (s ? String(s).slice(0, 10) : '—');
const stamp = (s: any) => (s ? String(s).replace('T', ' ').slice(0, 16) : '—');
const words = (s: any) => String(s ?? '').replace(/([a-z])([A-Z])/g, '$1 $2');
const omit = (o: any, keys: string[]) => Object.fromEntries(Object.entries(o || {}).filter(([k]) => !keys.includes(k)));

/* ── atoms ─────────────────────────────────────────────────────────────── */

export function Card({ title, meta, warn, span, children, className = '' }: { title: React.ReactNode; meta?: React.ReactNode; warn?: boolean; span?: 2 | 3; children: React.ReactNode; className?: string }) {
  const cls = warn ? 'bg-[#fffaf0] border border-[#f0d9a8] rounded-xl overflow-hidden ' + SHADOW : CARD;
  return (
    <section className={cls + (span === 2 ? ' lg:col-span-2' : span === 3 ? ' lg:col-span-3' : '') + ' flex flex-col ' + className}>
      <div className="flex items-baseline justify-between gap-3 px-3.5 pt-2.5 pb-1.5">
        <h4 className="text-[13px] font-bold text-[#0f1f2b] m-0">{title}</h4>
        {meta != null && <span className={'text-[10.5px] whitespace-nowrap ' + (warn ? 'font-semibold text-[#b45309]' : 'text-[#8a95a1]')}>{meta}</span>}
      </div>
      <div className="px-3.5 pb-3 flex-1 min-w-0">{children}</div>
    </section>
  );
}

export function Row({ label, value, mono, tone, title, emptyText = 'not collected' }: { label: React.ReactNode; value: any; mono?: boolean; tone?: string; title?: string; emptyText?: string }) {
  const empty = !has(value) || value === '—';
  const long = typeof value === 'string' && value.length > 30;   // long values wrap across both columns, never clipped
  return (
    <div className={'flex items-baseline justify-between gap-3 py-[3px] min-w-0' + (long ? ' sm:col-span-2' : '')}>
      <span className="text-[11.5px] text-[#6b7787] whitespace-nowrap">{label}</span>
      <span title={title || (typeof value === 'string' ? value : undefined)}
        className={(mono && !empty ? MONO + ' text-[11.5px]' : 'text-[12px]') + ' text-right min-w-0 ' + (long ? 'break-words' : 'truncate')}
        style={{ color: empty ? '#aeb8c2' : TONE[tone || ''] || '#0f1f2b', fontStyle: empty ? 'italic' : undefined }}>
        {empty ? emptyText : value}
      </span>
    </div>
  );
}

function Pill({ on, children, warn }: { on: boolean; children: React.ReactNode; warn?: boolean }) {
  const c = on ? 'text-[#1f7a54] bg-[#e7f5ee] border-[#bfe3cf]' : warn ? 'text-[#9a6410] bg-[#fbf2df] border-[#f0d9a8]' : 'text-[#6b7787] bg-[#f1f4f6] border-[#e1e6ea]';
  return <span className={'inline-block text-[10.5px] font-semibold rounded-md px-1.5 py-[1px] border whitespace-nowrap ' + c}>{children}</span>;
}

function Bar({ pct }: { pct: number }) {
  return <div className="h-[6px] flex-1 rounded-full bg-[#eef1f3] overflow-hidden"><div className="h-full rounded-full bg-[#005B96]" style={{ width: Math.max(2, Math.min(100, pct)) + '%' }} /></div>;
}

export const Muted = ({ children }: { children: React.ReactNode }) => <div className="text-[11.5px] text-[#aeb8c2] italic py-1">{children}</div>;
export const Sub = ({ children }: { children: React.ReactNode }) => <div className="text-[10px] font-bold tracking-[0.05em] uppercase text-[#8a95a1] mt-2 mb-0.5">{children}</div>;

/** Leftover fields of a curated section — scalars as rows, nested data as generic blocks. */
function Rest({ data, used }: { data: any; used: string[] }) {
  if (!isObj(data)) return null;
  const left = omit(data, used);
  const scalars = toItems(left);
  const nested = Object.fromEntries(Object.entries(left).filter(([, v]) => isObj(v) || (Array.isArray(v) && v.some((x) => x && typeof x === 'object'))));
  if (!scalars.length && !Object.keys(nested).length) return null;
  return (
    <>
      {scalars.map((it: any, i: number) => <Row key={i} label={it.label} value={it.value} mono={it.mono} tone={it.tone} />)}
      {Object.keys(nested).length > 0 && <div className="mt-1.5 flex flex-col gap-2 sm:col-span-2">{blocksFor('details', nested).map((b: any, i: number) => <Block key={i} b={b} />)}</div>}
    </>
  );
}

/* ── generic section rendering (unchanged block grammar, now as cards) ── */

function Cell({ label, value, tone, mono }: any) {
  const empty = value === '—' || value === '' || value == null;
  const v = empty ? 'Not set' : value;
  const wide = !empty && typeof v === 'string' && v.length > 24;
  const color = empty ? '#8a95a1' : TONE[tone] || '#0f1f2b';
  return (
    <div className={'min-w-0' + (wide ? ' sm:col-span-2' : '')}>
      <div className="text-[10px] font-bold tracking-[0.05em] uppercase text-[#8a95a1] mb-0.5">{label}</div>
      <div className={(mono ? MONO + ' text-[12px]' : 'text-[13px]') + ' break-words leading-snug'} style={{ color, fontStyle: empty ? 'italic' : undefined }}>{v}</div>
    </div>
  );
}

// Field list in the mock's label-left / value-right rows; two columns when long.
function KV({ items }: { items: any[] }) {
  return (
    <div className={items.length > 5 ? 'grid sm:grid-cols-2 gap-x-6' : ''}>
      {items.map((it, i) => <Row key={i} label={it.label} value={it.value === '—' ? null : it.value} mono={it.mono} tone={it.tone} />)}
    </div>
  );
}

function ObjList({ label, objects }: { label?: string; objects: any[] }) {
  return (
    <div>
      {label && <Sub>{label}</Sub>}
      <div className="grid grid-cols-[repeat(auto-fit,minmax(220px,1fr))] gap-2">
        {objects.map((o, i) => (
          <div key={i} className="border border-[#f0f3f5] bg-[#fafbfc] rounded-lg px-3 py-2.5">
            <div className="grid grid-cols-[repeat(auto-fit,minmax(110px,1fr))] gap-x-3.5 gap-y-2">{o.map((it: any, j: number) => <Cell key={j} {...it} />)}</div>
          </div>
        ))}
      </div>
    </div>
  );
}

function SmallTable({ head, children, max = 'max-h-[300px]' }: { head: React.ReactNode; children: React.ReactNode; max?: string }) {
  return (
    <div className="border border-[#f0f3f5] rounded-lg overflow-hidden">
      <div className={max + ' overflow-auto'}>
        <table className="w-full border-collapse text-[12px]"><thead>{head}</thead><tbody>{children}</tbody></table>
      </div>
    </div>
  );
}

function UsersTable({ rows }: { rows: any[] }) {
  return (
    <SmallTable max="max-h-[200px]" head={<tr><th className={TH}>Account</th><th className={TH}>SID</th><th className={TH}>Lockout</th><th className={TH + ' text-center'}>Status</th></tr>}>
      {rows.map((r, i) => (
        <tr key={i}>
          <td className={TD}><div className="font-semibold text-[#0f1f2b]">{r[1]}</div>{r[0] && r[0] !== '—' && <div className="text-[#8a95a1] text-[11px]">{r[0]}</div>}</td>
          <td className={TD + ' text-[#8a95a1] text-[10.5px] break-all ' + MONO}>{r[2]}</td>
          <td className={TD + ' text-[#3a4653]'}>{r[3] === '✓' ? 'Locked' : '—'}</td>
          <td className={TD + ' text-center'}><Pill on={r[4] !== '✓'}>{r[4] === '✓' ? 'Disabled' : 'Enabled'}</Pill></td>
        </tr>
      ))}
    </SmallTable>
  );
}

function GenericTable({ headers, rows }: { headers: string[]; rows: any[] }) {
  return (
    <SmallTable head={<tr>{headers.map((h, i) => <th key={i} className={TH}>{h}</th>)}</tr>}>
      {rows.map((r, i) => <tr key={i}>{r.map((c: any, j: number) => <td key={j} className={TD + (j === 0 ? ' font-semibold text-[#0f1f2b]' : ' text-[#3a4653]')}>{c}</td>)}</tr>)}
    </SmallTable>
  );
}

function Block({ b }: { b: any }) {
  if (b.type === 'note') return <div className="text-[12px] text-[#8a95a1] italic leading-snug">{b.text}</div>;
  if (b.type === 'kv') return <KV items={b.items} />;
  if (b.type === 'sub') return <div><Sub>{b.label}</Sub><KV items={b.items} /></div>;
  if (b.type === 'objlist') return <ObjList label={b.label} objects={b.objects} />;
  if (b.type === 'stat') return <div className="flex gap-2">{b.items.map((it: any, i: number) => <Tile key={i} n={it.value} label={it.label} />)}</div>;
  if (b.type === 'table' && b.variant === 'users') return <UsersTable rows={b.rows} />;
  if (b.type === 'table' && b.variant === 'groups') return <GenericTable headers={['Group', 'Description']} rows={b.rows} />;
  if (b.type === 'table') return <div>{b.label && <Sub>{b.label}</Sub>}<GenericTable headers={b.headers} rows={b.rows} /></div>;
  return null;
}

function secSummary(s: any): string {
  if (s.rows) return `${s.rows.length} rows`;
  let n = 0;
  for (const b of (s.blocks || [])) {
    if (b.type === 'table') return `${(b.rows || []).length} rows`;
    if (b.type === 'objlist') n += (b.objects || []).length;
    else if (b.items) n += b.items.length;
  }
  return n ? `${n} field${n === 1 ? '' : 's'}` : (s.status || '');
}

const spanOf = (s: any): 'half' | 'full' => {
  const blocks = s.blocks || [];
  const wide = s.variant === 'services' || blocks.some((b: any) => b.type === 'table') || blocks.some((b: any) => b.type === 'objlist' && (b.objects || []).length >= 3);
  return LAYOUT[s.title] || (wide ? 'full' : 'half');
};

export function SectionCards({ secs }: { secs: any[] }) {
  if (!secs.length) return null;
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 grid-flow-row-dense gap-2.5 mt-2.5">
      {secs.map((s: any, i: number) => (
        <Card key={i} title={s.title} meta={secSummary(s)} span={spanOf(s) === 'full' ? 2 : undefined}>
          {s.variant === 'services'
            ? <GenericTable headers={['Name', 'Display name', 'State', 'Start', 'Account', 'Path']} rows={s.rows.map((r: any) => [r[1], r[5], r[4], r[3], r[0], r[2]])} />
            : <div className="flex flex-col gap-3">{(s.blocks || []).map((b: any, j: number) => <Block key={j} b={b} />)}</div>}
        </Card>
      ))}
    </div>
  );
}

function Tile({ n, label, sub, on, onClick }: { n: any; label: string; sub?: React.ReactNode; on?: boolean; onClick?: () => void }) {
  return (
    <button type="button" onClick={onClick} disabled={!onClick}
      className={'flex-1 min-w-0 text-left rounded-xl border px-3 py-2 ' + (on ? 'bg-[#EFF5FA] border-[#9cc0dd] ring-1 ring-[#005B96]/30' : 'bg-[#f6f8f9] border-[#eef1f3]') + (onClick ? ' cursor-pointer hover:border-[#9cc0dd]' : ' cursor-default')}>
      <div className={'text-[20px] font-bold leading-none text-[#0f1f2b] ' + MONO}>{num(n) ?? '—'}</div>
      <div className="text-[11.5px] font-semibold text-[#3a4653] mt-1">{label}</div>
      {sub && <div className="text-[10.5px] text-[#8a95a1] truncate">{sub}</div>}
    </button>
  );
}

export function ProvenanceCard({ card, wide }: { card: any; wide?: boolean }) {
  const setCount = card.fields.filter((f: any) => f.value !== '—' && f.value !== '' && f.value != null).length;
  return (
    <Card span={wide ? 2 : undefined} title={card.title} meta={<span className="inline-flex items-center gap-2"><span className="text-[#c79a3a] font-semibold">{setCount} of {card.fields.length} set</span>{card.onEdit && <a onClick={card.onEdit} className="text-[11.5px] font-semibold text-[#005B96] cursor-pointer">Edit</a>}</span>}>
      <div className="h-1 bg-[#f4f6f7] rounded-full overflow-hidden mb-2.5"><div className="h-full bg-[#e2b33c]" style={{ width: Math.round((setCount / card.fields.length) * 100) + '%' }} /></div>
      <div className={'grid grid-flow-row-dense gap-x-6 sm:grid-cols-2 ' + (wide ? 'lg:grid-cols-4' : '')}>
        {card.fields.map((f: any, i: number) => <Row key={i} label={f.label} value={f.value === '—' ? null : f.value} mono={f.mono} tone={f.tone} emptyText="Not set" />)}
      </div>
    </Card>
  );
}

/* ── curated host cards ─────────────────────────────────────────────────── */

const MEM_TYPE: Record<string, string> = { '20': 'DDR', '21': 'DDR2', '24': 'DDR3', '26': 'DDR4', '27': 'LPDDR', '28': 'LPDDR2', '29': 'LPDDR3', '30': 'LPDDR4', '34': 'DDR5', '35': 'LPDDR5' };
const NIC_STATUS: Record<string, string> = { '0': 'Disconnected', '1': 'Connecting', '2': 'Up', '3': 'Disconnecting', '4': 'Not present', '5': 'Disabled', '6': 'Malfunction', '7': 'Disconnected', '8': 'Authenticating', '9': 'Up', '10': 'Auth failed', '11': 'Invalid address', '12': 'Credentials required' };
const maskBits = (m: any) => (/^\d+\.\d+\.\d+\.\d+$/.test(String(m || '')) ? String(m).split('.').reduce((n, o) => n + (+o).toString(2).split('1').length - 1, 0) : null);
const speed = (bps: any) => (typeof bps !== 'number' || bps <= 0 || bps >= 9e18 ? null : bps >= 1e9 ? `${+(bps / 1e9).toFixed(1)} Gbps` : `${Math.round(bps / 1e6)} Mbps`);
const list = (v: any) => (Array.isArray(v) ? v.filter((x) => x !== null && x !== '') : has(v) ? [v] : []);

export function HardwareCards({ A }: { A: any }) {
  const { pp, asset } = A.raw;
  const idn = dataOf(pp, 'identity') || {};
  const cpu = dataOf(pp, 'cpu');
  const mem = dataOf(pp, 'memory');
  const sto = dataOf(pp, 'storage');
  const fw = dataOf(pp, 'firmware');
  const gpuD = dataOf(pp, 'gpu');
  const gpus = Array.isArray(gpuD) ? gpuD : isObj(gpuD) ? [gpuD] : [];
  const net = dataOf(pp, 'network');
  const nics: any[] = Array.isArray(net) ? net : isObj(net) && Array.isArray(net.interfaces) ? net.interfaces : [];
  const [showFolded, setShowFolded] = useState(false);
  const folded = nics.filter((n) => /wan miniport/i.test(n?.description || ''));
  const shownNics = showFolded ? nics : nics.filter((n) => !folded.includes(n));
  const dimms: any[] = isObj(mem) && Array.isArray(mem.dimms) ? mem.dimms : [];
  const disks: any[] = isObj(sto) && Array.isArray(sto.physical_disks) ? sto.physical_disks.filter((d: any) => !/^(loop|ram|sr|fd)\d/i.test(String(d?.name ?? ''))) : [];
  const vols: any[] = isObj(sto) ? (Array.isArray(sto.volumes) ? sto.volumes : Array.isArray(sto.mounts) ? sto.mounts : []) : [];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-2.5">
      <Card title="System" span={2} meta={`${Object.keys(idn).length} fields`}>
        <div className="grid sm:grid-cols-2 grid-flow-row-dense gap-x-6">
        <Row label="Make" value={idn.manufacturer || asset?.manufacturer} />
        <Row label="Model" value={idn.model || asset?.model} mono />
        <Row label="Product" value={fw?.motherboard?.product} mono />
        <Row label="Serial" value={idn.serial || asset?.serial_number} mono />
        <Row label="FQDN" value={idn.fqdn || asset?.fqdn} mono />
        <Row label="Hostname" value={idn.hostname || asset?.host_name} mono />
        {has(idn.domain || idn.workgroup) && <Row label={idn.part_of_domain ? 'Domain' : 'Workgroup'} value={idn.part_of_domain ? idn.domain : (idn.workgroup || idn.domain)} />}
        <Rest data={idn} used={['manufacturer', 'model', 'serial', 'fqdn', 'hostname', 'domain', 'workgroup', 'part_of_domain', ...(idn.bios_serial === idn.serial ? ['bios_serial'] : []), ...(sec(pp, 'os') ? [] : ['distribution', 'distro_id', 'distro_version', 'kernel'])]} />
        </div>
      </Card>

      <Card title="Memory" meta={dimms.length ? `${dimms.length} DIMM${dimms.length > 1 ? 's' : ''}` : undefined}>
        {isObj(mem) ? (
          <>
            <div className="flex items-baseline gap-2 mb-1.5">
              <span className={'text-[22px] font-bold text-[#0f1f2b] ' + MONO}>{has(mem.total_gb) ? `${mem.total_gb} GB` : '—'}</span>
              {dimms.length > 0 && <span className="text-[11.5px] text-[#6b7787]">{dimms.length} module{dimms.length > 1 ? 's' : ''} installed</span>}
            </div>
            <div className="flex flex-col gap-1.5">
              {dimms.map((d, i) => (
                <div key={i} className="rounded-lg border border-[#e8ecee] bg-[#fafbfc] px-2.5 py-1.5" title={`Part ${d.part_number || '—'} · Serial ${d.serial || '—'}`}>
                  <div className="flex justify-between gap-2 text-[11.5px]"><span className="text-[#3a4653] truncate">{d.slot || `DIMM ${i}`}</span><span className={MONO + ' text-[#0f1f2b] whitespace-nowrap'}>{d.capacity_gb != null ? `${d.capacity_gb} GB` : '—'} {MEM_TYPE[String(d.type)] || d.type || ''}{d.speed_mhz ? `-${d.speed_mhz}` : ''}</span></div>
                  <div className={'text-[10px] text-[#8a95a1] truncate ' + MONO}>{[d.manufacturer, d.part_number, d.serial && `S/N ${d.serial}`].filter(Boolean).join(' · ')}</div>
                  <Rest data={d} used={['slot', 'capacity_gb', 'type', 'speed_mhz', 'manufacturer', 'part_number', 'serial']} />
                </div>
              ))}
            </div>
            <Rest data={mem} used={['total_gb', 'dimms']} />
          </>
        ) : <Muted>Memory not collected</Muted>}
      </Card>

      <Card title="CPU" meta={isObj(cpu) ? `${Object.keys(cpu).length} fields` : undefined}>
        {isObj(cpu) ? (
          <>
            <div className="text-[13px] font-semibold text-[#0f1f2b] mb-1 truncate" title={cpu.model}>{String(cpu.model || '—').replace(/\(R\)|\(TM\)/g, '')}</div>
            {has(cpu.physical_cores) && <Row label="Cores / threads" value={`${cpu.physical_cores} / ${cpu.logical_processors ?? '—'}`} mono />}
            {has(cpu.clock_mhz) && <Row label="Base clock" value={`${(cpu.clock_mhz / 1000).toFixed(2)} GHz`} mono />}
            <Row label="Architecture" value={cpu.architecture} mono />
            <Row label="Manufacturer" value={cpu.manufacturer || cpu.vendor} />
            <Rest data={cpu} used={['model', 'physical_cores', 'logical_processors', 'clock_mhz', 'architecture', 'manufacturer', 'vendor']} />
          </>
        ) : <Muted>CPU not collected</Muted>}
      </Card>

      <Card title="Firmware & GPU" span={2} meta={gpus.length ? `${gpus.length} GPU${gpus.length > 1 ? 's' : ''}` : undefined}>
        <div className="grid sm:grid-cols-2 gap-x-6">
          <div>
            {isObj(fw) ? (
              <>
                <Row label="BIOS" value={[fw.bios?.vendor, fw.bios?.version].filter(Boolean).join(' ') || null} mono />
                <Row label="BIOS date" value={fw.bios?.date ? day(String(fw.bios.date).replace(/^(\d\d)\/(\d\d)\/(\d{4}).*/, '$3-$1-$2')) : null} mono />
                <Row label="Boot mode" value={fw.bios?.mode} mono />
                <Row label="Board" value={[fw.motherboard?.manufacturer, fw.motherboard?.product].filter(Boolean).join(' ') || null} mono />
                <Row label="Board serial" value={fw.motherboard?.serial} mono />
                <Rest data={fw.bios} used={['vendor', 'version', 'date', 'mode']} />
                <Rest data={fw.motherboard} used={['manufacturer', 'product', 'serial']} />
                <Rest data={fw} used={['bios', 'motherboard']} />
              </>
            ) : <Muted>Firmware not collected</Muted>}
          </div>
          <div>
            {gpus.length ? gpus.map((g, i) => (
              <div key={i}>
                <Row label="GPU" value={String(g.model || g.description || '—').replace(/\(R\)/g, '')} mono />
                {has(g.vendor) && <Row label="Vendor" value={g.vendor} />}
                {has(g.vram_mb) && <Row label="VRAM" value={`${num(g.vram_mb)} MB`} mono />}
                {has(g.driver_version) && <Row label="Driver" value={`${g.driver_version}${g.driver_date ? ' · ' + String(g.driver_date).slice(0, 10) : ''}`} mono />}
                <Rest data={g} used={['model', 'description', 'vendor', 'vram_mb', 'driver_version', 'driver_date']} />
              </div>
            )) : <Muted>GPU not collected</Muted>}
          </div>
        </div>
      </Card>

      <Card title="Storage" span={3} meta={disks.length ? `${disks.length} disk${disks.length > 1 ? 's' : ''}` : undefined}>
        {isObj(sto) ? (
          <>
            <div className="grid lg:grid-cols-2 gap-x-6">
            <div>
            {disks.map((d, i) => (
              <div key={i} className="mb-1.5">
                <div className="text-[12px] text-[#0f1f2b]">{d.model || d.name || 'Disk'} <span className={MONO + ' text-[#6b7787]'}>{d.size_gb != null ? `${d.size_gb} GB` : d.size || ''}</span></div>
                <div className={'text-[10px] text-[#8a95a1] break-all ' + MONO}>{[d.media_type, d.bus_type || d.interface, d.model && d.name, d.serial && `S/N ${d.serial}`].filter(Boolean).join(' · ')}</div>
                <Rest data={d} used={['model', 'name', 'size_gb', 'size', 'media_type', 'bus_type', 'interface', 'serial']} />
              </div>
            ))}
            </div>
            <div className="flex flex-col gap-1.5 mt-1 lg:mt-0">
              {vols.map((v, i) => {
                const cap = v.capacity_gb, free = v.free_gb;
                const used = typeof cap === 'number' && typeof free === 'number' ? cap - free : null;
                const pct = used != null && cap ? (used / cap) * 100 : parseFloat(String(v.use_pct || '').replace('%', '')) || 0;
                const label = `${v.drive_letter || v.mount_point || v.mount || '—'} ${v.type || v.filesystem || ''}`.trim();
                return (
                  <div key={i} title={v.mount ? `${v.filesystem || ''} · ${v.available || ''} available` : undefined}>
                    <div className="flex items-center gap-2.5">
                      <span className="text-[11.5px] text-[#3a4653] w-[92px] truncate">{label}</span>
                      <Bar pct={pct} />
                      <span className={MONO + ' text-[11px] text-[#3a4653] whitespace-nowrap'}>{used != null ? `${used} of ${cap} GB` : `${v.used || '—'} of ${v.size || '—'}`}</span>
                    </div>
                    {(v.mount || free != null) && <div className={'text-[10px] text-[#8a95a1] pl-[102px] truncate ' + MONO}>{v.mount ? [v.filesystem, v.available && `${v.available} free`, v.use_pct].filter(Boolean).join(' · ') : `${free} GB free`}</div>}
                    <Rest data={v} used={['capacity_gb', 'free_gb', 'drive_letter', 'mount_point', 'mount', 'type', 'filesystem', 'used', 'size', 'use_pct', 'available']} />
                  </div>
                );
              })}
            </div>
            </div>
            <Rest data={sto} used={['physical_disks', 'volumes', 'mounts']} />
          </>
        ) : <Muted>Storage not collected</Muted>}
      </Card>

      <Card title="Network adapters" span={3} meta={nics.length ? <span>{nics.length} adapters{folded.length ? <> · {folded.length} WAN miniports {showFolded ? 'shown' : 'folded'} <a className="text-[#005B96] font-semibold cursor-pointer ml-1" onClick={() => setShowFolded((v) => !v)}>{showFolded ? 'fold' : 'show'}</a></> : null}</span> : undefined}>
        {nics.length ? (
          <SmallTable max="max-h-[220px]" head={<tr><th className={TH}>Adapter</th><th className={TH}>IPv4 / prefix</th><th className={TH}>Addressing</th><th className={TH}>MAC</th><th className={TH}>Speed</th><th className={TH + ' text-right'}>Status</th></tr>}>
            {shownNics.map((n, i) => {
              const v4 = list(n.ipv4); const v6 = list(n.ipv6); const gw = list(n.gateway); const dns = list(n.dns);
              const bits = maskBits(list(n.subnet)[0]);
              const v6bits = list(n.subnet).find((x: any) => /^\d{1,3}$/.test(String(x)));
              const raw = String(n.status ?? n.state ?? '');
              const st = NIC_STATUS[raw] || (raw ? (/^up$/i.test(raw) ? 'Up' : /^down$/i.test(raw) ? 'Down' : raw) : '');
              return (
                <tr key={i}>
                  <td className={TD}><div className="font-semibold text-[#0f1f2b]">{String(n.description || n.name || '—').replace(/\(R\)/g, '')}</div>{n.description && n.name && <div className="text-[10.5px] text-[#8a95a1]">{n.name}</div>}</td>
                  <td className={TD + ' ' + MONO + ' text-[11.5px]'}>{v4.length ? v4.map((ip: string, j: number) => <div key={j}>{ip}{bits != null && j === 0 ? <span className="text-[#8a95a1]"> /{bits}</span> : ''}</div>) : <span className="text-[#aeb8c2]">—</span>}{v6.map((ip: string, j: number) => <div key={'6' + j} className="text-[10px] text-[#8a95a1]">{ip}{v6bits && j === 0 ? ` /${v6bits}` : ''}</div>)}</td>
                  <td className={TD + ' text-[11.5px] text-[#3a4653]'}>{n.dhcp_enabled != null ? (n.dhcp_enabled ? 'DHCP' : 'Static') : ''}{gw.length ? <span className={MONO}>{n.dhcp_enabled != null ? ' · ' : ''}gw {gw.join(', ')}</span> : ''}{dns.length ? <div className={'text-[10px] text-[#8a95a1] ' + MONO}>dns {dns.join(', ')}</div> : null}{!gw.length && !dns.length && n.dhcp_enabled == null && <span className="text-[#aeb8c2]">—</span>}</td>
                  <td className={TD + ' ' + MONO + ' text-[11.5px] text-[#3a4653]'}>{n.mac || '—'}</td>
                  <td className={TD + ' ' + MONO + ' text-[11px] text-[#6b7787] whitespace-nowrap'}>{speed(n.speed_bps) || '—'}</td>
                  <td className={TD + ' text-right'}>{st ? <Pill on={st === 'Up'}>{st}</Pill> : <span className="text-[10.5px] text-[#aeb8c2]" title="Status not reported by the adapter">not reported</span>}</td>
                </tr>
              );
            })}
          </SmallTable>
        ) : <Muted>Network adapters not collected</Muted>}
        {isObj(net) && <div className="mt-1.5"><Rest data={net} used={['interfaces']} /></div>}
      </Card>
    </div>
  );
}

// Normalise Windows (flat list) and Linux ({init_system, services}) service shapes.
function serviceRows(svcD: any): any[] {
  const rows = Array.isArray(svcD) ? svcD : isObj(svcD) && Array.isArray(svcD.services) ? svcD.services : [];
  return rows.filter((s: any) => s && typeof s === 'object').map((s: any) => ({ ...s, state: String(s.state || s.sub || '—') }));
}

export function SoftwareCards({ A }: { A: any }) {
  const { pp, asset } = A.raw;
  const os = dataOf(pp, 'os');
  const idn = dataOf(pp, 'identity') || {};
  const pkg = dataOf(pp, 'packages') || dataOf(pp, 'pkg');
  const svcD = dataOf(pp, 'services');
  const svcs = serviceRows(svcD);
  const tasks = dataOf(pp, 'scheduled_tasks');
  const shares = dataOf(pp, 'shares');
  const sw: any[] = A.security.software || [];
  const sources = Array.from(new Set(sw.map((p) => p.source).filter((s) => s && s !== '—')));
  const virtKeys = ['virtualization', 'virt', 'docker', 'podman'].filter((k) => sec(pp, k));
  const [panel, setPanel] = useState<'packages' | 'services' | 'shares' | 'tasks'>(sw.length ? 'packages' : 'services');
  const [q, setQ] = useState('');
  const [svcState, setSvcState] = useState<'all' | 'running' | 'stopped'>('all');
  const running = svcs.filter((s) => /running|active/i.test(s.state)).length;
  const ql = q.trim().toLowerCase();
  const pkgRows = ql ? sw.filter((p) => `${p.name} ${p.version} ${p.source}`.toLowerCase().includes(ql)) : sw;
  const svcRows = svcs.filter((s) => (svcState === 'all' || (svcState === 'running' ? /running|active/i.test(s.state) : !/running|active/i.test(s.state)))
    && (!ql || `${s.name} ${s.display_name || ''} ${s.account || ''} ${s.path || ''}`.toLowerCase().includes(ql)));
  const pkgCount = pkg?.installed_count ?? pkg?.count ?? sw.length;
  const shareList: any[] = Array.isArray(shares) ? shares : [];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-2.5">
      <Card title="Operating system" meta={isObj(os) ? `${Object.keys(os).length} fields` : undefined}>
        <Row label="Family" value={asset?.os_family ? asset.os_family.charAt(0).toUpperCase() + asset.os_family.slice(1) : null} />
        {isObj(os) ? (
          <div className="grid sm:grid-cols-2 gap-x-6">
            <Row label="Edition" value={String(os.edition || '').replace(/^Microsoft /, '') || asset?.os_edition} />
            <Row label="Version" value={os.version} mono />
            <Row label="Build" value={os.build || asset?.os_build} mono />
            <Row label="Architecture" value={os.architecture} mono />
            <Row label="Installed" value={os.install_date} mono />
            <Row label="Last boot" value={os.last_boot} mono />
            <Row label="Uptime" value={os.uptime_hours != null ? `${os.uptime_hours} h` : null} mono />
            <Row label="Timezone" value={os.timezone} />
            <Row label={os.part_of_domain ? 'Domain' : 'Workgroup'} value={os.domain} />
            <Rest data={os} used={['edition', 'version', 'build', 'architecture', 'install_date', 'last_boot', 'uptime_hours', 'timezone', 'domain', 'part_of_domain']} />
          </div>
        ) : (
          <>
            <Row label="Distribution" value={idn.distribution || asset?.os_version} />
            <Row label="Version" value={idn.distro_version} mono />
            <Row label="Kernel" value={idn.kernel} mono />
            <Row label="Build" value={asset?.os_build} mono />
          </>
        )}
        <Row label="Normalised OS key" value={asset?.os_normalized} mono />
      </Card>

      <Card title="Packages & agent">
        <Row label="Package manager" value={pkg?.package_manager || pkg?.manager || (sources.length ? sources.map((x) => (x === 'registry' ? 'Windows registry' : x)).join(' + ') : null)} mono />
        <Row label="Installed packages" value={pkgCount != null ? num(pkgCount) : null} mono />
        <Row label="CAIVA agent" value={asset?.agent_version || (asset?.last_seen_source ? `none · ${asset.last_seen_source} scan` : null)} mono />
        <Row label="Last report" value={stamp(asset?.last_seen_at)} mono />
        <Row label="First seen" value={day(asset?.first_seen_at || asset?.created_at)} mono />
        <Row label="Record source" value={asset?.source_system} />
        <Rest data={pkg} used={['package_manager', 'manager', 'installed_count', 'count']} />
      </Card>

      <div className="lg:col-span-2 flex gap-2.5">
        <Tile n={svcs.length || (sec(pp, 'services') ? 0 : '—')} label="Services" sub={svcs.length ? `${running} running${isObj(svcD) && svcD.init_system ? ' · ' + svcD.init_system : ''}` : 'not collected'} on={panel === 'services'} onClick={svcs.length ? () => setPanel('services') : undefined} />
        <Tile n={isObj(tasks) ? (tasks.total ?? '—') : '—'} label="Scheduled tasks" sub={isObj(tasks) ? (tasks.enabled != null ? `${num(tasks.enabled)} enabled` : '') : 'not collected'} on={panel === 'tasks'} onClick={isObj(tasks) ? () => setPanel('tasks') : undefined} />
        <Tile n={Array.isArray(shares) ? shares.length : '—'} label="Shares" sub={shareList.length ? shareList.map((s) => s.name).join(' · ') : Array.isArray(shares) ? 'none' : 'not collected'} on={panel === 'shares'} onClick={shareList.length ? () => setPanel('shares') : undefined} />
        <Tile n={sw.length || pkgCount || '—'} label="Installed packages" sub={sw.length ? 'with versions' : 'not collected'} on={panel === 'packages'} onClick={sw.length ? () => setPanel('packages') : undefined} />
      </div>

      <section className={CARD + ' lg:col-span-2'}>
        <div className="flex flex-wrap items-center gap-2 px-3.5 pt-2.5 pb-2">
          <h4 className="text-[13px] font-bold text-[#0f1f2b] m-0 mr-auto">{panel === 'packages' ? 'Installed packages' : panel === 'services' ? 'Services' : panel === 'shares' ? 'Shares' : 'Scheduled tasks'}</h4>
          {(panel === 'packages' || panel === 'services') && <input value={q} onChange={(e) => setQ(e.target.value)} placeholder={panel === 'packages' ? 'Search packages…' : 'Search services…'} className="w-[220px] text-[12px] px-2.5 py-[5px] border border-[#e8ecee] rounded-lg bg-[#fafbfc] outline-none focus:border-[#005B96]" />}
          {panel === 'services' && (['all', 'running', 'stopped'] as const).map((k) => (
            <button key={k} type="button" onClick={() => setSvcState(k)} className={'text-[11px] font-semibold px-2 py-[4px] rounded-md border ' + (svcState === k ? 'bg-[#005B96] text-white border-[#005B96]' : 'bg-white text-[#3a4653] border-[#e8ecee]')}>
              {k === 'all' ? `All ${svcs.length}` : k === 'running' ? `Running ${running}` : `Stopped ${svcs.length - running}`}
            </button>
          ))}
        </div>
        <div className="px-3.5 pb-2.5">
          {panel === 'packages' && (
            <>
              <SmallTable max="max-h-[260px]" head={<tr><th className={TH}>Package</th><th className={TH}>Version</th><th className={TH}>Source</th><th className={TH}>Tracked as asset</th></tr>}>
                {pkgRows.map((p, i) => (
                  <tr key={i} onClick={p.onClick} className={p.onClick ? 'cursor-pointer hover:bg-[#fafbfc]' : undefined}>
                    <td className={TD + ' font-semibold text-[#0f1f2b]'}>{p.name}</td>
                    <td className={TD + ' text-[#3a4653] text-[11.5px] ' + MONO}>{p.version}</td>
                    <td className={TD + ' text-[#6b7787]'}>{p.source === 'registry' ? 'Registry' : p.source}</td>
                    <td className={TD}>{!p.tracked || p.tracked === '—' ? <span className="text-[#aeb8c2]">—</span> : <span className="text-[11.5px] font-semibold text-[#005B96]">{p.tracked}</span>}</td>
                  </tr>
                ))}
              </SmallTable>
              {pkgRows.length === 0 && <Muted>No packages match “{q}”.</Muted>}
              <div className="text-[10.5px] text-[#8a95a1] mt-1.5">{pkgRows.length} of {sw.length} shown — the full list feeds licensing and vulnerability matching · SBOM export lives in the Software tab</div>
            </>
          )}
          {panel === 'services' && (
            <>
              <SmallTable max="max-h-[260px]" head={<tr><th className={TH}>Service</th><th className={TH}>State</th><th className={TH}>Start</th><th className={TH}>Account</th><th className={TH}>Path</th></tr>}>
                {svcRows.map((s, i) => (
                  <tr key={i}>
                    <td className={TD}><div className={'font-semibold text-[#0f1f2b] text-[11.5px] ' + MONO}>{s.name}</div>{s.display_name && <div className="text-[#8a95a1] text-[11px]">{s.display_name}</div>}</td>
                    <td className={TD}><Pill on={/running|active/i.test(s.state)}>{s.state}</Pill></td>
                    <td className={TD + ' text-[#3a4653]'}>{s.start_mode || '—'}</td>
                    <td className={TD + ' text-[#3a4653] text-[11px]'}>{s.account || '—'}</td>
                    <td className={TD + ' text-[#8a95a1] text-[10.5px] break-all ' + MONO}>{s.path || '—'}</td>
                  </tr>
                ))}
              </SmallTable>
              {svcRows.length === 0 && <Muted>No services match.</Muted>}
            </>
          )}
          {panel === 'shares' && <GenericTable headers={['Share', 'Path', 'Description', 'Type']} rows={shareList.map((s) => [s.name || '—', s.path || '—', s.description || '—', s.type || '—'])} />}
          {panel === 'tasks' && (isObj(tasks) ? <div className="max-w-sm"><Rest data={tasks} used={[]} /></div> : <Muted>Scheduled tasks not collected</Muted>)}
        </div>
      </section>

      <Card title="Virtualization & containers" span={2}>
        {virtKeys.length ? (
          <div className="grid sm:grid-cols-2 gap-x-6 gap-y-2">
            {virtKeys.map((k) => <div key={k}><Sub>{k}</Sub>{blocksFor(k, dataOf(pp, k)).map((b: any, i: number) => <Block key={i} b={b} />)}</div>)}
          </div>
        ) : <Muted>Hypervisor and container runtime not collected by this scan</Muted>}
      </Card>
    </div>
  );
}

/** Security review items — every one derived from a collected value. */
export function securityReview(pp: any) {
  const out: Record<string, string[]> = { av: [], defender: [], firewall: [], disk: [], update: [] };
  const sp = dataOf(pp, 'security_products');
  if (isObj(sp)) {
    (sp.edr_xdr || []).forEach((e: any) => { if (e && e.running === false) out.av.push(`${e.service || e.product} service ${String(e.status || 'stopped').toLowerCase()}`); });
    (sp.antivirus || []).forEach((a: any) => { if (a?.enabled === false) out.av.push(`${a.name} disabled`); else if (a?.up_to_date === false) out.av.push(`${a.name} out of date`); });
  }
  const df = dataOf(pp, 'defender');
  if (isObj(df)) {
    if (df.realtime_protection === false) out.defender.push('Real-time protection off');
    if (df.tamper_protected === false) out.defender.push('Tamper protection off');
    if (typeof df.signature_age_days === 'number' && df.signature_age_days > 7) out.defender.push(`Signatures ${df.signature_age_days} days old`);
  }
  const fwl = dataOf(pp, 'firewall');
  if (Array.isArray(fwl)) fwl.forEach((p: any) => { if (p?.enabled === false) out.firewall.push(`${p.profile} profile off`); });
  const bl = dataOf(pp, 'bitlocker');
  (Array.isArray(bl) ? bl : isObj(bl) ? [bl] : []).forEach((v: any) => {
    if (v?.volume_status && v.volume_status !== 'FullyEncrypted') out.disk.push(`${v.mount_point || 'Volume'} ${words(v.volume_status).toLowerCase()}`);
    if (/^off$/i.test(String(v?.protection_status || ''))) out.disk.push(`${v.mount_point || 'Volume'} protection suspended`);
  });
  return out;
}

const onOff = (v: any, warnOff = false) => (v == null ? <span className="text-[#aeb8c2] italic text-[12px]">not collected</span> : <Pill on={!!v} warn={warnOff && !v}>{v ? 'On' : 'Off'}</Pill>);

export function SecurityCards({ A, review }: { A: any; review: Record<string, string[]> }) {
  const { pp, posture } = A.raw;
  const sp = dataOf(pp, 'security_products');
  const df = dataOf(pp, 'defender');
  const fwl = dataOf(pp, 'firewall');
  const blD = dataOf(pp, 'bitlocker');
  const bl = Array.isArray(blD) ? blD : isObj(blD) ? [blD] : [];
  const users = dataOf(pp, 'local_users');
  const groups = dataOf(pp, 'local_groups');
  const wu = dataOf(pp, 'windows_update');
  const su = dataOf(pp, 'security_updates') || dataOf(pp, 'sec_updates');
  const cats = isObj(posture?.categories) ? Object.entries(posture.categories).filter(([, n]) => (n as number) > 0) : [];
  const [showAccounts, setShowAccounts] = useState(false);
  const RL = ({ k }: { k: string }) => (review[k].length ? <div className="flex flex-wrap gap-1 mt-2">{review[k].map((t, i) => <Pill key={i} on={false} warn>{t}</Pill>)}</div> : null);
  const meta = (k: string, fallback?: string) => (review[k].length ? `${review[k].length} to review` : fallback);

  // Three balanced stacks (last card in each grows) so no card is left half-empty.
  return (
    <div className="flex flex-col gap-2.5">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-2.5">
        <div className="flex flex-col gap-2.5">
          <Card title="Antivirus & EDR" warn={review.av.length > 0} meta={meta('av')}>
            {isObj(sp) ? (
              <>
                {(sp.antivirus || []).map((a: any, i: number) => <Row key={'a' + i} label={i === 0 ? 'Antivirus' : 'Also present'} value={<span className="inline-flex items-center gap-1.5"><span className={MONO + ' text-[11.5px]'}>{a.name}</span>{a.up_to_date != null && <span className="text-[10px] text-[#8a95a1]">{a.up_to_date ? 'up to date' : 'out of date'}</span>}</span>} title={a.state_hex ? `state ${a.state_hex}` : undefined} />)}
                {(sp.edr_xdr || []).map((e: any, i: number) => (
                  <React.Fragment key={'e' + i}>
                    <Row label={e.type || 'EDR'} value={e.product} mono />
                    <Row label="EDR service" value={<Pill on={!!e.running} warn={!e.running}>{e.service ? `${e.service} · ` : ''}{e.status || (e.running ? 'Running' : 'Stopped')}</Pill>} />
                  </React.Fragment>
                ))}
                {!(sp.edr_xdr || []).length && <Row label="EDR" value={sp.edr_present === false ? 'None detected' : null} />}
                {(sp.antivirus || []).some((a: any) => a.state_hex) && <Row label="AV state" value={(sp.antivirus || []).map((a: any) => a.state_hex).filter(Boolean).join(', ')} mono />}
                <Rest data={sp} used={['antivirus', 'edr_xdr', 'edr_present']} />
              </>
            ) : (
              <>
                <Row label="Antivirus" value={posture?.has_antivirus ? (posture.antivirus_products || []).join(', ') : null} />
                <Row label="EDR" value={posture?.has_edr ? (posture.edr_products || []).join(', ') : null} />
              </>
            )}
            <RL k="av" />
          </Card>

          <Card title="Disk encryption" warn={review.disk.length > 0} meta={meta('disk', bl.length ? `BitLocker · ${bl.length} volume${bl.length > 1 ? 's' : ''}` : undefined)}>
            {bl.length ? bl.map((v: any, i: number) => (
              <div key={i}>
                <Row label={`Volume ${v.mount_point || ''}`} value={words(v.volume_status)} mono />
                <Row label="Protection" value={v.protection_status != null ? <Pill on={/^on$/i.test(v.protection_status)} warn={/^off$/i.test(v.protection_status)}>{v.protection_status}</Pill> : null} />
                <Row label="Method" value={v.encryption_method ? String(v.encryption_method).replace(/^XtsAes(\d+)/i, 'XTS-AES $1').replace(/^Aes(\d+)/i, 'AES $1') : null} mono />
                <Row label="Encrypted" value={v.encryption_percentage != null ? `${v.encryption_percentage}%` : null} mono />
                <Rest data={v} used={['mount_point', 'volume_status', 'protection_status', 'encryption_method', 'encryption_percentage']} />
              </div>
            )) : <Muted>Disk encryption not collected</Muted>}
            <RL k="disk" />
          </Card>

          <Card title="What runs here" className="flex-1" meta={cats.length ? 'from installed packages' : undefined}>
            {cats.length ? (
              <div className="flex flex-wrap gap-1.5">
                {cats.map(([k, n]) => <span key={k} className="text-[11.5px] font-semibold rounded-md border border-[#9cc0dd] bg-[#EFF5FA] text-[#014A81] px-2 py-[2px]">{words(k).replace(/_/g, ' ').replace(/^\w/, (c) => c.toUpperCase())} <span className={MONO + ' font-normal text-[#5f7a91]'}>{n as number}</span></span>)}
              </div>
            ) : <Muted>No package categories yet</Muted>}
            {Array.isArray(posture?.security_tools) && posture.security_tools.length > 0 && <div className="text-[10.5px] text-[#8a95a1] mt-2">Security tools: {posture.security_tools.join(', ')}</div>}
          </Card>
        </div>
        <div className="flex flex-col gap-2.5">
          <Card title="Defender" warn={review.defender.length > 0} meta={meta('defender', isObj(df) ? `${Object.keys(df).length} fields` : undefined)}>
            {isObj(df) ? (
              <>
                <Row label="Real-time protection" value={onOff(df.realtime_protection, true)} />
                <Row label="Antivirus engine" value={onOff(df.antivirus_enabled, true)} />
                <Row label="Antispyware" value={onOff(df.antispyware_enabled, true)} />
                <Row label="Signature age" value={df.signature_age_days != null ? `${df.signature_age_days} day${df.signature_age_days === 1 ? '' : 's'}` : null} mono />
                <Row label="Signatures" value={df.signature_version} mono />
                <Row label="Engine" value={df.engine_version} mono />
                <Row label="Tamper protection" value={onOff(df.tamper_protected, true)} />
                <Rest data={df} used={['realtime_protection', 'antivirus_enabled', 'antispyware_enabled', 'signature_age_days', 'signature_version', 'engine_version', 'tamper_protected']} />
              </>
            ) : <Muted>Defender status not collected</Muted>}
            <RL k="defender" />
          </Card>

          <Card title="Host firewall" className="flex-1" warn={review.firewall.length > 0} meta={meta('firewall', Array.isArray(fwl) ? `${fwl.length} profiles` : undefined)}>
            {Array.isArray(fwl) ? (
              <div className="flex flex-col gap-1.5">
                {fwl.map((p: any, i: number) => (
                  <div key={i} className="flex items-center justify-between rounded-lg border border-[#e8ecee] bg-[#fafbfc] px-2.5 py-1.5">
                    <div><div className="text-[12px] font-semibold text-[#0f1f2b]">{p.profile}</div><div className="text-[10px] text-[#8a95a1]">in {words(p.default_inbound || '—')} · out {words(p.default_outbound || '—')}</div></div>
                    {onOff(p.enabled, true)}
                  </div>
                ))}
              </div>
            ) : <Muted>Firewall profiles not collected</Muted>}
          </Card>
        </div>
        <div className="flex flex-col gap-2.5">
          <Card title="Update state" meta={wu ? 'Windows Update' : isObj(su) ? su.update_manager || 'Security updates' : undefined}>
            {isObj(wu) ? (
              <>
                <Row label="Last installed" value={wu.last_installed ? String(wu.last_installed).replace(/^(\d\d)\/(\d\d)\/(\d{4}).*/, '$3-$1-$2') : null} mono />
                <Row label="Days since patch" value={wu.days_since_last_patch} mono tone={typeof wu.days_since_last_patch === 'number' && wu.days_since_last_patch > 30 ? 'warn' : undefined} />
                <Row label="Hotfixes installed" value={wu.hotfix_count} mono />
                <Row label="Last hotfix" value={wu.last_hotfix} mono />
                {Array.isArray(wu.recent_hotfixes) && wu.recent_hotfixes.length > 0 && (
                  <div className="mt-1.5 border-t border-[#f0f3f5] pt-1">
                    {wu.recent_hotfixes.map((h: any, i: number) => <div key={i} className={'flex justify-between gap-2 text-[10.5px] text-[#6b7787] ' + MONO}><span>{h.id}</span><span className="truncate">{h.type}</span><span>{String(h.installed || '').replace(/^(\d\d)\/(\d\d)\/(\d{4}).*/, '$3-$1-$2')}</span></div>)}
                  </div>
                )}
                <Rest data={wu} used={['last_installed', 'days_since_last_patch', 'hotfix_count', 'last_hotfix', 'recent_hotfixes']} />
              </>
            ) : isObj(su) ? <Rest data={su} used={[]} /> : <Muted>Patch state not collected</Muted>}
          </Card>

          <Card title="Local users" className="flex-1" meta={<span>{Array.isArray(users) ? `${users.length} users` : ''}{Array.isArray(groups) ? ` · ${groups.length} groups` : ''}{(Array.isArray(users) || Array.isArray(groups)) && <a className="text-[#005B96] font-semibold cursor-pointer ml-2" onClick={() => setShowAccounts((v) => !v)}>{showAccounts ? 'Hide table' : 'Full table'}</a>}</span>}>
            {Array.isArray(users) ? (
              <>
                <div className="flex flex-wrap gap-1.5">
                  {users.map((u: any, i: number) => (
                    <span key={i} title={[u.full_name, u.sid].filter(Boolean).join(' · ')} className={'text-[11.5px] rounded-md border px-2 py-[2px] ' + (u.disabled ? 'border-[#e8ecee] bg-[#fafbfc] text-[#6b7787]' : 'border-[#cfe0f0] bg-[#EFF5FA] text-[#0f1f2b] font-semibold')}>
                      {u.name}{u.disabled ? <span className="font-normal text-[#aeb8c2]"> disabled</span> : ''}{u.lockout ? <span className="font-semibold text-[#9a6410]"> locked</span> : ''}
                    </span>
                  ))}
                </div>
                <div className="text-[10.5px] text-[#8a95a1] mt-2">Administrators group membership is not collected by this scan.</div>
              </>
            ) : <Muted>Local accounts not collected</Muted>}
          </Card>
        </div>
      </div>
      {showAccounts && (
        <Card title="Local accounts" span={3} meta={<a className="text-[#005B96] font-semibold cursor-pointer" onClick={() => setShowAccounts(false)}>Hide table</a>}>
          <div className="grid lg:grid-cols-2 gap-2">
            {Array.isArray(users) && <UsersTable rows={users.map((u: any) => [u.full_name || '—', u.name || '—', u.sid || '—', u.lockout ? '✓' : '✗', u.disabled ? '✓' : '✗'])} />}
            {Array.isArray(groups) && <GenericTable headers={['Group', 'Description']} rows={groups.map((g: any) => [g.name || '—', g.description || '—'])} />}
          </div>
        </Card>
      )}
    </div>
  );
}

// Sections each curated host card owns (only when the data has the shape it renders).
export function claimedKeys(pp: any): Set<string> {
  const c = new Set<string>();
  const d = (k: string) => dataOf(pp, k);
  ['cpu', 'memory', 'storage', 'firmware', 'os', 'scheduled_tasks', 'security_products', 'defender', 'windows_update', 'packages', 'pkg', 'security_updates', 'sec_updates'].forEach((k) => isObj(d(k)) && c.add(k));
  if (isObj(d('gpu')) || Array.isArray(d('gpu'))) c.add('gpu');
  if (Array.isArray(d('network')) || (isObj(d('network')) && Array.isArray(d('network').interfaces))) c.add('network');
  if (serviceRows(d('services')).length) c.add('services');
  ['shares', 'firewall', 'local_users', 'local_groups'].forEach((k) => Array.isArray(d(k)) && c.add(k));
  if (isObj(d('bitlocker')) || Array.isArray(d('bitlocker'))) c.add('bitlocker');
  ['virtualization', 'virt', 'docker', 'podman'].forEach((k) => sec(pp, k) && c.add(k));
  return c;
}

