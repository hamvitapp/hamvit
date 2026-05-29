# HAMVIT - CHECKLIST FINAL DE ACEITE RCP (Execução Local)

Data: 2026-05-21

## 1) UX/Branding Mobile (RCP UX V3)
- [x] Paleta oficial aplicada no tema.
- [x] Bottom navigation com 5 itens (Hoje, Hábitos, Alimentação, Evolução, Perfil).
- [x] Drawer lateral parcial (~82%), com categorias expansíveis e subitens.
- [x] Slogan oficial presente: "Evolua no seu ritmo.".
- [x] Componentes base HAMVIT centralizados em `shared/widgets/hamvit_components.dart`.
- [x] Estilo visual atualizado para linguagem premium/clean (cards, tipografia, ícones, estados).

## 2) Funcionalidades Core
- [x] Auth base Supabase (login/sign up/recover/sign out).
- [x] Nutrição com diário base + scanner por Edge Function.
- [x] Foto de comida Premium com upload no Storage e revisão (`food-photo`).
- [x] Recomendações alimentares bloqueadas para Free e liberadas para Premium.
- [x] Premium/Pagamentos base com criação e simulação webhook approved.
- [x] Relatórios: Free em tela, Premium em PDF (registro em `generated_reports`).
- [x] Atividade física GPS com iniciar/pausar/finalizar + distância, ritmo, velocidade e MET.
- [x] Hidratação e hábitos com fluxo de uso local no app.

## 3) Supabase / Banco / Segurança
- [x] Migrations aplicando schema principal e complementos.
- [x] RLS base ativa nas tabelas-chave.
- [x] Seed oficial conectado ao reset e executando com sucesso.
- [x] Edge Functions locais para scanner, food-photo, payments, reports.
- [x] Segredos sensíveis fora do Flutter (backend/functions).

## 4) Testes e execução
- [x] `supabase db push` OK.
- [x] `supabase db reset` OK.
- [x] Testes HTTP reais das functions OK (arquivo `docs/edge_functions_test_results.json`).
- [x] `flutter test` OK.
- [x] `flutter analyze` OK (apenas 2 infos não bloqueantes).
- [x] `flutter build apk --debug` OK.
- [x] E2E Android de execução: emulador API 35 criado, app instalado e iniciado.

## 5) Evidências objetivas
- `docs/edge_functions_test_results.json`
- `docs/HAMVIT_RELATORIO_EXECUCAO_AUTOMATICA_2026-05-21.md`
- APK: `hamvit_mobile/build/app/outputs/flutter-apk/app-debug.apk`
- App Android em execução no emulador (`com.example.hamvit_mobile`, PID detectado)

## 6) Pendências reais remanescentes (não inventadas)
- [ ] Ativação de `GEMINI_API_KEY` local para troca de fallback por inferência real do Gemini.
- [ ] Validação manual de UX e jornada completa em dispositivo físico (câmera/GPS com uso humano real).
- [ ] Cobertura de testes automatizados E2E instrumentados (integração UI completa) ainda não implementada.
- [ ] Ajuste de identidade Android (`applicationId` ainda padrão `com.example.hamvit_mobile`).
- [ ] Alguns módulos seguem em versão funcional inicial (não profundidade total de produção em todos os subfluxos do RCP).
