import 'package:flutter/material.dart';

import '../../shared/widgets/hamvit_components.dart';

class AdminShortcutsPage extends StatelessWidget {
  const AdminShortcutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        HamvitHeader(title: 'Atalhos Admin', subtitle: 'Disponível apenas para perfis autorizados.'),
        SizedBox(height: 12),
        HamvitIconCard(assetPath: 'assets/icons/relatorios.png', label: 'Pagamentos e webhooks'),
        SizedBox(height: 8),
        HamvitIconCard(assetPath: 'assets/icons/alimentacao.png', label: 'Receitas e alimentos'),
        SizedBox(height: 8),
        HamvitIconCard(assetPath: 'assets/icons/bem_estar.png', label: 'Suporte e falhas de IA'),
      ],
    );
  }
}
