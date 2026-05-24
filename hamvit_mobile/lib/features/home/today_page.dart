import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/onboarding/providers/onboarding_profile_provider.dart';
import '../meal_recommendations/meal_recommendations_page.dart';
import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../../theme/hamvit_colors.dart';
import 'widgets/daily_stats/hamvit_mini_progress_bar.dart';
import 'widgets/home_dashboard/hamvit_home_dashboard.dart';
import 'widgets/insights/hamvit_insight_card.dart';
import 'widgets/quick_actions/hamvit_quick_actions_row.dart';

class TodayPage extends ConsumerWidget {
  final bool isPremium;
  const TodayPage({super.key, required this.isPremium});

  HamvitHomeDashboardData _buildDashboardData(OnboardingProfileState onboarding) {
    final completion = onboarding.completionPercent;
    final hydrationGoal = onboarding.hydrationGoalMl ?? 2500;
    final hydrationPercent = (0.42 + (completion / 200)).clamp(0.25, 0.95);
    final waterMl = (hydrationGoal * hydrationPercent).round();

    final caloriesGoal = switch ((onboarding.objective ?? '').toLowerCase()) {
      'emagrecer' => 2100,
      'ganhar massa muscular' => 2500,
      _ => 2300,
    };
    final calories = (caloriesGoal * (0.48 + completion / 250)).round();

    const habitsTotal = 6;
    final habitsDone = ((completion / 100) * habitsTotal).round().clamp(1, habitsTotal);

    final baseDistance = switch ((onboarding.activityLevel ?? '').toLowerCase()) {
      'sedentaria' => 1.8,
      'leve' => 2.9,
      'moderada' => 3.8,
      'alta' => 5.2,
      _ => 3.2,
    };
    final distanceKm = (baseDistance + completion / 180).clamp(1.2, 6.8);
    final steps = (distanceKm * 1400).round();

    final sleepHours = onboarding.sleepHours ?? 6.7;
    final sleep = Duration(minutes: (sleepHours * 60).round());

    final waterProgress = waterMl / hydrationGoal;
    final caloriesProgress = calories / caloriesGoal;
    final habitsProgress = habitsDone / habitsTotal;
    final activityProgress = (distanceKm / 6.0).clamp(0.0, 1.0);
    final consistencyProgress = (completion / 100).clamp(0.0, 1.0);

    final score = ((waterProgress * 0.2) +
            (caloriesProgress.clamp(0.0, 1.0) * 0.2) +
            (habitsProgress * 0.22) +
            (activityProgress * 0.2) +
            (consistencyProgress * 0.18)) *
        100;

    final scorePercent = score.round().clamp(35, 96);
    final status = switch (scorePercent) {
      >= 82 => 'Ritmo excelente hoje, com equilíbrio e constância.',
      >= 70 => 'Boa constância hoje. Seu dia está evoluindo bem.',
      >= 55 => 'Bom começo de dia. Pequenos passos já contam.',
      _ => 'Dia em construção. Um registro agora já melhora seu score.',
    };

    final primaryInsight = waterProgress >= 0.7
        ? 'Ótimo progresso na hidratação. Você está mais consistente que semana passada.'
        : 'Seu dia está ganhando ritmo. Mais um registro de água melhora sua constância.';

    final secondaryInsight = habitsDone >= 4
        ? 'Hábitos em boa sequência hoje. Continue no seu ritmo.'
        : 'Ative um hábito rápido agora para subir seu score diário.';

    final trend = [42, 51, 58, 63, 67, scorePercent - 4, scorePercent.toDouble()];

    return HamvitHomeDashboardData(
      score: scorePercent,
      statusText: status,
      waterMl: waterMl,
      waterGoalMl: hydrationGoal,
      calories: calories,
      caloriesGoal: caloriesGoal,
      habitsDone: habitsDone,
      habitsTotal: habitsTotal,
      steps: steps,
      distanceKm: distanceKm,
      sleepDuration: sleep,
      dayCompletionPercent: ((completion * 0.45) + (scorePercent * 0.55)).round().clamp(30, 98),
      primaryInsight: primaryInsight,
      secondaryInsight: secondaryInsight,
      trend: trend.map((e) => e.toDouble()).toList(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProfileProvider);
    final dashboard = _buildDashboardData(onboarding);

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 4, 10, 10),
      children: [
        SizedBox(
          height: 90,
          width: double.infinity,
          child: Image.asset(
            'assets/branding/hamvit_hoje_exata.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        const SizedBox(height: 8),
        if (onboarding.completionPercent < 60) ...[
          HamvitProfileCompletionCard(
            percent: onboarding.completionPercent,
            onContinue: () => context.go('/onboarding/general'),
          ),
          const SizedBox(height: 10),
        ],
        HamvitHomeDashboard(data: dashboard),
        const SizedBox(height: 10),
        HamvitQuickActionsRow(
          onWater: () => context.go('/onboarding/hydration'),
          onMeal: () => context.go('/nutrition'),
          onWalk: () => context.go('/activities'),
          onHabit: () => context.go('/habits'),
        ),
        const SizedBox(height: 10),
        Text(
          'Módulos principais',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HamvitColors.darkText,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.08,
          children: [
            _HomeModuleCard(
              title: 'Hábitos',
              subtitle: '${dashboard.habitsDone} de ${dashboard.habitsTotal} concluídos hoje',
              icon: Icons.checklist_rounded,
              progress: dashboard.habitsDone / dashboard.habitsTotal,
              onTap: () => context.go('/habits'),
            ),
            _HomeModuleCard(
              title: 'Água',
              subtitle: '${((dashboard.waterMl / dashboard.waterGoalMl) * 100).round()}% da meta diária',
              icon: Icons.water_drop_outlined,
              progress: dashboard.waterMl / dashboard.waterGoalMl,
              onTap: () => context.go('/onboarding/hydration'),
            ),
            _HomeModuleCard(
              title: 'Alimentação',
              subtitle: '${dashboard.calories} kcal registradas',
              icon: Icons.restaurant_menu_outlined,
              progress: dashboard.calories / dashboard.caloriesGoal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Sugestões Premium')),
                      body: MealRecommendationsPage(isPremium: isPremium),
                    ),
                  ),
                );
              },
            ),
            _HomeModuleCard(
              title: 'Atividades',
              subtitle: '${dashboard.distanceKm.toStringAsFixed(1)} km esta semana',
              icon: Icons.directions_walk_outlined,
              progress: (dashboard.distanceKm / 6.0).clamp(0.0, 1.0),
              onTap: () => context.go('/activities'),
            ),
            _HomeModuleCard(
              title: 'Evolução',
              subtitle: 'Peso estável nos últimos 7 dias',
              icon: Icons.trending_up_rounded,
              progress: (dashboard.score / 100).clamp(0.0, 1.0),
              onTap: () => context.go('/progress'),
            ),
            _HomeModuleCard(
              title: 'Perfil',
              subtitle: 'Dados essenciais ${onboarding.essentialCompleted ? 'completos' : 'em progresso'}',
              icon: Icons.account_circle_outlined,
              progress: (onboarding.completionPercent / 100).clamp(0.0, 1.0),
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        HamvitInsightCard(
          primaryInsight: dashboard.primaryInsight,
          secondaryInsight: dashboard.secondaryInsight,
          trend: dashboard.trend,
        ),
      ],
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HamvitColors.darkTextMuted),
            ),
            const Spacer(),
            HamvitMiniProgressBar(value: progress),
          ],
        ),
      ),
    );
  }
}

