-- HAMVIT indoor/outdoor hybrid activity support

alter table if exists activity_sessions
  add column if not exists tracking_mode text,
  add column if not exists activity_environment text,
  add column if not exists manual_distance_meters numeric(10,2),
  add column if not exists manual_speed_kmh numeric(6,2),
  add column if not exists estimated_calories_kcal numeric(8,2),
  add column if not exists average_pace_seconds integer,
  add column if not exists average_speed_kmh numeric(6,2);

update activity_sessions
set
  tracking_mode = coalesce(
    tracking_mode,
    case
      when coalesce(distance_meters, 0) > 0 then 'gps'
      when coalesce(distance_m, 0) > 0 then 'gps'
      else 'manual'
    end
  ),
  activity_environment = coalesce(
    activity_environment,
    case
      when coalesce(distance_meters, 0) > 0 or coalesce(distance_m, 0) > 0 then 'outdoor'
      else 'indoor'
    end
  );

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'activity_sessions_tracking_mode_check'
  ) then
    alter table activity_sessions
      add constraint activity_sessions_tracking_mode_check
      check (tracking_mode in ('gps', 'manual', 'hybrid'));
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'activity_sessions_activity_environment_check'
  ) then
    alter table activity_sessions
      add constraint activity_sessions_activity_environment_check
      check (activity_environment in ('indoor', 'outdoor'));
  end if;
end $$;

