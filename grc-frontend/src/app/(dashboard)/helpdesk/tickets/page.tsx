"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import { Ticket, Search, List, LayoutGrid, ArrowUpDown } from "lucide-react";
import { Avatar, Chip, PRIORITY_CHIP, STATUS_BAR, PageHeader, RefreshBtn, Empty, ErrorBanner, Loading, SlaBadge, timeAgo, useHd } from "../_ui";

const TABS = ["Open", "Replied", "Resolved", "Closed"];
const PRI: Record<string, number> = { urgent: 0, high: 1, medium: 2, low: 3 };
type SortKey = "created" | "priority" | "status";

export default function TicketsPage() {
  const [tab, setTab] = useState("all");
  const [q, setQ] = useState("");
  const [view, setView] = useState<"list" | "board">("list");
  const [sort, setSort] = useState<SortKey>("created");
  // Fetch unfiltered once; tabs/search filter client-side so summary counts stay stable.
  const { data, loading, error, reload } = useHd<any>("/helpdesk/tickets");
  const tickets: any[] = data?.tickets || [];
  const summary: Record<string, number> = data?.summary || {};
  const total = summary.total ?? summary.All ?? tickets.length;

  const rows = useMemo(() => {
    const s = q.toLowerCase();
    const f = tickets.filter((t) =>
      (tab === "all" || (t.status || "").toLowerCase() === tab.toLowerCase()) &&
      (!s || [t.name, t.subject, t.customer, t.contact, t.team, t.cve_id].some((v) => String(v || "").toLowerCase().includes(s))));
    return [...f].sort((a, b) =>
      sort === "priority" ? (PRI[(a.priority || "").toLowerCase()] ?? 9) - (PRI[(b.priority || "").toLowerCase()] ?? 9)
        : sort === "status" ? String(a.status).localeCompare(String(b.status))
        : new Date(b.created || 0).getTime() - new Date(a.created || 0).getTime());
  }, [tickets, tab, q, sort]);

  const tabCls = (on: boolean) => `border-b-2 px-3 py-2 text-sm ${on ? "border-[var(--color-base)] font-medium text-[var(--color-base)]" : "border-transparent text-slate-500 hover:text-slate-700"}`;
  const th = "px-3 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-slate-500";
  const tgl = (on: boolean) => `rounded-md p-1.5 ${on ? "bg-white text-[var(--color-base)] shadow-sm" : "text-slate-400"}`;

  return (
    <div className="space-y-4 p-6">
      <PageHeader icon={Ticket} title="Tickets" subtitle={`${total} support tickets`} actions={<RefreshBtn onClick={reload} loading={loading} />} />
      <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-200">
        <div className="flex items-center">
          <button onClick={() => setTab("all")} className={tabCls(tab === "all")}>All <span className="ml-1 text-xs text-slate-400">{total}</span></button>
          {TABS.map((s) => (
            <button key={s} onClick={() => setTab(s)} className={tabCls(tab === s)}>
              {s} <span className="ml-1 text-xs text-slate-400">{summary[s] ?? summary[s.toLowerCase()] ?? 0}</span>
            </button>
          ))}
        </div>
        <div className="flex items-center gap-2 pb-1.5">
          <div className="relative">
            <Search size={15} className="absolute left-2.5 top-1/2 -translate-y-1/2 text-slate-400" />
            <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search subject, customer, CVE…"
              className="w-64 rounded-lg border border-slate-200 py-1.5 pl-8 pr-3 text-sm focus:border-[var(--color-base)] focus:outline-none" />
          </div>
          <label className="flex items-center gap-1 rounded-lg border border-slate-200 px-2 py-1.5 text-xs text-slate-500">
            <ArrowUpDown size={13} />
            <select value={sort} onChange={(e) => setSort(e.target.value as SortKey)} className="bg-transparent text-slate-700 focus:outline-none">
              <option value="created">Newest</option><option value="priority">Priority</option><option value="status">Status</option>
            </select>
          </label>
          <div className="flex rounded-lg bg-slate-100 p-0.5">
            <button onClick={() => setView("list")} className={tgl(view === "list")} title="List"><List size={15} /></button>
            <button onClick={() => setView("board")} className={tgl(view === "board")} title="Board"><LayoutGrid size={15} /></button>
          </div>
        </div>
      </div>
      {error && <ErrorBanner msg={error} />}
      {loading ? <Loading what="tickets" /> : rows.length === 0 ? (
        <Empty icon={Ticket} title="No tickets here" hint="Tickets matching this filter will appear here." />
      ) : view === "list" ? (
        <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
          <table className="w-full text-sm">
            <thead className="border-b border-slate-200 bg-slate-50">
              <tr>{["Subject", "Status", "Priority", "Team", "Customer", "Created", "Response"].map((h) => <th key={h} className={th}>{h}</th>)}<th className={th} /></tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {rows.map((t) => (
                <tr key={t.name} className="hover:bg-slate-50">
                  <td className="max-w-[360px] px-3 py-2.5">
                    <Link href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`} className="block">
                      <span className="line-clamp-2 font-semibold text-slate-800 hover:text-[var(--color-base)]">{t.subject}</span>
                      <span className="font-mono text-[11px] text-slate-400">#{t.name}</span>
                    </Link>
                  </td>
                  <td className="px-3 py-2.5"><Chip value={t.status} /></td>
                  <td className="px-3 py-2.5"><Chip value={t.priority} map={PRIORITY_CHIP} /></td>
                  <td className="px-3 py-2.5 text-xs text-slate-500">{t.team || "—"}</td>
                  <td className="px-3 py-2.5">
                    <div className="flex items-center gap-2">
                      <Avatar name={t.contact || t.customer} size={22} />
                      <div className="min-w-0 text-xs"><div className="truncate text-slate-700">{t.customer || "—"}</div>{t.contact && <div className="truncate text-slate-400">{t.contact}</div>}</div>
                    </div>
                  </td>
                  <td className="whitespace-nowrap px-3 py-2.5 text-xs text-slate-400">{timeAgo(t.created)}</td>
                  <td className="whitespace-nowrap px-3 py-2.5"><SlaBadge due={t.response_by} done={/replied|resolved|closed/i.test(t.status || "")} /></td>
                  <td className="px-3 py-2.5 text-right">{t.cve_id && <span className="rounded bg-red-50 px-1.5 py-0.5 font-mono text-[11px] font-medium text-red-700">{t.cve_id}</span>}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      ) : (
        <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
          {TABS.map((col) => {
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
