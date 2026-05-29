# HAMVIT Profile Photo Upload Fix

Resumo das mudanças e instruções para deploy/migration referentes ao upload de fotos de perfil.

Bucket e path
- Bucket: `profile-photos`
- Path por usuário: `{user_id}/profile.jpg`
- Para versões com histórico: `{user_id}/profile_{timestamp}.jpg`

Políticas (RLS / Storage)
- Fornecemos uma migration em `supabase/migrations/20260525000021_profile_photo_system.sql` que:
  - adiciona `photo_url` na tabela `profiles` (se não existir)
  - cria o bucket `profile-photos` (public = true, file_size_limit = 5MB)
  - adiciona policies para que o usuário autenticado apenas insira/atualize/delete objetos cujo caminho comece com `auth.uid()`

Campo no banco
- Novo campo usado: `profiles.photo_url`
- Comportamento: leitura preferencial em `photo_url`, fallback para `avatar_url` quando necessário
- Atualização: o fluxo do app atualiza `profiles.photo_url` após upload bem-sucedido

Fluxo no app (resumo técnico)
1. Usuário escolhe/tira foto (ImagePicker)
2. Realizamos crop/compress via `image_cropper` com `compressQuality=85`, resize max 1024x1024
3. Criamos um arquivo temporário local a partir dos bytes
4. Fazemos upload para Supabase Storage em `profile-photos/{userId}/profile.jpg` com `upsert=true`
5. Obtemos URL pública via `getPublicUrl(path)` e atualizamos `profiles.photo_url`
6. Atualizamos o `authState` (bootstrap) para propagar a nova URL à UI
7. Mostramos `SnackBar` de sucesso e invalidamos caches locais

Logs temporários
- Durante desenvolvimento adicionamos `print()` com informações:
  - userId, tamanho do arquivo, path, resultado do upload, publicUrl, resultado do update profiles
- Esses logs devem ser removidos ou convertidos para mecanismo de logging apropriado antes do deploy em produção

Permissões nativas
- Android:
  - `CAMERA` permission
  - `READ_EXTERNAL_STORAGE` (Android <13) / `READ_MEDIA_IMAGES` (Android 13+)
- iOS:
  - `NSCameraUsageDescription`
  - `NSPhotoLibraryUsageDescription`

Testes obrigatórios
- Escolher foto da galeria
- Tirar foto pela câmera
- Remover foto
- Trocar foto existente
- Sair e entrar novamente e verificar persistência
- Validar objeto aparece no Storage e `profiles.photo_url` no DB

Migração
- A migration já adicionada: `supabase/migrations/20260525000021_profile_photo_system.sql`
- Aplicar as migrations no ambiente (supabase migrate)

Observações
- Garantir que `supabase` client tenha permissões corretas no ambiente de deploy
- Para MVP recomendamos bucket público; se optar por privado, alterar lógica para gerar signed URLs e ajustar policies de leitura

Arquivo(s) alterados no app
- `lib/features/profile/services/profile_photo_service.dart` — novo método `uploadAndSavePhoto` com logs e update do `profiles.photo_url`
- `lib/features/profile/profile_edit_screen.dart` — usa o novo método, atualiza UI e chama `authStateProvider.notifier.bootstrap()` para refresh
- `android` — manifest e build changes para resolver dependências de image cropper (já aplicadas durante o debug)

Critérios de aceite
- Foto da câmera salva
- Foto da galeria salva
- Upload aparece no Storage
- `profiles.photo_url` atualizado
- UI mostra a foto imediatamente e persiste após reinício
- Usuários não conseguem salvar foto em pastas de outros usuários (policies)

Próximos passos sugeridos
- Remover `print()` e substituir por logging estruturado (Sentry/LogRocket) em produção
- Ajustar mensagens do UI para evitar palavras "avatar"; usar "foto"
- Cobrir fluxo com testes de integração (e2e) contra ambiente de staging

