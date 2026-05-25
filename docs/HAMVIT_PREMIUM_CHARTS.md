# HAMVIT Premium Charts

## Objetivo
Evoluir os dashboards do HAMVIT para uma experiência wellness premium com:
- dados reais do Supabase
- interpretação automática (insights)
- metas visuais
- tooltips elegantes
- animações suaves
- loading e empty state amigáveis
- seletor de período persistente

## Escopo implementado

### Dashboard principal
Arquivo: `lib/features/dashboard/dashboard_page.dart`

- 8 gráficos ativos:
  - Água
  - Calorias
  - Hábitos
  - Atividade
  - Sono
  - Evolução de peso
  - IMC
  - Consistência
- Todos com:
  - seletor de período
  - linha suave com área preenchida em gradiente
  - linha de meta tracejada
  - tooltip customizado
  - insight textual
  - resumo rápido no rodapé
  - loading premium
  - estado vazio sem dados fake

### Períodos suportados
- 7 dias
- 30 dias
- 90 dias
- 1 ano
- Tudo

Persistência da seleção via `SharedPreferences`.

## Arquitetura criada

### Domain
- `lib/features/dashboard/domain/chart_aggregation_service.dart`
  - agregação real por período
  - normalização diária
  - cálculo de metas e resumo
- `lib/features/dashboard/domain/chart_insight_engine.dart`
  - engine textual acolhedora para tendência, estabilidade e metas
- `lib/features/dashboard/domain/dashboard_metrics_service.dart`
  - orquestração final dos 8 gráficos
  - provider de período persistente
  - provider de snapshot para UI

### Widgets
- `lib/features/dashboard/widgets/hamvit_line_chart.dart`
- `lib/features/dashboard/widgets/hamvit_chart_card.dart`
- `lib/features/dashboard/widgets/hamvit_chart_header.dart`
- `lib/features/dashboard/widgets/hamvit_goal_line.dart`
- `lib/features/dashboard/widgets/hamvit_chart_tooltip.dart`
- `lib/features/dashboard/widgets/hamvit_chart_insight.dart`
- `lib/features/dashboard/widgets/hamvit_period_selector.dart`
- `lib/features/dashboard/widgets/hamvit_empty_chart_state.dart`
- `lib/features/dashboard/widgets/hamvit_loading_chart_state.dart`

## Fontes de dados reais usadas
- `hydration_logs`
- `meal_logs`
- `meal_items`
- `habit_logs`
- `activity_sessions`
- `sleep_logs`
- `weight_logs` (com fallback para `body_progress_logs`)
- `health_profiles` (altura e meta de peso)
- `daily_nutrition_targets` (metas)
- `user_habits` (meta de hábitos)

## Home dashboard
Arquivo: `lib/features/home/data/home_dashboard_repository.dart`

- trend semanal deixou de usar fallback mockado constante.
- quando não há `home_daily_summaries`, o trend é calculado com dados reais de:
  - hidratação
  - alimentação
  - hábitos
  - atividade
  - sono

## Design wellness premium
- visual clean e acolhedor
- sem aparência de BI financeiro
- grid minimalista
- cores coerentes por métrica
- motion leve e não intrusivo

## Qualidade
- implementação incremental sem remover módulos existentes.
- providers antigos de dashboard mantidos com `@Deprecated` para compatibilidade.
- validação com `flutter analyze` nos arquivos alterados.
