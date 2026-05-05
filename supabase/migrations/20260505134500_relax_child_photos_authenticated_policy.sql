-- Hotfix: child photo uploads still blocked by Storage RLS.
-- This policy set prioritizes functionality: any authenticated user can
-- read/insert/update objects in `child-photos` when the first folder segment is a UUID.
-- (You can tighten this later with role/district constraints once production is stable.)

insert into storage.buckets (id, name, public)
values ('child-photos', 'child-photos', false)
on conflict (id) do nothing;

alter table storage.objects enable row level security;

drop policy if exists "child_photos_select_own" on storage.objects;
drop policy if exists "child_photos_select_midwife_same_district" on storage.objects;
drop policy if exists "child_photos_select_midwife_role" on storage.objects;
drop policy if exists "child_photos_insert_own_or_midwife" on storage.objects;
drop policy if exists "child_photos_insert_own_or_midwife_role" on storage.objects;
drop policy if exists "child_photos_update_own_or_midwife" on storage.objects;
drop policy if exists "child_photos_update_own_or_midwife_role" on storage.objects;

create policy "child_photos_select_authenticated_uuid_folder"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'child-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
  );

create policy "child_photos_insert_authenticated_uuid_folder"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'child-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
  );

create policy "child_photos_update_authenticated_uuid_folder"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'child-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
  )
  with check (
    bucket_id = 'child-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
  );
