"use client";

// Tenant-SAFE Help Desk settings. Only Saved Replies are editable (they carry
// the tenant partition). SLA / business hours / auto-assignment are GLOBAL
// engine config — shown read-only ("Managed by your administrator"), never
// editable from a tenant UI (editing would mutate shared state).
import { useState } from "react";
import Link from "next/link";
import { Settings, Plus, Pencil, Trash2, MessageSquareText, Clock, Users, UsersRound, ShieldCheck, Lock, X } from "lucide-react";
import { apiClient } from "@/lib/api";
import { RichComposer, isEmptyHtml } from "../RichText";
import { Avatar, ErrorBanner, Loading, PageHeader, RefreshBtn, useHd } from "../_ui";

const strip = (h: string) => h.replace(/<[^>]*>/g, " ").replace(/\s+/g, " ").trim();

export default function HelpDeskSettings() {
  const { data, loading, error, reload } = useHd<any>("/helpdesk/saved-replies");
  const { data: cfg, loading: cfgLoading } = useHd<any>("/helpdesk/config");
  const [edit, setEdit] = useState<null | { name?: string; title: string; message: string }>(null);
  const [busy, setBusy] = useState(false);
  const [composerKey, setComposerKey] = useState(0);
  const [msg, setMsg] = useState<string | null>(null);

  const replies: any[] = data?.saved_replies || [];
  const sla = cfg?.sla || {};

  const openNew = () => { setEdit({ title: "", message: "" }); setComposerKey((k) => k + 1); };
  const openEdit = (r: any) => { setEdit({ name: r.name, title: r.title, message: r.message || "" }); setComposerKey((k) => k + 1); };

  const save = async () => {
    if (!edit || !edit.title.trim()) return;
    setBusy(true);
    try {
      const body = { title: edit.title.trim(), message: edit.message };
      if (edit.name) await apiClient.put(`/helpdesk/saved-replies/${encodeURIComponent(edit.name)}`, body);
      else await apiClient.post(`/helpdesk/saved-replies`, body);
      setMsg(edit.name ? "Saved reply updated." : "Saved reply created."); setEdit(null); reload();
    } catch { setMsg("Couldn't save — you may not have edit rights."); }
    finally { setBusy(false); }
  };
  const del = async (r: any) => {
    if (!window.confirm(`Delete saved reply "${r.title}"?`)) return;
    try { await apiClient.delete(`/helpdesk/saved-replies/${encodeURIComponent(r.name)}`); setMsg("Saved reply deleted."); reload(); }
    catch { setMsg("Couldn't delete — you may not have edit rights."); }
  };

  return (
    <div className="space-y-6 p-6">
      <PageHeader icon={Settings} title="Settings" subtitle="Help Desk configuration" actions={<RefreshBtn onClick={reload} loading={loading} />} />
      {error && <ErrorBanner msg={error} />}
      {msg && <div className="rounded-md bg-slate-50 px-3 py-2 text-xs text-slate-500">{msg}</div>}

      {/* ── Saved Replies (editable, tenant-scoped) ── */}
      <section className="rounded-xl border border-slate-200 bg-white">
        <div className="flex items-center justify-between border-b border-slate-100 px-5 py-3">
          <div className="flex items-center gap-2">
            <MessageSquareText size={18} className="text-[var(--color-base)]" />
            <h2 className="font-semibold text-[var(--color-text)]">Saved replies</h2>
            <span className="text-sm text-slate-400">{replies.length}</span>
          </div>
          <button onClick={openNew} className="flex items-center gap-1.5 rounded-lg bg-[var(--color-base)] px-3 py-1.5 text-sm font-medium text-white"><Plus size={15} /> New</button>
        </div>
        {loading ? <Loading what="saved replies" /> : replies.length === 0 ? (
          <p className="px-5 py-8 text-center text-sm text-slate-400">No saved replies yet. Create one to reuse across tickets.</p>
        ) : (
          <ul className="divide-y divide-slate-100">
            {replies.map((r) => (
              <li key={r.name} className="flex items-start gap-3 px-5 py-3">
                <div className="min-w-0 flex-1">
                  <div className="font-medium text-slate-800">{r.title}</div>
                  {r.message && <p className="mt-0.5 line-clamp-2 text-sm text-slate-500">{strip(r.message)}</p>}
                </div>
                <button onClick={() => openEdit(r)} className="rounded p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700" title="Edit"><Pencil size={15} /></button>
                <button onClick={() => del(r)} className="rounded p-1.5 text-slate-400 hover:bg-rose-50 hover:text-rose-600" title="Delete"><Trash2 size={15} /></button>
              </li>
            ))}
          </ul>
        )}
      </section>

      {/* ── Read-only engine config ── */}
      <section className="rounded-xl border border-slate-200 bg-white p-5">
        <div className="mb-3 flex items-center gap-2">
          <ShieldCheck size={18} className="text-slate-500" />
          <h2 className="font-semibold text-[var(--color-text)]">How your Help Desk is configured</h2>
          <span className="ml-2 inline-flex items-center gap-1 rounded-full bg-slate-100 px-2 py-0.5 text-[11px] text-slate-500"><Lock size={11} /> Managed by your administrator</span>
        </div>
        {cfgLoading ? <Loading what="configuration" /> : (
          <div className="grid gap-5 md:grid-cols-2">
            <div>
              <div className="mb-2 text-xs font-semibold uppercase tracking-wide text-slate-400">SLA targets{sla.policy ? ` · ${sla.policy}` : ""}</div>
              {Array.isArray(sla.priorities) && sla.priorities.length > 0 ? (
                <table className="w-full text-sm">
                  <thead><tr className="text-left text-xs text-slate-400"><th className="py-1 font-medium">Priority</th><th className="py-1 font-medium">Response</th><th className="py-1 font-medium">Resolution</th></tr></thead>
                  <tbody className="divide-y divide-slate-100">
                    {sla.priorities.map((p: any) => (
                      <tr key={p.priority}><td className="py-1.5 text-slate-700">{p.priority}</td><td className="py-1.5 text-slate-600">{p.response || "—"}</td><td className="py-1.5 text-slate-600">{p.resolution || "—"}</td></tr>
                    ))}
                  </tbody>
                </table>
              ) : <p className="text-sm text-slate-400">No SLA targets configured.</p>}
            </div>
            <div className="space-y-4">
              <div>
                <div className="mb-2 flex items-center gap-1.5 text-xs font-semibold uppercase tracking-wide text-slate-400"><Clock size={12} /> Business hours</div>
                {Array.isArray(sla.service_days) && sla.service_days.length > 0 ? (
                  <ul className="space-y-0.5 text-sm text-slate-600">
                    {sla.service_days.map((d: any) => <li key={d.day} className="flex justify-between"><span>{d.day}</span><span className="text-slate-500">{(d.start || "—").slice(0, 5)}–{(d.end || "—").slice(0, 5)}</span></li>)}
                  </ul>
                ) : <p className="text-sm text-slate-400">Not configured.</p>}
                {sla.holiday_list && <p className="mt-2 text-xs text-slate-400">Holiday calendar: {sla.holiday_list}</p>}
              </div>
              <div>
                <div className="mb-1 text-xs font-semibold uppercase tracking-wide text-slate-400">Auto-assignment</div>
                <span className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-0.5 text-sm ${cfg?.auto_assignment ? "bg-emerald-50 text-emerald-700" : "bg-slate-100 text-slate-500"}`}>
                  <span className={`h-1.5 w-1.5 rounded-full ${cfg?.auto_assignment ? "bg-emerald-500" : "bg-slate-400"}`} />
                  {cfg?.auto_assignment ? "Active — new tickets route to your team automatically" : "Not active"}
                </span>
              </div>
            </div>
          </div>
        )}
      </section>

      {/* ── links to the agent/team admin pages (already exist) ── */}
      <section className="grid gap-4 sm:grid-cols-2">
        <Link href="/helpdesk/agents" className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white p-4 hover:shadow-sm">
          <Users size={20} className="text-[var(--color-base)]" />
          <div><div className="font-medium text-slate-800">Agents</div><div className="text-sm text-slate-500">Manage who works your tickets</div></div>
        </Link>
        <Link href="/helpdesk/teams" className="flex items-center gap-3 rounded-xl border border-slate-200 bg-white p-4 hover:shadow-sm">
          <UsersRound size={20} className="text-[var(--color-base)]" />
          <div><div className="font-medium text-slate-800">Teams</div><div className="text-sm text-slate-500">Group agents for routing</div></div>
        </Link>
      </section>

      {/* ── create / edit modal ── */}
      {edit && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 p-4" onClick={() => setEdit(null)}>
          <div className="w-full max-w-lg rounded-xl bg-white p-5 shadow-xl" onClick={(e) => e.stopPropagation()}>
            <div className="mb-3 flex items-center justify-between">
              <h3 className="font-semibold text-[var(--color-text)]">{edit.name ? "Edit saved reply" : "New saved reply"}</h3>
              <button onClick={() => setEdit(null)} className="rounded p-1 text-slate-400 hover:bg-slate-100"><X size={16} /></button>
            </div>
            <label className="mb-1 block text-xs font-medium text-slate-500">Title</label>
            <input value={edit.title} onChange={(e) => setEdit({ ...edit, title: e.target.value })} placeholder="e.g. Awaiting customer response"
              className="mb-3 w-full rounded-md border border-slate-200 px-2.5 py-1.5 text-sm focus:border-[var(--color-base)] focus:outline-none" />
            <label className="mb-1 block text-xs font-medium text-slate-500">Message</label>
            <RichComposer key={composerKey} value={edit.message} onChange={(html) => setEdit((e) => (e ? { ...e, message: html } : e))} />
            <div className="mt-4 flex justify-end gap-2">
              <button onClick={() => setEdit(null)} className="rounded-lg border border-slate-200 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50">Cancel</button>
              <button onClick={save} disabled={busy || !edit.title.trim() || isEmptyHtml(edit.message)} className="rounded-lg bg-[var(--color-base)] px-4 py-1.5 text-sm font-medium text-white disabled:opacity-40">{busy ? "Saving…" : "Save"}</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
