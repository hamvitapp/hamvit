# HAMVIT Settings Module

## Rotas implementadas

- /settings/account
- /settings/security
- /settings/notifications
- /settings/privacy
- /settings/accessibility
- /settings/data-export

## Navegação pelo drawer

A categoria Configurações do menu lateral agora abre rotas reais, sem placeholder:

- Conta -> /settings/account
- Segurança -> /settings/security
- Notificações -> /settings/notifications
- Privacidade -> /settings/privacy
- Acessibilidade -> /settings/accessibility
- Dados e exportação -> /settings/data-export

## Componentes reutilizáveis

Arquivo: lib/features/settings/widgets/hamvit_settings_components.dart

- HamvitSettingsScreen
- HamvitSettingsSection
- HamvitSettingsTile
- HamvitSettingsSwitchTile
- HamvitSettingsActionTile
- HamvitSettingsInfoCard
- HamvitDangerZoneCard

## Camada de dados

Arquivo: lib/features/settings/data/settings_repository.dart

Cobertura principal:

- leitura de dados da conta (perfil, plano, objetivo)
- alteração de nome
- atualização e recuperação de senha
- encerramento de sessão
- preferências de notificação e horários
- consentimento de IA de foto de comida
- preferências de acessibilidade
- solicitações de exportação e exclusão
- auditoria básica em audit_logs

## Providers

- lib/features/settings/providers/settings_provider.dart
- lib/features/settings/providers/notification_preferences_provider.dart
- lib/features/settings/providers/accessibility_preferences_provider.dart

## Banco e RLS

Migration criada:

- supabase/migrations/20260524000017_settings_module.sql

Inclui:

- evolução de notification_preferences para formato estruturado
- tabela user_consents
- tabela data_export_requests
- tabela account_deletion_requests
- novos campos de acessibilidade em user_preferences
- políticas RLS de leitura/criação/atualização por usuário
- políticas de service_role para processamento sensível

## Estado atual

O módulo está funcional e integrado ao app com telas reais, ações com feedback e confirmações para operações sensíveis.
