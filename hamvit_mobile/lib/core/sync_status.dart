import 'package:flutter/material.dart';

enum SyncStatus { pending, synced, failed, conflict }

class SyncBadge extends StatelessWidget {
  final SyncStatus status;
  const SyncBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (text, color) = switch (status) {
      SyncStatus.pending => ('Pendente', Colors.orange),
      SyncStatus.synced => ('Sincronizado', Colors.green),
      SyncStatus.failed => ('Falhou', Colors.red),
      SyncStatus.conflict => ('Conflito', Colors.deepOrange),
    };
    return Chip(label: Text(text), backgroundColor: color.withValues(alpha: 0.15));
  }
}


