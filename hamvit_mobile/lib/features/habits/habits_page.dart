import 'package:flutter/material.dart';

import '../../shared/widgets/hamvit_components.dart';

class HabitsPage extends StatefulWidget {
  const HabitsPage({super.key});

  @override
  State<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends State<HabitsPage> {
  final Map<String, bool> habits = {
    'Dormir melhor': false,
    'Comer com atenção': false,
    'Beber água': false,
    'Caminhar 20 minutos': false,
  };

  @override
  Widget build(BuildContext context) {
    final done = habits.values.where((e) => e).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HamvitHeader(title: 'Hábitos', subtitle: 'Constância diária: $done/${habits.length} concluídos hoje'),
        const SizedBox(height: 12),
        for (final entry in habits.entries) ...[
          Card(
            child: CheckboxListTile(
              value: entry.value,
              title: Text(entry.key),
              subtitle: const Text('Marque quando concluir este hábito hoje.'),
              onChanged: (v) => setState(() => habits[entry.key] = v ?? false),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
