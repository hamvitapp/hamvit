-- HAMVIT initial schema (aligned to RCP set)
create extension if not exists pgcrypto;

create type entitlement_plan as enum ('free','premium_lifetime');
create type sync_status as enum ('pending','synced','failed','conflict');

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  plan entitlement_plan not null default 'free',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists health_profiles (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade, age int, weight_kg numeric(5,2), height_cm int, created_at timestamptz default now());
create table if not exists user_preferences (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade, data jsonb not null default '{}', created_at timestamptz default now());
create table if not exists user_devices (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade, device_id text not null, push_token text, created_at timestamptz default now());
create table if not exists food_categories (id bigserial primary key, name text not null unique);
create table if not exists foods (id uuid primary key default gen_random_uuid(), category_id bigint references food_categories(id), name text not null, calories numeric(8,2), protein_g numeric(8,2), carbs_g numeric(8,2), fats_g numeric(8,2), source text default 'admin');
create table if not exists food_portions (id uuid primary key default gen_random_uuid(), food_id uuid not null references foods(id) on delete cascade, label text not null, grams numeric(8,2) not null);
create table if not exists nutrition_sources (id uuid primary key default gen_random_uuid(), provider text not null, payload jsonb not null default '{}', created_at timestamptz default now());
create table if not exists recipes (id uuid primary key default gen_random_uuid(), name text not null, source text not null default 'admin', visibility text not null default 'public', prep_time_min int, preparation text, objective text, needs_review boolean not null default false, created_at timestamptz default now());
create table if not exists recipe_ingredients (id uuid primary key default gen_random_uuid(), recipe_id uuid not null references recipes(id) on delete cascade, food_id uuid references foods(id), ingredient_text text, quantity_text text);
create table if not exists meal_logs (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade, meal_type text not null, consumed_at timestamptz not null, created_at timestamptz default now());
create table if not exists meal_items (id uuid primary key default gen_random_uuid(), meal_log_id uuid not null references meal_logs(id) on delete cascade, food_id uuid references foods(id), recipe_id uuid references recipes(id), calories numeric(8,2), protein_g numeric(8,2), carbs_g numeric(8,2), fats_g numeric(8,2));
create table if not exists user_foods (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id) on delete cascade, food_id uuid not null references foods(id), is_favorite boolean default false);
create table if not exists barcode_lookups (id uuid primary key default gen_random_uuid(), barcode text not null unique, food_id uuid references foods(id), payload jsonb default '{}', created_at timestamptz default now());
create table if not exists food_photo_analyses (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), storage_path text not null, result jsonb default '{}', status text not null default 'pending', created_at timestamptz default now());
create table if not exists ai_usage_limits (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), feature text not null, usage_date date not null, used_count int not null default 0, unique(user_id, feature, usage_date));
create table if not exists ai_provider_logs (id uuid primary key default gen_random_uuid(), user_id uuid references profiles(id), provider text not null, model text not null, request_meta jsonb default '{}', created_at timestamptz default now());
create table if not exists habit_templates (id uuid primary key default gen_random_uuid(), name text not null, description text);
create table if not exists user_habits (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), template_id uuid references habit_templates(id), name text not null, created_at timestamptz default now());
create table if not exists habit_logs (id uuid primary key default gen_random_uuid(), user_habit_id uuid not null references user_habits(id) on delete cascade, logged_at timestamptz not null, done boolean not null default true);
create table if not exists hydration_logs (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), ml int not null, logged_at timestamptz not null);
create table if not exists exercise_library (id uuid primary key default gen_random_uuid(), name text not null, met numeric(5,2), metadata jsonb default '{}');
create table if not exists workout_sessions (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), started_at timestamptz, ended_at timestamptz, duration_sec int, calories_estimated numeric(8,2));
create table if not exists activity_sessions (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), activity_type text not null, started_at timestamptz, ended_at timestamptz, distance_m numeric(10,2), avg_pace text, avg_speed_kmh numeric(6,2), calories_estimated numeric(8,2));
create table if not exists activity_points (id uuid primary key default gen_random_uuid(), session_id uuid not null references activity_sessions(id) on delete cascade, lat numeric(10,7), lng numeric(10,7), ts timestamptz);
create table if not exists weight_logs (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), weight_kg numeric(5,2), logged_at timestamptz);
create table if not exists body_measurements (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), data jsonb not null default '{}', logged_at timestamptz);
create table if not exists body_photos (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), storage_path text not null, created_at timestamptz default now());
create table if not exists generated_reports (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), period_start date, period_end date, format text not null default 'pdf', storage_path text, created_at timestamptz default now());
create table if not exists report_shares (id uuid primary key default gen_random_uuid(), report_id uuid not null references generated_reports(id) on delete cascade, channel text not null, shared_at timestamptz default now());
create table if not exists professional_report_access (id uuid primary key default gen_random_uuid(), professional_id uuid not null, user_id uuid not null references profiles(id), granted_at timestamptz default now());
create table if not exists professionals (id uuid primary key default gen_random_uuid(), profile_id uuid references profiles(id), crn text, cnpj text, created_at timestamptz default now());
create table if not exists professional_coupons (id uuid primary key default gen_random_uuid(), professional_id uuid not null references professionals(id), code text not null unique, discount_percent numeric(5,2), commission_percent numeric(5,2));
create table if not exists patient_professional_links (id uuid primary key default gen_random_uuid(), professional_id uuid not null references professionals(id), user_id uuid not null references profiles(id), created_at timestamptz default now());
create table if not exists professional_commissions (id uuid primary key default gen_random_uuid(), professional_id uuid not null references professionals(id), payment_id uuid, amount_brl numeric(10,2), created_at timestamptz default now());
create table if not exists payments (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), provider text not null default 'mercado_pago', amount_brl numeric(10,2) not null, status text not null, created_at timestamptz default now());
create table if not exists payment_webhooks (id uuid primary key default gen_random_uuid(), provider text not null, payload jsonb not null, processed_at timestamptz);
create table if not exists user_entitlements (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), plan entitlement_plan not null, active boolean not null default true, granted_at timestamptz default now());
create table if not exists achievements (id uuid primary key default gen_random_uuid(), code text unique, title text not null);
create table if not exists user_achievements (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), achievement_id uuid not null references achievements(id), granted_at timestamptz default now());
create table if not exists challenges (id uuid primary key default gen_random_uuid(), title text not null, starts_at timestamptz, ends_at timestamptz);
create table if not exists user_challenges (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), challenge_id uuid not null references challenges(id), status text);
create table if not exists user_streaks (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), streak_type text not null, current_count int not null default 0, updated_at timestamptz default now());
create table if not exists notification_preferences (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), data jsonb not null default '{}');
create table if not exists notification_logs (id uuid primary key default gen_random_uuid(), user_id uuid references profiles(id), type text, payload jsonb default '{}', sent_at timestamptz);
create table if not exists client_mutations (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), entity text not null, local_id text not null, remote_id uuid, sync_status sync_status not null default 'pending', payload jsonb not null, created_at timestamptz default now(), updated_at timestamptz default now(), last_sync_attempt_at timestamptz);
create table if not exists sync_conflicts (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), entity text not null, local_payload jsonb, remote_payload jsonb, created_at timestamptz default now());
create table if not exists audit_logs (id uuid primary key default gen_random_uuid(), actor_user_id uuid, action text not null, target_table text, target_id text, payload jsonb default '{}', created_at timestamptz default now());
create table if not exists app_error_logs (id uuid primary key default gen_random_uuid(), user_id uuid references profiles(id), source text, message text, stack text, created_at timestamptz default now());

create table if not exists recipe_meal_categories (id uuid primary key default gen_random_uuid(), code text unique not null, label text not null);
create table if not exists recipe_tags (id uuid primary key default gen_random_uuid(), tag text unique not null);
create table if not exists recipe_tag_links (id uuid primary key default gen_random_uuid(), recipe_id uuid not null references recipes(id) on delete cascade, tag_id uuid not null references recipe_tags(id) on delete cascade, unique(recipe_id,tag_id));
create table if not exists recipe_nutrition_profiles (id uuid primary key default gen_random_uuid(), recipe_id uuid not null references recipes(id) on delete cascade, calories numeric(8,2), protein_g numeric(8,2), carbs_g numeric(8,2), fats_g numeric(8,2));
create table if not exists recipe_seed_batches (id uuid primary key default gen_random_uuid(), source_file text not null, imported_at timestamptz default now(), imported_count int not null default 0, flagged_count int not null default 0);
create table if not exists daily_nutrition_targets (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), target_date date not null, calories numeric(8,2), protein_g numeric(8,2), carbs_g numeric(8,2), fats_g numeric(8,2), unique(user_id,target_date));
create table if not exists meal_target_distribution (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), meal_type text not null, pct numeric(5,2) not null);
create table if not exists user_recipe_preferences (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), recipe_id uuid not null references recipes(id), preference text not null, created_at timestamptz default now(), unique(user_id,recipe_id));
create table if not exists user_meal_plan_suggestions (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), suggestion_date date not null, meal_type text not null, recipe_id uuid not null references recipes(id), score numeric(8,2), reason jsonb default '{}', created_at timestamptz default now());
create table if not exists recommendation_events (id uuid primary key default gen_random_uuid(), user_id uuid not null references profiles(id), event_type text not null, payload jsonb default '{}', created_at timestamptz default now());

alter table profiles enable row level security;
alter table health_profiles enable row level security;
alter table meal_logs enable row level security;
alter table meal_items enable row level security;
alter table user_entitlements enable row level security;

drop policy if exists profiles_owner on profiles;create policy profiles_owner on profiles for all using (auth.uid() = id) with check (auth.uid() = id);
drop policy if exists health_profiles_owner on health_profiles;create policy health_profiles_owner on health_profiles for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists meal_logs_owner on meal_logs;create policy meal_logs_owner on meal_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
drop policy if exists meal_items_owner on meal_items;create policy meal_items_owner on meal_items for all using (exists(select 1 from meal_logs ml where ml.id = meal_items.meal_log_id and ml.user_id = auth.uid())) with check (exists(select 1 from meal_logs ml where ml.id = meal_items.meal_log_id and ml.user_id = auth.uid()));
drop policy if exists user_entitlements_owner on user_entitlements;create policy user_entitlements_owner on user_entitlements for select using (auth.uid() = user_id);
