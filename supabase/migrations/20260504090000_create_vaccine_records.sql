-- Create vaccine_records table for storing vaccines added by midwife (and readable by mom)
-- Run via Supabase migrations.

create extension if not exists "pgcrypto";

create table if not exists public.vaccine_records (
  id uuid primary key default gen_random_uuid(),
  mom_user_id uuid not null references auth.users(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,
  vaccine_name text not null,
  dosage text not null,
  administered_on date not null default current_date,
  created_at timestamptz not null default now()
);

create index if not exists idx_vaccine_records_mom_user_id on public.vaccine_records(mom_user_id);
create index if not exists idx_vaccine_records_administered_on on public.vaccine_records(administered_on desc);

alter table public.vaccine_records enable row level security;

-- Ensure PostgREST client role can access (subject to RLS)
grant select, insert on public.vaccine_records to authenticated;

-- Mom can read their own vaccine records
drop policy if exists "vaccine_records_select_own_mom" on public.vaccine_records;
create policy "vaccine_records_select_own_mom"
  on public.vaccine_records
  for select
  to authenticated
  using (auth.uid() = mom_user_id);

-- Midwife can read vaccine records for moms in same district
drop policy if exists "vaccine_records_select_midwife_same_district" on public.vaccine_records;
create policy "vaccine_records_select_midwife_same_district"
  on public.vaccine_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = vaccine_records.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- Mom can insert their own records (optional; keeps app flexible)
drop policy if exists "vaccine_records_insert_own_mom" on public.vaccine_records;
create policy "vaccine_records_insert_own_mom"
  on public.vaccine_records
  for insert
  to authenticated
  with check (
    auth.uid() = mom_user_id
    and auth.uid() = created_by_user_id
  );

-- Midwife can insert for moms in same district
drop policy if exists "vaccine_records_insert_midwife_same_district" on public.vaccine_records;
create policy "vaccine_records_insert_midwife_same_district"
  on public.vaccine_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = vaccine_records.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );
