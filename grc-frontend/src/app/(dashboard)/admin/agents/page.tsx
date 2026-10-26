'use client';

export const dynamic = 'force-dynamic';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Download, RefreshCw, CheckCircle2 } from 'lucide-react';
import apiClient, { agentsApi } from '@/lib/api';
import { useToast } from '@/components/ui/ToastProvider';
import { usePermissions } from '@/hooks/usePermissions';

type Agent = {
  id: number;
  agent_name: string;
  mode: 'collector' | 'endpoint';
  os_family?: string | null;
  hostname?: string | null;
  ip_address?: string | null;
  asset_id?: number | null;
  status: 'pending' | 'active' | 'stale' | 'revoked';
  agent_version?: string | null;
  last_heartbeat_at?: string | null;
  last_result_at?: string | null;
  enrolled_at?: string | null;
  created_at?: string | null;
};

const STATUS_COLORS: Record<string, string> = {
  active: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  pending: 'bg-amber-50 text-amber-700 border-amber-200',
  stale: 'bg-amber-50 text-amber-700 border-amber-200',
  revoked: 'bg-slate-100 text-slate-600 border-slate-300',
};

function fmtAgo(iso?: string | null): string {
  if (!iso) return 'never';
  const utc = /[zZ]$|[+-]\d{2}:?\d{2}$/.test(iso) ? iso : `${iso}Z`;
  const ms = Date.now() - new Date(utc).getTime();
  const s = Math.floor(ms / 1000);
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}

const STALE_THRESHOLD_MS = 5 * 60 * 1000; // 5 minutes without heartbeat → stale

/** Derive effective status — active agents that haven't pinged in >5min
 * are visually flagged as stale even if backend still says 'active'. */
function effectiveStatus(a: { status: string; last_heartbeat_at?: string | null }): string {
  if (a.status !== 'active') return a.status;
  if (!a.last_heartbeat_at) return 'pending';
  const utc = /[zZ]$|[+-]\d{2}:?\d{2}$/.test(a.last_heartbeat_at)
    ? a.last_heartbeat_at : `${a.last_heartbeat_at}Z`;
  const ms = Date.now() - new Date(utc).getTime();
  return ms > STALE_THRESHOLD_MS ? 'stale' : 'active';
}

export default function AgentsAdminPage() {
  const qc = useQueryClient();
  const toast = useToast();
  const { hasPermission, isLoading: permsLoading } = usePermissions();
  const canManageAgents = hasPermission('compliance:agents:manage');
  // Custom revoke modal state — replaces browser prompt+confirm
  const [revokeTarget, setRevokeTarget] = useState<Agent | null>(null);
  const [revokeReason, setRevokeReason] = useState('');

  const q = useQuery<{ items: Agent[] }>({
    queryKey: ['agents'],
    queryFn: async () => (await agentsApi.list()).data,
    refetchInterval: 5000,
  });

  const revokeMut = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) =>
      agentsApi.revoke(id, reason),
    onSuccess: (_res, vars) => {
      qc.invalidateQueries({ queryKey: ['agents'] });
      const target = agents.find(a => a.id === vars.id);
      toast.toast({ title: 'Agent revoked', message: target ? `${target.agent_name} can no longer push results.` : undefined, type: 'success' });
      setRevokeTarget(null);
      setRevokeReason('');
    },
    onError: () => toast.toast({ title: 'Revoke failed', type: 'error' }),
  });

  const agents = q.data?.items ?? [];

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      <div className="min-w-0">
        <h1 className="text-xl font-semibold text-slate-900">Compliance Agents</h1>
        <p className="mt-1 max-w-3xl text-sm text-slate-500">
          Install a lightweight agent on a host — it enrols, inventories the machine, and runs
          CIS benchmarks locally, then reports to CAIVA. Built for endpoints you can&apos;t reach
          over the network: roaming laptops, NAT&apos;d or firewalled boxes. Pick an OS to download.
        </p>
      </div>

      {!permsLoading && !canManageAgents && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 px-4 py-2.5 text-sm text-amber-800">
          You need the <code className="rounded bg-amber-100 px-1">compliance:agents:manage</code> permission to install or revoke agents.
        </div>
      )}

      {/* Agent installers — one self-contained binary per OS. It enrols,
          inventories the host, and runs CIS benchmarks locally, then reports
          to CAIVA. One file works on any host of the same OS family. */}
      <div className="grid gap-4 sm:grid-cols-2">
        {([
          { os: 'windows' as const, glyph: '🪟', title: 'Windows agent',
            meta: 'x64 · runs as LocalSystem',
            support: 'Windows 10 / 11 · Server 2016 – 2022' },
          { os: 'linux' as const, glyph: '🐧', title: 'Linux agent',
            meta: 'x64 · systemd service',
            support: 'Ubuntu 20/22/24 · Debian 11/12 · RHEL/Alma 8/9 · Amazon Linux' },
        ]).map((c) => (
          <div
            key={c.os}
            className="flex flex-col rounded-xl border border-slate-200 bg-white p-5 shadow-sm transition hover:border-primary-300 hover:shadow"
          >
            <div className="flex items-center gap-3">
              <div className="grid h-11 w-11 shrink-0 place-items-center rounded-xl bg-primary-50 text-2xl">{c.glyph}</div>
              <div className="min-w-0">
                <div className="text-sm font-semibold text-slate-900">{c.title}</div>
                <div className="text-[11px] text-slate-500">{c.meta}</div>
              </div>
            </div>
            <ul className="mt-4 space-y-1.5 text-xs text-slate-600">
              {[
                'Full hardware + software inventory',
                'Runs CIS benchmarks locally — no inbound firewall rule',
                'Auto-enrols, heartbeats, re-scans on schedule',
              ].map((f) => (
                <li key={f} className="flex items-start gap-1.5">
                  <CheckCircle2 className="mt-0.5 h-3.5 w-3.5 shrink-0 text-emerald-500" />
                  <span>{f}</span>
                </li>
              ))}
            </ul>
            <div className="mt-auto pt-4">
              <InstallerButtons
                os={c.os}
                label={`Download ${c.title.split(' ')[0]} installer`}
                canManage={canManageAgents}
                toast={toast}
              />
              <p className="mt-2 text-center text-[10px] text-slate-400">{c.support}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Installed agents */}
      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white shadow-sm">
        <div className="flex items-center justify-between gap-2 border-b border-slate-200 px-5 py-3">
          <h2 className="text-sm font-semibold text-slate-900">
            Installed agents
            {agents.length > 0 && (
              <span className="ml-2 rounded-full bg-slate-100 px-1.5 py-0.5 text-[11px] font-medium text-slate-600">{agents.length}</span>
            )}
          </h2>
          <button
            onClick={() => q.refetch()}
            className="inline-flex items-center gap-1 text-xs text-slate-500 transition hover:text-primary-700"
          >
            <RefreshCw className="h-3.5 w-3.5" /> Refresh
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-slate-50 text-xs uppercase tracking-wide text-slate-600">
              <tr>
                <th className="text-left px-4 py-2.5">Agent</th>
                <th className="text-left px-4 py-2.5 w-32">Mode</th>
                <th className="text-left px-4 py-2.5 w-32">Host</th>
                <th className="text-left px-4 py-2.5 w-24">OS</th>
                <th className="text-left px-4 py-2.5 w-28">Status</th>
                <th className="text-left px-4 py-2.5 w-32">Last heartbeat</th>
                <th className="text-left px-4 py-2.5 w-32">Last results</th>
                <th className="text-right px-4 py-2.5 w-24">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {agents.length === 0 && (
                <tr>
                  <td colSpan={8} className="px-4 py-12 text-center">
                    <div className="mx-auto max-w-sm">
                      <div className="mx-auto mb-3 grid h-12 w-12 place-items-center rounded-full bg-slate-100 text-2xl">🤖</div>
                      <div className="text-sm font-medium text-slate-900">No agents installed yet</div>
                      <p className="mt-1 text-xs text-slate-500">
                        Download an installer above and run it on a host. It appears here within a
                        minute of enrolling, then inventories and scans on schedule.
                      </p>
                    </div>
                  </td>
                </tr>
              )}
              {agents.map((a) => (
                <tr key={a.id} className="hover:bg-slate-50">
                  <td className="px-4 py-3">
                    <div className="font-medium text-slate-900">{a.agent_name}</div>
                    {a.agent_version && (
                      <div className="text-[10px] text-slate-500">v{a.agent_version}</div>
                    )}
                  </td>
                  <td className="px-4 py-3 text-xs text-slate-700 capitalize">{a.mode}</td>
                  <td className="px-4 py-3 font-mono text-xs text-slate-700">
                    {a.hostname || <span className="text-slate-400">—</span>}
                  </td>
                  <td className="px-4 py-3 text-xs text-slate-700 capitalize">{a.os_family || '—'}</td>
                  <td className="px-4 py-3">
                    {(() => {
                      const eff = effectiveStatus(a);
                      const isStale = eff === 'stale' && a.status === 'active';
                      return (
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-medium border uppercase ${STATUS_COLORS[eff] ?? 'bg-slate-100 text-slate-600 border-slate-200'}`}
                          title={isStale ? 'Heartbeat not received in 5+ minutes' : undefined}
                        >
                          {eff}
                        </span>
                      );
                    })()}
                  </td>
                  <td className="px-4 py-3 text-xs text-slate-600">{fmtAgo(a.last_heartbeat_at)}</td>
                  <td className="px-4 py-3 text-xs text-slate-600">{fmtAgo(a.last_result_at)}</td>
                  <td className="px-4 py-3 text-right">
                    {a.status === 'revoked' ? (
                      <span className="text-xs text-slate-400">revoked</span>
                    ) : (
                      <button
                        onClick={() => { setRevokeTarget(a); setRevokeReason(''); }}
                        className="text-xs text-rose-600 hover:underline"
                      >
                        Revoke
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Custom revoke modal — replaces browser confirm() */}
      {revokeTarget && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md p-6">
            <h3 className="text-lg font-semibold text-slate-900 mb-1">Revoke agent?</h3>
            <p className="text-sm text-slate-600 mb-4">
              <strong>{revokeTarget.agent_name}</strong>'s next heartbeat will be
              rejected and it will lose access to the backend. Asset records remain
              intact; only the agent's push capability is killed.
            </p>
            <label className="block text-xs font-medium text-slate-700 mb-1">
              Reason (optional)
            </label>
            <textarea
              value={revokeReason}
              onChange={(e) => setRevokeReason(e.target.value)}
              placeholder="e.g. Replaced by new build, host decommissioned…"
              rows={3}
              className="w-full px-3 py-2 border border-slate-300 rounded-md text-sm focus:outline-none focus:border-rose-500 focus:ring-1 focus:ring-rose-500"
            />
            <div className="flex justify-end gap-2 mt-5">
              <button
                onClick={() => { setRevokeTarget(null); setRevokeReason(''); }}
                className="px-4 py-1.5 text-sm border border-slate-300 rounded-md hover:bg-slate-50"
              >
                Cancel
              </button>
              <button
                onClick={() => revokeMut.mutate({ id: revokeTarget.id, reason: revokeReason })}
                disabled={revokeMut.isPending}
                className="px-4 py-1.5 text-sm bg-rose-600 text-white rounded-md hover:bg-rose-700 disabled:opacity-50"
              >
                {revokeMut.isPending ? 'Revoking…' : 'Revoke agent'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── InstallerButtons ────────────────────────────────────────────────────
// Mints a fleet enrollment token (unlimited uses, 72h TTL) and streams the
// per-OS installer file as a download. One file works on any host of the
// SAME OS family — the installer + agent both refuse to enrol on a
// mismatched OS. Powered by the CIS Phase 3 backend endpoints
// (/agents/installer.cmd | .sh | .command). Revocable any time via the
// Agents table below.
function InstallerButtons({
  os, label, canManage, toast,
}: {
  os: 'windows' | 'linux';
  label: string;
  canManage: boolean;
  toast: ReturnType<typeof useToast>;
}) {
  const [busy, setBusy] = useState(false);
  const download = async () => {
    if (!canManage) {
      toast.toast({
        title: 'Permission required',
        message: 'You need the "compliance:agents:manage" permission to download an installer.',
        type: 'warning',
      });
      return;
    }
    setBusy(true);
    try {
      // Mint a one-time enrollment token, then fetch the personalised installer
      // (enrollment token + cloud URL baked in) and save it as a file. Running it
      // installs the agent as a service → it enrols, scans this host, and reports.
      const enr = await agentsApi.enroll({ agent_name: `${os} agent`, os_family: os });
      const token = (enr.data as { enrollment_token: string }).enrollment_token;
      const resp = await apiClient.get(`/agents/installer/${os}/${token}`, { responseType: 'blob' });
      const filename = os === 'windows' ? 'install-ava-agent.ps1' : 'install-ava-agent.sh';
      const url = URL.createObjectURL(new Blob([resp.data], { type: 'application/octet-stream' }));
      const a = document.createElement('a');
      a.href = url;
      a.download = filename;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
      toast.toast({
        title: 'Installer downloaded',
        message: `Run ${filename} as ${os === 'windows' ? 'Administrator' : 'root'} on the target host — it enrols, scans, and reports automatically.`,
        type: 'success',
      });
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : 'Unknown error';
      toast.toast({ title: 'Download failed', message: msg, type: 'error' });
    } finally {
      setBusy(false);
    }
  };

  return (
    <button
      type="button"
      onClick={download}
      disabled={busy}
      className="inline-flex w-full items-center justify-center gap-1.5 rounded-md bg-primary-600 px-3 py-2 text-xs font-medium text-white transition hover:bg-primary-700 disabled:opacity-50"
    >
      <Download className="h-3.5 w-3.5" />
      {busy ? 'Preparing…' : label}
    </button>
  );
}
