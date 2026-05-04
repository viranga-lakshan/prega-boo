-- Create clinic_visit_records table for storing mom clinic visit entries
-- Run via Supabase migrations.

create extension if not exists "pgcrypto";

create table if not exists public.clinic_visit_records (
  id uuid primary key default gen_random_uuid(),
  mom_user_id uuid not null references auth.users(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,

  visit_date date not null,
  visit_time text not null,
  purpose text not null,

  created_at timestamptz not null default now()
);

create index if not exists idx_clinic_visit_records_mom_user_id on public.clinic_visit_records(mom_user_id);
create index if not exists idx_clinic_visit_records_visit_date on public.clinic_visit_records(visit_date desc);

alter table public.clinic_visit_records enable row level security;

-- Ensure PostgREST client role can access (subject to RLS)
grant select, insert on public.clinic_visit_records to authenticated;

-- Mom can read their own clinic visit records
drop policy if exists "clinic_visit_records_select_own_mom" on public.clinic_visit_records;
create policy "clinic_visit_records_select_own_mom"
  on public.clinic_visit_records
  for select
  to authenticated
  using (auth.uid() = mom_user_id);

-- Midwife can read clinic visits for moms in same district
drop policy if exists "clinic_visit_records_select_midwife_same_district" on public.clinic_visit_records;
create policy "clinic_visit_records_select_midwife_same_district"
  on public.clinic_visit_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = clinic_visit_records.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- Mom can insert their own records (optional)
drop policy if exists "clinic_visit_records_insert_own_mom" on public.clinic_visit_records;
create policy "clinic_visit_records_insert_own_mom"
  on public.clinic_visit_records
  for insert
  to authenticated
  with check (
    auth.uid() = mom_user_id
    and auth.uid() = created_by_user_id
  );

-- Midwife can insert for moms in same district
drop policy if exists "clinic_visit_records_insert_midwife_same_district" on public.clinic_visit_records;
create policy "clinic_visit_records_insert_midwife_same_district"
  on public.clinic_visit_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = clinic_visit_records.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );
