"use client";

/**
 * Help Desk — personal agent home, in AVA's Performance-dashboard language.
 * "Hey, {name}" + the signed-in agent's own queue and 30-day performance.
 * Everything is tenant-scoped by the proxy; "mine" = tickets whose assignee
 * email matches the logged-in user. Personal 30-day stats come from the native
 * dashboard-data number cards scoped to the user (agent=@me — a non-manager is
 * allowed to read their OWN agent data), so they carry period deltas too.
 */
import Link from "next/link";
import { useMemo } from "react";
import { AlertTriangle, CheckCircle2, Clock, Home, Inbox, Star, Timer, Users } from "lucide-react";
import { Card, Empty, Loading, T, nfmt } from "../../dashboard/_components/kit";
import { DeltaInfo, Kpi, fmtD, fmtH, slaBuckets } from "../_dash";
import { Chip, PRIORITY_CHIP, ErrorBanner, SlaBadge, timeAgo, useHd } from "../_ui";

const isOpen = (s?: string) => !/resolved|closed|cancelled/i.test(s || "");
type NumberCard = { title: string; value: number | null; suffix?: string; delta: number | null; deltaSuffix?: string; negativeIsBetter?: boolean; deltaCaption?: string };
const deltaOf = (c?: NumberCard): DeltaInfo | null =>
  c ? { delta: c.delta, suffix: c.deltaSuffix, negativeIsBetter: c.negativeIsBetter, caption: c.deltaCaption } : null;

export default function HelpDeskHome() {
  const me = useHd<any>("/auth/me");
  const { data, loading, error, reload } = useHd<any>("/helpdesk/tickets");
  const myStats = useHd<NumberCard[]>("/helpdesk/dashboard-data?type=number_card&agent=@me");

  const user = me.data?.user;
  const email = (user?.email || "").toLowerCase();
  const name = user?.display_name || user?.username || (email ? email.split("@")[0] : "there");

  const mine = useMemo(() => {
    const all: any[] = data?.tickets || [];
    return email ? all.filter((t) => String(t.agent || "").toLowerCase() === email) : [];
  }, [data, email]);

  const open = useMemo(() => mine.filter((t) => isOpen(t.status))
    .sort((a, b) => new Date(b.created || 0).getTime() - new Date(a.created || 0).getTime()), [mine]);
  const sla = useMemo(() => slaBuckets(mine), [mine]);
  const resolved = useMemo(() => mine.filter((t) => !isOpen(t.status)).length, [mine]);

  const liveTiles = [
    { icon: <Inbox size={15} />, label: "My open tickets", value: nfmt(open.length), sub: "assigned to you" },
    { icon: <AlertTriangle size={15} />, label: "SLA at risk", value: nfmt(sla.breached + sla.atRisk), sub: `${nfmt(sla.breached)} breached · ${nfmt(sla.atRisk)} due soon` },
    { icon: <CheckCircle2 size={15} />, label: "Resolved by you", value: nfmt(resolved), sub: "all time" },
  ];

  const nc = myStats.data || [];
  const perfTiles = [
    { icon: <Inbox size={15} />, label: "Tickets handled", value: nc[0] ? nfmt(nc[0].value ?? 0) : "—", delta: deltaOf(nc[0]) },
    { icon: <Clock size={15} />, label: "Avg first response", value: fmtH(nc[2]?.value ?? null), delta: deltaOf(nc[2]) },
    { icon: <Timer size={15} />, label: "Avg resolution", value: fmtD(nc[3]?.value ?? null), delta: deltaOf(nc[3]) },
    { icon: <Star size={15} />, label: "Avg feedback", value: nc[4]?.value == null ? "—" : `${nc[4].value}/5`, delta: deltaOf(nc[4]) },
  ];
  const hasPerf = nc.length > 0;

  return (
    <div className="mx-auto flex w-full max-w-[1600px] flex-col gap-4 text-[#0F172A]">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="grid h-10 w-10 place-items-center rounded-[12px]" style={{ background: "rgba(0,91,150,.10)", color: T.base }}><Home size={22} strokeWidth={1.75} /></div>
          <div>
            <h1 className="m-0 text-[20px] font-semibold leading-tight text-[#0F172A]">Hey, {name}</h1>
            <p className="m-0 text-[12.5px] text-[#64748B]">Your personal Help Desk queue</p>
          </div>
        </div>
        <Link href="/helpdesk/dashboard" className="inline-flex h-8 items-center gap-1.5 rounded-[9px] border border-[#E2E5EC] bg-white px-3 text-[12px] font-semibold text-[#334155] hover:bg-[#F6F7FB]"><Users size={14} /> Team dashboard</Link>
      </div>
      {error && <ErrorBanner msg={error} />}

      {loading ? <Card title="Your work"><Loading rows={5} note="Loading your queue…" /></Card>
        : !email ? <Card title="Your work"><Empty icon={<Home size={16} />} title="Sign in to see your queue" body="We couldn't identify the current user." /></Card>
        : mine.length === 0 ? (
          <Card title="Your work"><Empty icon={<Inbox size={16} />} title="Nothing assigned to you yet" body="Tickets assigned to you show up here. Browse the full queue under Tickets." href="/helpdesk/tickets" cta="Open all tickets" /></Card>
        ) : (
          <>
            {/* Live queue snapshot */}
            <div className="grid grid-cols-1 gap-2.5 sm:grid-cols-3">
              {liveTiles.map((t) => <Kpi key={t.label} icon={t.icon} label={t.label} value={t.value} sub={t.sub} href="/helpdesk/tickets" />)}
            </div>

            {/* Personal 30-day performance (self-scoped number cards, with deltas) */}
            {hasPerf && (
              <div>
                <p className="mb-2 text-[10.5px] font-semibold uppercase tracking-[.07em] text-[#64748B]">Your last 30 days</p>
                <div className="grid grid-cols-2 gap-2.5 md:grid-cols-4">
                  {perfTiles.map((t) => <Kpi key={t.label} icon={t.icon} label={t.label} value={t.value} delta={t.delta} />)}
                </div>
              </div>
            )}

            {/* Open queue */}
            <Card title="My open tickets" sub={`${nfmt(open.length)} open`} href="/helpdesk/tickets" cta="All tickets">
              {open.length === 0 ? (
                <Empty icon={<CheckCircle2 size={16} />} title="You're all caught up" body="No open tickets assigned to you." compact />
              ) : (
                <ul className="m-0 flex list-none flex-col divide-y divide-[#F1F3F7] p-0">
                  {open.map((t) => (
                    <li key={t.name}>
                      <Link href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`} className="flex items-center gap-3 px-1 py-2.5 hover:bg-[#F6F7FB]">
                        <span className="font-mono text-[11px] text-[#94A3B8]">#{t.name}</span>
                        <span className="min-w-0 flex-1 truncate text-[13px] font-medium text-[#0F172A]">{t.subject || "(no subject)"}</span>
                        <Chip value={t.priority} map={PRIORITY_CHIP} />
                        <Chip value={t.status} />
                        <span className="hidden w-24 text-right sm:block"><SlaBadge due={t.response_by} done={/replied|resolved|closed/i.test(t.status || "")} /></span>
                        <span className="hidden w-16 shrink-0 text-right text-[11px] text-[#94A3B8] md:block">{timeAgo(t.created)}</span>
                      </Link>
                    </li>
                  ))}
                </ul>
              )}
            </Card>
          </>
        )}
    </div>
  );
}
