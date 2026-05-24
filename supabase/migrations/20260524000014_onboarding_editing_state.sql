-- Onboarding vs permanent editing state columns

alter table if exists profiles
  add column if not exists onboarding_step int not null default 1,
  add column if not exists profile_completion_percent int not null default 0;

update profiles
set onboarding_step = coalesce(onboarding_step, 1),
    profile_completion_percent = coalesce(profile_completion_percent, 0)
where onboarding_step is null or profile_completion_percent is null;
