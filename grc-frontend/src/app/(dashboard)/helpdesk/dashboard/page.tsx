"use client";

import Link from "next/link";
import { useMemo } from "react";
import { LifeBuoy, Inbox, ShieldAlert, Layers, Clock, Timer, Gauge, Star } from "lucide-react";
import {
  PieChart, Pie, Cell, Tooltip, ResponsiveContainer, Legend,
  AreaChart, Area, XAxis, YAxis, CartesianGrid,
} from "recharts";
import { Chip, PRIORITY_CHIP, PageHeader, RefreshBtn, Table, Empty, timeAgo, useHd } from "../_ui";

const ACCENT = "#005B96";
const DONUT = ["#005B96", "#3279A3", "#06b6d4", "#8b5cf6", "#f97316", "#22c55e", "#eab308", "#ec4899", "#64748b"];
const PRIORITY_COLOR: Record<string, string> = { urgent: "#dc2626", high: "#f97316", medium: "#eab308", low: "#3b82f6" };

interface Analytics {
  total: number; sla_fulfilled_pct: number | null; avg_first_response_hours: number | null;
  avg_resolution_days: number | null; avg_feedback_rating: number | null; feedback_count: number;
  trend: { date: string; created: number; resolved: number }[];
  by_team: Record<string, number>; by_priority: Record<string, number>;
  by_type: Record<string, number>; by_status_category: Record<string, number>;
}

const fmtH = (h: number | null) => (h == null ? "—" : h < 1 ? `${Math.round(h * 60)}m` : h < 48 ? `${h.toFixed(1)}h` : `${(h / 24).toFixed(1)}d`);

function Donut({ title, data, colorFor }: { title: string; data: Record<string, number>; colorFor?: (name: string, i: number) => string }) {
  const entries = Object.entries(data || {}).filter(([, v]) => v > 0).sort((a, b) => b[1] - a[1]);
  const rows = entries.map(([name, value]) => ({ name, value }));
  const total = entries.reduce((a, [, v]) => a + v, 0);
  return (
    <div className="rounded-xl border border-slate-200 bg-white p-5">
      <h2 className="mb-3 text-sm font-semibold text-[var(--color-text)]">{title}</h2>
      {rows.length === 0 ? <p className="py-10 text-center text-sm text-slate-400">No data yet</p> : (
        <div className="flex items-center gap-4">
          <div className="h-40 w-40 shrink-0">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={rows} dataKey="value" nameKey="name" cx="50%" cy="50%" innerRadius={42} outerRadius={64} paddingAngle={2}>
                  {rows.map((r, i) => <Cell key={r.name} fill={colorFor ? colorFor(r.name, i) : DONUT[i % DONUT.length]} />)}
                </Pie>
                <Tooltip />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="min-w-0 flex-1 space-y-1.5">
            {rows.slice(0, 7).map((r, i) => (
              <div key={r.name} className="flex items-center gap-2 text-xs">
                <span className="h-2.5 w-2.5 shrink-0 rounded-full" style={{ background: colorFor ? colorFor(r.name, i) : DONUT[i % DONUT.length] }} />
                <span className="truncate capitalize text-slate-600">{r.name}</span>
                <span className="ml-auto text-slate-400">{r.value} ({total ? Math.round((r.value / total) * 100) : 0}%)</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export default function HelpDeskDashboard() {
  const { data: a, loading, error, reload } = useHd<Analytics>("/helpdesk/dashboard-analytics");
  const { data: base } = useHd<any>("/helpdesk/dashboard"); // recent tickets (existing)
  const recent: any[] = Array.isArray(base?.recent) ? base.recent : [];

  const kpis = useMemo(() => [
    { label: "Total tickets", v: a?.total ?? 0, sub: "", icon: Layers, c: "text-slate-600 bg-slate-100" },
    { label: "SLA fulfilled", v: a?.sla_fulfilled_pct == null ? "—" : `${a.sla_fulfilled_pct}%`, icon: Gauge, c: "text-blue-600 bg-blue-50" },
    { label: "Avg first response", v: fmtH(a?.avg_first_response_hours ?? null), icon: Clock, c: "text-indigo-600 bg-indigo-50" },
    { label: "Avg resolution", v: a?.avg_resolution_days == null ? "—" : `${a.avg_resolution_days}d`, icon: Timer, c: "text-amber-600 bg-amber-50" },
    { label: "Avg feedback", v: a?.avg_feedback_rating == null ? "—" : `${a.avg_feedback_rating}/5`, sub: a?.feedback_count ? `${a.feedback_count} rated` : "", icon: Star, c: "text-emerald-600 bg-emerald-50" },
  ], [a]);

  return (
    <div className="space-y-5 p-6">
      <PageHeader icon={LifeBuoy} title="Help Desk" subtitle="Agent desk overview"
        actions={<>
          <Link href="/helpdesk" className="flex items-center gap-2 rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50"><ShieldAlert size={15} /> Remediation board</Link>
          <RefreshBtn onClick={reload} loading={loading} />
        </>} />
      {error && <Empty icon={Inbox} title="Analytics unavailable" hint="The Help Desk data couldn't be loaded yet." />}

      <div className="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-5">
        {kpis.map((t) => (
          <div key={t.label} className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white p-4">
            <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${t.c}`}><t.icon size={20} /></div>
            <div className="min-w-0">
              <div className="truncate text-2xl font-semibold leading-none text-[var(--color-text)]">{t.v ?? 0}</div>
              <div className="mt-1 truncate text-xs text-slate-500">{t.label}{t.sub ? ` · ${t.sub}` : ""}</div>
            </div>
          </div>
        ))}
      </div>

      {/* 30-day ticket trend */}
      <div className="rounded-xl border border-slate-200 bg-white p-5">
        <h2 className="mb-3 text-sm font-semibold text-[var(--color-text)]">Ticket trend · last 30 days</h2>
        <div className="h-64">
          <ResponsiveContainer width="100%" height="100%">
            <AreaChart data={a?.trend || []} margin={{ top: 5, right: 10, left: -18, bottom: 0 }}>
              <defs>
                <linearGradient id="gCreated" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor={ACCENT} stopOpacity={0.3} /><stop offset="95%" stopColor={ACCENT} stopOpacity={0} /></linearGradient>
                <linearGradient id="gResolved" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor="#22c55e" stopOpacity={0.3} /><stop offset="95%" stopColor="#22c55e" stopOpacity={0} /></linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="date" tick={{ fontSize: 10, fill: "#94a3b8" }} tickFormatter={(d: string) => d.slice(5)} interval={4} />
              <YAxis tick={{ fontSize: 10, fill: "#94a3b8" }} allowDecimals={false} />
              <Tooltip />
              <Legend wrapperStyle={{ fontSize: 12 }} />
              <Area type="monotone" dataKey="created" name="Created" stroke={ACCENT} fill="url(#gCreated)" strokeWidth={2} />
              <Area type="monotone" dataKey="resolved" name="Resolved" stroke="#22c55e" fill="url(#gResolved)" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <Donut title="By priority" data={a?.by_priority || {}} colorFor={(n, i) => PRIORITY_COLOR[n.toLowerCase()] || DONUT[i % DONUT.length]} />
        <Donut title="By status" data={a?.by_status_category || {}} />
        <Donut title="By team" data={a?.by_team || {}} />
        <Donut title="By type" data={a?.by_type || {}} />
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
    </div>
  );
}
