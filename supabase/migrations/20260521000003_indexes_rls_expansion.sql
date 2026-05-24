-- performance indexes and additional RLS coverage
create index if not exists idx_meal_logs_user_date on meal_logs(user_id, consumed_at desc);
create index if not exists idx_meal_items_log on meal_items(meal_log_id);
create index if not exists idx_hydration_user_date on hydration_logs(user_id, logged_at desc);
create index if not exists idx_weight_user_date on weight_logs(user_id, logged_at desc);
create index if not exists idx_activity_user_date on activity_sessions(user_id, started_at desc);
create index if not exists idx_user_habits_user on user_habits(user_id);
create index if not exists idx_habit_logs_habit_date on habit_logs(user_habit_id, logged_at desc);
create index if not exists idx_user_meal_suggestions_user_date on user_meal_plan_suggestions(user_id, suggestion_date desc);

alter table user_habits enable row level security;
alter table habit_logs enable row level security;
alter table hydration_logs enable row level security;
alter table workout_sessions enable row level security;
alter table activity_sessions enable row level security;
alter table weight_logs enable row level security;
alter table body_measurements enable row level security;
alter table generated_reports enable row level security;

drop policy if exists user_habits_owner on user_habits;create policy user_habits_owner on user_habits
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists habit_logs_owner on habit_logs;create policy habit_logs_owner on habit_logs
for all using (
  exists(select 1 from user_habits uh where uh.id = habit_logs.user_habit_id and uh.user_id = auth.uid())
) with check (
  exists(select 1 from user_habits uh where uh.id = habit_logs.user_habit_id and uh.user_id = auth.uid())
);

drop policy if exists hydration_owner on hydration_logs;create policy hydration_owner on hydration_logs
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists workout_owner on workout_sessions;create policy workout_owner on workout_sessions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists activity_owner on activity_sessions;create policy activity_owner on activity_sessions
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists weight_owner on weight_logs;create policy weight_owner on weight_logs
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists body_measurements_owner on body_measurements;create policy body_measurements_owner on body_measurements
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists reports_owner on generated_reports;create policy reports_owner on generated_reports
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
