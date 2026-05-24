-- HAMVIT food preferences permanent module

create table if not exists user_food_preferences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  eating_styles jsonb not null default '[]'::jsonb,
  restrictions jsonb not null default '[]'::jsonb,
  disliked_foods jsonb not null default '[]'::jsonb,
  favorite_foods jsonb not null default '[]'::jsonb,
  meals_per_day integer,
  cooking_frequency text,
  prep_time_preference text,
  lunchbox_habit text,
  food_goals jsonb not null default '[]'::jsonb,
  usual_meals jsonb not null default '[]'::jsonb,
  meal_times jsonb not null default '{}'::jsonb,
  suggestion_style jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists ux_user_food_preferences_user on user_food_preferences(user_id);
create index if not exists idx_user_food_preferences_updated_at on user_food_preferences(updated_at desc);

alter table if exists user_food_preferences enable row level security;

drop policy if exists user_food_preferences_owner on user_food_preferences;
create policy user_food_preferences_owner on user_food_preferences
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
