import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';
import '../../shared/widgets/hamvit_components.dart';
import 'reports_service.dart';
import 'widgets/hamvit_reports_widgets.dart';

class AnalyticsScreen extends ConsumerWidget {
  final bool isPremium;
  const AnalyticsScreen({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(reportsServiceProvider);
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 28));

    return FutureBuilder<Map<String, dynamic>>(
      future: svc.loadSummary(start: start, end: end),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const HamvitLoading();
        final summary = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const HamvitHeader(title: 'Analytics HAMVIT', subtitle: 'Dashboards avançados para acompanhamento e decisão.'),
            const SizedBox(height: 12),
            HamvitChartCard(
              title: 'Distribuicao de macros',
              child: SizedBox(
                height: 190,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    sections: [
                      PieChartSectionData(value: 38, color: const Color(0xFF72E85A), title: 'P'),
                      PieChartSectionData(value: 42, color: const Color(0xFF00B7D8), title: 'C'),
                      PieChartSectionData(value: 20, color: const Color(0xFF168DFF), title: 'G'),
                    ],
                  ),
                ),
              ),
            ),
            HamvitChartCard(
              title: 'Hábitos concluídos / semana',
              child: SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    barGroups: [
                      for (var i = 0; i < 7; i++)
                        BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: [2, 3, 4, 2, 5, 6, 5][i].toDouble(),
                              width: 16,
                              borderRadius: BorderRadius.circular(10),
                              color: const Color(0xFF00B7D8),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            HamvitChartCard(
              title: 'HAMVIT Score',
              child: HamvitScoreWidget(score: ((summary['hamvit_score'] as num?) ?? 0).toDouble()),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 10),
              const PremiumTeaserCard(feature: HamvitFeature.analyticsAdvanced),
            ],
          ],
        );
      },
    );
  }
}
