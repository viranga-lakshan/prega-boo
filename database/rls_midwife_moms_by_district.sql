-- RLS fix: Midwife can view only moms in the same district
-- Safe to run on an existing schema.

-- 1) Ensure RLS is enabled
alter table if exists public.user_roles enable row level security;
alter table if exists public.midwife_profiles enable row level security;
alter table if exists public.mom_profiles enable row level security;

-- 2) user_roles: midwife must be able to read their own role
-- (If you already have these, this just re-creates them.)
drop policy if exists "user_roles_select_own" on public.user_roles;
create policy "user_roles_select_own"
  on public.user_roles
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Optional: allow self-insert (used by in-app registration)
drop policy if exists "user_roles_insert_own" on public.user_roles;
create policy "user_roles_insert_own"
  on public.user_roles
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- 3) midwife_profiles: midwife must be able to read their own profile (district)
drop policy if exists "midwife_profiles_select_own" on public.midwife_profiles;
create policy "midwife_profiles_select_own"
  on public.midwife_profiles
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Optional: allow self insert/update (used by in-app registration)
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

-- 4) mom_profiles: midwife can SELECT moms only where districts match
-- IMPORTANT: this policy compares DISTRICT values after trimming & lowercasing.
-- NOTE: Supabase policies are OR'ed. If you have ANY other SELECT policy on mom_profiles
-- (e.g. `using (true)`), the midwife will see all moms. So we drop all SELECT policies
-- and recreate only the two allowed cases.
do $$
declare p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'mom_profiles'
      and lower(cmd) = 'select'
  loop
    execute format('drop policy if exists %I on public.mom_profiles', p.policyname);
  end loop;
end $$;

-- Mom can read only their own profile row
drop policy if exists "mom_profiles_select_own" on public.mom_profiles;
create policy "mom_profiles_select_own"
  on public.mom_profiles
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Midwife can read moms only in the same district
drop policy if exists "mom_profiles_select_midwife_same_district" on public.mom_profiles;
create policy "mom_profiles_select_midwife_same_district"
  on public.mom_profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(district))
    )
  );

-- Quick debug (run as postgres role, or use SQL editor):
-- select * from public.midwife_profiles;
-- select * from public.user_roles;
-- select district, count(*) from public.mom_profiles group by district;
