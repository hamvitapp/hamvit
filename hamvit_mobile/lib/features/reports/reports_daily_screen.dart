import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/providers/home_dashboard_provider.dart';
import '../../theme/hamvit_colors.dart';

class ReportsDailyScreen extends ConsumerWidget {
  const ReportsDailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(homeDashboardProvider);

    return dashboard.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Falha ao carregar relatorio diario: $error'),
        ),
      ),
      data: (data) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Resumo diario HAMVIT',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            _DailyLine(label: 'Score', value: '${data.score}%'),
            _DailyLine(label: 'Agua', value: '${data.waterMl} ml / ${data.waterGoalMl} ml'),
            _DailyLine(
              label: 'Calorias',
              value: data.caloriesGoal == null
                  ? '${data.calories} kcal (meta pendente)'
                  : '${data.calories} kcal / ${data.caloriesGoal} kcal',
            ),
            _DailyLine(label: 'Habitos', value: '${data.habitsDone} de ${data.habitsTotal} concluidos'),
            _DailyLine(label: 'Atividade', value: '${data.distanceKm.toStringAsFixed(2)} km e ${data.activeMinutes} min'),
            _DailyLine(
              label: 'Sono',
              value: data.sleepHours == null ? 'Sem registro' : '${data.sleepHours!.toStringAsFixed(1)} h',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HamvitColors.darkCard.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                data.statusText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HamvitColors.darkText),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DailyLine extends StatelessWidget {
  final String label;
  final String value;

  const _DailyLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: HamvitColors.darkTextMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
