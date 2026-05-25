# HAMVIT Privacy Screen Protection

## Objetivo

Implementar proteção de privacidade contextual para telas sensíveis, mantendo UX leve nas áreas não sensíveis.

## Escopo atual

Proteção aplicada apenas em áreas sensíveis:

- Relatório de evolução
- PDF de relatórios (preview/exportação)
- Evolução corporal (peso/IMC/medidas)
- Fotos corporais
- Nutrição detalhada
- Dados e exportação
- Compartilhamento profissional no drawer

Telas não bloqueadas (sem proteção global):

- Home
- Hábitos
- Dashboard básico
- Onboarding
- Gamificação leve
- Telas promocionais

## Arquitetura

Novos arquivos em `hamvit_mobile/lib/features/privacy/`:

- `privacy_protection_service.dart`
- `screenshot_protection_service.dart`
- `app_blur_overlay.dart`
- `privacy_settings_screen.dart`

### Serviço central

`PrivacyProtectionService` concentra:

- controle de lifecycle (`WidgetsBindingObserver`)
- aplicação contextual de proteção Android (`FLAG_SECURE`)
- estado global de blur quando app vai para background
- persistência das preferências de proteção

### Wrapper de tela protegida

`HamvitProtectedScreenWrapper`:

- ativa proteção ao entrar na tela
- desativa ao sair
- exibe snackbar discreto:
  - `Capturas de tela desativadas nesta área por privacidade.`

### Overlay

`HamvitPrivacyOverlay`:

- blur suave
- fundo escuro premium
- identidade HAMVIT
- animação fade

Aplicado no app inteiro apenas para cenário de background/app switcher.

## Configurações

Em `Configurações > Privacidade` foi adicionada seção:

- `Bloquear capturas em telas sensíveis`
- `Ocultar app nos aplicativos recentes`
- `Blur automático ao minimizar o app`

Texto explicativo:

- `Protege informações sensíveis quando o app estiver aberto.`

## Persistência

Preferências salvas em `user_preferences`:

- `screenshot_protection_enabled`
- `app_blur_enabled`
- `hide_recent_apps_preview`

Migration:

- `supabase/migrations/20260525000019_privacy_screen_protection.sql`

RLS já é coberta pela política existente de `user_preferences` no módulo de settings.

## Android

Implementado em `MainActivity.kt` via `MethodChannel`:

- canal: `hamvit/privacy_protection`
- método: `setSecure`
- comportamento: aplica/remove `WindowManager.LayoutParams.FLAG_SECURE`

Efeitos esperados quando ativo:

- bloqueio de screenshot
- bloqueio de gravação/espelhamento
- ocultação de preview em recentes

## iOS

No workspace atual não há target iOS (`hamvit_mobile/ios` ausente).

Implementação Flutter já pronta para iOS no nível de UX:

- blur de privacidade no background/app switcher
- arquitetura preparada para evento de screenshot via `EventChannel`

Quando o target iOS for adicionado, falta conectar o evento nativo de screenshot para aviso discreto.

## PDF

PDF de evolução agora inclui:

- marca d'água discreta `HAMVIT`
- data/hora de geração (já existente)
- aviso explícito `Documento informativo.`

## Critérios de aceite atendidos nesta etapa

- sem bloqueio global irritante
- proteção contextual apenas em telas sensíveis
- home continua compartilhável
- configurações de privacidade disponíveis ao usuário
- overlay de privacidade ativo em background
- arquitetura centralizada e extensível
