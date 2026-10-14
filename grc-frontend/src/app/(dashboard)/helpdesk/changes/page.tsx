"use client";

/**
 * Help Desk — Changes (process === 'change').
 * Tickets list columns + the approval_state badge, change_type, planned window,
 * and a per-row action menu driving the §5 approval transitions. The row subject
 * links to the shared ticket detail. Read GET /helpdesk/changes.
 */
import Link from "next/link";
import { useMemo, useState } from "react";
import { GitPullRequest, Inbox, Search } from "lucide-react";
import { Chip, PRIORITY_CHIP, ErrorBanner, Empty, Loading, PageHeader, SlaBadge, Table, timeAgo, useHd } from "../_ui";
import { ApprovalBadge, ChangeActions } from "./_actions";

const fmt = (v?: string | null) => {
  if (!v) return null;
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? null : d.toLocaleString(undefined, { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });
};
function PlannedWindow({ start, end }: { start?: string | null; end?: string | null }) {
  const s = fmt(start), e = fmt(end);
  if (!s && !e) return <span className="text-[#CBD5E1]">—</span>;
  return <span className="text-[12px] text-[#475569]">{s || "?"} → {e || "?"}</span>;
}

export default function HelpDeskChanges() {
  const { data, loading, error, reload } = useHd<{ tickets: any[] }>("/helpdesk/changes");
  const [q, setQ] = useState("");

  const tickets = data?.tickets || [];
  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return tickets;
    return tickets.filter(
      (t) => String(t.subject || "").toLowerCase().includes(needle) || String(t.name || "").includes(needle),
    );
  }, [tickets, q]);

  return (
    <div className="flex flex-col gap-4 text-[#0F172A]">
      <PageHeader icon={GitPullRequest} title="Changes" subtitle="Planned changes moving through the approval workflow" />

      {error && <ErrorBanner msg={error} />}

      <div className="relative max-w-sm">
        <Search size={15} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search subject or #id…"
          className="w-full rounded-[9px] border border-[#E2E5EC] bg-white py-2 pl-9 pr-3 text-[13px] outline-none focus:border-[#005B96] focus:ring-2 focus:ring-[#005B96]/15"
        />
      </div>

      {loading ? (
        <Loading what="changes" />
      ) : filtered.length === 0 ? (
        <Empty
          icon={Inbox}
          title={q ? "No changes match your search" : "No changes yet"}
          hint={q ? "Try a different term." : "Raise a change request from the New-ticket flow."}
        />
      ) : (
        <Table head={["#", "Subject", "Approval", "Type", "Planned window", "Priority", "SLA", "Created", ""]}>
          {filtered.map((t) => (
            <tr key={t.name} className="hover:bg-[#F9FAFC]">
              <td className="px-4 py-2.5 font-mono text-[11px] text-[#94A3B8]">
                <Link href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`} className="hover:text-[#005B96]">#{t.name}</Link>
              </td>
              <td className="px-4 py-2.5">
                <Link href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`} className="font-medium text-[#0F172A] hover:text-[#005B96]">
                  {t.subject || "(no subject)"}
                </Link>
              </td>
              <td className="px-4 py-2.5"><ApprovalBadge state={t.approval_state} /></td>
              <td className="px-4 py-2.5 text-[12.5px] capitalize text-[#475569]">{t.change_type || "—"}</td>
              <td className="px-4 py-2.5"><PlannedWindow start={t.planned_start} end={t.planned_end} /></td>
              <td className="px-4 py-2.5"><Chip value={t.priority} map={PRIORITY_CHIP} /></td>
              <td className="px-4 py-2.5"><SlaBadge due={t.response_by} done={/resolved|closed/i.test(t.status || "")} /></td>
              <td className="px-4 py-2.5 text-[11.5px] text-[#94A3B8]">{timeAgo(t.created)}</td>
              <td className="px-4 py-2.5 text-right"><ChangeActions change={t} onChanged={reload} /></td>
            </tr>
          ))}
        </Table>
      )}
    </div>
  );
}
