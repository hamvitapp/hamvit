import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/dashboard_metrics_service.dart';

LineTouchTooltipData buildHamvitTooltip({
  required List<DashboardPoint> points,
  required String unit,
  required double? goal,
  required Color color,
}) {
  return LineTouchTooltipData(
    getTooltipColor: (_) => const Color(0xEE0D2236),
    fitInsideHorizontally: true,
    fitInsideVertically: true,
    tooltipRoundedRadius: 10,
    tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    getTooltipItems: (items) {
      return items.map((item) {
        final index = item.spotIndex;
        final point = index >= 0 && index < points.length ? points[index] : null;
        final date = point?.date;
        final dayLabel = date == null
            ? 'Dia'
            : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
        final value = item.y;
        final main = '$dayLabel • ${value.toStringAsFixed(unit == '%' ? 0 : 1)} $unit';
        final goalText = goal != null && goal > 0
            ? '\nMeta: ${goal.toStringAsFixed(unit == '%' ? 0 : 1)} $unit'
            : '';

        return LineTooltipItem(
          '$main$goalText',
          const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: goal != null && goal > 0
                  ? '\n${value >= goal ? 'Acima da meta' : 'Abaixo da meta'}'
                  : '',
              style: TextStyle(
                color: color.withValues(alpha: 0.92),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(growable: false);
    },
  );
}
