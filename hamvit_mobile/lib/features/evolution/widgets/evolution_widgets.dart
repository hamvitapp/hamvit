import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/hamvit_date_utils.dart';
import '../../../theme/hamvit_colors.dart';
import '../domain/body_metrics_service.dart';
import '../evolution_models.dart';

class HamvitEvolutionSummaryCard extends StatelessWidget {
  final double? initialWeight;
  final double? currentWeight;
  final double? targetWeight;
  final double progressPercent;
  final double? initialBmi;
  final double? currentBmi;
  final int daysSinceStart;

  const HamvitEvolutionSummaryCard({
    super.key,
    required this.initialWeight,
    required this.currentWeight,
    required this.targetWeight,
    required this.progressPercent,
    required this.initialBmi,
    required this.currentBmi,
    required this.daysSinceStart,
  });

  @override
  Widget build(BuildContext context) {
    final delta = (initialWeight != null && currentWeight != null)
        ? (currentWeight! - initialWeight!)
        : null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3150), Color(0xFF124F6B), Color(0xFF17696A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            delta == null
                ? 'Evolucao corporal com dados reais'
                : 'Voce ja evoluiu ${delta.abs().toStringAsFixed(1)} kg desde o inicio.',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _metric('Peso inicial', _f(initialWeight, 'kg')),
              _metric('Peso atual', _f(currentWeight, 'kg')),
              _metric('Peso alvo', _f(targetWeight, 'kg')),
              _metric('Progresso', '${progressPercent.toStringAsFixed(0)}%'),
              _metric('IMC inicial', initialBmi == null ? '--' : initialBmi!.toStringAsFixed(1)),
              _metric('IMC atual', currentBmi == null ? '--' : currentBmi!.toStringAsFixed(1)),
              _metric('Tempo', '$daysSinceStart dias'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
        ],
      ),
    );
  }

  String _f(double? value, String suffix) => value == null ? '--' : '${value.toStringAsFixed(1)} $suffix';
}

class HamvitWeightChart extends StatelessWidget {
  final List<WeightLogEntry> logs;

  const HamvitWeightChart({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('Sem dados de peso para o periodo selecionado.'),
        ),
      );
    }

    final asc = [...logs]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final spots = <FlSpot>[];
    for (var i = 0; i < asc.length; i++) {
      spots.add(FlSpot(i.toDouble(), asc[i].weightKg));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evolucao de peso', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, horizontalInterval: 1),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: (spots.length / 4).clamp(1, 999).toDouble(),
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= asc.length) return const SizedBox.shrink();
                          return Text(
                            HamvitDateUtils.formatDateBr(asc[idx].loggedAt).substring(0, 5),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 34),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: HamvitColors.accentCyan,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            HamvitColors.accentCyan.withValues(alpha: 0.25),
                            HamvitColors.accentCyan.withValues(alpha: 0.03),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitBMIHistoryCard extends StatelessWidget {
  final double? initialBmi;
  final double? currentBmi;
  final String classification;

  const HamvitBMIHistoryCard({
    super.key,
    required this.initialBmi,
    required this.currentBmi,
    required this.classification,
  });

  @override
  Widget build(BuildContext context) {
    final delta = (initialBmi != null && currentBmi != null) ? (currentBmi! - initialBmi!) : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Evolucao de IMC', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('IMC atual: ${currentBmi?.toStringAsFixed(1) ?? '--'}'),
            Text('IMC inicial: ${initialBmi?.toStringAsFixed(1) ?? '--'}'),
            Text('Diferenca: ${delta == null ? '--' : delta.toStringAsFixed(1)}'),
            Text('Classificacao atual: $classification'),
            const SizedBox(height: 6),
            Text(
              delta == null
                  ? 'Registre mais pesagens para acompanhar seu IMC historico.'
                  : (delta < 0 ? 'Seu IMC reduziu desde o inicio.' : 'Seu IMC evoluiu no periodo analisado.'),
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitGoalProgressCard extends StatelessWidget {
  final double? currentWeight;
  final double? targetWeight;
  final double progressPercent;
  final String healthyEstimate;

  const HamvitGoalProgressCard({
    super.key,
    required this.currentWeight,
    required this.targetWeight,
    required this.progressPercent,
    required this.healthyEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (currentWeight != null && targetWeight != null)
        ? (currentWeight! - targetWeight!).abs()
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Progresso do objetivo', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Peso atual: ${currentWeight?.toStringAsFixed(1) ?? '--'} kg'),
            Text('Peso desejado: ${targetWeight?.toStringAsFixed(1) ?? '--'} kg'),
            Text('Quanto falta: ${remaining?.toStringAsFixed(1) ?? '--'} kg'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: (progressPercent / 100).clamp(0, 1),
              ),
            ),
            const SizedBox(height: 8),
            Text('Voce ja atingiu ${progressPercent.toStringAsFixed(0)}% do seu objetivo.'),
            const SizedBox(height: 4),
            Text(healthyEstimate, style: const TextStyle(color: HamvitColors.darkTextMuted)),
          ],
        ),
      ),
    );
  }
}

class HamvitWeightHistoryList extends StatelessWidget {
  final List<WeightLogEntry> logs;

  const HamvitWeightHistoryList({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(12), child: Text('Sem pesagens registradas ainda.')));
    }

    final sorted = [...logs]..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Historico de pesagens', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...List.generate(sorted.length, (index) {
              final item = sorted[index];
              final prev = index + 1 < sorted.length ? sorted[index + 1] : null;
              final variation = prev == null ? null : item.weightKg - prev.weightKg;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(HamvitDateUtils.formatDateBr(item.loggedAt)),
                    ),
                    Expanded(child: Text('${item.weightKg.toStringAsFixed(1)} kg')),
                    SizedBox(
                      width: 72,
                      child: Text(variation == null ? '--' : '${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(1)} kg'),
                    ),
                    SizedBox(
                      width: 68,
                      child: Text(item.bmi == null ? '--' : 'IMC ${item.bmi!.toStringAsFixed(1)}'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class HamvitProgressPhotosCard extends StatelessWidget {
  final List<ProgressPhotoEntry> photos;
  final VoidCallback onOpen;

  const HamvitProgressPhotosCard({
    super.key,
    required this.photos,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Fotos corporais', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Acompanhe sua evolucao no seu ritmo.'),
            const SizedBox(height: 8),
            if (photos.isEmpty)
              const Text('Sem fotos registradas ainda.')
            else
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(photo.imageUrl),
                        width: 86,
                        height: 86,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 86,
                          height: 86,
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemCount: photos.length.clamp(0, 8),
                ),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Gerenciar fotos'),
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitEvolutionInsightsCard extends StatelessWidget {
  final List<String> insights;

  const HamvitEvolutionInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Insights', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (insights.isEmpty)
              const Text('Registre mais dados para gerar insights personalizados.')
            else
              ...insights.map(
                (insight) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $insight'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HamvitAddWeightButton extends StatelessWidget {
  final VoidCallback onPressed;

  const HamvitAddWeightButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.monitor_weight_outlined),
        label: const Text('Registrar peso'),
      ),
    );
  }
}

class HamvitBodyMeasurementsCard extends StatelessWidget {
  final List<BodyMetricsDelta> deltas;
  final int totalEntries;
  final VoidCallback onAdd;

  const HamvitBodyMeasurementsCard({
    super.key,
    required this.deltas,
    required this.totalEntries,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Medidas corporais', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Registros: $totalEntries'),
            const SizedBox(height: 8),
            if (deltas.isEmpty)
              const Text('Sem medidas registradas ainda.')
            else
              ...deltas.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    d.change == null
                        ? '${d.label}: sem dados suficientes'
                        : '${d.label}: ${d.latest!.toStringAsFixed(1)} cm (${d.change! >= 0 ? '+' : ''}${d.change!.toStringAsFixed(1)} cm)',
                  ),
                ),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.straighten_outlined),
              label: const Text('Registrar medidas'),
            ),
          ],
        ),
      ),
    );
  }
}