# HAMVIT Onboarding UX Architecture

Implementacao oficial da arquitetura de onboarding contextual, soft gating e acesso parcial, conforme requisito obrigatorio.

## Principio aplicado

- Entrada rapida no app.
- Exploracao rapida sem bloqueio total.
- Solicitacoes contextuais suaves por tela.
- Desbloqueio progressivo conforme completude do perfil.

## Nivel 1 - Primeiro login

Fluxo implementado:

1. Login/Cadastro autenticado.
2. Redirecionamento para `WelcomeScreen`.
3. Tela com:
   - logo HAMVIT
   - slogan
   - ilustracao leve
   - texto: "Vamos personalizar sua experiencia."
   - botoes:
     - `Comecar`
     - `Pular por agora` (sempre visivel)
4. Acoes:
   - `Comecar` -> `GeneralProfileFlow`
   - `Pular por agora` -> Home

Arquivo principal:
- `hamvit_mobile/lib/features/onboarding/presentation/welcome_screen.dart`

## Estrutura obrigatoria da Home

Ordem implementada em `TodayPage`:

1. Header
2. `HamvitProfileCompletionCard`
3. Resumo do Dia
4. Habitos
5. Agua
6. Alimentacao
7. Atividades
8. Insights

Regras:
- `HamvitProfileCompletionCard` aparece abaixo do header.
- Card desaparece automaticamente quando onboarding essencial atinge >= 60%.

Arquivo:
- `hamvit_mobile/lib/features/home/today_page.dart`

## Onboarding essencial

Campos essenciais:
- objetivo
- peso
- altura
- atividade

Peso de completude:
- 15% para cada item essencial = 60% total

Regras:
- `profile_completion_percent >= 60` quando essenciais completos.
- Coleta restante permanece progressiva.

Provider:
- `hamvit_mobile/lib/features/onboarding/providers/onboarding_profile_provider.dart`

## Fluxos independentes e retomaveis

Fluxos implementados:
- `GeneralProfileFlow`
- `FoodPreferencesFlow`
- `ActivityProfileFlow`
- `SleepFlow`
- `HydrationFlow`

Caracteristicas:
- cada fluxo abre separadamente
- pode ser retomado depois
- salva progresso parcial em `user_preferences.data.onboarding`
- dados de peso/altura em `health_profiles`

Arquivos:
- `hamvit_mobile/lib/features/onboarding/presentation/general_profile_flow.dart`
- `hamvit_mobile/lib/features/onboarding/presentation/food_preferences_flow.dart`
- `hamvit_mobile/lib/features/onboarding/presentation/activity_profile_flow.dart`
- `hamvit_mobile/lib/features/onboarding/presentation/sleep_flow.dart`
- `hamvit_mobile/lib/features/onboarding/presentation/hydration_flow.dart`

## Soft gating oficial

### Alimentacao

Condicao:
- faltando objetivo ou preferencias ou restricoes

Comportamento:
- mostra `HamvitSoftGateCard` no topo da tela
- CTA `Configurar Alimentacao` -> `FoodPreferencesFlow`
- NAO bloqueia uso de diario manual, busca/scanner e registro

Arquivo:
- `hamvit_mobile/lib/features/nutrition/nutrition_page.dart`

### Caminhada/Corrida

Condicao:
- faltando peso ou altura ou atividade

Comportamento:
- mostra `HamvitSoftGateCard`
- CTA `Completar Dados` -> `ActivityProfileFlow`
- permite iniciar atividade normalmente
- calculos ficam limitados com aviso contextual

Arquivo:
- `hamvit_mobile/lib/features/activities/activities_page.dart`

### Relatorios

Condicao:
- perfil essencial incompleto

Comportamento:
- mensagem: "Complete seu perfil para relatorios mais precisos."
- sem bloqueio de acesso basico

Arquivo:
- `hamvit_mobile/lib/features/reports/reports_page.dart`

## Premium teaser sem popup agressivo

Implementado `PremiumTeaserCard` com:
- preview blur elegante
- beneficios
- textos de valor:
  - Premium Vitalicio
  - Sem mensalidade
  - Sem anuncios
- botoes:
  - `Conhecer Premium`
  - `Agora nao`

Arquivos:
- `hamvit_mobile/lib/core/premium/premium_widgets.dart`
- `hamvit_mobile/lib/features/meal_recommendations/meal_recommendations_page.dart`

## Navegacao obrigatoria no Drawer

Novo bloco:
- `Meu Perfil`

Itens:
- Objetivos
- Alimentacao
- Atividade Fisica
- Habitos
- Sono
- Preferencias

Cada item abre tela propria.

Arquivo:
- `hamvit_mobile/lib/shared/widgets/hamvit_side_drawer.dart`

## Componentes obrigatorios criados

- `HamvitProfileCompletionCard`
- `HamvitSoftGateCard`
- `HamvitContextualCTA`
- `HamvitOnboardingStepper`
- `HamvitProgressRing`
- `HamvitFeatureUnlockCard`

Arquivo:
- `hamvit_mobile/lib/shared/widgets/hamvit_onboarding_widgets.dart`

## Comportamento de botoes

Regras aplicadas nos fluxos:
- `Agora nao` disponivel em soft gate e premium teaser
- `Depois` disponivel nos fluxos contextuais
- `Pular` disponivel em fluxo nao critico
- sem travamento completo de navegacao

## Rotas adicionadas

- `/welcome`
- `/onboarding/general`
- `/onboarding/food`
- `/onboarding/activity`
- `/onboarding/sleep`
- `/onboarding/hydration`
- `/meu-perfil`

Arquivo:
- `hamvit_mobile/lib/router/app_router.dart`

## Validacao

- `flutter analyze` executado com sucesso (sem issues).
- arquitetura implementada em modo soft gating (sem hard blocking).
