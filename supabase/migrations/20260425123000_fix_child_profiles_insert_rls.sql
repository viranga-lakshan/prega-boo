-- Migration: fix child_profiles RLS for baby registration
-- Resets child_profiles policies to avoid conflicts from previous scripts.

alter table if exists public.child_profiles enable row level security;

-- Drop all existing policies on child_profiles to remove conflicting rules.
do $$
declare p record;
begin
  for p in
    select policyname
    from pg_policies
    where schemaname = 'public'
      and tablename = 'child_profiles'
  loop
    execute format('drop policy if exists %I on public.child_profiles', p.policyname);
  end loop;
end $$;

-- MOM: read own children
create policy "child_profiles_select_own_mom"
  on public.child_profiles
  for select
  to authenticated
  using (auth.uid() = mom_user_id);

-- MOM: insert own child (optional but safe)
create policy "child_profiles_insert_own_mom"
  on public.child_profiles
  for insert
  to authenticated
  with check (auth.uid() = mom_user_id);

-- MIDWIFE: read children for moms in same district
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

-- MIDWIFE: insert child only for moms in same district
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
