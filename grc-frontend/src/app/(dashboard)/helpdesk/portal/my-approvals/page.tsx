"use client";

/**
 * Requester portal — "My Approvals".
 *
 * Items waiting on THIS user's sign-off (service-request approvals and CAB
 * votes). Approve / Reject with an optional comment.
 *
 * Backend (PLACEHOLDER — not in portal.py yet; scoped server-side to the
 * signed-in approver, never trusting a client-supplied identity):
 *   GET  /helpdesk/portal/my-approvals
 *        -> { approvals: [{ id, kind: "request"|"cab"|"ecab", ticket_name, subject,
 *                           requested_by?, opened_at?, required_quorum?, approve_count?,
 *                           description?, risk?, cost? }] }
 *   POST /helpdesk/portal/approvals/{id}/vote   body { decision: "approve"|"reject", comment? }
 *        -> updated approval (wraps approvals.cast_vote with approver = current user)
 */
import { useState } from "react";
import Link from "next/link";
import { ShieldCheck, Inbox, ThumbsUp, ThumbsDown, Clock, User } from "lucide-react";
import { Chip, ErrorBanner, Empty, Loading, PageHeader, RefreshBtn, timeAgo, useHd } from "../../_ui";
import { Btn, Modal, Field, Textarea, FormError, hdCall } from "../../_admin";

const KIND_LABEL: Record<string, string> = {
  request: "Service request",
  cab: "Change (CAB)",
  ecab: "Emergency change (ECAB)",
};

type Pending = { approval: any; decision: "approve" | "reject" };

export default function MyApprovals() {
  const { data, loading, error, reload } = useHd<{ approvals: any[] }>("/helpdesk/portal/my-approvals");
  const rows: any[] = Array.isArray(data?.approvals) ? data!.approvals : [];

  const [pending, setPending] = useState<Pending | null>(null);
  const [comment, setComment] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [notice, setNotice] = useState<string | null>(null);

  const open = (approval: any, decision: "approve" | "reject") => {
    setPending({ approval, decision }); setComment(""); setErr(null);
  };
  const close = () => { if (!busy) setPending(null); };

  const confirm = async () => {
    if (!pending) return;
    setBusy(true); setErr(null);
    const r = await hdCall("post", `/helpdesk/portal/approvals/${encodeURIComponent(String(pending.approval.id))}/vote`, {
      decision: pending.decision,
      comment: comment.trim() || null,
    });
    setBusy(false);
    if (!r.ok) { setErr(r.error || "Sorry — we couldn't record that. Please try again."); return; }
    setNotice(
      `${pending.decision === "approve" ? "Approved" : "Rejected"} “${pending.approval.subject || `#${pending.approval.ticket_name}`}”.`,
    );
    setPending(null);
    reload();
  };

  const isApprove = pending?.decision === "approve";

  return (
    <div className="mx-auto flex max-w-4xl flex-col gap-4 text-[#0F172A]">
      <PageHeader
        icon={ShieldCheck}
        title="My Approvals"
        subtitle="Requests and changes waiting for your decision."
        actions={<RefreshBtn onClick={reload} loading={loading} />}
      />

      {error && <ErrorBanner msg={error} />}
      {notice && (
        <div className="rounded-lg border border-emerald-200 bg-emerald-50 px-3 py-2 text-[12.5px] text-emerald-700">{notice}</div>
      )}

      {loading ? (
        <Loading what="your approvals" />
      ) : rows.length === 0 ? (
        <Empty icon={Inbox} title="Nothing waiting on you" hint="When someone needs your approval, it will show up here." />
      ) : (
        <div className="flex flex-col gap-3">
          {rows.map((a) => (
            <div key={a.id} className="rounded-xl border border-slate-200 bg-white p-4">
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-mono text-[11px] text-[#94A3B8]">#{a.ticket_name}</span>
                    <Chip value={KIND_LABEL[(a.kind || "").toLowerCase()] || a.kind || "Approval"} />
                  </div>
                  <Link
                    href={`/helpdesk/portal/my-requests/${encodeURIComponent(String(a.ticket_name))}`}
                    className="mt-1 block font-medium text-[#0F172A] hover:text-[#005B96]"
                  >
                    {a.subject || "(no subject)"}
                  </Link>
                  {a.description && (
                    <p className="mt-1 line-clamp-2 text-xs text-slate-500">{a.description}</p>
                  )}
                  <div className="mt-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-[11.5px] text-[#94A3B8]">
                    {a.requested_by && (
                      <span className="inline-flex items-center gap-1"><User size={12} /> {a.requested_by}</span>
                    )}
                    {a.opened_at && (
                      <span className="inline-flex items-center gap-1"><Clock size={12} /> {timeAgo(a.opened_at)}</span>
                    )}
                    {typeof a.required_quorum === "number" && a.required_quorum > 1 && (
                      <span>{a.approve_count || 0} of {a.required_quorum} approvals</span>
                    )}
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <Btn variant="danger" icon={<ThumbsDown size={14} />} onClick={() => open(a, "reject")}>Reject</Btn>
                  <Btn variant="primary" icon={<ThumbsUp size={14} />} onClick={() => open(a, "approve")}>Approve</Btn>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <Modal
        open={!!pending}
        onClose={close}
        title={isApprove ? "Approve this request?" : "Reject this request?"}
        subtitle={pending ? pending.approval.subject || `#${pending.approval.ticket_name}` : undefined}
        footer={
          <>
            <Btn variant="ghost" onClick={close} disabled={busy}>Cancel</Btn>
            <Btn variant={isApprove ? "primary" : "danger"} onClick={confirm} busy={busy}>
              {isApprove ? "Approve" : "Reject"}
            </Btn>
          </>
        }
      >
        <FormError msg={err} />
        <Field
          label="Comment"
          hint={isApprove ? "Optional — add a note for the requester." : "Optional — tell the requester why."}
        >
          <Textarea
            value={comment}
            onChange={(e) => setComment(e.target.value)}
            placeholder="Add a comment…"
            autoFocus
          />
        </Field>
      </Modal>
    </div>
  );
}
