-- Create child-level health records (vaccine, growth, clinic visits)
-- Run via Supabase migrations.

create extension if not exists "pgcrypto";

-- -----------------------------
-- Child Vaccine Records
-- -----------------------------
create table if not exists public.child_vaccine_records (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,

  administered_on date not null default current_date,
  vaccine_name text not null,
  dosage text not null,

  created_at timestamptz not null default now()
);

create index if not exists idx_child_vaccine_records_child_id on public.child_vaccine_records(child_id);
create index if not exists idx_child_vaccine_records_administered_on on public.child_vaccine_records(administered_on desc);

alter table public.child_vaccine_records enable row level security;

grant select, insert on public.child_vaccine_records to authenticated;

drop policy if exists "child_vaccine_records_select_own_mom" on public.child_vaccine_records;
create policy "child_vaccine_records_select_own_mom"
  on public.child_vaccine_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.child_profiles cp
      where cp.id = child_vaccine_records.child_id
        and cp.mom_user_id = auth.uid()
    )
  );

drop policy if exists "child_vaccine_records_select_midwife_same_district" on public.child_vaccine_records;
create policy "child_vaccine_records_select_midwife_same_district"
  on public.child_vaccine_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.child_profiles cp on cp.id = child_vaccine_records.child_id
      join public.mom_profiles mom on mom.user_id = cp.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

drop policy if exists "child_vaccine_records_insert_own_mom" on public.child_vaccine_records;
create policy "child_vaccine_records_insert_own_mom"
  on public.child_vaccine_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.child_profiles cp
      where cp.id = child_vaccine_records.child_id
        and cp.mom_user_id = auth.uid()
    )
  );

drop policy if exists "child_vaccine_records_insert_midwife_same_district" on public.child_vaccine_records;
create policy "child_vaccine_records_insert_midwife_same_district"
  on public.child_vaccine_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.child_profiles cp on cp.id = child_vaccine_records.child_id
      join public.mom_profiles mom on mom.user_id = cp.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- -----------------------------
-- Child Growth Records
-- -----------------------------
create table if not exists public.child_growth_records (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,

  measured_on date not null default current_date,
  weight_kg numeric not null,
  height_cm numeric not null,
  milestones text,
  notes text,

  created_at timestamptz not null default now()
);

create index if not exists idx_child_growth_records_child_id on public.child_growth_records(child_id);
create index if not exists idx_child_growth_records_measured_on on public.child_growth_records(measured_on desc);

alter table public.child_growth_records enable row level security;

grant select, insert on public.child_growth_records to authenticated;

drop policy if exists "child_growth_records_select_own_mom" on public.child_growth_records;
create policy "child_growth_records_select_own_mom"
  on public.child_growth_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.child_profiles cp
      where cp.id = child_growth_records.child_id
        and cp.mom_user_id = auth.uid()
    )
  );

drop policy if exists "child_growth_records_select_midwife_same_district" on public.child_growth_records;
create policy "child_growth_records_select_midwife_same_district"
  on public.child_growth_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.child_profiles cp on cp.id = child_growth_records.child_id
      join public.mom_profiles mom on mom.user_id = cp.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

drop policy if exists "child_growth_records_insert_own_mom" on public.child_growth_records;
create policy "child_growth_records_insert_own_mom"
  on public.child_growth_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.child_profiles cp
      where cp.id = child_growth_records.child_id
        and cp.mom_user_id = auth.uid()
    )
  );

drop policy if exists "child_growth_records_insert_midwife_same_district" on public.child_growth_records;
create policy "child_growth_records_insert_midwife_same_district"
  on public.child_growth_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.child_profiles cp on cp.id = child_growth_records.child_id
      join public.mom_profiles mom on mom.user_id = cp.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- -----------------------------
-- Child Clinic Visit Records
-- -----------------------------
create table if not exists public.child_clinic_visit_records (
  id uuid primary key default gen_random_uuid(),
  child_id uuid not null references public.child_profiles(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,

  visit_date date not null,
  visit_time text not null,
  purpose text not null,

  created_at timestamptz not null default now()
);

create index if not exists idx_child_clinic_visit_records_child_id on public.child_clinic_visit_records(child_id);
create index if not exists idx_child_clinic_visit_records_visit_date on public.child_clinic_visit_records(visit_date desc);

alter table public.child_clinic_visit_records enable row level security;

grant select, insert on public.child_clinic_visit_records to authenticated;

drop policy if exists "child_clinic_visit_records_select_own_mom" on public.child_clinic_visit_records;
create policy "child_clinic_visit_records_select_own_mom"
  on public.child_clinic_visit_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.child_profiles cp
      where cp.id = child_clinic_visit_records.child_id
        and cp.mom_user_id = auth.uid()
    )
  );

drop policy if exists "child_clinic_visit_records_select_midwife_same_district" on public.child_clinic_visit_records;
create policy "child_clinic_visit_records_select_midwife_same_district"
  on public.child_clinic_visit_records
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.child_profiles cp on cp.id = child_clinic_visit_records.child_id
      join public.mom_profiles mom on mom.user_id = cp.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

drop policy if exists "child_clinic_visit_records_insert_own_mom" on public.child_clinic_visit_records;
create policy "child_clinic_visit_records_insert_own_mom"
  on public.child_clinic_visit_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.child_profiles cp
      where cp.id = child_clinic_visit_records.child_id
        and cp.mom_user_id = auth.uid()
    )
  );

drop policy if exists "child_clinic_visit_records_insert_midwife_same_district" on public.child_clinic_visit_records;
create policy "child_clinic_visit_records_insert_midwife_same_district"
  on public.child_clinic_visit_records
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.child_profiles cp on cp.id = child_clinic_visit_records.child_id
      join public.mom_profiles mom on mom.user_id = cp.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );
