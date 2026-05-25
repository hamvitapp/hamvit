import 'package:flutter/material.dart';

import 'report_repository.dart';

class HamvitReportPeriodSelector extends StatelessWidget {
  final ReportPeriodType selected;
  final ValueChanged<ReportPeriodType> onChanged;

  const HamvitReportPeriodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ReportPeriodType.values.map((period) {
        final active = selected == period;
        return ChoiceChip(
          label: Text(period.label),
          selected: active,
          onSelected: (_) => onChanged(period),
        );
      }).toList(growable: false),
    );
  }
}
