'use client';

/**
 * Admin → Departments. Manages the Help-Desk service-desk departments from Ava
 * Administration (owner wants them managed here AND visible in Help Desk — both
 * surfaces read the same endpoints, so they stay in sync). grc_hd_department
 * stays the authoritative table owned by the native Help Desk engine; this page
 * is just a CRUD surface over GET/POST/PUT/DELETE /helpdesk/departments.
 */

import { useState, type ReactNode } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import apiClient, { teamsApi, type Team } from '@/lib/api';
import { Plus, Pencil, Trash2, X, Loader2, Building2, Check } from 'lucide-react';

type Department = {
  id: number;
  name: string;
  description: string | null;
  default_team_id: number | null;
  default_team: string | null;
  enabled: boolean;
};

const inputCls =
  'w-full rounded-lg border border-slate-300 px-2.5 py-1.5 text-sm text-slate-900 focus:border-[var(--color-base)] focus:outline-none focus:ring-1 focus:ring-[var(--color-base)]';

function errMsg(e: unknown): string {
  const anyE = e as { response?: { data?: { detail?: string } }; message?: string };
  return anyE?.response?.data?.detail || anyE?.message || 'Something went wrong';
}

export default function DepartmentsAdminPage() {
  const qc = useQueryClient();
  const [editing, setEditing] = useState<Department | 'new' | null>(null);

  const deptsQ = useQuery<Department[]>({
    queryKey: ['hd-departments'],
    queryFn: () => apiClient.get('/helpdesk/departments').then((r) => r.data.departments as Department[]),
  });
  const teamsQ = useQuery<Team[]>({
    queryKey: ['admin-teams-for-depts'],
    queryFn: () => teamsApi.list(true).then((r) => r.data),
  });

  const delMut = useMutation({
    mutationFn: (id: number) => apiClient.delete(`/helpdesk/departments/${id}`),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['hd-departments'] }),
  });

  const depts = deptsQ.data ?? [];
  const teams = teamsQ.data ?? [];

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h2 className="flex items-center gap-2 text-lg font-semibold text-slate-900">
            <Building2 size={18} className="text-[var(--color-base)]" />
            Departments
          </h2>
          <p className="mt-0.5 text-sm text-slate-500">
            Service-desk departments — managed here, also visible in Help Desk. Each routes its new tickets to a default team.
          </p>
        </div>
        <button
          onClick={() => setEditing('new')}
          className="inline-flex items-center gap-1.5 rounded-lg bg-primary-600 px-3 py-2 text-sm font-semibold text-white hover:bg-primary-700"
        >
          <Plus size={15} />
          New Department
        </button>
      </div>

      <div className="overflow-hidden rounded-xl border border-slate-200 bg-white">
        {deptsQ.isLoading ? (
          <div className="flex h-28 items-center justify-center text-slate-400">
            <Loader2 className="h-5 w-5 animate-spin" />
          </div>
        ) : deptsQ.isError ? (
          <div className="px-4 py-10 text-center text-sm text-rose-600">{errMsg(deptsQ.error)}</div>
        ) : depts.length === 0 ? (
          <div className="px-4 py-10 text-center text-sm text-slate-500">
            No departments yet. Create one to route tickets by area (e.g. IT, Security, Finance, Sales).
          </div>
        ) : (
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-slate-100 text-left text-[12px] font-semibold text-slate-600">
                <th className="px-4 py-2.5">Name</th>
                <th className="px-4 py-2.5">Description</th>
                <th className="px-4 py-2.5">Default team</th>
                <th className="px-4 py-2.5">Status</th>
                <th className="w-20 px-4 py-2.5"></th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {depts.map((d) => (
                <tr key={d.id} className="hover:bg-slate-50">
                  <td className="px-4 py-2.5 font-medium text-slate-900">{d.name}</td>
                  <td className="px-4 py-2.5 text-slate-500">{d.description || '—'}</td>
                  <td className="px-4 py-2.5 text-slate-700">{d.default_team || <span className="text-slate-400">—</span>}</td>
                  <td className="px-4 py-2.5">
                    {d.enabled ? (
                      <span className="inline-flex items-center gap-1 text-[12px] font-medium text-emerald-700">
                        <Check size={13} />
                        Enabled
                      </span>
                    ) : (
                      <span className="text-[12px] text-slate-400">Disabled</span>
                    )}
                  </td>
                  <td className="px-4 py-2.5">
                    <div className="flex items-center justify-end gap-1">
                      <button
                        onClick={() => setEditing(d)}
                        className="rounded-md p-1.5 text-slate-400 hover:bg-slate-100 hover:text-slate-700"
                        title="Edit"
                      >
                        <Pencil size={15} />
                      </button>
                      <button
                        onClick={() => {
                          if (window.confirm(`Delete department "${d.name}"? Its ticket types become global (unassigned).`)) {
                            delMut.mutate(d.id);
                          }
                        }}
                        className="rounded-md p-1.5 text-slate-400 hover:bg-rose-50 hover:text-rose-600"
                        title="Delete"
                      >
                        <Trash2 size={15} />
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
      {delMut.isError && <p className="text-sm text-rose-600">{errMsg(delMut.error)}</p>}

      {editing && (
        <DepartmentModal
          dept={editing === 'new' ? null : editing}
          teams={teams}
          onClose={() => setEditing(null)}
          onSaved={() => {
            setEditing(null);
            qc.invalidateQueries({ queryKey: ['hd-departments'] });
          }}
        />
      )}
    </div>
  );
}

function DepartmentModal({
  dept,
  teams,
  onClose,
  onSaved,
}: {
  dept: Department | null;
  teams: Team[];
  onClose: () => void;
  onSaved: () => void;
}) {
  const [name, setName] = useState(dept?.name ?? '');
  const [description, setDescription] = useState(dept?.description ?? '');
  const [teamId, setTeamId] = useState<string>(dept?.default_team_id ? String(dept.default_team_id) : '');
  const [enabled, setEnabled] = useState(dept?.enabled ?? true);

  const save = useMutation({
    mutationFn: () => {
      const body = {
        name: name.trim(),
        description: description || null,
        default_team_id: teamId ? Number(teamId) : null,
        enabled,
      };
      return dept
        ? apiClient.put(`/helpdesk/departments/${dept.id}`, body)
        : apiClient.post('/helpdesk/departments', body);
    },
    onSuccess: onSaved,
  });

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 p-4" onClick={onClose}>
      <div className="w-full max-w-md rounded-xl bg-white shadow-xl" onClick={(e) => e.stopPropagation()}>
        <div className="flex items-center justify-between border-b border-slate-100 px-5 py-3">
          <h3 className="text-sm font-semibold text-slate-900">{dept ? 'Edit department' : 'New department'}</h3>
          <button onClick={onClose} className="text-slate-400 hover:text-slate-600">
            <X size={18} />
          </button>
        </div>
        <div className="space-y-3 px-5 py-4">
          <Field label="Name">
            <input value={name} onChange={(e) => setName(e.target.value)} className={inputCls} placeholder="e.g. IT, Security, Finance" autoFocus />
          </Field>
          <Field label="Description">
            <input value={description} onChange={(e) => setDescription(e.target.value)} className={inputCls} placeholder="Optional" />
          </Field>
          <Field label="Default team">
            <select value={teamId} onChange={(e) => setTeamId(e.target.value)} className={inputCls}>
              <option value="">— none —</option>
              {teams.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>
            <p className="mt-1 text-[11px] text-slate-400">New tickets for this department route to this team (Administration → Teams).</p>
          </Field>
          <label className="flex items-center gap-2 text-sm text-slate-700">
            <input type="checkbox" checked={enabled} onChange={(e) => setEnabled(e.target.checked)} style={{ accentColor: 'var(--color-base)' }} />
            Enabled
          </label>
          {save.isError && <p className="text-sm text-rose-600">{errMsg(save.error)}</p>}
        </div>
        <div className="flex justify-end gap-2 border-t border-slate-100 px-5 py-3">
          <button onClick={onClose} className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50">
            Cancel
          </button>
          <button
            disabled={!name.trim() || save.isPending}
            onClick={() => save.mutate()}
            className="inline-flex items-center gap-1.5 rounded-lg bg-primary-600 px-3 py-1.5 text-sm font-semibold text-white hover:bg-primary-700 disabled:opacity-50"
          >
            {save.isPending && <Loader2 size={14} className="animate-spin" />}
            Save
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <div>
      <label className="mb-1 block text-[12px] font-medium text-slate-600">{label}</label>
      {children}
    </div>
  );
}
