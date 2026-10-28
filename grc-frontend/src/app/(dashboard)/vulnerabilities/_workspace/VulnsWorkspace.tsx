'use client';

/**
 * VulnsWorkspace — Vulnerability Register, redesigned to the handoff mock
 * ("Vulnerabilities.mock.html") 1:1: a contextual-priority ribbon, a triage-view
 * rail, an Overview / Register toggle, and a clean findings table.
 *
 * Still purely presentational — ALL data, filter state + setters, permissions
 * and handlers arrive as props from VulnerabilitiesPage. The triage rail applies
 * a LOCAL view filter on top of the page's already-filtered `filteredVulns`;
 * search stays wired to the page. Priority · Ctx is the real `composite_priority`
 * (0–10) ×10 — the same number the server dashboard bands at 55 / 25.
 */

import { useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { Search, Download, Plus, Upload, FileSpreadsheet, Loader2, Building2, Clock, Target, LayoutDashboard, ChevronDown, Server, Ticket, ScanLine, Trash2, Filter, ArrowUpDown, Check, X } from 'lucide-react';
import { shortenVulnTitle, deBrandDomain, PriorityRawCell, PriorityContextualCell, enrichmentPriority, type Vulnerability } from './lib';
import CtemScopesRedesign from '../ctem-scopes/CtemScopesRedesign';
import VulnCommandCenter from './VulnCommandCenter';
import ScanWorkspace from './ScanWorkspace';

// ── mock palette (kept literal so the register reads exactly like the mock) ──
const AC = '#005B96', ACS = '#014A81', ACSOFT = '#EFF5FA';
const MUTED = '#8A95A1', FAINT = '#AEB8C2', BORDER = '#E8ECEE', BORDER2 = '#F0F3F5', INK = '#0F1F2B', SEC = '#3A4653';
const SEV = {
  critical: { pillC: '#C2453F', pillBg: '#FBEAEA', label: 'Critical', dot: '#C2453F' },
  high: { pillC: '#C0682F', pillBg: '#FCEEE2', label: 'High', dot: '#DB7B45' },
  medium: { pillC: '#9A6410', pillBg: '#FBF2DF', label: 'Medium', dot: '#E0AF33' },
  low: { pillC: '#1F7A54', pillBg: '#E7F5EE', label: 'Low', dot: '#005B96' },
  info: { pillC: '#6B7787', pillBg: '#EEF1F3', label: 'Info', dot: '#AEB8C2' },
} as const;
type SevKey = keyof typeof SEV;
const MONO = 'ui-monospace,Consolas,monospace';

const normSev = (s?: string): SevKey => {
  const k = (s || '').toLowerCase();
  return (k in SEV ? k : k === 'informational' ? 'info' : 'info') as SevKey;
};
const hasExploit = (v: Vulnerability) => (v.public_exploit_count ?? 0) > 0 || (v.exploitdb_count ?? 0) > 0 || !!v.kev_flag;
const ctxScore = (v: Vulnerability) => Math.round((v.composite_priority ?? 0) * 10); // 0–100
const band = (score: number) => (score >= 55 ? 'urgent' : score >= 25 ? 'moderate' : 'low');
const BAND_META = { urgent: { c: '#C2453F', label: 'Urgent' }, moderate: { c: '#9A6410', label: 'Mod' }, low: { c: '#1F7A54', label: 'Low' } } as const;
const isUnassigned = (v: Vulnerability) => !v.assigned_to && !(v as any).assignee_name && !((v as any).assigned_departments?.length);
const isLinked = (v: Vulnerability) => (((v as any).linked_assets?.length ?? 0) > 0);
const isExposed = (v: Vulnerability) => !!(v as any).internet_facing || !!(v as any).internet_exposed;
// MUST mirror the backend domains bucket (null plugin_family => "Uncategorized"): the sidebar
// counts come from the backend while the row filter runs here, so any divergence (e.g. the old
// affected_component/'General' fallback) made "Uncategorized" count 1 but show 0.
const domainOf = (v: Vulnerability) => v.plugin_family || 'Uncategorized';
const OPEN_ISH = new Set(['open', 'in_progress', 'remediated', 'verified']);
const dueLabel = (v: Vulnerability) => {
  if (!v.due_date) return null;
  const d = Math.ceil((new Date(v.due_date).getTime() - Date.now()) / 864e5);
  return d < 0 ? { t: `${-d}d overdue`, c: '#B23A3A' } : { t: `due ${d}d`, c: d <= 7 ? '#B23A3A' : SEC };
};

interface VulnDashboard {
  total_vulnerabilities?: number; by_severity?: Record<string, number>; by_status?: Record<string, number>;
  overdue_count?: number; sla_compliance?: Record<string, { total: number; resolved: number; on_time: number; compliance_rate: number }>;
  kev_count?: number; exploit_count?: number; no_exploit_count?: number; with_cve_count?: number;
  high_tactics_count?: number; high_tactics_with_exploit_count?: number; high_epss_count?: number;
  internet_exposed_count?: number; patch_count?: number; mttr_days?: number;
  contextual_priority?: { urgent?: number; moderate?: number; low?: number };
}

export interface VulnsWorkspaceProps {
  vulns: Vulnerability[]; filteredVulns: Vulnerability[]; dashboard: VulnDashboard | undefined; scoped?: boolean;
  domains?: { family: string; total: number; worst_severity: string }[]; loading?: boolean;
  registerType: 'standard' | 'nca'; setRegisterType: (v: 'standard' | 'nca') => void; renderNcaRegister: () => React.ReactNode;
  searchTerm: string; setSearchTerm: (v: string) => void;
  statusFilter: string; setStatusFilter: (v: string) => void;
  severityFilter: string; setSeverityFilter: (v: string) => void;
  showClosed: boolean; setShowClosed: (v: boolean) => void;
  exploitFilter: string; setExploitFilter: (v: string) => void;
  tacticsFilter: string; setTacticsFilter: (v: string) => void;
  assetFilter?: string; setAssetFilter?: (v: string) => void; assetItems?: { value: string; label: string }[];
  canCreate: boolean; canEdit: boolean; canDelete: boolean;
  onView: (vuln: Vulnerability) => void; onEdit?: (vuln: Vulnerability) => void; onAssign?: (vuln: Vulnerability) => void;
  onChangeStatus?: (vuln: Vulnerability) => void; onDelete?: (vuln: Vulnerability) => void;
  onBulkAssign?: (ids: number[]) => void; onOpenFull: (id: number) => void;
  /** Create Help Desk tickets for a set of findings (passed the currently-shown ids). Omitted → button hidden. */
  onBulkCreateTickets?: (ids: number[]) => void;
  onTemplate: () => void; onBulkUpload: () => void; onImport: () => void; onAdd: () => void;
  bulkUploadState?: 'idle' | 'uploading' | 'done' | 'error'; bulkUploadMsg?: string | null;
}

type TriageView = 'all' | 'kev' | 'exploit' | 'cve' | 'epss' | 'exposed' | 'unassigned' | 'linked' | 'unlinked' | `sev-${SevKey}` | `dom-${string}`;

// Prominent header bar — brand blue, bold white (owner ask). Sticky over the body.
const th: React.CSSProperties = { textAlign: 'left', fontSize: 11, letterSpacing: '.04em', textTransform: 'uppercase', color: '#fff', fontWeight: 700, padding: '9px 10px', borderBottom: '1px solid #0A4C84', whiteSpace: 'nowrap', position: 'sticky', top: 0, background: '#005B96', zIndex: 1 };
const td: React.CSSProperties = { padding: '9px 10px', borderBottom: `1px solid ${BORDER2}`, verticalAlign: 'middle', whiteSpace: 'nowrap', fontSize: 12 };
const SEV_ORDER: Record<SevKey, number> = { critical: 5, high: 4, medium: 3, low: 2, info: 1 };
// Click a header to sort by it (replaces the old Sort select). Metrics sort high→low, text A→Z.
const HEADS: { key: string; label: string; sortable: boolean }[] = [
  { key: 'id', label: 'ID', sortable: true }, { key: 'title', label: 'Title', sortable: true },
  { key: 'asset', label: 'Linked asset', sortable: true }, { key: 'cve', label: 'CVE', sortable: true },
  { key: 'sev', label: 'Severity', sortable: true }, { key: 'cvss', label: 'CVSS', sortable: true },
  { key: 'epss', label: 'EPSS', sortable: true }, { key: 'exploit', label: 'Exploit', sortable: true },
  { key: 'before', label: 'Priority before', sortable: true }, { key: 'after', label: 'Priority after', sortable: true },
  { key: 'status', label: 'Status', sortable: true },
  { key: 'due', label: 'SLA / Due', sortable: true }, { key: 'owner', label: 'Assigned to', sortable: true },
];
const _ownerOf = (v: Vulnerability) => ((v as any).assignee_name || v.assigned_to || '') as string;
const SORTERS: Record<string, (a: Vulnerability, b: Vulnerability) => number> = {
  id: (a, b) => (a.id || 0) - (b.id || 0),
  title: (a, b) => (a.title || '').localeCompare(b.title || ''),
  asset: (a, b) => (a.linked_assets?.[0] || '').localeCompare(b.linked_assets?.[0] || ''),
  cve: (a, b) => (a.cve_id || '').localeCompare(b.cve_id || ''),
  sev: (a, b) => SEV_ORDER[normSev(a.severity)] - SEV_ORDER[normSev(b.severity)],
  cvss: (a, b) => (a.cvss_score ?? 0) - (b.cvss_score ?? 0),
  epss: (a, b) => (a.epss_score ?? 0) - (b.epss_score ?? 0),
  exploit: (a, b) => (hasExploit(a) ? 1 : 0) - (hasExploit(b) ? 1 : 0),
  before: (a, b) => enrichmentPriority(a).before - enrichmentPriority(b).before,
  after: (a, b) => ctxScore(a) - ctxScore(b),
  status: (a, b) => (a.status || '').localeCompare(b.status || ''),
  due: (a, b) => new Date(a.due_date || '2999-01-01').getTime() - new Date(b.due_date || '2999-01-01').getTime(),
  owner: (a, b) => _ownerOf(a).localeCompare(_ownerOf(b)),
};
const TEXT_SORTS = new Set(['title', 'asset', 'cve', 'status', 'owner']);
// Short labels for the Sort menu button/list (HEADS labels are too long for a button).
const SORT_LABEL: Record<string, string> = { id: 'ID', title: 'Title', asset: 'Linked asset', cve: 'CVE', sev: 'Severity', cvss: 'CVSS', epss: 'EPSS', exploit: 'Exploit', before: 'Priority (before)', after: 'Priority (after)', status: 'Status', due: 'SLA / Due', owner: 'Assigned to' };
const btn: React.CSSProperties = { border: `1px solid #E4E8EC`, background: '#fff', color: SEC, borderRadius: 9, padding: '7px 12px', fontSize: 12, fontWeight: 500, display: 'inline-flex', alignItems: 'center', gap: 6, cursor: 'pointer' };
const btnGreen: React.CSSProperties = { ...btn, background: AC, borderColor: AC, color: '#fff', fontWeight: 600 };
const pill = (c: string, bg: string): React.CSSProperties => ({ display: 'inline-flex', alignItems: 'center', gap: 5, fontSize: 11, fontWeight: 600, padding: '2px 9px', borderRadius: 999, whiteSpace: 'nowrap', color: c, background: bg });

const SevPill = ({ s }: { s?: string }) => { const m = SEV[normSev(s)]; return <span style={pill(m.pillC, m.pillBg)}>{m.label}</span>; };

// One row of the "Import ▾" overflow menu — the three data-import actions live
// here instead of as three scattered toolbar buttons.
function ImportItem({ Icon, label, hint, onClick }: { Icon: typeof Plus; label: string; hint: string; onClick: () => void }) {
  return (
    <button role="menuitem" onClick={onClick} className="imp-item" style={{ display: 'flex', alignItems: 'center', gap: 10, width: '100%', border: 0, background: 'none', borderRadius: 9, padding: '8px 9px', cursor: 'pointer', textAlign: 'left' }}>
      <span style={{ width: 28, height: 28, borderRadius: 8, background: ACSOFT, color: AC, display: 'grid', placeItems: 'center', flex: 'none' }}><Icon size={15} /></span>
      <span style={{ minWidth: 0 }}>
        <span style={{ display: 'block', fontSize: 12.5, fontWeight: 600, color: INK }}>{label}</span>
        <span style={{ display: 'block', fontSize: 10.5, color: MUTED }}>{hint}</span>
      </span>
    </button>
  );
}

type Pane = 'cmd' | 'reg' | 'scan' | 'ctem';
const PANE_META: { key: Pane; label: string; Icon?: typeof Target }[] = [
  { key: 'cmd', label: 'Overview', Icon: LayoutDashboard },
  { key: 'reg', label: 'Register' },
  { key: 'scan', label: 'Scan', Icon: ScanLine },
  { key: 'ctem', label: 'CTEM Scopes', Icon: Target },
];
// One toggle, shared by the Overview surface and the register area — so the
// panes (Overview / Register / CTEM) can never drift apart. The old "Insights"
// pane was retired: it duplicated the analytics the Overview now owns.
function PaneToggle({ pane, setPane }: { pane: Pane; setPane: (p: Pane) => void }) {
  return (
    <div style={{ display: 'inline-flex', background: '#EAEEF1', borderRadius: 11, padding: 3, gap: 2 }}>
      {PANE_META.map(({ key, label, Icon }) => (
        <button key={key} onClick={() => setPane(key)} style={{ height: 32, padding: '0 14px', border: 0, borderRadius: 9, background: pane === key ? '#fff' : 'none', color: pane === key ? ACS : '#6B7787', fontSize: 12.5, fontWeight: 600, cursor: 'pointer', boxShadow: pane === key ? '0 1px 2px rgba(16,24,40,.06)' : 'none', display: 'inline-flex', alignItems: 'center', gap: 6 }}>{Icon && <Icon size={14} />}{label}</button>
      ))}
    </div>
  );
}

export function VulnsWorkspace(props: VulnsWorkspaceProps) {
  const {
    vulns, filteredVulns, dashboard, domains = [], loading = false, scoped = false,
    registerType, setRegisterType, renderNcaRegister,
    searchTerm, setSearchTerm, canCreate, canDelete, onDelete, onView, onOpenFull, onTemplate, onBulkUpload, onImport, onAdd,
    bulkUploadState = 'idle', bulkUploadMsg, onBulkCreateTickets,
    assetItems = [],
  } = props;

  // Independent filter axes, AND-combined — one named top-bar control each (was a single lumped
  // "Triage views" select). fFlag is single-select across the non-column flags (KEV / exploit / …).
  const [fSev, setFSev] = useState('');
  const [fDom, setFDom] = useState('');
  const [fStatus, setFStatus] = useState('');
  const [fFlag, setFFlag] = useState('');
  // Two-flow filter — surface (unauthenticated) vs authenticated findings.
  // Client-side only, layered on top of the page's already-filtered list.
  const [scanMode, setScanMode] = useState<'all' | 'surface' | 'credentialed'>('all');
  const [importOpen, setImportOpen] = useState(false); // "Import ▾" overflow menu
  // Overview ("Command") is the default landing pane — the act-now worklist —
  // with the register one click away. When scoped to a CTEM scope the register
  // itself is the point, so land there instead (the Overview reads the whole list).
  const [pane, setPane] = useState<Pane>(scoped ? 'reg' : 'cmd');
  const [sort, setSort] = useState('after');
  const [dir, setDir] = useState<1 | -1>(-1); // -1 = desc (highest priority / newest first)
  const [filtersOpen, setFiltersOpen] = useState(false); // right-side filter slide-over
  const [sortOpen, setSortOpen] = useState(false); // sort field/direction menu
  const isNca = registerType === 'nca';

  // Esc closes the filter drawer / sort menu (outside-click handled by their backdrops).
  useEffect(() => {
    if (!filtersOpen && !sortOpen) return;
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') { setFiltersOpen(false); setSortOpen(false); } };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [filtersOpen, sortOpen]);

  const all = vulns ?? [];
  const count = (f: (v: Vulnerability) => boolean) => all.filter(f).length;

  // Contextual-priority band tally (real composite_priority) — prefer server, else derive.
  const agg = useMemo(() => {
    const d = dashboard ?? {};
    const ctx = d.contextual_priority ?? {};
    const derive = () => ({ urgent: count((v) => ctxScore(v) >= 55), moderate: count((v) => ctxScore(v) >= 25 && ctxScore(v) < 55), low: count((v) => ctxScore(v) < 25) });
    const dv = (ctx.urgent == null) ? derive() : { urgent: ctx.urgent ?? 0, moderate: ctx.moderate ?? 0, low: ctx.low ?? 0 };
    return {
      total: d.total_vulnerabilities ?? all.length,
      kev: d.kev_count ?? count((v) => !!v.kev_flag),
      mttr: d.mttr_days,
      slaRate: d.sla_compliance ? Math.round((Object.values(d.sla_compliance).reduce((s, x) => s + (x.compliance_rate || 0), 0) / Math.max(1, Object.values(d.sla_compliance).length))) : null,
      ...dv,
    };
  }, [dashboard, all]);

  // Triage rail (counts from the full list).
  // Rail counts are the TRUE totals from the server dashboard (same source as the ribbon's
  // "Actively exploited"), so they never under-count the fetched page; client tally is only a
  // fallback when an aggregate is absent.
  const dcount = (agg: number | undefined, f: (v: Vulnerability) => boolean) => (agg != null ? agg : count(f));
  const RAIL: { key: TriageView; label: string; n: number; dot?: string; sw?: string }[] = [
    { key: 'all', label: 'All findings', n: dashboard?.total_vulnerabilities ?? all.length },
    { key: 'kev', label: 'Fix first · KEV', n: dcount(dashboard?.kev_count, (v) => !!v.kev_flag), dot: '#C2453F' },
    { key: 'exploit', label: 'Public exploit', n: dcount(dashboard?.exploit_count, hasExploit), dot: '#DB7B45' },
    { key: 'cve', label: 'With CVE', n: dcount(dashboard?.with_cve_count, (v) => !!v.cve_id), dot: '#2E63A8' },
    { key: 'epss', label: 'High EPSS', n: dcount(dashboard?.high_epss_count, (v) => (v.epss_score ?? 0) >= 0.1), dot: '#9A6410' },
    { key: 'exposed', label: 'Internet-exposed', n: dcount(dashboard?.internet_exposed_count, isExposed), dot: '#6A54C9' },
    { key: 'unassigned', label: 'Unassigned', n: count(isUnassigned), dot: '#8A95A1' },
    { key: 'linked', label: 'Asset-linked', n: count(isLinked), dot: '#2F9E5A' },
    { key: 'unlinked', label: 'Unlinked', n: count((v) => !isLinked(v)), dot: '#B98900' },
  ];
  // De-brand engine/tool names → assessment type, then MERGE families that
  // collapse to the same label (so the rail shows one "Penetration test", not five).
  const SEV_RANK: Record<SevKey, number> = { critical: 5, high: 4, medium: 3, low: 2, info: 1 };
  const domGroups = new Map<string, { n: number; worst: SevKey }>();
  for (const d of domains ?? []) {
    const label = deBrandDomain(d.family); const ws = normSev(d.worst_severity);
    const e = domGroups.get(label) || { n: 0, worst: 'info' as SevKey };
    e.n += d.total; if (SEV_RANK[ws] > SEV_RANK[e.worst]) e.worst = ws;
    domGroups.set(label, e);
  }
  const DOM_RAIL = Array.from(domGroups.entries()).sort((a, b) => b[1].n - a[1].n).slice(0, 6)
    .map(([label, e]) => ({ key: `dom-${label}` as TriageView, label, n: e.n, sw: SEV[e.worst].dot }));

  const flagOk = (v: Vulnerability) =>
    !fFlag
    || (fFlag === 'kev' ? !!v.kev_flag
      : fFlag === 'exploit' ? hasExploit(v)
      : fFlag === 'cve' ? !!v.cve_id
      : fFlag === 'epss' ? (v.epss_score ?? 0) >= 0.1
      : fFlag === 'exposed' ? isExposed(v)
      : fFlag === 'unassigned' ? isUnassigned(v)
      : fFlag === 'linked' ? isLinked(v)
      : fFlag === 'unlinked' ? !isLinked(v)
      : true);
  const rows = useMemo(() => {
    const r = (filteredVulns ?? []).filter((v) =>
      (!fSev || normSev(v.severity) === fSev) &&
      (!fDom || deBrandDomain(domainOf(v)) === fDom) &&
      (!fStatus || (v.status || 'open').toLowerCase() === fStatus) &&
      (scanMode === 'all' || (v.scan_mode ?? null) === scanMode) &&
      flagOk(v));
    const cmp = SORTERS[sort] || SORTERS.after;
    return [...r].sort((a, b) => cmp(a, b) * dir);
  }, [filteredVulns, fSev, fDom, fStatus, scanMode, fFlag, sort, dir]);
  // Click a header: same column flips direction; a new column sorts text A→Z, metrics high→low.
  const sortBy = (k: string) => { if (sort === k) setDir((d) => (d === 1 ? -1 : 1)); else { setSort(k); setDir(TEXT_SORTS.has(k) ? 1 : -1); } };

  const anyFilter = !!(fSev || fDom || fStatus || fFlag) || scanMode !== 'all';
  const activeCount = (fSev ? 1 : 0) + (fDom ? 1 : 0) + (fStatus ? 1 : 0) + (fFlag ? 1 : 0) + (scanMode !== 'all' ? 1 : 0);
  const sevOpts = (['critical', 'high', 'medium', 'low', 'info'] as SevKey[]).map((k) => ({ k, label: SEV[k].label, n: count((v) => normSev(v.severity) === k) }));
  const statusOpts = Array.from(new Set(all.map((v) => (v.status || 'open').toLowerCase()))).sort();

  // Filter-drawer building blocks — every option is a custom click control (native <select>
  // dropdowns don't render under the .inv2 zoom:0.8 on Chrome). Single-select per group, cleared
  // by re-clicking the active option; AND-combined across groups; filtering applies live.
  const grpWrap: React.CSSProperties = { display: 'flex', flexWrap: 'wrap', gap: 8 };
  const grpTitle = (t: string) => <div style={{ fontSize: 11.5, fontWeight: 800, letterSpacing: '.05em', textTransform: 'uppercase', color: INK, margin: '16px 0 8px' }}>{t}</div>;
  const optPill = (key: string, active: boolean, label: string, n: number | undefined, onClick: () => void) => (
    <button key={key} type="button" role="checkbox" aria-checked={active} onClick={onClick}
      style={{ display: 'inline-flex', alignItems: 'center', gap: 6, height: 32, padding: '0 11px', border: `1px solid ${active ? AC : '#E4E8EC'}`, background: active ? AC : '#fff', color: active ? '#fff' : SEC, borderRadius: 999, fontSize: 12, fontWeight: active ? 600 : 500, cursor: 'pointer', textTransform: 'capitalize' }}>
      {active && <Check size={13} />}{label}{n != null && <span style={{ opacity: 0.75, fontWeight: 500 }}>{n}</span>}
    </button>
  );
  const clearAll = () => { setFSev(''); setFDom(''); setFStatus(''); setFFlag(''); setScanMode('all'); };

  // Overview (cmd) flows at natural height so the whole page scrolls with the
  // shell's <main> — like every other page, no contained inner scrollbar.
  // Register/CTEM keep their own bounded-height inner table scroll.
  const pageScroll = pane === 'cmd' && !isNca;

  return (
    // zoom:0.8 is the SAME density knob the Performance page uses (page at 80%) — it scales
    // the header AND the VulnCommandCenter dashboard (which renders inside this root) uniformly.
    // Bounded panes (register/CTEM/NCA) are height:100%, which would only fill 80% once zoomed,
    // so they compensate to 100%/0.8 = 125% layout height → exactly one viewport after zoom.
    <div className="inv2" style={{ background: '#F4F6F7', zoom: 0.8, height: pageScroll ? 'auto' : 'calc(100% / 0.8)', minHeight: 0, display: 'flex', flexDirection: 'column', overflowY: pageScroll ? 'visible' : 'auto', overflowX: pageScroll ? 'visible' : 'hidden', padding: '10px 10px 0', fontSize: 13.5, color: INK }}>
      {/* ONE shared pane toggle, pinned at the top of every pane (non-NCA) so the four tabs
          never move or disappear — always in the same place, whichever pane is open. */}
      {!isNca && <div style={{ marginBottom: 10, flexShrink: 0 }}><PaneToggle pane={pane} setPane={setPane} /></div>}
      {/* header — hidden on the CTEM/Scan panes (they carry their own) */}
      {pane !== 'ctem' && pane !== 'scan' && (
      <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 16, marginBottom: 10, flexWrap: 'wrap', flexShrink: 0 }}>
        <div>
          <h1 style={{ fontSize: 19, letterSpacing: '-.025em', margin: 0 }}>{isNca ? 'NCA Vulnerability Register' : 'Vulnerability Register'}</h1>
          <div style={{ fontSize: 12.5, color: MUTED, marginTop: 3, display: 'flex', alignItems: 'center', gap: 7 }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: AC }} />{agg.total} findings · triage by real-world priority, not raw CVSS
          </div>
        </div>
        {/* Two clean zones: [ which register ] │ [ import ▾ ] [ + Add (primary) ].
            Choke points removed; the three import actions collapse into one menu. */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
          <select value={registerType} onChange={(e) => setRegisterType(e.target.value as 'standard' | 'nca')} style={{ ...btn, cursor: 'pointer' }} title="Switch register">
            <option value="standard">Standard register</option><option value="nca">NCA Template</option>
          </select>
          {canCreate && (
            <>
              <span aria-hidden style={{ width: 1, height: 22, background: BORDER, flex: 'none' }} />
              <div style={{ position: 'relative' }}>
                <button style={btn} onClick={() => setImportOpen((o) => !o)} aria-haspopup="menu" aria-expanded={importOpen} title="Import findings">
                  {bulkUploadState === 'uploading' ? <Loader2 size={15} className="animate-spin" /> : <Upload size={15} />}Import<ChevronDown size={14} style={{ marginLeft: 1, opacity: 0.55 }} />
                </button>
                {importOpen && (
                  <>
                    {/* transparent backdrop = lazy, reliable click-outside-to-close */}
                    <div onClick={() => setImportOpen(false)} style={{ position: 'fixed', inset: 0, zIndex: 40 }} />
                    <div role="menu" style={{ position: 'absolute', top: 'calc(100% + 6px)', right: 0, zIndex: 41, minWidth: 214, background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 12, boxShadow: '0 14px 34px -10px rgba(16,24,40,.32)', padding: 5 }}>
                      <ImportItem Icon={Download} label="Download template" hint="CSV starter file" onClick={() => { setImportOpen(false); onTemplate(); }} />
                      <ImportItem Icon={Upload} label="Bulk upload" hint="Fill the template, upload it" onClick={() => { setImportOpen(false); onBulkUpload(); }} />
                      <ImportItem Icon={FileSpreadsheet} label="Smart import" hint="Map any spreadsheet" onClick={() => { setImportOpen(false); onImport(); }} />
                    </div>
                  </>
                )}
              </div>
            </>
          )}
          {canCreate && <button style={btnGreen} onClick={onAdd}><Plus size={15} />{isNca ? 'Add NCA Entry' : 'Add Vulnerability'}</button>}
        </div>
      </div>
      )}

      {pane !== 'ctem' && pane !== 'scan' && bulkUploadMsg && <div style={{ marginBottom: 12, borderRadius: 9, padding: '9px 14px', fontSize: 12.5, fontWeight: 500, background: bulkUploadState === 'error' ? '#FBEAEA' : '#E7F5EE', color: bulkUploadState === 'error' ? '#B23A3A' : '#1F7A54' }}>{bulkUploadMsg}</div>}

      {isNca ? (
        <div style={{ background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 14, flex: 1, minHeight: 0, overflow: 'auto' }}>{renderNcaRegister()}</div>
      ) : (
        <>
          {pane === 'scan' ? (
            <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
              <div style={{ flex: 1, minHeight: 0 }}><ScanWorkspace vulns={all} assetItems={assetItems} /></div>
            </div>
          ) : pane === 'ctem' ? (
            <div style={{ flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
              <div style={{ flex: 1, minHeight: 0 }}><CtemScopesRedesign /></div>
            </div>
          ) : pane === 'cmd' ? (
            <div style={{ flexShrink: 0, display: 'flex', flexDirection: 'column' }}>
              <div><VulnCommandCenter vulns={all} dashboard={dashboard} onView={onView} /></div>
            </div>
          ) : (
          <>
          {/* contextual-priority ribbon */}
          <section style={{ background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 14, boxShadow: '0 1px 2px rgba(16,24,40,.04)', display: 'flex', alignItems: 'stretch', flexWrap: 'wrap', marginBottom: 10, flexShrink: 0 }}>
            <div style={{ padding: '10px 16px', flex: 1, minWidth: 320 }}>
              <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 5 }}><span style={{ fontSize: 12, color: MUTED, fontWeight: 500 }}>Contextual priority</span><span style={{ fontSize: 10.5, color: FAINT }}>raw severity ≠ real priority</span></div>
              <div style={{ display: 'flex', height: 9, borderRadius: 999, overflow: 'hidden', background: '#EAEEF1' }}>
                {[['urgent', agg.urgent, '#C2453F'], ['moderate', agg.moderate, '#E0AF33'], ['low', agg.low, '#005B96']].map(([k, n, c]) => <i key={k as string} style={{ width: `${(Number(n) / Math.max(1, agg.total)) * 100}%`, background: c as string }} />)}
              </div>
              <div style={{ display: 'flex', gap: 16, marginTop: 6, flexWrap: 'wrap', fontSize: 12 }}>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 7 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: '#C2453F' }} />Urgent <b className="num" style={{ color: INK }}>{agg.urgent}</b></span>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 7 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: '#E0AF33' }} />Moderate <b className="num" style={{ color: INK }}>{agg.moderate}</b></span>
                <span style={{ display: 'inline-flex', alignItems: 'center', gap: 7 }}><span style={{ width: 8, height: 8, borderRadius: 2, background: '#005B96' }} />Low <b className="num" style={{ color: INK }}>{agg.low}</b></span>
                <span style={{ color: FAINT, fontSize: 11 }}>most &ldquo;critical-looking&rdquo; findings are internal, unexploited, low-EPSS</span>
              </div>
            </div>
            <div style={{ width: 1, background: BORDER2, margin: '10px 0' }} />
            <div style={{ display: 'flex', alignItems: 'center', gap: 22, padding: '10px 18px', flexWrap: 'wrap' }}>
              <div><div style={{ fontSize: 11.5, color: MUTED }}>Total findings</div><b className="num" style={{ fontSize: 17, fontWeight: 600 }}>{agg.total}</b></div>
              <div><div style={{ fontSize: 11.5, color: MUTED }}>Actively exploited</div><b className="num" style={{ fontSize: 17, fontWeight: 600, color: agg.kev > 0 ? '#B23A3A' : INK }}>{agg.kev}</b></div>
              <div><div style={{ fontSize: 11.5, color: MUTED }}>MTTR</div><b className="num" style={{ fontSize: 17, fontWeight: 600 }}>{agg.mttr != null ? `${agg.mttr}d` : '—'}</b></div>
              <div><div style={{ fontSize: 11.5, color: MUTED }}>SLA</div><b className="num" style={{ fontSize: 17, fontWeight: 600, color: agg.slaRate != null && agg.slaRate < 80 ? '#B23A3A' : INK }}>{agg.slaRate != null ? `${agg.slaRate}%` : '—'}</b></div>
            </div>
          </section>

          {/* Full width — the left triage rail was cut; its Triage views / By severity / By domain
              filters now live in the single top-bar <select> below (same `view` state). */}
          <div style={{ display: 'flex', flexDirection: 'column', minHeight: 0, height: '100%', flexShrink: 0, overflow: 'hidden' }}>
            <div style={{ minWidth: 0, display: 'flex', flexDirection: 'column', minHeight: 0, flex: 1 }}>
              {/* Clean one-row toolbar: Search · Filters (drawer) · Sort (menu) · Create tickets.
                  The old 4 selects + 8 chips + Dept/SLA links moved into the filter drawer; native
                  <select>s were also broken by the .inv2 zoom:0.8, so everything is custom now. */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 10, flexShrink: 0 }}>
                <div style={{ position: 'relative', flex: 1, minWidth: 200 }}>
                  <Search size={16} style={{ position: 'absolute', left: 11, top: 10, color: FAINT }} />
                  <input value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} placeholder="Search by title, CVE ID…" style={{ width: '100%', height: 34, border: `1px solid #E4E8EC`, borderRadius: 9, padding: '0 12px 0 34px', fontSize: 12.5, color: SEC, background: '#fff' }} />
                </div>
                <button type="button" onClick={() => setFiltersOpen(true)} aria-haspopup="dialog" aria-expanded={filtersOpen} title="Filter findings"
                  style={{ ...btn, height: 34, cursor: 'pointer', ...(activeCount ? { borderColor: AC, color: AC, background: ACSOFT, fontWeight: 600 } : {}) }}>
                  <Filter size={15} />Filters
                  {activeCount > 0 && <span style={{ minWidth: 18, height: 18, padding: '0 5px', borderRadius: 999, background: AC, color: '#fff', fontSize: 10.5, fontWeight: 700, display: 'inline-grid', placeItems: 'center' }}>{activeCount}</span>}
                </button>
                <div style={{ position: 'relative' }}>
                  <button type="button" onClick={() => setSortOpen((o) => !o)} aria-haspopup="menu" aria-expanded={sortOpen} title="Change sort field and direction"
                    style={{ ...btn, height: 34, cursor: 'pointer' }}>
                    <ArrowUpDown size={14} />Sort: {SORT_LABEL[sort] || 'Priority'} {dir === -1 ? '↓' : '↑'}
                  </button>
                  {sortOpen && (
                    <>
                      <div onClick={() => setSortOpen(false)} style={{ position: 'fixed', inset: 0, zIndex: 40 }} />
                      <div role="menu" style={{ position: 'absolute', top: 'calc(100% + 6px)', left: 0, zIndex: 41, minWidth: 224, background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 12, boxShadow: '0 14px 34px -10px rgba(16,24,40,.32)', padding: 6 }}>
                        <div style={{ display: 'flex', gap: 4, padding: '2px 4px 8px' }}>
                          {([[1, 'Ascending', '↑'], [-1, 'Descending', '↓']] as const).map(([d, lbl, ar]) => (
                            <button key={d} type="button" onClick={() => setDir(d)}
                              style={{ flex: 1, height: 30, border: `1px solid ${dir === d ? AC : '#E4E8EC'}`, background: dir === d ? AC : '#fff', color: dir === d ? '#fff' : SEC, borderRadius: 8, fontSize: 11.5, fontWeight: 600, cursor: 'pointer' }}>{ar} {lbl}</button>
                          ))}
                        </div>
                        <div style={{ borderTop: `1px solid ${BORDER2}`, paddingTop: 4 }}>
                          {HEADS.filter((h) => h.sortable).map((h) => {
                            const on = sort === h.key;
                            return (
                              <button key={h.key} role="menuitemradio" aria-checked={on} type="button" onClick={() => { setSort(h.key); setSortOpen(false); }}
                                style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%', border: 0, background: on ? ACSOFT : 'none', color: on ? ACS : SEC, borderRadius: 8, padding: '7px 9px', fontSize: 12, fontWeight: on ? 600 : 500, cursor: 'pointer', textAlign: 'left' }}>
                                {SORT_LABEL[h.key] || h.label}{on && <Check size={14} />}
                              </button>
                            );
                          })}
                        </div>
                      </div>
                    </>
                  )}
                </div>
                {onBulkCreateTickets && rows.length > 0 && (
                  <button
                    style={{ ...btnGreen, height: 34 }}
                    title="Open a Help Desk ticket for every finding shown in this view (idempotent — findings that already have a ticket are skipped)"
                    onClick={() => {
                      const ids = rows.map((v) => v.id);
                      if (window.confirm(`Create Help Desk tickets for the ${ids.length} finding(s) shown? Findings that already have a ticket are skipped.`)) {
                        onBulkCreateTickets(ids);
                      }
                    }}
                  >
                    <Ticket size={14} /> Create Help Desk tickets
                  </button>
                )}
              </div>

              {(
                <div style={{ background: '#fff', border: `1px solid ${BORDER}`, borderRadius: 14, boxShadow: '0 1px 2px rgba(16,24,40,.04)', overflow: 'hidden', flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column' }}>
                  <div style={{ overflow: 'auto', flex: 1, minHeight: 0 }}>
                    {/* The dashboard shell's global `.governance-light thead th` repaints headers light/muted
                        and overrides our inline blue, so force the brand-blue header bar with a scoped rule. */}
                    <style dangerouslySetInnerHTML={{ __html: '.inv2 .vreg-tbl thead th{background:#005B96!important;color:#fff!important;border-bottom-color:#0A4C84!important;font-weight:700!important}' }} />
                    <table className="vreg-tbl" style={{ width: '100%', borderCollapse: 'collapse', tableLayout: 'auto' }}>
                      <thead><tr>{HEADS.map((h) => (
                        <th key={h.key} style={{ ...th, cursor: h.sortable ? 'pointer' : 'default', userSelect: 'none' }}
                          onClick={h.sortable ? () => sortBy(h.key) : undefined}
                          title={h.sortable ? `Sort by ${h.label}` : undefined}>
                          {h.label}{sort === h.key ? <span style={{ marginLeft: 5, fontWeight: 800 }} title={dir === -1 ? 'Descending' : 'Ascending'}>{dir === -1 ? '↓' : '↑'}</span> : null}
                        </th>
                      ))}{canDelete && <th style={th}></th>}</tr></thead>
                      <tbody>
                        {loading ? (
                          <tr><td colSpan={canDelete ? 14 : 13} style={{ ...td, textAlign: 'center', color: '#9BA6B2', padding: 28 }}>Loading…</td></tr>
                        ) : rows.length === 0 ? (
                          <tr><td colSpan={canDelete ? 14 : 13} style={{ ...td, textAlign: 'center', color: '#9BA6B2', padding: 28 }}>No findings match this view.</td></tr>
                        ) : rows.map((v) => {
                          const sev = normSev(v.severity); const sm = SEV[sev];
                          const exp = hasExploit(v); const due = dueLabel(v);
                          const owner = (v as any).assignee_name as string | undefined;
                          const depts = (v as any).assigned_departments as string[] | undefined;
                          const assets = v.linked_assets || [];
                          return (
                            <tr key={v.id} onClick={() => onView(v)} style={{ cursor: 'pointer' }} className="vrow">
                              <td style={{ ...td, fontFamily: MONO }}>VULN-{v.id}</td>
                              <td style={{ ...td, maxWidth: 240, overflow: 'hidden', textOverflow: 'ellipsis' }} title={v.title}>{shortenVulnTitle(v.title)}{v.kev_flag && <span style={{ ...pill('#C2453F', '#FBEAEA'), fontSize: 9, marginLeft: 6 }}>KEV</span>}{v.scan_mode === 'surface' && <span style={{ ...pill(MUTED, '#EEF1F3'), fontSize: 9, marginLeft: 6 }} title="Surface / Unauthenticated scan">Surface</span>}{v.scan_mode === 'credentialed' && <span style={{ ...pill(ACS, '#EFF5FA'), fontSize: 9, marginLeft: 6 }} title="Authenticated scan">Auth</span>}</td>
                              {/* LINKED ASSET — promoted to a prominent lead field so "this finding → this asset" reads at a glance */}
                              <td style={{ ...td, maxWidth: 230 }}>
                                {assets.length ? (
                                  <span style={{ display: 'inline-flex', alignItems: 'center', gap: 7, maxWidth: 230 }} title={assets.join(', ')}>
                                    <span style={{ width: 22, height: 22, borderRadius: 6, background: ACSOFT, color: AC, display: 'grid', placeItems: 'center', flex: 'none' }}><Server size={12} /></span>
                                    <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}><b style={{ fontWeight: 600, color: INK }}>{assets[0]}</b>{assets.length > 1 && <span style={{ color: FAINT, fontWeight: 500 }}> +{assets.length - 1}</span>}</span>
                                  </span>
                                ) : <span style={{ color: FAINT, fontStyle: 'italic' }}>— no linked asset</span>}
                              </td>
                              <td style={{ ...td, fontFamily: MONO, color: v.cve_id ? SEC : FAINT }}>{v.cve_id || '—'}</td>
                              <td style={td}><SevPill s={v.severity} /></td>
                              <td style={{ ...td, fontFamily: MONO, color: sm.pillC }}>{v.cvss_score ?? '—'}</td>
                              <td style={{ ...td, fontFamily: MONO, color: FAINT }}>{v.epss_score != null ? `${(v.epss_score * 100).toFixed(1)}%` : '—'}</td>
                              <td style={{ ...td, color: exp ? '#C0682F' : FAINT }}>{exp ? 'Public' : 'None'}</td>
                              <td style={td}><PriorityRawCell v={v} /></td>
                              <td style={td}><PriorityContextualCell v={v} /></td>
                              <td style={td}><span style={{ ...pill('#B23A3A', '#fff'), border: '1px solid #F3D3DA', textTransform: 'capitalize' }}>{(v.status || 'open').replace(/_/g, ' ')}</span></td>
                              <td style={td}>{due ? <b style={{ fontWeight: 600, color: due.c }}>{due.t}</b> : <span style={{ color: FAINT }}>—</span>}</td>
                              <td style={td}>
                                {depts && depts.length ? (
                                  <span style={{ display: 'inline-flex', flexDirection: 'column', lineHeight: 1.25 }} title={[...depts, owner].filter(Boolean).join(' · ')}>
                                    <span style={{ color: SEC }}>{depts[0]}{depts.length > 1 && <span style={{ color: FAINT }}> +{depts.length - 1}</span>}</span>
                                    {owner && <span style={{ fontSize: 10.5, color: FAINT }}>{owner}</span>}
                                  </span>
                                ) : owner ? <span style={{ color: SEC }}>{owner}</span> : <span style={{ color: FAINT }}>Unassigned</span>}
                              </td>
                              {canDelete && (
                                <td style={{ ...td, textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                                  <button onClick={() => onDelete?.(v)} title="Delete from register"
                                    style={{ border: 'none', background: 'none', cursor: 'pointer', color: '#B23A3A', padding: 4, borderRadius: 6, display: 'inline-flex' }}>
                                    <Trash2 size={14} />
                                  </button>
                                </td>
                              )}
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                  <div style={{ padding: '7px 16px', fontSize: 11, color: MUTED }}>Row → full finding detail · click a column header or the <b>Sort</b> button to reorder · <b>Priority·Contextual</b> = composite of exposure, exploit, EPSS &amp; asset criticality on top of CVSS.</div>
                </div>
              )}
            </div>
          </div>

          {/* Filter slide-over — all dimensions as custom click controls (native <select> is broken
              under .inv2 zoom:0.8). Single-select per group, AND-combined, live. Esc + backdrop close. */}
          {filtersOpen && (
            <>
              <div onClick={() => setFiltersOpen(false)} style={{ position: 'fixed', inset: 0, background: 'rgba(16,24,40,.28)', zIndex: 50 }} />
              <aside role="dialog" aria-modal="true" aria-label="Filter findings" style={{ position: 'fixed', top: 0, right: 0, bottom: 0, width: 372, maxWidth: '92vw', background: '#fff', zIndex: 51, boxShadow: '-16px 0 40px -16px rgba(16,24,40,.4)', display: 'flex', flexDirection: 'column' }}>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '14px 18px', borderBottom: `1px solid ${BORDER}` }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}><Filter size={16} color={AC} /><h3 style={{ margin: 0, fontSize: 15 }}>Filters</h3>{activeCount > 0 && <span style={{ fontSize: 11.5, color: MUTED }}>{activeCount} active</span>}</div>
                  <button type="button" onClick={() => setFiltersOpen(false)} aria-label="Close filters" style={{ border: 0, background: 'none', cursor: 'pointer', color: SEC, padding: 4, borderRadius: 6, display: 'inline-flex' }}><X size={18} /></button>
                </div>
                <div style={{ flex: 1, minHeight: 0, overflowY: 'auto', padding: '2px 18px 18px' }}>
                  {grpTitle('Severity')}
                  <div style={grpWrap}>{sevOpts.map((o) => optPill(o.k, fSev === o.k, o.label, o.n, () => setFSev(fSev === o.k ? '' : o.k)))}</div>
                  {DOM_RAIL.length > 0 && (<>{grpTitle('Domain')}<div style={grpWrap}>{DOM_RAIL.map((r) => optPill(r.key as string, fDom === r.label, r.label, r.n, () => setFDom(fDom === r.label ? '' : r.label)))}</div></>)}
                  {grpTitle('Status')}
                  <div style={grpWrap}>{statusOpts.map((s) => optPill(s, fStatus === s, s.replace(/_/g, ' '), count((v) => (v.status || 'open').toLowerCase() === s), () => setFStatus(fStatus === s ? '' : s)))}</div>
                  {grpTitle('Scan provenance')}
                  <div style={grpWrap}>{([['all', 'All'], ['credentialed', 'Authenticated'], ['surface', 'Surface / Unauth']] as const).map(([v, l]) => optPill(v, scanMode === v, l, v === 'all' ? all.length : count((x) => (x.scan_mode ?? null) === v), () => setScanMode(v)))}</div>
                  {grpTitle('Triage flags')}
                  <div style={grpWrap}>{RAIL.filter((r) => r.key !== 'all').map((r) => optPill(r.key as string, fFlag === r.key, r.label, r.n, () => setFFlag(fFlag === r.key ? '' : (r.key as string))))}</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 10, padding: '12px 18px', borderTop: `1px solid ${BORDER}` }}>
                  <div style={{ display: 'flex', gap: 14 }}>
                    <Link href="/vulnerabilities/departments" style={{ fontSize: 12, color: AC, textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: 5 }}><Building2 size={14} />Departments</Link>
                    <Link href="/vulnerabilities/sla" style={{ fontSize: 12, color: AC, textDecoration: 'none', display: 'inline-flex', alignItems: 'center', gap: 5 }}><Clock size={14} />SLA</Link>
                  </div>
                  <button type="button" disabled={!anyFilter} onClick={clearAll}
                    style={{ ...btn, height: 32, opacity: anyFilter ? 1 : 0.5, cursor: anyFilter ? 'pointer' : 'default' }}>Clear all</button>
                </div>
              </aside>
            </>
          )}
          </>
          )}
        </>
      )}
      <style>{`.inv2 .vrow:hover{background:#F7FBFA}.inv2 .imp-item:hover{background:#F2F7FB}`}</style>
    </div>
  );
}


export default VulnsWorkspace;
