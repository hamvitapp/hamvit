enum DashboardRange {
  sevenDays,
  fifteenDays,
  thirtyDays,
  total,
}

extension DashboardRangeX on DashboardRange {
  String get label {
    switch (this) {
      case DashboardRange.sevenDays:
        return '7 dias';
      case DashboardRange.fifteenDays:
        return '15 dias';
      case DashboardRange.thirtyDays:
        return '30 dias';
      case DashboardRange.total:
        return 'Total';
    }
  }

  int? get days {
    switch (this) {
      case DashboardRange.sevenDays:
        return 7;
      case DashboardRange.fifteenDays:
        return 15;
      case DashboardRange.thirtyDays:
        return 30;
      case DashboardRange.total:
        return null;
    }
  }
}

class DashboardSeriesPoint {
  final DateTime date;
  final double value;

  const DashboardSeriesPoint({
    required this.date,
    required this.value,
  });
}

class DashboardChartsData {
  final List<DashboardSeriesPoint> waterMl;
  final List<DashboardSeriesPoint> caloriesKcal;
  final List<DashboardSeriesPoint> habitsDone;
  final List<DashboardSeriesPoint> activityMinutes;
  final List<DashboardSeriesPoint> sleepAccumulatedHours;

  const DashboardChartsData({
    required this.waterMl,
    required this.caloriesKcal,
    required this.habitsDone,
    required this.activityMinutes,
    required this.sleepAccumulatedHours,
  });
}
