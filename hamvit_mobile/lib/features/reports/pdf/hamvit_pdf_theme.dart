import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class HamvitPdfTheme {
  final pw.Font base;
  final pw.Font bold;
  final pw.ImageProvider? brandLogo;
  HamvitPdfTheme({required this.base, required this.bold, this.brandLogo});

  // Core palette
  static const PdfColor navy = PdfColor.fromInt(0xFF071A2D);
  static const PdfColor deepBlue = PdfColor.fromInt(0xFF03243A);
  static const PdfColor midnight = PdfColor.fromInt(0xFF0B2A45);
  static const PdfColor cyan = PdfColor.fromInt(0xFF00B7D8);
  static const PdfColor mint = PdfColor.fromInt(0xFF39D98A);
  static const PdfColor blue = PdfColor.fromInt(0xFF168DFF);
  static const PdfColor text = PdfColor.fromInt(0xFF142033);
  static const PdfColor muted = PdfColor.fromInt(0xFF5B667A);
  static const PdfColor soft = PdfColor.fromInt(0xFFF6F8FB);
  static const PdfColor cardBorder = PdfColor.fromInt(0xFFE3E8F2);
  static const PdfColor goalLine = PdfColor.fromInt(0xFFFF6B6B);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF0F4FA);

  static const PdfColor coverGradTop = PdfColor.fromInt(0xFF071A2D);
  static const PdfColor coverGradMid = PdfColor.fromInt(0xFF0F2D4F);
  static const PdfColor coverGradBot = PdfColor.fromInt(0xFF1A4A78);
  static const PdfColor accentGold = PdfColor.fromInt(0xFFFFD700);

  // Typography
  pw.TextStyle title([double size = 28]) => pw.TextStyle(
        font: bold,
        fontSize: size,
        color: PdfColors.white,
      );
  pw.TextStyle h2() => pw.TextStyle(font: bold, fontSize: 16, color: text);
  pw.TextStyle h3() => pw.TextStyle(font: bold, fontSize: 14, color: text);
  pw.TextStyle body([double size = 10.5]) => pw.TextStyle(font: base, fontSize: size, color: text);
  pw.TextStyle bodyMuted([double size = 10]) => pw.TextStyle(font: base, fontSize: size, color: muted);
  pw.TextStyle small([double size = 8]) => pw.TextStyle(font: base, fontSize: size, color: muted);
  pw.TextStyle insightStyle() => pw.TextStyle(font: base, fontSize: 9, color: muted);
  pw.TextStyle goalStyle() => pw.TextStyle(font: base, fontSize: 8, color: goalLine);
  pw.TextStyle scaleLabel() => pw.TextStyle(font: base, fontSize: 7, color: muted);

  // Cover styles
  pw.TextStyle coverTitle([double size = 36]) => pw.TextStyle(
        font: bold,
        fontSize: size,
        color: PdfColors.white,
      );
  pw.TextStyle coverSlogan([double size = 13]) => pw.TextStyle(
        font: base,
        fontSize: size,
        color: PdfColors.white,
      );
  pw.TextStyle coverSubtitle([double size = 11]) => pw.TextStyle(
        font: base,
        fontSize: size,
        color: const PdfColor.fromInt(0xFFA0B8D4),
      );
  pw.TextStyle coverScoreLabel([double size = 10]) => pw.TextStyle(
        font: base,
        fontSize: size,
        color: const PdfColor.fromInt(0xFFCFE6FA),
      );
  pw.TextStyle coverScoreValue([double size = 48]) => pw.TextStyle(
        font: bold,
        fontSize: size,
        color: accentGold,
      );
  pw.TextStyle coverCardLabel() => pw.TextStyle(font: base, fontSize: 8, color: muted);
  pw.TextStyle coverCardValue() => pw.TextStyle(font: bold, fontSize: 12, color: text);

  // Header / Logo
  pw.TextStyle logoWordmark([double size = 14]) => pw.TextStyle(
        font: bold,
        fontSize: size,
        color: blue,
      );
  pw.TextStyle headerSectionName() => pw.TextStyle(font: bold, fontSize: 10, color: muted);
  pw.TextStyle headerPeriod() => pw.TextStyle(font: base, fontSize: 8, color: muted);

  // Footer
  pw.TextStyle footerText() => pw.TextStyle(font: base, fontSize: 7, color: muted);
  pw.TextStyle footerDisclaimer() => pw.TextStyle(font: base, fontSize: 6.5, color: muted);

  // Decorations
  pw.BoxDecoration card() => pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: cardBorder),
      );

  pw.BoxDecoration headerLine() => pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: soft, width: 1)),
      );

  pw.Widget divider() => pw.Container(
        height: 1,
        color: soft,
        margin: const pw.EdgeInsets.symmetric(vertical: 6),
      );

  pw.Widget pageHeader(String sectionName, String periodText) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: const PdfColor.fromInt(0xFFE3E8F2), width: 1)),
      ),
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            children: [
              pw.Text(sectionName, style: headerSectionName()),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget fullFooter(int pageNumber, String generationDate) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: const PdfColor.fromInt(0xFFE3E8F2), width: 1)),
      ),
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Row(
                children: [
                  if (brandLogo != null)
                    pw.Image(brandLogo!, width: 60, height: 12, fit: pw.BoxFit.contain)
                  else ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: blue,
                        borderRadius: pw.BorderRadius.circular(3),
                      ),
                      child: pw.Text('H', style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColors.white)),
                    ),
                    pw.SizedBox(width: 4),
                    pw.Text('HAMVIT', style: footerText()),
                  ],
                ],
              ),
              pw.Text('Gerado em: $generationDate  •  Página $pageNumber', style: footerText()),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text('Documento informativo. Não substitui avaliação profissional.', style: footerDisclaimer()),
        ],
      ),
    );
  }
}
