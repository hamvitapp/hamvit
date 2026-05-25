class CalorieEstimationService {
  static double estimateCalories({
    required double met,
    required double weightKg,
    required int durationSeconds,
  }) {
    if (weightKg <= 0 || durationSeconds <= 0) return 0;
    final hours = durationSeconds / 3600.0;
    return met * weightKg * hours;
  }

  static double metForIndoor({
    required String activityType,
    required double speedKmh,
  }) {
    final type = activityType.toLowerCase();
    if (type.contains('esteira')) {
      if (speedKmh >= 9) return 9.0;
      if (speedKmh >= 7) return 7.0;
      if (speedKmh >= 5.5) return 4.3;
      return 3.5;
    }
    if (type.contains('corrida')) {
      if (speedKmh >= 10) return 9.0;
      if (speedKmh >= 8) return 8.0;
      return 7.0;
    }
    if (type.contains('bicicleta')) {
      if (speedKmh >= 26) return 10.0;
      if (speedKmh >= 20) return 8.0;
      return 6.8;
    }
    if (speedKmh >= 6) return 4.3;
    return 3.5;
  }
}

