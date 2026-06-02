import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'hamvit_pdf_theme.dart';

List<double> _buildScaleTicks(double maxVal) {
  if (maxVal <= 0) return [0, 20, 40, 60, 80, 100];
  final magnitude = _orderOfMagnitude(maxVal);
  final normalized = maxVal / magnitude;
  double niceMax;
  if (normalized <= 1) {
    niceMax = 1;
  } else if (normalized <= 2) {
    niceMax = 2;
  } else if (normalized <= 5) {
    niceMax = 5;
  } else {
    niceMax = 10;
  }
  niceMax *= magnitude;

  final step = niceMax / 4;
  return [0, step, step * 2, step * 3, step * 4];
}

double _orderOfMagnitude(double val) {
  if (val <= 0) return 1;
  var magnitude = 1;
  while (val >= 10) {
    val = val / 10;
    magnitude *= 10;
  }
  return magnitude.toDouble();
}

String _fmtScale(double val, String unit) {
  if (val == 0) return '0';
  if (val >= 1000 && unit == 'ml') return '${(val / 1000).toStringAsFixed(1)}L';
  if (val >= 1000) return val.toStringAsFixed(0);
  if (val == val.roundToDouble()) return val.toStringAsFixed(0);
  return val.toStringAsFixed(1);
}

List<String> _buildXAxisDateLabels(List<DateTime> dates) {
  if (dates.isEmpty) return const <String>[];
  if (dates.length <= 10) {
    return dates
        .map((d) =>
            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}')
        .toList(growable: false);
  }

  final step = dates.length <= 15
      ? 2
      : dates.length <= 31
          ? 3
          : 5;
  final labels = List<String>.filled(dates.length, '', growable: false);
  for (var i = 0; i < dates.length; i++) {
    final isEdge = i == 0 || i == dates.length - 1;
    final isStep = i % step == 0;
    if (isEdge || isStep) {
      final d = dates[i];
      labels[i] =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }
  }
  return labels;
}

pw.Widget fallbackCard(HamvitPdfTheme t, String message, {pw.ImageProvider? icon}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(14),
    decoration: t.card(),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (icon != null)
          pw.Image(icon, width: 18, height: 18, fit: pw.BoxFit.contain)
        else if (t.brandLogo != null)
          pw.Image(t.brandLogo!, width: 70, height: 16, fit: pw.BoxFit.contain)
        else
          pw.Text('HAMVIT', style: t.h2()),
        pw.SizedBox(height: 6),
        pw.Text(message, style: t.bodyMuted()),
        pw.SizedBox(height: 4),
        pw.Text('Registre dados continuamente para habilitar grÃ¡ficos completos.', style: t.small()),
      ],
    ),
  );
}

pw.Widget metricPill(HamvitPdfTheme t, String label, String value) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: pw.BoxDecoration(
      color: HamvitPdfTheme.soft,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: t.bodyMuted(8.5)),
        pw.Text(value, style: t.body(10)),
      ],
    ),
  );
}

pw.Widget chartCard(
  HamvitPdfTheme t, {
  required String title,
  required String subtitle,
  required List<double> values,
  List<DateTime>? dates,
  required String legend,
  required String insight,
  double? goal,
  bool bars = false,
  String emptyMessage = 'Sem dados suficientes neste perÃ­odo.',
  String unit = '',
  String goalLabel = 'Meta calculada',
}) {
  if (values.where((v) => v > 0).isEmpty) return fallbackCard(t, emptyMessage);

  final avg = values.reduce((a, b) => a + b) / values.length;
  final maxVal = values.reduce((a, b) => a > b ? a : b);
  final safeMax = (goal != null && goal > maxVal ? goal * 1.15 : maxVal * 1.2).clamp(1.0, 999999.0);
  final ticks = _buildScaleTicks(safeMax);
  final axisMax = ticks.last;
  const chartHeight = 130.0;

  final baseDates = (dates != null && dates.length == values.length) ? dates : null;
  final displayValues = values.length > 30 ? _downsample(values, 30) : values;
  final List<DateTime> displayDates = baseDates == null
      ? List<DateTime>.generate(
          displayValues.length,
          (i) => DateTime(2000, 1, i + 1),
        )
      : (baseDates.length > 30 ? _downsample(baseDates, 30) : baseDates);
  final xAxisLabels = _buildXAxisDateLabels(displayDates);

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: t.card(),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: t.h2()),
        pw.SizedBox(height: 2),
        pw.Text(subtitle, style: t.bodyMuted()),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            metricPill(t, 'MÃ©dia', '${avg.toStringAsFixed(1)} $unit'),
            metricPill(t, 'Meta', goal == null ? '-' : '${goal.toStringAsFixed(1)} $unit'),
            metricPill(t, 'Pico', '${maxVal.toStringAsFixed(1)} $unit'),
          ],
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 34,
              height: chartHeight,
              child: pw.Stack(
                children: ticks.map((tick) {
                  final y = chartHeight * (1 - tick / axisMax);
                  final labelTop = (y - 4).clamp(0.0, chartHeight - 8.0);
                  return pw.Positioned(
                    top: labelTop,
                    left: 0,
                    child: pw.Text(_fmtScale(tick, unit), style: t.scaleLabel()),
                  );
                }).toList(),
              ),
            ),
            pw.SizedBox(width: 4),
            pw.Expanded(
              child: pw.Stack(
                children: [
                  ...ticks.map((tick) {
                    final y = chartHeight * (1 - tick / axisMax);
                    return pw.Positioned(
                      left: 0,
                      right: 0,
                      top: y,
                      child: pw.Container(height: 0.5, color: const PdfColor.fromInt(0xFFE3E8F2)),
                    );
                  }),
                  pw.Container(
                    height: chartHeight,
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: displayValues.map((v) {
                        final barH = ((v / axisMax) * chartHeight).clamp(0.0, chartHeight).toDouble();
                        return pw.Expanded(
                          child: pw.Column(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              if (v == maxVal && v > 0)
                                pw.Text(
                                  v.toStringAsFixed(1),
                                  style: pw.TextStyle(font: t.base, fontSize: 6, color: HamvitPdfTheme.muted),
                                ),
                              if (barH > 0)
                                pw.Container(
                                  margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                                  height: barH,
                                  decoration: pw.BoxDecoration(
                                    color: bars ? HamvitPdfTheme.blue : HamvitPdfTheme.cyan,
                                    borderRadius: pw.BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (goal != null && goal > 0)
                    pw.Positioned(
                      top: chartHeight * (1 - goal.clamp(0, axisMax) / axisMax),
                      left: 0,
                      right: 0,
                      child: pw.Container(
                        height: 1.5,
                        decoration: pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: HamvitPdfTheme.goalLine, width: 1.5)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('Dia:', style: t.small()),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Row(
                children: List.generate(displayValues.length, (i) {
                  return pw.Expanded(
                    child: pw.Center(
                      child: pw.Text(xAxisLabels[i], style: t.small(6.3)),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Barras: $legend em $unit. ${goal != null ? 'Linha vermelha: $goalLabel ($goal $unit).' : ''} PerÃ­odo analisado: perÃ­odo completo.',
          style: t.small(),
        ),
        pw.SizedBox(height: 3),
        pw.Text('Insight: $insight', style: t.body(9.5)),
      ],
    ),
  );
}

pw.Widget macrosSegmentedBar(HamvitPdfTheme t, {required double protein, required double carbs, required double fat}) {
  final total = (protein + carbs + fat) <= 0 ? 1.0 : (protein + carbs + fat);
  final p = protein / total;
  final c = carbs / total;
  final f = fat / total;
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: t.card(),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('DistribuiÃ§Ã£o de Macros', style: t.h2()),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 24,
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: (p * 1000).round().clamp(1, 1000),
                child: pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: HamvitPdfTheme.mint,
                    borderRadius: pw.BorderRadius.only(
                      topLeft: pw.Radius.circular(4),
                      bottomLeft: pw.Radius.circular(4),
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: p > 0.08
                      ? pw.Text('${(p * 100).toStringAsFixed(0)}%', style: pw.TextStyle(font: t.base, fontSize: 9, color: PdfColors.white))
                      : pw.Container(),
                ),
              ),
              pw.Expanded(
                flex: (c * 1000).round().clamp(1, 1000),
                child: pw.Container(
                  color: HamvitPdfTheme.cyan,
                  alignment: pw.Alignment.center,
                  child: c > 0.08
                      ? pw.Text('${(c * 100).toStringAsFixed(0)}%', style: pw.TextStyle(font: t.base, fontSize: 9, color: PdfColors.white))
                      : pw.Container(),
                ),
              ),
              pw.Expanded(
                flex: (f * 1000).round().clamp(1, 1000),
                child: pw.Container(
                  decoration: const pw.BoxDecoration(
                    color: HamvitPdfTheme.blue,
                    borderRadius: pw.BorderRadius.only(
                      topRight: pw.Radius.circular(4),
                      bottomRight: pw.Radius.circular(4),
                    ),
                  ),
                  alignment: pw.Alignment.center,
                  child: f > 0.08
                      ? pw.Text('${(f * 100).toStringAsFixed(0)}%', style: pw.TextStyle(font: t.base, fontSize: 9, color: PdfColors.white))
                      : pw.Container(),
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            _macroDot(t, HamvitPdfTheme.mint, 'ProteÃ­na', protein, 'g'),
            pw.SizedBox(width: 12),
            _macroDot(t, HamvitPdfTheme.cyan, 'Carboidrato', carbs, 'g'),
            pw.SizedBox(width: 12),
            _macroDot(t, HamvitPdfTheme.blue, 'Gordura', fat, 'g'),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text('Legenda: distribuiÃ§Ã£o percentual de macronutrientes â€¢ PerÃ­odo analisado: perÃ­odo completo.', style: t.small()),
      ],
    ),
  );
}

pw.Widget _macroDot(HamvitPdfTheme t, PdfColor color, String label, double grams, String unit) {
  return pw.Row(
    children: [
      pw.Container(width: 8, height: 8, decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(4))),
      pw.SizedBox(width: 4),
      pw.Text('$label ${grams.toStringAsFixed(0)}$unit', style: t.body(9)),
    ],
  );
}

pw.Widget heatmap(
  HamvitPdfTheme t, {
  required List<double> values,
  List<DateTime>? dates,
}) {
  if (values.isEmpty) return fallbackCard(t, 'Sem dados de consistÃªncia neste perÃ­odo.');
  final colorScale = [
    PdfColor.fromInt(0xFFE7EDF5),
    PdfColor.fromInt(0xFFCFE6FA),
    PdfColor.fromInt(0xFF8FD0F5),
    PdfColor.fromInt(0xFF3FB9EE),
    PdfColor.fromInt(0xFF168DFF),
  ];

  final labels = (dates != null && dates.length == values.length)
      ? dates
          .map((d) =>
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}')
          .toList(growable: false)
      : List<String>.generate(values.length, (i) => '${i + 1}');

  const maxCols = 15;
  final rows = <pw.Widget>[];
  for (var start = 0; start < values.length; start += maxCols) {
    final end = (start + maxCols) > values.length ? values.length : (start + maxCols);
    final chunkValues = values.sublist(start, end);
    final chunkLabels = labels.sublist(start, end);
    rows.add(
      pw.Row(
        children: List.generate(maxCols, (i) {
          if (i >= chunkValues.length) {
            return pw.Expanded(child: pw.SizedBox(height: 18));
          }
          final v = chunkValues[i];
          final idx = (v / 25).floor().clamp(0, 4);
          final color = colorScale[idx];
          return pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.symmetric(horizontal: 1.5),
              height: 18,
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                chunkLabels[i],
                style: pw.TextStyle(
                  font: t.bold,
                  fontSize: 5.5,
                  color: const PdfColor.fromInt(0xFF1D2A3A),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: t.card(),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('ConsistÃªncia de HÃ¡bitos', style: t.h2()),
        pw.SizedBox(height: 4),
        pw.Text('RelaÃ§Ã£o de constÃ¢ncia por dia', style: t.bodyMuted()),
        pw.SizedBox(height: 8),
        pw.Column(
          children: rows
              .map((r) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: r,
                  ))
              .toList(),
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          children: [
            pw.Text('0%', style: t.small(7)),
            ...colorScale.map(
              (c) => pw.Container(
                width: 16,
                height: 10,
                margin: const pw.EdgeInsets.symmetric(horizontal: 1),
                decoration: pw.BoxDecoration(color: c, borderRadius: pw.BorderRadius.circular(2)),
              ),
            ),
            pw.Text('100%', style: t.small(7)),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Legenda: cada bloco representa um dia. Quanto mais escuro, maior a consistÃªncia de hÃ¡bitos naquele dia. PerÃ­odo analisado: perÃ­odo completo.',
          style: t.small(),
        ),
      ],
    ),
  );
}
List<T> _downsample<T>(List<T> data, int targetCount) {
  if (data.length <= targetCount) return data;
  final step = data.length / targetCount;
  final result = <T>[];
  for (var i = 0; i < targetCount; i++) {
    final idx = (i * step).floor().clamp(0, data.length - 1);
    result.add(data[idx]);
  }
  return result;
}

