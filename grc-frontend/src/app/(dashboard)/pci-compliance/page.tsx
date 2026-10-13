"use client";

/**
 * PCI-DSS 4.0.1 compliance — real requirements derived from the SCF crosswalk,
 * per-requirement coverage tracked by assessment + evidence. The requirement
 * list and the control activities under each requirement come straight from the
 * crosswalk; only the assessment state (status / note / evidence) is stored.
 */

import { useMemo, useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  ShieldCheck,
  ChevronRight,
  Plus,
  X,
  ExternalLink,
  Check,
  Loader2,
} from "lucide-react";
import { pciComplianceApi } from "@/lib/api";

type Status = "met" | "partial" | "gap" | "not_applicable" | "not_assessed";

interface Cov {
  total: number;
  applicable: number;
  met: number;
  partial: number;
  gap: number;
  not_applicable: number;
  not_assessed: number;
  coverage_pct: number;
  assessed_pct: number;
}
interface Group extends Cov {
  id: string;
  title: string;
}
interface Overview {
  framework: string;
  source: string;
  overall: Cov;
  groups: Group[];
}
interface Control {
  scf_id: string;
  name: string;
  domain?: string;
  description?: string;
}
interface Evidence {
  label?: string;
  url?: string;
}
interface Requirement {
  code: string;
  group: string;
  controls: Control[];
  status: Status;
  note: string | null;
  evidence: Evidence[] | null;
  assessed_by: string | null;
  assessed_at: string | null;
}

const STATUS_META: Record<Status, { label: string; text: string; chip: string; seg: string }> = {
  met: { label: "Met", text: "text-emerald-700", chip: "bg-emerald-50 text-emerald-700 border-emerald-200", seg: "bg-emerald-500" },
  partial: { label: "Partial", text: "text-amber-700", chip: "bg-amber-50 text-amber-700 border-amber-200", seg: "bg-amber-400" },
  gap: { label: "Gap", text: "text-rose-700", chip: "bg-rose-50 text-rose-700 border-rose-200", seg: "bg-rose-500" },
  not_applicable: { label: "N/A", text: "text-slate-500", chip: "bg-slate-100 text-slate-600 border-slate-200", seg: "bg-slate-300" },
  not_assessed: { label: "Not assessed", text: "text-slate-400", chip: "bg-white text-slate-500 border-slate-200", seg: "bg-slate-200" },
};
const STATUS_ORDER: Status[] = ["met", "partial", "gap", "not_applicable", "not_assessed"];

function Ring({ pct, size = 112 }: { pct: number; size?: number }) {
  const stroke = 9;
  const r = (size - stroke) / 2;
  const c = 2 * Math.PI * r;
  const off = c - (Math.min(100, Math.max(0, pct)) / 100) * c;
  return (
    <svg width={size} height={size} className="-rotate-90">
      <circle cx={size / 2} cy={size / 2} r={r} fill="none" stroke="#e2e8f0" strokeWidth={stroke} />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={r}
        fill="none"
        stroke="var(--color-base)"
        strokeWidth={stroke}
        strokeLinecap="round"
        strokeDasharray={c}
        strokeDashoffset={off}
        style={{ transition: "stroke-dashoffset .5s ease" }}
      />
    </svg>
  );
}

function StackBar({ cov, className = "" }: { cov: Cov; className?: string }) {
  const segs = STATUS_ORDER.map((s) => ({ s, n: (cov as any)[s] as number })).filter((x) => x.n > 0);
  return (
    <div className={`flex h-2 w-full overflow-hidden rounded-full bg-slate-100 ${className}`}>
      {segs.map(({ s, n }) => (
        <div
          key={s}
          className={STATUS_META[s].seg}
          style={{ width: `${(n / cov.total) * 100}%` }}
          title={`${STATUS_META[s].label}: ${n}`}
        />
      ))}
    </div>
  );
}

const Btn = "inline-flex items-center gap-1.5 rounded-lg border px-2.5 py-1 text-[12px] font-medium transition-colors";

export default function PciCompliancePage() {
  const qc = useQueryClient();
  const [activeGroup, setActiveGroup] = useState<string>("1");
  const [expanded, setExpanded] = useState<string | null>(null);

  const ovQ = useQuery<Overview>({
    queryKey: ["pci-overview"],
    queryFn: () => pciComplianceApi.overview().then((r) => r.data),
  });
  const reqQ = useQuery<{ requirements: Requirement[] }>({
    queryKey: ["pci-requirements", activeGroup],
    queryFn: () => pciComplianceApi.requirements(activeGroup).then((r) => r.data),
  });

  const invalidate = () => {
    qc.invalidateQueries({ queryKey: ["pci-overview"] });
    qc.invalidateQueries({ queryKey: ["pci-requirements", activeGroup] });
  };

  const assessMut = useMutation({
    mutationFn: (b: { requirement_code: string; status: Status; note?: string | null; evidence?: Evidence[] | null }) =>
      pciComplianceApi.assess(b),
    onSuccess: invalidate,
  });
  const bulkMut = useMutation({
    mutationFn: (b: { group: string; status: Status }) => pciComplianceApi.bulk(b.group, b.status),
    onSuccess: invalidate,
  });

  const ov = ovQ.data;
  const activeGroupMeta = useMemo(() => ov?.groups.find((g) => g.id === activeGroup), [ov, activeGroup]);

  return (
    <div className="space-y-5">
      {/* Summary band */}
      <section className="rounded-xl border border-slate-200 bg-white p-5">
        {!ov ? (
          <div className="flex h-28 items-center justify-center text-slate-400">
            <Loader2 className="h-5 w-5 animate-spin" />
          </div>
        ) : (
          <div className="flex flex-wrap items-center gap-6">
            <div className="relative flex items-center justify-center" style={{ width: 112, height: 112 }}>
              <Ring pct={ov.overall.coverage_pct} />
              <div className="absolute flex flex-col items-center">
                <span className="text-2xl font-bold text-[var(--color-text)]">{ov.overall.coverage_pct}%</span>
                <span className="text-[10px] font-medium uppercase tracking-wide text-slate-400">covered</span>
              </div>
            </div>
            <div className="min-w-[260px] flex-1">
              <div className="flex items-center gap-2 text-[var(--color-text)]">
                <ShieldCheck className="h-5 w-5 text-[var(--color-base)]" />
                <h2 className="text-base font-semibold">{ov.framework}</h2>
              </div>
              <p className="mt-0.5 text-[12px] text-slate-500">
                {ov.overall.total} requirements · {ov.overall.assessed_pct}% assessed · coverage = fully-met of applicable
              </p>
              <StackBar cov={ov.overall} className="mt-3" />
              <div className="mt-2.5 flex flex-wrap gap-x-4 gap-y-1">
                {STATUS_ORDER.map((s) => (
                  <span key={s} className="inline-flex items-center gap-1.5 text-[12px] text-slate-600">
                    <span className={`inline-block h-2.5 w-2.5 rounded-sm ${STATUS_META[s].seg}`} />
                    {STATUS_META[s].label}
                    <span className="font-semibold text-[var(--color-text)]">{(ov.overall as any)[s]}</span>
                  </span>
                ))}
              </div>
            </div>
          </div>
        )}
      </section>

      {/* Requirement groups */}
      <section>
        <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-3 lg:grid-cols-5">
          {ov?.groups.map((g) => {
            const active = g.id === activeGroup;
            return (
              <button
                key={g.id}
                onClick={() => {
                  setActiveGroup(g.id);
                  setExpanded(null);
                }}
                className={`rounded-xl border p-3 text-left transition-all ${
                  active ? "border-[var(--color-base)] ring-1 ring-[var(--color-base)] bg-[var(--color-base)]/[0.04]" : "border-slate-200 bg-white hover:border-slate-300"
                }`}
              >
                <div className="flex items-center justify-between">
                  <span className="rounded-md bg-slate-100 px-1.5 py-0.5 text-[11px] font-bold text-slate-600">
                    {g.id.startsWith("A") ? g.id : `Req ${g.id}`}
                  </span>
                  <span className="text-[13px] font-bold text-[var(--color-text)]">{g.coverage_pct}%</span>
                </div>
                <p className="mt-1.5 line-clamp-2 min-h-[32px] text-[11.5px] leading-tight text-slate-600">{g.title}</p>
                <StackBar cov={g} className="mt-2" />
                <p className="mt-1 text-[10.5px] text-slate-400">
                  {g.met}/{g.applicable} met{g.not_applicable ? ` · ${g.not_applicable} N/A` : ""}
                </p>
              </button>
            );
          })}
        </div>
      </section>

      {/* Active group requirements */}
      <section className="rounded-xl border border-slate-200 bg-white">
        <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 px-4 py-3">
          <div>
            <h3 className="text-[13px] font-semibold text-[var(--color-text)]">
              {activeGroupMeta?.id?.startsWith("A") ? "Appendix " + activeGroupMeta?.id : "Requirement " + activeGroup}
              <span className="ml-2 font-normal text-slate-500">{activeGroupMeta?.title}</span>
            </h3>
            <p className="mt-0.5 text-[11.5px] text-slate-400">{reqQ.data?.requirements.length ?? "…"} sub-requirements</p>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="mr-1 text-[11px] text-slate-400">Set all:</span>
            {(["met", "not_applicable", "not_assessed"] as Status[]).map((s) => (
              <button
                key={s}
                disabled={bulkMut.isPending}
                onClick={() => bulkMut.mutate({ group: activeGroup, status: s })}
                className={`${Btn} ${STATUS_META[s].chip} hover:brightness-95 disabled:opacity-50`}
              >
                {STATUS_META[s].label}
              </button>
            ))}
          </div>
        </div>

        <div className="divide-y divide-slate-100">
          {reqQ.isLoading && (
            <div className="flex h-24 items-center justify-center text-slate-400">
              <Loader2 className="h-5 w-5 animate-spin" />
            </div>
          )}
          {reqQ.data?.requirements.map((req) => (
            <RequirementRow
              key={req.code}
              req={req}
              open={expanded === req.code}
              onToggle={() => setExpanded((c) => (c === req.code ? null : req.code))}
              onAssess={(status, note, evidence) =>
                assessMut.mutate({ requirement_code: req.code, status, note, evidence })
              }
              saving={assessMut.isPending && assessMut.variables?.requirement_code === req.code}
            />
          ))}
        </div>
      </section>
    </div>
  );
}

function RequirementRow({
  req,
  open,
  onToggle,
  onAssess,
  saving,
}: {
  req: Requirement;
  open: boolean;
  onToggle: () => void;
  onAssess: (status: Status, note: string | null, evidence: Evidence[] | null) => void;
  saving: boolean;
}) {
  const [note, setNote] = useState(req.note ?? "");
  const [evidence, setEvidence] = useState<Evidence[]>(req.evidence ?? []);
  const [evLabel, setEvLabel] = useState("");
  const [evUrl, setEvUrl] = useState("");

  const m = STATUS_META[req.status];
  const controlNames = req.controls.map((c) => c.name).filter(Boolean);

  return (
    <div className="px-4 py-2.5">
      <div className="flex items-center gap-3">
        <button onClick={onToggle} className="flex min-w-0 flex-1 items-center gap-3 text-left">
          <ChevronRight className={`h-4 w-4 flex-shrink-0 text-slate-400 transition-transform ${open ? "rotate-90" : ""}`} />
          <span className="w-16 flex-shrink-0 font-mono text-[12.5px] font-bold text-[var(--color-text)]">{req.code}</span>
          <span className="min-w-0 flex-1 truncate text-[12.5px] text-slate-600">
            <span className="text-slate-400">Control activities: </span>
            {controlNames.slice(0, 3).join(", ")}
            {controlNames.length > 3 ? ` +${controlNames.length - 3}` : ""}
          </span>
        </button>
        <span className={`hidden flex-shrink-0 rounded-full border px-2 py-0.5 text-[11px] font-medium sm:inline ${m.chip}`}>
          {m.label}
        </span>
        <select
          value={req.status}
          onChange={(e) => onAssess(e.target.value as Status, req.note, req.evidence)}
          className="flex-shrink-0 rounded-lg border border-slate-200 bg-white px-2 py-1 text-[12px] font-medium text-slate-700 focus:border-[var(--color-base)] focus:outline-none"
        >
          {STATUS_ORDER.map((s) => (
            <option key={s} value={s}>
              {STATUS_META[s].label}
            </option>
          ))}
        </select>
      </div>

      {open && (
        <div className="ml-7 mt-3 space-y-3 border-l-2 border-slate-100 pl-4">
          <div>
            <p className="mb-1 text-[11px] font-semibold uppercase tracking-wide text-slate-400">
              Mapped SCF control activities ({req.controls.length})
            </p>
            <ul className="space-y-1">
              {req.controls.map((c) => (
                <li key={c.scf_id} className="text-[12px] text-slate-600">
                  <span className="font-medium text-slate-700">{c.name}</span>
                  {c.domain ? <span className="text-slate-400"> — {c.domain}</span> : null}
                </li>
              ))}
            </ul>
          </div>

          <div>
            <p className="mb-1 text-[11px] font-semibold uppercase tracking-wide text-slate-400">Assessment note</p>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              rows={2}
              placeholder="How is this requirement met? Reference the control, owner, ticket…"
              className="w-full resize-y rounded-lg border border-slate-200 px-2.5 py-1.5 text-[12.5px] text-slate-700 focus:border-[var(--color-base)] focus:outline-none"
            />
          </div>

          <div>
            <p className="mb-1 text-[11px] font-semibold uppercase tracking-wide text-slate-400">Evidence</p>
            {evidence.length > 0 && (
              <ul className="mb-2 space-y-1">
                {evidence.map((ev, i) => (
                  <li key={i} className="flex items-center gap-2 text-[12px]">
                    {ev.url ? (
                      <a href={ev.url} target="_blank" rel="noreferrer" className="inline-flex items-center gap-1 text-[var(--color-base)] hover:underline">
                        <ExternalLink className="h-3 w-3" />
                        {ev.label || ev.url}
                      </a>
                    ) : (
                      <span className="text-slate-600">{ev.label}</span>
                    )}
                    <button onClick={() => setEvidence((x) => x.filter((_, j) => j !== i))} className="text-slate-300 hover:text-rose-500">
                      <X className="h-3.5 w-3.5" />
                    </button>
                  </li>
                ))}
              </ul>
            )}
            <div className="flex flex-wrap items-center gap-2">
              <input
                value={evLabel}
                onChange={(e) => setEvLabel(e.target.value)}
                placeholder="Label (e.g. Firewall review Q3)"
                className="w-48 rounded-lg border border-slate-200 px-2 py-1 text-[12px] focus:border-[var(--color-base)] focus:outline-none"
              />
              <input
                value={evUrl}
                onChange={(e) => setEvUrl(e.target.value)}
                placeholder="Link (optional)"
                className="w-56 rounded-lg border border-slate-200 px-2 py-1 text-[12px] focus:border-[var(--color-base)] focus:outline-none"
              />
              <button
                disabled={!evLabel && !evUrl}
                onClick={() => {
                  setEvidence((x) => [...x, { label: evLabel || undefined, url: evUrl || undefined }]);
                  setEvLabel("");
                  setEvUrl("");
                }}
                className={`${Btn} border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-40`}
              >
                <Plus className="h-3.5 w-3.5" /> Add
              </button>
            </div>
          </div>

          <div className="flex items-center gap-3 pt-1">
            <button
              disabled={saving}
              onClick={() => onAssess(req.status, note, evidence)}
              className={`${Btn} border-[var(--color-base)] bg-[var(--color-base)] text-white hover:brightness-95 disabled:opacity-50`}
            >
              {saving ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Check className="h-3.5 w-3.5" />}
              Save note & evidence
            </button>
            {req.assessed_by && (
              <span className="text-[11px] text-slate-400">
                Last assessed by {req.assessed_by}
                {req.assessed_at ? ` · ${new Date(req.assessed_at).toLocaleDateString()}` : ""}
              </span>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
