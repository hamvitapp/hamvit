import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final doc = pw.Document();

  final navy = PdfColor.fromInt(0xFF071A2D);
  final cyan = PdfColor.fromInt(0xFF00B7D9);
  final green = PdfColor.fromInt(0xFF1FC2A6);

  // Cover
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(32),
        decoration: pw.BoxDecoration(
          gradient: pw.LinearGradient(colors: [navy, PdfColor.fromInt(0xFF03243A)]),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Spacer(),
          pw.Text('HAMVIT', style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
          pw.SizedBox(height: 8),
          pw.Text('Evolua no seu ritmo.', style: pw.TextStyle(fontSize: 14, color: PdfColors.white)),
          pw.SizedBox(height: 40),
          pw.Text('João da Silva', style: pw.TextStyle(fontSize: 18, color: PdfColors.white)),
          pw.SizedBox(height: 4),
          pw.Text('Período: 01/05/2026 - 24/05/2026', style: pw.TextStyle(fontSize: 9, color: PdfColors.white)),
          pw.SizedBox(height: 24),
          pw.Row(children: [
            pw.Container(width: 130, height: 70, padding: const pw.EdgeInsets.all(8), decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)), child: pw.Column(children: [pw.Text('Peso', style: pw.TextStyle(fontSize: 10)), pw.Spacer(), pw.Text('72.4 kg', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))])),
            pw.SizedBox(width: 12),
            pw.Container(width: 130, height: 70, padding: const pw.EdgeInsets.all(8), decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)), child: pw.Column(children: [pw.Text('Hábitos', style: pw.TextStyle(fontSize: 10)), pw.Spacer(), pw.Text('78%', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))])),
            pw.SizedBox(width: 12),
            pw.Container(width: 130, height: 70, padding: const pw.EdgeInsets.all(8), decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)), child: pw.Column(children: [pw.Text('Hidratação', style: pw.TextStyle(fontSize: 10)), pw.Spacer(), pw.Text('2.1 L', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold))])),
          ]),
          pw.Spacer(),
        ]),
      ),
    ),
  );

  // Executive summary
  doc.addPage(pw.MultiPage(build: (context) => [
        pw.Text('Resumo Executivo', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: navy)),
        pw.SizedBox(height: 8),
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
          pw.Expanded(child: pw.Text('HAMVIT Score: 82', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold))),
          pw.Container(padding: const pw.EdgeInsets.all(8), decoration: pw.BoxDecoration(color: cyan, borderRadius: pw.BorderRadius.circular(8)), child: pw.Text('Melhora +12%', style: pw.TextStyle(color: PdfColors.white)))
        ]),
        pw.SizedBox(height: 12),
        pw.Text('Tendências: houve melhora consistente de hábitos e hidratação; peso estabilizado próximo à meta.', style: pw.TextStyle(fontSize: 11)),
        pw.SizedBox(height: 18),
        pw.Text('Evolução de peso', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _simpleSparkline([74.2, 73.1, 72.8, 72.6, 72.4], cyan, green),
        pw.SizedBox(height: 18),
        pw.Text('Alimentação', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        _simpleBars([2200, 2100, 2000, 2300, 2150], cyan),
      ]));

  // Insights
  doc.addPage(pw.MultiPage(build: (context) => [
        pw.Text('Insights Premium', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: navy)),
        pw.SizedBox(height: 8),
        pw.Container(padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(color: PdfColors.white, borderRadius: pw.BorderRadius.circular(8)), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('Consistência de hábitos aumentou 18%', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.Text('Recomendação: manter rotina de anotação pós-refeição e meta de hidratação diária.'),
        ])),
        pw.SizedBox(height: 20),
        pw.Text('FIM DO RELATÓRIO', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
      ]));

  final outDir = Directory('build/reports');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  final file = File('build/reports/sample_report.pdf');
  await file.writeAsBytes(await doc.save());
  print('PDF gerado em: ${file.path}');
}

pw.Widget _simpleSparkline(List<double> values, PdfColor start, PdfColor end) {
  final max = values.reduce((a, b) => a > b ? a : b);
  final points = values.asMap().entries.map((e) {
    final x = e.key.toDouble();
    final y = (e.value / (max == 0 ? 1 : max)) * 40;
    return pw.Positioned(child: pw.Container());
  }).toList();

  return pw.Container(
    height: 60,
    child: pw.Stack(children: [
      pw.Container(height: 60, decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(6))),
      pw.Container(margin: const pw.EdgeInsets.all(8), child: pw.Center(child: pw.Text('Sparkline (preview)', style: pw.TextStyle(color: PdfColors.grey600)))),
    ]),
  );
}

pw.Widget _simpleBars(List<int> values, PdfColor color) {
  final max = values.reduce((a, b) => a > b ? a : b);
  final bars = values.map((v) {
    final h = (v / (max == 0 ? 1 : max)) * 40;
    return pw.Container(width: 10, height: h < 4 ? 4 : h, decoration: pw.BoxDecoration(gradient: pw.LinearGradient(colors: [color, PdfColor.fromInt(0xFF1FC2A6)]), borderRadius: pw.BorderRadius.circular(3)));
  }).toList();

  return pw.Row(mainAxisAlignment: pw.MainAxisAlignment.start, children: bars.map((b) => pw.Padding(padding: const pw.EdgeInsets.only(right: 6), child: b)).toList());
}
