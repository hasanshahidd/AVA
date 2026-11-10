'use client';

/*
 * One change-journal entry: when (date + time), who, from which source, and
 * every change grouped the way the asset record is organised — category
 * (Identity & network, Hardware / Software / Security telemetry, Ownership, …),
 * then telemetry section (CPU, Packages, Defender, Local users, …), then rows
 * with full before → after values. Added / removed items (a new package, a
 * removed local user) are badged rather than shown as empty → value.
 */

import { useState } from 'react';
import { ArrowRight } from 'lucide-react';
import {
  ADD, BORDER, CATEGORY_ORDER, DEL, FAINT, INK, MUTED, SEC, SOFT, type ChangeEntry, type ChangeField,
  actorOf, categoryMeta, categoryOfField, fieldLabel, fieldsOf, fmtDate, fmtTime, fmtValue, isEmpty,
  isTelemetry, sectionLabel, sectionOf, sourceMeta, sourceOf, titleCase, totalOf,
} from './model';

const COLLAPSED_ROWS = 12;
const GRID = 'grid grid-cols-1 sm:grid-cols-[170px_minmax(0,1fr)_16px_minmax(0,1fr)] gap-x-3';
const MONO_RE = /(ip_address|mac|fqdn|host_name|serial|build|version|path|known_ips|\[)/i;

function Value({ f, which }: { f: ChangeField; which: 'old' | 'new' }) {
  const v = which === 'old' ? f.old : f.new;
  const lbl = which === 'old' ? f.old_label : f.new_label;
  if (isEmpty(v)) return <span className="text-[11.5px] italic" style={{ color: FAINT }}>{which === 'old' && f.change === 'added' ? '—' : 'empty'}</span>;
  const mono = MONO_RE.test(f.field) ? "font-['IBM_Plex_Mono',ui-monospace,monospace] text-[11.5px]" : 'text-[12.5px]';
  return (
    <span className={`${mono} break-words`} title={String(typeof v === 'object' ? JSON.stringify(v) : v)}
      style={which === 'old'
        ? { color: MUTED, textDecoration: f.change === 'removed' ? 'none' : 'line-through', textDecorationColor: '#C4CCD4', overflowWrap: 'anywhere' }
        : { color: INK, fontWeight: 600, overflowWrap: 'anywhere' }}>
      {fmtValue(v, lbl)}
    </span>
  );
}

function Badge({ change }: { change?: string }) {
  if (change !== 'added' && change !== 'removed') return null;
  const c = change === 'added' ? ADD : DEL;
  return (
    <span className="ml-1.5 inline-block rounded-[4px] px-1 text-[9.5px] font-bold uppercase tracking-[0.04em] align-[1px]"
      style={{ color: c, background: `${c}14`, border: `1px solid ${c}33` }}>{change}</span>
  );
}

function FieldRow({ f }: { f: ChangeField }) {
  return (
    <div className={`${GRID} gap-y-0.5 items-baseline py-[6px] px-3`} style={{ borderTop: `1px solid ${BORDER}` }}>
      <span className="text-[12px] font-semibold break-words" style={{ color: SEC, overflowWrap: 'anywhere' }}>
        {fieldLabel(f)}<Badge change={f.change} />
      </span>
      <Value f={f} which="old" />
      <ArrowRight className="hidden sm:block h-3.5 w-3.5 self-center" style={{ color: FAINT }} aria-hidden />
      <Value f={f} which="new" />
    </div>
  );
}

function SectionHead({ name, counts }: { name: string; counts?: { added: number; removed: number; changed: number } }) {
  return (
    <div className="flex flex-wrap items-center gap-x-2 px-3 pt-2 pb-1 text-[11px] font-semibold" style={{ color: INK }}>
      {sectionLabel(name)}
      {counts && (
        <span className="text-[10.5px] font-medium" style={{ color: MUTED }}>
          {counts.added > 0 && <span style={{ color: ADD }}>+{counts.added} added </span>}
          {counts.removed > 0 && <span style={{ color: DEL }}>−{counts.removed} removed </span>}
          {counts.changed > 0 && <span>{counts.changed} changed</span>}
        </span>
      )}
    </div>
  );
}

export default function ChangeEntryCard({ entry }: { entry: ChangeEntry }) {
  const [expanded, setExpanded] = useState(false);
  const src = sourceMeta(sourceOf(entry));
  const fields = fieldsOf(entry);
  const total = totalOf(entry);
  const actor = actorOf(entry);
  const initials = actor.split(/\s+/).map((w) => w[0]).join('').slice(0, 2).toUpperCase();

  // category → section → rows, in asset-record order; rows beyond the fold hidden until expanded.
  let budget = expanded ? Infinity : COLLAPSED_ROWS;
  const groups = CATEGORY_ORDER.map((c) => {
    const fs = fields.filter((f) => categoryOfField(f) === c);
    const sections: { name: string; telemetry: boolean; rows: ChangeField[] }[] = [];
    for (const f of fs) {
      const name = isTelemetry(f) ? sectionOf(f) : '';
      const last = sections[sections.length - 1];
      if (last && last.name === name) last.rows.push(f);
      else sections.push({ name, telemetry: !!name, rows: [f] });
    }
    const shown = sections.map((s) => {
      const rows = s.rows.slice(0, Math.max(0, budget));
      budget -= rows.length;
      return { ...s, rows };
    }).filter((s) => s.rows.length);
    return { c, count: fs.length, sections: shown };
  }).filter((g) => g.sections.length);
  const hidden = fields.length - groups.reduce((n, g) => n + g.sections.reduce((m, s) => m + s.rows.length, 0), 0);

  return (
    <article className="relative rounded-[12px] bg-white overflow-hidden"
      style={{ border: `1px solid ${BORDER}`, boxShadow: '0 1px 2px rgba(16,24,40,.04)' }}>
      <span className="absolute left-0 top-0 bottom-0 w-[3px]" style={{ background: src.color }} aria-hidden />
      <header className="flex flex-wrap items-center gap-x-3 gap-y-1.5 pl-4 pr-3 py-2.5">
        <span className="flex items-center justify-center h-7 w-7 rounded-full text-[10.5px] font-bold text-white flex-none"
          style={{ background: src.color }} aria-hidden>{initials}</span>
        <div className="min-w-0 flex-1">
          <div className="text-[13px] font-semibold break-words" style={{ color: INK }}>
            {actor}
            <span className="font-normal" style={{ color: MUTED }}>
              {total ? ` made ${total} change${total === 1 ? '' : 's'}` : ` · ${entry.detail || titleCase(entry.action)}`}
            </span>
          </div>
          <div className="text-[11px] flex flex-wrap items-center gap-x-1.5" style={{ color: MUTED }}>
            <time dateTime={entry.created_at}>{fmtDate(entry.created_at)}</time>
            <span aria-hidden>·</span>
            <span className="font-['IBM_Plex_Mono',ui-monospace,monospace]">{fmtTime(entry.created_at)}</span>
            <span aria-hidden>·</span>
            <span className="font-['IBM_Plex_Mono',ui-monospace,monospace]">{entry.action}</span>
          </div>
        </div>
        <span className="text-[10.5px] font-semibold rounded-full px-2.5 py-[3px] whitespace-nowrap"
          style={{ background: `${src.color}14`, color: src.color, border: `1px solid ${src.color}33` }}>
          {src.label}
        </span>
      </header>

      {groups.length > 0 && (
        <div className={`hidden sm:grid ${GRID} px-3 py-1 text-[9.5px] font-bold uppercase tracking-[0.06em]`}
          style={{ color: FAINT, borderTop: `1px solid ${BORDER}` }}>
          <span>Field</span><span>Before</span><span /><span>After</span>
        </div>
      )}
      {groups.map((g) => {
        const cm = categoryMeta(g.c);
        return (
          <section key={g.c} aria-label={`${cm.label} changes`}>
            <div className="flex items-center gap-1.5 px-3 py-[5px] text-[10px] font-bold uppercase tracking-[0.06em]"
              style={{ background: SOFT, color: cm.color, borderTop: `1px solid ${BORDER}` }}>
              <span className="h-[6px] w-[6px] rounded-full" style={{ background: cm.color }} aria-hidden />
              {cm.label}
              <span style={{ color: FAINT }}>· {g.count}</span>
            </div>
            {g.sections.map((s, i) => (
              <div key={`${s.name}-${i}`}>
                {s.telemetry && <SectionHead name={s.name} counts={entry.sections?.[s.name]} />}
                {s.rows.map((f, j) => <FieldRow key={`${f.field}-${j}`} f={f} />)}
              </div>
            ))}
          </section>
        );
      })}

      {(hidden > 0 || (entry.truncated ?? 0) > 0 || (expanded && fields.length > COLLAPSED_ROWS)) && (
        <footer className="flex flex-wrap items-center justify-between gap-2 px-3 py-2 text-[11.5px]"
          style={{ borderTop: `1px solid ${BORDER}`, background: SOFT, color: MUTED }}>
          <span>
            {(entry.truncated ?? 0) > 0 && `${entry.truncated} further changes were counted in the section totals but not stored row by row.`}
          </span>
          {fields.length > COLLAPSED_ROWS && (
            <button type="button" onClick={() => setExpanded((v) => !v)} className="font-semibold" style={{ color: '#005B96' }}>
              {expanded ? 'Show fewer' : `Show all ${fields.length} changes`}
            </button>
          )}
        </footer>
      )}
    </article>
  );
}
