import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_provider.dart';
import 'pdf/hamvit_pdf_report_service.dart';
import 'pdf/hamvit_pdf_theme.dart';
import 'pdf/hamvit_report_data.dart';
import 'report_repository.dart';

final reportPdfServiceProvider = Provider<ReportPdfService>((ref) {
  return ReportPdfService(ref.watch(supabaseClientProvider));
});

class GeneratedReportFile {
  final String? reportId;
  final String? storagePath;
  final Uint8List bytes;
  const GeneratedReportFile({
    required this.reportId,
    required this.storagePath,
    required this.bytes,
  });
}

class ReportPdfService {
  final SupabaseClient? _client;
  ReportPdfService(this._client);

  Future<GeneratedReportFile> generateEvolutionPdf({
    required EvolutionReportData data,
    required String userName,
  }) async {
    final bytes = await _buildPdf(data: data, userName: userName);
    final uploadResult = await _storePdfAndRegister(data: data, bytes: bytes);
    return GeneratedReportFile(
      reportId: uploadResult['report_id']?.toString(),
      storagePath: uploadResult['pdf_path']?.toString(),
      bytes: bytes,
    );
  }

  Future<void> sharePdf({required Uint8List bytes, required String filename}) async {
    await Printing.sharePdf(bytes: bytes, filename: filename);
  }

  Future<Uint8List> _buildPdf({
    required EvolutionReportData data,
    required String userName,
  }) async {
    final regular = pwFont(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final bold = pwFont(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
    final client = _client;
    final user = client?.auth.currentUser;

    pw.ImageProvider? brandLogo;
    pw.ImageProvider? hydrationIcon;
    pw.ImageProvider? nutritionIcon;
    pw.ImageProvider? habitsIcon;
    pw.ImageProvider? sleepIcon;
    pw.ImageProvider? fallbackIcon;
    pw.ImageProvider? profilePhoto;

    try {
      final logoBytes = (await rootBundle.load('assets/branding/hamvit_brand_title_transparent.png')).buffer.asUint8List();
      brandLogo = pw.MemoryImage(logoBytes);
    } catch (_) {}
    try {
      hydrationIcon = pw.MemoryImage((await rootBundle.load('assets/icons/hidratacao.png')).buffer.asUint8List());
      nutritionIcon = pw.MemoryImage((await rootBundle.load('assets/icons/alimentacao.png')).buffer.asUint8List());
      habitsIcon = pw.MemoryImage((await rootBundle.load('assets/icons/habitos.png')).buffer.asUint8List());
      sleepIcon = pw.MemoryImage((await rootBundle.load('assets/icons/sono.png')).buffer.asUint8List());
      fallbackIcon = pw.MemoryImage((await rootBundle.load('assets/icons/relatorios.png')).buffer.asUint8List());
    } catch (_) {}

    if (client != null && user != null) {
      try {
        final row = await client
            .from('profiles')
            .select('photo_url, avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        final rawUrl = (row?['photo_url'] ?? row?['avatar_url'])?.toString();
        if (rawUrl != null && rawUrl.trim().isNotEmpty) {
          profilePhoto = await networkImage(rawUrl.trim());
        }
      } catch (_) {}
    }

    final theme = HamvitPdfTheme(base: regular, bold: bold, brandLogo: brandLogo);
    final service = HamvitPdfReportService(theme: theme);

    final model = HamvitReportData(
      userName: userName,
      periodStart: data.start,
      periodEnd: data.end,
      score: data.hamvitScore,
      weightLogs: data.weightPoints.map((p) => DateValue(p.date, p.value)).toList(growable: false),
      bmiLogs: data.bmiPoints.map((p) => DateValue(p.date, p.value)).toList(growable: false),
      hydrationLogs: data.waterPoints.map((p) => DateValue(p.date, p.value)).toList(growable: false),
      calorieLogs: data.caloriesPoints.map((p) => DateValue(p.date, p.value)).toList(growable: false),
      macroAverages: MacroShare(
        protein: data.proteinAverage,
        carbs: data.carbsAverage,
        fat: data.fatsAverage,
      ),
      sleepLogs: data.sleepPoints.map((p) => DateValue(p.date, p.value)).toList(growable: false),
      activityLogs: data.activityPoints.map((p) => DateValue(p.date, p.value)).toList(growable: false),
      habitLogs: data.habitsPoints.map((p) => DateValue(p.date, p.value)).toList(growable: false),
      consistencyLogs: data.consistencyPoints.map((p) => DateValue(p.date, p.value)).toList(growable: false),
      insights: data.insights.map((i) => i['title'] ?? i['body'] ?? '').where((v) => v.isNotEmpty).toList(growable: false),
      generatedAt: DateTime.now(),
      weightInitial: data.weightInitial,
      weightCurrent: data.weightCurrent,
      weightTarget: data.weightTarget,
      bmiCurrent: data.bmiCurrent,
      waterGoal: data.waterGoal,
      caloriesGoal: data.caloriesGoal,
      waterGoalDays: data.waterGoalDays,
      caloriesWithinGoalDays: data.caloriesWithinGoalDays,
      habitsCompleted: data.habitsCompleted,
      habitsConsistency: data.habitsConsistency,
      sleepAverageHours: data.sleepAverageHours,
      activeMinutes: data.activeMinutes,
      distanceKm: data.distanceKm,
      activityCalories: data.activityCalories,
      activityCount: data.activityCount,
      brandLogo: brandLogo,
      profilePhoto: profilePhoto,
      hydrationIcon: hydrationIcon,
      nutritionIcon: nutritionIcon,
      habitsIcon: habitsIcon,
      sleepIcon: sleepIcon,
      fallbackIcon: fallbackIcon,
    );

    final doc = await service.buildReport(model);
    return Uint8List.fromList(await doc.save());
  }

  Future<Map<String, dynamic>> _storePdfAndRegister({
    required EvolutionReportData data,
    required Uint8List bytes,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return const {};

    final now = DateTime.now();
    final fileName = 'evolution_${now.millisecondsSinceEpoch}.pdf';
    final path = '${user.id}/$fileName';
    String? storedPath;

    try {
      await client.storage.from('report-pdfs').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true, contentType: 'application/pdf'),
          );
      storedPath = path;
    } catch (_) {
      storedPath = null;
    }

    try {
      final inserted = await client.from('generated_reports').insert({
        'user_id': user.id,
        'format': 'pdf',
        'report_type': 'evolution',
        'period_type': data.period.code,
        'period_start': data.start.toIso8601String().substring(0, 10),
        'period_end': data.end.toIso8601String().substring(0, 10),
        'storage_path': storedPath,
        'pdf_path': storedPath,
        'status': 'ready',
        'summary_json': data.toSummaryJson(),
        'created_at': now.toIso8601String(),
        'ready_at': now.toIso8601String(),
      }).select('id').single();
      return {'report_id': inserted['id']?.toString(), 'pdf_path': storedPath};
    } catch (_) {
      return {'pdf_path': storedPath};
    }
  }
}

pw.Font pwFont(ByteData data) {
  return pw.Font.ttf(data);
}
