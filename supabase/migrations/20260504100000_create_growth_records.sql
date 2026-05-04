-- Create growth_records table for storing mom growth tracking entries
-- Run via Supabase migrations.

create extension if not exists "pgcrypto";

create table if not exists public.growth_records (
  id uuid primary key default gen_random_uuid(),
  mom_user_id uuid not null references auth.users(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,

  measured_on date not null default current_date,
  weight_kg numeric not null,
  height_cm numeric not null,
  milestones text,
  notes text,

  created_at timestamptz not null default now()
);

create index if not exists idx_growth_records_mom_user_id on public.growth_records(mom_user_id);
create index if not exists idx_growth_records_measured_on on public.growth_records(measured_on desc);

alter table public.growth_records enable row level security;

-- Ensure PostgREST client role can access (subject to RLS)
grant select, insert on public.growth_records to authenticated;

-- Mom can read their own growth records
drop policy if exists "growth_records_select_own_mom" on public.growth_records;
create policy "growth_records_select_own_mom"
  on public.growth_records
  for select
  to authenticated
  using (auth.uid() = mom_user_id);

-- Midwife can read growth records for moms in same district
drop policy if exists "growth_records_select_midwife_same_district" on public.growth_records;
create policy "growth_records_select_midwife_same_district"
  on public.growth_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = growth_records.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- Mom can insert their own records (optional)
drop policy if exists "growth_records_insert_own_mom" on public.growth_records;
create policy "growth_records_insert_own_mom"
  on public.growth_records
  for insert
  to authenticated
  with check (
    auth.uid() = mom_user_id
    and auth.uid() = created_by_user_id
  );

-- Midwife can insert for moms in same district
drop policy if exists "growth_records_insert_midwife_same_district" on public.growth_records;
create policy "growth_records_insert_midwife_same_district"
  on public.growth_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = growth_records.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );
