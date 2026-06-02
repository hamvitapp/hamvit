import 'package:flutter/material.dart';

import '../../../../theme/hamvit_colors.dart';
import '../daily_score/hamvit_daily_score_widget.dart';
import '../daily_stats/hamvit_daily_stats_grid.dart';
import 'hamvit_day_completion_bar.dart';

class HamvitHomeDashboardData {
  final int score;
  final String statusText;
  final int waterMl;
  final int waterGoalMl;
  final int calories;
  final int? caloriesGoal;
  final int habitsDone;
  final int habitsTotal;
  final int? steps;
  final double distanceKm;
  final int activeMinutes;
  final int activityCaloriesKcal;
  final Duration? sleepDuration;
  final double? currentWeightKg;
  final double? initialWeightKg;
  final double? targetWeightKg;
  final int dayCompletionPercent;
  final String primaryInsight;
  final String? secondaryInsight;
  final List<double> trend;
  final VoidCallback? onScoreTap;
  final VoidCallback? onWaterTap;
  final VoidCallback? onCaloriesTap;
  final VoidCallback? onHabitsTap;
  final VoidCallback? onActivityTap;
  final VoidCallback? onSleepTap;
  final VoidCallback? onEvolutionTap;

  const HamvitHomeDashboardData({
    required this.score,
    required this.statusText,
    required this.waterMl,
    required this.waterGoalMl,
    required this.calories,
    required this.caloriesGoal,
    required this.habitsDone,
    required this.habitsTotal,
    required this.steps,
    required this.distanceKm,
    required this.activeMinutes,
    required this.activityCaloriesKcal,
    required this.sleepDuration,
    required this.currentWeightKg,
    required this.initialWeightKg,
    required this.targetWeightKg,
    required this.dayCompletionPercent,
    required this.primaryInsight,
    this.secondaryInsight,
    required this.trend,
    this.onScoreTap,
    this.onWaterTap,
    this.onCaloriesTap,
    this.onHabitsTap,
    this.onActivityTap,
    this.onSleepTap,
    this.onEvolutionTap,
  });
}

class HamvitHomeDashboard extends StatelessWidget {
  final HamvitHomeDashboardData data;

  const HamvitHomeDashboard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HamvitColors.primaryNavy.withValues(alpha: 0.98),
            HamvitColors.primaryDark.withValues(alpha: 0.98),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HamvitDailyScoreWidget(score: data.score, statusText: data.statusText, onTap: data.onScoreTap),
          const SizedBox(height: 10),
          HamvitDailyStatsGrid(
            waterMl: data.waterMl,
            waterGoalMl: data.waterGoalMl,
            calories: data.calories,
            caloriesGoal: data.caloriesGoal,
            habitsDone: data.habitsDone,
            habitsTotal: data.habitsTotal,
            steps: data.steps,
            distanceKm: data.distanceKm,
            activeMinutes: data.activeMinutes,
            activityCaloriesKcal: data.activityCaloriesKcal,
            sleepDuration: data.sleepDuration,
            currentWeightKg: data.currentWeightKg,
            initialWeightKg: data.initialWeightKg,
            targetWeightKg: data.targetWeightKg,
            onWaterTap: data.onWaterTap,
            onCaloriesTap: data.onCaloriesTap,
            onHabitsTap: data.onHabitsTap,
            onActivityTap: data.onActivityTap,
            onSleepTap: data.onSleepTap,
            onEvolutionTap: data.onEvolutionTap,
          ),
          const SizedBox(height: 10),
          HamvitDayCompletionBar(percent: data.dayCompletionPercent),
        ],
      ),
    );
  }
}
