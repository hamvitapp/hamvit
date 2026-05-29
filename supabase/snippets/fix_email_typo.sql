update auth.users
set email = 'mauriciocandido@correios.com.br',
    raw_user_meta_data = coalesce(raw_user_meta_data, '{}'::jsonb) || '{"email":"mauriciocandido@correios.com.br","email_verified":true}'::jsonb,
    encrypted_password = crypt('Teste1234', gen_salt('bf')),
    email_confirmed_at = coalesce(email_confirmed_at, now()),
    updated_at = now()
where lower(email)=lower('mauriciocandido@correisos.com.br');

update auth.identities
set identity_data = jsonb_set(coalesce(identity_data, '{}'::jsonb), '{email}', '"mauriciocandido@correios.com.br"'::jsonb, true),
    updated_at = now()
where lower((identity_data->>'email'))=lower('mauriciocandido@correisos.com.br');