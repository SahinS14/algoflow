-- Run this once in Supabase Dashboard → SQL Editor.
create table if not exists public.dsa_access (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  approved boolean not null default false,
  requested_at timestamptz not null default now()
);

alter table public.dsa_access enable row level security;
revoke all on table public.dsa_access from anon;
grant select, insert on table public.dsa_access to authenticated;

drop policy if exists "Users can view their own access request" on public.dsa_access;
create policy "Users can view their own access request"
  on public.dsa_access for select to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "Users can request access" on public.dsa_access;
create policy "Users can request access"
  on public.dsa_access for insert to authenticated
  with check ((select auth.uid()) = user_id and approved = false);

create table if not exists public.dsa_progress (
  user_id uuid primary key references auth.users(id) on delete cascade,
  solved jsonb not null default '{}'::jsonb,
  bookmarks jsonb not null default '{}'::jsonb,
  target jsonb,
  updated_at timestamptz not null default now()
);

alter table public.dsa_progress enable row level security;

revoke all on table public.dsa_progress from anon;
grant select, insert, update on table public.dsa_progress to authenticated;

drop policy if exists "Users can read their own DSA progress" on public.dsa_progress;
create policy "Users can read their own DSA progress"
  on public.dsa_progress for select to authenticated
  using ((select auth.uid()) = user_id and exists (select 1 from public.dsa_access where user_id = (select auth.uid()) and approved = true));

drop policy if exists "Users can create their own DSA progress" on public.dsa_progress;
create policy "Users can create their own DSA progress"
  on public.dsa_progress for insert to authenticated
  with check ((select auth.uid()) = user_id and exists (select 1 from public.dsa_access where user_id = (select auth.uid()) and approved = true));

drop policy if exists "Users can update their own DSA progress" on public.dsa_progress;
create policy "Users can update their own DSA progress"
  on public.dsa_progress for update to authenticated
  using ((select auth.uid()) = user_id and exists (select 1 from public.dsa_access where user_id = (select auth.uid()) and approved = true))
  with check ((select auth.uid()) = user_id and exists (select 1 from public.dsa_access where user_id = (select auth.uid()) and approved = true));
