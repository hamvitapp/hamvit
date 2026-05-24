class NutritionTargetModel {
  final double bmr;
  final double tdee;
  final int caloriesKcal;
  final int proteinG;
  final int carbsG;
  final int fatG;
  final int waterMl;
  final int deficitPercent;
  final int deficitKcal;
  final double estimatedWeeklyLossKg;
  final int? estimatedWeeks;
  final double? weightDifferenceKg;
  final String source;
  final bool userAdjusted;

  const NutritionTargetModel({
    required this.bmr,
    required this.tdee,
    required this.caloriesKcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.waterMl,
    required this.deficitPercent,
    required this.deficitKcal,
    required this.estimatedWeeklyLossKg,
    required this.estimatedWeeks,
    required this.weightDifferenceKg,
    required this.source,
    required this.userAdjusted,
  });
}
