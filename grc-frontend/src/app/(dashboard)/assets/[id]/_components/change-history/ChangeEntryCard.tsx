'use client';

/*
 * One change-journal entry, as a row inside its day card:
 *   summary line  — who (or which asset, in the estate feed), what changed in
 *                   plain words, source badge, time;
 *   field diffs   — grouped the way the asset record is organised (category →
 *                   telemetry section → "Label  old → new"), added / removed items
 *                   badged; long entries fold behind "Show all N changes";
 *   older rows    — whose values were never recorded collapse to one
 *                   "Fields updated: Confidentiality, Integrity" line.
 */

import { useState } from 'react';
import Link from 'next/link';
import {
  ArrowRight, ChevronDown, Cpu, FileUp, Plug, Radar, ScanLine, Settings2, type LucideIcon,
} from 'lucide-react';
import {
  ADD, BRAND, CATEGORY_ORDER, DEL, DIVIDER, FAINT, INK, MUTED, SEC, SOFT, type ChangeEntry, type ChangeField,
  actorOf, categoryMeta, categoryOfField, entrySummary, fieldLabel, fieldsOf, fmtDate, fmtTime, fmtValue, isEmpty,
  isTelemetry, sectionLabel, sectionOf, sourceMeta, sourceOf,
} from './model';

const MONO = "font-['IBM_Plex_Mono',ui-monospace,monospace] text-[11.5px]";
const MONO_RE = /(ip_address|mac|fqdn|host_name|serial|build|version|path|known_ips|\[)/i;
const SOURCE_ICON: Record<string, LucideIcon> = {
  scan: ScanLine, discovery: Radar, connector: Plug, agent: Cpu, import: FileUp, system: Settings2,
};

export function SourceBadge({ source }: { source: string }) {
  const m = sourceMeta(source);
  return (
    <span className="inline-flex items-center gap-1.5 h-[22px] rounded-full px-2 text-[11px] font-medium whitespace-nowrap"
      style={{ background: '#F4F6F7', color: SEC, border: '1px solid #E8ECEE' }}>
      <span className="h-[6px] w-[6px] rounded-full" style={{ background: m.color }} aria-hidden />
      {m.label}
    </span>
  );
}

function Avatar({ entry }: { entry: ChangeEntry }) {
  const src = sourceOf(entry);
  const Icon = src === 'manual' ? null : SOURCE_ICON[src] ?? Settings2;
  const initials = actorOf(entry).split(/\s+/).map((w) => w[0]).join('').slice(0, 2).toUpperCase();
  return (
    <span className="flex items-center justify-center h-8 w-8 rounded-full flex-none text-[11px] font-semibold"
      style={{ background: '#EFF5FA', color: '#014A81' }} aria-hidden>
      {Icon ? <Icon className="h-4 w-4" strokeWidth={1.9} /> : initials}
    </span>
  );
}

function Value({ f, which }: { f: ChangeField; which: 'old' | 'new' }) {
  const v = which === 'old' ? f.old : f.new;
  if (isEmpty(v)) return <span className="italic" style={{ color: MUTED }}>not set</span>;
  const text = fmtValue(v, which === 'old' ? f.old_label : f.new_label);
  return (
    <span className={MONO_RE.test(f.field) ? MONO : ''} title={text}
      style={which === 'old'
        ? { color: MUTED, textDecoration: f.change === 'removed' ? 'line-through' : undefined, overflowWrap: 'anywhere' }
        : { color: INK, fontWeight: 500, overflowWrap: 'anywhere' }}>
      {text}
    </span>
  );
}

function Tag({ change }: { change: 'added' | 'removed' }) {
  const c = change === 'added' ? ADD : DEL;
  return (
    <span className="inline-flex items-center h-[18px] rounded-[5px] px-1.5 text-[10.5px] font-semibold mr-2 flex-none"
      style={{ color: c, background: `${c}12` }}>{change === 'added' ? 'Added' : 'Removed'}</span>
  );
}

function DiffRow({ f }: { f: ChangeField }) {
  return (
    <li className="grid grid-cols-1 sm:grid-cols-[minmax(120px,180px)_minmax(0,1fr)] gap-x-4 gap-y-0.5 py-[5px] text-[12.5px]">
      <span className="font-medium" style={{ color: SEC, overflowWrap: 'anywhere' }}>{fieldLabel(f)}</span>
      <span className="flex flex-wrap items-baseline gap-x-1.5 min-w-0">
        {f.change === 'added' || f.change === 'removed' ? (
          <><Tag change={f.change} /><Value f={f} which={f.change === 'added' ? 'new' : 'old'} /></>
        ) : (
          <>
            <Value f={f} which="old" />
            <ArrowRight className="h-3.5 w-3.5 flex-none self-center" style={{ color: FAINT }} aria-label="changed to" />
            <Value f={f} which="new" />
          </>
        )}
      </span>
    </li>
  );
}

function sectionCounts(t?: { added: number; removed: number; changed: number }) {
  if (!t) return '';
  return [t.added && `${t.added} added`, t.removed && `${t.removed} removed`, t.changed && `${t.changed} changed`]
    .filter(Boolean).join(', ');
}

type Group = { c: string; sections: { name: string; rows: ChangeField[] }[]; legacy: ChangeField[] };

function groupFields(fields: ChangeField[], limit: number): { groups: Group[]; shown: number } {
  let budget = limit;
  const groups: Group[] = [];
  for (const c of CATEGORY_ORDER) {
    const fs = fields.filter((f) => categoryOfField(f) === c);
    if (!fs.length) continue;
    const legacy = fs.filter((f) => f.change === 'updated');   // values not recorded: names only
    const sections: Group['sections'] = [];
    for (const f of fs) {
      if (f.change === 'updated' || budget <= 0) continue;
      budget -= 1;
      const name = isTelemetry(f) ? sectionOf(f) : '';
      const last = sections[sections.length - 1];
      if (last && last.name === name) last.rows.push(f);
      else sections.push({ name, rows: [f] });
    }
    if (sections.length || legacy.length) groups.push({ c, sections, legacy });
  }
  return { groups, shown: limit - budget };
}

export default function ChangeEntryCard({ entry, preview = 6, showAsset = false }: {
  entry: ChangeEntry;
  /** Diff rows visible before "Show all N changes". */
  preview?: number;
  /** Estate feed: lead with the asset (linking to its history) instead of the person. */
  showAsset?: boolean;
}) {
  const [expanded, setExpanded] = useState(false);
  const src = sourceOf(entry);
  const fields = fieldsOf(entry);
  const recorded = fields.filter((f) => f.change !== 'updated').length;
  const { groups, shown } = groupFields(fields, expanded ? Infinity : preview);
  const multiCat = new Set(fields.map(categoryOfField)).size > 1;   // from all rows, not just the previewed ones
  const truncated = entry.truncated ?? 0;
  const assetHref = entry.asset_id ? `/assets/${entry.asset_id}/history` : null;

  return (
    <article className="flex gap-3 px-4 py-3.5">
      <Avatar entry={entry} />
      <div className="min-w-0 flex-1">
        <header className="flex flex-col sm:flex-row sm:items-start gap-x-3 gap-y-1.5">
          <div className="min-w-0 flex-1 text-[13px] leading-[1.45]" style={{ color: SEC }}>
            {showAsset ? (
              <>
                {assetHref
                  ? <Link href={assetHref} className="font-semibold hover:underline focus-visible:underline rounded-sm focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[#19A8E6]" style={{ color: BRAND }}>{entry.asset_name || `Asset ${entry.asset_id}`}</Link>
                  : <span className="font-semibold" style={{ color: INK }}>{entry.asset_name || 'Unknown asset'}</span>}
                {entry.asset_type && <span className="ml-1.5 text-[11.5px] capitalize" style={{ color: MUTED }}>{entry.asset_type}</span>}
                <div className="mt-0.5"><span className="font-medium" style={{ color: INK }}>{actorOf(entry)}</span> {entrySummary(entry)}</div>
              </>
            ) : (
              <><span className="font-semibold" style={{ color: INK }}>{actorOf(entry)}</span> {entrySummary(entry)}</>
            )}
          </div>
          <div className="flex items-center gap-2 flex-none">
            <SourceBadge source={src} />
            <time dateTime={entry.created_at} title={`${fmtDate(entry.created_at)} ${fmtTime(entry.created_at, true)}`}
              className="text-[11.5px] tabular-nums w-[38px] text-right" style={{ color: MUTED }}>
              {fmtTime(entry.created_at)}
            </time>
          </div>
        </header>

        {groups.length > 0 && (
          <div className="mt-2 rounded-[10px] px-3 py-1.5" style={{ background: SOFT, border: `1px solid ${DIVIDER}` }}>
            {groups.map((g, gi) => (
              <section key={g.c} aria-label={categoryMeta(g.c).label}
                className={gi ? 'pt-1.5 mt-1.5' : ''} style={gi ? { borderTop: `1px solid ${DIVIDER}` } : undefined}>
                {multiCat && (
                  <h4 className="flex items-center gap-1.5 pt-1 text-[11.5px] font-semibold" style={{ color: INK }}>
                    <span className="h-[6px] w-[6px] rounded-full" style={{ background: categoryMeta(g.c).color }} aria-hidden />
                    {categoryMeta(g.c).label}
                  </h4>
                )}
                {g.sections.map((s, i) => (
                  <div key={`${s.name}-${i}`}>
                    {s.name && (
                      <div className="pt-1 text-[11.5px]" style={{ color: MUTED }}>
                        <span className="font-semibold" style={{ color: SEC }}>{sectionLabel(s.name)}</span>
                        {sectionCounts(entry.sections?.[s.name]) && <span className="ml-2">{sectionCounts(entry.sections?.[s.name])}</span>}
                      </div>
                    )}
                    <ul>{s.rows.map((f, j) => <DiffRow key={`${f.field}-${j}`} f={f} />)}</ul>
                  </div>
                ))}
                {g.legacy.length > 0 && (
                  <p className="py-[5px] text-[12.5px]" style={{ color: SEC }}
                    title="This older change recorded which fields changed, not their values.">
                    <span style={{ color: MUTED }}>Fields updated: </span>
                    {g.legacy.map(fieldLabel).join(', ')}
                  </p>
                )}
              </section>
            ))}
          </div>
        )}

        {(recorded > preview || truncated > 0) && (
          <div className="mt-1.5 flex flex-wrap items-center gap-x-3 gap-y-1 text-[12px]">
            {recorded > preview && (
              <button type="button" onClick={() => setExpanded((v) => !v)} aria-expanded={expanded}
                className="inline-flex items-center gap-1 font-semibold rounded-[6px] px-1 -mx-1 hover:underline focus-visible:outline focus-visible:outline-2 focus-visible:outline-[#19A8E6]"
                style={{ color: BRAND }}>
                <ChevronDown className={`h-3.5 w-3.5 transition-transform ${expanded ? 'rotate-180' : ''}`} aria-hidden />
                {expanded ? 'Show fewer' : `Show all ${recorded} changes`}
                {!expanded && <span className="sr-only">{` (${recorded - shown} more)`}</span>}
              </button>
            )}
            {truncated > 0 && (
              <span style={{ color: MUTED }}>
                {truncated} more changes are counted in the section totals but were not stored one by one.
              </span>
            )}
          </div>
        )}
      </div>
    </article>
  );
}
