import 'calorie_goal_calculator.dart';
import 'hydration_goal_calculator.dart';
import 'nutrition_target_model.dart';
import 'weight_goal_estimator.dart';

class GoalCalculationEngineInput {
  final double? weightKg;
  final double? targetWeightKg;
  final int? heightCm;
  final int? ageYears;
  final String? biologicalSex;
  final String? activityLevel;
  final String? objective;
  final String source;
  final bool userAdjusted;

  const GoalCalculationEngineInput({
    required this.weightKg,
    required this.targetWeightKg,
    required this.heightCm,
    required this.ageYears,
    required this.biologicalSex,
    required this.activityLevel,
    required this.objective,
    this.source = 'system_calculated',
    this.userAdjusted = false,
  });
}

class GoalCalculationEngine {
  static NutritionTargetModel? calculate(GoalCalculationEngineInput input) {
    if (input.weightKg == null || input.heightCm == null) {
      return null;
    }

    final age = input.ageYears ?? 30;

    final calorie = CalorieGoalCalculator.calculate(
      CalorieGoalInput(
        weightKg: input.weightKg!,
        heightCm: input.heightCm!,
        ageYears: age,
        biologicalSex: (input.biologicalSex ?? 'não informado'),
        activityLevel: (input.activityLevel ?? 'leve'),
        objective: (input.objective ?? ''),
      ),
    );

    final waterMl = HydrationGoalCalculator.calculateMl(weightKg: input.weightKg!);
    final estimation = WeightGoalEstimator.estimate(
      currentWeightKg: input.weightKg,
      targetWeightKg: input.targetWeightKg,
    );

    final protein = (input.weightKg! * 1.8).round();
    final fat = ((calorie.caloriesTarget * 0.25) / 9).round();
    final carbs = ((calorie.caloriesTarget - (protein * 4) - (fat * 9)) / 4).round();

    return NutritionTargetModel(
      bmr: calorie.bmr,
      tdee: calorie.tdee,
      caloriesKcal: calorie.caloriesTarget,
      proteinG: protein,
      carbsG: carbs < 0 ? 0 : carbs,
      fatG: fat,
      waterMl: waterMl,
      deficitPercent: calorie.deficitPercent,
      deficitKcal: calorie.deficitKcal,
      estimatedWeeklyLossKg: 0.5,
      estimatedWeeks: estimation.estimatedWeeks,
      weightDifferenceKg: estimation.weightDifferenceKg,
      source: input.source,
      userAdjusted: input.userAdjusted,
    );
  }
}
