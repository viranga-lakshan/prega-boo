-- Migration: create mom profiles table
-- Source: database/mom_profiles.sql

-- Optional (usually already enabled on Supabase)
create extension if not exists "pgcrypto";

-- Stores mom profile details linked to Supabase Auth user.
create table if not exists public.mom_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,

  full_name text not null,
  contact_number text not null,
  district text not null,

  -- last menstrual period (first day)
  lmp_date date,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  unique (user_id)
);

-- Auto-update updated_at
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_mom_profiles_set_updated_at on public.mom_profiles;
create trigger trg_mom_profiles_set_updated_at
before update on public.mom_profiles
for each row execute function public.set_updated_at();

-- Row Level Security
alter table public.mom_profiles enable row level security;

-- Policies: only the owning authenticated user can read/write their profile
drop policy if exists "mom_profiles_select_own" on public.mom_profiles;
create policy "mom_profiles_select_own"
  on public.mom_profiles
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "mom_profiles_insert_own" on public.mom_profiles;
create policy "mom_profiles_insert_own"
  on public.mom_profiles
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "mom_profiles_update_own" on public.mom_profiles;
create policy "mom_profiles_update_own"
  on public.mom_profiles
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Optional: prevent deletes from client apps (keep server-only)
-- drop policy if exists "mom_profiles_delete_own" on public.mom_profiles;
-- create policy "mom_profiles_delete_own"
--   on public.mom_profiles
--   for delete
--   to authenticated
--   using (false);
