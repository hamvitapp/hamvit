import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/providers/onboarding_profile_provider.dart';
import '../../features/activities/providers/activity_refresh_provider.dart';
import '../../features/activities/providers/activity_live_provider.dart';
import 'domain/home_dashboard_model.dart';
import 'providers/home_dashboard_provider.dart';
import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../../theme/hamvit_colors.dart';
import 'widgets/home_dashboard/hamvit_home_dashboard.dart';
import 'widgets/insights/hamvit_insight_card.dart';

class TodayPage extends ConsumerStatefulWidget {
  final bool isPremium;
  const TodayPage({super.key, required this.isPremium});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
  int _lastSeenActivityTick = 0;
  @override
  void initState() {
    super.initState();
  }
  Future<void> _refreshDashboard() async {
    ref.invalidate(homeDashboardProvider);
    await ref.read(homeDashboardProvider.future);
  }

  Future<void> _navigateAndRefresh(String route) async {
    await context.push(route);
    if (!mounted) return;
    await _refreshDashboard();
  }

  HamvitHomeDashboardData _mapDashboardData(HomeDashboardModel model) {
    return HamvitHomeDashboardData(
      score: model.score,
      statusText: model.statusText,
      waterMl: model.waterMl,
      waterGoalMl: model.waterGoalMl,
      calories: model.calories,
      caloriesGoal: model.caloriesGoal,
      habitsDone: model.habitsDone,
      habitsTotal: model.habitsTotal,
      steps: model.stepsToday,
      distanceKm: model.distanceKm,
      activityCaloriesKcal: model.activityCaloriesKcal,
      sleepDuration: model.sleepHours == null
          ? null
          : Duration(minutes: (model.sleepHours! * 60).round()),
      currentWeightKg: null,
      targetWeightKg: null,
      dayCompletionPercent: model.dayCompletionPercent,
      primaryInsight: model.primaryInsight,
      secondaryInsight: model.secondaryInsight,
      trend: model.trend,
      onScoreTap: () => _navigateAndRefresh('/reports/daily'),
      onWaterTap: () => _navigateAndRefresh('/hydration'),
      onCaloriesTap: () => _navigateAndRefresh('/nutrition'),
      onHabitsTap: () => _navigateAndRefresh('/habits'),
      onActivityTap: () => _navigateAndRefresh('/activities'),
      onSleepTap: () => _navigateAndRefresh('/sleep'),
      onEvolutionTap: () => _navigateAndRefresh('/progress'),
    );
  }

  Widget _loadingState() {
    Widget skeletonBox({required double height}) {
      return Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          skeletonBox(height: 126),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: List.generate(4, (_) => skeletonBox(height: 82)),
          ),
          const SizedBox(height: 10),
          skeletonBox(height: 44),
        ],
      ),
    );
  }

  Widget _errorState(Object error) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Falha ao carregar dashboard real',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '$error',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: HamvitColors.darkTextMuted),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: _refreshDashboard,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Observe global activity tick and invalidate dashboard when it increments.
    final tick = ref.watch(activityRefreshTickProvider);
    if (tick != _lastSeenActivityTick) {
      _lastSeenActivityTick = tick;
      debugPrint('TodayPage: activity tick changed to $tick, invalidating dashboard');
      ref.invalidate(homeDashboardProvider);
    }
    final onboarding = ref.watch(onboardingProfileProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final live = ref.watch(activityLiveStateProvider);
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    const bottomNavHeight = kBottomNavigationBarHeight;
    final bottomContentPadding = bottomSafeArea + bottomNavHeight + 24;

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: ListView(
        padding: EdgeInsets.fromLTRB(10, 12, 10, bottomContentPadding),
        children: [
          SizedBox(
            height: 120,
            width: double.infinity,
            child: Image.asset(
              'assets/branding/hamvit_hoje_exata.png',
              fit: BoxFit.fitWidth,
              alignment: Alignment.center,
            ),
          ),
          const SizedBox(height: 8),
          if (onboarding.completionPercent < 60) ...[
            HamvitProfileCompletionCard(
              percent: onboarding.completionPercent,
              onContinue: () => context.push('/onboarding/goal'),
            ),
            const SizedBox(height: 10),
          ],
          dashboardAsync.when(
            loading: _loadingState,
            error: (error, _) => _errorState(error),
            data: (model) {
                final dashboard = _mapDashboardData(model);
                // merge live activity overlay if disponível
                final adjustedDashboard = live != null
                  ? HamvitHomeDashboardData(
                    score: dashboard.score,
                    statusText: dashboard.statusText,
                    waterMl: dashboard.waterMl,
                    waterGoalMl: dashboard.waterGoalMl,
                    calories: dashboard.calories,
                    caloriesGoal: dashboard.caloriesGoal,
                    habitsDone: dashboard.habitsDone,
                    habitsTotal: dashboard.habitsTotal,
                    steps: dashboard.steps,
                    distanceKm: dashboard.distanceKm + live.distanceKm,
                    activityCaloriesKcal:
                      dashboard.activityCaloriesKcal + live.caloriesKcal,
                    sleepDuration: dashboard.sleepDuration,
                    currentWeightKg: onboarding.weightKg,
                    targetWeightKg: onboarding.targetWeightKg,
                    dayCompletionPercent: dashboard.dayCompletionPercent,
                    primaryInsight: dashboard.primaryInsight,
                    secondaryInsight: dashboard.secondaryInsight,
                    trend: dashboard.trend,
                    onScoreTap: dashboard.onScoreTap,
                    onWaterTap: dashboard.onWaterTap,
                    onCaloriesTap: dashboard.onCaloriesTap,
                    onHabitsTap: dashboard.onHabitsTap,
                    onActivityTap: dashboard.onActivityTap,
                    onSleepTap: dashboard.onSleepTap,
                    onEvolutionTap: dashboard.onEvolutionTap,
                  )
                  : HamvitHomeDashboardData(
                    score: dashboard.score,
                    statusText: dashboard.statusText,
                    waterMl: dashboard.waterMl,
                    waterGoalMl: dashboard.waterGoalMl,
                    calories: dashboard.calories,
                    caloriesGoal: dashboard.caloriesGoal,
                    habitsDone: dashboard.habitsDone,
                    habitsTotal: dashboard.habitsTotal,
                    steps: dashboard.steps,
                    distanceKm: dashboard.distanceKm,
                    activityCaloriesKcal: dashboard.activityCaloriesKcal,
                    sleepDuration: dashboard.sleepDuration,
                    currentWeightKg: onboarding.weightKg,
                    targetWeightKg: onboarding.targetWeightKg,
                    dayCompletionPercent: dashboard.dayCompletionPercent,
                    primaryInsight: dashboard.primaryInsight,
                    secondaryInsight: dashboard.secondaryInsight,
                    trend: dashboard.trend,
                    onScoreTap: dashboard.onScoreTap,
                    onWaterTap: dashboard.onWaterTap,
                    onCaloriesTap: dashboard.onCaloriesTap,
                    onHabitsTap: dashboard.onHabitsTap,
                    onActivityTap: dashboard.onActivityTap,
                    onSleepTap: dashboard.onSleepTap,
                    onEvolutionTap: dashboard.onEvolutionTap,
                  );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (model.isOffline || model.warningMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        model.warningMessage ??
                            'Modo offline ativo. Dados em cache local.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: HamvitColors.darkText),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  HamvitHomeDashboard(data: adjustedDashboard),
                  if (model.isEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: HamvitColors.darkCard.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        'Ainda não há registros reais hoje. Use os módulos abaixo para iniciar seu dia.',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: HamvitColors.darkTextMuted),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  HamvitInsightCard(
                    primaryInsight: adjustedDashboard.primaryInsight,
                    secondaryInsight: adjustedDashboard.secondaryInsight,
                    trend: adjustedDashboard.trend,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
