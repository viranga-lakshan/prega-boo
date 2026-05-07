-- Midwife profile photos storage support.
-- Allows admin-managed uploads at registration and midwife self-access.

insert into storage.buckets (id, name, public)
values ('midwife-photos', 'midwife-photos', false)
on conflict (id) do nothing;

alter table storage.objects enable row level security;

drop policy if exists "midwife_photos_select_own" on storage.objects;
create policy "midwife_photos_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'midwife-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "midwife_photos_insert_own" on storage.objects;
create policy "midwife_photos_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'midwife-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "midwife_photos_update_own" on storage.objects;
create policy "midwife_photos_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'midwife-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'midwife-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "midwife_photos_select_admin_all" on storage.objects;
create policy "midwife_photos_select_admin_all"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'midwife-photos'
    and public.is_admin()
  );

drop policy if exists "midwife_photos_insert_admin_any_uuid_folder" on storage.objects;
create policy "midwife_photos_insert_admin_any_uuid_folder"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'midwife-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
    and public.is_admin()
  );

drop policy if exists "midwife_photos_update_admin_any_uuid_folder" on storage.objects;
create policy "midwife_photos_update_admin_any_uuid_folder"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'midwife-photos'
    and public.is_admin()
  )
  with check (
    bucket_id = 'midwife-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
    and public.is_admin()
  );
