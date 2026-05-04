-- Migration: fix RLS for mom registration (mom_profiles)
-- Ensures the iOS app can upsert the authenticated mom's profile.

alter table if exists public.mom_profiles enable row level security;

-- Drop ALL policies on mom_profiles to remove conflicting scripts
-- (Supabase policiesdf are OR'ed; a permissive/blocked policy can break intended behavior.)
do $$
declare p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'mom_profiles'
  loop
    execute format('drop policy if exists %I on public.mom_profiles', p.policyname);
  end loop;
end $$;

-- MOM: can read only her own profile
drop policy if exists "mom_profiles_select_own" on public.mom_profiles;
create policy "mom_profiles_select_own"
  on public.mom_profiles
  for select
  to authenticated
  using (auth.uid() = user_id);

-- MOM: can insert only her own profile
drop policy if exists "mom_profiles_insert_own" on public.mom_profiles;
create policy "mom_profiles_insert_own"
  on public.mom_profiles
  for insert
  to authenticated
  with check (auth.uid() = user_id);

-- MOM: can update only her own profile
drop policy if exists "mom_profiles_update_own" on public.mom_profiles;
create policy "mom_profiles_update_own"
  on public.mom_profiles
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- MIDWIFE: can read moms only in the same district
-- (Used by the midwife moms list / details screens.)
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
