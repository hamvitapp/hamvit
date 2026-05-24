import 'package:flutter/material.dart';

import '../../shared/widgets/hamvit_components.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final weightCtrl = TextEditingController();
  final heightCtrl = TextEditingController(text: '170');
  String result = '';

  void _calculateImc() {
    final w = double.tryParse(weightCtrl.text.replaceAll(',', '.'));
    final hCm = double.tryParse(heightCtrl.text.replaceAll(',', '.'));
    if (w == null || hCm == null || hCm <= 0) return;
    final h = hCm / 100;
    final imc = w / (h * h);
    setState(() => result = 'IMC estimado: ${imc.toStringAsFixed(1)}');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HamvitHeader(title: 'Evolução', subtitle: 'Peso, medidas e consistência com visão de longo prazo.'),
        const SizedBox(height: 12),
        HamvitCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IMC', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              HamvitTextField(controller: weightCtrl, label: 'Peso (kg)', keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              HamvitTextField(controller: heightCtrl, label: 'Altura (cm)', keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              HamvitButton(label: 'Calcular', onPressed: _calculateImc),
              if (result.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(result),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        const HamvitIconCard(
          assetPath: 'assets/icons/progresso.png',
          label: 'Fotos corporais',
          subtitle: 'Acompanhe mudanças com perspectiva acolhedora e sem comparações extremas.',
        ),
      ],
    );
  }
}

