import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/hamvit_settings_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HamvitSettingsScreen(
      title: 'Configurações',
      subtitle: 'Ajuste conta, segurança, lembretes, privacidade, acessibilidade e dados.',
      children: [
        HamvitSettingsSection(
          title: 'Módulos de configuração',
          children: [
            HamvitSettingsActionTile(
              icon: Icons.person_outline,
              title: 'Conta',
              subtitle: 'Perfil, plano, saída e exclusão',
              onTap: () => context.push('/settings/account'),
            ),
            HamvitSettingsActionTile(
              icon: Icons.security_outlined,
              title: 'Segurança',
              subtitle: 'Senha, recuperação e sessões',
              onTap: () => context.push('/settings/security'),
            ),
            HamvitSettingsActionTile(
              icon: Icons.notifications_outlined,
              title: 'Notificações',
              subtitle: 'Categorias e horários de lembrete',
              onTap: () => context.push('/settings/notifications'),
            ),
            HamvitSettingsActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacidade',
              subtitle: 'Consentimentos e compartilhamento',
              onTap: () => context.push('/settings/privacy'),
            ),
            HamvitSettingsActionTile(
              icon: Icons.accessibility_new_outlined,
              title: 'Acessibilidade',
              subtitle: 'Leitura, contraste e simplificação',
              onTap: () => context.push('/settings/accessibility'),
            ),
            HamvitSettingsActionTile(
              icon: Icons.file_download_outlined,
              title: 'Dados e exportação',
              subtitle: 'Exportar, sincronizar e solicitações',
              onTap: () => context.push('/settings/data-export'),
            ),
          ],
        ),
      ],
    );
  }
}
