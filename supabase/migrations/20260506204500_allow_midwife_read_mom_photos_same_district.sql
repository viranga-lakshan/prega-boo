-- Allow midwives to read mom profile photos for moms in the same district.
-- Keeps mom self-access policy intact.

insert into storage.buckets (id, name, public)
values ('mom-photos', 'mom-photos', false)
on conflict (id) do nothing;

alter table storage.objects enable row level security;

drop policy if exists "mom_photos_select_midwife_same_district" on storage.objects;
create policy "mom_photos_select_midwife_same_district"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'mom-photos'
    and split_part(name, '/', 1) ~ '^[0-9a-fA-F-]{36}$'
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp
        on mp.user_id = ur.user_id
      join public.mom_profiles mom
        on mom.user_id = split_part(name, '/', 1)::uuid
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );
