# HAMVIT Biometric Auth

## Objetivo

Adicionar biometria como desbloqueio local de sessão autenticada via Supabase, sem substituir Supabase Auth.

## Escopo implementado

- Login rápido local com biometria após sessão Supabase válida.
- Bloqueio biométrico ao reabrir app autenticado com biometria ativa.
- Rebloqueio após tempo em background maior que 5 minutos.
- Gate biométrico para telas sensíveis.
- Revalidação biométrica para ações críticas.

## Arquitetura

Novos arquivos em `hamvit_mobile/lib/features/security/`:

- `biometric_auth_service.dart`
- `biometric_settings_provider.dart`
- `biometric_gate.dart`
- `biometric_lock_screen.dart`

### Serviço

`BiometricAuthService`:

- verifica disponibilidade biométrica
- consulta tipos disponíveis
- solicita autenticação biométrica
- trata falhas e mensagens amigáveis

### Providers

- `biometricAvailableProvider`
- `biometricSettingsProvider`
- `biometricEnabledProvider`
- `biometricSensitiveScreensEnabledProvider`
- `biometricAppLockControllerProvider`

### Lock global

`HamvitBiometricAppLockOverlay` no `main.dart`:

- mantém Supabase Auth como fonte principal
- exige biometria para destravar sessão local quando configurado
- fallback para login por senha (`/login`) em caso de falha persistente

## Configuração em Segurança

Em `Configurações > Segurança`:

Seção **Biometria** com:

- Ativar desbloqueio por biometria
- Usar biometria em telas sensíveis

Texto exibido:

- `Use biometria do seu dispositivo para desbloquear o HAMVIT com mais segurança.`

Sem suporte biométrico:

- `Biometria não disponível neste dispositivo.`

## Telas sensíveis protegidas

Proteção biométrica antes de abrir:

- Relatório de evolução
- Relatórios PDF
- Fotos corporais
- Dados corporais
- Privacidade
- Dados e exportação
- Compartilhamento com profissional

## Ações críticas com revalidação

- Gerar PDF de relatório
- Compartilhar relatório profissional
- Exportar dados
- Solicitar exclusão de dados
- Solicitar exclusão de conta

## Persistência

Tabela: `user_preferences`

Novos campos:

- `biometric_unlock_enabled`
- `biometric_sensitive_screens_enabled`
- `last_biometric_unlock_at`

Migration:

- `supabase/migrations/20260525000020_biometric_auth_settings.sql`

Fallback:

- também persiste em `data.security.biometric` quando necessário.

## Segurança

Não armazena:

- senha
- token sensível
- credenciais fora do Supabase Auth

Armazena apenas:

- flags de biometria
- timestamp de último desbloqueio

## Android

- Dependência: `local_auth`
- `MainActivity` atualizada para `FlutterFragmentActivity`
- Permissões no AndroidManifest:
  - `android.permission.USE_BIOMETRIC`
  - `android.permission.USE_FINGERPRINT`

## iOS

No workspace atual não existe pasta `hamvit_mobile/ios`.

Pendência quando target iOS for adicionado:

- incluir em `Info.plist`:
  - `NSFaceIDUsageDescription = O HAMVIT usa Face ID para proteger seu acesso e dados sensíveis.`

## Regras de fallback

Se biometria falhar:

- usuário pode tentar novamente
- usuário pode usar senha via fluxo de login
- app não bloqueia permanentemente

## Observações

Biometria é desbloqueio local da sessão já autenticada.
Supabase Auth continua como autenticação principal.