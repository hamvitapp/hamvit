# HAMVIT Monorepo

Slogan oficial: **HAMVIT - Evolua no seu ritmo.**

## Estrutura
- `hamvit_mobile`: app Flutter.
- `hamvit_admin`: painel Next.js.
- `hamvit_backend`: funções críticas.
- `supabase`: migrations, RLS e seeds SQL.
- `seeds`: seed estruturado de receitas.
- `docs`: documentação técnica e índice mestre RCP.

## Comandos esperados
### Mobile
- `cd hamvit_mobile`
- `set PATH=e:\Projetos\Projeto HAMFIT\tools\flutter\bin;%PATH%` (Windows local SDK)
- `flutter pub get`
- `flutter run`

### Admin
- `cd hamvit_admin`
- `npm.cmd install`
- `npm.cmd run dev`

### Supabase
- `supabase start`
- `supabase db reset`

### Payments (Mercado Pago)
- `supabase functions serve create-mercado-pago-payment --env-file .env`
- `supabase functions serve mercado-pago-webhook --env-file .env`
- `supabase functions deploy create-mercado-pago-payment`
- `supabase functions deploy mercado-pago-webhook`

## Checklist de inicialização
- [x] Índice mestre com precedência dos RCPs.
- [x] Estrutura de pastas do projeto.
- [x] Base de design system Flutter criada.
- [x] Navegação base (bottom nav + drawer parcial).
- [x] Migration inicial com tabelas e RLS base.
- [x] Seed de 300 receitas convertido para JSON/CSV.
- [ ] Execução Flutter local (SDK ausente no ambiente atual).
- [ ] Execução Supabase local (depende de Docker Desktop).
- [ ] Testes automatizados.


## Dependências de ambiente ainda necessárias
- Docker Desktop (para `supabase start` local).
- JDK 17 + Android SDK/cmdline-tools (para build Android Flutter).

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

## Fluxo oficial Premium (backend seguro)
- Flutter chama `create-mercado-pago-payment` para criar pagamento PIX ou preference de checkout.
- Mercado Pago envia notificacao para `mercado-pago-webhook`.
- O backend valida o pagamento no provedor e atualiza `payments`.
- Em `approved`, backend ativa `user_entitlements` (`premium_lifetime`) e atualiza `profiles`.
- Se houver cupom valido, backend registra `professional_commissions` e `patient_professional_links`.
- O app Flutter apenas le status/entitlement e libera recursos Premium apos confirmacao backend.

## Regras de datas e metas calculadas
- Datas de interface devem sempre aparecer em DD/MM/AAAA.
- Metas de calorias e água devem ser calculadas pelo sistema, evitando campo livre como padrão.
- Documento técnico: docs/HAMVIT_GOALS_AND_DATE_RULES.md.

## Correcao incremental aplicada: Auth/Login HAMVIT

Implementacao realizada de forma incremental, preservando arquitetura existente e integrando Supabase Auth + Riverpod + GoRouter com protecao de rotas.

### Escopo implementado
- Cadastro com nome, e-mail, senha e confirmacao.
- Politica de senha no app: minimo 8 chars, 1 maiuscula, 1 numero, 1 especial.
- Login por Supabase Auth.
- Recuperacao de senha e tela de redefinicao.
- Logout com limpeza de estado de sessao no provider.
- Bootstrap de sessao no start do app com criacao/garantia de `profiles`.
- Carregamento de `profiles` e `user_entitlements` no estado autenticado.
- Estados de auth: `initial`, `loading`, `unauthenticated`, `authenticated`, `needsOnboarding`, `error`.
- Protecao de rotas por autenticacao, premium e admin em GoRouter.
- Redirecionamento de Free para paywall em rotas Premium.
- Onboarding inicial apos cadastro/login quando `onboarding_completed = false`.

### Arquivos principais adicionados/ajustados
- `hamvit_mobile/lib/features/auth/data/auth_repository.dart`
- `hamvit_mobile/lib/features/auth/domain/auth_state.dart`
- `hamvit_mobile/lib/features/auth/providers/auth_provider.dart`
- `hamvit_mobile/lib/features/auth/presentation/login_screen.dart`
- `hamvit_mobile/lib/features/auth/presentation/register_screen.dart`
- `hamvit_mobile/lib/features/auth/presentation/forgot_password_screen.dart`
- `hamvit_mobile/lib/features/auth/presentation/reset_password_screen.dart`
- `hamvit_mobile/lib/features/auth/presentation/onboarding_screen.dart`
- `hamvit_mobile/lib/router/app_router.dart`
- `hamvit_mobile/lib/shared/widgets/hamvit_scaffold.dart`

### Banco e RLS (incremental)
- Migration: `supabase/migrations/20260521000005_auth_module_alignment.sql`
- Adiciona/alinha enums e campos de `profiles` e `user_entitlements` sem destruir dados existentes.
- Ativa/ajusta RLS para leitura/escrita propria em `profiles`.
- `user_entitlements` com leitura propria e escrita restrita a `service_role`.
- Trigger de protecao para impedir alteracao manual de `role`, `plan` e `premium_active` pelo cliente.

### Comandos locais de validacao
- `cd E:\Projetos\Projeto HAMFIT`
- `npx supabase db reset`
- `cd hamvit_mobile`
- `flutter analyze`
- `flutter test`
