"use client";

/**
 * Requester portal — "Request something".
 *
 * Guided 4-step wizard for service requests (new laptop, software, access…):
 *   1. pick a category   2. pick a request item   3. fill in the details
 *   4. review & submit.
 * Submits POST /helpdesk/portal/requests with process="service_request"; the
 * backend derives priority/SLA and routes to the right team. On success we offer
 * a link to the new request in My Requests.
 *
 * Catalogue source (end-user safe):
 *   1. GET /helpdesk/portal/catalogue  — PLACEHOLDER, not in portal.py yet. When
 *      the backend adds it, the wizard picks it up automatically (see shape below).
 *   2. fallback: GET /helpdesk/portal/templates — the predefined request library
 *      that already exists, filtered to service requests.
 *
 * Expected /helpdesk/portal/catalogue shape:
 *   { categories: [{id,name,description?}],
 *     services:   [{id,name,category_id?}],
 *     requests:   [{id,code?,name,description?,category?,category_id?,business_service?,
 *                   business_service_id?,approval_required?,sla_hours?,cost?,department_id?,
 *                   default_impact?,default_urgency?,
 *                   fields?: [{key,label,type?: text|textarea|select|number|date|checkbox,
 *                              required?,hint?,options?: string[]}]}] }
 */
import { useMemo, useState } from "react";
import Link from "next/link";
import { ClipboardList, CheckCircle2, ArrowLeft, ArrowRight, Check, Search, FolderOpen, Inbox, BookOpen, ShieldCheck } from "lucide-react";
import { Empty, Loading, PageHeader, useHd } from "../../_ui";
import { Field, Input, Textarea, Select, Btn, FormError, hdCall } from "../../_admin";

type FieldDef = { key: string; label: string; type: string; required: boolean; hint?: string; options: string[] };
type Item = {
  key: string;
  requestItemId: number | null;
  name: string;
  description: string;
  category: string;
  service: string;
  approvalRequired: boolean;
  slaHours: number | null;
  cost: number | null;
  departmentId: number | null;
  impact: string;
  urgency: string;
  requestCategory: string;
  requestSubcategory: string;
  defaultDescription: string;
  fields: FieldDef[];
};

const STEPS = ["Category", "Request", "Details", "Review"];

const URGENCY = [
  { value: "low", label: "Whenever — it's not blocking me" },
  { value: "medium", label: "Soon — it's slowing me down" },
  { value: "high", label: "Urgent — I can't work without it" },
];
const urgencyLabel = (v: string) => URGENCY.find((u) => u.value === v)?.label || v;

// ── normalise whichever catalogue source answered ───────────────────────────
function toFields(raw: any): FieldDef[] {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter((f: any) => f && (f.key || f.label))
    .map((f: any, i: number) => ({
      key: String(f.key || f.label || `field_${i}`),
      label: String(f.label || f.key),
      type: String(f.type || "text").toLowerCase(),
      required: !!f.required,
      hint: f.hint || f.help || undefined,
      options: Array.isArray(f.options) ? f.options.map((o: any) => String(o)) : [],
    }));
}

function normalise(cat: any, tpl: any): Item[] {
  const reqs: any[] = Array.isArray(cat?.requests) ? cat.requests : [];
  if (reqs.length > 0) {
    const cats: any[] = Array.isArray(cat?.categories) ? cat.categories : [];
    return reqs.map((r: any) => {
      const catName =
        r.category || cats.find((c: any) => c.id === r.category_id)?.name || "General";
      return {
        key: `item-${r.id ?? r.code ?? r.name}`,
        requestItemId: typeof r.id === "number" ? r.id : null,
        name: String(r.name || r.code || "Request"),
        description: String(r.description || ""),
        category: String(catName),
        service: String(r.business_service || ""),
        approvalRequired: !!r.approval_required,
        slaHours: typeof r.sla_hours === "number" ? r.sla_hours : null,
        cost: typeof r.cost === "number" ? r.cost : null,
        departmentId: typeof r.department_id === "number" ? r.department_id : null,
        impact: String(r.default_impact || "low"),
        urgency: String(r.default_urgency || "medium"),
        requestCategory: String(catName),
        requestSubcategory: "",
        defaultDescription: "",
        fields: toFields(r.fields),
      };
    });
  }
  // Fallback: the request library that portal.py already exposes.
  const all: any[] = Array.isArray(tpl?.templates) ? tpl.templates : [];
  const svc = all.filter((t: any) => (t.process || "") === "service_request");
  return (svc.length > 0 ? svc : all).map((t: any) => ({
    key: `tpl-${t.id}`,
    requestItemId: null,
    name: String(t.template_name || t.default_subject || "Request"),
    description: String(t.default_description || ""),
    category: String(t.default_category || t.department || "General"),
    service: String(t.default_subcategory || ""),
    approvalRequired: false,
    slaHours: null,
    cost: null,
    departmentId: typeof t.department_id === "number" ? t.department_id : null,
    impact: String(t.default_impact || "low"),
    urgency: String(t.default_urgency || "medium"),
    requestCategory: String(t.default_category || ""),
    requestSubcategory: String(t.default_subcategory || ""),
    defaultDescription: String(t.default_description || ""),
    fields: [],
  }));
}

// ── page ────────────────────────────────────────────────────────────────────
export default function RequestSomething() {
  const cat = useHd<any>("/helpdesk/portal/catalogue"); // placeholder endpoint
  const tpl = useHd<any>("/helpdesk/portal/templates");
  const kb = useHd<{ articles: any[] }>("/helpdesk/portal/kb");

  const items = useMemo(() => normalise(cat.data, tpl.data), [cat.data, tpl.data]);
  const categories = useMemo(() => {
    const m = new Map<string, number>();
    items.forEach((i) => m.set(i.category, (m.get(i.category) || 0) + 1));
    const descs = new Map<string, string>();
    (Array.isArray(cat.data?.categories) ? cat.data.categories : []).forEach((c: any) => {
      if (c?.name) descs.set(String(c.name), String(c.description || ""));
    });
    return Array.from(m.entries())
      .sort((a, b) => a[0].localeCompare(b[0]))
      .map(([name, count]) => ({ name, count, description: descs.get(name) || "" }));
  }, [items, cat.data]);

  const [step, setStep] = useState(0);
  const [category, setCategory] = useState<string | null>(null);
  const [service, setService] = useState("");
  const [search, setSearch] = useState("");
  const [item, setItem] = useState<Item | null>(null);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [notes, setNotes] = useState("");
  const [urgency, setUrgency] = useState("medium");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const [doneId, setDoneId] = useState<string | null>(null);
  const [needsApproval, setNeedsApproval] = useState(false);

  const loading = cat.loading || tpl.loading;

  const inCategory = useMemo(() => items.filter((i) => i.category === category), [items, category]);
  const services = useMemo(
    () => Array.from(new Set(inCategory.map((i) => i.service).filter(Boolean))).sort(),
    [inCategory],
  );
  const visible = useMemo(() => {
    const s = search.trim().toLowerCase();
    return inCategory.filter(
      (i) =>
        (!service || i.service === service) &&
        (!s || [i.name, i.description].some((v) => (v || "").toLowerCase().includes(s))),
    );
  }, [inCategory, service, search]);

  // KB suggestions: published articles whose title shares a word with the chosen request.
  const suggestions = useMemo(() => {
    if (!item) return [];
    const words = item.name.toLowerCase().split(/\W+/).filter((w) => w.length > 3);
    if (words.length === 0) return [];
    const arts: any[] = Array.isArray(kb.data?.articles) ? kb.data!.articles : [];
    return arts
      .filter((a) => !/draft|archiv/i.test(a.status || ""))
      .filter((a) => words.some((w) => (a.title || "").toLowerCase().includes(w)))
      .slice(0, 3);
  }, [item, kb.data]);

  const pickCategory = (name: string) => {
    setCategory(name); setService(""); setSearch(""); setItem(null); setErr(null);
    setStep(1);
  };
  const pickItem = (i: Item) => {
    setItem(i); setAnswers({}); setNotes(""); setUrgency(i.urgency || "medium"); setErr(null);
  };

  const validate = (s: number): string | null => {
    if (s === 0 && !category) return "Please choose a category.";
    if (s === 1 && !item) return "Please choose what you'd like to request.";
    if (s === 2 && item) {
      for (const f of item.fields) {
        if (f.required && f.type !== "checkbox" && !(answers[f.key] || "").trim()) {
          return `Please fill in “${f.label}”.`;
        }
      }
    }
    return null;
  };
  const next = () => {
    const v = validate(step);
    if (v) { setErr(v); return; }
    setErr(null); setStep((s) => Math.min(s + 1, STEPS.length - 1));
  };
  const back = () => { setErr(null); setStep((s) => Math.max(s - 1, 0)); };

  const answerLines = (): string[] =>
    (item?.fields || [])
      .map((f) => {
        const v = f.type === "checkbox" ? (answers[f.key] === "yes" ? "Yes" : "No") : (answers[f.key] || "").trim();
        return v ? `${f.label}: ${v}` : "";
      })
      .filter(Boolean);

  const submit = async () => {
    if (!item) return;
    for (let s = 0; s < 3; s++) {
      const v = validate(s);
      if (v) { setErr(v); setStep(s); return; }
    }
    setBusy(true); setErr(null);
    // Answers are also folded into the description so nothing is lost even if
    // the backend ignores the structured `fields` payload.
    const description = [notes.trim() || item.defaultDescription, ...answerLines()].filter(Boolean).join("\n");
    const body: Record<string, unknown> = {
      subject: item.name,
      description: description || null,
      process: "service_request",
      urgency,
      impact: item.impact,
      request_category: item.requestCategory || item.category,
      request_subcategory: item.requestSubcategory || item.service || undefined,
      fields: answers,
    };
    if (item.departmentId != null) body.department_id = item.departmentId;
    if (item.requestItemId != null) body.request_item_id = item.requestItemId;
    const r = await hdCall("post", "/helpdesk/portal/requests", body);
    setBusy(false);
    if (!r.ok || !r.data?.name) { setErr(r.error || "Sorry — we couldn't submit that. Please try again."); return; }
    setNeedsApproval(item.approvalRequired);
    setDoneId(String(r.data.name));
  };

  const reset = () => {
    setDoneId(null); setStep(0); setCategory(null); setService(""); setSearch("");
    setItem(null); setAnswers({}); setNotes(""); setUrgency("medium"); setErr(null); setNeedsApproval(false);
  };

  if (doneId) {
    return (
      <div className="mx-auto flex max-w-lg flex-col items-center gap-4 py-20 text-center">
        <div className="grid h-14 w-14 place-items-center rounded-full bg-emerald-50 text-emerald-600">
          <CheckCircle2 size={30} />
        </div>
        <h1 className="text-xl font-semibold text-[#0F172A]">Request submitted!</h1>
        <p className="text-sm text-[#64748B]">
          Your request <span className="font-mono font-semibold text-[#005B96]">#{doneId}</span> has been received.
          {needsApproval
            ? " It needs an approval first — we'll let you know as soon as it's decided."
            : " You can follow its progress and reply from My Requests."}
        </p>
        <div className="flex items-center gap-2">
          <Link href={`/helpdesk/portal/my-requests/${encodeURIComponent(doneId)}`}>
            <Btn variant="primary">View my request</Btn>
          </Link>
          <Btn variant="ghost" onClick={reset}>Request something else</Btn>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto flex max-w-3xl flex-col gap-5 text-[#0F172A]">
      <PageHeader
        icon={ClipboardList}
        title="Request something"
        subtitle="Pick what you need and we'll take care of the rest."
      />

      {/* progress indicator */}
      <ol className="flex items-center gap-2">
        {STEPS.map((label, i) => {
          const done = i < step;
          const active = i === step;
          return (
            <li key={label} className="flex flex-1 items-center gap-2">
              <span
                className={`grid h-6 w-6 shrink-0 place-items-center rounded-full text-[11px] font-semibold ${
                  done ? "bg-emerald-500 text-white" : active ? "bg-[#005B96] text-white" : "bg-[#EEF1F5] text-[#94A3B8]"
                }`}
              >
                {done ? <Check size={13} /> : i + 1}
              </span>
              <span className={`text-[12px] font-medium ${active ? "text-[#0F172A]" : "text-[#94A3B8]"}`}>{label}</span>
              {i < STEPS.length - 1 && <span className={`h-px flex-1 ${done ? "bg-emerald-300" : "bg-[#E2E5EC]"}`} />}
            </li>
          );
        })}
      </ol>

      <div className="rounded-2xl border border-[#EEF1F5] bg-white p-5">
        <FormError msg={err} />

        {loading ? (
          <Loading what="the catalogue" />
        ) : items.length === 0 ? (
          <Empty
            icon={Inbox}
            title="Nothing to request yet"
            hint="No request items are published for you yet. You can still report an issue."
          />
        ) : (
          <>
            {/* STEP 1 — category */}
            {step === 0 && (
              <div className="flex flex-col gap-3">
                <h2 className="text-[15px] font-semibold">What kind of request is it?</h2>
                <div className="grid gap-3 sm:grid-cols-2">
                  {categories.map((c) => {
                    const sel = category === c.name;
                    return (
                      <button
                        key={c.name}
                        type="button"
                        onClick={() => pickCategory(c.name)}
                        className={`flex items-start gap-3 rounded-xl border p-4 text-left transition hover:shadow-sm ${
                          sel ? "border-[#005B96] bg-[#005B96]/5" : "border-slate-200 bg-white"
                        }`}
                      >
                        <FolderOpen size={18} className="mt-0.5 shrink-0 text-[#005B96]" />
                        <span className="min-w-0 flex-1">
                          <span className="block font-medium text-[#0F172A]">{c.name}</span>
                          <span className="mt-0.5 block text-xs text-slate-500">
                            {c.description || `${c.count} ${c.count === 1 ? "option" : "options"}`}
                          </span>
                        </span>
                      </button>
                    );
                  })}
                </div>
              </div>
            )}

            {/* STEP 2 — request item */}
            {step === 1 && (
              <div className="flex flex-col gap-3">
                <h2 className="text-[15px] font-semibold">What would you like in “{category}”?</h2>
                <div className="flex flex-wrap items-center gap-2">
                  <div className="relative flex-1">
                    <Search size={15} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
                    <input
                      value={search}
                      onChange={(e) => setSearch(e.target.value)}
                      placeholder="Search this category…"
                      className="w-full rounded-lg border border-slate-200 bg-white py-1.5 pl-9 pr-3 text-sm outline-none focus:border-[#005B96]"
                    />
                  </div>
                  {services.length > 1 && (
                    <div className="w-52">
                      <Select value={service} onChange={(e) => setService(e.target.value)}>
                        <option value="">All services</option>
                        {services.map((s) => <option key={s} value={s}>{s}</option>)}
                      </Select>
                    </div>
                  )}
                </div>
                {visible.length === 0 ? (
                  <Empty icon={Inbox} title="No matching requests" hint="Try a different search or category." />
                ) : (
                  <div className="grid gap-3 sm:grid-cols-2">
                    {visible.map((i) => {
                      const sel = item?.key === i.key;
                      return (
                        <button
                          key={i.key}
                          type="button"
                          onClick={() => pickItem(i)}
                          className={`rounded-xl border p-4 text-left transition hover:shadow-sm ${
                            sel ? "border-[#005B96] bg-[#005B96]/5" : "border-slate-200 bg-white"
                          }`}
                        >
                          <span className="block font-medium text-[#0F172A]">{i.name}</span>
                          {i.description && (
                            <span className="mt-1 block text-xs text-slate-500">{i.description}</span>
                          )}
                          <span className="mt-2 flex flex-wrap items-center gap-2 text-[11px] text-slate-500">
                            {i.service && <span className="rounded-full bg-slate-100 px-2 py-0.5">{i.service}</span>}
                            {i.approvalRequired && (
                              <span className="inline-flex items-center gap-1 rounded-full bg-amber-50 px-2 py-0.5 text-amber-700">
                                <ShieldCheck size={11} /> Needs approval
                              </span>
                            )}
                            {i.slaHours != null && <span>~{i.slaHours}h to fulfil</span>}
                          </span>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            {/* STEP 3 — details */}
            {step === 2 && item && (
              <div className="flex flex-col gap-4">
                <div>
                  <h2 className="text-[15px] font-semibold">{item.name}</h2>
                  {item.description && <p className="mt-0.5 text-xs text-slate-500">{item.description}</p>}
                </div>

                {suggestions.length > 0 && (
                  <div className="rounded-xl border border-slate-200 bg-[#F9FAFC] p-3">
                    <div className="mb-1.5 flex items-center gap-1.5 text-[12px] font-semibold text-[#475569]">
                      <BookOpen size={13} /> These help articles might save you time
                    </div>
                    <ul className="space-y-1">
                      {suggestions.map((a) => (
                        <li key={a.name} className="text-[12.5px]">
                          <Link href="/helpdesk/portal/kb" className="text-[#005B96] hover:underline">
                            {a.title || a.name}
                          </Link>
                        </li>
                      ))}
                    </ul>
                  </div>
                )}

                {item.fields.map((f) => (
                  <Field key={f.key} label={f.label} required={f.required} hint={f.hint}>
                    {f.type === "textarea" ? (
                      <Textarea
                        value={answers[f.key] || ""}
                        onChange={(e) => setAnswers((a) => ({ ...a, [f.key]: e.target.value }))}
                      />
                    ) : f.type === "select" ? (
                      <Select
                        value={answers[f.key] || ""}
                        onChange={(e) => setAnswers((a) => ({ ...a, [f.key]: e.target.value }))}
                      >
                        <option value="">Select…</option>
                        {f.options.map((o) => <option key={o} value={o}>{o}</option>)}
                      </Select>
                    ) : f.type === "checkbox" ? (
                      <span className="inline-flex items-center gap-2 text-[13px]">
                        <input
                          type="checkbox"
                          checked={answers[f.key] === "yes"}
                          onChange={(e) => setAnswers((a) => ({ ...a, [f.key]: e.target.checked ? "yes" : "" }))}
                        />
                        Yes
                      </span>
                    ) : (
                      <Input
                        type={f.type === "number" ? "number" : f.type === "date" ? "date" : "text"}
                        value={answers[f.key] || ""}
                        onChange={(e) => setAnswers((a) => ({ ...a, [f.key]: e.target.value }))}
                      />
                    )}
                  </Field>
                ))}

                <Field label="Anything else we should know?" hint="Why you need it, who it's for, when you need it by.">
                  <Textarea
                    value={notes}
                    onChange={(e) => setNotes(e.target.value)}
                    placeholder={item.defaultDescription || "Add any details…"}
                  />
                </Field>
                <Field label="How soon do you need it?">
                  <Select value={urgency} onChange={(e) => setUrgency(e.target.value)}>
                    {URGENCY.map((u) => <option key={u.value} value={u.value}>{u.label}</option>)}
                  </Select>
                </Field>
              </div>
            )}

            {/* STEP 4 — review */}
            {step === 3 && item && (
              <div className="flex flex-col gap-3">
                <h2 className="text-[15px] font-semibold">Review your request</h2>
                <dl className="divide-y divide-[#EEF1F5] rounded-xl border border-[#EEF1F5] text-sm">
                  <ReviewRow label="Category" value={item.category} />
                  <ReviewRow label="Request" value={item.name} />
                  {item.service && <ReviewRow label="Service" value={item.service} />}
                  {item.fields.map((f) => (
                    <ReviewRow
                      key={f.key}
                      label={f.label}
                      value={f.type === "checkbox" ? (answers[f.key] === "yes" ? "Yes" : "No") : answers[f.key] || "—"}
                    />
                  ))}
                  <ReviewRow label="Details" value={notes.trim() || "—"} />
                  <ReviewRow label="Urgency" value={urgencyLabel(urgency)} />
                </dl>
                {item.approvalRequired && (
                  <div className="flex items-center gap-2 rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-[12.5px] text-amber-800">
                    <ShieldCheck size={14} /> This request needs an approval before it can be fulfilled.
                  </div>
                )}
              </div>
            )}

            {/* nav */}
            <div className="mt-5 flex items-center justify-between gap-2 border-t border-[#EEF1F5] pt-4">
              <div>
                {step > 0 ? (
                  <Btn variant="ghost" onClick={back} icon={<ArrowLeft size={14} />}>Back</Btn>
                ) : (
                  <Link href="/helpdesk/portal/my-requests"><Btn variant="ghost">Cancel</Btn></Link>
                )}
              </div>
              {step < STEPS.length - 1 ? (
                <Btn variant="primary" onClick={next} icon={<ArrowRight size={14} />}>Next</Btn>
              ) : (
                <Btn variant="primary" onClick={submit} busy={busy}>Submit request</Btn>
              )}
            </div>
          </>
        )}
      </div>
    </div>
  );
}

function ReviewRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex gap-4 px-4 py-2.5">
      <dt className="w-32 shrink-0 text-[12px] font-semibold text-[#64748B]">{label}</dt>
      <dd className="min-w-0 flex-1 whitespace-pre-wrap break-words text-[#0F172A]">{value}</dd>
    </div>
  );
}
