# HAMVIT Mercado Pago - Notas de Implementacao

## 1) Auditoria no projeto de referencia (HQuiz KPOP)

Caminho auditado: E:\Projetos\Projeto HQuiz KPOP

Arquivos encontrados com implementacao/referencias relevantes:
- src/components/PlanPaymentModal.tsx
- src/services/mercadoPagoClient.ts
- src/pages/Plans.tsx
- database/schema.sql
- database/migrations/20260510_mercado_pago_billing_tables.sql
- database/rls.sql
- .env.example
- src/config/vite-env.d.ts

Observacoes importantes da auditoria:
- HQuiz tem fluxo de PIX e cartao funcional no frontend web.
- HQuiz usa polling para sincronizar status de PIX.
- HQuiz persiste tabelas de pagamentos e eventos de webhook.
- HQuiz usa external_reference, provider_payment_id e status do MP.
- HQuiz expoe anti-pattern critico: token de acesso Mercado Pago no frontend (VITE_MERCADO_PAGO_ACCESS_TOKEN). Esse padrao NAO foi reaproveitado no HAMVIT.

## 2) O que foi reaproveitado e adaptado para HAMVIT

Reaproveitado conceitualmente:
- Fluxo prioritario PIX.
- Fluxo alternativo cartao por preference (Checkout).
- Persistencia de payment e webhook para rastreabilidade.
- Uso de external_reference para correlacao segura.
- Tratamento de status approved/pending/rejected.

Adaptacoes obrigatorias para arquitetura HAMVIT:
- Toda criacao de pagamento movida para backend seguro (Supabase Edge Function).
- Nenhum segredo Mercado Pago no app Flutter.
- Validacao de autenticacao pelo token do usuario na Edge Function.
- Webhook idempotente com tabela payment_webhooks e chave unica de evento.
- Ativacao premium apenas no backend apos confirmacao do Mercado Pago.
- Registro de cupom/comissao e vinculo paciente-profissional no backend.

## 3) Variaveis de ambiente necessarias

Variaveis documentadas em .env.example (sem valores reais):
- MERCADO_PAGO_ACCESS_TOKEN
- MERCADO_PAGO_PUBLIC_KEY
- MERCADO_PAGO_WEBHOOK_SECRET
- MERCADO_PAGO_WEBHOOK_URL
- MERCADO_PAGO_SUCCESS_URL
- MERCADO_PAGO_FAILURE_URL
- MERCADO_PAGO_PENDING_URL
- HAMVIT_APP_URL
- SUPABASE_URL
- SUPABASE_ANON_KEY
- SUPABASE_SERVICE_ROLE_KEY

## 4) Diferencas HQuiz x HAMVIT

- HQuiz: frontend web com SDK do Mercado Pago no cliente.
- HAMVIT: Flutter + Supabase Edge Functions (backend-first).
- HQuiz: token de acesso no frontend (inseguro).
- HAMVIT: access token apenas no backend.
- HQuiz: foco em assinatura/plano do app web.
- HAMVIT: premium vitalicio, sem recorrencia e com regras RCP (entitlements + profile + comissao).

## 5) Implementacoes feitas no HAMVIT

Banco (migration incremental):
- supabase/migrations/20260521000007_mercado_pago_hardening.sql

Edge Functions:
- supabase/functions/create-mercado-pago-payment/index.ts
- supabase/functions/mercado-pago-webhook/index.ts

Flutter Premium:
- hamvit_mobile/lib/features/premium/payment_repository.dart
- hamvit_mobile/lib/features/premium/premium_controller.dart
- hamvit_mobile/lib/features/premium/coupon_input.dart
- hamvit_mobile/lib/features/premium/payment_status_screen.dart
- hamvit_mobile/lib/features/premium/premium_screen.dart
- hamvit_mobile/lib/features/premium/premium_page.dart (adaptado para usar premium_screen)

## 6) Resultado do alinhamento

- PIX priorizado no fluxo.
- Cartao mantido como opcao via checkout preference.
- Premium vitalicio sem recorrencia.
- Webhook idempotente e com correlacao de pagamento.
- Entitlement premium_lifetime ativado somente apos approved confirmado no backend.
- Profile atualizado para premium_active = true e plan = premium_lifetime.
- Cupom validado no backend com registro de comissao e vinculo profissional quando aplicavel.
