create table if not exists public.activity_route_points (
  id uuid primary key default gen_random_uuid(),
  activity_session_id uuid not null references public.activity_sessions(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  latitude double precision not null,
  longitude double precision not null,
  altitude double precision,
  accuracy double precision,
  speed_mps double precision,
  heading double precision,
  recorded_at timestamptz not null,
  point_order integer not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_activity_route_points_session_id
  on public.activity_route_points(activity_session_id);
create index if not exists idx_activity_route_points_user_id
  on public.activity_route_points(user_id);
create index if not exists idx_activity_route_points_recorded_at
  on public.activity_route_points(recorded_at);

alter table public.activity_route_points enable row level security;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'activity_route_points'
      and policyname = 'route_points_select_own'
  ) then
    create policy route_points_select_own
      on public.activity_route_points
      for select
      using (auth.uid() = user_id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'activity_route_points'
      and policyname = 'route_points_insert_own'
  ) then
    create policy route_points_insert_own
      on public.activity_route_points
      for insert
      with check (
        auth.uid() = user_id
        and exists (
          select 1
          from public.activity_sessions s
          where s.id = activity_session_id
            and s.user_id = auth.uid()
        )
      );
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'activity_route_points'
      and policyname = 'route_points_update_own'
  ) then
    create policy route_points_update_own
      on public.activity_route_points
      for update
      using (auth.uid() = user_id)
      with check (auth.uid() = user_id);
  end if;
end $$;

do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'activity_route_points'
      and policyname = 'route_points_delete_own'
  ) then
    create policy route_points_delete_own
      on public.activity_route_points
      for delete
      using (auth.uid() = user_id);
  end if;
end $$;

