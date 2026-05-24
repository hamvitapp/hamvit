import 'package:flutter/material.dart';

import '../../shared/widgets/hamvit_components.dart';

class HydrationPage extends StatefulWidget {
  const HydrationPage({super.key});

  @override
  State<HydrationPage> createState() => _HydrationPageState();
}

class _HydrationPageState extends State<HydrationPage> {
  int consumedMl = 0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const HamvitHeader(title: 'Hidratação', subtitle: 'Meta sugerida: 30-35 ml por kg/dia.'),
        const SizedBox(height: 12),
        HamvitCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Consumo de hoje: $consumedMl ml', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => consumedMl += 250), child: const Text('+250 ml'))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(onPressed: () => setState(() => consumedMl += 500), child: const Text('+500 ml'))),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

