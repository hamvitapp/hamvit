import 'package:flutter/material.dart';

import '../../../../theme/hamvit_colors.dart';
import 'hamvit_sparkline_chart.dart';

class HamvitInsightCard extends StatelessWidget {
  final String primaryInsight;
  final String? secondaryInsight;
  final List<double> trend;

  const HamvitInsightCard({
    super.key,
    required this.primaryInsight,
    this.secondaryInsight,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HamvitColors.darkCard.withValues(alpha: 0.95),
            HamvitColors.primaryNavy.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: HamvitColors.accentMint, size: 18),
              const SizedBox(width: 6),
              Text(
                'Insights inteligentes',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            primaryInsight,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: HamvitColors.darkText,
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (secondaryInsight != null) ...[
            const SizedBox(height: 6),
            Text(
              secondaryInsight!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: HamvitColors.darkTextMuted),
            ),
          ],
          const SizedBox(height: 10),
          HamvitSparklineChart(points: trend),
        ],
      ),
    );
  }
}
