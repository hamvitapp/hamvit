import 'package:flutter/material.dart';

import '../../../theme/hamvit_colors.dart';
import '../domain/dashboard_metrics_service.dart';
import 'hamvit_period_selector.dart';

class HamvitChartHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final DashboardPeriod period;
  final ValueChanged<DashboardPeriod> onPeriodChanged;

  const HamvitChartHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.period,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HamvitColors.darkText,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HamvitColors.darkTextMuted,
              ),
        ),
        const SizedBox(height: 8),
        HamvitPeriodSelector(
          selected: period,
          onChanged: onPeriodChanged,
        ),
      ],
    );
  }
}
