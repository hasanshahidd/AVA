"use client";

import Link from "next/link";
import { LifeBuoy, Inbox, CheckCircle2, AlarmClock, UserX, ShieldAlert, Layers, BarChart3 } from "lucide-react";
import { Chip, PRIORITY_CHIP, PageHeader, RefreshBtn, Table, Empty, ErrorBanner, Loading, timeAgo, useHd } from "../_ui";

const STATUS_COLOR: Record<string, string> = {
  open: "bg-blue-500", replied: "bg-indigo-500", paused: "bg-amber-500", resolved: "bg-emerald-500", closed: "bg-slate-400",
};
const PRIORITY_COLOR: Record<string, string> = {
  urgent: "bg-red-500", high: "bg-orange-500", medium: "bg-amber-500", low: "bg-sky-500",
};
const k = (s: string) => s.toLowerCase().replace(/\s+/g, "_");

function BarPanel({ title, data, colors }: { title: string; data: Record<string, number>; colors: Record<string, string> }) {
  const entries = Object.entries(data || {}).sort((a, b) => b[1] - a[1]);
  const max = Math.max(1, ...entries.map(([, v]) => Number(v) || 0));
  const total = entries.reduce((a, [, v]) => a + (Number(v) || 0), 0);
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="flex items-center gap-2 text-sm font-semibold text-[var(--color-text)]"><BarChart3 size={16} className="text-slate-400" /> {title}</h2>
        <span className="text-xs text-slate-400">{total} total</span>
      </div>
      {entries.length === 0 ? <p className="py-6 text-center text-sm text-slate-400">No data yet</p> : (
        <div className="space-y-3">
          {entries.map(([name, v]) => {
            const n = Number(v) || 0;
            return (
              <div key={name}>
                <div className="mb-1 flex justify-between text-xs">
                  <span className="font-medium capitalize text-slate-600">{name}</span>
                  <span className="text-slate-500">{n} <span className="text-slate-300">({total ? Math.round((n / total) * 100) : 0}%)</span></span>
                </div>
                <div className="h-2.5 overflow-hidden rounded-full bg-slate-100">
                  <div className={`h-full rounded-full ${colors[k(name)] || "bg-slate-400"}`} style={{ width: `${(n / max) * 100}%` }} />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

export default function HelpDeskDashboard() {
  const { data, loading, error, reload } = useHd<any>("/helpdesk/dashboard");
  const d = data || {};
  const tiles = [
    { label: "Total", v: d.total, icon: Layers, c: "text-slate-600 bg-slate-100" },
    { label: "Open", v: d.open, icon: Inbox, c: "text-blue-600 bg-blue-50" },
    { label: "Resolved", v: d.resolved, icon: CheckCircle2, c: "text-emerald-600 bg-emerald-50" },
    { label: "Overdue", v: d.overdue, icon: AlarmClock, c: "text-rose-600 bg-rose-50" },
    { label: "Unassigned", v: d.unassigned, icon: UserX, c: "text-amber-600 bg-amber-50" },
  ];
  const recent: any[] = Array.isArray(d.recent) ? d.recent : [];

  return (
    <div className="space-y-5 p-6">
      <PageHeader icon={LifeBuoy} title="Help Desk" subtitle="Agent desk overview"
        actions={<>
          <Link href="/helpdesk" className="flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50">
            <ShieldAlert size={15} /> Remediation board
          </Link>
          <RefreshBtn onClick={reload} loading={loading} />
        </>} />
      {error && <ErrorBanner msg={error} />}
      {loading ? <Loading what="dashboard" /> : (
        <>
          <div className="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-5">
            {tiles.map((t) => (
              <div key={t.label} className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white p-4">
                <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${t.c}`}><t.icon size={20} /></div>
                <div>
                  <div className="text-2xl font-semibold leading-none text-[var(--color-text)]">{t.v ?? 0}</div>
                  <div className="mt-1 text-xs text-slate-500">{t.label}</div>
                </div>
              </div>
            ))}
          </div>
          <div className="grid gap-4 lg:grid-cols-2">
            <BarPanel title="Tickets by status" data={d.by_status || {}} colors={STATUS_COLOR} />
            <BarPanel title="Tickets by priority" data={d.by_priority || {}} colors={PRIORITY_COLOR} />
          </div>
          <div>
            <h2 className="mb-2 text-sm font-semibold text-[var(--color-text)]">Recent tickets</h2>
            {recent.length === 0 ? <Empty icon={Inbox} title="No tickets yet" hint="New tickets will appear here." /> : (
              <Table head={["Ticket", "Subject", "Status", "Priority", "Updated"]}>
                {recent.map((t) => (
                  <tr key={t.name} className="hover:bg-slate-50">
                    <td className="px-4 py-2.5 font-mono text-xs"><Link href={`/helpdesk/tickets/${t.name}`} className="text-[var(--color-base)] hover:underline">#{t.name}</Link></td>
                    <td className="px-4 py-2.5"><Link href={`/helpdesk/tickets/${t.name}`} className="font-medium text-[var(--color-text)] hover:underline">{t.subject || "(no subject)"}</Link></td>
                    <td className="px-4 py-2.5"><Chip value={t.status} /></td>
                    <td className="px-4 py-2.5"><Chip value={t.priority} map={PRIORITY_CHIP} /></td>
                    <td className="px-4 py-2.5 text-slate-500">{timeAgo(t.modified)}</td>
                  </tr>
                ))}
              </Table>
            )}
          </div>
        </>
      )}
    </div>
  );
}
