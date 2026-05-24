import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/hamvit_components.dart';
import 'reports_service.dart';
import 'widgets/hamvit_reports_widgets.dart';

class ReportsPeriodScreen extends ConsumerWidget {
  final String reportType;
  final bool isPremium;

  const ReportsPeriodScreen({super.key, required this.reportType, required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.watch(reportsServiceProvider);
    final end = DateTime.now();
    final start = switch (reportType) {
      'daily' => end.subtract(const Duration(days: 1)),
      'monthly' => end.subtract(const Duration(days: 30)),
      'professional' => end.subtract(const Duration(days: 30)),
      _ => end.subtract(const Duration(days: 7)),
    };

    return FutureBuilder<Map<String, dynamic>>(
      future: svc.loadSummary(start: start, end: end),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const HamvitLoading();
        final summary = snapshot.data!;
        final score = ((summary['hamvit_score'] as num?) ?? 0).toDouble();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            HamvitHeader(
              title: 'Relatório ${reportType.toUpperCase()}',
              subtitle: isPremium
                  ? 'Comparativos e analytics do período.'
                  : 'Visão simplificada para plano Free.',
            ),
            const SizedBox(height: 12),
            HamvitScoreWidget(score: score),
            const SizedBox(height: 12),
            HamvitChartCard(
              title: 'Evolução de aderência',
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
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        spots: const [
                          FlSpot(0, 42),
                          FlSpot(1, 50),
                          FlSpot(2, 58),
                          FlSpot(3, 62),
                          FlSpot(4, 70),
                          FlSpot(5, 76),
                          FlSpot(6, 80),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Comparativos avançados e histórico completo são exclusivos do Premium.'),
              ),
            ],
          ],
        );
      },
    );
  }
}
