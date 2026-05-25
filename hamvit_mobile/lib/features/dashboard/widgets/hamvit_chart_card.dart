import 'package:flutter/material.dart';

import '../../../theme/hamvit_colors.dart';
import '../domain/dashboard_metrics_service.dart';
import 'hamvit_chart_header.dart';
import 'hamvit_chart_insight.dart';
import 'hamvit_line_chart.dart';

class HamvitChartCard extends StatelessWidget {
  final DashboardMetricData metric;
  final Color color;
  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  const HamvitChartCard({
    super.key,
    required this.metric,
    required this.color,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HamvitColors.darkCard.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HamvitChartHeader(
            title: metric.title,
            subtitle: metric.subtitle,
            period: period,
            onPeriodChanged: onPeriodChanged,
          ),
          const SizedBox(height: 10),
          HamvitLineChart(
            points: metric.points,
            goal: metric.goal,
            color: color,
            unit: metric.unit,
            emptyMessage: metric.emptyMessage,
          ),
          HamvitChartInsight(text: metric.insight),
          const SizedBox(height: 6),
          Text(
            metric.summary,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HamvitColors.darkTextMuted,
                ),
          ),
        ],
      ),
    );
  }
}
