class WeightGoalEstimation {
  final double? weightDifferenceKg;
  final int? estimatedWeeks;
  final double weeklyRateKg;

  const WeightGoalEstimation({
    required this.weightDifferenceKg,
    required this.estimatedWeeks,
    this.weeklyRateKg = 0.5,
  });
}

class WeightGoalEstimator {
  static WeightGoalEstimation estimate({
    required double? currentWeightKg,
    required double? targetWeightKg,
  }) {
    if (currentWeightKg == null || targetWeightKg == null) {
      return const WeightGoalEstimation(weightDifferenceKg: null, estimatedWeeks: null);
    }

    final diff = (currentWeightKg - targetWeightKg).abs();
    if (diff == 0) {
      return const WeightGoalEstimation(weightDifferenceKg: 0, estimatedWeeks: 0);
    }

    final weeks = (diff / 0.5).ceil();
    return WeightGoalEstimation(weightDifferenceKg: diff, estimatedWeeks: weeks);
  }
}
