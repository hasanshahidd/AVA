"use client";

// Personal agent landing — "Hey, {name}" + the current user's own queue.
// Everything is already tenant-scoped by the proxy; "mine" = tickets whose
// assignee email matches the logged-in user.
import { useMemo } from "react";
import Link from "next/link";
import { Home, Inbox, AlertTriangle, CheckCircle2, ArrowRight } from "lucide-react";
import { Chip, PRIORITY_CHIP, Empty, ErrorBanner, Loading, PageHeader, RefreshBtn, SlaBadge, timeAgo, useHd } from "../_ui";

const isOpen = (s?: string) => !/resolved|closed|cancelled/i.test(s || "");
function slaAtRisk(t: any, now: number): boolean {
  if (t.agreement_status === "Failed") return true;
  if (!isOpen(t.status)) return false;
  const soon = now + 24 * 3600 * 1000;
  return [t.response_by, t.resolution_by].some((d) => {
    const ms = d ? new Date(d).getTime() : NaN;
    return !isNaN(ms) && ms <= soon;
  });
}

export default function HelpDeskHome() {
  const now = Date.now();
  const { data: me } = useHd<any>("/auth/me");
  const { data, loading, error, reload } = useHd<any>("/helpdesk/tickets");

  const user = me?.user;
  const email = (user?.email || "").toLowerCase();
  const name = user?.display_name || user?.username || (email ? email.split("@")[0] : "there");

  const mine = useMemo(() => {
    const all: any[] = data?.tickets || [];
    return email ? all.filter((t) => String(t.agent || "").toLowerCase() === email) : [];
  }, [data, email]);

  const open = useMemo(() => mine.filter((t) => isOpen(t.status))
    .sort((a, b) => new Date(b.created || 0).getTime() - new Date(a.created || 0).getTime()), [mine]);
  const atRisk = useMemo(() => mine.filter((t) => slaAtRisk(t, now)).length, [mine, now]);
  const resolved = useMemo(() => mine.filter((t) => !isOpen(t.status)).length, [mine]);

  const stats = [
    { label: "My open tickets", value: open.length, icon: Inbox, cls: "text-blue-600 bg-blue-50" },
    { label: "SLA at risk", value: atRisk, icon: AlertTriangle, cls: "text-amber-600 bg-amber-50" },
    { label: "Resolved by me", value: resolved, icon: CheckCircle2, cls: "text-emerald-600 bg-emerald-50" },
  ];

  return (
    <div className="space-y-6 p-6">
      <PageHeader icon={Home} title={`Hey, ${name}`} subtitle="Your personal Help Desk queue"
        actions={<RefreshBtn onClick={reload} loading={loading} />} />
      {error && <ErrorBanner msg={error} />}

      {loading ? <Loading what="your work" /> : !email ? (
        <Empty icon={Home} title="Sign in to see your queue" hint="We couldn't identify the current user." />
      ) : mine.length === 0 ? (
        <Empty icon={Inbox} title="Nothing assigned to you yet"
          hint="Tickets assigned to you will show up here. Browse the full queue under Tickets." />
      ) : (
        <>
          <div className="grid gap-4 sm:grid-cols-3">
            {stats.map((s) => (
              <div key={s.label} className="flex items-center gap-4 rounded-xl border border-slate-200 bg-white p-5">
                <div className={`flex h-11 w-11 items-center justify-center rounded-xl ${s.cls}`}><s.icon size={22} /></div>
                <div>
                  <div className="text-2xl font-semibold text-[var(--color-text)]">{s.value}</div>
                  <div className="text-sm text-slate-500">{s.label}</div>
                </div>
              </div>
            ))}
          </div>

          <div>
            <div className="mb-2 flex items-center justify-between">
              <h2 className="text-sm font-semibold uppercase tracking-wide text-slate-500">My open tickets</h2>
              <Link href="/helpdesk/tickets" className="flex items-center gap-1 text-sm text-[var(--color-base)] hover:underline">All tickets <ArrowRight size={14} /></Link>
            </div>
            {open.length === 0 ? (
              <Empty icon={CheckCircle2} title="You're all caught up" hint="No open tickets assigned to you." />
            ) : (
              <div className="divide-y divide-slate-100 overflow-hidden rounded-xl border border-slate-200 bg-white">
                {open.map((t) => (
                  <Link key={t.name} href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`}
                    className="flex items-center gap-3 px-4 py-3 hover:bg-slate-50">
                    <span className="font-mono text-[11px] text-slate-400">#{t.name}</span>
                    <span className="min-w-0 flex-1 truncate font-medium text-slate-800">{t.subject}</span>
                    <Chip value={t.priority} map={PRIORITY_CHIP} />
                    <Chip value={t.status} />
                    <span className="hidden w-24 text-right sm:block"><SlaBadge due={t.response_by} done={/replied|resolved|closed/i.test(t.status || "")} /></span>
                    <span className="hidden w-16 text-right text-xs text-slate-400 md:block">{timeAgo(t.created)}</span>
                  </Link>
                ))}
              </div>
            )}
          </div>
        </>
      )}
    </div>
  );
}
