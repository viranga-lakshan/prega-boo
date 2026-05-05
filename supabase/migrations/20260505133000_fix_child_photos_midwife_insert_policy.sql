-- Fix: midwife child photo uploads failing with RLS 403 on storage.objects.
-- Reason: prior policy required midwife district == mom district for INSERT/UPDATE.
-- This version keeps mom "own folder" safety and allows authenticated midwives
-- to upload/read/update child photos in UUID-named mom folders.

insert into storage.buckets (id, name, public)
values ('child-photos', 'child-photos', false)
on conflict (id) do nothing;

alter table storage.objects enable row level security;

-- Clean up old policies if present.
drop policy if exists "child_photos_select_own" on storage.objects;
drop policy if exists "child_photos_select_midwife_same_district" on storage.objects;
drop policy if exists "child_photos_insert_own_or_midwife" on storage.objects;
drop policy if exists "child_photos_update_own_or_midwife" on storage.objects;

-- SELECT: moms can read their own folder.
create policy "child_photos_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'child-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  );

-- SELECT: midwives can read UUID mom folders (operational access).
create policy "child_photos_select_midwife_role"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'child-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
    and exists (
      select 1
      from public.user_roles ur
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
    )
  );

-- INSERT: moms can upload to own folder OR midwives can upload to UUID mom folders.
create policy "child_photos_insert_own_or_midwife_role"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'child-photos'
    and (
      split_part(name, '/', 1) = auth.uid()::text
      or (
        split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
        and exists (
          select 1
          from public.user_roles ur
          where ur.user_id = auth.uid()
            and ur.role = 'midwife'
        )
      )
    )
  );

-- UPDATE: same rule as insert.
create policy "child_photos_update_own_or_midwife_role"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'child-photos'
    and (
      split_part(name, '/', 1) = auth.uid()::text
      or (
        split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
        and exists (
          select 1
          from public.user_roles ur
          where ur.user_id = auth.uid()
            and ur.role = 'midwife'
        )
      )
    )
  )
  with check (
    bucket_id = 'child-photos'
    and (
      split_part(name, '/', 1) = auth.uid()::text
      or (
        split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
        and exists (
          select 1
          from public.user_roles ur
          where ur.user_id = auth.uid()
            and ur.role = 'midwife'
        )
      )
    )
  );
