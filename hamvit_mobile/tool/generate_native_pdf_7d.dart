import 'dart:io';
import 'dart:typed_data';

import 'package:hamvit_mobile/features/reports/pdf/hamvit_pdf_report_service.dart';
import 'package:hamvit_mobile/features/reports/pdf/hamvit_pdf_theme.dart';
import 'package:hamvit_mobile/features/reports/pdf/hamvit_report_data.dart';
import 'package:pdf/widgets.dart' as pw;

Future<void> main() async {
  final regularBytes = await File('assets/fonts/Roboto-Regular.ttf').readAsBytes();
  final boldBytes = await File('assets/fonts/Roboto-Bold.ttf').readAsBytes();
  final theme = HamvitPdfTheme(
    base: pw.Font.ttf(ByteData.view(regularBytes.buffer)),
    bold: pw.Font.ttf(ByteData.view(boldBytes.buffer)),
  );

  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  List<DateValue> series(double base, double step) => List.generate(
        7,
        (i) => DateValue(start.add(Duration(days: i)), base + (i * step)),
      );

  final data = HamvitReportData(
    userName: 'Usuário HAMVIT',
    periodStart: start,
    periodEnd: DateTime(now.year, now.month, now.day),
    score: 81,
    weightLogs: series(82, -0.1),
    bmiLogs: series(26, -0.05),
    hydrationLogs: series(1800, 120),
    calorieLogs: series(1950, 35),
    macroAverages: const MacroShare(protein: 120, carbs: 240, fat: 70),
    sleepLogs: series(6.6, 0.08),
    activityLogs: series(24, 4),
    habitLogs: series(1, 0.1),
    consistencyLogs: series(58, 4),
    insights: const [
      'Hidratação em evolução no período.',
      'Sono apresentou melhora progressiva.',
      'Consistência semanal subiu em comparação ao período anterior.',
    ],
    generatedAt: DateTime.now(),
    weightInitial: 82.0,
    weightCurrent: 81.4,
    weightTarget: 78.0,
    bmiCurrent: 25.8,
    waterGoal: 2500,
    caloriesGoal: 2100,
    waterGoalDays: 4,
    caloriesWithinGoalDays: 5,
    habitsCompleted: 24,
    habitsConsistency: 78,
    sleepAverageHours: 7.2,
    activeMinutes: 188,
    distanceKm: 12.7,
    activityCalories: 1460,
    activityCount: 5,
  );

  final doc = await HamvitPdfReportService(theme: theme).buildReport(data);
  final outDir = Directory('build/reports');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final out = File('build/reports/hamvit_native_report_7d.pdf');
  await out.writeAsBytes(await doc.save(), flush: true);
  stdout.writeln('PDF gerado: ${out.path}');
}
