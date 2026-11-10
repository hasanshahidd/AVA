'use client';

/*
 * One change-journal entry: when (date + time), who, from which source, and
 * every changed field grouped by category with its full old → new values.
 */

import { ArrowRight } from 'lucide-react';
import {
  BORDER, CATEGORY_ORDER, FAINT, INK, MUTED, SEC, SOFT, type ChangeEntry, type ChangeField,
  actorOf, categoryMeta, categoryOfField, fieldLabel, fieldsOf, fmtDate, fmtTime, fmtValue, isEmpty,
  sourceMeta, sourceOf, titleCase,
} from './model';

const MONO = new Set(['ip_address', 'primary_mac', 'fqdn', 'host_name', 'serial_number', 'os_build', 'agent_version']);

function Value({ field, v, kind }: { field: string; v: unknown; kind: 'old' | 'new' }) {
  const empty = isEmpty(v);
  const mono = MONO.has(field) ? "font-['IBM_Plex_Mono',ui-monospace,monospace] text-[11.5px]" : 'text-[12.5px]';
  if (empty) return <span className="text-[11.5px] italic" style={{ color: FAINT }}>empty</span>;
  return (
    <span
      className={`${mono} break-words`}
      style={kind === 'old'
        ? { color: MUTED, textDecoration: 'line-through', textDecorationColor: '#C4CCD4', overflowWrap: 'anywhere' }
        : { color: INK, fontWeight: 600, overflowWrap: 'anywhere' }}
      title={String(v)}
    >
      {fmtValue(v)}
    </span>
  );
}

function FieldRow({ f }: { f: ChangeField }) {
  return (
    <div className="grid grid-cols-1 sm:grid-cols-[150px_minmax(0,1fr)_16px_minmax(0,1fr)] gap-x-3 gap-y-0.5 items-baseline py-[7px] px-3"
      style={{ borderTop: `1px solid ${BORDER}` }}>
      <span className="text-[12px] font-semibold" style={{ color: SEC }}>{fieldLabel(f.field)}</span>
      <Value field={f.field} v={f.old} kind="old" />
      <ArrowRight className="hidden sm:block h-3.5 w-3.5 self-center" style={{ color: FAINT }} aria-hidden />
      <Value field={f.field} v={f.new} kind="new" />
    </div>
  );
}

export default function ChangeEntryCard({ entry }: { entry: ChangeEntry }) {
  const src = sourceMeta(sourceOf(entry));
  const fields = fieldsOf(entry);
  const groups = CATEGORY_ORDER
    .map((c) => ({ c, fs: fields.filter((f) => categoryOfField(f) === c) }))
    .filter((g) => g.fs.length);
  const actor = actorOf(entry);
  const initials = actor.split(/\s+/).map((w) => w[0]).join('').slice(0, 2).toUpperCase();

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
              {fields.length
                ? ` changed ${fields.length} field${fields.length === 1 ? '' : 's'}`
                : ` · ${entry.detail || titleCase(entry.action)}`}
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
        <div className="hidden sm:grid grid-cols-[150px_minmax(0,1fr)_16px_minmax(0,1fr)] gap-x-3 px-3 py-1 text-[9.5px] font-bold uppercase tracking-[0.06em]"
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
              <span style={{ color: FAINT }}>· {g.fs.length}</span>
            </div>
            {g.fs.map((f, i) => <FieldRow key={`${f.field}-${i}`} f={f} />)}
          </section>
        );
      })}
    </article>
  );
}
