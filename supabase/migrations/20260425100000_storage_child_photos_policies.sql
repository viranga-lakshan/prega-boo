-- Migration: Storage policies for child ID photos
-- Ensures authenticated moms can access their own folder and midwives can access moms in same district.

-- Ensure the bucket exists (safe if you already created it manually)
insert into storage.buckets (id, name, public)
values ('child-photos', 'child-photos', false)
on conflict (id) do nothing;

-- Storage uses RLS on storage.objects
alter table storage.objects enable row level security;

-- SELECT: mom can read own folder
drop policy if exists "child_photos_select_own" on storage.objects;
create policy "child_photos_select_own"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'child-photos'
    and split_part(name, '/', 1) = auth.uid()::text
  );

-- SELECT: midwife can read moms in same district
drop policy if exists "child_photos_select_midwife_same_district" on storage.objects;
create policy "child_photos_select_midwife_same_district"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'child-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = split_part(storage.objects.name, '/', 1)::uuid
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- INSERT: allow mom inserting to own folder OR midwife inserting for moms in same district
drop policy if exists "child_photos_insert_own_or_midwife" on storage.objects;
create policy "child_photos_insert_own_or_midwife"
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
          join public.midwife_profiles mp on mp.user_id = ur.user_id
          join public.mom_profiles mom on mom.user_id = split_part(storage.objects.name, '/', 1)::uuid
          where ur.user_id = auth.uid()
            and ur.role = 'midwife'
            and btrim(lower(mp.district)) = btrim(lower(mom.district))
        )
      )
    )
  );

-- UPDATE: allow overwriting an existing object in the same allowed paths
drop policy if exists "child_photos_update_own_or_midwife" on storage.objects;
create policy "child_photos_update_own_or_midwife"
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
          join public.midwife_profiles mp on mp.user_id = ur.user_id
          join public.mom_profiles mom on mom.user_id = split_part(storage.objects.name, '/', 1)::uuid
          where ur.user_id = auth.uid()
            and ur.role = 'midwife'
            and btrim(lower(mp.district)) = btrim(lower(mom.district))
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
          join public.midwife_profiles mp on mp.user_id = ur.user_id
          join public.mom_profiles mom on mom.user_id = split_part(storage.objects.name, '/', 1)::uuid
          where ur.user_id = auth.uid()
            and ur.role = 'midwife'
            and btrim(lower(mp.district)) = btrim(lower(mom.district))
        )
      )
    )
  );
