"use client";

/**
 * Requester portal — "Report an issue".
 *
 * Friendly, jargon-free request form for normal employees (not the agent
 * console). Submits POST /helpdesk/portal/requests; the backend defaults the
 * ITIL process and derives priority, so we only collect subject + details + a
 * plain "how urgent" hint. On success we bounce to My Requests.
 */
import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { MessageSquareText, CheckCircle2 } from "lucide-react";
import { PageHeader } from "../../_ui";
import { Field, Input, Textarea, Select, Btn, FormError, hdCall } from "../../_admin";

const URGENCY = [
  { value: "low", label: "Whenever — it's not blocking me" },
  { value: "medium", label: "Soon — it's slowing me down" },
  { value: "high", label: "Urgent — I can't work until it's fixed" },
];

export default function ReportIssue() {
  const router = useRouter();
  const [subject, setSubject] = useState("");
  const [description, setDescription] = useState("");
  const [urgency, setUrgency] = useState("medium");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [doneId, setDoneId] = useState<string | null>(null);

  const submit = async () => {
    if (!subject.trim()) { setErr("Please give your issue a short title."); return; }
    setBusy(true); setErr(null);
    const r = await hdCall("post", "/helpdesk/portal/requests", {
      subject: subject.trim(),
      description: description.trim() || null,
      urgency,
    });
    setBusy(false);
    if (!r.ok || !r.data?.name) { setErr(r.error || "Sorry — we couldn't submit that. Please try again."); return; }
    setDoneId(String(r.data.name));
  };

  if (doneId) {
    return (
      <div className="mx-auto flex max-w-lg flex-col items-center gap-4 py-20 text-center">
        <div className="grid h-14 w-14 place-items-center rounded-full bg-emerald-50 text-emerald-600">
          <CheckCircle2 size={30} />
        </div>
        <h1 className="text-xl font-semibold text-[#0F172A]">Thanks — we've got it!</h1>
        <p className="text-sm text-[#64748B]">
          Your request <span className="font-mono font-semibold text-[#005B96]">#{doneId}</span> is with our team.
          You can follow its progress and reply from My Requests.
        </p>
        <div className="flex items-center gap-2">
          <Link href={`/helpdesk/portal/my-requests/${encodeURIComponent(doneId)}`}>
            <Btn variant="primary">View my request</Btn>
          </Link>
          <Btn variant="ghost" onClick={() => { setDoneId(null); setSubject(""); setDescription(""); setUrgency("medium"); }}>
            Report another
          </Btn>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto flex max-w-2xl flex-col gap-5 text-[#0F172A]">
      <PageHeader
        icon={MessageSquareText}
        title="Report an issue"
        subtitle="Tell us what's wrong and we'll get it sorted."
      />

      <div className="rounded-2xl border border-[#EEF1F5] bg-white p-5">
        <FormError msg={err} />
        <div className="flex flex-col gap-4">
          <Field label="What's the problem?" required hint="A short title, e.g. “Can't log in to email”.">
            <Input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Short summary" autoFocus />
          </Field>
          <Field label="Tell us more" hint="What happened, when it started, anything you've already tried.">
            <Textarea value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Describe the issue…" />
          </Field>
          <Field label="How urgent is this?">
            <Select value={urgency} onChange={(e) => setUrgency(e.target.value)}>
              {URGENCY.map((u) => <option key={u.value} value={u.value}>{u.label}</option>)}
            </Select>
          </Field>
          <div className="flex items-center justify-end gap-2 pt-1">
            <Link href="/helpdesk/portal/my-requests"><Btn variant="ghost">Cancel</Btn></Link>
            <Btn variant="primary" onClick={submit} busy={busy}>Submit request</Btn>
          </div>
        </div>
      </div>
    </div>
  );
}
