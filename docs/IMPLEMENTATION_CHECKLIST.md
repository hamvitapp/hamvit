# HAMVIT - Checklist de Implementação (Execução Atual)

## Etapas concluídas nesta execução
- [x] Leitura dos RCPs e índice mestre com precedência.
- [x] Estrutura monorepo (`hamvit_mobile`, `hamvit_admin`, `hamvit_backend`, `supabase`, `docs`, `seeds`).
- [x] Design system base Flutter (tema/paleta/componentes iniciais).
- [x] Navegação base com bottom nav (5 itens) + drawer lateral parcial.
- [x] Auth base Supabase no app (login, sign up/recovery hooks).
- [x] Separação inicial Free/Premium na UI de alimentação/hoje/perfil.
- [x] Migrações iniciais com tabelas obrigatórias + políticas RLS base.
- [x] Migração complementar de bucket privado e guardas Premium.
- [x] Conversão das 300 receitas para JSON/CSV.
- [x] Geração de seed SQL para receitas e perfis nutricionais.
- [x] Backend inicial para recomendação Premium, limite de foto IA e barcode lookup.
- [x] Admin Next.js compilando com rotas iniciais de módulos obrigatórios.

## Validações executadas
- [x] `flutter analyze` (passou; 2 lints informativos de `const`, sem erro).
- [x] `npm run build` no admin (sucesso).
- [x] `supabase init` (sucesso).
- [x] `supabase db push` (sucesso).
- [x] `supabase db reset` com migrations + seed oficial (sucesso).
- [x] Teste real local de Edge Functions:
  - [x] `scanner` (resolução/cache local funcionando).
  - [x] `food-photo` (bloqueio Free + execução Premium + limite diário preparado).
  - [x] `payments` (criação pendente + simulação webhook approved ativando premium).
  - [x] `reports` (Free `screen_only` e Premium `pdf`).
- [x] `flutter test` (sucesso, incluindo teste de gating Free/Premium).
- [x] `flutter build apk --debug` (sucesso).
- [x] Evidências consolidadas de aceite local em `docs/HAMVIT_EVIDENCIAS_ACEITE_LOCAL.md`.

## Pendências técnicas de implementação (código)
- [ ] Fluxos completos de onboarding e coleta progressiva de perfil.
- [ ] Implementação completa de scanner nativo Flutter + revisão de porção.
- [ ] Fluxo completo de foto IA (captura/compressão/upload/fila offline/revisão).
- [ ] Módulo GPS caminhada/corrida com cálculos MET e histórico completo.
- [ ] Relatórios PDF Premium com branding + compartilhamento.
- [ ] Fluxo de pagamento Mercado Pago (PIX/cartão) + webhook final.
- [ ] CRUDs completos no admin com audit_logs por ação.
- [ ] Testes automatizados críticos (navegação, RLS, Premium/Free, offline).

## Pendências de instalação de ambiente
- [x] Supabase Cloud (ativo e funcional com WSL2).
- [x] Android SDK + cmdline-tools (instalado localmente no projeto).
- [x] JDK 17 (instalado localmente no projeto).
- [ ] (Opcional) Android Studio para gerenciamento do SDK/AVD.
- [ ] (Opcional) Visual Studio C++ workload apenas para build Windows desktop.
