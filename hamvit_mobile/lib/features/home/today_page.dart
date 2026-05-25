import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/providers/onboarding_profile_provider.dart';
import 'domain/home_dashboard_model.dart';
import 'providers/home_dashboard_provider.dart';
import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../../theme/hamvit_colors.dart';
import 'widgets/daily_stats/hamvit_mini_progress_bar.dart';
import 'widgets/home_dashboard/hamvit_home_dashboard.dart';
import 'widgets/insights/hamvit_insight_card.dart';

class TodayPage extends ConsumerStatefulWidget {
  final bool isPremium;
  const TodayPage({super.key, required this.isPremium});

  @override
  ConsumerState<TodayPage> createState() => _TodayPageState();
}

class _TodayPageState extends ConsumerState<TodayPage> {
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
    final onboarding = ref.watch(onboardingProfileProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);
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
              onContinue: () => context.go('/onboarding/goal'),
            ),
            const SizedBox(height: 10),
          ],
          dashboardAsync.when(
            loading: _loadingState,
            error: (error, _) => _errorState(error),
            data: (model) {
              final dashboard = _mapDashboardData(model);
              final currentWeight = onboarding.weightKg;
              final targetWeight = onboarding.targetWeightKg;
              final hasGoalProgress = currentWeight != null &&
                  targetWeight != null &&
                  currentWeight != targetWeight;
              final safeCurrentWeight = currentWeight ?? 0.0;
              final safeTargetWeight = targetWeight ?? 0.0;

              final evolutionProgress = hasGoalProgress
                  ? (((currentWeight - targetWeight).abs() == 0)
                          ? 1.0
                          : 1 -
                              (((currentWeight - targetWeight).abs() /
                                      (currentWeight).abs())
                                  .clamp(0.0, 1.0)))
                      .clamp(0.0, 1.0)
                  : 0.0;

              final evolutionSubtitle = hasGoalProgress
                  ? 'Atual ${safeCurrentWeight.toStringAsFixed(1)} kg â€¢ alvo ${safeTargetWeight.toStringAsFixed(1)} kg'
                  : 'Acompanhe peso, IMC e historico corporal';

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
                  HamvitHomeDashboard(data: dashboard),
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
                  Text(
                    'Módulos principais',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HamvitColors.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final screenWidth = MediaQuery.of(context).size.width;
                      final moduleCardExtent =
                          screenWidth < 360 ? 170.0 : 156.0;
                      final moduleCards = [
                        _HomeModuleCard(
                          title: 'Hábitos',
                          subtitle:
                              '${dashboard.habitsDone} de ${dashboard.habitsTotal} concluÃ­dos hoje',
                          icon: Icons.checklist_rounded,
                          progress: dashboard.habitsTotal == 0
                              ? 0
                              : dashboard.habitsDone / dashboard.habitsTotal,
                          onTap: () => _navigateAndRefresh('/habits'),
                        ),
                        _HomeModuleCard(
                          title: 'Água',
                          subtitle:
                              '${((dashboard.waterMl / dashboard.waterGoalMl) * 100).round()}% da meta diária',
                          icon: Icons.water_drop_outlined,
                          progress: dashboard.waterMl / dashboard.waterGoalMl,
                          onTap: () => _navigateAndRefresh('/hydration'),
                        ),
                        _HomeModuleCard(
                          title: 'Alimentação',
                          subtitle: dashboard.caloriesGoal == null
                              ? '${dashboard.calories} kcal registradas (meta pendente)'
                              : '${dashboard.calories} kcal registradas',
                          icon: Icons.restaurant_menu_outlined,
                          progress: dashboard.caloriesGoal == null ||
                                  dashboard.caloriesGoal == 0
                              ? 0
                              : dashboard.calories / dashboard.caloriesGoal!,
                          onTap: () => _navigateAndRefresh('/nutrition'),
                        ),
                        _HomeModuleCard(
                          title: 'Atividades',
                          subtitle:
                              '${dashboard.distanceKm.toStringAsFixed(1)} km registrados hoje',
                          icon: Icons.directions_walk_outlined,
                          progress:
                              (dashboard.distanceKm / 3.0).clamp(0.0, 1.0),
                          onTap: () => _navigateAndRefresh('/activities'),
                        ),
                        _HomeModuleCard(
                          title: 'Sono',
                          subtitle: dashboard.sleepDuration == null
                              ? 'Sem registro recente'
                              : 'Último registro ${(dashboard.sleepDuration!.inMinutes / 60).toStringAsFixed(1)}h',
                          icon: Icons.bedtime_outlined,
                          progress: dashboard.sleepDuration == null
                              ? 0
                              : (dashboard.sleepDuration!.inMinutes / (8 * 60))
                                  .clamp(0.0, 1.0),
                          onTap: () => _navigateAndRefresh('/sleep'),
                        ),
                        _HomeModuleCard(
                          title: 'Evolução',
                          subtitle: evolutionSubtitle,
                          icon: Icons.monitor_weight_outlined,
                          progress: evolutionProgress,
                          onTap: () => _navigateAndRefresh('/progress'),
                        ),
                        _HomeModuleCard(
                          title: 'Score diário',
                          subtitle:
                              'Veja detalhes e histÃ³rico do score real de hoje',
                          icon: Icons.insights_outlined,
                          progress: (dashboard.score / 100).clamp(0.0, 1.0),
                          onTap: () => _navigateAndRefresh('/reports/daily'),
                        ),
                      ];

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: moduleCards.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: moduleCardExtent,
                        ),
                        itemBuilder: (context, index) => moduleCards[index],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  HamvitInsightCard(
                    primaryInsight: dashboard.primaryInsight,
                    secondaryInsight: dashboard.secondaryInsight,
                    trend: dashboard.trend,
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

class _HomeModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final double progress;
  final VoidCallback onTap;

  const _HomeModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: HamvitColors.darkCard.withValues(alpha: 0.85),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: HamvitColors.accentCyan, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: HamvitColors.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: HamvitColors.darkTextMuted),
            ),
            const SizedBox(height: 10),
            HamvitMiniProgressBar(value: progress),
          ],
        ),
      ),
    );
  }
}

