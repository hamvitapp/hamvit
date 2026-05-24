# HAMVIT Food Preferences Screen

## Objetivo
Substituir o fluxo de onboarding na acao Editar alimentacao por uma tela permanente chamada Preferencias Alimentares, com persistencia real em banco e experiencia premium de configuracao.

## Rotas permanentes
- /profile/food-preferences
- /nutrition/preferences

A acao Editar alimentacao nao usa mais /onboarding/food.

## Onde foi integrado
- goals_page: botao Editar alimentacao -> /profile/food-preferences
- nutrition_page: CTA de configuracao e botao Editar preferencias -> /nutrition/preferences
- settings/preferences_page: item Preferencias alimentares -> /nutrition/preferences
- settings/profile_page: item Alimentacao -> /profile/food-preferences
- app_router: adicionadas duas rotas permanentes autenticadas

## Estrutura da tela
Header:
- voltar
- titulo: Preferencias Alimentares
- subtitulo: Personalize sua alimentacao para sugestoes mais inteligentes.

Card de valor:
- explica como os dados melhoram sugestoes e personalizacao
- badge condicional por plano:
  - Free: Premium desbloqueia sugestoes inteligentes.
  - Premium: Sugestoes personalizadas ativas.

Secoes implementadas:
1. Estilo alimentar (multi-chip)
2. Restricoes e alergias (chips + adicionar personalizado)
3. Alimentos que nao gosta (input + lista)
4. Alimentos favoritos (input + lista)
5. Rotina alimentar (refeicoes por dia, cozinha, tempo, marmita)
6. Objetivo alimentar (multi-chip)
7. Horarios/refeicoes (multi-chip + horario aproximado)
8. Orcamento/praticidade (multi-chip)
9. Card Premium vendavel no fim

Botoes fixos:
- Salvar preferencias
- Cancelar

Nao possui:
- Passo X de Y
- barra de onboarding
- botao Pular de onboarding

## Persistencia
Tabela principal:
- user_food_preferences

Campos:
- id
- user_id
- eating_styles
- restrictions
- disliked_foods
- favorite_foods
- meals_per_day
- cooking_frequency
- prep_time_preference
- lunchbox_habit
- food_goals
- usual_meals
- meal_times
- suggestion_style
- created_at
- updated_at

Migration:
- supabase/migrations/20260524000010_food_preferences_module.sql

RLS:
- usuario so le e edita as proprias preferencias (policy user_food_preferences_owner)

## Compatibilidade e transicao
Enquanto ambientes sem migration estiverem em uso, o repositorio aplica fallback para user_preferences/onboarding.food para manter compatibilidade com regras antigas e soft gates.

## Regras Free vs Premium
- Free:
  - pode preencher e salvar todas as preferencias
  - card vendavel exibido
  - sugestoes inteligentes continuam bloqueadas
- Premium:
  - pode salvar normalmente
  - contexto premium de recomendacao alimentar eh atualizado no user_preferences

## Arquivos da feature
- hamvit_mobile/lib/features/nutrition/preferences/food_preferences_screen.dart
- hamvit_mobile/lib/features/nutrition/preferences/food_preferences_controller.dart
- hamvit_mobile/lib/features/nutrition/preferences/food_preferences_repository.dart
- hamvit_mobile/lib/features/nutrition/preferences/food_preferences_model.dart
- hamvit_mobile/lib/features/nutrition/preferences/food_preferences_widgets.dart

## Validacao esperada
- Editar alimentacao nao abre mais onboarding.
- Tela abre com layout premium e secoes completas.
- Preferencias sao carregadas e salvas.
- Snackbar de sucesso apos salvar.
- Free salva e continua com gate premium para sugestoes automaticas.
