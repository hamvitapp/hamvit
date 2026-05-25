import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_provider.dart';
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

  Future<Map<String, dynamic>> _storePdfAndRegister({
    required EvolutionReportData data,
    required Uint8List bytes,
  }) async {
    final client = _client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) {
      return const {};
    }

    final now = DateTime.now();
    final fileName = 'evolution_${now.millisecondsSinceEpoch}.pdf';
    final path = '${user.id}/$fileName';

    String? storedPath;
    try {
      await client.storage.from('report-pdfs').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'application/pdf',
            ),
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

      return {
        'report_id': inserted['id']?.toString(),
        'pdf_path': storedPath,
      };
    } catch (_) {
      return {'pdf_path': storedPath};
    }
  }

  Future<Uint8List> _buildPdf({
    required EvolutionReportData data,
    required String userName,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd/MM/yyyy', 'pt_BR');
    final generatedAt = dateFmt.format(DateTime.now());
    final periodLabel = '${dateFmt.format(data.start)} - ${dateFmt.format(data.end)}';

    pw.Widget header(String title, {String? subtitle}) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: const PdfColor(0.03, 0.10, 0.20),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                )),
            if (subtitle != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(subtitle, style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
            ],
            pw.SizedBox(height: 4),
            pw.Text('Período: $periodLabel  |  Gerado em: $generatedAt',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
          ],
        ),
      );
    }

    pw.Widget metricRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ),
            pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      );
    }

    pw.Widget simpleBars(String title, List<double> values) {
      final maxValue = values.isEmpty ? 1.0 : values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
          pw.SizedBox(height: 6),
          for (final value in values.take(14))
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Container(
                height: 6,
                width: 260 * (value / maxValue),
                decoration: pw.BoxDecoration(
                  color: const PdfColor(0.0, 0.72, 0.85),
                  borderRadius: pw.BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      );
    }

    pw.Widget watermark() {
      return pw.Opacity(
        opacity: 0.06,
        child: pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'HAMVIT',
            style: pw.TextStyle(
              fontSize: 42,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey500,
            ),
          ),
        ),
      );
    }

    doc.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            header('Relatório de acompanhamento HAMVIT', subtitle: 'Evolua no seu ritmo.'),
            watermark(),
            pw.SizedBox(height: 16),
            metricRow('Usuário', userName),
            metricRow('HAMVIT Score', data.hamvitScore.toStringAsFixed(0)),
            metricRow('Evolução de peso',
                '${(data.weightCurrent ?? 0).toStringAsFixed(1)} kg (inicial ${((data.weightInitial ?? 0)).toStringAsFixed(1)} kg)'),
            metricRow('Adesão de hábitos', '${data.habitsConsistency.toStringAsFixed(0)}%'),
            metricRow('Média de água', '${data.waterAverage.toStringAsFixed(0)} ml'),
            metricRow('Média calórica', '${data.caloriesAverage.toStringAsFixed(0)} kcal'),
            metricRow('Tempo ativo', '${data.activeMinutes.toStringAsFixed(0)} min'),
            pw.SizedBox(height: 14),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Text(
                'Este relatório é informativo e não substitui avaliação médica, nutricional ou profissional.',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Documento informativo.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        footer: (context) => pw.Text('HAMVIT • $periodLabel', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        build: (_) => [
          header('Página 2 — Evolução corporal'),
          watermark(),
          pw.SizedBox(height: 10),
          metricRow('Peso inicial', data.weightInitial == null ? '-' : '${data.weightInitial!.toStringAsFixed(1)} kg'),
          metricRow('Peso atual', data.weightCurrent == null ? '-' : '${data.weightCurrent!.toStringAsFixed(1)} kg'),
          metricRow('Peso alvo', data.weightTarget == null ? '-' : '${data.weightTarget!.toStringAsFixed(1)} kg'),
          metricRow('IMC inicial', data.bmiInitial == null ? '-' : data.bmiInitial!.toStringAsFixed(1)),
          metricRow('IMC atual', data.bmiCurrent == null ? '-' : data.bmiCurrent!.toStringAsFixed(1)),
          pw.SizedBox(height: 8),
          simpleBars('Gráfico de peso (estático)', data.weightPoints.map((e) => e.value).toList(growable: false)),
          pw.SizedBox(height: 8),
          simpleBars('Gráfico de IMC (estático)', data.bmiPoints.map((e) => e.value).toList(growable: false)),
          pw.SizedBox(height: 14),
          header('Página 3 — Alimentação'),
          pw.SizedBox(height: 10),
          metricRow('Média calórica', '${data.caloriesAverage.toStringAsFixed(0)} kcal'),
          metricRow('Meta calórica', '${data.caloriesGoal.toStringAsFixed(0)} kcal'),
          metricRow('Dias dentro da meta', '${data.caloriesWithinGoalDays}'),
          metricRow('Proteínas (média)', '${data.proteinAverage.toStringAsFixed(1)} g'),
          metricRow('Carboidratos (média)', '${data.carbsAverage.toStringAsFixed(1)} g'),
          metricRow('Gorduras (média)', '${data.fatsAverage.toStringAsFixed(1)} g'),
          pw.SizedBox(height: 8),
          simpleBars('Gráfico de calorias (estático)', data.caloriesPoints.map((e) => e.value).toList(growable: false)),
          pw.SizedBox(height: 14),
          header('Página 4 — Hidratação e hábitos'),
          pw.SizedBox(height: 10),
          metricRow('Média diária de água', '${data.waterAverage.toStringAsFixed(0)} ml'),
          metricRow('Meta diária', '${data.waterGoal.toStringAsFixed(0)} ml'),
          metricRow('Dias com meta batida', '${data.waterGoalDays}'),
          metricRow('Hábitos concluídos', '${data.habitsCompleted}'),
          metricRow('Consistência', '${data.habitsConsistency.toStringAsFixed(0)}%'),
          metricRow('Streak atual', '${data.currentStreak} dia(s)'),
          pw.SizedBox(height: 8),
          simpleBars('Heatmap de consistência (estático)', data.consistencyPoints.map((e) => e.value).toList(growable: false)),
          pw.SizedBox(height: 14),
          header('Página 5 — Atividade física e sono'),
          pw.SizedBox(height: 10),
          metricRow('Tempo ativo', '${data.activeMinutes.toStringAsFixed(0)} min'),
          metricRow('Distância', '${data.distanceKm.toStringAsFixed(2)} km'),
          metricRow('Calorias estimadas', '${data.activityCalories.toStringAsFixed(0)} kcal'),
          metricRow('Quantidade de atividades', '${data.activityCount}'),
          metricRow('Sono médio', '${data.sleepAverageHours.toStringAsFixed(1)} h'),
          metricRow('Último registro de sono', data.lastSleepLabel),
          metricRow('Qualidade média', data.sleepQuality == 0 ? '-' : data.sleepQuality.toStringAsFixed(1)),
          pw.SizedBox(height: 8),
          simpleBars('Gráfico de atividade (estático)', data.activityPoints.map((e) => e.value).toList(growable: false)),
          pw.SizedBox(height: 8),
          simpleBars('Gráfico de sono (estático)', data.sleepPoints.map((e) => e.value).toList(growable: false)),
          pw.SizedBox(height: 14),
          header('Página 6 — Insights e observações'),
          pw.SizedBox(height: 10),
          for (final insight in data.insights)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(insight['title'] ?? '-', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(insight['body'] ?? '-', style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Este relatório é informativo e não substitui avaliação médica, nutricional ou profissional.',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Documento informativo.',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    return Uint8List.fromList(bytes);
  }
}
