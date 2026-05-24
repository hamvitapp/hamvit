import 'package:flutter/material.dart';

import '../../core/hamvit_date_utils.dart';
import 'evolution_models.dart';

class WeightHistoryScreen extends StatelessWidget {
  final List<WeightLogEntry> logs;

  const WeightHistoryScreen({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historico de pesagens')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          final item = logs[index];
          return Card(
            child: ListTile(
              title: Text('${item.weightKg.toStringAsFixed(1)} kg'),
              subtitle: Text(HamvitDateUtils.formatDateBr(item.loggedAt)),
              trailing: Text(item.bmi == null ? '--' : 'IMC ${item.bmi!.toStringAsFixed(1)}'),
            ),
          );
        },
      ),
    );
  }
}