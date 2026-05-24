# HAMVIT - RELATORIO DE EXECUCAO AUTOMATICA (2026-05-21)

## Supabase local
- supabase start: OK
- supabase db reset: OK (migrations + seed)

## Edge Functions (teste HTTP real)
- scanner: OK
- food-photo (free bloqueado): OK (`premium_required`)
- food-photo (premium permitido): OK
- payments create_payment: OK
- payments webhook_approved: OK (ativou premium)
- reports premium: OK (`mode: pdf`)
- reports free: OK (`mode: screen_only`)
- evidencias detalhadas: `docs/edge_functions_test_results.json`

## Flutter
- flutter pub get: OK
- flutter analyze: OK (2 avisos informativos de const)
- flutter test: OK
- flutter build apk --debug: OK
- artefato: `hamvit_mobile/build/app/outputs/flutter-apk/app-debug.apk`

## Admin Next.js
- npm run build: OK

## E2E Android camera/GPS
- status: PENDENTE por ambiente
- motivo: sem dispositivo Android conectado e sem AVD configurado
- comando de verificacao: `flutter devices` e `flutter emulators`

## IA Gemini real
- status: PRONTO NO CODIGO, nao ativado na execucao atual
- motivo: secret `GEMINI_API_KEY` nao definido nesta rodada
- comportamento atual: fallback seguro `deterministic_fallback`
