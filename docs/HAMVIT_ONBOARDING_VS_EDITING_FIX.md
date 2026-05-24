# HAMVIT - Correcao obrigatoria: onboarding inicial vs edicao permanente

## Objetivo
Separar fluxo de onboarding inicial (wizard) das telas permanentes de edicao de perfil, objetivos e preferencias.

## Matriz de rotas

### Onboarding inicial (primeiro preenchimento)
- /welcome
- /onboarding
- /onboarding/goal
- /onboarding/body
- /onboarding/food
- /onboarding/activity
- /onboarding/sleep
- /onboarding/hydration

### Edicao permanente (pos-login)
- /profile/edit
- /profile/goals
- /profile/body-data
- /nutrition/preferences
- /activities/preferences
- /sleep/settings
- /hydration/settings
- /settings/preferences

## Ajustes implementados
- Router atualizado com novas rotas permanentes canonicas.
- Alias de compatibilidade mantidos para evitar quebra imediata:
  - /profile/body
  - /sleep
  - /hydration
- Nova tela de edicao completa de perfil em /profile/edit.
- Nova tela de preferencias de atividade em /activities/preferences.
- Botoes de edicao em perfil/objetivos/menu movidos para rotas permanentes.
- Soft gate de atividade ajustado para /profile/body-data.
- Estado de perfil atualizado para persistir:
  - onboarding_completed
  - onboarding_step
  - profile_completion_percent
- Migracao adicionada para colunas de progresso em profiles.

## Arquivos principais alterados
- hamvit_mobile/lib/router/app_router.dart
- hamvit_mobile/lib/features/profile/profile_edit_screen.dart
- hamvit_mobile/lib/features/activities/preferences/activity_preferences_screen.dart
- hamvit_mobile/lib/features/settings/profile_page.dart
- hamvit_mobile/lib/features/profile/goals_page.dart
- hamvit_mobile/lib/features/onboarding/presentation/my_profile_hub_screen.dart
- hamvit_mobile/lib/shared/widgets/hamvit_side_drawer.dart
- hamvit_mobile/lib/features/activities/activities_page.dart
- hamvit_mobile/lib/features/onboarding/providers/onboarding_profile_provider.dart
- supabase/migrations/20260524000014_onboarding_editing_state.sql

## Validacao esperada
1. Usuario logado abre telas de edicao e nao ve "Passo X de 5".
2. Botoes "Editar" nunca apontam para /onboarding/*.
3. Rotas permanentes funcionam com dados reais e salvam no mesmo backend.
4. Onboarding wizard continua disponivel para primeira configuracao e CTA "Completar perfil".
