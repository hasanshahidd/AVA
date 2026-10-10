"use client";

import { useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Send, MessageSquare, StickyNote, CheckCircle2, XCircle, UserPlus, ShieldAlert } from "lucide-react";
import { apiClient } from "@/lib/api";
import { Avatar, Chip, PRIORITY_CHIP, ErrorBanner, Loading, PropRow, SlaBadge, TimelineItem, useHd } from "../../_ui";

const fmt = (v?: string | null) => (v && !isNaN(new Date(v).getTime()) ? new Date(v).toLocaleString() : "—");
const doneRe = /replied|resolved|closed/i;

export default function TicketDetail() {
  const params = useParams();
  const name = decodeURIComponent(String(params.name));
  const base = `/helpdesk/tickets/${encodeURIComponent(name)}`;
  const { data, loading, error, reload } = useHd<any>(base);
  const [tab, setTab] = useState<"reply" | "comment">("reply");
  const [draft, setDraft] = useState("");
  const [note, setNote] = useState<string | null>(null);

  const t = data?.ticket;
  const conv: any[] = data?.conversation || [];

  const act = async (path: string, body: any, ok: string) => {
    try { await apiClient.post(`${base}/${path}`, body); setNote(ok); reload(); return true; }
    catch { setNote("Action isn't available yet — the engine connector may be read-only."); return false; }
  };
  const send = async () => {
    if (!draft.trim()) return;
    const ok = await act("reply", { content: draft, body: draft, internal: tab === "comment" }, tab === "comment" ? "Note added." : "Reply sent.");
    if (ok) setDraft("");
  };

  if (loading) return <div className="p-6"><Loading what="ticket" /></div>;
  if (!t) return (
    <div className="space-y-4 p-6">
      <Link href="/helpdesk/tickets" className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700"><ArrowLeft size={15} /> Tickets</Link>
      {error ? <ErrorBanner msg={error} /> : <div className="mt-10 text-center text-slate-500">Ticket not found.</div>}
    </div>
  );

  const btn = "flex items-center gap-1.5 rounded-lg border px-3 py-1.5 text-sm";
  return (
    <div className="flex h-full flex-col">
      <div className="border-b border-slate-200 bg-white px-6 py-3">
        <Link href="/helpdesk/tickets" className="mb-2 inline-flex items-center gap-1.5 text-xs text-slate-400 hover:text-slate-600"><ArrowLeft size={13} /> Tickets</Link>
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="min-w-0">
            <div className="flex flex-wrap items-center gap-2">
              <span className="font-mono text-xs text-slate-400">#{t.name || name}</span>
              <Chip value={t.status} />
              <Chip value={t.priority} map={PRIORITY_CHIP} />
              {(t.severity || t.cve_id) && (
                <span className="inline-flex items-center gap-1 rounded-full bg-red-50 px-2 py-0.5 text-xs font-medium text-red-700">
                  <ShieldAlert size={12} />{[t.severity, t.cve_id].filter(Boolean).join(" · ")}
                </span>
              )}
            </div>
            <h1 className="mt-1 truncate text-lg font-semibold text-[var(--color-text)]">{t.subject || `Ticket ${name}`}</h1>
          </div>
          <div className="flex items-center gap-2">
            <button onClick={() => setTab("reply")} className={`${btn} border-slate-200 text-slate-600 hover:bg-slate-50`}><MessageSquare size={15} /> Reply</button>
            <button onClick={() => act("status", { status: "Resolved" }, "Ticket resolved.")} className={`${btn} border-emerald-200 bg-emerald-50 font-medium text-emerald-700 hover:bg-emerald-100`}><CheckCircle2 size={15} /> Resolve</button>
            <button onClick={() => act("status", { status: "Closed" }, "Ticket closed.")} className={`${btn} border-slate-200 text-slate-600 hover:bg-slate-50`}><XCircle size={15} /> Close</button>
            <button onClick={() => setNote("Reassign isn't available yet — use the Assignee field once editing is enabled.")} className={`${btn} border-slate-200 text-slate-600 hover:bg-slate-50`}><UserPlus size={15} /> Reassign</button>
          </div>
        </div>
        {note && <div className="mt-2 rounded-md bg-slate-50 px-3 py-1.5 text-xs text-slate-500">{note}</div>}
      </div>

      <div className="flex min-h-0 flex-1 overflow-hidden">
        <div className="flex min-w-0 flex-1 flex-col">
          <div className="flex-1 space-y-4 overflow-y-auto px-6 py-5">
            {t.description && (
              <TimelineItem m={{ type: "received", sender: t.contact || t.raised_by || t.customer || "Customer", content: t.description, date: t.created || t.creation }} />
            )}
            {conv.length === 0 && !t.description ? (
              <div className="py-8 text-center text-xs text-slate-300">No activity yet.</div>
            ) : conv.map((m, i) => <TimelineItem key={i} m={m} />)}
          </div>

          <div className="border-t border-slate-200 bg-white px-6 py-3">
            <div className="mb-2 flex items-center gap-1.5">
              <button onClick={() => setTab("reply")} className={`flex items-center gap-1.5 rounded-md px-2.5 py-1 text-sm ${tab === "reply" ? "bg-slate-100 text-slate-800" : "text-slate-500"}`}><MessageSquare size={14} /> Reply</button>
              <button onClick={() => setTab("comment")} className={`flex items-center gap-1.5 rounded-md px-2.5 py-1 text-sm ${tab === "comment" ? "bg-amber-100 text-amber-800" : "text-slate-500"}`}><StickyNote size={14} /> Internal note</button>
            </div>
            <textarea value={draft} onChange={(e) => setDraft(e.target.value)} rows={3}
              placeholder={tab === "reply" ? "Reply to the customer…" : "Add an internal note…"}
              className={`w-full resize-none rounded-lg border p-3 text-sm focus:border-[var(--color-base)] focus:outline-none ${tab === "comment" ? "border-amber-200 bg-amber-50/50" : "border-slate-200"}`} />
            <div className="mt-2 flex items-center justify-end">
              <button onClick={send} disabled={!draft.trim()} className="flex items-center gap-1.5 rounded-lg bg-[var(--color-base)] px-3.5 py-1.5 text-sm font-medium text-white disabled:opacity-40"><Send size={14} /> {tab === "reply" ? "Send" : "Add note"}</button>
            </div>
          </div>
        </div>

        <aside className="w-80 shrink-0 space-y-3 overflow-y-auto border-l border-slate-200 bg-white px-4 py-5">
          <h3 className="text-xs font-semibold uppercase tracking-wide text-slate-400">Properties</h3>
          <PropRow label="Status"><Chip value={t.status} /></PropRow>
          <PropRow label="Priority"><Chip value={t.priority} map={PRIORITY_CHIP} /></PropRow>
          <PropRow label="Ticket type">{t.ticket_type || <span className="text-slate-300">Unset</span>}</PropRow>
          <PropRow label="Team">{t.team || <span className="text-slate-300">Unassigned</span>}</PropRow>
          <PropRow label="Assignee">{t.agent ? <span className="inline-flex items-center gap-1.5"><Avatar name={t.agent} size={20} />{t.agent}</span> : <span className="text-slate-300">Unassigned</span>}</PropRow>
          <PropRow label="Customer">{t.customer || "—"}</PropRow>
          <PropRow label="Contact">{t.contact || t.raised_by || "—"}</PropRow>
          <div className="border-t border-slate-100 pt-1" />
          <PropRow label="First response by"><span className="mr-auto">{fmt(t.response_by)}</span><SlaBadge due={t.response_by} done={doneRe.test(t.status || "")} /></PropRow>
          <PropRow label="Resolution by"><span className="mr-auto">{fmt(t.resolution_by)}</span><SlaBadge due={t.resolution_by} done={/resolved|closed/i.test(t.status || "")} /></PropRow>
          <PropRow label="Created">{fmt(t.created || t.creation)}</PropRow>
          {(t.cve_id || t.finding_id) && (
            <PropRow label="Related finding">
              <Link
                href={t.finding_id ? `/vulnerabilities/${encodeURIComponent(String(t.finding_id))}` : `/vulnerabilities?q=${encodeURIComponent(String(t.cve_id))}`}
                className="text-primary-600 hover:underline"
              >
                {String(t.cve_id || `Finding #${t.finding_id}`)} →
              </Link>
            </PropRow>
          )}
        </aside>
      </div>
    </div>
  );
}
