"""SLA engine — native FastAPI port of Frappe Helpdesk's SLA logic.

1:1 translation of the owned source (logic spec §1), not a redesign:
  * selection      — hd_service_level_agreement/utils.py:get_sla
  * business math   — hd_service_level_agreement.py:calc_time / calc_elapsed_time
  * apply sequence  — hd_service_level_agreement.py:apply (+ set_hold_time,
                      handle_agreement_status, set_first_response_time,
                      set_resolution_time) and hd_ticket.py:clear_sla_fields

Works on the native SQLAlchemy rows (_60_helpdesk_native_models) instead of
Frappe Documents: Frappe string links become FK ids, `Time` columns are
datetime.time (not timedelta), and `now` is datetime.utcnow(). Every function
returns a 200-safe shape and never raises on empty input.
"""
from __future__ import annotations

from datetime import datetime, time as dtime, timedelta
from typing import Optional

from sqlalchemy.orm import Session

from ...models import HDServiceLevelAgreement, HDTeam
from .common import iso

RESOLVED = "Resolved"
PAUSED = "Paused"

# frappe.utils.get_weekdays() — Monday-first, matching datetime.weekday() (0=Mon)
_WEEKDAYS = ["Monday", "Tuesday", "Wednesday", "Thursday",
             "Friday", "Saturday", "Sunday"]


# ─── low-level helpers ───────────────────────────────────────────────────────
def _secs(t) -> float:
    """utils.py:convert_to_seconds — seconds since midnight of a time/datetime."""
    if not t:
        return 0
    return t.hour * 3600 + t.minute * 60 + t.second


def _day_start(dt: datetime) -> datetime:
    """Midnight of `dt`'s date (Frappe's `getdate(add_to_date(...))` cursor jump)."""
    return datetime.combine(dt.date(), dtime.min)


def _workdays(sla) -> dict:
    """get_workdays() — {weekday name: HDServiceDay row}."""
    return {d.workday: d for d in sla.service_days}


def _holidays(sla) -> set:
    """get_holidays() — set of holiday dates (empty when no holiday list)."""
    hl = sla.holiday_list
    return {h.holiday_date for h in hl.holidays} if hl else set()


def _priority_row(sla, priority_id):
    """get_priorities()[priority] — the per-priority target row for this ticket."""
    for p in sla.priorities:
        if p.priority_id == priority_id:
            return p
    return None


def _calc_time(start_at, target_seconds, holidays, workdays, hold_time=0):
    """hd_service_level_agreement.py:calc_time — walk business time forward from
    `start_at` by `target_seconds` (+`hold_time` for resolution), skipping
    holidays and non-working days and clamping each day to its workday window.
    Returns the deadline datetime. Reimplemented exactly, including the
    `max(end_time, current_time_in_seconds)` skip-past-shift-end behaviour."""
    if not start_at:
        return None
    result = start_at
    remaining = (target_seconds or 0) + (hold_time or 0)
    guard = 0
    while remaining > 0:
        guard += 1
        if guard > 20000:
            # ponytail: ceiling guards a calendar with no working day at all;
            # a real budget exhausts in far fewer iterations.
            break
        current_dt = result
        current_date = current_dt.date()
        current_day = _WEEKDAYS[current_dt.weekday()]

        if current_date in holidays or current_day not in workdays:
            result = _day_start(current_dt + timedelta(days=1))
            continue

        wd = workdays[current_day]
        current_time_in_seconds = (current_dt - _day_start(current_dt)).total_seconds()
        start_time = max(_secs(wd.start_time), current_time_in_seconds)
        till_start_time = max(start_time - current_time_in_seconds, 0)
        end_time = max(_secs(wd.end_time), current_time_in_seconds)
        time_left = max(end_time - start_time, 0)
        if not time_left:
            result = _day_start(current_dt + timedelta(days=1))
            continue
        time_taken = min(remaining, time_left)
        remaining -= time_taken
        result = result + timedelta(seconds=till_start_time + time_taken)
    return result


def _calc_elapsed_time(start_time, end_time, holidays, workdays):
    """hd_service_level_agreement.py:calc_elapsed_time — working seconds between
    two datetimes, skipping holidays/non-work-days and clamping the first day's
    lower bound and the last day's upper bound to the workday window."""
    if not start_time or not end_time or start_time >= end_time:
        return 0
    total = 0
    current_date = start_time.date()
    end_date = end_time.date()
    while current_date <= end_date:
        if current_date in holidays:
            current_date += timedelta(days=1)
            continue
        day_name = _WEEKDAYS[current_date.weekday()]
        if day_name not in workdays:
            current_date += timedelta(days=1)
            continue
        wd = workdays[day_name]
        work_start = _secs(wd.start_time)
        work_end = _secs(wd.end_time)
        day_start = max(_secs(start_time), work_start) if current_date == start_time.date() else work_start
        day_end = min(_secs(end_time), work_end) if current_date == end_time.date() else work_end
        if day_start < day_end:
            total += day_end - day_start
        current_date += timedelta(days=1)
    return total


# ─── SLA selection (utils.py:get_sla) ────────────────────────────────────────
class _Doc(dict):
    """Attribute-accessible ticket view for condition eval; `doc.x` and
    `doc.get('x')` both work (frappe._dict parity)."""
    __getattr__ = dict.get


def _ctx(ticket) -> dict:
    """utils.get_context — the serialized ticket a condition is evaluated against.
    Link fields are exposed by their human value (Frappe field semantics), not
    FK ids, so authored conditions like `doc.priority == 'High'` work."""
    return {"doc": _Doc(
        subject=ticket.subject,
        status=ticket.status.label_agent if ticket.status else None,
        status_category=ticket.status_category,
        priority=(ticket.priority.name or ticket.priority.level) if ticket.priority else None,
        ticket_type=ticket.ticket_type.name if ticket.ticket_type else None,
        agent_group=ticket.team.team_name if ticket.team else None,
        customer=ticket.customer.customer_name if ticket.customer else None,
        contact=ticket.contact,
        raised_by=ticket.raised_by,
    )}


def _get_sla(db: Session, ticket):
    """utils.py:get_sla — the SLA that applies to `ticket`, or None.

    Enabled + inside [start_date, end_date] (null bound = open); if the ticket
    has a priority, only SLAs that define it. Ordered default_sla ASC (Default
    last), ranked-before-unranked, rank ASC, creation ASC; a default_sla row
    wins immediately, a blank condition is skipped, otherwise first truthy
    condition wins."""
    today = datetime.utcnow().date()
    cands = (
        db.query(HDServiceLevelAgreement)
        .filter(
            HDServiceLevelAgreement.tenant_id == ticket.tenant_id,
            HDServiceLevelAgreement.enabled == True,  # noqa: E712
        )
        .all()
    )
    cands = [
        s for s in cands
        if (s.start_date is None or s.start_date <= today)
        and (s.end_date is None or s.end_date >= today)
    ]
    if ticket.priority_id:
        cands = [s for s in cands
                 if any(p.priority_id == ticket.priority_id for p in s.priorities)]
    cands.sort(key=lambda s: (
        1 if s.default_sla else 0,        # Default considered last
        0 if (s.rank or 0) else 1,        # ranked before unranked (rank 0/None)
        s.rank or 0,
        s.created_at or datetime.min,
    ))

    context = None
    for s in cands:
        if s.default_sla:
            return s
        if not s.condition:
            continue  # a blank condition is not a false positive
        if context is None:
            context = _ctx(ticket)
        try:
            if eval(s.condition, {"__builtins__": {}}, context):  # noqa: S307
                # ponytail: restricted eval (no builtins) over label-resolved
                # ticket fields — same trust model as Frappe safe_eval
                # (tenant-admin-authored config). AST-allowlist if conditions
                # ever come from untrusted input.
                return s
        except Exception:
            continue
    return None


# ─── apply() sub-steps (hd_service_level_agreement.py) ────────────────────────
def _set_first_response_time(ticket, start, holidays, workdays):
    """set_first_response_time (:212)."""
    if not start or not ticket.first_responded_on:
        return
    ticket.first_response_time = _calc_elapsed_time(
        start, ticket.first_responded_on, holidays, workdays)
    if ticket.response_by and ticket.first_responded_on > ticket.response_by:
        ticket.first_response_failed_by = _calc_elapsed_time(
            ticket.response_by, ticket.first_responded_on, holidays, workdays)


def _set_hold_time(ticket, prev_status_category, now, holidays, workdays):
    """set_hold_time (:242). "Paused" is driven by status CATEGORY. Entering
    pause parks the deadlines + stamps on_hold_since; resuming nulls it and
    accrues the business-seconds held into total_hold_time."""
    was_paused = prev_status_category == PAUSED
    is_paused = ticket.status_category == PAUSED
    paused_since = ticket.on_hold_since
    if not paused_since and ticket.status_category != RESOLVED:
        # time spent resolved counts as hold only when reopened. ponytail: the
        # ticket core nulls the old resolution_date before recompute runs under
        # this wiring, so that fallback can only read what's still on the row.
        paused_since = ticket.resolution_date
    if is_paused and not was_paused:
        ticket.response_by = ticket.resolution_by if ticket.first_responded_on else None
        ticket.resolution_date = None
        ticket.resolution_by = None
        ticket.resolution_time = None
        ticket.on_hold_since = now
    elif not is_paused and was_paused:
        ticket.on_hold_since = None
    if is_paused or not paused_since:
        return
    ticket.on_hold_since = None
    ticket.total_hold_time = (ticket.total_hold_time or 0) + max(
        _calc_elapsed_time(paused_since, now, holidays, workdays), 0)


def _set_resolution_time(ticket, start, holidays, workdays):
    """set_resolution_time (:225) — effective business-seconds to resolve
    (hold time subtracted); resolution_failed_by if past the deadline."""
    if not ticket.resolution_date:
        return
    time_took = _calc_elapsed_time(start, ticket.resolution_date, holidays, workdays)
    ticket.resolution_time = max(time_took - (ticket.total_hold_time or 0), 0)
    if ticket.resolution_by and ticket.resolution_date > ticket.resolution_by:
        ticket.resolution_failed_by = _calc_elapsed_time(
            ticket.resolution_by, ticket.resolution_date, holidays, workdays)


def _handle_agreement_status(ticket, sla, now):
    """handle_agreement_status (:295) — first true wins: Failed → Paused →
    First Response Due → Resolution Due → Fulfilled. get_active_ticket_time =
    on_hold_since when paused else now."""
    active = ticket.on_hold_since or now
    first_failed = bool(ticket.response_by) and \
        ticket.response_by < (ticket.first_responded_on or active)
    reso_failed = bool(sla.apply_sla_for_resolution) and bool(ticket.resolution_by) and \
        ticket.resolution_by < (ticket.resolution_date or active)
    if first_failed or reso_failed:
        ticket.agreement_status = "Failed"
    elif ticket.on_hold_since:
        ticket.agreement_status = "Paused"
    elif not ticket.first_responded_on:
        ticket.agreement_status = "First Response Due"
    elif sla.apply_sla_for_resolution and not ticket.resolution_date:
        ticket.agreement_status = "Resolution Due"
    else:
        ticket.agreement_status = "Fulfilled"


# ─── public entry points ─────────────────────────────────────────────────────
def compute_sla_block(db: Session, ticket) -> dict:
    """§A4 nested `sla` block from the ticket's persisted SLA fields + policy.
    FE derives badge state from the timestamps, breach colour from `breached`
    (= status Failed). Safe when no SLA attaches (all null)."""
    status = ticket.agreement_status
    return {
        "policy": ticket.sla.service_level if ticket.sla else None,
        "agreement_status": status,
        "breached": status == "Failed",
        "first_responded_on": iso(ticket.first_responded_on),
        "resolution_date": iso(ticket.resolution_date),
        "response_by": iso(ticket.response_by),
        "resolution_by": iso(ticket.resolution_by),
        "on_hold_since": iso(ticket.on_hold_since),
        "first_response_failed_by": ticket.first_response_failed_by,
        "resolution_failed_by": ticket.resolution_failed_by,
        "total_hold_time": ticket.total_hold_time,
    }


def recompute(db: Session, ticket, *, prev_status_category: Optional[str] = None) -> None:
    """Apply the SLA after a status/field change — the native equivalent of
    set_sla + HDServiceLevelAgreement.apply (spec §1.1–§1.6). Mutates the
    ticket in place; the caller commits.

    Picks the policy via get_sla; with none, clear_sla_fields (hd_ticket.py:977)
    drops policy + targets while keeping the clock, keeping on_hold_since while
    Paused and agreement_status while Failed (both sticky). With a policy, runs
    apply() in Frappe's exact order so first-response/hold/resolution metrics
    read the OLD deadlines before handle_targets resets them."""
    now = datetime.utcnow()
    sla = _get_sla(db, ticket)
    if not sla:
        ticket.sla_id = None
        ticket.response_by = None
        ticket.resolution_by = None
        if ticket.status_category != PAUSED:
            ticket.on_hold_since = None
        if ticket.agreement_status != "Failed":
            ticket.agreement_status = None
        return

    ticket.sla_id = sla.id
    holidays = _holidays(sla)
    workdays = _workdays(sla)

    # 1. set_default_priority
    if not ticket.priority_id and sla.default_priority_id:
        ticket.priority_id = sla.default_priority_id
    # 2. start_clock — stamp the target anchor once, when the SLA attaches
    if not ticket.service_level_agreement_creation:
        ticket.service_level_agreement_creation = now
    start = ticket.service_level_agreement_creation
    # 3. handle_doc_status (order matters: reads the previous deadlines)
    _set_first_response_time(ticket, start, holidays, workdays)
    _set_hold_time(ticket, prev_status_category, now, holidays, workdays)
    _set_resolution_time(ticket, start, holidays, workdays)
    # 4. handle_targets — (re)compute response_by / resolution_by
    prow = _priority_row(sla, ticket.priority_id)
    resp_secs = (prow.response_time if prow else 0) or 0
    reso_secs = (prow.resolution_time if prow else 0) or 0
    ticket.response_by = _calc_time(start, resp_secs, holidays, workdays)
    ticket.resolution_by = _calc_time(
        start, reso_secs, holidays, workdays, hold_time=ticket.total_hold_time or 0)
    # 5. handle_agreement_status
    _handle_agreement_status(ticket, sla, now)


def _fmt_duration(secs) -> str:
    """Seconds → human string (`4h`, `2d`, `4h 30m`) for the config table."""
    secs = int(secs or 0)
    if secs <= 0:
        return "0"
    d, rem = divmod(secs, 86400)
    h, rem = divmod(rem, 3600)
    m, s = divmod(rem, 60)
    parts = []
    if d:
        parts.append(f"{d}d")
    if h:
        parts.append(f"{h}h")
    if m:
        parts.append(f"{m}m")
    if s:
        parts.append(f"{s}s")
    return " ".join(parts)


def _pick_config_sla(db: Session, tid):
    """Representative policy for the config view: default first, else best-ranked
    (the inverse of selection, which considers Default last)."""
    slas = (
        db.query(HDServiceLevelAgreement)
        .filter(
            HDServiceLevelAgreement.tenant_id == tid,
            HDServiceLevelAgreement.enabled == True,  # noqa: E712
        )
        .all()
    )
    if not slas:
        return None
    slas.sort(key=lambda s: (
        0 if s.default_sla else 1,
        0 if (s.rank or 0) else 1,
        s.rank or 0,
        s.created_at or datetime.min,
    ))
    return slas[0]


def config(db: Session, tid: int) -> dict:
    """§A20 read-only SLA config. Targets per priority (pre-formatted durations),
    service days as HH:MM:SS, holiday list, and auto_assignment = any team has an
    assignment rule (the assignment agent owns the rule logic). 200-safe: empty
    shape when nothing is configured."""
    sla = _pick_config_sla(db, tid)
    sla_block = {"policy": None, "priorities": [], "service_days": [], "holiday_list": None}
    if sla:
        sla_block = {
            "policy": sla.service_level,
            "priorities": [
                {
                    "priority": (p.priority.name or p.priority.level) if p.priority else None,
                    "response": _fmt_duration(p.response_time),
                    "resolution": _fmt_duration(p.resolution_time),
                }
                for p in sla.priorities
            ],
            "service_days": [
                {
                    "day": d.workday,
                    "start": d.start_time.strftime("%H:%M:%S") if d.start_time else None,
                    "end": d.end_time.strftime("%H:%M:%S") if d.end_time else None,
                }
                for d in sla.service_days
            ],
            "holiday_list": sla.holiday_list.holiday_list_name if sla.holiday_list else None,
        }
    auto_assignment = (
        db.query(HDTeam)
        .filter(
            HDTeam.tenant_id == tid,
            HDTeam.assignment_rule.isnot(None),
            HDTeam.assignment_rule != "",
        )
        .first()
        is not None
    )
    return {"sla": sla_block, "auto_assignment": auto_assignment, "managed": True}


if __name__ == "__main__":
    # Self-check for the business-hours math (no DB). 9–17 Mon–Fri.
    from types import SimpleNamespace

    wd = {d: SimpleNamespace(workday=d, start_time=dtime(9, 0), end_time=dtime(17, 0))
          for d in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]}
    mon = datetime(2024, 1, 1, 9, 0)   # 2024-01-01 is a Monday
    assert _calc_time(mon, 4 * 3600, set(), wd) == datetime(2024, 1, 1, 13, 0)
    assert _calc_time(mon, 8 * 3600, set(), wd) == datetime(2024, 1, 1, 17, 0)
    # spill into the next working day
    assert _calc_time(datetime(2024, 1, 1, 15, 0), 4 * 3600, set(), wd) == datetime(2024, 1, 2, 11, 0)
    # weekend skip: Fri 15:00 + 4h -> Mon 11:00
    assert _calc_time(datetime(2024, 1, 5, 15, 0), 4 * 3600, set(), wd) == datetime(2024, 1, 8, 11, 0)
    # hold time slides the resolution deadline out
    assert _calc_time(mon, 4 * 3600, set(), wd, hold_time=3600) == datetime(2024, 1, 1, 14, 0)
    # holiday skip
    assert _calc_time(mon, 8 * 3600, {datetime(2024, 1, 1).date()}, wd) == datetime(2024, 1, 2, 17, 0)
    # elapsed is the inverse
    assert _calc_elapsed_time(mon, datetime(2024, 1, 1, 13, 0), set(), wd) == 4 * 3600
    assert _calc_elapsed_time(datetime(2024, 1, 1, 16, 0), datetime(2024, 1, 2, 10, 0), set(), wd) == 2 * 3600
    assert _fmt_duration(14400) == "4h" and _fmt_duration(172800) == "2d"
    print("sla self-check ok")
