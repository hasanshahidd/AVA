"use client";

// Help Desk CMDB admin: CI types (+ attribute definitions), configuration items,
// relationship types, relationships, and a grouped graph view.
// All data comes from /helpdesk/admin/cmdb/* (tenant-scoped through apiClient).
import { useMemo, useState } from "react";
import { Boxes, Layers, Server, GitBranch, Link2, Network, Pencil, Trash2, Ban, Plus, ListChecks } from "lucide-react";
import { apiClient } from "@/lib/api";
import { Chip, PageHeader, RefreshBtn, Empty, ErrorBanner, Loading, Table, useHd } from "../../_ui";
import { Btn, Field, FormError, Input, Modal, NewBtn, Select, Textarea, Toggle } from "../../_admin";

const BASE = "/helpdesk/admin/cmdb";

// ── helpers ─────────────────────────────────────────────────────────────────
type Tab = "types" | "cis" | "reltypes" | "rels" | "graph";

const CI_STATUS_CHIP: Record<string, string> = {
  active: "bg-emerald-50 text-emerald-700", planned: "bg-blue-50 text-blue-700",
  maintenance: "bg-amber-50 text-amber-700", retired: "bg-slate-100 text-slate-500",
};
const CRIT_CHIP: Record<string, string> = {
  critical: "bg-red-100 text-red-700", high: "bg-orange-100 text-orange-700",
  medium: "bg-amber-100 text-amber-700", low: "bg-sky-100 text-sky-700",
};
const STATUSES = ["active", "planned", "maintenance", "retired"];
const CRITICALITIES = ["low", "medium", "high", "critical"];
const ENVIRONMENTS = ["production", "staging", "development", "test", "dr"];
const DATATYPES = ["string", "number", "boolean", "date", "enum"];

/** Pull an array out of either a bare array or a wrapped {key:[...]} response. */
const asList = (d: any, ...keys: string[]): any[] => {
  if (Array.isArray(d)) return d;
  for (const k of keys) if (Array.isArray(d?.[k])) return d[k];
  return [];
};

/** Surface server detail (string or FastAPI validation list) as readable text. */
const errText = (e: any): string => {
  const detail = e?.response?.data?.detail;
  if (typeof detail === "string" && detail) return detail;
  if (Array.isArray(detail) && detail.length) {
    return detail.map((x: any) => (typeof x === "string" ? x : x?.msg || JSON.stringify(x))).join("; ");
  }
  return e?.message || "Something went wrong — please try again.";
};

/** Mutate a CMDB endpoint; returns {ok,data} or {ok:false,error}. */
async function cmdb(method: "post" | "patch" | "delete", path: string, body?: unknown): Promise<{ ok: boolean; data?: any; error?: string }> {
  try {
    const res = method === "delete" ? await apiClient.delete(`${BASE}${path}`) : await apiClient[method](`${BASE}${path}`, body ?? {});
    return { ok: true, data: res.data };
  } catch (e: any) {
    return { ok: false, error: errText(e) };
  }
}

const intOrNull = (v: any): number | null => (v === "" || v == null || isNaN(Number(v)) ? null : Number(v));
const strOrNull = (v: any): string | null => { const s = (v ?? "").toString().trim(); return s ? s : null; };

function OptSelect({ value, options, onChange, blank }: { value: string; options: string[]; onChange: (v: string) => void; blank?: string }) {
  const opts = value && !options.includes(value) ? [value, ...options] : options;
  return (
    <Select value={value} onChange={(e) => onChange(e.target.value)}>
      {blank !== undefined && <option value="">{blank}</option>}
      {opts.map((o) => <option key={o} value={o}>{o}</option>)}
    </Select>
  );
}

function RowBtns({ children }: { children: React.ReactNode }) {
  return <div className="flex items-center justify-end gap-1.5">{children}</div>;
}

// ── page ────────────────────────────────────────────────────────────────────
const TABS: { id: Tab; label: string; icon: any }[] = [
  { id: "types", label: "CI Types", icon: Layers },
  { id: "cis", label: "Configuration Items", icon: Server },
  { id: "reltypes", label: "Relationship Types", icon: GitBranch },
  { id: "rels", label: "Relationships", icon: Link2 },
  { id: "graph", label: "Graph", icon: Network },
];

export default function CmdbAdminPage() {
  const [tab, setTab] = useState<Tab>("types");
  return (
    <div className="space-y-5 p-6">
      <PageHeader icon={Boxes} title="CMDB" subtitle="Configuration items, their types, and how they relate" />
      <div className="flex flex-wrap gap-1 border-b border-slate-200">
        {TABS.map((t) => {
          const Icon = t.icon;
          const on = tab === t.id;
          return (
            <button key={t.id} onClick={() => setTab(t.id)}
              className={`-mb-px inline-flex items-center gap-2 border-b-2 px-3.5 py-2 text-sm font-medium transition ${on ? "border-[var(--color-base)] text-[var(--color-base)]" : "border-transparent text-slate-500 hover:text-slate-700"}`}>
              <Icon size={15} /> {t.label}
            </button>
          );
        })}
      </div>
      {tab === "types" && <TypesTab />}
      {tab === "cis" && <CisTab />}
      {tab === "reltypes" && <RelTypesTab />}
      {tab === "rels" && <RelsTab />}
      {tab === "graph" && <GraphTab />}
    </div>
  );
}

// ── CI types + attribute definitions ───────────────────────────────────────
function TypesTab() {
  const { data, loading, error, reload } = useHd<any>(`${BASE}/types`);
  const types = asList(data, "types", "items");
  const byId = useMemo(() => new Map<any, any>(types.map((t: any) => [t.id, t] as [any, any])), [types]);
  const [edit, setEdit] = useState<any | null>(null);   // {id?,code,name,description,parent_id}
  const [attrsFor, setAttrsFor] = useState<any | null>(null);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-2">
        <p className="text-sm text-slate-500">{types.length} CI type{types.length === 1 ? "" : "s"}</p>
        <div className="flex items-center gap-2">
          <RefreshBtn onClick={reload} loading={loading} />
          <NewBtn label="New CI type" onClick={() => setEdit({ code: "", name: "", description: "", parent_id: "" })} />
        </div>
      </div>
      {error && <ErrorBanner msg={error} />}
      {loading ? <Loading what="CI types" /> : types.length === 0 ? <Empty icon={Layers} title="No CI types yet" hint="Create a type (e.g. Server, Database) to start adding configuration items." /> : (
        <Table head={["Code", "Name", "Parent", "Description", ""]}>
          {types.map((t: any) => (
            <tr key={t.id} className="hover:bg-slate-50/60">
              <td className="px-4 py-2.5 font-mono text-xs text-slate-600">{t.code}</td>
              <td className="px-4 py-2.5 font-medium text-[var(--color-text)]">{t.name}</td>
              <td className="px-4 py-2.5 text-slate-600">{t.parent_id ? (byId.get(t.parent_id) as any)?.name || `#${t.parent_id}` : <span className="text-slate-300">—</span>}</td>
              <td className="max-w-xs truncate px-4 py-2.5 text-slate-500">{t.description || <span className="text-slate-300">—</span>}</td>
              <td className="px-4 py-2.5">
                <RowBtns>
                  <Btn icon={<ListChecks size={13} />} onClick={() => setAttrsFor(t)}>Attributes</Btn>
                  <Btn icon={<Pencil size={13} />} onClick={() => setEdit({ id: t.id, code: t.code || "", name: t.name || "", description: t.description || "", parent_id: t.parent_id ?? "" })}>Edit</Btn>
                </RowBtns>
              </td>
            </tr>
          ))}
        </Table>
      )}
      {edit && <TypeModal init={edit} types={types} onClose={() => setEdit(null)} onSaved={() => { setEdit(null); reload(); }} />}
      {attrsFor && <AttributesModal type={attrsFor} onClose={() => setAttrsFor(null)} />}
    </div>
  );
}

function TypeModal({ init, types, onClose, onSaved }: { init: any; types: any[]; onClose: () => void; onSaved: () => void }) {
  const [f, setF] = useState<any>(init);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const isEdit = !!init.id;
  const set = (p: any) => setF((x: any) => ({ ...x, ...p }));

  const save = async () => {
    if (!f.code.trim() || !f.name.trim()) { setErr("Code and name are required."); return; }
    setBusy(true); setErr(null);
    const body = { code: f.code.trim(), name: f.name.trim(), description: strOrNull(f.description), parent_id: intOrNull(f.parent_id) };
    const r = isEdit ? await cmdb("patch", `/types/${init.id}`, body) : await cmdb("post", "/types", body);
    setBusy(false);
    if (r.ok) onSaved(); else setErr(r.error || "Could not save the CI type.");
  };

  return (
    <Modal open onClose={onClose} title={isEdit ? "Edit CI type" : "New CI type"}
      footer={<>
        <Btn onClick={onClose}>Cancel</Btn>
        <Btn variant="primary" busy={busy} onClick={save}>{isEdit ? "Save changes" : "Create type"}</Btn>
      </>}>
      <div className="space-y-3">
        <FormError msg={err} />
        <Field label="Code" required hint="Unique short identifier, e.g. server"><Input value={f.code} onChange={(e) => set({ code: e.target.value })} placeholder="server" /></Field>
        <Field label="Name" required><Input value={f.name} onChange={(e) => set({ name: e.target.value })} placeholder="Server" /></Field>
        <Field label="Parent type">
          <Select value={f.parent_id === null ? "" : String(f.parent_id)} onChange={(e) => set({ parent_id: e.target.value })}>
            <option value="">None</option>
            {types.filter((t: any) => t.id !== init.id).map((t: any) => <option key={t.id} value={t.id}>{t.name}</option>)}
          </Select>
        </Field>
        <Field label="Description"><Textarea value={f.description} onChange={(e) => set({ description: e.target.value })} /></Field>
      </div>
    </Modal>
  );
}

function AttributesModal({ type, onClose }: { type: any; onClose: () => void }) {
  const { data, loading, error, reload } = useHd<any>(`${BASE}/types/${type.id}/attributes`);
  const attrs = asList(data, "attributes", "items");
  const blank = { name: "", datatype: "string", required: false, options: "" };
  const [f, setF] = useState<any>(blank);
  const [editId, setEditId] = useState<number | null>(null);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const set = (p: any) => setF((x: any) => ({ ...x, ...p }));

  const optionsOf = (a: any): string => (Array.isArray(a.options) ? a.options.join(", ") : a.options ? String(a.options) : "");

  const save = async () => {
    if (!f.name.trim()) { setErr("An attribute name is required."); return; }
    const opts = f.datatype === "enum" ? f.options.split(",").map((s: string) => s.trim()).filter(Boolean) : null;
    if (f.datatype === "enum" && (!opts || opts.length === 0)) { setErr("List the allowed values (comma separated) for an enum attribute."); return; }
    setBusy(true); setErr(null);
    const body = { name: f.name.trim(), datatype: f.datatype, required: !!f.required, options: opts };
    const r = editId ? await cmdb("patch", `/attributes/${editId}`, body) : await cmdb("post", `/types/${type.id}/attributes`, body);
    setBusy(false);
    if (r.ok) { setF(blank); setEditId(null); reload(); } else setErr(r.error || "Could not save the attribute.");
  };

  const remove = async (a: any) => {
    if (!window.confirm(`Delete attribute “${a.name}”? This cannot be undone.`)) return;
    setErr(null);
    const r = await cmdb("delete", `/attributes/${a.id}`);
    if (r.ok) reload(); else setErr(r.error || "Could not delete the attribute.");
  };

  return (
    <Modal open onClose={onClose} wide title={`Attributes — ${type.name}`} subtitle="Custom fields captured on every configuration item of this type"
      footer={<Btn onClick={onClose}>Close</Btn>}>
      <div className="space-y-4">
        <FormError msg={err} />
        {error && <ErrorBanner msg={error} />}
        {loading ? <Loading what="attributes" /> : attrs.length === 0 ? (
          <p className="text-sm text-slate-400">No attributes defined for this type yet.</p>
        ) : (
          <Table head={["Name", "Datatype", "Required", "Options", ""]}>
            {attrs.map((a: any) => (
              <tr key={a.id}>
                <td className="px-4 py-2 font-medium text-[var(--color-text)]">{a.name}</td>
                <td className="px-4 py-2 text-slate-600">{a.datatype}</td>
                <td className="px-4 py-2 text-slate-600">{a.required ? "Yes" : "No"}</td>
                <td className="max-w-[10rem] truncate px-4 py-2 text-slate-500">{optionsOf(a) || <span className="text-slate-300">—</span>}</td>
                <td className="px-4 py-2">
                  <RowBtns>
                    <Btn icon={<Pencil size={13} />} onClick={() => { setEditId(a.id); setErr(null); setF({ name: a.name || "", datatype: a.datatype || "string", required: !!a.required, options: optionsOf(a) }); }}>Edit</Btn>
                    <Btn variant="danger" icon={<Trash2 size={13} />} onClick={() => remove(a)}>Delete</Btn>
                  </RowBtns>
                </td>
              </tr>
            ))}
          </Table>
        )}
        <div className="space-y-3 rounded-xl border border-slate-200 bg-slate-50/50 p-4">
          <div className="text-[13px] font-semibold text-[#0F172A]">{editId ? "Edit attribute" : "Add attribute"}</div>
          <div className="grid gap-3 sm:grid-cols-2">
            <Field label="Name" required><Input value={f.name} onChange={(e) => set({ name: e.target.value })} placeholder="hostname" /></Field>
            <Field label="Datatype"><OptSelect value={f.datatype} options={DATATYPES} onChange={(v) => set({ datatype: v })} /></Field>
          </div>
          {f.datatype === "enum" && (
            <Field label="Allowed values" hint="Comma separated, e.g. gold, silver, bronze"><Input value={f.options} onChange={(e) => set({ options: e.target.value })} /></Field>
          )}
          <Toggle checked={!!f.required} onChange={(v) => set({ required: v })} label="Required" />
          <div className="flex gap-2">
            <Btn variant="primary" busy={busy} icon={editId ? undefined : <Plus size={14} />} onClick={save}>{editId ? "Save attribute" : "Add attribute"}</Btn>
            {editId && <Btn onClick={() => { setEditId(null); setF(blank); setErr(null); }}>Cancel edit</Btn>}
          </div>
        </div>
      </div>
    </Modal>
  );
}

// ── configuration items ─────────────────────────────────────────────────────
function CisTab() {
  const [typeFilter, setTypeFilter] = useState("");
  const [svcFilter, setSvcFilter] = useState("");
  const qs = [typeFilter && `ci_type_id=${encodeURIComponent(typeFilter)}`, svcFilter.trim() && `business_service_id=${encodeURIComponent(svcFilter.trim())}`].filter(Boolean).join("&");
  const { data, loading, error, reload } = useHd<any>(`${BASE}/cis${qs ? `?${qs}` : ""}`);
  const typesRes = useHd<any>(`${BASE}/types`);
  const cis = asList(data, "cis", "items");
  const types = asList(typesRes.data, "types", "items");
  const typeName = useMemo(() => new Map<any, any>(types.map((t: any) => [t.id, t.name] as [any, any])), [types]);
  const [edit, setEdit] = useState<any | null>(null);
  const [rowErr, setRowErr] = useState<string | null>(null);

  const retire = async (c: any) => {
    if (!window.confirm(`Retire “${c.name}”? It will be marked retired.`)) return;
    setRowErr(null);
    const r = await cmdb("post", `/cis/${c.id}/retire`);
    if (r.ok) reload(); else setRowErr(r.error || "Could not retire the configuration item.");
  };

  const blank = { code: "", name: "", ci_type_id: typeFilter, business_service_id: svcFilter.trim(), status: "active", criticality: "medium", environment: "production", owner: "", attributes: {} };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <div className="w-52">
            <Select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
              <option value="">All CI types</option>
              {types.map((t: any) => <option key={t.id} value={t.id}>{t.name}</option>)}
            </Select>
          </div>
          <div className="w-52">
            <Input type="number" min={0} value={svcFilter} onChange={(e) => setSvcFilter(e.target.value)} placeholder="Business service ID" />
          </div>
          <span className="text-sm text-slate-500">{cis.length} item{cis.length === 1 ? "" : "s"}</span>
        </div>
        <div className="flex items-center gap-2">
          <RefreshBtn onClick={reload} loading={loading} />
          <NewBtn label="New CI" onClick={() => setEdit(blank)} />
        </div>
      </div>
      {error && <ErrorBanner msg={error} />}
      {rowErr && <FormError msg={rowErr} />}
      {loading ? <Loading what="configuration items" /> : cis.length === 0 ? <Empty icon={Server} title="No configuration items" hint={qs ? "Try clearing the filters." : "Create a CI to start building the CMDB."} /> : (
        <Table head={["Code", "Name", "Type", "Service", "Status", "Criticality", "Environment", "Owner", ""]}>
          {cis.map((c: any) => (
            <tr key={c.id} className="hover:bg-slate-50/60">
              <td className="px-4 py-2.5 font-mono text-xs text-slate-600">{c.code}</td>
              <td className="px-4 py-2.5 font-medium text-[var(--color-text)]">{c.name}</td>
              <td className="px-4 py-2.5 text-slate-600">{(typeName.get(c.ci_type_id) as string) || (c.ci_type_id ? `#${c.ci_type_id}` : "—")}</td>
              <td className="px-4 py-2.5 text-slate-600">{c.business_service_id ? `#${c.business_service_id}` : <span className="text-slate-300">—</span>}</td>
              <td className="px-4 py-2.5"><Chip value={c.status} map={CI_STATUS_CHIP} /></td>
              <td className="px-4 py-2.5"><Chip value={c.criticality} map={CRIT_CHIP} /></td>
              <td className="px-4 py-2.5 text-slate-600">{c.environment || <span className="text-slate-300">—</span>}</td>
              <td className="px-4 py-2.5 text-slate-600">{c.owner || <span className="text-slate-300">—</span>}</td>
              <td className="px-4 py-2.5">
                <RowBtns>
                  <Btn icon={<Pencil size={13} />} onClick={() => setEdit({
                    id: c.id, code: c.code || "", name: c.name || "", ci_type_id: c.ci_type_id ?? "", business_service_id: c.business_service_id ?? "",
                    status: c.status || "active", criticality: c.criticality || "medium", environment: c.environment || "", owner: c.owner || "",
                    attributes: c.attributes && typeof c.attributes === "object" ? c.attributes : {},
                  })}>Edit</Btn>
                  <Btn variant="danger" icon={<Ban size={13} />} disabled={(c.status || "").toLowerCase() === "retired"} onClick={() => retire(c)}>Retire</Btn>
                </RowBtns>
              </td>
            </tr>
          ))}
        </Table>
      )}
      {edit && <CiModal init={edit} types={types} onClose={() => setEdit(null)} onSaved={() => { setEdit(null); reload(); }} />}
    </div>
  );
}

function CiModal({ init, types, onClose, onSaved }: { init: any; types: any[]; onClose: () => void; onSaved: () => void }) {
  const [f, setF] = useState<any>(init);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const isEdit = !!init.id;
  const set = (p: any) => setF((x: any) => ({ ...x, ...p }));
  const typeId = f.ci_type_id === "" || f.ci_type_id == null ? null : Number(f.ci_type_id);
  const attrRes = useHd<any>(typeId ? `${BASE}/types/${typeId}/attributes` : `${BASE}/types`);
  const defs = typeId ? asList(attrRes.data, "attributes", "items") : [];
  const setAttr = (name: string, v: any) => setF((x: any) => ({ ...x, attributes: { ...(x.attributes || {}), [name]: v } }));

  const save = async () => {
    if (!f.code.trim() || !f.name.trim()) { setErr("Code and name are required."); return; }
    if (!typeId) { setErr("Choose a CI type."); return; }
    const missing = defs.filter((d: any) => d.required && (f.attributes?.[d.name] === undefined || f.attributes?.[d.name] === "" || f.attributes?.[d.name] === null));
    if (missing.length) { setErr(`Required attribute${missing.length === 1 ? "" : "s"}: ${missing.map((d: any) => d.name).join(", ")}`); return; }
    // keep only filled-in attribute values
    const attributes: Record<string, any> = {};
    Object.entries(f.attributes || {}).forEach(([k, v]) => { if (v !== "" && v !== undefined && v !== null) attributes[k] = v; });
    setBusy(true); setErr(null);
    const body = {
      code: f.code.trim(), name: f.name.trim(), ci_type_id: typeId, business_service_id: intOrNull(f.business_service_id),
      status: f.status, criticality: f.criticality, environment: strOrNull(f.environment), owner: strOrNull(f.owner), attributes,
    };
    const r = isEdit ? await cmdb("patch", `/cis/${init.id}`, body) : await cmdb("post", "/cis", body);
    setBusy(false);
    if (r.ok) onSaved(); else setErr(r.error || "Could not save the configuration item.");
  };

  const attrInput = (d: any) => {
    const v = f.attributes?.[d.name];
    if (d.datatype === "boolean") {
      return <Select value={v === true ? "true" : v === false ? "false" : ""} onChange={(e) => setAttr(d.name, e.target.value === "" ? "" : e.target.value === "true")}>
        <option value="">—</option><option value="true">Yes</option><option value="false">No</option>
      </Select>;
    }
    if (d.datatype === "enum" && Array.isArray(d.options)) {
      return <OptSelect value={v ?? ""} options={d.options} blank="—" onChange={(x) => setAttr(d.name, x)} />;
    }
    if (d.datatype === "number") return <Input type="number" value={v ?? ""} onChange={(e) => setAttr(d.name, e.target.value === "" ? "" : Number(e.target.value))} />;
    if (d.datatype === "date") return <Input type="date" value={v ?? ""} onChange={(e) => setAttr(d.name, e.target.value)} />;
    return <Input value={v ?? ""} onChange={(e) => setAttr(d.name, e.target.value)} />;
  };

  return (
    <Modal open wide onClose={onClose} title={isEdit ? "Edit configuration item" : "New configuration item"}
      footer={<>
        <Btn onClick={onClose}>Cancel</Btn>
        <Btn variant="primary" busy={busy} onClick={save}>{isEdit ? "Save changes" : "Create CI"}</Btn>
      </>}>
      <div className="space-y-3">
        <FormError msg={err} />
        <div className="grid gap-3 sm:grid-cols-2">
          <Field label="Code" required><Input value={f.code} onChange={(e) => set({ code: e.target.value })} placeholder="srv-web-01" /></Field>
          <Field label="Name" required><Input value={f.name} onChange={(e) => set({ name: e.target.value })} placeholder="Web server 01" /></Field>
          <Field label="CI type" required>
            <Select value={f.ci_type_id === null ? "" : String(f.ci_type_id)} onChange={(e) => set({ ci_type_id: e.target.value, attributes: {} })}>
              <option value="">Select a type…</option>
              {types.map((t: any) => <option key={t.id} value={t.id}>{t.name}</option>)}
            </Select>
          </Field>
          <Field label="Business service ID" hint="Optional"><Input type="number" min={0} value={f.business_service_id ?? ""} onChange={(e) => set({ business_service_id: e.target.value })} /></Field>
          <Field label="Status"><OptSelect value={f.status} options={STATUSES} onChange={(v) => set({ status: v })} /></Field>
          <Field label="Criticality"><OptSelect value={f.criticality} options={CRITICALITIES} onChange={(v) => set({ criticality: v })} /></Field>
          <Field label="Environment"><OptSelect value={f.environment} options={ENVIRONMENTS} blank="Not set" onChange={(v) => set({ environment: v })} /></Field>
          <Field label="Owner"><Input value={f.owner} onChange={(e) => set({ owner: e.target.value })} placeholder="Name or email" /></Field>
        </div>
        {typeId && (
          <div className="space-y-3 rounded-xl border border-slate-200 bg-slate-50/50 p-4">
            <div className="text-[13px] font-semibold text-[#0F172A]">Type attributes</div>
            {attrRes.loading ? <p className="text-sm text-slate-400">Loading attributes…</p> : defs.length === 0 ? (
              <p className="text-sm text-slate-400">This type has no custom attributes.</p>
            ) : (
              <div className="grid gap-3 sm:grid-cols-2">
                {defs.map((d: any) => <Field key={d.id ?? d.name} label={d.name} required={!!d.required}>{attrInput(d)}</Field>)}
              </div>
            )}
          </div>
        )}
      </div>
    </Modal>
  );
}

// ── relationship types ──────────────────────────────────────────────────────
function RelTypesTab() {
  const { data, loading, error, reload } = useHd<any>(`${BASE}/relationship-types`);
  const rows = asList(data, "relationship_types", "types", "items");
  const [edit, setEdit] = useState<any | null>(null);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-2">
        <p className="text-sm text-slate-500">{rows.length} relationship type{rows.length === 1 ? "" : "s"}</p>
        <div className="flex items-center gap-2">
          <RefreshBtn onClick={reload} loading={loading} />
          <NewBtn label="New relationship type" onClick={() => setEdit({ code: "", name: "", inverse_name: "" })} />
        </div>
      </div>
      {error && <ErrorBanner msg={error} />}
      {loading ? <Loading what="relationship types" /> : rows.length === 0 ? <Empty icon={GitBranch} title="No relationship types yet" hint="Define how CIs relate, e.g. “depends on” / “is depended on by”." /> : (
        <Table head={["Code", "Name", "Inverse name", ""]}>
          {rows.map((r: any) => (
            <tr key={r.id} className="hover:bg-slate-50/60">
              <td className="px-4 py-2.5 font-mono text-xs text-slate-600">{r.code}</td>
              <td className="px-4 py-2.5 font-medium text-[var(--color-text)]">{r.name}</td>
              <td className="px-4 py-2.5 text-slate-600">{r.inverse_name || <span className="text-slate-300">—</span>}</td>
              <td className="px-4 py-2.5">
                <RowBtns><Btn icon={<Pencil size={13} />} onClick={() => setEdit({ id: r.id, code: r.code || "", name: r.name || "", inverse_name: r.inverse_name || "" })}>Edit</Btn></RowBtns>
              </td>
            </tr>
          ))}
        </Table>
      )}
      {edit && <RelTypeModal init={edit} onClose={() => setEdit(null)} onSaved={() => { setEdit(null); reload(); }} />}
    </div>
  );
}

function RelTypeModal({ init, onClose, onSaved }: { init: any; onClose: () => void; onSaved: () => void }) {
  const [f, setF] = useState<any>(init);
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const isEdit = !!init.id;
  const set = (p: any) => setF((x: any) => ({ ...x, ...p }));

  const save = async () => {
    if (!f.code.trim() || !f.name.trim()) { setErr("Code and name are required."); return; }
    setBusy(true); setErr(null);
    const body = { code: f.code.trim(), name: f.name.trim(), inverse_name: strOrNull(f.inverse_name) };
    const r = isEdit ? await cmdb("patch", `/relationship-types/${init.id}`, body) : await cmdb("post", "/relationship-types", body);
    setBusy(false);
    if (r.ok) onSaved(); else setErr(r.error || "Could not save the relationship type.");
  };

  return (
    <Modal open onClose={onClose} title={isEdit ? "Edit relationship type" : "New relationship type"}
      footer={<>
        <Btn onClick={onClose}>Cancel</Btn>
        <Btn variant="primary" busy={busy} onClick={save}>{isEdit ? "Save changes" : "Create type"}</Btn>
      </>}>
      <div className="space-y-3">
        <FormError msg={err} />
        <Field label="Code" required hint="Unique short identifier, e.g. depends_on"><Input value={f.code} onChange={(e) => set({ code: e.target.value })} /></Field>
        <Field label="Name" required hint="Reads source → target, e.g. depends on"><Input value={f.name} onChange={(e) => set({ name: e.target.value })} /></Field>
        <Field label="Inverse name" hint="Reads target → source, e.g. is depended on by"><Input value={f.inverse_name} onChange={(e) => set({ inverse_name: e.target.value })} /></Field>
      </div>
    </Modal>
  );
}

// ── relationships ───────────────────────────────────────────────────────────
function RelsTab() {
  const { data, loading, error, reload } = useHd<any>(`${BASE}/relationships`);
  const cisRes = useHd<any>(`${BASE}/cis`);
  const rtRes = useHd<any>(`${BASE}/relationship-types`);
  const rels = asList(data, "relationships", "items");
  const cis = asList(cisRes.data, "cis", "items");
  const relTypes = asList(rtRes.data, "relationship_types", "types", "items");
  const ciName = useMemo(() => new Map<any, any>(cis.map((c: any) => [c.id, c.name || c.code] as [any, any])), [cis]);
  const rtName = useMemo(() => new Map<any, any>(relTypes.map((t: any) => [t.id, t.name] as [any, any])), [relTypes]);
  const [adding, setAdding] = useState(false);
  const [rowErr, setRowErr] = useState<string | null>(null);

  const remove = async (r: any) => {
    if (!window.confirm("Delete this relationship? This cannot be undone.")) return;
    setRowErr(null);
    const res = await cmdb("delete", `/relationships/${r.id}`);
    if (res.ok) reload(); else setRowErr(res.error || "Could not delete the relationship.");
  };

  const nm = (id: any) => (ciName.get(id) as string) || (id != null ? `#${id}` : "—");

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between gap-2">
        <p className="text-sm text-slate-500">{rels.length} relationship{rels.length === 1 ? "" : "s"}</p>
        <div className="flex items-center gap-2">
          <RefreshBtn onClick={() => { reload(); cisRes.reload(); rtRes.reload(); }} loading={loading} />
          <NewBtn label="New relationship" onClick={() => setAdding(true)} />
        </div>
      </div>
      {error && <ErrorBanner msg={error} />}
      {rowErr && <FormError msg={rowErr} />}
      {loading ? <Loading what="relationships" /> : rels.length === 0 ? <Empty icon={Link2} title="No relationships yet" hint="Link two configuration items with a relationship type." /> : (
        <Table head={["Source", "Relationship", "Target", ""]}>
          {rels.map((r: any) => (
            <tr key={r.id} className="hover:bg-slate-50/60">
              <td className="px-4 py-2.5 font-medium text-[var(--color-text)]">{r.source_name || nm(r.source_ci_id)}</td>
              <td className="px-4 py-2.5"><span className="rounded-full bg-indigo-50 px-2 py-0.5 text-xs font-medium text-indigo-700">{r.rel_name || r.rel_type_name || (rtName.get(r.rel_type_id) as string) || `#${r.rel_type_id}`}</span></td>
              <td className="px-4 py-2.5 font-medium text-[var(--color-text)]">{r.target_name || nm(r.target_ci_id)}</td>
              <td className="px-4 py-2.5"><RowBtns><Btn variant="danger" icon={<Trash2 size={13} />} onClick={() => remove(r)}>Delete</Btn></RowBtns></td>
            </tr>
          ))}
        </Table>
      )}
      {adding && <RelModal cis={cis} relTypes={relTypes} onClose={() => setAdding(false)} onSaved={() => { setAdding(false); reload(); }} />}
    </div>
  );
}

function RelModal({ cis, relTypes, onClose, onSaved }: { cis: any[]; relTypes: any[]; onClose: () => void; onSaved: () => void }) {
  const [f, setF] = useState<any>({ source_ci_id: "", target_ci_id: "", rel_type_id: "" });
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);
  const set = (p: any) => setF((x: any) => ({ ...x, ...p }));

  const save = async () => {
    if (!f.source_ci_id || !f.target_ci_id || !f.rel_type_id) { setErr("Choose a source, a target and a relationship type."); return; }
    if (f.source_ci_id === f.target_ci_id) { setErr("Source and target must be different configuration items."); return; }
    setBusy(true); setErr(null);
    const r = await cmdb("post", "/relationships", { source_ci_id: Number(f.source_ci_id), target_ci_id: Number(f.target_ci_id), rel_type_id: Number(f.rel_type_id) });
    setBusy(false);
    if (r.ok) onSaved(); else setErr(r.error || "Could not create the relationship.");
  };

  const ciOpts = (
    <>
      <option value="">Select a CI…</option>
      {cis.map((c: any) => <option key={c.id} value={c.id}>{c.name}{c.code ? ` (${c.code})` : ""}</option>)}
    </>
  );

  return (
    <Modal open onClose={onClose} title="New relationship"
      footer={<>
        <Btn onClick={onClose}>Cancel</Btn>
        <Btn variant="primary" busy={busy} onClick={save}>Create relationship</Btn>
      </>}>
      <div className="space-y-3">
        <FormError msg={err} />
        <Field label="Source CI" required><Select value={f.source_ci_id} onChange={(e) => set({ source_ci_id: e.target.value })}>{ciOpts}</Select></Field>
        <Field label="Relationship type" required>
          <Select value={f.rel_type_id} onChange={(e) => set({ rel_type_id: e.target.value })}>
            <option value="">Select a type…</option>
            {relTypes.map((t: any) => <option key={t.id} value={t.id}>{t.name}</option>)}
          </Select>
        </Field>
        <Field label="Target CI" required><Select value={f.target_ci_id} onChange={(e) => set({ target_ci_id: e.target.value })}>{ciOpts}</Select></Field>
      </div>
    </Modal>
  );
}

// ── graph (grouped nodes + outgoing edges) ──────────────────────────────────
function GraphTab() {
  const { data, loading, error, reload } = useHd<any>(`${BASE}/graph`);
  const typesRes = useHd<any>(`${BASE}/types`);
  const nodes = asList(data?.nodes ?? [], "nodes");
  const edges = asList(data?.edges ?? [], "edges");
  const types = asList(typesRes.data, "types", "items");
  const typeName = useMemo(() => new Map<any, any>(types.map((t: any) => [t.id, t.name] as [any, any])), [types]);
  const nodeById = useMemo(() => new Map<any, any>(nodes.map((n: any) => [n.id, n] as [any, any])), [nodes]);
  const [q, setQ] = useState("");

  const outgoing = useMemo(() => {
    const m = new Map<any, any[]>();
    edges.forEach((e: any) => m.set(e.source, [...(m.get(e.source) || []), e]));
    return m;
  }, [edges]);
  const incomingCount = useMemo(() => {
    const m = new Map<any, number>();
    edges.forEach((e: any) => m.set(e.target, (m.get(e.target) || 0) + 1));
    return m;
  }, [edges]);

  const groups = useMemo(() => {
    const s = q.toLowerCase();
    const m = new Map<string, any[]>();
    nodes.filter((n: any) => !s || [n.name, n.code].some((v) => (v || "").toLowerCase().includes(s)))
      .forEach((n: any) => { const t = (typeName.get(n.ci_type_id) as string) || "Untyped"; m.set(t, [...(m.get(t) || []), n]); });
    return Array.from(m.entries()).sort((a, b) => a[0].localeCompare(b[0]));
  }, [nodes, typeName, q]);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <p className="text-sm text-slate-500">{nodes.length} node{nodes.length === 1 ? "" : "s"} · {edges.length} edge{edges.length === 1 ? "" : "s"}</p>
        <div className="flex items-center gap-2">
          <div className="w-64"><Input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Filter nodes…" /></div>
          <RefreshBtn onClick={() => { reload(); typesRes.reload(); }} loading={loading} />
        </div>
      </div>
      {error && <ErrorBanner msg={error} />}
      {loading ? <Loading what="graph" /> : groups.length === 0 ? <Empty icon={Network} title="Nothing to show" hint={q ? "Try a different filter." : "Add configuration items and relationships to see the graph."} /> : (
        <div className="space-y-6">
          {groups.map(([tname, list]) => (
            <section key={tname}>
              <div className="mb-2 flex items-center gap-2">
                <h2 className="text-base font-semibold text-[var(--color-text)]">{tname}</h2>
                <span className="rounded-full bg-slate-100 px-2 py-0.5 text-xs text-slate-500">{list.length}</span>
              </div>
              <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
                {list.map((n: any) => {
                  const out = outgoing.get(n.id) || [];
                  return (
                    <div key={n.id} className="rounded-xl border border-slate-200 bg-white p-4">
                      <div className="flex items-start gap-3">
                        <Server size={18} className="mt-0.5 shrink-0 text-slate-400" />
                        <div className="min-w-0 flex-1">
                          <div className="truncate font-medium text-[var(--color-text)]">{n.name || n.code}</div>
                          <div className="mt-0.5 truncate font-mono text-xs text-slate-400">{n.code}</div>
                        </div>
                        <Chip value={n.status} map={CI_STATUS_CHIP} />
                      </div>
                      <div className="mt-3 space-y-1.5 border-t border-slate-100 pt-3 text-xs">
                        {out.length === 0 ? <div className="text-slate-300">No outgoing relationships</div> : out.map((e: any) => {
                          const t = nodeById.get(e.target) as any;
                          return (
                            <div key={e.id} className="flex items-center gap-1.5">
                              <span className="shrink-0 rounded-full bg-indigo-50 px-2 py-0.5 font-medium text-indigo-700">{e.rel_name || `#${e.rel_type_id}`}</span>
                              <span className="text-slate-400">→</span>
                              <span className="truncate text-slate-700">{t ? (t.name || t.code) : `#${e.target}`}</span>
                            </div>
                          );
                        })}
                        {(incomingCount.get(n.id) || 0) > 0 && <div className="pt-1 text-slate-400">{incomingCount.get(n.id)} incoming</div>}
                      </div>
                    </div>
                  );
                })}
              </div>
            </section>
          ))}
        </div>
      )}
    </div>
  );
}
