import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../theme/hamvit_colors.dart';

class HamvitSparklineChart extends StatelessWidget {
  final List<double> points;

  const HamvitSparklineChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    final data = points.isEmpty ? const [0.0, 0.0, 0.0, 0.0] : points;

    return SizedBox(
      height: 38,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: [for (var i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i].clamp(0, 100).toDouble())],
              isCurved: true,
              color: HamvitColors.accentMint,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    HamvitColors.accentMint.withValues(alpha: 0.25),
                    HamvitColors.accentMint.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
