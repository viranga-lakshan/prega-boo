-- Mom-owned reminders (custom tasks + notification preference in DB).
-- Clinic-derived reminders still come from clinic_visit_* tables in the app; this table stores user/midwife-added rows.

create extension if not exists "pgcrypto";

create table if not exists public.mom_reminders (
  id uuid primary key default gen_random_uuid(),
  mom_user_id uuid not null references auth.users(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,
  child_id uuid references public.child_profiles(id) on delete cascade,

  title text not null,
  reminder_date date not null,
  reminder_time text not null,
  metadata text,
  reminder_tag text not null default 'health' check (reminder_tag in ('health', 'pediatric')),
  icon_name text,

  notification_enabled boolean not null default true,
  status text not null default 'scheduled' check (status in ('scheduled', 'completed', 'dismissed')),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_mom_reminders_mom_user_id on public.mom_reminders(mom_user_id);
create index if not exists idx_mom_reminders_reminder_date on public.mom_reminders(reminder_date desc);
create index if not exists idx_mom_reminders_status on public.mom_reminders(status);

alter table public.mom_reminders enable row level security;

grant select, insert, update on public.mom_reminders to authenticated;

-- Mom: read own reminders
drop policy if exists "mom_reminders_select_own_mom" on public.mom_reminders;
create policy "mom_reminders_select_own_mom"
  on public.mom_reminders
  for select
  to authenticated
  using (auth.uid() = mom_user_id);

-- Midwife: read for moms in same district
drop policy if exists "mom_reminders_select_midwife_same_district" on public.mom_reminders;
create policy "mom_reminders_select_midwife_same_district"
  on public.mom_reminders
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = mom_reminders.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- Mom: insert own reminders
drop policy if exists "mom_reminders_insert_own_mom" on public.mom_reminders;
create policy "mom_reminders_insert_own_mom"
  on public.mom_reminders
  for insert
  to authenticated
  with check (
    auth.uid() = mom_user_id
    and auth.uid() = created_by_user_id
  );

-- Midwife: insert for moms in same district
drop policy if exists "mom_reminders_insert_midwife_same_district" on public.mom_reminders;
create policy "mom_reminders_insert_midwife_same_district"
  on public.mom_reminders
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = mom_reminders.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- Mom: update own reminders (toggle notifications, complete, etc.)
drop policy if exists "mom_reminders_update_own_mom" on public.mom_reminders;
create policy "mom_reminders_update_own_mom"
  on public.mom_reminders
  for update
  to authenticated
  using (auth.uid() = mom_user_id)
  with check (auth.uid() = mom_user_id);

-- Midwife: update for same-district moms
drop policy if exists "mom_reminders_update_midwife_same_district" on public.mom_reminders;
create policy "mom_reminders_update_midwife_same_district"
  on public.mom_reminders
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = mom_reminders.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  )
  with check (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = mom_reminders.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );
