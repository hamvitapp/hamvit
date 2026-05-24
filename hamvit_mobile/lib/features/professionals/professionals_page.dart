import 'package:flutter/material.dart';

import '../../shared/widgets/hamvit_components.dart';

class ProfessionalsPage extends StatelessWidget {
  const ProfessionalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        HamvitHeader(title: 'Área Profissional', subtitle: 'Vínculo com paciente, cupons e relatórios.'),
        SizedBox(height: 12),
        HamvitIconCard(assetPath: 'assets/icons/metas.png', label: 'Cupom profissional', subtitle: 'Aplicação de desconto ao paciente e rastreio de vínculo.'),
        SizedBox(height: 8),
        HamvitIconCard(assetPath: 'assets/icons/bem_estar.png', label: 'Pacientes vinculados', subtitle: 'Acesso apenas com autorização explícita.'),
        SizedBox(height: 8),
        HamvitIconCard(assetPath: 'assets/icons/progresso.png', label: 'Comissões', subtitle: 'Registro transparente para conciliação financeira.'),
      ],
    );
  }
}

