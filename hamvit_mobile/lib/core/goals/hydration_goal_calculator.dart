class HydrationGoalCalculator {
  static int calculateMl({required double weightKg}) {
    final ml = weightKg * 35;
    return _roundToNearest50(ml.round());
  }

  static int _roundToNearest50(int value) {
    final remainder = value % 50;
    if (remainder == 0) return value;
    return remainder >= 25 ? value + (50 - remainder) : value - remainder;
  }
}
