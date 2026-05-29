import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'hamvit_pdf_charts.dart';
import 'hamvit_pdf_theme.dart';
import 'hamvit_report_data.dart';

String _br(DateTime dt) => '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
double _avg(List<DateValue> items) => items.isEmpty ? 0 : items.map((e) => e.value).reduce((a, b) => a + b) / items.length;

// ══════════════════════════════════════════════════════════════════════
// COVER / FIRST PAGE — Premium Layout
// ══════════════════════════════════════════════════════════════════════
pw.Widget buildCoverSummary(HamvitPdfTheme t, HamvitReportData d) {
  final score = d.score.clamp(0, 100);
  // Score ring visual (simplified with text + bar)
  final scoreFillFlex = score.clamp(0, 100).round();
  final scoreEmptyFlex = 100 - scoreFillFlex;

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      // Logo + tagline block
      pw.Row(
        children: [
          if (d.brandLogo != null)
            pw.Image(d.brandLogo!, width: 340, height: 80, fit: pw.BoxFit.contain)
          else
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                color: HamvitPdfTheme.cyan,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text('HAMVIT', style: pw.TextStyle(font: t.bold, fontSize: 18, color: PdfColors.white, letterSpacing: 2)),
            ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Spacer(),

      // User info block
      pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              children: [
                pw.Container(
                  width: 34,
                  height: 34,
                  padding: const pw.EdgeInsets.all(2),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1A3A5C),
                    borderRadius: pw.BorderRadius.circular(17),
                  ),
                  child: d.profilePhoto != null
                      ? pw.ClipOval(child: pw.Image(d.profilePhoto!, fit: pw.BoxFit.cover))
                      : pw.Center(
                          child: pw.Text(
                            d.userName.isEmpty ? 'U' : d.userName.trim().substring(0, 1).toUpperCase(),
                            style: pw.TextStyle(font: t.bold, fontSize: 12, color: PdfColors.white),
                          ),
                        ),
                ),
                pw.SizedBox(width: 10),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(d.userName, style: pw.TextStyle(font: t.bold, fontSize: 16, color: PdfColors.white)),
                    pw.Text('Período: ${_br(d.periodStart)} a ${_br(d.periodEnd)}', style: t.coverSubtitle(10)),
                    pw.Text('Gerado em: ${_br(d.generatedAt)}', style: t.coverSubtitle(10)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),

      pw.SizedBox(height: 16),

      // HAMVIT Score — large, gold
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: const PdfColor.fromInt(0xFF0B2A45),
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: const PdfColor.fromInt(0xFF1A4A78), width: 1),
        ),
        child: pw.Column(
          children: [
            pw.Text('HAMVIT SCORE', style: t.coverScoreLabel()),
            pw.SizedBox(height: 6),
            pw.Text(score.toStringAsFixed(0), style: t.coverScoreValue(48)),
            pw.SizedBox(height: 2),
            pw.Text('de 100', style: t.coverScoreLabel(9)),
            pw.SizedBox(height: 8),
            // Score progress bar
            pw.Container(
              width: double.infinity,
              height: 6,
              child: pw.Row(
                children: [
                  if (scoreFillFlex > 0)
                    pw.Expanded(
                      flex: scoreFillFlex,
                      child: pw.Container(
                        height: 6,
                        decoration: const pw.BoxDecoration(
                          color: HamvitPdfTheme.accentGold,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                      ),
                    ),
                  if (scoreEmptyFlex > 0)
                    pw.Expanded(
                      flex: scoreEmptyFlex,
                      child: pw.Container(
                        height: 6,
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF1A3A5C),
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              score >= 80
                  ? 'Excelente! Continue mantendo a consistência.'
                  : score >= 60
                      ? 'Bom progresso. Há espaço para evoluir.'
                      : 'Comece pequeno. A consistência virá com o tempo.',
              style: t.coverSubtitle(9),
            ),
          ],
        ),
      ),

      pw.SizedBox(height: 20),

      // 4 Summary Cards
      pw.Text('Resumo do Período', style: pw.TextStyle(font: t.bold, fontSize: 11, color: const PdfColor.fromInt(0xFFCFE6FA))),
      pw.SizedBox(height: 8),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _coverCard(t, d.hydrationIcon, 'Água (Média)', '${_avg(d.hydrationLogs).toStringAsFixed(0)} ml'),
          _coverCard(t, d.nutritionIcon, 'Calorias (Média)', '${_avg(d.calorieLogs).toStringAsFixed(0)} kcal'),
          pw.SizedBox(width: 6),
          _coverCard(t, d.habitsIcon, 'Hábitos', '${d.habitsConsistency.toStringAsFixed(0)}%'),
          pw.SizedBox(width: 6),
          _coverCard(t, d.sleepIcon, 'Sono (Média)', '${_avg(d.sleepLogs).toStringAsFixed(1)} h'),
        ],
      ),

      pw.SizedBox(height: 24),

      // Footer note on cover
      pw.Text('Relatório gerado automaticamente pelo HAMVIT.', style: t.coverSubtitle(8)),
      pw.Spacer(),
    ],
  );
}

pw.Widget _coverCard(HamvitPdfTheme t, pw.ImageProvider? icon, String label, String value) {
  return pw.Expanded(
    child: pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFF0B2A45),
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFF1A4A78), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (icon != null)
            pw.Image(icon, width: 18, height: 18, fit: pw.BoxFit.contain)
          else
            pw.Text(label.substring(0, 1), style: pw.TextStyle(font: t.bold, fontSize: 12, color: PdfColors.white)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(font: t.base, fontSize: 8, color: const PdfColor.fromInt(0xFFA0B8D4))),
          pw.SizedBox(height: 2),
          pw.Text(value, style: pw.TextStyle(font: t.bold, fontSize: 11, color: PdfColors.white)),
        ],
      ),
    ),
  );
}

pw.Widget _interpretationItem(HamvitPdfTheme t, String title, String text, {String? interpretation}) {
  return pw.Container(
    width: double.infinity,
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.all(10),
    decoration: t.card(),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: t.h3()),
        pw.SizedBox(height: 4),
        pw.Text(text, style: t.body()),
        if (interpretation != null) ...[
          pw.SizedBox(height: 4),
          pw.Text('Interpretação:', style: pw.TextStyle(font: t.bold, fontSize: 10, color: HamvitPdfTheme.text)),
          pw.Text(interpretation, style: t.body()),
        ],
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
// INNER PAGES — Section Builder
// ══════════════════════════════════════════════════════════════════════
List<pw.Widget> buildPdfSections(HamvitPdfTheme t, HamvitReportData d) {
  final weightDiff = (d.weightCurrent != null && d.weightInitial != null) ? (d.weightCurrent! - d.weightInitial!) : null;
  final periodText = '${_br(d.periodStart)} - ${_br(d.periodEnd)}';
  final avgSleep = _avg(d.sleepLogs);

  return [
    // ── Page Header ────────────────────────────────────────────────
    t.pageHeader('1. Resumo Executivo', periodText),
    pw.SizedBox(height: 10),

    // ── Executive Summary Metrics ──────────────────────────────────
    pw.Wrap(spacing: 8, runSpacing: 8, children: [
      metricPill(t, 'Score', d.score.toStringAsFixed(0)),
      metricPill(t, 'Peso atual', d.weightCurrent == null ? '-' : '${d.weightCurrent!.toStringAsFixed(1)} kg'),
      metricPill(t, 'IMC atual', d.bmiCurrent == null ? '-' : d.bmiCurrent!.toStringAsFixed(1)),
      metricPill(t, 'Água média', '${_avg(d.hydrationLogs).toStringAsFixed(0)} ml'),
      metricPill(t, 'Calorias médias', '${_avg(d.calorieLogs).toStringAsFixed(0)} kcal'),
      metricPill(t, 'Consistência', '${d.habitsConsistency.toStringAsFixed(0)}%'),
      metricPill(t, 'Sono médio', '${avgSleep.toStringAsFixed(1)} h'),
      metricPill(t, 'Tempo ativo', '${d.activeMinutes.toStringAsFixed(0)} min'),
    ]),
    pw.SizedBox(height: 16),

    // ── Hydration ──────────────────────────────────────────────────
    pw.NewPage(freeSpace: 360),
    pw.Column(children: [
        t.pageHeader('2. Hidratação', periodText),
        pw.SizedBox(height: 10),
        chartCard(
          t,
          title: 'Hidratação',
          subtitle: 'Média diária ${_avg(d.hydrationLogs).toStringAsFixed(0)} ml • Meta ${d.waterGoal.toStringAsFixed(0)} ml • Dias na meta ${d.waterGoalDays}',
          values: d.hydrationLogs.map((e) => e.value).toList(),
          goal: d.waterGoal,
          unit: 'ml',
          goalLabel: 'Meta diária de hidratação',
          legend: 'consumo diário de água',
          insight: d.waterGoalDays > (d.hydrationLogs.length / 2) ? 'Boa aderência de hidratação no período.' : 'A meta de hidratação pode ser reforçada ao longo do dia.',
          bars: true,
        ),
      ]),
    pw.SizedBox(height: 12),

    // ── Nutrition ──────────────────────────────────────────────────
    pw.NewPage(freeSpace: 360),
    pw.Column(children: [
        t.pageHeader('3. Nutrição', periodText),
        pw.SizedBox(height: 10),
        chartCard(
          t,
          title: 'Alimentação',
          subtitle: 'Média ${_avg(d.calorieLogs).toStringAsFixed(0)} kcal • Meta ${d.caloriesGoal.toStringAsFixed(0)} kcal',
          values: d.calorieLogs.map((e) => e.value).toList(),
          goal: d.caloriesGoal,
          unit: 'kcal',
          goalLabel: 'Meta diária de calorias',
          legend: 'ingestão calórica diária',
          insight: d.caloriesWithinGoalDays >= (d.calorieLogs.length / 2) ? 'A aderência calórica está estável.' : 'Há oscilação na aderência calórica do período.',
        ),
      ]),
    pw.SizedBox(height: 10),

    // ── Macros ─────────────────────────────────────────────────────
    macrosSegmentedBar(
      t,
      protein: d.macroAverages.protein,
      carbs: d.macroAverages.carbs,
      fat: d.macroAverages.fat,
    ),
    pw.SizedBox(height: 12),

    // ── Habits ─────────────────────────────────────────────────────
    t.pageHeader('4. Hábitos', periodText),
    pw.SizedBox(height: 10),
    pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: t.card(),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Hábitos', style: t.h2()),
        pw.SizedBox(height: 6),
        pw.Wrap(spacing: 8, runSpacing: 4, children: [
          metricPill(t, 'Total concluído', '${d.habitsCompleted}'),
          metricPill(t, 'Consistência', '${d.habitsConsistency.toStringAsFixed(0)}%'),
          metricPill(t, 'Melhor dia', d.habitLogs.isEmpty ? '-' : d.habitLogs.map((e) => e.value).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)),
        ]),
      ]),
    ),
    pw.SizedBox(height: 10),

    // ── Heatmap ────────────────────────────────────────────────────
    heatmap(t, values: d.consistencyLogs.map((e) => e.value).toList()),
    pw.SizedBox(height: 12),

    // ── Sleep ──────────────────────────────────────────────────────
    pw.NewPage(freeSpace: 360),
    pw.Column(children: [
        t.pageHeader('5. Sono', periodText),
        pw.SizedBox(height: 10),
        chartCard(
          t,
          title: 'Sono',
          subtitle: 'Média ${avgSleep.toStringAsFixed(1)} h • Meta 8.0 h',
          values: d.sleepLogs.map((e) => e.value).toList(),
          goal: 8,
          unit: 'h',
          goalLabel: 'Meta de horas de sono',
          legend: 'horas dormidas por dia',
          insight: avgSleep >= 7 ? 'O padrão de sono está consistente.' : 'Há oportunidade de ampliar o tempo médio de sono.',
        ),
      ]),
    pw.SizedBox(height: 12),

    // ── Physical Activity ─────────────────────────────────────────
    pw.NewPage(freeSpace: 360),
    pw.Column(children: [
        t.pageHeader('6. Atividade Física', periodText),
        pw.SizedBox(height: 10),
        chartCard(
          t,
          title: 'Atividade Física',
          subtitle: 'Distância ${d.distanceKm.toStringAsFixed(2)} km • Tempo ativo ${d.activeMinutes.toStringAsFixed(0)} min • Calorias ${d.activityCalories.toStringAsFixed(0)} kcal • ${d.activityCount} atividades',
          values: d.activityLogs.map((e) => e.value).toList(),
          goal: d.caloriesGoal > 0 ? d.caloriesGoal : null,
          unit: 'kcal',
          goalLabel: 'Meta calórica de atividade',
          legend: 'gasto calórico diário em atividade',
          insight: d.activityCount > 0 ? 'Boa frequência de movimento no período.' : 'Sem atividades registradas no período.',
          bars: true,
          emptyMessage: 'Sem atividades registradas no período.',
        ),
      ]),
    pw.SizedBox(height: 12),

    // ── Weight Evolution ──────────────────────────────────────────
    pw.NewPage(freeSpace: 360),
    pw.Column(children: [
        t.pageHeader('7. Evolução Corporal', periodText),
        pw.SizedBox(height: 10),
        if (d.weightLogs.where((e) => e.value > 0).isEmpty)
          fallbackCard(
            t,
            'Registre peso ao menos 2 vezes para gerar curva de evolução.',
            icon: d.fallbackIcon,
          )
        else
          chartCard(
            t,
            title: 'Evolução Corporal',
            subtitle: 'Inicial ${d.weightInitial?.toStringAsFixed(1) ?? '-'} kg • Atual ${d.weightCurrent?.toStringAsFixed(1) ?? '-'} kg • Alvo ${d.weightTarget?.toStringAsFixed(1) ?? '-'} kg • Diferença ${weightDiff == null ? '-' : weightDiff.toStringAsFixed(1)} kg',
            values: d.weightLogs.map((e) => e.value).toList(),
            goal: d.weightTarget,
            unit: 'kg',
            goalLabel: 'Peso alvo',
            legend: 'registro de peso corporal',
            insight: 'Acompanhar registros consistentes melhora a precisão das análises.',
          ),
      ]),
    pw.SizedBox(height: 12),

    // ── Timeline ──────────────────────────────────────────────────
    pw.NewPage(freeSpace: 360),
    pw.Column(children: [
        t.pageHeader('8. Progresso', periodText),
        pw.SizedBox(height: 10),
        chartCard(
          t,
          title: 'Timeline de Progresso',
          subtitle: 'Tendência de consistência por dia',
          values: d.consistencyLogs.map((e) => e.value).toList(),
          goal: 70,
          unit: 'pts',
          goalLabel: 'Meta de consistência (70 pts)',
          legend: 'pontuação diária de constância (escala 0-100)',
          insight: 'A regularidade diária influencia diretamente o score global.',
        ),
      ]),
    pw.SizedBox(height: 12),

    // ── Insights ──────────────────────────────────────────────────
    t.pageHeader('9. Insights e Recomendações', periodText),
    pw.SizedBox(height: 10),
    pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: t.card(),
      child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text('Insights', style: t.h2()),
        pw.SizedBox(height: 6),
        ...(d.insights.isEmpty
            ? [pw.Text('Sem dados suficientes neste período.', style: t.bodyMuted())]
            : d.insights.map((i) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ', style: t.body()),
                    pw.Expanded(child: pw.Text(i, style: t.body())),
                  ],
                ),
              ))),
      ]),
    ),

    // ── Interpretation Page ───────────────────────────────────────
    pw.NewPage(freeSpace: 420),
    pw.SizedBox(height: 12),
    t.pageHeader('10. Como interpretar este relatório', periodText),
    pw.SizedBox(height: 8),
    pw.Text(
      'Guia rápido dos principais indicadores utilizados no acompanhamento HAMVIT.',
      style: t.bodyMuted(),
    ),
    pw.SizedBox(height: 10),
    _interpretationItem(
      t,
      '1. HAMVIT Score',
      'Pontuação de 0 a 100 que resume a consistência geral do período, considerando hábitos, hidratação, alimentação, sono e atividade física. Deve ser interpretado como indicador de regularidade, não como diagnóstico.',
      interpretation: '0–30: baixa constância\n31–60: em desenvolvimento\n61–80: boa consistência\n81–100: excelente aderência',
    ),
    _interpretationItem(
      t,
      '2. Hidratação',
      'Representa a média diária de água registrada no período. A meta é estimada com base no peso corporal e parâmetros gerais de hidratação. Necessidades individuais podem variar conforme clima, atividade física e orientação profissional.',
    ),
    _interpretationItem(
      t,
      '3. Alimentação e calorias',
      'Mostra a ingestão calórica registrada no período em comparação com a meta estimada. Os valores são aproximações e dependem da precisão dos alimentos e porções informadas.',
    ),
    _interpretationItem(
      t,
      '4. Macronutrientes',
      'Proteínas, carboidratos e gorduras são nutrientes que contribuem para energia, manutenção muscular, saciedade e funcionamento metabólico. A distribuição ideal varia conforme objetivo, rotina e orientação profissional.',
    ),
    _interpretationItem(
      t,
      '5. Hábitos e consistência',
      'Indica a frequência com que os hábitos cadastrados foram concluídos. O foco é acompanhar regularidade e evolução gradual, sem caráter punitivo.',
    ),
    _interpretationItem(
      t,
      '6. Sono',
      'Mostra a média de horas dormidas registradas. Para adultos, recomendações gerais indicam cerca de 7 a 9 horas por noite, podendo variar conforme necessidades individuais.',
    ),
    _interpretationItem(
      t,
      '7. Atividade física',
      'Resume tempo ativo, distância e calorias estimadas. Calorias de exercício são estimativas e podem variar conforme intensidade, peso, duração, GPS, sensores e registros manuais.',
    ),
    _interpretationItem(
      t,
      '8. Evolução corporal e IMC',
      'Peso e IMC ajudam a acompanhar tendências corporais. O IMC é calculado por peso dividido pela altura ao quadrado, mas não avalia composição corporal e não substitui avaliação profissional.',
    ),
    _interpretationItem(
      t,
      '9. Timeline de progresso',
      'Mostra a tendência de consistência ao longo do período analisado, ajudando a visualizar regularidade diária e evolução comportamental.',
    ),
    _interpretationItem(
      t,
      '10. Aviso profissional',
      'Este relatório tem finalidade informativa e educativa. Ele não substitui avaliação médica, nutricional, psicológica, fisioterapêutica ou de educação física.',
    ),
    pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(10),
      decoration: t.card(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Fontes de referência:', style: t.h3()),
          pw.SizedBox(height: 4),
          pw.Text('- Organização Mundial da Saúde (OMS)', style: t.body()),
          pw.Text('- American College of Sports Medicine (ACSM)', style: t.body()),
          pw.Text('- American Academy of Sleep Medicine (AASM)', style: t.body()),
          pw.Text('- European Food Safety Authority (EFSA)', style: t.body()),
          pw.Text('- Institute of Medicine (IOM)', style: t.body()),
          pw.Text('- Academy of Nutrition and Dietetics', style: t.body()),
        ],
      ),
    ),
  ];
}
