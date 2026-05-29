import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hamvit_mobile/features/dashboard/domain/dashboard_metrics_service.dart';
import 'package:hamvit_mobile/features/reports/report_layout_engine.dart';
import 'package:hamvit_mobile/features/reports/report_repository.dart';
import 'package:hamvit_mobile/features/reports/report_widget_image_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Generate 7d PDF without chart framework errors', (tester) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final points = List<DashboardPoint>.generate(
      7,
      (i) => DashboardPoint(
        date: start.add(Duration(days: i)),
        value: 60 + (i * 2).toDouble(),
      ),
    );

    final data = EvolutionReportData(
      period: ReportPeriodType.days7,
      start: start,
      end: DateTime(now.year, now.month, now.day),
      hamvitScore: 82,
      waterAverage: 2200,
      waterGoal: 2500,
      waterGoalDays: 4,
      caloriesAverage: 2050,
      caloriesGoal: 2100,
      caloriesWithinGoalDays: 5,
      proteinAverage: 110,
      carbsAverage: 220,
      fatsAverage: 70,
      habitsCompleted: 20,
      habitsConsistency: 78,
      currentStreak: 4,
      activeMinutes: 185,
      distanceKm: 12.4,
      activityCalories: 1450,
      activityCount: 5,
      sleepAverageHours: 7.1,
      lastSleepLabel: '25/05',
      sleepQuality: 81,
      weightInitial: 82.0,
      weightCurrent: 81.2,
      weightTarget: 78.0,
      bmiInitial: 26.2,
      bmiCurrent: 25.9,
      weightProgressPercent: 30,
      weightPoints: points,
      bmiPoints: points.map((e) => DashboardPoint(date: e.date, value: 25 + ((e.value - 60) / 30))).toList(),
      waterPoints: points.map((e) => DashboardPoint(date: e.date, value: 1800 + ((e.value - 60) * 80))).toList(),
      caloriesPoints: points.map((e) => DashboardPoint(date: e.date, value: 1900 + ((e.value - 60) * 12))).toList(),
      habitsPoints: points.map((e) => DashboardPoint(date: e.date, value: (e.value - 40).clamp(0, 100))).toList(),
      consistencyPoints: points.map((e) => DashboardPoint(date: e.date, value: (e.value + 10).clamp(0, 100))).toList(),
      activityPoints: points.map((e) => DashboardPoint(date: e.date, value: 18 + ((e.value - 60) * 1.8))).toList(),
      sleepPoints: points.map((e) => DashboardPoint(date: e.date, value: 6.2 + ((e.value - 60) * 0.04))).toList(),
      insights: const [
        {'title': 'Hidratacao em evolucao', 'body': 'Sua media de agua melhorou no periodo.'},
      ],
      bodyMeasures: const {},
    );

    final charts = await ReportWidgetImageRenderer().render(data);
    final doc = ReportLayoutEngine.buildDocument(data, 'Usuario Teste', charts: charts);
    final bytes = await doc.save();

    final outDir = Directory('build/reports');
    if (!outDir.existsSync()) outDir.createSync(recursive: true);
    final file = File('build/reports/hamvit_report_7d_smoke.pdf');
    await file.writeAsBytes(bytes, flush: true);

    expect(bytes.isNotEmpty, isTrue);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync() > 1024, isTrue);
  });
}

