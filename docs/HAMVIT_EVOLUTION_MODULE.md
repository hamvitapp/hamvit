# HAMVIT Evolution Module

## Objetivo
Transformar Evolucao em um modulo real de progresso corporal com historico, graficos, metas e insights acolhedores.

## Entrega principal
- Substituicao da calculadora isolada de IMC pela tela completa de evolucao.
- Persistencia real no Supabase para pesagens, medidas e fotos.
- Cards premium com resumo, objetivo, IMC historico, linha do tempo e insights.
- Grafico real de peso com filtros de periodo (7, 30, 90, 365 dias e tudo).
- Registro de peso por modal com data DD/MM/AAAA e observacao opcional.

## Arquitetura
### Camada Domain
- lib/features/evolution/domain/bmi_calculator.dart
- lib/features/evolution/domain/weight_progress_engine.dart
- lib/features/evolution/domain/evolution_insights_engine.dart
- lib/features/evolution/domain/body_metrics_service.dart

### Camada Data
- lib/features/evolution/evolution_models.dart
- lib/features/evolution/evolution_repository.dart
- lib/features/evolution/evolution_provider.dart

### Camada UI
- lib/features/evolution/evolution_screen.dart
- lib/features/evolution/add_weight_screen.dart
- lib/features/evolution/body_measurements_screen.dart
- lib/features/evolution/progress_photos_screen.dart
- lib/features/evolution/weight_history_screen.dart
- lib/features/evolution/widgets/evolution_widgets.dart

### Integração de rota/tela
- lib/features/progress/progress_page.dart agora delega para EvolutionScreen.

## Blocos implementados na tela
1. Resumo premium da evolucao (peso inicial/atual/alvo, IMC, progresso, tempo).
2. Grafico de evolucao do peso com fl_chart.
3. Card de evolucao de IMC com classificacao acolhedora.
4. Card de progresso do objetivo com barra visual.
5. Historico de pesagens (data DD/MM/AAAA, peso, variacao, IMC).
6. Registro de peso via bottom sheet.
7. Secao de medidas corporais com historico e variacao.
8. Card e tela de fotos corporais privadas.
9. Insights de evolucao orientados a consistencia.

## Supabase
Migration adicionada:
- supabase/migrations/20260524000013_evolution_module_real.sql

Inclui:
- alteracoes em weight_logs (bmi, notes, created_at, updated_at)
- alteracoes em body_measurements (measured_at e colunas especificas)
- criacao de progress_photos
- indices para consultas por usuario/data
- RLS e policy owner para progress_photos e reforco em weight/body_measurements

## Regras UX aplicadas
- Evolucao nao inicia mais como calculadora isolada.
- Tom acolhedor, sem linguagem ofensiva.
- Foco em consistencia e longo prazo.
- Nao ha promessa de resultado rapido.

## Integracao com Home
- Home possui card Evolucao com atalho para /progress e contexto de peso atual x alvo.

## Validacao tecnica esperada
- flutter analyze sem erros.
- fluxo de registrar peso atualiza modulo de evolucao.
- listas e graficos refletem dados reais do usuario autenticado.
