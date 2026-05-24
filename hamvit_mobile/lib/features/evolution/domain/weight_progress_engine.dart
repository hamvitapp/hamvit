import '../evolution_models.dart';

class WeightProgressSummary {
  final double? initialWeightKg;
  final double? currentWeightKg;
  final double? targetWeightKg;
  final double? differenceKg;
  final double progressPercent;
  final int daysSinceStart;

  const WeightProgressSummary({
    required this.initialWeightKg,
    required this.currentWeightKg,
    required this.targetWeightKg,
    required this.differenceKg,
    required this.progressPercent,
    required this.daysSinceStart,
  });
}

class WeightProgressEngine {
  static WeightProgressSummary build({
    required List<WeightLogEntry> logs,
    required double? fallbackCurrentWeight,
    required double? targetWeight,
  }) {
    final sortedAsc = [...logs]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    final initial = sortedAsc.isNotEmpty ? sortedAsc.first.weightKg : fallbackCurrentWeight;
    final current = sortedAsc.isNotEmpty ? sortedAsc.last.weightKg : fallbackCurrentWeight;

    final diff = (initial != null && current != null) ? (current - initial) : null;

    final days = sortedAsc.length < 2
        ? 0
        : sortedAsc.last.loggedAt.difference(sortedAsc.first.loggedAt).inDays;

    final progress = _goalProgress(
      initialWeight: initial,
      currentWeight: current,
      targetWeight: targetWeight,
    );

    return WeightProgressSummary(
      initialWeightKg: initial,
      currentWeightKg: current,
      targetWeightKg: targetWeight,
      differenceKg: diff,
      progressPercent: progress,
      daysSinceStart: days,
    );
  }

  static double _goalProgress({
    required double? initialWeight,
    required double? currentWeight,
    required double? targetWeight,
  }) {
    if (initialWeight == null || currentWeight == null || targetWeight == null) {
      return 0;
    }

    final totalNeeded = (targetWeight - initialWeight).abs();
    if (totalNeeded == 0) return 100;

    final achieved = (currentWeight - initialWeight).abs();
    final ratio = (achieved / totalNeeded).clamp(0, 1);
    return ratio * 100;
  }

  static String healthyPaceEstimate({
    required double? currentWeight,
    required double? targetWeight,
  }) {
    if (currentWeight == null || targetWeight == null) {
      return 'Estimativa disponivel apos definir peso atual e alvo.';
    }

    final delta = (currentWeight - targetWeight).abs();
    if (delta == 0) return 'Meta de peso atingida. Foque em manutencao e consistencia.';

    final weeks = (delta / 0.5).ceil();
    return 'Ritmo saudavel estimado: cerca de $weeks semanas (0,5 kg/semana).';
  }
}