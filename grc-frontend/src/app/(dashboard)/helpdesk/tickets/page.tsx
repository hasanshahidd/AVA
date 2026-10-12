"use client";

/**
 * Help Desk — Tickets list + New-Ticket flow.
 *
 * The list reads GET /helpdesk/tickets. "New ticket" opens a dialog that submits
 * POST /helpdesk/tickets (subject, description, department_id, agent_group_id,
 * customer_id, contact). Department is the headline field: a chosen department
 * routes the ticket to its default team, then the existing assignment+SLA engine
 * runs. Priority / Ticket Type / Assignee are applied in a follow-up
 * /update + /assign call because the create endpoint keys them by id while the
 * only id-free catalogue the API exposes is /meta's label list (resolved by
 * label on the update path).
 */
import Link from "next/link";
import { useMemo, useState } from "react";
import { Ticket, Inbox, Search } from "lucide-react";
import { Chip, PRIORITY_CHIP, ErrorBanner, Empty, Loading, PageHeader, Table, timeAgo, useHd } from "../_ui";
import { Modal, Field, Input, Textarea, Select, Btn, NewBtn, FormError, hdCall } from "../_admin";

type Meta = { priorities: string[]; ticket_types: string[]; statuses: { name: string; category: string }[] };
type Dept = { id: number; name: string; enabled: boolean };
type Team = { id: number; team_name: string };
type Agent = { email: string; agent_name: string };
type Customer = { name: string; customer_name: string };

const isOpen = (s?: string) => !/resolved|closed|cancelled/i.test(s || "");

export default function HelpDeskTickets() {
  const { data, loading, error, reload } = useHd<{ tickets: any[] }>("/helpdesk/tickets");
  const [q, setQ] = useState("");
  const [showNew, setShowNew] = useState(false);

  const tickets = data?.tickets || [];
  const filtered = useMemo(() => {
    const needle = q.trim().toLowerCase();
    if (!needle) return tickets;
    return tickets.filter(
      (t) =>
        String(t.subject || "").toLowerCase().includes(needle) ||
        String(t.name || "").includes(needle) ||
        String(t.contact || "").toLowerCase().includes(needle),
    );
  }, [tickets, q]);

  return (
    <div className="flex flex-col gap-4 text-[#0F172A]">
      <PageHeader
        icon={Ticket}
        title="Tickets"
        subtitle="Every request across all departments"
        actions={<NewBtn label="New ticket" onClick={() => setShowNew(true)} />}
      />

      {error && <ErrorBanner msg={error} />}

      <div className="relative max-w-sm">
        <Search size={15} className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-[#94A3B8]" />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Search subject, #id or contact…"
          className="w-full rounded-[9px] border border-[#E2E5EC] bg-white py-2 pl-9 pr-3 text-[13px] outline-none focus:border-[#005B96] focus:ring-2 focus:ring-[#005B96]/15"
        />
      </div>

      {loading ? (
        <Loading what="tickets" />
      ) : filtered.length === 0 ? (
        <Empty
          icon={Inbox}
          title={q ? "No tickets match your search" : "No tickets yet"}
          hint={q ? "Try a different term." : "Create your first ticket with the New ticket button."}
        />
      ) : (
        <Table head={["#", "Subject", "Status", "Priority", "Team", "Assignee", "Created"]}>
          {filtered.map((t) => (
            <tr key={t.name} className="hover:bg-[#F9FAFC]">
              <td className="px-4 py-2.5 font-mono text-[11px] text-[#94A3B8]">
                <Link href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`} className="hover:text-[#005B96]">
                  #{t.name}
                </Link>
              </td>
              <td className="px-4 py-2.5">
                <Link href={`/helpdesk/tickets/${encodeURIComponent(t.name)}`} className="font-medium text-[#0F172A] hover:text-[#005B96]">
                  {t.subject || "(no subject)"}
                </Link>
              </td>
              <td className="px-4 py-2.5"><Chip value={t.status} /></td>
              <td className="px-4 py-2.5"><Chip value={t.priority} map={PRIORITY_CHIP} /></td>
              <td className="px-4 py-2.5 text-[12.5px] text-[#475569]">{t.team || "—"}</td>
              <td className="px-4 py-2.5 text-[12.5px] text-[#475569]">{t.agent || <span className="text-[#CBD5E1]">Unassigned</span>}</td>
              <td className="px-4 py-2.5 text-[11.5px] text-[#94A3B8]">{timeAgo(t.created)}</td>
            </tr>
          ))}
        </Table>
      )}

      <NewTicketDialog
        open={showNew}
        onClose={() => setShowNew(false)}
        onCreated={() => {
          setShowNew(false);
          reload();
        }}
      />
    </div>
  );
}

function NewTicketDialog({ open, onClose, onCreated }: { open: boolean; onClose: () => void; onCreated: () => void }) {
  const meta = useHd<Meta>("/helpdesk/meta");
  const depts = useHd<{ departments: Dept[] }>("/helpdesk/departments");
  const teams = useHd<{ teams: Team[] }>("/helpdesk/teams");
  const agents = useHd<{ agents: Agent[] }>("/helpdesk/agents");
  const customers = useHd<{ customers: Customer[] }>("/helpdesk/customers");

  const [subject, setSubject] = useState("");
  const [description, setDescription] = useState("");
  const [departmentId, setDepartmentId] = useState("");
  const [ticketType, setTicketType] = useState("");
  const [priority, setPriority] = useState("");
  const [teamId, setTeamId] = useState("");
  const [assignee, setAssignee] = useState("");
  const [customerId, setCustomerId] = useState("");
  const [contact, setContact] = useState("");
  const [busy, setBusy] = useState(false);
  const [err, setErr] = useState<string | null>(null);

  const deptList = (depts.data?.departments || []).filter((d) => d.enabled);
  const teamList = teams.data?.teams || [];
  const selectedTeam = teamList.find((t) => String(t.id) === teamId);

  const reset = () => {
    setSubject(""); setDescription(""); setDepartmentId(""); setTicketType("");
    setPriority(""); setTeamId(""); setAssignee(""); setCustomerId(""); setContact(""); setErr(null);
  };

  const submit = async () => {
    if (!subject.trim()) { setErr("Subject is required."); return; }
    setBusy(true); setErr(null);

    const create = await hdCall("post", "/helpdesk/tickets", {
      subject: subject.trim(),
      description: description.trim() || null,
      department_id: departmentId ? Number(departmentId) : null,
      agent_group_id: teamId ? Number(teamId) : null,
      customer_id: customerId ? Number(customerId) : null,
      contact: contact.trim() || null,
    });
    if (!create.ok || !create.data?.name) { setBusy(false); setErr(create.error || "Could not create the ticket."); return; }
    const name = create.data.name;

    // Priority / Ticket Type are label-resolved on the update path.
    if (priority || ticketType) {
      const upd = await hdCall("post", `/helpdesk/tickets/${encodeURIComponent(name)}/update`, {
        priority: priority || undefined,
        ticket_type: ticketType || undefined,
      });
      if (!upd.ok) { setBusy(false); setErr(upd.error || "Ticket created, but priority/type could not be set."); return; }
    }
    // Explicit assignee (agent + optional team) overrides any auto-assignment.
    if (assignee) {
      const asn = await hdCall("post", `/helpdesk/tickets/${encodeURIComponent(name)}/assign`, {
        agent: assignee,
        team: selectedTeam?.team_name || null,
      });
      if (!asn.ok) { setBusy(false); setErr(asn.error || "Ticket created, but the assignee could not be set."); return; }
    }

    setBusy(false);
    reset();
    onCreated();
  };

  return (
    <Modal
      open={open}
      onClose={() => { if (!busy) { reset(); onClose(); } }}
      title="New ticket"
      subtitle="Raise a request for any department"
      wide
      footer={
        <>
          <Btn variant="ghost" onClick={() => { reset(); onClose(); }} disabled={busy}>Cancel</Btn>
          <Btn variant="primary" onClick={submit} busy={busy}>Create ticket</Btn>
        </>
      }
    >
      <FormError msg={err} />
      <div className="flex flex-col gap-3.5">
        <Field label="Subject" required>
          <Input value={subject} onChange={(e) => setSubject(e.target.value)} placeholder="Short summary of the request" autoFocus />
        </Field>
        <Field label="Description">
          <Textarea value={description} onChange={(e) => setDescription(e.target.value)} placeholder="What's going on? Steps, context, impact…" />
        </Field>

        <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-2">
          <Field label="Department" hint={deptList.length ? undefined : "No departments yet — create one in Settings → Departments."}>
            <Select value={departmentId} onChange={(e) => setDepartmentId(e.target.value)}>
              <option value="">— Select —</option>
              {deptList.map((d) => (
                <option key={d.id} value={d.id}>{d.name}</option>
              ))}
            </Select>
          </Field>
          <Field label="Team">
            <Select value={teamId} onChange={(e) => setTeamId(e.target.value)}>
              <option value="">— Route by department —</option>
              {teamList.map((t) => (
                <option key={t.id} value={t.id}>{t.team_name}</option>
              ))}
            </Select>
          </Field>
          <Field label="Ticket type">
            <Select value={ticketType} onChange={(e) => setTicketType(e.target.value)}>
              <option value="">— None —</option>
              {(meta.data?.ticket_types || []).map((t) => (
                <option key={t} value={t}>{t}</option>
              ))}
            </Select>
          </Field>
          <Field label="Priority">
            <Select value={priority} onChange={(e) => setPriority(e.target.value)}>
              <option value="">— Default —</option>
              {(meta.data?.priorities || []).map((p) => (
                <option key={p} value={p}>{p}</option>
              ))}
            </Select>
          </Field>
          <Field label="Assignee">
            <Select value={assignee} onChange={(e) => setAssignee(e.target.value)}>
              <option value="">— Auto-assign —</option>
              {(agents.data?.agents || []).map((a) => (
                <option key={a.email} value={a.email}>{a.agent_name || a.email}</option>
              ))}
            </Select>
          </Field>
          <Field label="Customer">
            <Select value={customerId} onChange={(e) => setCustomerId(e.target.value)}>
              <option value="">— None —</option>
              {(customers.data?.customers || []).map((c) => (
                <option key={c.name} value={c.name}>{c.customer_name}</option>
              ))}
            </Select>
          </Field>
        </div>

        <Field label="Contact email" hint="Who raised this, if not an internal user.">
          <Input type="email" value={contact} onChange={(e) => setContact(e.target.value)} placeholder="person@company.com" />
        </Field>
      </div>
    </Modal>
  );
}
