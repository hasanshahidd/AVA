"use client";

/**
 * Help Desk analytics widgets, drawn in the AVA Performance-dashboard visual
 * language: the same card shell, tokens, KPI tiles, stacked-bar breakdowns and
 * empty/loading states as (dashboard)/dashboard. We reuse that page's `kit`
 * (the product design system) rather than re-inventing one, and recharts (real
 * on the client, mocked on the server — see next.config.js) only for the one
 * genuinely time-series widget: the created-vs-resolved trend.
 */
import Link from "next/link";
import { useMemo, type ReactNode } from "react";
import { ArrowDownRight, ArrowUpRight, Minus, Star } from "lucide-react";
import {
  Area, CartesianGrid, ComposedChart, Legend, Line, ResponsiveContainer, Tooltip, XAxis, YAxis,
} from "recharts";
import { CARD_SHADOW, Card, SEV, T, alpha, nfmt, type Tone } from "../dashboard/_components/kit";
import { PartLegend, StackBar, type Part } from "../dashboard/_components/charts";

/* ---------- tokens shared with the breakdowns ---------- */
export const ACCENT = T.base;
// Categorical palette for non-ordinal breakdowns (team / type), CVD-spaced.
const CAT = ["#005B96", "#0E7490", "#7C3AED", "#B45309", "#047857", "#BE123C", "#2563EB", "#64748B"];
// Priority maps onto the severity scale; status onto Open/Resolved/Paused tones.
const PRIORITY_TONE: Record<string, Tone> = {
  urgent: SEV.critical, high: SEV.high, medium: SEV.medium, low: SEV.low,
};
const STATUS_TONE: Record<string, Tone> = {
  open: { label: "Open", c: "#2563EB", ink: "#1D4ED8", bg: "#E9F0FE" },
  resolved: { label: "Resolved", c: "#047857", ink: "#047857", bg: "#E7F5EE" },
  paused: { label: "Paused", c: "#B45309", ink: "#92400E", bg: "#FEF4E4" },
  closed: { label: "Closed", c: "#64748B", ink: "#475569", bg: "#F1F5F9" },
};
const toneFor = (name: string, i: number, map?: Record<string, Tone>): string =>
  map?.[name.toLowerCase()]?.c ?? CAT[i % CAT.length];

/* ---------- formatters ---------- */
/** Hours → "45m" / "3.2h" / "1.4d". */
export const fmtH = (h: number | null | undefined) =>
  h == null ? "—" : h < 1 ? `${Math.round(h * 60)}m` : h < 48 ? `${h.toFixed(1)}h` : `${(h / 24).toFixed(1)}d`;
export const fmtD = (d: number | null | undefined) => (d == null ? "—" : `${d.toFixed(d < 10 ? 1 : 0)}d`);

/* ---------- KPI tile (delta-aware), matching the exec dashboard's Kpi ---------- */
export type DeltaInfo = { delta: number | null; suffix?: string; negativeIsBetter?: boolean; caption?: string };
export function Kpi({ icon, label, value, sub, href, delta }: {
  icon: ReactNode; label: string; value: ReactNode; sub?: ReactNode; href?: string; delta?: DeltaInfo | null;
}) {
  const body = (
    <>
      <span className="flex items-center gap-2 text-[11.5px] font-medium text-[#64748B]">
        <span aria-hidden className="grid h-[26px] w-[26px] shrink-0 place-items-center rounded-[8px]" style={{ background: alpha(T.base, 0.08), color: T.base }}>{icon}</span>
        <span className="min-w-0 flex-1 truncate">{label}</span>
      </span>
      <span className="mt-1.5 flex items-end justify-between gap-2">
        <span className="text-[22px] font-semibold leading-[1.1] text-[#0F172A]">{value}</span>
        {delta && <DeltaBadge {...delta} />}
      </span>
      {sub && <span className="mt-1 text-[11.5px] leading-[1.4] text-[#64748B]">{sub}</span>}
    </>
  );
  const cls = `group relative flex min-w-0 flex-col rounded-[12px] border border-[#E2E5EC] bg-white px-3 py-2.5 ${CARD_SHADOW}`;
  return href
    ? <Link href={href} className={`${cls} transition hover:-translate-y-px hover:border-[#C7D2E4] hover:shadow-[0_8px_22px_rgba(16,24,40,.12)]`}>{body}</Link>
    : <div className={cls}>{body}</div>;
}

/** Period-over-period change. `negativeIsBetter` flips the colour (fewer tickets / faster = good). */
export function DeltaBadge({ delta, suffix = "%", negativeIsBetter, caption }: DeltaInfo) {
  if (delta == null) return <span className="text-[10.5px] font-medium text-[#94A3B8]" title={caption}>new</span>;
  const flat = Math.abs(delta) < 0.05;
  const good = flat ? null : negativeIsBetter ? delta < 0 : delta > 0;
  const color = good == null ? "#64748B" : good ? T.success : T.danger;
  const Icon = flat ? Minus : delta > 0 ? ArrowUpRight : ArrowDownRight;
  return (
    <span className="inline-flex items-center gap-0.5 text-[11.5px] font-semibold tabular-nums" style={{ color }} title={caption}>
      <Icon size={13} aria-hidden />{Math.abs(delta)}{suffix.trim()}
    </span>
  );
}

/* ---------- categorical breakdown as an on-brand 100% stacked bar + legend ---------- */
export function Breakdown({ title, sub, data, kind, href }: {
  title: string; sub?: string; data: Record<string, number> | null | undefined;
  kind?: "priority" | "status" | "cat"; href?: string;
}) {
  const map = kind === "priority" ? PRIORITY_TONE : kind === "status" ? STATUS_TONE : undefined;
  const parts: Part[] = useMemo(() => Object.entries(data || {})
    .filter(([, v]) => v > 0)
    .sort((a, b) => b[1] - a[1])
    .map(([name, n], i) => ({ key: name, label: map?.[name.toLowerCase()]?.label ?? name, n, c: toneFor(name, i, map) })),
    [data, map]);
  const total = parts.reduce((s, p) => s + p.n, 0);
  return (
    <Card title={title} sub={sub} href={href} cta="View tickets" ctaIcon>
      {parts.length === 0 ? (
        <div className="flex flex-1 items-center justify-center rounded-[12px] bg-[#F6F7FB] py-8 text-center text-[11.5px] text-[#94A3B8]">No tickets in this window</div>
      ) : (
        <div className="flex flex-1 flex-col">
          <StackBar parts={parts} label={title} height={14} />
          <div className="mt-3 flex-1"><PartLegend parts={parts} total={total} cols={1} fill /></div>
        </div>
      )}
    </Card>
  );
}

/* ---------- created vs resolved trend (+ optional SLA-fulfilled line) ---------- */
export type TrendRow = { date: string; created: number; resolved: number };
export function TrendChart({ data, slaByDate }: { data: TrendRow[]; slaByDate?: Record<string, number | null> }) {
  const hasSla = slaByDate && Object.values(slaByDate).some((v) => v != null);
  const rows = data.map((r) => ({ ...r, sla: slaByDate?.[r.date] ?? null }));
  return (
    <div className="h-64 w-full">
      <ResponsiveContainer width="100%" height="100%">
        <ComposedChart data={rows} margin={{ top: 8, right: hasSla ? 6 : 10, left: -20, bottom: 0 }}>
          <defs>
            <linearGradient id="hdCreated" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor={ACCENT} stopOpacity={0.28} /><stop offset="95%" stopColor={ACCENT} stopOpacity={0} /></linearGradient>
            <linearGradient id="hdResolved" x1="0" y1="0" x2="0" y2="1"><stop offset="5%" stopColor={T.success} stopOpacity={0.28} /><stop offset="95%" stopColor={T.success} stopOpacity={0} /></linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#EEF1F5" vertical={false} />
          <XAxis dataKey="date" tick={{ fontSize: 10, fill: T.faint }} tickFormatter={(d: string) => d.slice(5)} interval={4} tickLine={false} axisLine={{ stroke: "#E2E5EC" }} />
          <YAxis yAxisId="l" tick={{ fontSize: 10, fill: T.faint }} allowDecimals={false} tickLine={false} axisLine={false} width={34} />
          {hasSla && <YAxis yAxisId="r" orientation="right" domain={[0, 100]} unit="%" tick={{ fontSize: 10, fill: T.faint }} tickLine={false} axisLine={false} width={34} />}
          <Tooltip contentStyle={{ borderRadius: 10, border: "1px solid #E2E5EC", fontSize: 12, boxShadow: "0 6px 20px rgba(15,23,42,.12)" }} />
          <Legend wrapperStyle={{ fontSize: 11.5, paddingTop: 6 }} iconType="plainline" />
          <Area yAxisId="l" type="monotone" dataKey="created" name="Created" stroke={ACCENT} fill="url(#hdCreated)" strokeWidth={2} />
          <Area yAxisId="l" type="monotone" dataKey="resolved" name="Resolved" stroke={T.success} fill="url(#hdResolved)" strokeWidth={2} />
          {hasSla && <Line yAxisId="r" type="monotone" dataKey="sla" name="SLA fulfilled %" stroke="#7C3AED" strokeWidth={2} dot={false} connectNulls />}
        </ComposedChart>
      </ResponsiveContainer>
    </div>
  );
}

/* ---------- feedback: average as a 5-star gauge ---------- */
export function StarRating({ value, size = 18 }: { value: number; size?: number }) {
  const pct = Math.max(0, Math.min(100, (value / 5) * 100));
  return (
    <span className="relative inline-flex" role="img" aria-label={`${value.toFixed(1)} out of 5`}>
      <span className="flex" style={{ color: "#E2E5EC" }}>{[0, 1, 2, 3, 4].map((i) => <Star key={i} size={size} fill="currentColor" strokeWidth={0} />)}</span>
      <span className="absolute inset-0 flex overflow-hidden" style={{ width: `${pct}%`, color: "#F59E0B" }}>
        {[0, 1, 2, 3, 4].map((i) => <Star key={i} size={size} fill="currentColor" strokeWidth={0} className="shrink-0" />)}
      </span>
    </span>
  );
}

/* ---------- tenant-wide SLA health, derived from the ticket list ---------- */
const isOpenStatus = (s?: string) => !/resolved|closed|cancelled/i.test(s || "");
export function slaBuckets(tickets: any[], now = Date.now()) {
  const soon = now + 24 * 3600 * 1000;
  let breached = 0, atRisk = 0, fulfilled = 0, onTrack = 0;
  for (const t of tickets) {
    if (t.agreement_status === "Failed") { breached++; continue; }
    if (t.agreement_status === "Fulfilled") { fulfilled++; continue; }
    if (!isOpenStatus(t.status)) continue; // resolved w/o verdict → ignore
    const due = [t.response_by, t.resolution_by]
      .map((d) => (d ? new Date(d).getTime() : NaN))
      .filter((ms) => !Number.isNaN(ms));
    if (due.some((ms) => ms <= soon)) atRisk++; else onTrack++;
  }
  return { breached, atRisk, fulfilled, onTrack };
}

export function SlaPanel({ tickets, pct, href }: { tickets: any[]; pct: number | null; href?: string }) {
  const b = useMemo(() => slaBuckets(tickets), [tickets]);
  const total = b.breached + b.atRisk + b.fulfilled + b.onTrack;
  const parts: Part[] = [
    { key: "breached", label: "Breached", n: b.breached, c: T.danger },
    { key: "atRisk", label: "At risk (≤24h)", n: b.atRisk, c: "#B45309" },
    { key: "onTrack", label: "On track", n: b.onTrack, c: T.base },
    { key: "fulfilled", label: "Met SLA", n: b.fulfilled, c: T.success },
  ];
  return (
    <Card title="SLA health" sub="Across all tickets · fulfilled vs breached vs at risk" href={href} cta="View tickets" ctaIcon>
      <div className="mb-3 flex items-end gap-3">
        <div>
          <p className="m-0 text-[28px] font-semibold leading-none text-[#0F172A]">{pct == null ? "—" : `${Math.round(pct)}%`}</p>
          <p className="m-0 mt-1 text-[11px] text-[#64748B]">resolved within SLA</p>
        </div>
        <div className="ml-auto flex gap-4 text-right">
          <div><p className="m-0 text-[18px] font-semibold leading-none" style={{ color: T.danger }}>{nfmt(b.breached)}</p><p className="m-0 mt-1 text-[10.5px] text-[#64748B]">breached</p></div>
          <div><p className="m-0 text-[18px] font-semibold leading-none" style={{ color: "#B45309" }}>{nfmt(b.atRisk)}</p><p className="m-0 mt-1 text-[10.5px] text-[#64748B]">at risk</p></div>
        </div>
      </div>
      {total === 0 ? (
        <div className="flex flex-1 items-center justify-center rounded-[12px] bg-[#F6F7FB] py-6 text-center text-[11.5px] text-[#94A3B8]">No SLA data yet</div>
      ) : (
        <div className="flex flex-1 flex-col">
          <StackBar parts={parts.filter((p) => p.n > 0)} label="SLA status" height={14} />
          <div className="mt-3 flex-1"><PartLegend parts={parts} total={total} cols={2} fill /></div>
        </div>
      )}
    </Card>
  );
}
