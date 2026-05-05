-- Source of truth for Mom Track feature DB
-- Applied via: supabase/migrations/20260505153000_create_mom_track_entries.sql

-- Tracks mom-only entries for:
-- - weight tracker
-- - kick counter
-- - pregnancy tracker
-- - mood tracker

create table if not exists public.mom_track_entries (
  id uuid primary key default gen_random_uuid(),
  mom_user_id uuid not null references auth.users(id) on delete cascade,
  tracker_type text not null check (tracker_type in ('weight', 'kick', 'pregnancy', 'mood')),
  entry_date date not null default current_date,
  value_numeric double precision null,
  value_text text null,
  note text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_mom_track_entries_mom_type_date
  on public.mom_track_entries (mom_user_id, tracker_type, entry_date desc, created_at desc);

alter table public.mom_track_entries enable row level security;

drop policy if exists "mom_track_entries_select_own" on public.mom_track_entries;
create policy "mom_track_entries_select_own"
  on public.mom_track_entries
  for select
  to authenticated
  using (auth.uid() = mom_user_id);

drop policy if exists "mom_track_entries_insert_own" on public.mom_track_entries;
create policy "mom_track_entries_insert_own"
  on public.mom_track_entries
  for insert
  to authenticated
  with check (auth.uid() = mom_user_id);

drop policy if exists "mom_track_entries_update_own" on public.mom_track_entries;
create policy "mom_track_entries_update_own"
  on public.mom_track_entries
  for update
  to authenticated
  using (auth.uid() = mom_user_id)
  with check (auth.uid() = mom_user_id);
