/*
 * Field tracker model: every field of the asset (from GET /asset-fields, named
 * exactly like the change journal's paths) joined to the changes recorded for
 * it, so each field has its own track — current value plus what changed, when
 * and by which source — or "No change".
 */

import {
  type ChangeEntry, type ChangeField, actorOf, fieldLabel, fieldsOf, fmtValue, isEmpty, itemEnd, itemName, label,
  sectionLabel, sourceOf, splitPath,
} from './model';

export type FieldRow = {
  path: string; section: string; category: string; kind: 'value' | 'list' | 'live';
  value: unknown; count: number | null; label?: string | null;
};
export type TrackChange = {
  entry: number; at?: string; source: string; actor: string; change: string;
  /** A whole list item (or a plain list value), not a sub-field of one. */
  itemLevel: boolean;
  /** Item / sub-field below the track, e.g. "openssl" or "C: › Capacity (GB)". */
  where?: string; old: unknown; new: unknown; oldLabel?: string | null; newLabel?: string | null;
  /** Estate view: which asset changed. */
  assetId?: number | null; assetName?: string | null;
};
export type Track = Omit<FieldRow, 'kind'> & {
  kind: FieldRow['kind'] | 'gone';   // gone = no longer reported, but has history
  name: string;                      // field label
  group: string;                     // "Asset record" or the telemetry section's label
  isList: boolean;                   // a list of items (packages, ports, volumes…)
  changes: TrackChange[];            // newest first
};

export const RECORD_GROUP = 'Asset record';

/** Cut points of a journal path at top-level "." and "[" (item keys may hold dots / JSON). */
function cuts(p: string): number[] {
  const out: number[] = [];
  for (let i = 0; i < p.length;) {
    if (p[i] === '[') { out.push(i); i = itemEnd(p, i) + 1; }
    else { if (p[i] === '.') out.push(i); i++; }
  }
  return out;
}

/** "[openssl].version" → "openssl › Version". */
function describeRest(rest: string): string | undefined {
  const parts = splitPath(rest)
    .filter(([k, t]) => k === 'item' || (t !== 'data' && t !== 'items'))
    .map(([k, t]) => (k === 'item' ? itemName(t) : label(t)));
  return parts.length ? parts.join(' › ') : undefined;
}

/** Field label; a section whose data is the list itself (services, network) is named after the section. */
function nameOf(path: string, section: string): string {
  const n = fieldLabel({ field: path, section, old: null, new: null });
  return n === 'Section data' ? sectionLabel(section) : n;
}

const groupOf = (r: FieldRow) => (r.path === r.section ? RECORD_GROUP : sectionLabel(r.section));

/** The listed field a change belongs to: exact path, else its nearest listed parent. */
function owner(byPath: Map<string, Track>, f: ChangeField): [Track | undefined, string] {
  const exact = byPath.get(f.field);
  if (exact) return [exact, ''];
  const cs = cuts(f.field);
  for (let i = cs.length - 1; i >= 0; i--) {
    const t = byPath.get(f.field.slice(0, cs[i]));
    if (t) return [t, f.field.slice(cs[i])];
  }
  return [undefined, ''];
}

export function buildTracks(rows: FieldRow[], entries: ChangeEntry[]): Track[] {
  const tracks: Track[] = rows.map((r) => ({
    ...r, name: nameOf(r.path, r.section), group: groupOf(r),
    isList: r.kind === 'list', changes: [],
  }));
  const byPath = new Map(tracks.map((t) => [t.path, t]));
  for (const e of entries) {             // newest first, so each track's changes stay newest first
    for (const f of fieldsOf(e)) {
      const found = owner(byPath, f);
      let t = found[0];
      let rest = found[1];
      if (!t) {
        // Field no longer on the asset (section gone): keep its history on a "no longer reported" track.
        const sec = f.section || f.field;
        const cs = cuts(f.field);
        const listCut = cs.find((i) => f.field[i] === '[');
        const path = listCut !== undefined ? f.field.slice(0, listCut) : f.field;
        rest = f.field.slice(path.length);
        const gone: Track = {
          path, section: sec, category: f.category || 'other', kind: 'gone', value: undefined, count: null,
          name: nameOf(path, sec), group: path === sec ? RECORD_GROUP : sectionLabel(sec),
          isList: listCut !== undefined, changes: [],
        };
        tracks.push(gone);
        byPath.set(path, gone);
        t = gone;
      }
      t.changes.push({
        entry: e.id, at: e.created_at, source: sourceOf(e), actor: actorOf(e), change: f.change || 'changed',
        where: rest ? describeRest(rest) : undefined, itemLevel: !rest || rest.endsWith(']'),
        old: f.old, new: f.new, oldLabel: f.old_label, newLabel: f.new_label,
        assetId: e.asset_id, assetName: e.asset_name,
      });
    }
  }
  for (const t of tracks) {
    if (!t.isList || !t.changes.length) continue;
    if (t.changes.length > 1) t.changes = tidyList(t.changes);
    // Never show "removed" for an item the asset still has (needs the complete current list).
    const now = Array.isArray(t.value) && t.value.length === t.count ? new Set((t.value as unknown[]).map((x) => shown(x))) : null;
    if (now) t.changes = t.changes.filter((c) => !(c.itemLevel && c.change === 'removed' && now.has(shown(c.old))));
  }
  return tracks;
}

const DESC = /\bdescription: ([^,)]+)/;
const SERVICE = /\bservice: ([^,)]+)/;
/** Identity of a list item across reports: an adapter by its description (its MAC can change on
 *  reboot), a port by port/proto + the process on it, anything else by its key or value. */
function itemOf(c: TrackChange): string {
  const v = shown(c.change === 'added' ? c.new : c.old);
  const desc = DESC.exec(v)?.[1];
  const id = desc ?? `${c.where ?? v}${SERVICE.exec(v) ? ` ${SERVICE.exec(v)![1]}` : ''}`;
  return `${c.assetId ?? ''}|${id}`;
}

/** List history read as people expect it:
 *  - one report that removed X and added Y on the same sub-field (Wi-Fi › Gateway) → one change X → Y;
 *  - an item reported missing and then back again (a report that briefly lacked it) → both dropped,
 *    so something that is still there is never shown as removed. */
export function tidyList(changes: TrackChange[]): TrackChange[] {
  let out: TrackChange[] = [];
  const pairs = new Map<string, TrackChange[]>();
  for (const c of changes) {
    if (c.itemLevel || (c.change !== 'added' && c.change !== 'removed')) continue;
    const k = `${c.entry}|${c.assetId ?? ''}|${c.where ?? ''}`;
    pairs.set(k, [...(pairs.get(k) ?? []), c]);
  }
  const merged = new Set<TrackChange>();
  for (const cs of Array.from(pairs.values())) {
    const rem = cs.filter((c) => c.change === 'removed');
    const add = cs.filter((c) => c.change === 'added');
    if (rem.length === 1 && add.length === 1) {
      merged.add(rem[0]);
      Object.assign(add[0], { change: 'changed', old: rem[0].old, oldLabel: rem[0].oldLabel });
    }
  }
  out = changes.filter((c) => !merged.has(c));

  // Changes arrive newest first; walk each item's own events oldest → newest.
  const drop = new Set<TrackChange>();
  const lastEvent = new Map<string, TrackChange>();
  for (let i = out.length - 1; i >= 0; i--) {
    const c = out[i];
    if (!c.itemLevel || (c.change !== 'added' && c.change !== 'removed')) continue;
    const k = itemOf(c);
    const prev = lastEvent.get(k);
    if (prev && prev.change === 'removed' && c.change === 'added') {
      drop.add(prev);
      drop.add(c);
      lastEvent.delete(k);
    } else lastEvent.set(k, c);
  }
  return drop.size ? out.filter((c) => !drop.has(c)) : out;
}

/* ── plain-English wording ───────────────────────────────────────────── */

const VERBS: [RegExp, [string, string]][] = [
  [/(packages|software|hotfix|hotfixes|recent_hotfixes|detected_software_json|items)$/i, ['Installed', 'Uninstalled']],
  [/(open_ports|ports)$/i, ['Opened', 'Closed']],
];
const listVerbs = (path: string): [string, string] => VERBS.find(([re]) => re.test(path))?.[1] ?? ['Added', 'Removed'];

export const shown = (v: unknown, lbl?: string | null) => fmtValue(v, lbl);

/** One change as a sentence, e.g. "Installed KB5132061", "Version: 1.1 → 3.0", "Set to Yes". */
export type ChangeText = { text: string; from?: string; to?: string; /** item details, shown muted */ note?: string };

export function describeChange(t: Track, c: TrackChange): ChangeText {
  const where = c.where ? `${c.where}` : '';
  if (c.change === 'updated') return { text: `${where ? `${where}: ` : ''}Changed (values not recorded)` };
  if (c.change === 'added' || c.change === 'removed') {
    const [add, del] = listVerbs(t.path);
    const added = c.change === 'added';
    const val = added ? c.new : c.old;
    if (t.isList && !c.itemLevel) {   // a sub-field of an item appeared / vanished
      return added ? { text: `${where}: Set`, to: shown(val) } : { text: `${where}: Cleared`, from: shown(val) };
    }
    if (t.isList && !where && typeof val === 'string' && val.startsWith('[')) {
      return added ? { text: 'First recorded', to: val } : { text: 'Cleared', from: val };   // the whole list at once
    }
    if (t.isList) {
      // Item name, plus its details when the summary says more than the name.
      const detail = shown(val);
      if (!where || detail.startsWith(where)) return { text: `${added ? add : del} ${detail}` };
      return { text: `${added ? add : del} ${where}`, note: detail };
    }
    return added ? { text: `${where ? `${where}: ` : ''}Set`, to: shown(val) } : { text: `${where ? `${where}: ` : ''}Cleared`, from: shown(val) };
  }
  const prefix = where ? `${where}: ` : '';
  if (isEmpty(c.old) && !c.oldLabel) return { text: `${prefix}Set`, to: shown(c.new, c.newLabel) };
  if (isEmpty(c.new) && !c.newLabel) return { text: `${prefix}Cleared`, from: shown(c.old, c.oldLabel) };
  return { text: prefix ? prefix.slice(0, -2) : 'Changed', from: shown(c.old, c.oldLabel), to: shown(c.new, c.newLabel) };
}

/** Current value as text. */
export function currentValue(t: Track, estate = false): { text: string; muted: boolean } {
  if (t.kind === 'gone') return { text: estate ? 'Not reported by any asset now' : 'No longer reported', muted: true };
  if (estate) {   // catalog row: count = assets holding a value
    const n = t.count ?? 0;
    return n ? { text: `Set on ${n} asset${n === 1 ? '' : 's'}`, muted: false } : { text: 'Not set on any asset', muted: true };
  }
  if (t.kind === 'list') {
    const n = t.count ?? 0;
    if (!n) return { text: 'None', muted: true };
    const items = Array.isArray(t.value) ? (t.value as unknown[]).map((v) => shown(v)) : [];
    const head = items.slice(0, 3).join(', ');
    return { text: `${n} item${n === 1 ? '' : 's'}${head ? ` · ${head}${n > 3 ? '…' : ''}` : ''}`, muted: false };
  }
  if (isEmpty(t.value) && !t.label) return { text: 'Not set', muted: true };
  return { text: shown(t.value, t.label), muted: false };
}

export const inPeriod = (c: TrackChange, since: number | null) => since === null || (!!c.at && Date.parse(c.at) >= since);
