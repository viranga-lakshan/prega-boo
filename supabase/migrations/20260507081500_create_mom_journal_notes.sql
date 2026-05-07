-- Mom journal notes (Note · Journal feature).
-- Midwives in the same district as the mom can read/write; admins can read; mom can read her own.

create extension if not exists "pgcrypto";

create table if not exists public.mom_journal_notes (
  id uuid primary key default gen_random_uuid(),
  mom_user_id uuid not null references auth.users(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete restrict,
  author_role text not null check (author_role in ('mom', 'midwife', 'admin')),
  child_id uuid references public.child_profiles(id) on delete cascade,

  title text not null,
  body text not null default '',

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_mom_journal_notes_mom_user_id on public.mom_journal_notes(mom_user_id);
create index if not exists idx_mom_journal_notes_created_at on public.mom_journal_notes(created_at desc);

alter table public.mom_journal_notes enable row level security;

grant select, insert, update, delete on public.mom_journal_notes to authenticated;

-- Updated_at maintenance trigger (idempotent).
create or replace function public.set_mom_journal_notes_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_mom_journal_notes_updated_at on public.mom_journal_notes;
create trigger trg_mom_journal_notes_updated_at
  before update on public.mom_journal_notes
  for each row execute function public.set_mom_journal_notes_updated_at();

-- Mom: read own.
drop policy if exists "mom_journal_notes_select_own_mom" on public.mom_journal_notes;
create policy "mom_journal_notes_select_own_mom"
  on public.mom_journal_notes
  for select
  to authenticated
  using (auth.uid() = mom_user_id);

-- Midwife: read for moms in the same district.
drop policy if exists "mom_journal_notes_select_midwife_same_district" on public.mom_journal_notes;
create policy "mom_journal_notes_select_midwife_same_district"
  on public.mom_journal_notes
  for select
  to authenticated
  using (
    exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = mom_journal_notes.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- Admin: read all (uses public.is_admin defined in earlier migration).
drop policy if exists "mom_journal_notes_select_admin" on public.mom_journal_notes;
create policy "mom_journal_notes_select_admin"
  on public.mom_journal_notes
  for select
  to authenticated
  using (public.is_admin());

-- Mom: insert own (author_role must be 'mom').
drop policy if exists "mom_journal_notes_insert_own_mom" on public.mom_journal_notes;
create policy "mom_journal_notes_insert_own_mom"
  on public.mom_journal_notes
  for insert
  to authenticated
  with check (
    auth.uid() = mom_user_id
    and auth.uid() = created_by_user_id
    and author_role = 'mom'
  );

-- Midwife: insert for moms in same district.
drop policy if exists "mom_journal_notes_insert_midwife_same_district" on public.mom_journal_notes;
create policy "mom_journal_notes_insert_midwife_same_district"
  on public.mom_journal_notes
  for insert
  to authenticated
  with check (
    auth.uid() = created_by_user_id
    and author_role = 'midwife'
    and exists (
      select 1
      from public.user_roles ur
      join public.midwife_profiles mp on mp.user_id = ur.user_id
      join public.mom_profiles mom on mom.user_id = mom_journal_notes.mom_user_id
      where ur.user_id = auth.uid()
        and ur.role = 'midwife'
        and btrim(lower(mp.district)) = btrim(lower(mom.district))
    )
  );

-- Author: update own notes (mom or midwife).
drop policy if exists "mom_journal_notes_update_author" on public.mom_journal_notes;
create policy "mom_journal_notes_update_author"
  on public.mom_journal_notes
  for update
  to authenticated
  using (auth.uid() = created_by_user_id)
  with check (auth.uid() = created_by_user_id);

-- Author: delete own notes.
drop policy if exists "mom_journal_notes_delete_author" on public.mom_journal_notes;
create policy "mom_journal_notes_delete_author"
  on public.mom_journal_notes
  for delete
  to authenticated
  using (auth.uid() = created_by_user_id);
