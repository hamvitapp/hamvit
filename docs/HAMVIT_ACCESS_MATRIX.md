# HAMVIT Access Matrix (Free vs Premium)

## Principios oficiais

- Premium Vitalicio.
- Sem mensalidade.
- Sem anuncios.
- Evolua no seu ritmo.
- Free deve permanecer funcional sem bloqueio agressivo.

## Matriz oficial aplicada

| Feature | Free | Premium |
|---|---|---|
| Diario alimentar manual | Liberado | Liberado |
| Scanner de codigo de barras | Liberado | Liberado |
| IA de foto da comida | Bloqueado | Liberado (limite inicial de 3 fotos/dia) |
| Recomendacoes automaticas de alimentacao | Bloqueado | Liberado |
| Relatorios em tela | Liberado | Liberado |
| Exportacao PDF | Bloqueado | Liberado |
| Compartilhamento de relatorios | Bloqueado | Liberado |
| Analytics basico | Liberado | Liberado |
| Analytics avancado | Bloqueado | Liberado |
| Atividade fisica basica | Liberado | Liberado |
| Evolucao corporal basica | Liberado | Liberado |
| Recursos avancados de comparativos/insights | Bloqueado | Liberado |

## Centralizacao tecnica

- Matriz central em [hamvit_mobile/lib/core/premium/premium_access_matrix.dart](hamvit_mobile/lib/core/premium/premium_access_matrix.dart).
- Componentes de gate e upsell em [hamvit_mobile/lib/core/premium/premium_widgets.dart](hamvit_mobile/lib/core/premium/premium_widgets.dart).
- Guardas de rota dedicados em [hamvit_mobile/lib/core/premium/route_guards.dart](hamvit_mobile/lib/core/premium/route_guards.dart).

## Back-end enforcement

- Verificacao de entitlement premium centralizada em [supabase/functions/_shared/entitlements.ts](supabase/functions/_shared/entitlements.ts).
- Food photo validado no backend em [supabase/functions/food-photo/index.ts](supabase/functions/food-photo/index.ts).
- Reports PDF validado no backend em [supabase/functions/reports/index.ts](supabase/functions/reports/index.ts).

## UX de paywall

- Upsell elegante e contextual via card/sheet.
- Sem popups agressivos e sem bloquear funcionalidades essenciais do plano Free.
- Mensagens padrao:
  - Premium Vitalicio
  - Sem mensalidade
  - Sem anuncios
  - Evolua no seu ritmo.
