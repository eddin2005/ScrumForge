-- ============================================================================
-- ScrumForge — bootstrap patch (run once in Supabase SQL Editor, ~2s)
--
-- Adds create_my_workspace(): the app calls this on first cloud sign-in
-- instead of doing raw inserts, so workspace creation cannot be blocked by
-- client-side RLS ordering. The function runs as the table owner, checks the
-- caller's identity itself, and is idempotent — safe to re-run:
--   * if the caller already belongs to a workspace, it just returns that one
--   * otherwise it creates the workspace and adds the caller as its owner
--
-- (Your first project row is uploaded by the app right after this succeeds.)
-- ============================================================================

create or replace function public.create_my_workspace(p_name text, p_project text default 'My project')
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_ws  uuid;
  v_prj uuid;
begin
  if v_uid is null then
    raise exception 'Not authenticated';
  end if;

  -- Already a member of a workspace? Return it unchanged (idempotent).
  select m.workspace_id into v_ws
  from public.workspace_members m
  where m.user_id = v_uid
  order by m.created_at
  limit 1;

  if v_ws is not null then
    select p.id into v_prj
    from public.projects p
    where p.workspace_id = v_ws
    order by p.created_at
    limit 1;
    return json_build_object('workspace_id', v_ws, 'project_id', v_prj, 'created', false);
  end if;

  -- First sign-in: create the workspace and make the caller its owner.
  insert into public.workspaces (name, created_by)
  values (coalesce(nullif(trim(p_name), ''), 'My workspace'), v_uid)
  returning id into v_ws;

  insert into public.workspace_members (workspace_id, user_id, role)
  values (v_ws, v_uid, 'owner');

  return json_build_object('workspace_id', v_ws, 'project_id', v_prj, 'created', true);
end $$;

grant execute on function public.create_my_workspace(text, text) to authenticated;

-- Done. Reload the app and sign in — the badge should say CLOUD SYNC and your
-- board uploads to the workspace automatically.
