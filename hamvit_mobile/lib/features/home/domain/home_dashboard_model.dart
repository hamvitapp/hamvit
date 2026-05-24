class HomeDashboardModel {
  final DateTime referenceDate;
  final int waterMl;
  final int waterGoalMl;
  final int calories;
  final int? caloriesGoal;
  final int habitsDone;
  final int habitsTotal;
  final int? stepsToday;
  final double distanceKm;
  final int activeMinutes;
  final double? sleepHours;
  final int score;
  final int dayCompletionPercent;
  final String statusText;
  final String primaryInsight;
  final String? secondaryInsight;
  final List<double> trend;
  final bool isOffline;
  final String? warningMessage;

  const HomeDashboardModel({
    required this.referenceDate,
    required this.waterMl,
    required this.waterGoalMl,
    required this.calories,
    required this.caloriesGoal,
    required this.habitsDone,
    required this.habitsTotal,
    required this.stepsToday,
    required this.distanceKm,
    required this.activeMinutes,
    required this.sleepHours,
    required this.score,
    required this.dayCompletionPercent,
    required this.statusText,
    required this.primaryInsight,
    required this.secondaryInsight,
    required this.trend,
    this.isOffline = false,
    this.warningMessage,
  });

  DateTime get date => referenceDate;
  int get waterConsumedMl => waterMl;
  int get waterGoalMlValue => waterGoalMl;
  int get caloriesConsumedKcal => calories;
  int? get calorieGoalKcal => caloriesGoal;
  int get habitsCompleted => habitsDone;
  int get stepsTodayValue => stepsToday ?? 0;
  double get distanceTodayKm => distanceKm;
  int get activeMinutesToday => activeMinutes;
  double get sleepHoursLastNight => sleepHours ?? 0;
  int get dailyScorePercent => score;
  List<String> get insights => [
        primaryInsight,
        if (secondaryInsight != null && secondaryInsight!.trim().isNotEmpty) secondaryInsight!,
      ];

  bool get isEmpty {
    final hasWater = waterMl > 0;
    final hasCalories = calories > 0;
    final hasHabits = habitsDone > 0;
    final hasActivity = distanceKm > 0 || activeMinutes > 0;
    final hasSleep = (sleepHours ?? 0) > 0;
    return !(hasWater || hasCalories || hasHabits || hasActivity || hasSleep);
  }

  HomeDashboardModel copyWith({
    bool? isOffline,
    String? warningMessage,
  }) {
    return HomeDashboardModel(
      referenceDate: referenceDate,
      waterMl: waterMl,
      waterGoalMl: waterGoalMl,
      calories: calories,
      caloriesGoal: caloriesGoal,
      habitsDone: habitsDone,
      habitsTotal: habitsTotal,
      stepsToday: stepsToday,
      distanceKm: distanceKm,
      activeMinutes: activeMinutes,
      sleepHours: sleepHours,
      score: score,
      dayCompletionPercent: dayCompletionPercent,
      statusText: statusText,
      primaryInsight: primaryInsight,
      secondaryInsight: secondaryInsight,
      trend: trend,
      isOffline: isOffline ?? this.isOffline,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }
}
