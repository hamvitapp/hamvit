with u as (
  select id from auth.users where lower(email)=lower('mauriciocandido@correios.com.br') limit 1
)
update public.profiles p
set premium_active = true,
    plan = 'premium_lifetime',
    updated_at = now()
from u
where p.id = u.id;

with u as (
  select id from auth.users where lower(email)=lower('mauriciocandido@correios.com.br') limit 1
)
insert into public.user_entitlements (
  user_id,
  plan,
  active,
  granted_at,
  entitlement_key,
  starts_at,
  expires_at
)
select
  u.id,
  'premium_lifetime',
  true,
  now(),
  'premium_lifetime',
  now(),
  null
from u
where not exists (
  select 1 from public.user_entitlements ue
  where ue.user_id = u.id and ue.entitlement_key = 'premium_lifetime'
);

with u as (
  select id from auth.users where lower(email)=lower('mauriciocandido@correios.com.br') limit 1
)
update public.user_entitlements ue
set active = true,
    plan = 'premium_lifetime',
    starts_at = coalesce(ue.starts_at, now()),
    expires_at = null
from u
where ue.user_id = u.id
  and ue.entitlement_key = 'premium_lifetime';