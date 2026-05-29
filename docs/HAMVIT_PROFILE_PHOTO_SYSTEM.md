# HAMVIT Profile Photo System

## Objetivo

Substituir o conceito antigo de "avatar URL" por um sistema real de foto de perfil do usuário, com captura via câmera, galeria, crop, compressão, upload para Supabase Storage e cache local.

## Alterações Realizadas

### 1. Migration (Supabase)
- **Arquivo:** `supabase/migrations/20260525000021_profile_photo_system.sql`
- Adicionada coluna `photo_url` à tabela `profiles`
- Criado bucket `profile-photos` (público, max 5MB, JPEG/PNG/WebP)
- Políticas RLS para usuário autenticado gerenciar sua própria foto

### 2. Modelo de Dados (Flutter)
- **Arquivo:** `lib/features/auth/domain/auth_state.dart`
- Adicionado campo `photoUrl` à classe `AppProfile`
- `fromMap` lê `photo_url` do banco

### 3. Serviço de Upload
- **Arquivo:** `lib/features/profile/services/profile_photo_service.dart`
- `pickFromCamera()` / `pickFromGallery()` — image_picker com compressão
- `uploadPhoto(userId, XFile)` — upload com upsert para sobrescrever foto existente
- `deletePhoto(userId)` — remove foto do Storage
- Estrutura de armazenamento: `profile-photos/{userId}/profile.jpg`

### 4. Widget de Foto
- **Arquivo:** `lib/features/profile/widgets/profile_photo_widget.dart`
- Exibe foto circular com borda HAMVIT (azul/ciano) e sombra
- Placeholder com inicial do nome ou ícone de perfil
- Badge de câmera no canto inferior direito (modo edição)
- Texto "Alterar foto" abaixo (modo edição, sem foto)
- Modal bottom sheet com opções: Tirar foto, Galeria, Remover foto, Cancelar
- **Dependências:** `cached_network_image` para cache e fade

### 5. Tela de Edição de Perfil (Refatorada)
- **Arquivo:** `lib/features/profile/profile_edit_screen.dart`
- **Removido:** campo `avatar_url` (URL de avatar)
- **Adicionado:** `ProfilePhotoWidget` no topo
- **Adicionado:** `ImageCropper` com crop quadrado (1:1) após seleção
- **Adicionado:** upload automático ao selecionar foto
- **Adicionado:** snackbar de erro "Não foi possível atualizar sua foto."
- **Adicionado:** opção "Remover foto" no modal quando já existe foto

### 6. Dependências Adicionadas
- `image_picker` (já existia)
- `image_cropper` (novo)
- `cached_network_image` (novo)

## Fluxo do Usuário

1. Acessa "Editar perfil"
2. Vê foto atual (ou placeholder com inicial)
3. Toca na foto → modal nativo:
   - "Tirar foto" → abre câmera
   - "Escolher da galeria" → abre galeria
   - "Remover foto" (se existir) → deleta do Storage
   - "Cancelar"
4. Após selecionar imagem → crop quadrado (1:1)
5. Upload automático para `profile-photos/{userId}/profile.jpg`
6. Coluna `photo_url` atualizada no banco via `profiles.update`
7. Cache local via `cached_network_image` com fade de 300ms

## Estrutura no Supabase Storage

```
profile-photos/
  {userId}/
    profile.jpg
```

## Permissões (RLS)

- **SELECT:** qualquer usuário autenticado
- **INSERT:** apenas o próprio usuário (valida pelo prefixo do path = userId)
- **UPDATE:** apenas o próprio usuário
- **DELETE:** apenas o próprio usuário

## Fallbacks

- **Sem foto:** exibe inicial do nome (ou ícone `person_outline` se sem nome)
- **Erro de upload:** snackbar "Não foi possível atualizar sua foto."
- **Cache:** `CachedNetworkImage` com placeholder e error widget
- **Imagem inválida:** fallback para placeholder

## Próximos Passos

- [ ] Exibir foto em outras telas (Home, configurações, etc.)
- [ ] Sincronizar `photo_url` no provider após upload sem precisar fechar a tela
- [ ] Adicionar animação de transição ao trocar foto