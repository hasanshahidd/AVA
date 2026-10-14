"use client";

/**
 * Requester portal — request detail + reply.
 *
 * GET /helpdesk/portal/requests/{id} → { ticket, conversation } (server returns
 * 404 unless raised_by == current_user). Shows the conversation as replies only
 * (internal notes/activity are hidden from the requester) and lets them reply via
 * POST /helpdesk/portal/requests/{id}/reply.
 */
import { useMemo, useState } from "react";
import { useParams } from "next/navigation";
import Link from "next/link";
import { ArrowLeft, Send, MessageSquareText } from "lucide-react";
import { apiClient } from "@/lib/api";
import { Chip, ErrorBanner, Loading, SlaBadge, TimelineItem, useHd } from "../../../_ui";

const fmt = (v?: string | null) => (v && !isNaN(new Date(v).getTime()) ? new Date(v).toLocaleString() : "—");
const doneRe = /resolved|closed/i;

const FRIENDLY_STATUS: Record<string, string> = {
  open: "Received", new: "Received", replied: "Awaiting your reply",
  in_progress: "In progress", paused: "On hold", on_hold: "On hold",
  resolved: "Resolved", closed: "Closed", cancelled: "Cancelled",
};
const friendly = (s?: string | null) => FRIENDLY_STATUS[(s || "").toLowerCase().replace(/\s+/g, "_")] || s || "—";

export default function MyRequestDetail() {
  const params = useParams();
  const id = decodeURIComponent(String(params.id));
  const base = `/helpdesk/portal/requests/${encodeURIComponent(id)}`;
  const { data, loading, error, reload } = useHd<any>(base);
  const [draft, setDraft] = useState("");
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState<string | null>(null);

  const t = data?.ticket;
  const conv: any[] = data?.conversation || [];

  // Requesters only see replies (+ their own original message) — never internal notes/activity.
  const replies = useMemo(() => {
    const out: any[] = [];
    if (t?.description) out.push({ type: "received", sender: t.raised_by || t.contact || "You", content: t.description, date: t.created || t.creation });
    for (const m of conv) {
      if (/activity|comment|note/i.test(m.type || "")) continue;
      out.push(m);
    }
    return out;
  }, [conv, t]);

  const send = async () => {
    if (!draft.trim()) return;
    setBusy(true); setNote(null);
    try {
      await apiClient.post(`${base}/reply`, { content: draft, body: draft });
      setDraft(""); setNote("Your reply has been sent."); reload();
    } catch {
      setNote("Sorry — we couldn't send that reply. Please try again.");
    } finally { setBusy(false); }
  };

  if (loading) return <div className="p-6"><Loading what="your request" /></div>;
  if (!t) return (
    <div className="mx-auto max-w-3xl space-y-4 p-6">
      <Link href="/helpdesk/portal/my-requests" className="inline-flex items-center gap-1.5 text-sm text-slate-500 hover:text-slate-700"><ArrowLeft size={15} /> My Requests</Link>
      {error ? <ErrorBanner msg={error} /> : <div className="mt-10 text-center text-slate-500">We couldn't find that request.</div>}
    </div>
  );

  const done = doneRe.test(t.status || "");

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-4 text-[#0F172A]">
      <div>
        <Link href="/helpdesk/portal/my-requests" className="mb-2 inline-flex items-center gap-1.5 text-xs text-slate-400 hover:text-slate-600"><ArrowLeft size={13} /> My Requests</Link>
        <div className="flex flex-wrap items-center gap-2">
          <span className="font-mono text-xs text-slate-400">#{t.name || id}</span>
          <Chip value={friendly(t.status)} />
        </div>
        <h1 className="mt-1 text-xl font-semibold text-[#0F172A]">{t.subject || `Request ${id}`}</h1>
        {!done && t.response_by && (
          <p className="mt-1 flex items-center gap-1.5 text-sm text-[#64748B]">
            We'll respond by <SlaBadge due={t.response_by} /> <span className="text-slate-300">·</span> raised {fmt(t.created || t.creation)}
          </p>
        )}
      </div>

      {note && <div className="rounded-md bg-slate-50 px-3 py-1.5 text-xs text-slate-500">{note}</div>}

      <div className="space-y-4 rounded-2xl border border-[#EEF1F5] bg-white p-5">
        {replies.length === 0 ? (
          <div className="py-8 text-center text-xs text-slate-300">No messages yet.</div>
        ) : replies.map((m, i) => <TimelineItem key={i} m={m} />)}
      </div>

      {done ? (
        <div className="rounded-xl border border-dashed border-slate-300 bg-white px-4 py-4 text-center text-sm text-slate-500">
          This request is {friendly(t.status).toLowerCase()}. Need more help?{" "}
          <Link href="/helpdesk/portal/report" className="font-medium text-[#005B96] hover:underline">Report a new issue</Link>.
        </div>
      ) : (
        <div className="rounded-2xl border border-[#EEF1F5] bg-white p-4">
          <div className="mb-2 flex items-center gap-1.5 text-[12.5px] font-semibold text-[#475569]">
            <MessageSquareText size={14} /> Add a reply
          </div>
          <textarea
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            rows={4}
            placeholder="Type your reply to our team…"
            className="w-full resize-y rounded-[9px] border border-[#E2E5EC] bg-white p-3 text-[13px] text-[#0F172A] outline-none placeholder:text-[#94A3B8] focus:border-[#005B96] focus:ring-2 focus:ring-[#005B96]/15"
          />
          <div className="mt-2 flex items-center justify-end">
            <button onClick={send} disabled={busy || !draft.trim()} className="flex items-center gap-1.5 rounded-[9px] bg-[#005B96] px-3.5 py-1.5 text-sm font-medium text-white transition hover:bg-[#014A81] disabled:opacity-40">
              <Send size={14} /> Send reply
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
