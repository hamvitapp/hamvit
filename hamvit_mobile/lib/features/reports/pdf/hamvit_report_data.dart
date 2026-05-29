import 'package:pdf/widgets.dart' as pw;

class DateValue {
  final DateTime date;
  final double value;
  const DateValue(this.date, this.value);
}

class MacroShare {
  final double protein;
  final double carbs;
  final double fat;
  const MacroShare({
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}

class HamvitReportData {
  final String userName;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double score;

  final List<DateValue> weightLogs;
  final List<DateValue> bmiLogs;
  final List<DateValue> hydrationLogs;
  final List<DateValue> calorieLogs;
  final MacroShare macroAverages;
  final List<DateValue> sleepLogs;
  final List<DateValue> activityLogs;
  final List<DateValue> habitLogs;
  final List<DateValue> consistencyLogs;
  final List<String> insights;
  final DateTime generatedAt;

  final double? weightInitial;
  final double? weightCurrent;
  final double? weightTarget;
  final double? bmiCurrent;
  final double waterGoal;
  final double caloriesGoal;
  final int waterGoalDays;
  final int caloriesWithinGoalDays;
  final int habitsCompleted;
  final double habitsConsistency;
  final double sleepAverageHours;
  final double activeMinutes;
  final double distanceKm;
  final double activityCalories;
  final int activityCount;
  final pw.ImageProvider? brandLogo;
  final pw.ImageProvider? profilePhoto;
  final pw.ImageProvider? hydrationIcon;
  final pw.ImageProvider? nutritionIcon;
  final pw.ImageProvider? habitsIcon;
  final pw.ImageProvider? sleepIcon;
  final pw.ImageProvider? fallbackIcon;

  const HamvitReportData({
    required this.userName,
    required this.periodStart,
    required this.periodEnd,
    required this.score,
    required this.weightLogs,
    required this.bmiLogs,
    required this.hydrationLogs,
    required this.calorieLogs,
    required this.macroAverages,
    required this.sleepLogs,
    required this.activityLogs,
    required this.habitLogs,
    required this.consistencyLogs,
    required this.insights,
    required this.generatedAt,
    required this.weightInitial,
    required this.weightCurrent,
    required this.weightTarget,
    required this.bmiCurrent,
    required this.waterGoal,
    required this.caloriesGoal,
    required this.waterGoalDays,
    required this.caloriesWithinGoalDays,
    required this.habitsCompleted,
    required this.habitsConsistency,
    required this.sleepAverageHours,
    required this.activeMinutes,
    required this.distanceKm,
    required this.activityCalories,
    required this.activityCount,
    this.brandLogo,
    this.profilePhoto,
    this.hydrationIcon,
    this.nutritionIcon,
    this.habitsIcon,
    this.sleepIcon,
    this.fallbackIcon,
  });
}
