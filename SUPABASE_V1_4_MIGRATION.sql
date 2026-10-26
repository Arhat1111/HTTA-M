-- ============================================================
-- HTTA v1.4 MIGRATION
-- Run this ONCE in Supabase -> SQL Editor BEFORE uploading v1.4.
-- It preserves the existing students/payments and creates a proper
-- fee-cycle ledger so changing fees does not double-count payments.
-- ============================================================

-- Allow any positive number of months instead of only 1/3/12.
alter table public.students
  drop constraint if exists students_plan_months_check;

alter table public.students
  add constraint students_plan_months_check
  check (plan_months >= 1 and plan_months <= 60);

alter table public.payments
  drop constraint if exists payments_plan_months_check;

alter table public.payments
  add constraint payments_plan_months_check
  check (plan_months >= 1 and plan_months <= 60);

alter table public.renewals
  drop constraint if exists renewals_plan_months_check;

alter table public.renewals
  add constraint renewals_plan_months_check
  check (plan_months >= 1 and plan_months <= 60);


-- Store the ACTUAL total fee for a student's current plan/cycle.
-- monthly_fee remains only for backward compatibility.
alter table public.students
  add column if not exists plan_fee_amount numeric(12,2) not null default 0;

update public.students
set plan_fee_amount =
  case
    when plan_fee_amount > 0 then plan_fee_amount
    else coalesce(monthly_fee,0) * greatest(coalesce(plan_months,1),1)
  end;


-- Fee-cycle ledger.
create table if not exists public.fee_cycles (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  cycle_type text not null default 'regular'
    check (cycle_type in ('regular','legacy_balance')),
  cycle_start date,
  cycle_end date,
  months integer not null default 1 check (months >= 1 and months <= 60),
  fee_amount numeric(12,2) not null default 0 check (fee_amount >= 0),
  amount_paid numeric(12,2) not null default 0 check (amount_paid >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists fee_cycles_student_regular_start_uidx
on public.fee_cycles(student_id, cycle_start)
where cycle_type='regular' and cycle_start is not null;

create index if not exists fee_cycles_student_idx
on public.fee_cycles(student_id);

create index if not exists fee_cycles_start_idx
on public.fee_cycles(cycle_start);

drop trigger if exists fee_cycles_updated_at on public.fee_cycles;
create trigger fee_cycles_updated_at
before update on public.fee_cycles
for each row execute function public.htta_set_updated_at();


-- Backfill each student's CURRENT cycle.
-- This preserves the current pending total:
--  * if pending <= current cycle fee, the difference is treated as paid
--  * if pending > current cycle fee, excess becomes a legacy balance row
insert into public.fee_cycles (
  student_id, cycle_type, cycle_start, cycle_end, months, fee_amount, amount_paid
)
select
  s.id,
  'regular',
  s.cycle_start,
  s.cycle_end,
  greatest(s.plan_months,1),
  s.plan_fee_amount,
  greatest(
    0,
    s.plan_fee_amount - least(coalesce(s.pending_amount,0), s.plan_fee_amount)
  )
from public.students s
where s.cycle_start is not null
on conflict do nothing;


insert into public.fee_cycles (
  student_id, cycle_type, cycle_start, cycle_end, months, fee_amount, amount_paid
)
select
  s.id,
  'legacy_balance',
  null,
  null,
  1,
  greatest(coalesce(s.pending_amount,0) - s.plan_fee_amount,0),
  0
from public.students s
where coalesce(s.pending_amount,0) > s.plan_fee_amount
  and not exists (
    select 1
    from public.fee_cycles fc
    where fc.student_id=s.id
      and fc.cycle_type='legacy_balance'
  );


-- Security for the new table.
alter table public.fee_cycles enable row level security;
revoke all on public.fee_cycles from anon;
grant select, insert, update, delete on public.fee_cycles to authenticated;

drop policy if exists "HTTA authenticated fee cycles" on public.fee_cycles;
create policy "HTTA authenticated fee cycles"
on public.fee_cycles
for all
to authenticated
using (true)
with check (true);


-- Keep existing setting for compatibility, but no fixed fee is used.
update public.academy_settings
set reminder_lead_days=3,
    default_monthly_fee=0
where id=1;


-- Final verification.
select
  (select count(*) from public.students) as students,
  (select count(*) from public.payments) as payments,
  (select count(*) from public.fee_cycles) as fee_cycles;
