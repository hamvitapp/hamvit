# HAMVIT Navigation Stack Fix

## Objetivo

Corrigir o comportamento de navegação hierárquica para que subtelas retornem sempre para a tela imediatamente anterior no stack, sem saltar para Home indevidamente.

## Problema raiz identificado

O fluxo interno estava usando `context.go(...)` em várias subtelas. Como `go` troca rota de forma declarativa no nível atual, o histórico da pilha era descartado em cenários internos.

Exemplo observado:

- Configurações -> Privacidade -> Política de Privacidade
- Voltar
- Resultado incorreto: retorno direto para Home

## Regra aplicada

- Navegação interna/subtelas: `context.push(...)`.
- Navegação raiz/módulo principal/autenticação: `context.go(...)`.
- Botão voltar: `Navigator.pop()` (via AppBar/back do sistema) sempre que houver stack.

## Arquivos ajustados

### Configurações e legal

- `hamvit_mobile/lib/features/settings/settings_screen.dart`
  - Links para `account/security/notifications/privacy/accessibility/data-export` migrados de `go` para `push`.

- `hamvit_mobile/lib/features/settings/privacy/privacy_settings_screen.dart`
  - Abertura de Política e Termos migrada para `push`.
  - Abertura de relatórios compartilhados migrada para `push`.

- `hamvit_mobile/lib/features/settings/account/account_settings_screen.dart`
  - Navegação para perfil, metas e premium migrada para `push`.
  - Logout mantém `go('/login')` por ser transição de raiz.

- `hamvit_mobile/lib/features/settings/data_export/data_export_settings_screen.dart`
  - Navegação para premium e relatórios migrada para `push`.

- `hamvit_mobile/lib/features/settings/preferences_page.dart`
  - Navegação para preferências alimentares e hidratação migrada para `push`.

### Perfil, objetivos e hubs

- `hamvit_mobile/lib/features/settings/profile_page.dart`
  - Botões de edição migrados para `push`.

- `hamvit_mobile/lib/features/profile/goals_page.dart`
  - Ações de edição (objetivo, corpo, alimentação, atividade, sono, hidratação) migradas para `push`.

- `hamvit_mobile/lib/features/onboarding/presentation/my_profile_hub_screen.dart`
  - Tiles internas migradas para `push`.

### Relatórios

- `hamvit_mobile/lib/features/reports/reports_page.dart`
  - Abertura de relatório de evolução e analytics migrada para `push`.

- `hamvit_mobile/lib/features/reports/evolution_report_screen.dart`
  - Ação "Ver histórico" agora faz `pop` quando possível; sem stack, faz `push('/reports')`.

### Nutrição, atividade e premium teaser

- `hamvit_mobile/lib/features/activities/activities_page.dart`
  - Soft gate para dados corporais migrado para `push`.

- `hamvit_mobile/lib/features/nutrition/nutrition_page.dart`
  - Aberturas de preferências alimentares migradas para `push`.

- `hamvit_mobile/lib/features/nutrition/preferences/food_preferences_screen.dart`
  - Abertura de premium migrada para `push`.

- `hamvit_mobile/lib/features/meal_recommendations/meal_recommendations_page.dart`
  - Teaser premium migrado para `push`.

- `hamvit_mobile/lib/core/premium/premium_widgets.dart`
  - Upsell sheet abre premium com `push`.

### Onboarding

- `hamvit_mobile/lib/features/onboarding/presentation/welcome_screen.dart`
  - Início do onboarding (`/onboarding/goal`) migrado para `push`.

- `hamvit_mobile/lib/features/onboarding/presentation/general_profile_flow.dart`
  - Transição para `/onboarding/activity` migrada para `push`.

- `hamvit_mobile/lib/features/onboarding/presentation/activity_profile_flow.dart`
  - Transição para `/onboarding/food` migrada para `push`.

- `hamvit_mobile/lib/shared/widgets/hamvit_onboarding_widgets.dart`
  - Helper `openOnboardingFlow` migrado para `push`.

### Drawer

- `hamvit_mobile/lib/shared/widgets/hamvit_side_drawer.dart`
  - Adicionado `_push(...)` para rotas internas.
  - Itens hierárquicos de Perfil, Configurações, Relatórios, Suporte e subpáginas migrados para `push`.
  - `go` mantido disponível para cenários de troca de módulo raiz.

## Comportamento esperado após correção

Exemplo principal:

- Home
- Configurações
- Privacidade
- Política de Privacidade
- Voltar -> Privacidade
- Voltar -> Configurações
- Voltar -> tela anterior (ex.: Home)

## Observações

- `context.go(...)` permanece em fluxos de autenticação e retornos explícitos para Home (encerramento de fluxo), conforme regra de navegação raiz.
- O `hamvitBackAppBar` continua priorizando `Navigator.pop()` e só usa fallback para Home quando não existe stack.

## Validação recomendada (manual)

1. Configurações -> Privacidade -> Política de Privacidade -> voltar duas vezes.
2. Configurações -> Segurança -> voltar.
3. Relatórios -> Relatório de evolução -> voltar.
4. Perfil -> Objetivos -> Editar objetivo -> voltar.
5. Validar botão físico Android, botão de AppBar e gesto (iOS).
