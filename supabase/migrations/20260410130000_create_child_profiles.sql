-- Migration: create child profiles table + RLS
-- Source: database/child_profiles.sql

create extension if not exists "pgcrypto";

create table if not exists public.child_profiles (
  id uuid primary key default gen_random_uuid(),
  mom_user_id uuid not null references auth.users(id) on delete cascade,
  full_name text not null,
  birth_date date not null,

  gender text,
  delivery_method text,
  notes text,
  id_photo_path text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table if exists public.child_profiles
  add column if not exists gender text,
  add column if not exists delivery_method text,
  add column if not exists notes text,
  add column if not exists id_photo_path text;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_child_profiles_set_updated_at on public.child_profiles;
create trigger trg_child_profiles_set_updated_at
before update on public.child_profiles
for each row execute function public.set_updated_at();

alter table public.child_profiles enable row level security;

drop policy if exists "child_profiles_select_own_mom" on public.child_profiles;
create policy "child_profiles_select_own_mom"
  on public.child_profiles
  for select
  to authenticated
  using (auth.uid() = mom_user_id);

drop policy if exists "child_profiles_select_midwife_same_district" on public.child_profiles;
create policy "child_profiles_select_midwife_same_district"
  on public.child_profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = child_profiles.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

drop policy if exists "child_profiles_insert_midwife_same_district" on public.child_profiles;
create policy "child_profiles_insert_midwife_same_district"
  on public.child_profiles
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = child_profiles.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );
