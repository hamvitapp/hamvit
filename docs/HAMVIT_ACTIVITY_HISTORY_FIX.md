# HAMVIT Activity History Fix

## Causa encontrada

- O fluxo de finalização dependia de `_sessionId` criado no início da atividade.
- Quando o insert inicial falhava (ex.: instabilidade/offline), `_finish()` não criava registro final e o histórico continuava com dados antigos/zerados.
- O relatório usava colunas legadas (`distance_km`, `distance_m`, `calories_estimated`) e ignorava campos atuais (`distance_meters`, `manual_distance_meters`, `estimated_calories_kcal`), gerando atividade zerada em partes do app.

## Fluxo corrigido

1. Finalizar atividade calcula snapshot final (tempo, distância, velocidade, ritmo, calorias).
2. Tenta `update` por `id` quando sessão inicial existe.
3. Se não existir/falhar, tenta `insert` completo do snapshot final.
4. Se remoto falhar, salva payload local em fila offline (`SharedPreferences`).
5. Na próxima carga de atividades, fila offline é sincronizada automaticamente.
6. Após persistir, app invalida providers de:
   - histórico/atividade local
   - dashboard home
   - dashboard analítico
   - relatórios/evolução

## Persistência e sincronização

- Chave local: `hamvit_pending_activity_sessions_v1`
- Estrutura armazenada: JSON completo da sessão finalizada.
- Sincronização: executada antes do carregamento semanal em `_loadWeeklyFromDb()`.

## Atualização de providers

Após finalizar atividade:

- `activityRefreshTickProvider` incrementado
- `homeDashboardProvider` invalidado
- `dashboardSnapshotProvider` invalidado
- `evolutionReportProvider` invalidado
- `reportHistoryProvider` invalidado

Isso garante atualização imediata sem reiniciar tela/app.

## Histórico visual

- Histórico trocado para cards com:
  - tipo
  - indoor/outdoor
  - distância
  - duração
  - calorias
  - ritmo médio
  - data/hora
- Agrupamento por:
  - Hoje
  - Ontem
  - Esta semana
  - Mais antigas

## Logs temporários adicionados

- atividade iniciada
- atividade pausada/retomada
- atividade finalizada
- payload salvo
- resultado de update/insert/sync offline
- refresh do histórico
- invalidação de providers
