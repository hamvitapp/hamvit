import 'package:flutter/material.dart';

import '../../shared/widgets/hamvit_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        HamvitHeader(title: 'Configurações', subtitle: 'Conta, notificações, privacidade e dados.'),
        SizedBox(height: 12),
        HamvitIconCard(assetPath: 'assets/icons/sono.png', label: 'Privacidade e segurança'),
        SizedBox(height: 8),
        HamvitIconCard(assetPath: 'assets/icons/habitos.png', label: 'Notificações e lembretes'),
      ],
    );
  }
}
