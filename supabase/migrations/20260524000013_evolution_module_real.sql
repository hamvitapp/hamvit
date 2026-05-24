-- HAMVIT evolution module real data expansion

alter table if exists weight_logs
  add column if not exists bmi numeric(6,2),
  add column if not exists notes text,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table if exists body_measurements
  add column if not exists measured_at timestamptz,
  add column if not exists waist_cm numeric(6,2),
  add column if not exists abdomen_cm numeric(6,2),
  add column if not exists chest_cm numeric(6,2),
  add column if not exists arm_cm numeric(6,2),
  add column if not exists thigh_cm numeric(6,2),
  add column if not exists hip_cm numeric(6,2),
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

update body_measurements
set
  measured_at = coalesce(measured_at, logged_at, created_at, now()),
  waist_cm = coalesce(waist_cm, (data ->> 'waist_cm')::numeric),
  abdomen_cm = coalesce(abdomen_cm, (data ->> 'abdomen_cm')::numeric),
  chest_cm = coalesce(chest_cm, (data ->> 'chest_cm')::numeric),
  arm_cm = coalesce(arm_cm, (data ->> 'arm_cm')::numeric),
  thigh_cm = coalesce(thigh_cm, (data ->> 'thigh_cm')::numeric),
  hip_cm = coalesce(hip_cm, (data ->> 'hip_cm')::numeric),
  updated_at = now()
where measured_at is null
   or waist_cm is null
   or abdomen_cm is null
   or chest_cm is null
   or arm_cm is null
   or thigh_cm is null
   or hip_cm is null;

create table if not exists progress_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  image_url text not null,
  taken_at timestamptz not null default now(),
  notes text,
  created_at timestamptz not null default now()
);

insert into progress_photos (user_id, image_url, taken_at, created_at)
select bp.user_id, bp.storage_path, coalesce(bp.created_at, now()), coalesce(bp.created_at, now())
from body_photos bp
where not exists (
  select 1
  from progress_photos pp
  where pp.user_id = bp.user_id
    and pp.image_url = bp.storage_path
);

create index if not exists idx_weight_logs_user_logged_at on weight_logs(user_id, logged_at desc);
create index if not exists idx_body_measurements_user_measured_at on body_measurements(user_id, measured_at desc);
create index if not exists idx_progress_photos_user_taken_at on progress_photos(user_id, taken_at desc);

alter table if exists progress_photos enable row level security;

drop policy if exists progress_photos_owner on progress_photos;
create policy progress_photos_owner
on progress_photos
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

alter table if exists weight_logs enable row level security;
alter table if exists body_measurements enable row level security;

drop policy if exists weight_logs_owner_strict on weight_logs;
create policy weight_logs_owner_strict
on weight_logs
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists body_measurements_owner_strict on body_measurements;
create policy body_measurements_owner_strict
on body_measurements
for all
using (auth.uid() = user_id)
with check (auth.uid() = user_id);