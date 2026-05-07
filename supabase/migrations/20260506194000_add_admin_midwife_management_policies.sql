-- Allow ADMIN users to manage midwife accounts from the app.
-- This keeps self-service policies intact and adds admin-only capabilities.

alter table public.user_roles enable row level security;
alter table public.midwife_profiles enable row level security;

drop policy if exists "user_roles_select_admin_all" on public.user_roles;
create policy "user_roles_select_admin_all"
  on public.user_roles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles me
      where me.user_id = auth.uid()
        and me.role = 'admin'
    )
  );

drop policy if exists "user_roles_insert_admin_midwife" on public.user_roles;
create policy "user_roles_insert_admin_midwife"
  on public.user_roles
  for insert
  to authenticated
  with check (
    role = 'midwife'
    and exists (
      select 1
      from public.user_roles me
      where me.user_id = auth.uid()
        and me.role = 'admin'
    )
  );

drop policy if exists "user_roles_update_admin_midwife" on public.user_roles;
create policy "user_roles_update_admin_midwife"
  on public.user_roles
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles me
      where me.user_id = auth.uid()
        and me.role = 'admin'
    )
  )
  with check (
    role = 'midwife'
    and exists (
      select 1
      from public.user_roles me
      where me.user_id = auth.uid()
        and me.role = 'admin'
    )
  );

drop policy if exists "midwife_profiles_select_admin_all" on public.midwife_profiles;
create policy "midwife_profiles_select_admin_all"
  on public.midwife_profiles
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles me
      where me.user_id = auth.uid()
        and me.role = 'admin'
    )
  );

drop policy if exists "midwife_profiles_insert_admin" on public.midwife_profiles;
create policy "midwife_profiles_insert_admin"
  on public.midwife_profiles
  for insert
  to authenticated
  with check (
    exists (
      select 1
      from public.user_roles me
      where me.user_id = auth.uid()
        and me.role = 'admin'
    )
  );

drop policy if exists "midwife_profiles_update_admin" on public.midwife_profiles;
create policy "midwife_profiles_update_admin"
  on public.midwife_profiles
  for update
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles me
      where me.user_id = auth.uid()
        and me.role = 'admin'
    )
  )
  with check (
    exists (
      select 1
      from public.user_roles me
      where me.user_id = auth.uid()
        and me.role = 'admin'
    )
  );
