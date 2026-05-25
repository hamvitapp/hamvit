class ActivityTrackingEngine {
  static double manualDistanceMeters({
    required double speedKmh,
    required int durationSeconds,
  }) {
    if (speedKmh <= 0 || durationSeconds <= 0) return 0;
    final hours = durationSeconds / 3600.0;
    return speedKmh * 1000.0 * hours;
  }

  static double averageSpeedKmh({
    required double distanceMeters,
    required int durationSeconds,
  }) {
    if (distanceMeters <= 0 || durationSeconds <= 0) return 0;
    final hours = durationSeconds / 3600.0;
    return (distanceMeters / 1000.0) / hours;
  }

  static int averagePaceSeconds({
    required double distanceMeters,
    required int durationSeconds,
  }) {
    if (distanceMeters <= 0 || durationSeconds <= 0) return 0;
    return (durationSeconds / (distanceMeters / 1000.0)).round();
  }
}

