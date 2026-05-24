-- Home dashboard contract alignment + RLS hardening

alter table if exists sleep_logs
  add column if not exists slept_at timestamptz,
  add column if not exists woke_at timestamptz,
  add column if not exists duration_minutes integer,
  add column if not exists quality integer,
  add column if not exists notes text;

update sleep_logs
set
  slept_at = coalesce(slept_at, bedtime),
  woke_at = coalesce(woke_at, wake_time),
  duration_minutes = coalesce(duration_minutes, total_sleep_minutes),
  quality = coalesce(quality, sleep_quality),
  updated_at = now()
where
  slept_at is null
  or woke_at is null
  or duration_minutes is null
  or quality is null;

alter table if exists home_daily_summaries
  add column if not exists water_consumed_ml integer,
  add column if not exists water_goal_ml integer,
  add column if not exists calories_consumed_kcal numeric(8,2),
  add column if not exists calorie_goal_kcal numeric(8,2),
  add column if not exists daily_score_percent integer,
  add column if not exists generated_at timestamptz default now();

update home_daily_summaries
set
  water_consumed_ml = coalesce(water_consumed_ml, water_ml, 0),
  calories_consumed_kcal = coalesce(calories_consumed_kcal, calories_kcal, 0),
  daily_score_percent = coalesce(daily_score_percent, daily_score, 0),
  generated_at = coalesce(generated_at, now()),
  updated_at = now()
where
  water_consumed_ml is null
  or calories_consumed_kcal is null
  or daily_score_percent is null
  or generated_at is null;

alter table hydration_logs enable row level security;
alter table daily_nutrition_targets enable row level security;
alter table meal_logs enable row level security;
alter table habit_logs enable row level security;
alter table activity_sessions enable row level security;
alter table sleep_logs enable row level security;
alter table home_daily_summaries enable row level security;

drop policy if exists hydration_logs_owner_select on hydration_logs;
create policy hydration_logs_owner_select
  on hydration_logs for select
  using (auth.uid() = user_id);

drop policy if exists hydration_logs_owner_insert on hydration_logs;
create policy hydration_logs_owner_insert
  on hydration_logs for insert
  with check (auth.uid() = user_id);

drop policy if exists hydration_logs_owner_update on hydration_logs;
create policy hydration_logs_owner_update
  on hydration_logs for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists hydration_logs_owner_delete on hydration_logs;
create policy hydration_logs_owner_delete
  on hydration_logs for delete
  using (auth.uid() = user_id);

drop policy if exists daily_nutrition_targets_owner_select on daily_nutrition_targets;
create policy daily_nutrition_targets_owner_select
  on daily_nutrition_targets for select
  using (auth.uid() = user_id);

drop policy if exists daily_nutrition_targets_owner_insert on daily_nutrition_targets;
create policy daily_nutrition_targets_owner_insert
  on daily_nutrition_targets for insert
  with check (auth.uid() = user_id);

drop policy if exists daily_nutrition_targets_owner_update on daily_nutrition_targets;
create policy daily_nutrition_targets_owner_update
  on daily_nutrition_targets for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists daily_nutrition_targets_owner_delete on daily_nutrition_targets;
create policy daily_nutrition_targets_owner_delete
  on daily_nutrition_targets for delete
  using (auth.uid() = user_id);

drop policy if exists meal_logs_owner_select on meal_logs;
create policy meal_logs_owner_select
  on meal_logs for select
  using (auth.uid() = user_id);

drop policy if exists meal_logs_owner_insert on meal_logs;
create policy meal_logs_owner_insert
  on meal_logs for insert
  with check (auth.uid() = user_id);

drop policy if exists meal_logs_owner_update on meal_logs;
create policy meal_logs_owner_update
  on meal_logs for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists meal_logs_owner_delete on meal_logs;
create policy meal_logs_owner_delete
  on meal_logs for delete
  using (auth.uid() = user_id);

drop policy if exists habit_logs_owner_select_strict on habit_logs;
create policy habit_logs_owner_select_strict
  on habit_logs for select
  using (auth.uid() = user_id);

drop policy if exists habit_logs_owner_insert_strict on habit_logs;
create policy habit_logs_owner_insert_strict
  on habit_logs for insert
  with check (auth.uid() = user_id);

drop policy if exists habit_logs_owner_update_strict on habit_logs;
create policy habit_logs_owner_update_strict
  on habit_logs for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists habit_logs_owner_delete_strict on habit_logs;
create policy habit_logs_owner_delete_strict
  on habit_logs for delete
  using (auth.uid() = user_id);

drop policy if exists activity_sessions_owner_select on activity_sessions;
create policy activity_sessions_owner_select
  on activity_sessions for select
  using (auth.uid() = user_id);

drop policy if exists activity_sessions_owner_insert on activity_sessions;
create policy activity_sessions_owner_insert
  on activity_sessions for insert
  with check (auth.uid() = user_id);

drop policy if exists activity_sessions_owner_update on activity_sessions;
create policy activity_sessions_owner_update
  on activity_sessions for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists activity_sessions_owner_delete on activity_sessions;
create policy activity_sessions_owner_delete
  on activity_sessions for delete
  using (auth.uid() = user_id);

-- keep existing sleep_logs/home_daily_summaries policies and ensure naming consistency

drop policy if exists sleep_logs_owner_select_strict on sleep_logs;
create policy sleep_logs_owner_select_strict
  on sleep_logs for select
  using (auth.uid() = user_id);

drop policy if exists sleep_logs_owner_insert_strict on sleep_logs;
create policy sleep_logs_owner_insert_strict
  on sleep_logs for insert
  with check (auth.uid() = user_id);

drop policy if exists sleep_logs_owner_update_strict on sleep_logs;
create policy sleep_logs_owner_update_strict
  on sleep_logs for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists sleep_logs_owner_delete_strict on sleep_logs;
create policy sleep_logs_owner_delete_strict
  on sleep_logs for delete
  using (auth.uid() = user_id);

drop policy if exists home_daily_summaries_owner_select_strict on home_daily_summaries;
create policy home_daily_summaries_owner_select_strict
  on home_daily_summaries for select
  using (auth.uid() = user_id);

drop policy if exists home_daily_summaries_owner_insert_strict on home_daily_summaries;
create policy home_daily_summaries_owner_insert_strict
  on home_daily_summaries for insert
  with check (auth.uid() = user_id);

drop policy if exists home_daily_summaries_owner_update_strict on home_daily_summaries;
create policy home_daily_summaries_owner_update_strict
  on home_daily_summaries for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists home_daily_summaries_owner_delete_strict on home_daily_summaries;
create policy home_daily_summaries_owner_delete_strict
  on home_daily_summaries for delete
  using (auth.uid() = user_id);
