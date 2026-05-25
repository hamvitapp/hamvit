-- HAMVIT: reminder hour support for habits (push scheduling)

alter table if exists user_habits
  add column if not exists reminder_time time,
  add column if not exists reminder_enabled boolean not null default false;

create index if not exists idx_user_habits_reminder_enabled
  on user_habits(user_id, reminder_enabled)
  where reminder_enabled = true;

