# HAMVIT Monorepo

Slogan oficial: **HAMVIT - Evolua no seu ritmo.**

## Estrutura
- `hamvit_mobile`: app Flutter.
- `hamvit_admin`: painel Next.js.
- `hamvit_backend`: funções críticas.
- `supabase`: migrations, RLS, funções e seeds SQL para Supabase Cloud.
- `seeds`: seed estruturado de receitas.
- `docs`: documentação técnica e índice mestre RCP.

## Comandos esperados
### Mobile
- `cd hamvit_mobile`
- `flutter pub get`
- `flutter run --dart-define=SUPABASE_URL=https://SEU_PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_...`

### Admin
- `cd hamvit_admin`
- `npm.cmd install`
- `npm.cmd run dev`

### Supabase Cloud
- `supabase link --project-ref <project_ref>`
- `supabase db push --include-all --yes`
- `supabase db query --linked -f supabase/seeds/20260521_recipes_seed_utf8.sql`

### Payments (Mercado Pago)
- `supabase functions deploy create-mercado-pago-payment`
- `supabase functions deploy mercado-pago-webhook`

## Dependências de ambiente necessárias
- JDK 17 + Android SDK/cmdline-tools (build Android Flutter).
- Flutter SDK.
- Supabase CLI.

## Variáveis de ambiente para pagamentos
- `MERCADO_PAGO_ACCESS_TOKEN`
- `MERCADO_PAGO_PUBLIC_KEY`
- `MERCADO_PAGO_WEBHOOK_SECRET`
- `MERCADO_PAGO_WEBHOOK_URL`
- `MERCADO_PAGO_SUCCESS_URL`
- `MERCADO_PAGO_FAILURE_URL`
- `MERCADO_PAGO_PENDING_URL`
- `HAMVIT_APP_URL`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
