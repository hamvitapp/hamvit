# HAMVIT Indoor Activity Support

## Escopo implementado
- Separacao de atividades `outdoor` e `indoor`.
- Seletor de tipos:
  - Caminhada outdoor
  - Corrida outdoor
  - Caminhada indoor
  - Corrida indoor
  - Esteira
  - Bicicleta ergonometrica
- Tracking hibrido:
  - Outdoor: GPS (`tracking_mode = gps`)
  - Indoor: manual por tempo/velocidade (`tracking_mode = manual`)
- Calculo de distancia indoor por `velocidade x tempo`.
- Calorias por MET com label de estimativa.
- Edicao manual ao finalizar atividade indoor:
  - distancia final
  - velocidade media
- Persistencia de campos hibridos em `activity_sessions`.
- Home dashboard preparado para atividade indoor:
  - distancia e tempo de atividade
  - calorias estimadas no card de atividade.

## Novos arquivos Flutter
- `lib/features/activities/activity_type_selector.dart`
- `lib/features/activities/indoor_activity_screen.dart`
- `lib/features/activities/treadmill_activity_screen.dart`
- `lib/features/activities/activity_tracking_engine.dart`
- `lib/features/activities/calorie_estimation_service.dart`

## Arquivos alterados
- `lib/features/activities/activities_page.dart`
- `lib/features/home/data/home_dashboard_repository.dart`
- `lib/features/home/domain/home_dashboard_model.dart`
- `lib/features/home/widgets/home_dashboard/hamvit_home_dashboard.dart`
- `lib/features/home/widgets/daily_stats/hamvit_daily_stats_grid.dart`
- `lib/features/home/today_page.dart`

## Banco de dados
Migration criada:
- `supabase/migrations/20260524000015_activity_indoor_hybrid_support.sql`

Campos adicionados em `activity_sessions`:
- `tracking_mode` (`gps|manual|hybrid`)
- `activity_environment` (`indoor|outdoor`)
- `manual_distance_meters`
- `manual_speed_kmh`
- `estimated_calories_kcal`
- `average_pace_seconds`
- `average_speed_kmh`

## Regras de calculo
- Distancia indoor:
  - `distance_meters = speed_kmh * 1000 * (duration_seconds / 3600)`
- Calorias estimadas:
  - `calorias = MET * peso_kg * horas`

## Observacoes
- Atividade indoor nao depende de GPS.
- Arquitetura pronta para evolucao com Health Connect/watch como proxima etapa.
