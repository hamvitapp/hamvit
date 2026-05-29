import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';
import '../privacy/app_blur_overlay.dart';
import '../security/biometric_gate.dart';
import '../auth/providers/auth_provider.dart';
import '../dashboard/domain/dashboard_metrics_service.dart';
import 'report_controller.dart';
import 'report_pdf_service.dart';
import 'report_period_selector.dart';
import 'report_repository.dart';

class EvolutionReportScreen extends ConsumerStatefulWidget {
  const EvolutionReportScreen({super.key});

  @override
  ConsumerState<EvolutionReportScreen> createState() => _EvolutionReportScreenState();
}

class _EvolutionReportScreenState extends ConsumerState<EvolutionReportScreen> {
  bool _loadingPdf = false;

  String _date(DateTime value) => DateFormat('dd/MM/yyyy', 'pt_BR').format(value.toLocal());

  String _periodLabel(EvolutionReportData data) => '${_date(data.start)} a ${_date(data.end)}';

  Future<void> _downloadPdf(EvolutionReportData data) async {
    final allowed = await requireBiometricForAction(
      context,
      ref,
      reason: 'Confirme sua biometria para gerar o PDF do relatório.',
    );
    if (!allowed) return;

    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        useSafeArea: true,
        builder: (_) => const PremiumTeaserCard(feature: HamvitFeature.reportsPdfExport),
      );
      return;
    }

    setState(() => _loadingPdf = true);
    try {
      final profile = ref.read(currentProfileProvider);
      final pdf = await ref.read(reportPdfServiceProvider).generateEvolutionPdf(
            data: data,
            userName: profile?.displayName ?? 'Usuário HAMVIT',
          );

      await ref.read(reportPdfServiceProvider).sharePdf(
            bytes: pdf.bytes,
            filename: 'relatorio_acompanhamento_hamvit_${data.period.code}.pdf',
          );

      if (pdf.reportId != null) {
        await ref.read(reportRepositoryProvider).registerShare(
              reportId: pdf.reportId!,
              channel: 'share_sheet',
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relatório PDF gerado e pronto para compartilhamento.')),
      );
      ref.invalidate(reportHistoryProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível gerar o PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingPdf = false);
    }
  }

  Future<void> _sendToProfessional(EvolutionReportData data) async {
    final allowed = await requireBiometricForAction(
      context,
      ref,
      reason: 'Confirme sua biometria para compartilhar relatório com profissional.',
    );
    if (!allowed) return;

    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        useSafeArea: true,
        builder: (_) => const PremiumTeaserCard(feature: HamvitFeature.reportsSharing),
      );
      return;
    }

    setState(() => _loadingPdf = true);
    try {
      final profile = ref.read(currentProfileProvider);
      final pdf = await ref.read(reportPdfServiceProvider).generateEvolutionPdf(
            data: data,
            userName: profile?.displayName ?? 'Usuário HAMVIT',
          );

      await ref.read(reportPdfServiceProvider).sharePdf(
            bytes: pdf.bytes,
            filename: 'relatorio_hamvit_profissional_${data.period.code}.pdf',
          );

      if (pdf.reportId != null) {
        await ref.read(reportRepositoryProvider).registerShare(
              reportId: pdf.reportId!,
              channel: 'nutritionist_share',
            );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compartilhamento iniciado pelo Share Sheet.')),
      );
      ref.invalidate(reportHistoryProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível compartilhar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final reportAsync = ref.watch(evolutionReportProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return HamvitBiometricGate(
      reason: 'Confirme sua biometria para acessar o relatório de evolução.',
      child: HamvitProtectedScreenWrapper(
        child: Scaffold(
        appBar: AppBar(title: const Text('Relatório de evolução')),
        body: SafeArea(
          child: reportAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Falha ao carregar relatório: $error'),
            ),
          ),
          data: (data) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                HamvitReportSection(
                  title: 'Período',
                  subtitle: _periodLabel(data),
                  child: HamvitReportPeriodSelector(
                    selected: period,
                    onChanged: (value) {
                      ref.read(reportPeriodProvider.notifier).state = value;
                    },
                  ),
                ),
                HamvitReportSummaryCard(data: data),
                HamvitReportSection(
                  title: 'Evolução corporal',
                  child: Column(
                    children: [
                      _kv('Peso inicial', data.weightInitial == null ? '-' : '${data.weightInitial!.toStringAsFixed(1)} kg'),
                      _kv('Peso atual', data.weightCurrent == null ? '-' : '${data.weightCurrent!.toStringAsFixed(1)} kg'),
                      _kv(
                        'Peso alvo',
                        () {
                          final fallback = (data.bodyMeasures['target_weight_kg'] ??
                                  data.bodyMeasures['desired_weight_kg'] ??
                                  data.bodyMeasures['targetWeightKg'] ??
                                  data.bodyMeasures['desiredWeightKg'])
                              ?.toString();
                          final fallbackNum = fallback == null ? null : double.tryParse(fallback.replaceAll(',', '.'));
                          final target = data.weightTarget ?? (fallbackNum != null && fallbackNum > 0 ? fallbackNum : null);
                          return target == null ? '-' : '${target.toStringAsFixed(1)} kg';
                        }(),
                      ),
                      _kv('Progresso', '${data.weightProgressPercent.toStringAsFixed(0)}%'),
                      _kv('IMC inicial', data.bmiInitial == null ? '-' : data.bmiInitial!.toStringAsFixed(1)),
                      _kv('IMC atual', data.bmiCurrent == null ? '-' : data.bmiCurrent!.toStringAsFixed(1)),
                      const SizedBox(height: 8),
                      HamvitReportChartCard(title: 'Peso', points: data.weightPoints, color: const Color(0xFF00B7D8)),
                      const SizedBox(height: 8),
                      HamvitReportChartCard(title: 'IMC', points: data.bmiPoints, color: const Color(0xFF38D39F)),
                    ],
                  ),
                ),
                HamvitReportSection(
                  title: 'Alimentação',
                  child: Column(
                    children: [
                      _kv('Calorias médias', '${data.caloriesAverage.toStringAsFixed(0)} kcal'),
                      _kv('Meta calórica', '${data.caloriesGoal.toStringAsFixed(0)} kcal'),
                      _kv('Dias dentro da meta', '${data.caloriesWithinGoalDays}'),
                      _kv('Proteínas (média)', '${data.proteinAverage.toStringAsFixed(1)} g'),
                      _kv('Carboidratos (média)', '${data.carbsAverage.toStringAsFixed(1)} g'),
                      _kv('Gorduras (média)', '${data.fatsAverage.toStringAsFixed(1)} g'),
                      const SizedBox(height: 8),
                      HamvitReportChartCard(title: 'Calorias', points: data.caloriesPoints, color: const Color(0xFF3EA7FF)),
                    ],
                  ),
                ),
                HamvitReportSection(
                  title: 'Hidratação',
                  child: Column(
                    children: [
                      _kv('Média diária', '${data.waterAverage.toStringAsFixed(0)} ml'),
                      _kv('Meta diária', '${data.waterGoal.toStringAsFixed(0)} ml'),
                      _kv('Dias com meta atingida', '${data.waterGoalDays}'),
                      const SizedBox(height: 8),
                      HamvitReportChartCard(title: 'Água', points: data.waterPoints, color: const Color(0xFF00B7D8)),
                    ],
                  ),
                ),
                HamvitReportSection(
                  title: 'Hábitos',
                  child: Column(
                    children: [
                      _kv('Hábitos concluídos', '${data.habitsCompleted}'),
                      _kv('Consistência', '${data.habitsConsistency.toStringAsFixed(0)}%'),
                      _kv('Streak atual', '${data.currentStreak} dia(s)'),
                      const SizedBox(height: 8),
                      HamvitReportChartCard(title: 'Hábitos', points: data.habitsPoints, color: const Color(0xFF4FD1C5)),
                      const SizedBox(height: 8),
                      _ConsistencyHeatmap(points: data.consistencyPoints),
                    ],
                  ),
                ),
                HamvitReportSection(
                  title: 'Atividades físicas',
                  child: Column(
                    children: [
                      _kv('Tempo ativo', '${data.activeMinutes.toStringAsFixed(0)} min'),
                      _kv('Distância', '${data.distanceKm.toStringAsFixed(2)} km'),
                      _kv('Calorias estimadas', '${data.activityCalories.toStringAsFixed(0)} kcal'),
                      _kv('Quantidade de atividades', '${data.activityCount}'),
                      const SizedBox(height: 8),
                      HamvitReportChartCard(title: 'Atividade', points: data.activityPoints, color: const Color(0xFF7AC5FF)),
                    ],
                  ),
                ),
                HamvitReportSection(
                  title: 'Sono',
                  child: Column(
                    children: [
                      _kv('Média de sono', '${data.sleepAverageHours.toStringAsFixed(1)} h'),
                      _kv('Último registro', data.lastSleepLabel),
                      _kv('Qualidade média', data.sleepQuality == 0 ? '-' : data.sleepQuality.toStringAsFixed(1)),
                      const SizedBox(height: 8),
                      HamvitReportChartCard(title: 'Sono', points: data.sleepPoints, color: const Color(0xFF9B8CFF)),
                    ],
                  ),
                ),
                HamvitReportSection(
                  title: 'Insights',
                  child: Column(
                    children: [
                      for (final insight in data.insights)
                        HamvitReportInsightCard(
                          title: insight['title'] ?? '-',
                          body: insight['body'] ?? '-',
                        ),
                    ],
                  ),
                ),
                HamvitReportActionBar(
                  loading: _loadingPdf,
                  onDownloadPdf: () => _downloadPdf(data),
                  onSendToProfessional: () => _sendToProfessional(data),
                  onHistory: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    } else {
                      context.push('/reports');
                    }
                  },
                  isPremium: isPremium,
                ),
                if (!isPremium) ...[
                  const SizedBox(height: 8),
                  const PremiumTeaserCard(feature: HamvitFeature.reportsPdfExport),
                ],
              ],
            );
          },
          ),
        ),
        ),
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class HamvitReportSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const HamvitReportSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class HamvitReportSummaryCard extends StatelessWidget {
  final EvolutionReportData data;

  const HamvitReportSummaryCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final weightDelta = ((data.weightCurrent ?? 0) - (data.weightInitial ?? 0));
    final interpretation = data.hamvitScore >= 70
        ? 'Você manteve uma constância sólida no período analisado.'
        : 'Seu relatório indica espaço para evoluir com pequenas ações consistentes.';

    return HamvitReportSection(
      title: 'Resumo executivo',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _chip('HAMVIT Score', data.hamvitScore.toStringAsFixed(0))),
              const SizedBox(width: 8),
              Expanded(child: _chip('Evolução de peso', '${weightDelta.toStringAsFixed(1)} kg')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _chip('Adesão hábitos', '${data.habitsConsistency.toStringAsFixed(0)}%')),
              const SizedBox(width: 8),
              Expanded(child: _chip('Água média', '${data.waterAverage.toStringAsFixed(0)} ml')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _chip('Média calórica', '${data.caloriesAverage.toStringAsFixed(0)} kcal')),
              const SizedBox(width: 8),
              Expanded(child: _chip('Tempo ativo', '${data.activeMinutes.toStringAsFixed(0)} min')),
            ],
          ),
          const SizedBox(height: 10),
          Text(interpretation),
        ],
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class HamvitReportChartCard extends StatelessWidget {
  final String title;
  final List<DashboardPoint> points;
  final Color color;

  const HamvitReportChartCard({
    super.key,
    required this.title,
    required this.points,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final visible = points.where((p) => p.value > 0).toList(growable: false);
    if (visible.length < 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Text('$title sem dados no período.'),
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value));
    }

    final maxY = visible.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.2;

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY <= 1 ? 1 : maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 0 ? 1 : (maxY / 4).clamp(1, 99999),
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.08),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipRoundedRadius: 8,
              getTooltipItems: (touched) {
                return touched
                    .map((item) => LineTooltipItem(
                          item.y.toStringAsFixed(1),
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ))
                    .toList(growable: false);
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 3,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.20), color.withValues(alpha: 0.03)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitReportInsightCard extends StatelessWidget {
  final String title;
  final String body;

  const HamvitReportInsightCard({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
    );
  }
}

class HamvitPdfDownloadButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const HamvitPdfDownloadButton({
    super.key,
    required this.onPressed,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: const Text('Baixar PDF'),
    );
  }
}

class HamvitReportActionBar extends StatelessWidget {
  final VoidCallback onDownloadPdf;
  final VoidCallback onSendToProfessional;
  final VoidCallback onHistory;
  final bool loading;
  final bool isPremium;

  const HamvitReportActionBar({
    super.key,
    required this.onDownloadPdf,
    required this.onSendToProfessional,
    required this.onHistory,
    required this.loading,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    return HamvitReportSection(
      title: 'Ações',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: HamvitPdfDownloadButton(
                  onPressed: onDownloadPdf,
                  loading: loading,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: loading ? null : onSendToProfessional,
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Enviar ao nutricionista/médico'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onHistory,
                  icon: const Icon(Icons.history_outlined),
                  label: const Text('Ver histórico'),
                ),
              ),
            ],
          ),
          if (!isPremium) ...[
            const SizedBox(height: 8),
            const Text(
              'No plano Free você visualiza o relatório em tela. PDF e compartilhamento profissional estão no Premium Vitalício.',
            ),
          ],
        ],
      ),
    );
  }
}

class _ConsistencyHeatmap extends StatelessWidget {
  final List<DashboardPoint> points;

  const _ConsistencyHeatmap({required this.points});

  @override
  Widget build(BuildContext context) {
    final values = points.isEmpty
        ? List<double>.filled(14, 0)
        : points.map((e) => e.value).toList(growable: false);

    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: values.take(28).map((value) {
        final opacity = (value / 100).clamp(0.08, 1.0);
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF00B7D8).withValues(alpha: opacity),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }).toList(growable: false),
    );
  }
}
