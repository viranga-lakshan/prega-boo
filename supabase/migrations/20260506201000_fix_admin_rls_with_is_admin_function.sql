-- Fix admin RLS for user_roles / midwife_profiles using a SECURITY DEFINER helper.
-- This avoids brittle self-references in policies and makes admin checks consistent.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.user_roles ur
    where ur.user_id = auth.uid()
      and ur.role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

alter table public.user_roles enable row level security;
alter table public.midwife_profiles enable row level security;

drop policy if exists "user_roles_select_admin_all" on public.user_roles;
create policy "user_roles_select_admin_all"
  on public.user_roles
  for select
  to authenticated
  using (public.is_admin());

drop policy if exists "user_roles_insert_admin_midwife" on public.user_roles;
create policy "user_roles_insert_admin_midwife"
  on public.user_roles
  for insert
  to authenticated
  with check (
    public.is_admin()
    and role = 'midwife'
  );

drop policy if exists "user_roles_update_admin_midwife" on public.user_roles;
create policy "user_roles_update_admin_midwife"
  on public.user_roles
  for update
  to authenticated
  using (public.is_admin())
  with check (
    public.is_admin()
    and role = 'midwife'
  );

drop policy if exists "midwife_profiles_select_admin_all" on public.midwife_profiles;
create policy "midwife_profiles_select_admin_all"
  on public.midwife_profiles
  for select
  to authenticated
  using (public.is_admin());

drop policy if exists "midwife_profiles_insert_admin" on public.midwife_profiles;
create policy "midwife_profiles_insert_admin"
  on public.midwife_profiles
  for insert
  to authenticated
  with check (public.is_admin());

drop policy if exists "midwife_profiles_update_admin" on public.midwife_profiles;
create policy "midwife_profiles_update_admin"
  on public.midwife_profiles
  for update
  to authenticated
  using (public.is_admin())
  with check (public.is_admin());
