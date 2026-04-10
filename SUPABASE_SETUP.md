# Supabase setup (Prega-Boo)

## Create the `mom_profiles` table (Dashboard method)
1. Open your Supabase project.
2. Left sidebar → **SQL Editor**.
3. Click **New query**.
4. Paste the contents of `database/mom_profiles.sql` (or `supabase/migrations/20260410120000_create_mom_profiles.sql`).
5. Click **Run**.
6. Go to **Database → Tables**, make sure schema is `public`, then refresh.

### Quick verify
Run:
```sql
select to_regclass('public.mom_profiles') as table_name;
```
If it returns `public.mom_profiles`, the table exists.

## Create roles + `user_roles` + `midwife_profiles`
Run the SQL in `database/roles_midwife_profiles.sql` (or the migration `supabase/migrations/20260410123000_create_roles_and_midwife_profiles.sql`).

### What it adds
- `public.app_role` enum: `mom`, `midwife`, `admin`
- `public.user_roles` table (RLS: users can read/insert their own role row)
- `public.midwife_profiles` table (RLS: midwife can read/write own profile)
- Extra RLS policy on `public.mom_profiles` so a **midwife** can `SELECT` all moms (needed for the “Moms List” screen)

### Quick verify
```sql
select to_regclass('public.user_roles') as user_roles;
select to_regclass('public.midwife_profiles') as midwife_profiles;

-- Verify your midwife can view moms (after creating a midwife user + role)
select count(*) from public.mom_profiles;
```

## Fix midwife district-only moms list (existing schema)
If your tables already exist but the midwife sees an empty list, run:
- `database/rls_midwife_moms_by_district.sql`

This re-creates the needed RLS policies so a midwife can only `SELECT` moms where:
- `user_roles.role = 'midwife'`
- `midwife_profiles.district` matches `mom_profiles.district` (trimmed + case-insensitive)

Note: Supabase policies are OR'ed. The fix script drops any other `SELECT` policies on `mom_profiles` that may accidentally allow a midwife to read all moms.

## Create `child_profiles` (midwife adds children)
Run `database/child_profiles.sql` (or `supabase/migrations/20260410130000_create_child_profiles.sql`).

This adds a `public.child_profiles` table and RLS so:
- A mom can read her own children
- A midwife can read/insert children only for moms in the same district

## Create the table (Supabase CLI method, optional)
This is useful when you want repeatable migrations.

### Install CLI (macOS)
```bash
brew install supabase/tap/supabase
```

### Link to your project
In your repo root:
```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

### Push migrations
```bash
supabase db push
```

> Note: CLI workflows may require Docker depending on your setup.
