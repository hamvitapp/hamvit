with updated as (
  update auth.users
  set encrypted_password = crypt('M@uricio1', gen_salt('bf')),
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      confirmation_token = '',
      recovery_token = '',
      email_change_token_new = '',
      email_change = '',
      email_change_token_current = '',
      reauthentication_token = '',
      raw_app_meta_data = '{"provider":"email","providers":["email"]}'::jsonb,
      raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"email":"mauriciocandido@correisos.com.br","email_verified":true}'::jsonb,
      updated_at = now()
  where lower(email)=lower('mauriciocandido@correisos.com.br')
  returning id
), inserted as (
  insert into auth.users (
    instance_id, id, aud, role, email, encrypted_password,
    email_confirmed_at,
    confirmation_token, recovery_token, email_change_token_new,
    email_change, email_change_token_current, reauthentication_token,
    raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  select
    '00000000-0000-0000-0000-000000000000', gen_random_uuid(),
    'authenticated', 'authenticated',
    'mauriciocandido@correisos.com.br', crypt('M@uricio1', gen_salt('bf')),
    now(),
    '', '', '',
    '', '', '',
    '{"provider":"email","providers":["email"]}'::jsonb,
    '{"email":"mauriciocandido@correisos.com.br","email_verified":true,"phone_verified":false}'::jsonb,
    now(), now()
  where not exists (select 1 from updated)
    and not exists (select 1 from auth.users where lower(email)=lower('mauriciocandido@correisos.com.br'))
  returning id
), u as (
  select id from updated
  union all
  select id from inserted
)
insert into auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
select id::text, id, ('{"sub":"' || id::text || '","email":"mauriciocandido@correisos.com.br","email_verified":true,"phone_verified":false}')::jsonb,
       'email', now(), now(), now()
from u
where not exists (select 1 from auth.identities i where i.provider = 'email' and i.provider_id = u.id::text);