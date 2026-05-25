import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

HorizontalLine? buildHamvitGoalLine(double? goal, Color color) {
  if (goal == null || goal <= 0) return null;
  return HorizontalLine(
    y: goal,
    color: color.withValues(alpha: 0.5),
    strokeWidth: 1.2,
    dashArray: [8, 6],
    label: HorizontalLineLabel(
      show: true,
      alignment: Alignment.topRight,
      style: TextStyle(
        color: color.withValues(alpha: 0.9),
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      labelResolver: (_) => 'Meta',
    ),
  );
}
