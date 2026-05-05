-- Add mom profile photo support for manual registration.
-- 1) Store `photo_path` in `mom_profiles`
-- 2) Create `mom-photos` storage bucket + RLS policies for own-folder access

alter table public.mom_profiles
  add column if not exists photo_path text;

insert into storage.buckets (id, name, public)
values ('mom-photos', 'mom-photos', false)
on conflict (id) do nothing;

alter table storage.objects enable row level security;

drop policy if exists "mom_photos_select_own" on storage.objects;
create policy "mom_photos_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'mom-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "mom_photos_insert_own" on storage.objects;
create policy "mom_photos_insert_own"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'mom-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  );

drop policy if exists "mom_photos_update_own" on storage.objects;
create policy "mom_photos_update_own"
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'mom-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  )
  with check (
    bucket_id = 'mom-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  );
