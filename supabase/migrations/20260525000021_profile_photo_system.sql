-- HAMVIT Profile Photo System
-- Adiciona photo_url à tabela profiles (substituindo conceito de avatar)

alter table profiles add column if not exists photo_url text;

-- Bucket para fotos de perfil
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('profile-photos', 'profile-photos', true, 5242880, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do nothing;

-- Políticas de acesso ao bucket (usuário só vê e gerencia sua própria foto)
drop policy if exists "profile_photos_select_own" on storage.objects;
create policy "profile_photos_select_own" on storage.objects
  for select using (
    bucket_id = 'profile-photos' and auth.role() = 'authenticated'
  );

drop policy if exists "profile_photos_insert_own" on storage.objects;
create policy "profile_photos_insert_own" on storage.objects
  for insert with check (
    bucket_id = 'profile-photos' and auth.role() = 'authenticated'
      and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "profile_photos_update_own" on storage.objects;
create policy "profile_photos_update_own" on storage.objects
  for update using (
    bucket_id = 'profile-photos' and auth.role() = 'authenticated'
      and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "profile_photos_delete_own" on storage.objects;
create policy "profile_photos_delete_own" on storage.objects
  for delete using (
    bucket_id = 'profile-photos' and auth.role() = 'authenticated'
      and (storage.foldername(name))[1] = auth.uid()::text
  );