-- HAMVIT habits real module incremental migration

alter table if exists user_habits
  add column if not exists title text,
  add column if not exists description text,
  add column if not exists category text,
  add column if not exists frequency text,
  add column if not exists target_value numeric,
  add column if not exists target_unit text,
  add column if not exists active boolean not null default true,
  add column if not exists updated_at timestamptz not null default now();

update user_habits
set title = coalesce(title, name)
where title is null and name is not null;

alter table if exists habit_logs
  add column if not exists user_id uuid references profiles(id) on delete cascade,
  add column if not exists habit_id uuid references user_habits(id) on delete cascade,
  add column if not exists log_date date,
  add column if not exists completed boolean,
  add column if not exists value numeric,
  add column if not exists notes text,
  add column if not exists sync_status text,
  add column if not exists client_uuid text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update habit_logs hl
set user_id = coalesce(hl.user_id, uh.user_id),
    habit_id = coalesce(hl.habit_id, hl.user_habit_id),
    log_date = coalesce(hl.log_date, (hl.logged_at at time zone 'utc')::date),
    completed = coalesce(hl.completed, hl.done),
    sync_status = coalesce(hl.sync_status, 'pending'),
    updated_at = coalesce(hl.updated_at, now())
from user_habits uh
where hl.user_habit_id = uh.id;

alter table if exists habit_templates
  add column if not exists title text,
  add column if not exists category text,
  add column if not exists default_frequency text,
  add column if not exists icon_key text,
  add column if not exists active boolean not null default true,
  add column if not exists created_at timestamptz not null default now();

update habit_templates
set title = coalesce(title, name)
where title is null and name is not null;

alter table if exists user_streaks
  add column if not exists best_count int not null default 0;

create unique index if not exists ux_habit_logs_user_habit_date on habit_logs(user_id, habit_id, log_date);
create index if not exists idx_user_habits_user_active on user_habits(user_id, active);
create index if not exists idx_habit_logs_user_date on habit_logs(user_id, log_date desc);

alter table if exists user_habits enable row level security;
alter table if exists habit_logs enable row level security;

drop policy if exists user_habits_owner on user_habits;
create policy user_habits_owner on user_habits
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists habit_logs_owner on habit_logs;
create policy habit_logs_owner on habit_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
