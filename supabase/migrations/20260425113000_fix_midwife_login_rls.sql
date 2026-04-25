-- Migration: fix RLS for midwife login/registration
-- Ensures the iOS app can:
-- - INSERT a self role row into public.user_roles (mom/midwife only)
-- - SELECT its own role row from public.user_roles
-- - UPSERT its own profile row in public.midwife_profiles

-- =========================
-- 1) USER ROLES
-- =========================

alter table if exists public.user_roles enable row level security;

drop policy if exists "user_roles_select_own" on public.user_roles;
create policy "user_roles_select_own"
  on public.user_roles
  for select
  to authenticated
  using (auth.uid() = user_id);

-- Remove common conflicting policies (from earlier drafts/scripts)
drop policy if exists "user_roles_insert_mom_self" on public.user_roles;
drop policy if exists "user_roles_insert_own" on public.user_roles;
drop policy if exists "user_roles_insert_own_mom_or_midwife" on public.user_roles;

-- Allow a signed-in user to create ONLY their own role row,
-- and only for mom/midwife (never allow self-assign admin).
create policy "user_roles_insert_own_mom_or_midwife"
  on public.user_roles
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and role in ('mom', 'midwife')
  );

-- Block client-side role changes/deletes
drop policy if exists "user_roles_update_blocked" on public.user_roles;
create policy "user_roles_update_blocked"
  on public.user_roles
  for update
  to authenticated
  using (false);

drop policy if exists "user_roles_delete_blocked" on public.user_roles;
create policy "user_roles_delete_blocked"
  on public.user_roles
  for delete
  to authenticated
  using (false);


-- =========================
-- 2) MIDWIFE PROFILES
-- =========================

alter table if exists public.midwife_profiles enable row level security;

-- Remove common conflicting "blocked" policies (breaks in-app registration)
drop policy if exists "midwife_profiles_insert_blocked" on public.midwife_profiles;
drop policy if exists "midwife_profiles_update_blocked" on public.midwife_profiles;
drop policy if exists "midwife_profiles_delete_blocked" on public.midwife_profiles;

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
