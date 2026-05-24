import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';
import '../../shared/widgets/hamvit_components.dart';
import 'reports_service.dart';
import 'widgets/hamvit_reports_widgets.dart';

class ReportsPage extends ConsumerStatefulWidget {
  final bool isPremium;
  const ReportsPage({super.key, required this.isPremium});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  @override
  Widget build(BuildContext context) {
    final svc = ref.watch(reportsServiceProvider);
    final onboarding = ref.watch(onboardingProfileProvider);
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 7));

    return FutureBuilder<Map<String, dynamic>>(
      future: svc.loadSummary(start: start, end: end),
      builder: (context, summarySnapshot) {
        if (!summarySnapshot.hasData) return const HamvitLoading();
        final summary = summarySnapshot.data!;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: svc.loadHeatmap(start: start, end: end),
          builder: (context, heatmapSnapshot) {
            final heatValues = heatmapSnapshot.hasData
                ? heatmapSnapshot.data!
                    .map((e) => (e['score'] as num?)?.toInt() ?? 0)
                    .toList()
                : List<int>.filled(7, 0);

            final insights = svc.buildDeterministicInsights(summary);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const HamvitHeader(title: 'Relatórios HAMVIT', subtitle: 'Evolução clara, sem poluição visual e com foco em constância.'),
                if (!onboarding.essentialCompleted) ...[
                  const SizedBox(height: 10),
                  const HamvitCard(
                    child: Text('Complete seu perfil para relatórios mais precisos.'),
                  ),
                ],
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.18,
                  children: [
                    HamvitAnalyticsCard(
                      title: 'Calorias',
                      value: '${(summary['calories_total'] as num?)?.toStringAsFixed(0) ?? '0'} kcal',
                      icon: Icons.local_fire_department_outlined,
                    ),
                    HamvitAnalyticsCard(
                      title: 'Proteina',
                      value: '${(summary['protein_total'] as num?)?.toStringAsFixed(0) ?? '0'} g',
                      icon: Icons.fitness_center_outlined,
                    ),
                    HamvitAnalyticsCard(
                      title: 'Água',
                      value: '${(summary['water_total_ml'] as num?)?.toStringAsFixed(0) ?? '0'} ml',
                      icon: Icons.water_drop_outlined,
                    ),
                    HamvitAnalyticsCard(
                      title: 'Score',
                      value: (summary['hamvit_score'] as num?)?.toStringAsFixed(0) ?? '0',
                      icon: Icons.insights_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                HamvitChartCard(
                  title: 'Evolução semanal',
                  subtitle: 'Peso, adesão e constância em leitura rápida.',
                  child: SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: true,
                            color: const Color(0xFF00B7D8),
                            dotData: const FlDotData(show: false),
                            barWidth: 3,
                            spots: const [
                              FlSpot(0, 50),
                              FlSpot(1, 58),
                              FlSpot(2, 55),
                              FlSpot(3, 62),
                              FlSpot(4, 68),
                              FlSpot(5, 72),
                              FlSpot(6, 79),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                HamvitChartCard(
                  title: 'Constancia (heatmap)',
                  child: HamvitHeatmap(values: heatValues),
                ),
                HamvitChartCard(
                  title: 'HAMVIT Score',
                  child: HamvitScoreWidget(score: ((summary['hamvit_score'] as num?) ?? 0).toDouble()),
                ),
                const SizedBox(height: 8),
                ...insights.map(
                  (i) => HamvitInsightCard(
                    title: i['title'] ?? '',
                    body: i['body'] ?? '',
                    severity: i['severity'] ?? 'info',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(onPressed: () => context.go('/reports/weekly'), child: const Text('Semanal')),
                    OutlinedButton(onPressed: () => context.go('/reports/monthly'), child: const Text('Mensal')),
                    OutlinedButton(onPressed: () => context.go('/reports/professional'), child: const Text('Profissional')),
                    FilledButton(
                      onPressed: () {
                        if (PremiumAccessMatrix.isAllowed(HamvitFeature.reportsPdfExport, isPremium: widget.isPremium)) {
                          context.go('/reports/pdf');
                          return;
                        }
                        showModalBottomSheet(
                          context: context,
                          useSafeArea: true,
                          builder: (_) => const PremiumUpsellSheet(feature: HamvitFeature.reportsPdfExport),
                        );
                      },
                      child: const Text('PDF'),
                    ),
                    FilledButton(onPressed: () => context.go('/analytics'), child: const Text('Analytics')),
                  ],
                ),
                if (!widget.isPremium) ...[
                  const SizedBox(height: 12),
                  const PremiumTeaserCard(feature: HamvitFeature.reportsPdfExport),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

