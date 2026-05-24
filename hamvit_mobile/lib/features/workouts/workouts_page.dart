import 'package:flutter/material.dart';

import '../../shared/widgets/hamvit_components.dart';

class WorkoutsPage extends StatelessWidget {
  const WorkoutsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        HamvitHeader(title: 'Treinos', subtitle: 'Progressão segura e foco em regularidade.'),
        SizedBox(height: 12),
        HamvitIconCard(assetPath: 'assets/icons/treinos.png', label: 'Iniciar sessão'),
        SizedBox(height: 8),
        HamvitIconCard(assetPath: 'assets/icons/treinos.png', label: 'Pausar sessão'),
        SizedBox(height: 8),
        HamvitIconCard(assetPath: 'assets/icons/treinos.png', label: 'Finalizar sessão'),
      ],
    );
  }
}

