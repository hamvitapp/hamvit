import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/widgets/hamvit_settings_components.dart';
import 'privacy_protection_service.dart';

class HamvitPrivacySettingsCard extends ConsumerWidget {
  const HamvitPrivacySettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(privacyProtectionServiceProvider);
    final settings = service.settings;

    return HamvitSettingsSection(
      title: 'Proteção de privacidade',
      subtitle: 'Protege informações sensíveis quando o app estiver aberto.',
      children: [
        HamvitSettingsSwitchTile(
          icon: Icons.screenshot_monitor_outlined,
          title: 'Bloquear capturas em telas sensíveis',
          value: settings.screenshotProtectionEnabled,
          onChanged: (value) {
            service.updateSettings(
              settings.copyWith(screenshotProtectionEnabled: value),
            );
          },
        ),
        HamvitSettingsSwitchTile(
          icon: Icons.app_blocking_outlined,
          title: 'Ocultar app nos aplicativos recentes',
          subtitle: 'Evita preview com dados sensíveis no app switcher.',
          value: settings.hideRecentAppsPreview,
          onChanged: (value) {
            service.updateSettings(
              settings.copyWith(hideRecentAppsPreview: value),
            );
          },
        ),
        HamvitSettingsSwitchTile(
          icon: Icons.blur_on_outlined,
          title: 'Blur automático ao minimizar o app',
          value: settings.appBlurEnabled,
          onChanged: (value) {
            service.updateSettings(
              settings.copyWith(appBlurEnabled: value),
            );
          },
        ),
      ],
    );
  }
}
