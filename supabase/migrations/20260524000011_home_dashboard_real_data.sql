-- Home dashboard real data support

alter table if exists hydration_logs
  add column if not exists log_date date,
  add column if not exists amount_ml integer,
  add column if not exists sync_status text default 'synced',
  add column if not exists client_uuid text,
  add column if not exists created_at timestamptz default now();

update hydration_logs
set
  log_date = coalesce(log_date, (logged_at at time zone 'utc')::date),
  amount_ml = coalesce(amount_ml, ml)
where log_date is null or amount_ml is null;

alter table if exists meal_logs
  add column if not exists meal_date date,
  add column if not exists total_calories_kcal numeric(8,2),
  add column if not exists notes text;

update meal_logs
set meal_date = coalesce(meal_date, (consumed_at at time zone 'utc')::date)
where meal_date is null;

alter table if exists activity_sessions
  add column if not exists finished_at timestamptz,
  add column if not exists duration_seconds integer,
  add column if not exists distance_meters numeric(10,2),
  add column if not exists calories_estimated_kcal numeric(8,2),
  add column if not exists created_at timestamptz default now();

update activity_sessions
set
  finished_at = coalesce(finished_at, ended_at),
  distance_meters = coalesce(distance_meters, distance_m),
  calories_estimated_kcal = coalesce(calories_estimated_kcal, calories_estimated),
  duration_seconds = coalesce(
    duration_seconds,
    case
      when started_at is not null and ended_at is not null and ended_at > started_at
      then extract(epoch from (ended_at - started_at))::int
      else null
    end
  )
where
  finished_at is null
  or distance_meters is null
  or calories_estimated_kcal is null
  or duration_seconds is null;

alter table if exists daily_nutrition_targets
  add column if not exists calories_kcal numeric(8,2),
  add column if not exists water_ml integer,
  add column if not exists updated_at timestamptz default now(),
  add column if not exists created_at timestamptz default now();

update daily_nutrition_targets
set calories_kcal = coalesce(calories_kcal, calories)
where calories_kcal is null;

create table if not exists sleep_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  sleep_date date not null,
  bedtime timestamptz,
  wake_time timestamptz,
  total_sleep_minutes integer,
  sleep_quality integer,
  source text default 'manual',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint sleep_logs_quality_check check (sleep_quality is null or (sleep_quality between 1 and 5)),
  constraint sleep_logs_minutes_check check (total_sleep_minutes is null or total_sleep_minutes >= 0),
  unique (user_id, sleep_date)
);

create index if not exists idx_sleep_logs_user_date on sleep_logs(user_id, sleep_date desc);

create table if not exists home_daily_summaries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  summary_date date not null,
  water_ml integer not null default 0,
  calories_kcal numeric(8,2) not null default 0,
  habits_completed integer not null default 0,
  habits_total integer not null default 0,
  distance_meters numeric(10,2) not null default 0,
  active_minutes integer not null default 0,
  sleep_minutes integer,
  daily_score integer not null default 0,
  data_source text not null default 'aggregated',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, summary_date)
);

create index if not exists idx_home_daily_summaries_user_date on home_daily_summaries(user_id, summary_date desc);

alter table sleep_logs enable row level security;
alter table home_daily_summaries enable row level security;

drop policy if exists sleep_logs_owner_select on sleep_logs;
create policy sleep_logs_owner_select
  on sleep_logs for select
  using (auth.uid() = user_id);

drop policy if exists sleep_logs_owner_insert on sleep_logs;
create policy sleep_logs_owner_insert
  on sleep_logs for insert
  with check (auth.uid() = user_id);

drop policy if exists sleep_logs_owner_update on sleep_logs;
create policy sleep_logs_owner_update
  on sleep_logs for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists sleep_logs_owner_delete on sleep_logs;
create policy sleep_logs_owner_delete
  on sleep_logs for delete
  using (auth.uid() = user_id);

drop policy if exists home_daily_summaries_owner_select on home_daily_summaries;
create policy home_daily_summaries_owner_select
  on home_daily_summaries for select
  using (auth.uid() = user_id);

drop policy if exists home_daily_summaries_owner_insert on home_daily_summaries;
create policy home_daily_summaries_owner_insert
  on home_daily_summaries for insert
  with check (auth.uid() = user_id);

drop policy if exists home_daily_summaries_owner_update on home_daily_summaries;
create policy home_daily_summaries_owner_update
  on home_daily_summaries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists home_daily_summaries_owner_delete on home_daily_summaries;
create policy home_daily_summaries_owner_delete
  on home_daily_summaries for delete
  using (auth.uid() = user_id);
