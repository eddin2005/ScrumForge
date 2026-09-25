-- ============================================================================
-- ScrumForge Platform — Supabase schema v2 (run in Supabase SQL Editor, ~10s)
--
-- Architecture:
--   * workspaces / members / roles  -> relational, protected by RLS
--   * projects                      -> one row per project; the working dataset
--                                      (backlog, sprints, team) lives in
--                                      projects.data JSONB and syncs realtime
--   * activity                      -> relational audit trail per project
--
-- This gives real authentication, real role-based permissions enforced by the
-- database (RLS), real cross-device sync and a real activity log — while the
-- proven single-file app keeps working identically in local mode.
--
-- Safe to re-run at any time (idempotent: create-if-not-exists everywhere).
-- ============================================================================

-- Workspaces (organizations) -------------------------------------------------
create table if not exists public.workspaces (
  id         uuid primary key default gen_random_uuid(),
  name       text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

-- Membership + role: owner | admin | scrum_master | product_owner | developer | viewer
create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  role         text not null default 'developer'
               check (role in ('owner','admin','scrum_master','product_owner','developer','viewer')),
  created_at   timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

-- Projects: template = scrum | kanban | scrumban | custom ---------------------
create table if not exists public.projects (
  id           uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  name         text not null,
  key          text not null default 'SF',
  description  text default '',
  template     text not null default 'scrum',
  color        text default '#2563eb',
  data         jsonb not null default '{}'::jsonb,   -- working dataset (see app)
  updated_by   uuid references auth.users(id) on delete set null,
  archived     boolean not null default false,
  created_at   timestamptz not null default now()
);

-- Activity history -------------------------------------------------------------
create table if not exists public.activity (
  id         bigint generated always as identity primary key,
  workspace_id uuid not null references public.workspaces(id) on delete cascade,
  project_id uuid references public.projects(id) on delete cascade,
  user_id    uuid references auth.users(id) on delete set null,
  kind       text not null,            -- created | moved | updated | commented | member | deleted
  detail     text not null default '',
  created_at timestamptz not null default now()
);

-- Helpers ---------------------------------------------------------------------
create or replace function public.is_member(w uuid)
returns boolean language sql security definer stable as
$$ select exists (
  select 1 from public.workspace_members m
  where m.workspace_id = w and m.user_id = auth.uid()
) $$;

create or replace function public.my_role(w uuid)
returns text language sql security definer stable as
$$ select coalesce(
  (select role from public.workspace_members m
   where m.workspace_id = w and m.user_id = auth.uid()),
  'viewer') $$;

create or replace function public.can_write(w uuid)
returns boolean language sql security definer stable as
$$ select public.my_role(w) in
  ('owner','admin','scrum_master','product_owner','developer') $$;

-- Owner/admin adds a member by email (SECURITY DEFINER bypasses RLS safely:
-- the function itself checks the caller's role before inserting).
create or replace function public.add_member_by_email(w uuid, member_email text, member_role text)
returns void language plpgsql security definer as $$
declare target uuid;
begin
  if public.my_role(w) not in ('owner','admin') then
    raise exception 'Only owners and admins can add members';
  end if;
  if member_role not in ('admin','scrum_master','product_owner','developer','viewer') then
    raise exception 'Invalid role';
  end if;
  select id into target from auth.users where lower(email) = lower(member_email) limit 1;
  if target is null then
    raise exception 'No signed-up user with email % yet — ask them to register first', member_email;
  end if;
  insert into public.workspace_members (workspace_id, user_id, role)
  values (w, target, member_role)
  on conflict (workspace_id, user_id) do update set role = excluded.role;
end $$;

-- Row Level Security -----------------------------------------------------------
alter table public.workspaces        enable row level security;
alter table public.workspace_members enable row level security;
alter table public.projects          enable row level security;
alter table public.activity          enable row level security;

-- Workspaces
drop policy if exists ws_read on public.workspaces;
create policy ws_read on public.workspaces for select using (public.is_member(id));

drop policy if exists ws_insert on public.workspaces;
create policy ws_insert on public.workspaces
  for insert to authenticated with check (created_by = auth.uid());

drop policy if exists ws_update on public.workspaces;
create policy ws_update on public.workspaces
  for update using (public.my_role(id) in ('owner','admin'));

-- Members: read if fellow member; self-join on creation; owner/admin manage
drop policy if exists wm_read on public.workspace_members;
create policy wm_read on public.workspace_members
  for select using (public.is_member(workspace_id));

drop policy if exists wm_insert on public.workspace_members;
create policy wm_insert on public.workspace_members
  for insert to authenticated with check (
    user_id = auth.uid() and exists (
      select 1 from public.workspaces w
      where w.id = workspace_id and w.created_by = auth.uid()
    )
  );

drop policy if exists wm_update on public.workspace_members;
create policy wm_update on public.workspace_members
  for update using (public.my_role(workspace_id) in ('owner','admin'));

drop policy if exists wm_delete on public.workspace_members;
create policy wm_delete on public.workspace_members
  for delete using (
    user_id = auth.uid()
    or public.my_role(workspace_id) in ('owner','admin')
  );

-- Projects: members read, writers write
drop policy if exists pr_read on public.projects;
create policy pr_read on public.projects
  for select using (public.is_member(workspace_id));

drop policy if exists pr_write on public.projects;
create policy pr_write on public.projects
  for all using (public.can_write(workspace_id))
  with check (public.can_write(workspace_id));

-- Activity: members read; any member writes (auditable trail)
drop policy if exists ac_read on public.activity;
create policy ac_read on public.activity
  for select using (public.is_member(workspace_id));

drop policy if exists ac_write on public.activity;
create policy ac_write on public.activity
  for insert to authenticated with check (public.is_member(workspace_id));

-- Realtime: project payload + activity stream
drop publication if exists supabase_realtime;
create publication supabase_realtime for table public.projects, public.activity;
-- (If your project already has a publication named supabase_realtime, instead run:
--   alter publication supabase_realtime add table public.projects;
--   alter publication supabase_realtime add table public.activity; )

-- ============================================================================
-- Team tip: teammates sign up from the app's login screen first (and confirm
-- their email), then the owner invites them — Team view → Invite — or run in
-- SQL Editor:
--   select public.add_member_by_email('<workspace-uuid>','their@email.com','developer');
-- Invite them BEFORE their first sign-in and they land directly in this
-- workspace. Roles: admin | scrum_master | product_owner | developer | viewer.
-- ============================================================================
