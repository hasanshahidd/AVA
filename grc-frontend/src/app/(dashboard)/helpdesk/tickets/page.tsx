"use client";

import { useEffect, useMemo, useState } from "react";
import Link from "next/link";
import { Ticket, Search, List, LayoutGrid, ArrowUpDown, SlidersHorizontal, Columns3, CheckCircle2, UserPlus, X } from "lucide-react";
import { apiClient } from "@/lib/api";
import { Avatar, Chip, PRIORITY_CHIP, STATUS_BAR, PageHeader, RefreshBtn, Empty, ErrorBanner, Loading, SlaBadge, timeAgo, useHd } from "../_ui";

const BOARD_COLS = ["Open", "Replied", "Resolved", "Closed"];
const PRI: Record<string, number> = { urgent: 0, high: 1, medium: 2, low: 3 };
type SortKey = "created" | "priority" | "sla" | "status";
type GroupKey = "none" | "status" | "priority" | "team";
type SavedView = "all" | "pending" | "assigned" | "sla" | "feedback";

// ── saved / public views: each is a preset filter over the loaded rows ──
const parseDue = (v?: string | null) => (v ? new Date(v).getTime() : NaN);
function slaAtRisk(t: any, now: number): boolean {
  if (t.agreement_status === "Failed") return true;
  const done = /resolved|closed/i.test(t.status || "");
  if (done) return false;
  const soon = now + 24 * 3600 * 1000;
  return [t.response_by, t.resolution_by].some((d) => {
    const ms = parseDue(d);
    return !isNaN(ms) && ms <= soon; // in the past OR within 24h
  });
}
function applyView(rows: any[], view: SavedView, now: number): any[] {
  switch (view) {
    case "pending": return rows.filter((t) => ["open", "replied"].includes((t.status || "").toLowerCase()));
    case "assigned": return [...rows.filter((t) => t.agent)]
      .sort((a, b) => new Date(b.modified || b.created || 0).getTime() - new Date(a.modified || a.created || 0).getTime())
      .slice(0, 25);
    case "sla": return rows.filter((t) => slaAtRisk(t, now));
    case "feedback": return rows.filter((t) => Number(t.feedback_rating) > 0);
    default: return rows;
  }
}

// ── configurable columns (persisted per-browser) ──
const ALL_COLS = [
  { key: "id", label: "ID" }, { key: "subject", label: "Subject" }, { key: "status", label: "Status" },
  { key: "priority", label: "Priority" }, { key: "team", label: "Team" }, { key: "assignee", label: "Assignee" },
  { key: "customer", label: "Customer" }, { key: "sla", label: "SLA due" }, { key: "created", label: "Created" },
  { key: "cve", label: "CVE" },
] as const;
const DEFAULT_COLS = ["id", "subject", "status", "priority", "team", "assignee", "sla", "created"];
const COLS_LS = "hd.tickets.cols";

export default function TicketsPage() {
  const now = Date.now();
  const [savedView, setSavedView] = useState<SavedView>("all");
  const [q, setQ] = useState("");
  const [view, setView] = useState<"list" | "board">("list");
  const [sort, setSort] = useState<SortKey>("created");
  const [dir, setDir] = useState<"asc" | "desc">("desc");
  const [group, setGroup] = useState<GroupKey>("none");
  const [showFilters, setShowFilters] = useState(false);
  const [showCols, setShowCols] = useState(false);
  const [fStatus, setFStatus] = useState(""); const [fPriority, setFPriority] = useState("");
  const [fTeam, setFTeam] = useState(""); const [fAgent, setFAgent] = useState("");
  const [cols, setCols] = useState<string[]>(DEFAULT_COLS);
  const [sel, setSel] = useState<Set<string>>(new Set());
  const [bulk, setBulk] = useState<string | null>(null);

  const { data, loading, error, reload } = useHd<any>("/helpdesk/tickets");
  const { data: agentsData } = useHd<any>("/helpdesk/agents");
  const tickets: any[] = data?.tickets || [];
  const agents: any[] = agentsData?.agents || [];

  useEffect(() => {
    try { const s = localStorage.getItem(COLS_LS); if (s) setCols(JSON.parse(s)); } catch { /* ignore */ }
  }, []);
  const toggleCol = (key: string) => setCols((c) => {
    const next = c.includes(key) ? c.filter((k) => k !== key) : [...c, key];
    try { localStorage.setItem(COLS_LS, JSON.stringify(next)); } catch { /* ignore */ }
    return next;
  });
  const show = (key: string) => cols.includes(key);

  // distinct filter options from loaded rows
  const opts = useMemo(() => {
    const u = (f: (t: any) => any) => Array.from(new Set(tickets.map(f).filter(Boolean))).sort();
    return { status: u((t) => t.status), priority: u((t) => t.priority), team: u((t) => t.team), agent: u((t) => t.agent) };
  }, [tickets]);

  // view counts (over the full set)
  const counts = useMemo(() => ({
    all: tickets.length,
    pending: applyView(tickets, "pending", now).length,
    assigned: applyView(tickets, "assigned", now).length,
    sla: applyView(tickets, "sla", now).length,
    feedback: applyView(tickets, "feedback", now).length,
  }), [tickets, now]);

  const rows = useMemo(() => {
    let r = applyView(tickets, savedView, now);
    const s = q.toLowerCase();
    r = r.filter((t) =>
      (!s || [t.name, t.subject, t.customer, t.contact, t.team, t.agent, t.cve_id].some((v) => String(v || "").toLowerCase().includes(s))) &&
      (!fStatus || t.status === fStatus) && (!fPriority || t.priority === fPriority) &&
      (!fTeam || t.team === fTeam) && (!fAgent || t.agent === fAgent));
    if (savedView === "assigned") return r; // preset owns its ordering
    const mul = dir === "asc" ? 1 : -1;
    const cmp = (a: any, b: any) =>
      sort === "priority" ? (PRI[(a.priority || "").toLowerCase()] ?? 9) - (PRI[(b.priority || "").toLowerCase()] ?? 9)
        : sort === "status" ? String(a.status).localeCompare(String(b.status))
        : sort === "sla" ? ((parseDue(a.response_by) || Infinity) - (parseDue(b.response_by) || Infinity))
        : new Date(a.created || 0).getTime() - new Date(b.created || 0).getTime();
    return [...r].sort((a, b) => cmp(a, b) * mul);
  }, [tickets, savedView, q, fStatus, fPriority, fTeam, fAgent, sort, dir, now]);

  // group rows for grouped rendering
  const groups = useMemo(() => {
    if (group === "none") return [["", rows]] as [string, any[]][];
    const m = new Map<string, any[]>();
    for (const t of rows) {
      const g = String((group === "team" ? t.team : t[group]) || "—");
      (m.get(g) || m.set(g, []).get(g)!).push(t);
    }
    return Array.from(m.entries());
  }, [rows, group]);

  // bulk actions
  const toggleSel = (name: string) => setSel((s) => { const n = new Set(s); n.has(name) ? n.delete(name) : n.add(name); return n; });
  const allSelected = rows.length > 0 && rows.every((t) => sel.has(t.name));
  const selectAll = () => setSel(allSelected ? new Set() : new Set(rows.map((t) => t.name)));
  const runBulk = async (fn: (name: string) => Promise<any>, verb: string) => {
    const names = Array.from(sel); if (!names.length) return;
    setBulk(`${verb} ${names.length} ticket(s)…`);
    let ok = 0;
    for (const n of names) { try { await fn(n); ok++; } catch { /* skip */ } }
    setBulk(`${verb} ${ok}/${names.length} done.`); setSel(new Set()); reload();
    setTimeout(() => setBulk(null), 4000);
  };
  const bulkResolve = () => runBulk((n) => apiClient.post(`/helpdesk/tickets/${encodeURIComponent(n)}/status`, { status: "Resolved" }), "Resolved");
  const bulkAssign = (agent: string) => { if (agent) runBulk((n) => apiClient.post(`/helpdesk/tickets/${encodeURIComponent(n)}/assign`, { agent }), "Assigned"); };

  const pill = (v: SavedView, label: string, c: number) => (
    <button key={v} onClick={() => { setSavedView(v); setSel(new Set()); }}
      className={`rounded-full px-3 py-1 text-sm ${savedView === v ? "bg-[var(--color-base)] text-white" : "bg-slate-100 text-slate-600 hover:bg-slate-200"}`}>
      {label} <span className={savedView === v ? "text-white/80" : "text-slate-400"}>{c}</span>
    </button>
  );
  const th = "px-3 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-slate-500";
  const tgl = (on: boolean) => `rounded-md p-1.5 ${on ? "bg-white text-[var(--color-base)] shadow-sm" : "text-slate-400"}`;
  const ctrl = "flex items-center gap-1 rounded-lg border border-slate-200 px-2 py-1.5 text-xs text-slate-500";

  const Row = ({ t }: { t: any }) => (
    <tr className="hover:bg-slate-50">
      <td className="w-8 px-3 py-2.5"><input type="checkbox" checked={sel.has(t.name)} onChange={() => toggleSel(t.name)} /></td>
      {show("id") && <td className="whitespace-nowrap px-3 py-2.5 font-mono text-[11px] text-slate-400">#{t.name}</td>}
      {show("subject") && <td className="max-w-[360px] px-3 py-2.5"><Link href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`} className="line-clamp-2 font-semibold text-slate-800 hover:text-[var(--color-base)]">{t.subject}</Link></td>}
      {show("status") && <td className="px-3 py-2.5"><Chip value={t.status} /></td>}
      {show("priority") && <td className="px-3 py-2.5"><Chip value={t.priority} map={PRIORITY_CHIP} /></td>}
      {show("team") && <td className="px-3 py-2.5 text-xs text-slate-500">{t.team || "—"}</td>}
      {show("assignee") && <td className="px-3 py-2.5">{t.agent ? <span className="flex items-center gap-1.5 text-xs text-slate-600"><Avatar name={t.agent} size={20} />{t.agent}</span> : <span className="text-xs text-slate-300">Unassigned</span>}</td>}
      {show("customer") && <td className="px-3 py-2.5 text-xs text-slate-500">{t.customer || "—"}</td>}
      {show("sla") && <td className="whitespace-nowrap px-3 py-2.5"><SlaBadge due={t.response_by} done={/replied|resolved|closed/i.test(t.status || "")} /></td>}
      {show("created") && <td className="whitespace-nowrap px-3 py-2.5 text-xs text-slate-400">{timeAgo(t.created)}</td>}
      {show("cve") && <td className="px-3 py-2.5">{t.cve_id && <span className="rounded bg-red-50 px-1.5 py-0.5 font-mono text-[11px] font-medium text-red-700">{t.cve_id}</span>}</td>}
    </tr>
  );

  return (
    <div className="space-y-4 p-6">
      <PageHeader icon={Ticket} title="Tickets" subtitle={`${counts.all} support tickets`} actions={<RefreshBtn onClick={reload} loading={loading} />} />

      {/* Feature 1 — saved / public views */}
      <div className="flex flex-wrap items-center gap-2">
        {pill("all", "All", counts.all)}
        {pill("pending", "Pending", counts.pending)}
        {pill("assigned", "Recently assigned", counts.assigned)}
        {pill("sla", "SLA at risk", counts.sla)}
        {pill("feedback", "With feedback", counts.feedback)}
      </div>

      {/* Feature 2 — queue controls */}
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <div className="relative">
            <Search size={15} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search subject, customer, CVE…"
              className="w-56 rounded-lg border border-slate-200 py-1.5 pl-8 pr-3 text-sm focus:border-[var(--color-base)] focus:outline-none" />
          </div>
          <button onClick={() => setShowFilters((v) => !v)} className={`${ctrl} ${showFilters ? "border-[var(--color-base)] text-[var(--color-base)]" : ""}`}><SlidersHorizontal size={13} /> Filter</button>
          <label className={ctrl}><ArrowUpDown size={13} />
            <select value={sort} onChange={(e) => setSort(e.target.value as SortKey)} className="bg-transparent text-slate-700 focus:outline-none">
              <option value="created">Created</option><option value="priority">Priority</option><option value="sla">SLA due</option><option value="status">Status</option>
            </select>
            <button onClick={() => setDir((d) => (d === "asc" ? "desc" : "asc"))} className="font-semibold text-slate-600">{dir === "asc" ? "↑" : "↓"}</button>
          </label>
          <label className={ctrl}>Group
            <select value={group} onChange={(e) => setGroup(e.target.value as GroupKey)} className="bg-transparent text-slate-700 focus:outline-none">
              <option value="none">None</option><option value="status">Status</option><option value="priority">Priority</option><option value="team">Team</option>
            </select>
          </label>
          <div className="relative">
            <button onClick={() => setShowCols((v) => !v)} className={ctrl}><Columns3 size={13} /> Columns</button>
            {showCols && (
              <div className="absolute left-0 top-9 z-20 w-44 rounded-xl border border-slate-200 bg-white p-2 shadow-lg">
                {ALL_COLS.map((c) => (
                  <label key={c.key} className="flex items-center gap-2 rounded px-2 py-1 text-sm text-slate-600 hover:bg-slate-50">
                    <input type="checkbox" checked={show(c.key)} onChange={() => toggleCol(c.key)} disabled={c.key === "subject"} /> {c.label}
                  </label>
                ))}
              </div>
            )}
          </div>
        </div>
        <div className="flex rounded-lg bg-slate-100 p-0.5">
          <button onClick={() => setView("list")} className={tgl(view === "list")} title="List"><List size={15} /></button>
          <button onClick={() => setView("board")} className={tgl(view === "board")} title="Board"><LayoutGrid size={15} /></button>
        </div>
      </div>

      {showFilters && (
        <div className="flex flex-wrap items-center gap-3 rounded-xl border border-slate-200 bg-slate-50 p-3 text-sm">
          {([["Status", fStatus, setFStatus, opts.status], ["Priority", fPriority, setFPriority, opts.priority],
            ["Team", fTeam, setFTeam, opts.team], ["Assignee", fAgent, setFAgent, opts.agent]] as const).map(([label, val, set, o]) => (
            <label key={label} className="flex items-center gap-1.5 text-xs text-slate-500">{label}
              <select value={val} onChange={(e) => (set as any)(e.target.value)} className="rounded-md border border-slate-200 bg-white px-2 py-1 text-slate-700">
                <option value="">All</option>{(o as string[]).map((v) => <option key={v} value={v}>{v}</option>)}
              </select>
            </label>
          ))}
          {(fStatus || fPriority || fTeam || fAgent) && (
            <button onClick={() => { setFStatus(""); setFPriority(""); setFTeam(""); setFAgent(""); }} className="flex items-center gap-1 text-xs text-slate-400 hover:text-slate-600"><X size={12} /> Clear</button>
          )}
        </div>
      )}

      {/* bulk action bar */}
      {sel.size > 0 && view === "list" && (
        <div className="flex flex-wrap items-center gap-3 rounded-xl border border-[var(--color-base)]/30 bg-[var(--color-base)]/5 px-4 py-2.5 text-sm">
          <span className="font-medium text-[var(--color-base)]">{sel.size} selected</span>
          <button onClick={bulkResolve} className="flex items-center gap-1.5 rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-1.5 text-emerald-700 hover:bg-emerald-100"><CheckCircle2 size={14} /> Resolve</button>
          <label className="flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-slate-600"><UserPlus size={14} />
            <select defaultValue="" onChange={(e) => { bulkAssign(e.target.value); e.target.value = ""; }} className="bg-transparent focus:outline-none">
              <option value="">Assign to…</option>
              {agents.map((a) => <option key={a.name} value={a.email || a.name}>{a.agent_name || a.email}</option>)}
            </select>
          </label>
          <button onClick={() => setSel(new Set())} className="ml-auto flex items-center gap-1 text-xs text-slate-400 hover:text-slate-600"><X size={12} /> Clear</button>
        </div>
      )}
      {bulk && <div className="rounded-lg bg-slate-800 px-4 py-2 text-sm text-white">{bulk}</div>}

      {error && <ErrorBanner msg={error} />}
      {loading ? <Loading what="tickets" /> : rows.length === 0 ? (
        <Empty icon={Ticket} title="No tickets here" hint="Tickets matching this view will appear here." />
      ) : view === "list" ? (
        <div className="space-y-4">
          {groups.map(([g, gr]) => (
            <div key={g || "_"} className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
              {g && <div className="flex items-center gap-2 border-b border-slate-200 bg-slate-50 px-3 py-2 text-xs font-semibold text-slate-600">{g}<span className="text-slate-400">{gr.length}</span></div>}
              <table className="w-full text-sm">
                <thead className="border-b border-slate-200 bg-slate-50">
                  <tr>
                    <th className="w-8 px-3 py-2"><input type="checkbox" checked={allSelected} onChange={selectAll} /></th>
                    {ALL_COLS.filter((c) => show(c.key)).map((c) => <th key={c.key} className={th}>{c.label}</th>)}
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">{gr.map((t) => <Row key={t.name} t={t} />)}</tbody>
              </table>
            </div>
          ))}
        </div>
      ) : (
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          {BOARD_COLS.map((col) => {
            const items = rows.filter((t) => (t.status || "").toLowerCase() === col.toLowerCase());
            return (
              <div key={col} className="rounded-xl bg-slate-50 p-2">
                <div className="mb-2 flex items-center gap-2 px-1 text-xs font-semibold text-slate-600">
                  <span className={`h-2 w-2 rounded-full ${STATUS_BAR[col.toLowerCase()]}`} />{col}<span className="text-slate-400">{items.length}</span>
                </div>
                <div className="space-y-2">
                  {items.map((t) => (
                    <Link key={t.name} href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`} className="block rounded-lg border border-slate-200 bg-white p-2.5 hover:shadow-sm">
                      <div className="line-clamp-2 text-sm font-medium text-slate-800">{t.subject}</div>
                      <div className="mt-2 flex items-center justify-between"><Chip value={t.priority} map={PRIORITY_CHIP} /><span className="text-[11px] text-slate-400">{timeAgo(t.created)}</span></div>
                    </Link>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
