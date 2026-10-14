"use client";

/**
 * Help Desk — rich, process-aware New-Ticket form (ITSM §7).
 *
 * Step 1 picks the Process (Incident / Service Request / Problem / Change) +
 * Department; then process-specific fields render. Submits a single
 * POST /helpdesk/tickets with `process` + the collected extension fields
 * (exact key names from spec §1/§2). The backend re-derives priority from the
 * impact/urgency matrix authoritatively — the live Priority chip here is just
 * UX feedback (same §4 matrix, client-side).
 */
import { useMemo, useState } from "react";
import { Chip, PRIORITY_CHIP, useHd } from "./_ui";
import { Modal, Field, Input, Textarea, Select, Btn, FormError, hdCall } from "./_admin";

type Dept = { id: number; name: string; enabled: boolean };

const PROCESSES = [
  { value: "incident", label: "Incident" },
  { value: "service_request", label: "Service Request" },
  { value: "problem", label: "Problem" },
  { value: "change", label: "Change" },
] as const;
type Process = (typeof PROCESSES)[number]["value"];

const SLA_LABEL: Record<Process, string> = {
  incident: "Incident SLA",
  service_request: "Service Request SLA",
  problem: "Problem SLA",
  change: "Change SLA",
};

// §4 priority matrix (impact row × urgency column). Backend is authoritative.
const MATRIX: Record<string, Record<string, string>> = {
  high: { high: "Urgent", medium: "High", low: "Medium" },
  medium: { high: "High", medium: "Medium", low: "Low" },
  low: { high: "Medium", medium: "Low", low: "Low" },
};
const derivePriority = (impact: string, urgency: string): string | null =>
  impact && urgency ? MATRIX[impact]?.[urgency] ?? null : null;

const LEVELS = ["low", "medium", "high"];

export function NewTicketDialog({
  open,
  onClose,
  onCreated,
}: {
  open: boolean;
  onClose: () => void;
  onCreated: () => void;
}) {
  const depts = useHd<{ departments: Dept[] }>("/helpdesk/departments");
  // Shape: a map of category → [subcategories] (§3.5). Tolerate a {catalog:…} wrapper or absence.
  const sc = useHd<any>("/helpdesk/service-catalog");

  const [process, setProcess] = useState<Process>("incident");
  const [departmentId, setDepartmentId] = useState("");
  const [subject, setSubject] = useState("");
  const [description, setDescription] = useState("");
  const [contact, setContact] = useState("");

  // shared (incident + service_request)
  const [impact, setImpact] = useState("");
  const [urgency, setUrgency] = useState("");
  // service_request
  const [category, setCategory] = useState("");
  const [subcategory, setSubcategory] = useState("");
  // problem
  const [rootCause, setRootCause] = useState("");
  // change
  const [changeType, setChangeType] = useState("normal");
  const [changeRisk, setChangeRisk] = useState("medium");
  const [plannedStart, setPlannedStart] = useState("");
  const [plannedEnd, setPlannedEnd] = useState("");
  const [implPlan, setImplPlan] = useState("");
  const [backoutPlan, setBackoutPlan] = useState("");

  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const deptList = (depts.data?.departments || []).filter((d) => d.enabled);

  const catalog: Record<string, string[]> = useMemo(() => {
    const raw = sc.data;
    if (!raw || typeof raw !== "object") return {};
    const map = raw.catalog && typeof raw.catalog === "object" ? raw.catalog : raw;
    const out: Record<string, string[]> = {};
    for (const k of Object.keys(map)) if (Array.isArray(map[k])) out[k] = map[k];
    return out;
  }, [sc.data]);
  const categories = Object.keys(catalog);
  const subs = category ? catalog[category] || [] : [];

  const derived = derivePriority(impact, urgency);

  const reset = () => {
    setProcess("incident");
    setDepartmentId(""); setSubject(""); setDescription(""); setContact("");
    setImpact(""); setUrgency("");
    setCategory(""); setSubcategory("");
    setRootCause("");
    setChangeType("normal"); setChangeRisk("medium");
    setPlannedStart(""); setPlannedEnd(""); setImplPlan(""); setBackoutPlan("");
    setErr(null);
  };

  const close = () => { if (!busy) { reset(); onClose(); } };

  const submit = async () => {
    if (!subject.trim()) { setErr("Subject is required."); return; }
    setBusy(true); setErr(null);

    const payload: Record<string, unknown> = {
      process,
      subject: subject.trim(),
      description: description.trim() || null,
      department_id: departmentId ? Number(departmentId) : null,
    };
    if (contact.trim()) payload.contact = contact.trim();

    if (process === "incident" || process === "service_request") {
      if (impact) payload.impact = impact;
      if (urgency) payload.urgency = urgency;
    }
    if (process === "service_request") {
      if (category) payload.request_category = category;
      if (subcategory) payload.request_subcategory = subcategory;
    }
    if (process === "problem") {
      if (rootCause.trim()) payload.root_cause = rootCause.trim();
    }
    if (process === "change") {
      payload.change_type = changeType;
      payload.change_risk = changeRisk;
      if (plannedStart) payload.planned_start = plannedStart;
      if (plannedEnd) payload.planned_end = plannedEnd;
      if (implPlan.trim()) payload.implementation_plan = implPlan.trim();
      if (backoutPlan.trim()) payload.backout_plan = backoutPlan.trim();
    }

    const create = await hdCall("post", "/helpdesk/tickets", payload);
    setBusy(false);
    if (!create.ok || !create.data?.name) {
      setErr(create.error || "Could not create the ticket.");
      return;
    }
    reset();
    onCreated();
  };

  return (
    <Modal
      open={open}
      onClose={close}
      title="New ticket"
      subtitle="Pick a process, then fill in what it needs"
      wide
      footer={
        <>
          <Btn variant="ghost" onClick={close} disabled={busy}>Cancel</Btn>
          <Btn variant="primary" onClick={submit} busy={busy}>
            {process === "change" ? "Create draft change" : "Create ticket"}
          </Btn>
        </>
      }
    >
      <FormError msg={err} />
      <div className="flex flex-col gap-3.5">
        {/* Step 1 — process */}
        <div>
          <span className="mb-1.5 block text-[11.5px] font-semibold text-[#475569]">Process</span>
          <div className="flex flex-wrap gap-2">
            {PROCESSES.map((p) => (
              <button
                key={p.value}
                type="button"
                onClick={() => setProcess(p.value)}
                className={`rounded-[9px] border px-3 py-1.5 text-[12.5px] font-semibold transition ${
                  process === p.value
                    ? "border-[#005B96] bg-[#005B96] text-white"
                    : "border-[#E2E5EC] bg-white text-[#334155] hover:bg-[#F6F7FB]"
                }`}
              >
                {p.label}
              </button>
            ))}
          </div>
          <span className="mt-1.5 inline-flex items-center gap-1 text-[11px] text-[#94A3B8]">
            SLA: <span className="font-medium text-[#64748B]">{SLA_LABEL[process]}</span>
          </span>
        </div>

        <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-2">
          <Field label="Department" hint={deptList.length ? undefined : "No departments yet — create one in Settings → Departments."}>
            <Select value={departmentId} onChange={(e) => setDepartmentId(e.target.value)}>
              <option value="">— Select —</option>
              {deptList.map((d) => (
                <option key={d.id} value={d.id}>{d.name}</option>
              ))}
            </Select>
          </Field>
          <Field label="Subject" required>
            <Input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Short summary of the request" autoFocus />
          </Field>
        </div>

        {/* Incident */}
        {process === "incident" && (
          <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-3">
            <Field label="Impact">
              <Select value={impact} onChange={(e) => setImpact(e.target.value)}>
                <option value="">— Select —</option>
                {LEVELS.map((l) => <option key={l} value={l}>{l[0].toUpperCase() + l.slice(1)}</option>)}
              </Select>
            </Field>
            <Field label="Urgency">
              <Select value={urgency} onChange={(e) => setUrgency(e.target.value)}>
                <option value="">— Select —</option>
                {LEVELS.map((l) => <option key={l} value={l}>{l[0].toUpperCase() + l.slice(1)}</option>)}
              </Select>
            </Field>
            <Field label="Priority" hint="Derived from impact × urgency.">
              <div className="flex h-[38px] items-center">
                {derived ? <Chip value={derived} map={PRIORITY_CHIP} /> : <span className="text-[12px] text-[#94A3B8]">Pick impact + urgency</span>}
              </div>
            </Field>
          </div>
        )}

        {/* Service Request */}
        {process === "service_request" && (
          <>
            <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-2">
              <Field label="Category">
                <Select value={category} onChange={(e) => { setCategory(e.target.value); setSubcategory(""); }}>
                  <option value="">{categories.length ? "— Select —" : "No catalog configured"}</option>
                  {categories.map((c) => <option key={c} value={c}>{c}</option>)}
                </Select>
              </Field>
              <Field label="Subcategory">
                <Select value={subcategory} onChange={(e) => setSubcategory(e.target.value)} disabled={!subs.length}>
                  <option value="">{subs.length ? "— Select —" : "—"}</option>
                  {subs.map((s) => <option key={s} value={s}>{s}</option>)}
                </Select>
              </Field>
            </div>
            <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-3">
              <Field label="Impact">
                <Select value={impact} onChange={(e) => setImpact(e.target.value)}>
                  <option value="">— Optional —</option>
                  {LEVELS.map((l) => <option key={l} value={l}>{l[0].toUpperCase() + l.slice(1)}</option>)}
                </Select>
              </Field>
              <Field label="Urgency">
                <Select value={urgency} onChange={(e) => setUrgency(e.target.value)}>
                  <option value="">— Optional —</option>
                  {LEVELS.map((l) => <option key={l} value={l}>{l[0].toUpperCase() + l.slice(1)}</option>)}
                </Select>
              </Field>
              <Field label="Priority" hint="Derived from impact × urgency.">
                <div className="flex h-[38px] items-center">
                  {derived ? <Chip value={derived} map={PRIORITY_CHIP} /> : <span className="text-[12px] text-[#94A3B8]">Default</span>}
                </div>
              </Field>
            </div>
          </>
        )}

        {/* Problem */}
        {process === "problem" && (
          <Field label="Root cause" hint="Optional — linked incidents can be added on the problem detail page.">
            <Textarea value={rootCause} onChange={(e) => setRootCause(e.target.value)} placeholder="Suspected or confirmed root cause…" />
          </Field>
        )}

        {/* Change */}
        {process === "change" && (
          <>
            <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-2">
              <Field label="Change type">
                <Select value={changeType} onChange={(e) => setChangeType(e.target.value)}>
                  <option value="standard">Standard</option>
                  <option value="normal">Normal</option>
                  <option value="emergency">Emergency</option>
                </Select>
              </Field>
              <Field label="Risk">
                <Select value={changeRisk} onChange={(e) => setChangeRisk(e.target.value)}>
                  {LEVELS.map((l) => <option key={l} value={l}>{l[0].toUpperCase() + l.slice(1)}</option>)}
                </Select>
              </Field>
              <Field label="Planned start">
                <Input type="datetime-local" value={plannedStart} onChange={(e) => setPlannedStart(e.target.value)} />
              </Field>
              <Field label="Planned end">
                <Input type="datetime-local" value={plannedEnd} onChange={(e) => setPlannedEnd(e.target.value)} />
              </Field>
            </div>
            <Field label="Implementation plan">
              <Textarea value={implPlan} onChange={(e) => setImplPlan(e.target.value)} placeholder="Steps to implement the change…" />
            </Field>
            <Field label="Backout plan">
              <Textarea value={backoutPlan} onChange={(e) => setBackoutPlan(e.target.value)} placeholder="How to roll back if it goes wrong…" />
            </Field>
          </>
        )}

        <Field label="Description">
          <Textarea value={description} onChange={(e) => setDescription(e.target.value)} placeholder="What's going on? Steps, context, impact…" />
        </Field>

        <Field label="Contact email" hint="Who raised this, if not an internal user.">
          <Input type="email" value={contact} onChange={(e) => setContact(e.target.value)} placeholder="person@company.com" />
        </Field>
      </div>
    </Modal>
  );
}
