-- storage buckets and premium guard helpers
create table if not exists app_settings (
  key text primary key,
  value jsonb not null default '{}'
);

insert into app_settings (key, value) values ('ai_photo_daily_limit', '{"limit":3}') on conflict (key) do nothing;

create or replace function is_premium_user(p_user uuid)
returns boolean
language sql
stable
as $$
  select exists(
    select 1
    from user_entitlements ue
    where ue.user_id = p_user
      and ue.plan = 'premium_lifetime'
      and ue.active = true
  );
$$;

alter table ai_usage_limits enable row level security;
alter table food_photo_analyses enable row level security;
alter table user_meal_plan_suggestions enable row level security;

drop policy if exists ai_usage_limits_owner on ai_usage_limits;create policy ai_usage_limits_owner on ai_usage_limits
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists food_photo_analyses_owner on food_photo_analyses;create policy food_photo_analyses_owner on food_photo_analyses
for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists user_meal_plan_suggestions_owner on user_meal_plan_suggestions;create policy user_meal_plan_suggestions_owner on user_meal_plan_suggestions
for select using (auth.uid() = user_id);

insert into storage.buckets (id, name, public)
values ('food-photos', 'food-photos', false)
on conflict (id) do nothing;

drop policy if exists "food photos owner read" on storage.objects;create policy "food photos owner read" on storage.objects
for select to authenticated
using (bucket_id = 'food-photos' and owner = auth.uid());

drop policy if exists "food photos owner write" on storage.objects;create policy "food photos owner write" on storage.objects
for insert to authenticated
with check (bucket_id = 'food-photos' and owner = auth.uid());
