import 'package:flutter/material.dart';

import '../../../theme/hamvit_colors.dart';
import '../domain/dashboard_metrics_service.dart';

class HamvitPeriodSelector extends StatelessWidget {
  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  const HamvitPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final period in DashboardPeriod.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(period.label),
                selected: selected == period,
                onSelected: (_) => onChanged(period),
                selectedColor: HamvitColors.accentCyan.withValues(alpha: 0.22),
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                labelStyle: TextStyle(
                  color: selected == period
                      ? HamvitColors.darkText
                      : HamvitColors.darkTextMuted,
                  fontWeight:
                      selected == period ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
