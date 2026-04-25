-- Migration: create roles + midwife profiles (+ midwife read access to moms list)
-- Source: database/roles_midwife_profiles.sql

create extension if not exists "pgcrypto";

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
begin
  create type public.app_role as enum ('mom', 'midwife', 'admin');
exception
  when duplicate_object then null;
end $$;

create table if not exists public.user_roles (
  user_id uuid not null primary key references auth.users(id) on delete cascade,
  role public.app_role not null,
  created_at timestamptz not null default now()
);

alter table public.user_roles enable row level security;

drop policy if exists "user_roles_select_own" on public.user_roles;
create policy "user_roles_select_own"
  on public.user_roles
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "user_roles_insert_own" on public.user_roles;
create policy "user_roles_insert_own"
  on public.user_roles
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and role in ('mom', 'midwife')
  );

create table if not exists public.midwife_profiles (
  id uuid not null default gen_random_uuid(),
  user_id uuid not null,
  full_name text not null,
  district text not null,
  nic_number text not null,
  photo_path text null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint midwife_profiles_pkey primary key (id),
  constraint midwife_profiles_nic_number_key unique (nic_number),
  constraint midwife_profiles_user_id_key unique (user_id),
  constraint midwife_profiles_user_id_fkey foreign key (user_id) references auth.users (id) on delete cascade
) tablespace pg_default;

drop trigger if exists trg_midwife_profiles_set_updated_at on public.midwife_profiles;
create trigger trg_midwife_profiles_set_updated_at
before update on public.midwife_profiles
for each row execute function public.set_updated_at();

alter table public.midwife_profiles enable row level security;

drop policy if exists "midwife_profiles_select_own" on public.midwife_profiles;
create policy "midwife_profiles_select_own"
  on public.midwife_profiles
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "midwife_profiles_insert_own" on public.midwife_profiles;
create policy "midwife_profiles_insert_own"
  on public.midwife_profiles
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "midwife_profiles_update_own" on public.midwife_profiles;
create policy "midwife_profiles_update_own"
  on public.midwife_profiles
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

alter table if exists public.mom_profiles enable row level security;

drop policy if exists "mom_profiles_select_midwife" on public.mom_profiles;
create policy "mom_profiles_select_midwife"
  on public.mom_profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp
        on mp.user_id = ur.user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(district))
    )
  );
