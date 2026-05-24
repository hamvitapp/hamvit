import 'package:flutter/material.dart';

import '../../../../theme/hamvit_colors.dart';
import 'hamvit_stat_card.dart';

class HamvitDailyStatsGrid extends StatelessWidget {
  final int waterMl;
  final int waterGoalMl;
  final int calories;
  final int caloriesGoal;
  final int habitsDone;
  final int habitsTotal;
  final int steps;
  final double distanceKm;
  final Duration sleepDuration;

  const HamvitDailyStatsGrid({
    super.key,
    required this.waterMl,
    required this.waterGoalMl,
    required this.calories,
    required this.caloriesGoal,
    required this.habitsDone,
    required this.habitsTotal,
    required this.steps,
    required this.distanceKm,
    required this.sleepDuration,
  });

  String _formatLiters(int ml) => '${(ml / 1000).toStringAsFixed(1)}L';

  String _formatSleep(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        HamvitStatCard(
          icon: Icons.water_drop_outlined,
          title: 'Água',
          value: '${_formatLiters(waterMl)} / ${_formatLiters(waterGoalMl)}',
          subtitle: 'Meta diária',
          progress: waterGoalMl == 0 ? 0 : waterMl / waterGoalMl,
          progressGradient: const [HamvitColors.accentCyan, HamvitColors.accentBlue],
        ),
        HamvitStatCard(
          icon: Icons.local_fire_department_outlined,
          title: 'Calorias',
          value: '$calories / $caloriesGoal',
          subtitle: 'Consumo do dia',
          progress: caloriesGoal == 0 ? 0 : calories / caloriesGoal,
          progressGradient: const [HamvitColors.accentMint, HamvitColors.accentGreen],
        ),
        HamvitStatCard(
          icon: Icons.checklist_rounded,
          title: 'Hábitos',
          value: '$habitsDone/$habitsTotal concluídos',
          subtitle: 'Rotina diária',
          progress: habitsTotal == 0 ? 0 : habitsDone / habitsTotal,
          progressGradient: const [HamvitColors.accentGreen, HamvitColors.accentMint],
        ),
        HamvitStatCard(
          icon: Icons.directions_walk_outlined,
          title: 'Passos',
          value: '$steps • ${distanceKm.toStringAsFixed(1)} km',
          subtitle: 'Movimento hoje',
          progress: (distanceKm / 6.0).clamp(0, 1),
          progressGradient: const [HamvitColors.accentBlue, HamvitColors.accentCyan],
        ),
        HamvitStatCard(
          icon: Icons.bedtime_outlined,
          title: 'Sono',
          value: _formatSleep(sleepDuration),
          subtitle: 'Último registro',
          progress: (sleepDuration.inMinutes / (8 * 60)).clamp(0, 1),
          progressGradient: const [HamvitColors.accentBlue, HamvitColors.accentMint],
        ),
      ],
    );
  }
}
