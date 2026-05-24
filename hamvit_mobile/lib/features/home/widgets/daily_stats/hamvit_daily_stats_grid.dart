import 'package:flutter/material.dart';

import '../../../../theme/hamvit_colors.dart';
import 'hamvit_stat_card.dart';

class HamvitDailyStatsGrid extends StatelessWidget {
  final int waterMl;
  final int waterGoalMl;
  final int calories;
  final int? caloriesGoal;
  final int habitsDone;
  final int habitsTotal;
  final int? steps;
  final double distanceKm;
  final Duration? sleepDuration;
  final VoidCallback? onWaterTap;
  final VoidCallback? onCaloriesTap;
  final VoidCallback? onHabitsTap;
  final VoidCallback? onActivityTap;
  final VoidCallback? onSleepTap;

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
    this.onWaterTap,
    this.onCaloriesTap,
    this.onHabitsTap,
    this.onActivityTap,
    this.onSleepTap,
  });

  String _formatLiters(int ml) => '${(ml / 1000).toStringAsFixed(1)}L';

  String _formatSleep(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final waterProgress =
        waterGoalMl == 0 ? 0.0 : (waterMl / waterGoalMl).clamp(0.0, 1.0);
    final caloriesRawProgress = (caloriesGoal == null || caloriesGoal == 0)
        ? 0.0
        : calories / caloriesGoal!;
    final caloriesProgress = caloriesRawProgress.clamp(0.0, 1.0);
    final caloriesOverTarget =
        (caloriesGoal != null && caloriesGoal! > 0) && calories > caloriesGoal!;
    final habitsProgress =
        habitsTotal == 0 ? 0.0 : (habitsDone / habitsTotal).clamp(0.0, 1.0);
    final activityProgress = (distanceKm / 3.0).clamp(0.0, 1.0);
    final sleepProgress = sleepDuration == null
        ? 0.0
        : (sleepDuration!.inMinutes / (8 * 60)).clamp(0.0, 1.0);

    final screenWidth = MediaQuery.of(context).size.width;
    final cardExtent = screenWidth < 360 ? 188.0 : 172.0;

    final cards = [
      HamvitStatCard(
        icon: Icons.water_drop_outlined,
        title: 'Água',
        value: '${_formatLiters(waterMl)} / ${_formatLiters(waterGoalMl)}',
        subtitle: 'Meta diária',
        progress: waterProgress,
        progressGradient: const [
          HamvitColors.accentCyan,
          HamvitColors.accentBlue
        ],
        progressLabel: '${(waterProgress * 100).round()}%',
        footerNote:
            waterMl == 0 ? '0% • Registre seu primeiro consumo hoje' : null,
        onTap: onWaterTap,
      ),
      HamvitStatCard(
        icon: Icons.local_fire_department_outlined,
        title: 'Calorias',
        value: caloriesGoal == null
            ? '$calories kcal'
            : '$calories / $caloriesGoal',
        subtitle: caloriesGoal == null ? 'Meta pendente' : 'Consumo do dia',
        progress: caloriesProgress,
        progressGradient: const [
          HamvitColors.accentCyan,
          HamvitColors.accentBlue
        ],
        progressLabel: '${(caloriesProgress * 100).round()}%',
        footerNote: caloriesGoal == null
            ? 'Meta pendente'
            : (caloriesOverTarget ? 'Levemente acima da meta hoje' : null),
        onTap: onCaloriesTap,
      ),
      HamvitStatCard(
        icon: Icons.checklist_rounded,
        title: 'Hábitos',
        value: '$habitsDone/$habitsTotal concluídos',
        subtitle: 'Rotina diária',
        progress: habitsProgress,
        progressGradient: const [
          HamvitColors.accentCyan,
          HamvitColors.accentBlue
        ],
        progressLabel: '${(habitsProgress * 100).round()}%',
        footerNote: habitsTotal == 0 ? '0% • Nenhum habito ativo hoje' : null,
        onTap: onHabitsTap,
      ),
      HamvitStatCard(
        icon: Icons.directions_walk_outlined,
        title: 'Atividade',
        value: steps == null
            ? '${distanceKm.toStringAsFixed(1)} km'
            : '$steps • ${distanceKm.toStringAsFixed(1)} km',
        subtitle: 'Movimento hoje',
        progress: activityProgress,
        progressGradient: const [
          HamvitColors.accentCyan,
          HamvitColors.accentBlue
        ],
        progressLabel: '${(activityProgress * 100).round()}%',
        footerNote: distanceKm == 0 ? '0% • Inicie uma caminhada' : null,
        onTap: onActivityTap,
      ),
      HamvitStatCard(
        icon: Icons.bedtime_outlined,
        title: 'Sono',
        value: sleepDuration == null
            ? 'Sem registro'
            : _formatSleep(sleepDuration!),
        subtitle:
            sleepDuration == null ? 'Toque para registrar' : 'Último registro',
        progress: sleepProgress,
        progressGradient: const [
          HamvitColors.accentCyan,
          HamvitColors.accentBlue
        ],
        progressLabel: '${(sleepProgress * 100).round()}%',
        footerNote:
            sleepDuration == null ? '0% • Sono ainda nao registrado' : null,
        onTap: onSleepTap,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: cardExtent,
      ),
      itemBuilder: (context, index) => cards[index],
    );
  }
}
