class CalorieGoalInput {
  final double weightKg;
  final int heightCm;
  final int ageYears;
  final String biologicalSex;
  final String activityLevel;
  final String objective;

  const CalorieGoalInput({
    required this.weightKg,
    required this.heightCm,
    required this.ageYears,
    required this.biologicalSex,
    required this.activityLevel,
    required this.objective,
  });
}

class CalorieGoalResult {
  final double bmr;
  final double tdee;
  final int caloriesTarget;
  final int deficitPercent;
  final int deficitKcal;

  const CalorieGoalResult({
    required this.bmr,
    required this.tdee,
    required this.caloriesTarget,
    required this.deficitPercent,
    required this.deficitKcal,
  });
}

class CalorieGoalCalculator {
  static CalorieGoalResult calculate(CalorieGoalInput input) {
    final bmr = _calculateBmr(input);
    final tdee = bmr * _activityFactor(input.activityLevel);

    final deficitPercent = _deficitPercentForObjective(input.objective);
    final rawTarget = tdee * (1 - (deficitPercent / 100));
    final minSafe = _minimumSafeCalories(input.biologicalSex);
    final safeTarget = rawTarget < minSafe ? minSafe : rawTarget;

    return CalorieGoalResult(
      bmr: bmr,
      tdee: tdee,
      caloriesTarget: safeTarget.round(),
      deficitPercent: deficitPercent,
      deficitKcal: (tdee - safeTarget).round(),
    );
  }

  static double _calculateBmr(CalorieGoalInput input) {
    final sex = input.biologicalSex.toLowerCase();
    final male = 10 * input.weightKg + 6.25 * input.heightCm - 5 * input.ageYears + 5;
    final female = 10 * input.weightKg + 6.25 * input.heightCm - 5 * input.ageYears - 161;

    if (sex == 'masculino') return male;
    if (sex == 'feminino') return female;
    return (male + female) / 2;
  }

  static double _activityFactor(String activityLevel) {
    final level = activityLevel.toLowerCase();
    if (level.contains('sedent')) return 1.2;
    if (level.contains('leve')) return 1.375;
    if (level.contains('moder')) return 1.55;
    if (level.contains('alta') || level.contains('muito')) return 1.725;
    return 1.375;
  }

  static int _deficitPercentForObjective(String objective) {
    final normalized = objective.toLowerCase();
    if (normalized.contains('emagrec')) return 15;
    if (normalized.contains('massa')) return 0;
    if (normalized.contains('manter')) return 0;
    return 10;
  }

  static int _minimumSafeCalories(String biologicalSex) {
    final sex = biologicalSex.toLowerCase();
    if (sex == 'feminino') return 1200;
    if (sex == 'masculino') return 1500;
    return 1400;
  }
}
