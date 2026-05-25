-- Settings module: structured preferences, requests, consents, and RLS

alter table if exists notification_preferences
  add column if not exists category text,
  add column if not exists channel text,
  add column if not exists enabled boolean,
  add column if not exists reminder_time time,
  add column if not exists created_at timestamptz default now(),
  add column if not exists updated_at timestamptz default now();

create unique index if not exists idx_notification_preferences_user_category_channel
  on notification_preferences(user_id, category, channel)
  where category is not null and channel is not null;

create table if not exists user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  consent_key text not null,
  accepted boolean not null default false,
  accepted_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, consent_key)
);

create table if not exists data_export_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  request_type text not null,
  status text not null default 'requested',
  file_path text,
  requested_at timestamptz not null default now(),
  completed_at timestamptz
);

create table if not exists account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  status text not null default 'requested',
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  reason text
);

alter table if exists user_preferences
  add column if not exists text_size text,
  add column if not exists high_contrast boolean,
  add column if not exists reduce_motion boolean,
  add column if not exists simple_mode boolean,
  add column if not exists larger_buttons boolean,
  add column if not exists simplified_language boolean,
  add column if not exists updated_at timestamptz default now();

create index if not exists idx_user_consents_user_key
  on user_consents(user_id, consent_key);
create index if not exists idx_data_export_requests_user_date
  on data_export_requests(user_id, requested_at desc);
create index if not exists idx_account_deletion_requests_user_date
  on account_deletion_requests(user_id, requested_at desc);

alter table user_preferences enable row level security;
alter table notification_preferences enable row level security;
alter table user_consents enable row level security;
alter table data_export_requests enable row level security;
alter table account_deletion_requests enable row level security;

drop policy if exists user_preferences_owner_select on user_preferences;
create policy user_preferences_owner_select
  on user_preferences for select
  using (auth.uid() = user_id);

drop policy if exists user_preferences_owner_insert on user_preferences;
create policy user_preferences_owner_insert
  on user_preferences for insert
  with check (auth.uid() = user_id);

drop policy if exists user_preferences_owner_update on user_preferences;
create policy user_preferences_owner_update
  on user_preferences for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists user_preferences_owner_delete on user_preferences;
create policy user_preferences_owner_delete
  on user_preferences for delete
  using (auth.uid() = user_id);

drop policy if exists notification_preferences_owner_select on notification_preferences;
create policy notification_preferences_owner_select
  on notification_preferences for select
  using (auth.uid() = user_id);

drop policy if exists notification_preferences_owner_insert on notification_preferences;
create policy notification_preferences_owner_insert
  on notification_preferences for insert
  with check (auth.uid() = user_id);

drop policy if exists notification_preferences_owner_update on notification_preferences;
create policy notification_preferences_owner_update
  on notification_preferences for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists notification_preferences_owner_delete on notification_preferences;
create policy notification_preferences_owner_delete
  on notification_preferences for delete
  using (auth.uid() = user_id);

drop policy if exists user_consents_owner_select on user_consents;
create policy user_consents_owner_select
  on user_consents for select
  using (auth.uid() = user_id);

drop policy if exists user_consents_owner_insert on user_consents;
create policy user_consents_owner_insert
  on user_consents for insert
  with check (auth.uid() = user_id);

drop policy if exists user_consents_owner_update on user_consents;
create policy user_consents_owner_update
  on user_consents for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists user_consents_owner_delete on user_consents;
create policy user_consents_owner_delete
  on user_consents for delete
  using (auth.uid() = user_id);

drop policy if exists data_export_requests_owner_select on data_export_requests;
create policy data_export_requests_owner_select
  on data_export_requests for select
  using (auth.uid() = user_id);

drop policy if exists data_export_requests_owner_insert on data_export_requests;
create policy data_export_requests_owner_insert
  on data_export_requests for insert
  with check (auth.uid() = user_id);

drop policy if exists data_export_requests_owner_update on data_export_requests;
create policy data_export_requests_owner_update
  on data_export_requests for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists account_deletion_requests_owner_select on account_deletion_requests;
create policy account_deletion_requests_owner_select
  on account_deletion_requests for select
  using (auth.uid() = user_id);

drop policy if exists account_deletion_requests_owner_insert on account_deletion_requests;
create policy account_deletion_requests_owner_insert
  on account_deletion_requests for insert
  with check (auth.uid() = user_id);

-- backend/service policies for sensitive processing

drop policy if exists user_consents_service_all on user_consents;
create policy user_consents_service_all
  on user_consents for all
  to service_role
  using (true)
  with check (true);

drop policy if exists data_export_requests_service_all on data_export_requests;
create policy data_export_requests_service_all
  on data_export_requests for all
  to service_role
  using (true)
  with check (true);

drop policy if exists account_deletion_requests_service_all on account_deletion_requests;
create policy account_deletion_requests_service_all
  on account_deletion_requests for all
  to service_role
  using (true)
  with check (true);
