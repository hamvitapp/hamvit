# HAMVIT Home Dashboard com Dados Reais

## Objetivo
- Garantir que os numeros da Home sejam calculados apenas com dados reais do usuario autenticado.
- Eliminar calculos sinteticos e cards sem acao.

## Camada de dados
- Model: `hamvit_mobile/lib/features/home/domain/home_dashboard_model.dart`
- Repository: `hamvit_mobile/lib/features/home/data/home_dashboard_repository.dart`
- Provider: `hamvit_mobile/lib/features/home/providers/home_dashboard_provider.dart`

## Fontes reais consumidas
- `hydration_logs`: soma diaria de agua consumida.
- `daily_nutrition_targets`: metas diarias de agua/calorias (com fallback de compatibilidade).
- `meal_logs` + `meal_items`: calorias registradas no dia.
- `user_habits` + `habit_logs`: total e concluidos no dia.
- `activity_sessions`: distancia e minutos ativos no dia.
- `sleep_logs`: ultimo sono registrado.
- `home_daily_summaries`: tendencia semanal do score (quando disponivel).

## Quick actions gravando no banco
- Registrar agua: insere `+200 ml` em `hydration_logs`.
- Registrar refeicao: dialogo de kcal e insert em `meal_logs` + `meal_items`.
- Registrar habito: conclui um habito pendente em `habit_logs`.
- Iniciar caminhada: cria sessao em `activity_sessions` com `started_at`.

## Navegacao dos cards
- Agua: `/hydration`
- Calorias: `/nutrition`
- Habitos: `/habits`
- Atividade: `/activities`
- Sono: `/sleep`
- Score: `/reports/daily`

## Estados de UX
- Loading: skeleton de cards (sem valores fake).
- Empty: mensagem orientando uso das quick actions quando nao ha registros no dia.
- Error: bloco de erro com botao de retry.
- Offline/cache: fallback com ultimo dashboard carregado em memoria.
- Refresh: pull-to-refresh + refresh ao retornar de rotas abertas pela Home.

## Migracao aplicada
- Arquivo: `supabase/migrations/20260524000011_home_dashboard_real_data.sql`
- Inclui:
  - alteracoes de compatibilidade em tabelas legadas (`hydration_logs`, `meal_logs`, `activity_sessions`, `daily_nutrition_targets`)
  - criacao de `sleep_logs`
  - criacao de `home_daily_summaries`
  - RLS e politicas owner para as novas tabelas

## Migracao complementar de contrato
- Arquivo: `supabase/migrations/20260524000012_home_dashboard_contract_and_rls.sql`
- Inclui:
  - alinhamento de colunas contratuais (`sleep_logs.slept_at/woke_at/duration_minutes/quality/notes`)
  - alinhamento de colunas de cache (`home_daily_summaries.water_consumed_ml`, `daily_score_percent`, etc.)
  - reforco de RLS/policies owner para tabelas da Home (`hydration_logs`, `daily_nutrition_targets`, `meal_logs`, `habit_logs`, `activity_sessions`, `sleep_logs`, `home_daily_summaries`)
