-- Goals, hydration targets and date-oriented profile fields

alter table if exists health_profiles
  add column if not exists birth_date date,
  add column if not exists biological_sex text,
  add column if not exists target_weight_kg numeric(5,2),
  add column if not exists activity_level text,
  add column if not exists current_weight_kg numeric(5,2);

-- Keep current_weight_kg synchronized when legacy weight_kg exists.
update health_profiles
set current_weight_kg = weight_kg
where current_weight_kg is null
  and weight_kg is not null;

alter table if exists daily_nutrition_targets
  add column if not exists calories_kcal int,
  add column if not exists fat_g int,
  add column if not exists water_ml int,
  add column if not exists calculation_source text not null default 'system_calculated',
  add column if not exists calculated_at timestamptz,
  add column if not exists user_adjusted boolean not null default false;

update daily_nutrition_targets
set calories_kcal = coalesce(calories_kcal, round(calories)::int),
    fat_g = coalesce(fat_g, round(fats_g)::int)
where calories is not null or fats_g is not null;

create table if not exists goal_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  previous_weight_kg numeric(5,2),
  target_weight_kg numeric(5,2),
  estimated_weeks int,
  calorie_target_kcal int,
  water_target_ml int,
  source text not null default 'system_calculated',
  created_at timestamptz not null default now()
);

create index if not exists idx_goal_history_user_created_at on goal_history(user_id, created_at desc);

alter table if exists goal_history enable row level security;

drop policy if exists goal_history_owner on goal_history;
create policy goal_history_owner
on goal_history
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
