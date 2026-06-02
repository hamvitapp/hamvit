import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../theme/hamvit_colors.dart';
import '../domain/dashboard_metrics_service.dart';
import 'hamvit_chart_tooltip.dart';
import 'hamvit_goal_line.dart';
import 'hamvit_empty_chart_state.dart';

class HamvitLineChart extends StatelessWidget {
  final List<DashboardPoint> points;
  final double? goal;
  final Color color;
  final String unit;
  final String emptyMessage;

  const HamvitLineChart({
    super.key,
    required this.points,
    required this.goal,
    required this.color,
    required this.unit,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final visiblePoints = points.where((p) => p.value > 0).toList();
    if (points.isEmpty || visiblePoints.isEmpty) {
      return HamvitEmptyChartState(message: emptyMessage);
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    final values = visiblePoints.map((e) => e.value).toList(growable: false);
    final minPoint = values.reduce((a, b) => a < b ? a : b);
    final maxPoint = values.reduce((a, b) => a > b ? a : b);
    final range = (maxPoint - minPoint).abs();
    final isBodyMetric = unit == 'kg' || unit == 'IMC';
    final isConsistency = unit == '%';

    final double minY;
    final double maxY;
    if (isConsistency) {
      minY = 0;
      maxY = 100;
    } else if (isBodyMetric) {
      // Smart Y-domain: keeps subtle body-metric changes (e.g. 172 -> 170) visible.
      const basePadding = 0.8;
      final padding = range > 0 ? (range * 0.28).clamp(basePadding, 99999.0) : basePadding;
      final minYRaw =
          ((range > 0 ? (minPoint - padding) : (minPoint - basePadding)).clamp(0.0, 999999.0))
              .toDouble();
      final maxYRaw =
          ((range > 0 ? (maxPoint + padding) : (maxPoint + basePadding)).clamp(1.0, 999999.0))
              .toDouble();
      minY = minYRaw;
      maxY = maxYRaw <= minY ? minY + 1.0 : maxYRaw;
    } else {
      // Non-body metrics must keep zero baseline to avoid "floating history".
      minY = 0;
      final topCandidate = [maxPoint, goal ?? 0].reduce((a, b) => a > b ? a : b);
      final top = (topCandidate * 1.22).clamp(1.0, 999999.0).toDouble();
      maxY = top <= minY ? minY + 1.0 : top;
    }
    final ySpan = (maxY - minY).abs();
    final goalValue = goal;
    final goalInRange = goalValue != null && goalValue >= minY && goalValue <= maxY;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final animatedSpots = spots
            .map((s) => FlSpot(s.x, minY + ((s.y - minY) * t)))
            .toList(growable: false);

        return SizedBox(
          height: 170,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (animatedSpots.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              clipData: const FlClipData.all(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (ySpan / 4).clamp(0.2, 99999),
                getDrawingHorizontalLine: (_) => FlLine(
                  color: Colors.white.withValues(alpha: 0.08),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: (animatedSpots.length / 4).ceilToDouble().clamp(1, 999),
                    getTitlesWidget: (value, meta) {
                      final index = value.round();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      final date = points[index].date;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          '${date.day}/${date.month}',
                          style: const TextStyle(
                            color: HamvitColors.darkTextMuted,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  if (goalInRange && buildHamvitGoalLine(goal, color) != null)
                    buildHamvitGoalLine(goal, color)!,
                ],
              ),
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: buildHamvitTooltip(
                  points: points,
                  unit: unit,
                  goal: goal,
                  color: color,
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: animatedSpots,
                  isCurved: animatedSpots.length > 2,
                  curveSmoothness: 0.18,
                  preventCurveOverShooting: true,
                  preventCurveOvershootingThreshold: 8,
                  barWidth: 3,
                  color: color,
                  dotData: FlDotData(
                    show: true,
                    checkToShowDot: (spot, barData) =>
                        spot.x % (animatedSpots.length > 12 ? 4 : 2) == 0,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 2.2,
                      color: color,
                      strokeColor: Colors.white,
                      strokeWidth: 1,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withValues(alpha: 0.25),
                        color.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
