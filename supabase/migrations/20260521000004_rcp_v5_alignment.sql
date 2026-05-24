-- RCP V5 alignment (non-breaking, local-first)
-- Adds complementary fields and backfills without removing legacy columns.

alter table if exists public.recipe_meal_categories
  add column if not exists key text,
  add column if not exists name text,
  add column if not exists sort_order integer not null default 0,
  add column if not exists active boolean not null default true,
  add column if not exists created_at timestamptz not null default now();

update public.recipe_meal_categories
set key = coalesce(key, code),
    name = coalesce(name, label)
where key is null or name is null;

create unique index if not exists recipe_meal_categories_key_uidx
  on public.recipe_meal_categories(key);

alter table if exists public.recipe_tags
  add column if not exists key text,
  add column if not exists name text,
  add column if not exists active boolean not null default true,
  add column if not exists created_at timestamptz not null default now();

update public.recipe_tags
set key = coalesce(key, tag),
    name = coalesce(name, tag)
where key is null or name is null;

create unique index if not exists recipe_tags_key_uidx
  on public.recipe_tags(key);

alter table if exists public.recipe_nutrition_profiles
  add column if not exists calories_kcal numeric(10,2),
  add column if not exists fat_g numeric(10,2),
  add column if not exists fiber_g numeric(10,2),
  add column if not exists sodium_mg numeric(10,2),
  add column if not exists serving_label text,
  add column if not exists serving_grams numeric(10,2),
  add column if not exists updated_at timestamptz not null default now();

update public.recipe_nutrition_profiles
set calories_kcal = coalesce(calories_kcal, calories),
    fat_g = coalesce(fat_g, fats_g),
    updated_at = now()
where calories_kcal is null or fat_g is null;

create unique index if not exists recipe_nutrition_profiles_recipe_uidx
  on public.recipe_nutrition_profiles(recipe_id);

alter table if exists public.recipe_seed_batches
  add column if not exists source_file_name text,
  add column if not exists source_version text,
  add column if not exists imported_by uuid,
  add column if not exists total_records int,
  add column if not exists status text,
  add column if not exists notes text;

update public.recipe_seed_batches
set source_file_name = coalesce(source_file_name, source_file),
    total_records = coalesce(total_records, imported_count),
    status = coalesce(status, 'completed')
where source_file_name is null or total_records is null or status is null;

alter table if exists public.daily_nutrition_targets
  add column if not exists calories_kcal numeric(10,2),
  add column if not exists fat_g numeric(10,2),
  add column if not exists water_ml integer,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.daily_nutrition_targets
set calories_kcal = coalesce(calories_kcal, calories),
    fat_g = coalesce(fat_g, fats_g),
    updated_at = now()
where calories_kcal is null or fat_g is null;

alter table if exists public.meal_target_distribution
  add column if not exists calories_percent numeric(6,2),
  add column if not exists protein_percent numeric(6,2),
  add column if not exists carbs_percent numeric(6,2),
  add column if not exists fat_percent numeric(6,2),
  add column if not exists active boolean not null default true,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update public.meal_target_distribution
set calories_percent = coalesce(calories_percent, pct),
    updated_at = now()
where calories_percent is null;

alter table if exists public.user_recipe_preferences
  add column if not exists preference_type text,
  add column if not exists reason text;

update public.user_recipe_preferences
set preference_type = coalesce(preference_type, preference)
where preference_type is null;

alter table if exists public.user_meal_plan_suggestions
  add column if not exists reason_json jsonb not null default '{}'::jsonb,
  add column if not exists status text not null default 'suggested',
  add column if not exists accepted_at timestamptz,
  add column if not exists rejected_at timestamptz;

update public.user_meal_plan_suggestions
set reason_json = coalesce(reason_json, reason, '{}'::jsonb),
    status = coalesce(status, 'suggested')
where reason_json = '{}'::jsonb or status is null;

create index if not exists user_meal_plan_suggestions_user_date_idx
  on public.user_meal_plan_suggestions(user_id, suggestion_date desc);

alter table if exists public.recommendation_events
  add column if not exists recipe_id uuid references public.recipes(id) on delete set null,
  add column if not exists metadata jsonb not null default '{}'::jsonb;

update public.recommendation_events
set metadata = coalesce(metadata, payload, '{}'::jsonb)
where metadata = '{}'::jsonb;

create index if not exists recommendation_events_user_created_idx
  on public.recommendation_events(user_id, created_at desc);
