import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'hamvit_pdf_sections.dart';
import 'hamvit_pdf_theme.dart';
import 'hamvit_report_data.dart';

class HamvitPdfReportService {
  final HamvitPdfTheme theme;
  HamvitPdfReportService({required this.theme});

  Future<pw.Document> buildReport(HamvitReportData data) async {
    final doc = pw.Document();

    final generationDate =
        '${data.generatedAt.day.toString().padLeft(2, '0')}/${data.generatedAt.month.toString().padLeft(2, '0')}/${data.generatedAt.year}';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(
          padding: const pw.EdgeInsets.all(24),
          decoration: const pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [
                HamvitPdfTheme.coverGradTop,
                HamvitPdfTheme.coverGradMid,
                HamvitPdfTheme.coverGradBot,
              ],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(child: buildCoverSummary(theme, data)),
              pw.Column(
                children: [
                  pw.Divider(color: const PdfColor.fromInt(0xFF1A4A78)),
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      if (theme.brandLogo != null)
                        pw.Image(theme.brandLogo!, width: 70, height: 14, fit: pw.BoxFit.contain)
                      else
                        pw.Text('HAMVIT', style: theme.coverSubtitle(9)),
                      pw.Text('Página 1', style: theme.coverSubtitle(9)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        header: (ctx) => pw.SizedBox(height: 0),
        footer: (ctx) => theme.fullFooter(ctx.pageNumber, generationDate),
        build: (_) => buildPdfSections(theme, data),
      ),
    );

    return doc;
  }
}
