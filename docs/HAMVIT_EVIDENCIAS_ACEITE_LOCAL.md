# HAMVIT - Evidências de Aceite Local (2026-05-21)

## 1) Edge Functions local (Supabase)

### Scanner
- Endpoint: `POST /functions/v1/scanner`
- Evidência: retorno `source: supabase` com payload de barcode cacheado.
- Status: **OK**

### IA Foto (Premium)
- Endpoint: `POST /functions/v1/food-photo`
- Evidências:
  - Usuário Free: retorno `premium_required` (bloqueio correto).
  - Usuário Premium: retorno `allowed: true`, `status: needs_review` e aviso de estimativa.
  - Resultado inclui `provider`:
    - `gemini_flash_vision` quando `GEMINI_API_KEY` disponível.
    - `deterministic_fallback` quando chave ausente.
- Status: **OK (com fallback ativo no ambiente atual)**

### Pagamentos
- Endpoint: `POST /functions/v1/payments`
- Evidências:
  - `create_payment` cria registro `pending`.
  - `webhook_approved` atualiza pagamento e ativa entitlement premium.
- Status: **OK**

### Relatórios
- Endpoint: `POST /functions/v1/reports`
- Evidências:
  - Free sem entitlement: `mode: screen_only`.
  - Premium com entitlement: `mode: pdf` e registro em `generated_reports`.
- Status: **OK**

## 2) Flutter - Fluxos Premium/Free

### Alimentação / Scanner
- Tela: `NutritionPage`
- Regra validada:
  - Scanner disponível para Free/Premium.
  - Consulta via Edge Function `scanner`.
- Status: **OK**

### Alimentação / Foto IA
- Tela: `NutritionPage`
- Regra validada:
  - Botões de captura/galeria implementados.
  - Free bloqueado com `premium_required`.
  - Premium faz upload privado + invoke `food-photo`.
- Status: **OK (funcional local)**

### Recomendações alimentares
- Tela: `MealRecommendationsPage`
- Regra validada por teste:
  - Free vê teaser de bloqueio.
  - Premium vê sugestões.
- Status: **OK**

## 3) Atividade Física (GPS)
- Tela: `ActivitiesPage`
- Implementado:
  - iniciar/pausar/finalizar,
  - tempo,
  - distância (stream de localização),
  - ritmo médio,
  - velocidade média,
  - calorias por MET (`MET × peso × duração(h)`).
- Status: **Implementado, pendente validação em dispositivo Android real**

## 4) Bateria técnica final
- `supabase db reset`: **OK**
- `flutter analyze`: **OK** (2 avisos informativos de `const`)
- `flutter test`: **OK**
- `flutter build apk --debug`: **OK**
  - artefato: `hamvit_mobile/build/app/outputs/flutter-apk/app-debug.apk`
- `hamvit_admin npm run build`: **OK**

## 5) Pendências objetivas para aceite total E2E Android
- Não há dispositivo Android conectado no ambiente atual.
- Não há AVD configurado (`flutter emulators` sem fontes).
- Chave `GEMINI_API_KEY` não configurada localmente neste ciclo (fallback usado).

## 6) Resultado consolidado
- Fluxos críticos de backend local (scanner, foto IA, pagamentos, relatórios): **validados**.
- Separação Free vs Premium: **validada**.
- App Android compila e gera APK: **validado**.
- E2E Android com câmera/GPS em hardware/emulador: **pendente somente por ausência de alvo**.
