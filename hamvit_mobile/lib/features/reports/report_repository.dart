import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_provider.dart';
import '../dashboard/domain/chart_aggregation_service.dart';
import '../dashboard/domain/dashboard_metrics_service.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReportRepository(client);
});

enum ReportPeriodType {
  days7,
  days15,
  days30,
  all,
}

extension ReportPeriodTypeX on ReportPeriodType {
  String get label {
    switch (this) {
      case ReportPeriodType.days7:
        return '7 dias';
      case ReportPeriodType.days15:
        return '15 dias';
      case ReportPeriodType.days30:
        return '30 dias';
      case ReportPeriodType.all:
        return 'Todos';
    }
  }

  String get code {
    switch (this) {
      case ReportPeriodType.days7:
        return '7d';
      case ReportPeriodType.days15:
        return '15d';
      case ReportPeriodType.days30:
        return '30d';
      case ReportPeriodType.all:
        return 'all';
    }
  }
}

class EvolutionReportData {
  final ReportPeriodType period;
  final DateTime start;
  final DateTime end;
  final double hamvitScore;
  final double waterAverage;
  final double waterGoal;
  final int waterGoalDays;
  final double caloriesAverage;
  final double caloriesGoal;
  final int caloriesWithinGoalDays;
  final double proteinAverage;
  final double carbsAverage;
  final double fatsAverage;
  final int habitsCompleted;
  final double habitsConsistency;
  final int currentStreak;
  final double activeMinutes;
  final double distanceKm;
  final double activityCalories;
  final int activityCount;
  final double sleepAverageHours;
  final String lastSleepLabel;
  final double sleepQuality;
  final double? weightInitial;
  final double? weightCurrent;
  final double? weightTarget;
  final double? bmiInitial;
  final double? bmiCurrent;
  final double weightProgressPercent;
  final List<DashboardPoint> weightPoints;
  final List<DashboardPoint> bmiPoints;
  final List<DashboardPoint> waterPoints;
  final List<DashboardPoint> caloriesPoints;
  final List<DashboardPoint> habitsPoints;
  final List<DashboardPoint> consistencyPoints;
  final List<DashboardPoint> activityPoints;
  final List<DashboardPoint> sleepPoints;
  final List<Map<String, String>> insights;
  final Map<String, dynamic> bodyMeasures;

  const EvolutionReportData({
    required this.period,
    required this.start,
    required this.end,
    required this.hamvitScore,
    required this.waterAverage,
    required this.waterGoal,
    required this.waterGoalDays,
    required this.caloriesAverage,
    required this.caloriesGoal,
    required this.caloriesWithinGoalDays,
    required this.proteinAverage,
    required this.carbsAverage,
    required this.fatsAverage,
    required this.habitsCompleted,
    required this.habitsConsistency,
    required this.currentStreak,
    required this.activeMinutes,
    required this.distanceKm,
    required this.activityCalories,
    required this.activityCount,
    required this.sleepAverageHours,
    required this.lastSleepLabel,
    required this.sleepQuality,
    required this.weightInitial,
    required this.weightCurrent,
    required this.weightTarget,
    required this.bmiInitial,
    required this.bmiCurrent,
    required this.weightProgressPercent,
    required this.weightPoints,
    required this.bmiPoints,
    required this.waterPoints,
    required this.caloriesPoints,
    required this.habitsPoints,
    required this.consistencyPoints,
    required this.activityPoints,
    required this.sleepPoints,
    required this.insights,
    required this.bodyMeasures,
  });

  Map<String, dynamic> toSummaryJson() {
    return {
      'period': period.code,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'hamvit_score': hamvitScore,
      'water_average': waterAverage,
      'water_goal': waterGoal,
      'water_goal_days': waterGoalDays,
      'calories_average': caloriesAverage,
      'calories_goal': caloriesGoal,
      'calories_within_goal_days': caloriesWithinGoalDays,
      'protein_average': proteinAverage,
      'carbs_average': carbsAverage,
      'fats_average': fatsAverage,
      'habits_completed': habitsCompleted,
      'habits_consistency': habitsConsistency,
      'current_streak': currentStreak,
      'active_minutes': activeMinutes,
      'distance_km': distanceKm,
      'activity_calories': activityCalories,
      'activity_count': activityCount,
      'sleep_average_hours': sleepAverageHours,
      'last_sleep_label': lastSleepLabel,
      'sleep_quality': sleepQuality,
      'weight_initial': weightInitial,
      'weight_current': weightCurrent,
      'weight_target': weightTarget,
      'bmi_initial': bmiInitial,
      'bmi_current': bmiCurrent,
      'weight_progress_percent': weightProgressPercent,
      'body_measures': bodyMeasures,
      'insights': insights,
    };
  }
}

class ReportRepository {
  final SupabaseClient? _client;

  ReportRepository(this._client);

  DateTime _startOfDay(DateTime value) => DateTime(value.year, value.month, value.day);

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return _startOfDay(DateTime.now());
    final parsed = DateTime.tryParse(value.toString());
    if (parsed != null) return _startOfDay(parsed);
    return _startOfDay(DateTime.now());
  }

  List<DashboardPoint> _filterByDate(List<DashboardPoint> points, DateTime start) {
    return points.where((p) => !_startOfDay(p.date).isBefore(start)).toList(growable: false);
  }

  double? _nullablePositive(dynamic value) {
    final parsed = _toDouble(value);
    return parsed > 0 ? parsed : null;
  }

  Future<EvolutionReportData> loadEvolutionReport({required ReportPeriodType period}) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponível.');

    final user = client.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final aggregation = ChartAggregationService(client: client, userId: user.id);
    final sourcePeriod = switch (period) {
      ReportPeriodType.days7 => DashboardPeriod.days7,
      ReportPeriodType.days15 => DashboardPeriod.days30,
      ReportPeriodType.days30 => DashboardPeriod.days30,
      ReportPeriodType.all => DashboardPeriod.all,
    };

    final aggregated = await aggregation.aggregate(sourcePeriod);
    final end = _startOfDay(DateTime.now());
    final start = switch (period) {
      ReportPeriodType.days7 => end.subtract(const Duration(days: 6)),
      ReportPeriodType.days15 => end.subtract(const Duration(days: 14)),
      ReportPeriodType.days30 => end.subtract(const Duration(days: 29)),
      ReportPeriodType.all => aggregated.start,
    };

    final waterPoints = _filterByDate(aggregated.water, start);
    final caloriesPoints = _filterByDate(aggregated.calories, start);
    final habitsPoints = _filterByDate(aggregated.habits, start);
    final activityPoints = _filterByDate(aggregated.activity, start);
    final sleepPoints = _filterByDate(aggregated.sleep, start);
    var weightPoints = _filterByDate(aggregated.weight, start);
    var bmiPoints = _filterByDate(aggregated.bmi, start);
    final consistencyPoints = _filterByDate(aggregated.consistency, start);

    final validDays = math.max(1, waterPoints.length).toDouble();

    final waterGoal = aggregated.waterGoal ?? 2500;
    final caloriesGoal = aggregated.caloriesGoal ?? 2000;

    final waterAverage = waterPoints.fold<double>(0, (a, b) => a + b.value) / validDays;
    final caloriesAverage = caloriesPoints.fold<double>(0, (a, b) => a + b.value) / validDays;

    final waterGoalDays = waterPoints.where((p) => p.value >= waterGoal).length;
    final caloriesWithinGoalDays = caloriesPoints.where((p) => p.value > 0 && p.value <= caloriesGoal * 1.1).length;

    final habitsCompleted = habitsPoints.fold<double>(0, (a, b) => a + b.value).round();
    final habitsConsistency = habitsPoints.isEmpty
      ? 0.0
        : (habitsPoints.where((p) => p.value > 0).length / habitsPoints.length) * 100;

    final currentStreak = _computeCurrentStreak(habitsPoints);

    final activeMinutes = activityPoints.fold<double>(0, (a, b) => a + b.value);

    final activityMetrics = await _loadActivityMetrics(user.id, start, end);
    final sleepMetrics = await _loadSleepMetrics(user.id, start, end);
    final macroMetrics = await _loadMacroMetrics(user.id, start, end);
    final bodyMeasures = await _loadBodyMeasures(user.id);
    final prefTargetWeight = await _loadTargetWeightFromPreferences(user.id);
    final profileSnapshot = await _loadHealthProfileSnapshot(user.id);
    final targetWeight = await _loadTargetWeight(user.id) ??
        prefTargetWeight ??
        profileSnapshot.targetWeightKg ??
        _nullablePositive(bodyMeasures['target_weight_kg']) ??
        _nullablePositive(bodyMeasures['desired_weight_kg']) ??
        _nullablePositive(bodyMeasures['targetWeightKg']) ??
        _nullablePositive(bodyMeasures['desiredWeightKg']);

    if (weightPoints.where((p) => p.value > 0).isEmpty && profileSnapshot.currentWeightKg != null) {
      weightPoints = [
        DashboardPoint(date: end, value: profileSnapshot.currentWeightKg!),
      ];
    }
    if (bmiPoints.where((p) => p.value > 0).isEmpty && profileSnapshot.currentWeightKg != null && profileSnapshot.heightCm != null) {
      final heightM = profileSnapshot.heightCm! / 100.0;
      if (heightM > 0) {
        final bmi = profileSnapshot.currentWeightKg! / (heightM * heightM);
        bmiPoints = [
          DashboardPoint(date: end, value: bmi),
        ];
      }
    }

    // Seed do peso inicial para preservar histórico de partida (ex.: 172kg)
    // quando o período já contém apenas registros de evolução (ex.: 170kg).
    if (profileSnapshot.initialWeightKg != null &&
        profileSnapshot.initialWeightKg! > 0 &&
        profileSnapshot.createdAt != null) {
      final createdDay = _startOfDay(profileSnapshot.createdAt!);
      final hasInitialPoint = weightPoints.any(
        (p) => _startOfDay(p.date) == createdDay && (p.value - profileSnapshot.initialWeightKg!).abs() < 0.05,
      );
      if (!hasInitialPoint && !createdDay.isBefore(start) && !createdDay.isAfter(end)) {
        weightPoints = [
          DashboardPoint(date: createdDay, value: profileSnapshot.initialWeightKg!),
          ...weightPoints,
        ]..sort((a, b) => a.date.compareTo(b.date));

        if (profileSnapshot.heightCm != null && profileSnapshot.heightCm! > 0) {
          final hM = profileSnapshot.heightCm! / 100.0;
          final initialBmi = profileSnapshot.initialWeightKg! / (hM * hM);
          bmiPoints = [
            DashboardPoint(date: createdDay, value: initialBmi),
            ...bmiPoints,
          ]..sort((a, b) => a.date.compareTo(b.date));
        }
      }
    }

    final weightValues = weightPoints.where((p) => p.value > 0).toList(growable: false);
    final bmiValues = bmiPoints.where((p) => p.value > 0).toList(growable: false);

    final weightInitial = weightValues.isEmpty ? null : weightValues.first.value;
    final weightCurrent = weightValues.isEmpty
        ? profileSnapshot.currentWeightKg
        : weightValues.last.value;
    final bmiInitial = bmiValues.isEmpty ? null : bmiValues.first.value;
    final bmiCurrent = bmiValues.isEmpty ? null : bmiValues.last.value;

    double weightProgressPercent = 0;
    if (weightInitial != null && weightCurrent != null && targetWeight != null) {
      final denominator = (targetWeight - weightInitial).abs();
      if (denominator > 0) {
        weightProgressPercent = ((weightCurrent - weightInitial).abs() / denominator) * 100;
        weightProgressPercent = weightProgressPercent.clamp(0, 100).toDouble();
      }
    }

    final consistencyAverage = consistencyPoints.isEmpty
        ? 0.0
        : consistencyPoints.fold<double>(0, (a, b) => a + b.value) / consistencyPoints.length;

    final hamvitScore = consistencyAverage;

    final insights = _buildInsights(
      hamvitScore: hamvitScore,
      waterAverage: waterAverage,
      waterGoal: waterGoal,
      caloriesAverage: caloriesAverage,
      caloriesGoal: caloriesGoal,
      habitsConsistency: habitsConsistency,
      sleepAverage: sleepMetrics.averageHours,
      activeMinutes: activeMinutes,
    );

    return EvolutionReportData(
      period: period,
      start: start,
      end: end,
      hamvitScore: hamvitScore,
      waterAverage: waterAverage,
      waterGoal: waterGoal,
      waterGoalDays: waterGoalDays,
      caloriesAverage: caloriesAverage,
      caloriesGoal: caloriesGoal,
      caloriesWithinGoalDays: caloriesWithinGoalDays,
      proteinAverage: macroMetrics.avgProtein,
      carbsAverage: macroMetrics.avgCarbs,
      fatsAverage: macroMetrics.avgFats,
      habitsCompleted: habitsCompleted,
      habitsConsistency: habitsConsistency,
      currentStreak: currentStreak,
      activeMinutes: activeMinutes,
      distanceKm: activityMetrics.distanceKm,
      activityCalories: activityMetrics.calories,
      activityCount: activityMetrics.count,
      sleepAverageHours: sleepMetrics.averageHours,
      lastSleepLabel: sleepMetrics.lastLabel,
      sleepQuality: sleepMetrics.quality,
      weightInitial: weightInitial,
      weightCurrent: weightCurrent,
      weightTarget: targetWeight,
      bmiInitial: bmiInitial,
      bmiCurrent: bmiCurrent,
      weightProgressPercent: weightProgressPercent,
      weightPoints: weightPoints,
      bmiPoints: bmiPoints,
      waterPoints: waterPoints,
      caloriesPoints: caloriesPoints,
      habitsPoints: habitsPoints,
      consistencyPoints: consistencyPoints,
      activityPoints: activityPoints,
      sleepPoints: sleepPoints,
      insights: insights,
      bodyMeasures: bodyMeasures,
    );
  }

  Future<List<Map<String, dynamic>>> loadReportsHistory() async {
    final client = _client;
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .from('generated_reports')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    return List<Map<String, dynamic>>.from(rows.map((row) => Map<String, dynamic>.from(row as Map)));
  }

  Future<void> registerShare({
    required String reportId,
    required String channel,
    String? sharedTo,
  }) async {
    final client = _client;
    if (client == null) return;
    final user = client.auth.currentUser;
    if (user == null) return;

    await client.from('report_shares').insert({
      'report_id': reportId,
      'user_id': user.id,
      'channel': channel,
      'shared_to_email': sharedTo,
      'shared_at': DateTime.now().toIso8601String(),
    });
  }

  int _computeCurrentStreak(List<DashboardPoint> habitsPoints) {
    var streak = 0;
    for (var i = habitsPoints.length - 1; i >= 0; i--) {
      if (habitsPoints[i].value > 0) {
        streak += 1;
      } else {
        break;
      }
    }
    return streak;
  }

  Future<_ActivityMetrics> _loadActivityMetrics(String userId, DateTime start, DateTime end) async {
    final client = _client;
    if (client == null) return const _ActivityMetrics(distanceKm: 0, calories: 0, count: 0);

    try {
      final rows = await client
          .from('activity_sessions')
          .select('distance_meters, manual_distance_meters, distance_m, estimated_calories_kcal, calories_estimated, started_at')
          .eq('user_id', userId)
          .gte('started_at', start.toIso8601String())
          .lt('started_at', end.add(const Duration(days: 1)).toIso8601String());

      var distanceKm = 0.0;
      var calories = 0.0;
      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final meters = _toDouble(row['distance_meters']);
        final manualMeters = _toDouble(row['manual_distance_meters']);
        final legacyMeters = _toDouble(row['distance_m']);
        final chosenMeters = meters > 0 ? meters : (manualMeters > 0 ? manualMeters : legacyMeters);
        distanceKm += chosenMeters / 1000;
        final kcal = _toDouble(row['estimated_calories_kcal']);
        calories += kcal > 0 ? kcal : _toDouble(row['calories_estimated']);
      }

      return _ActivityMetrics(distanceKm: distanceKm, calories: calories, count: rows.length);
    } catch (_) {
      return const _ActivityMetrics(distanceKm: 0, calories: 0, count: 0);
    }
  }

  Future<_SleepMetrics> _loadSleepMetrics(String userId, DateTime start, DateTime end) async {
    final client = _client;
    if (client == null) return const _SleepMetrics(averageHours: 0, lastLabel: 'Sem registro', quality: 0);

    try {
      final rows = await client
          .from('sleep_logs')
          .select('sleep_date, duration_minutes, total_sleep_minutes, quality, sleep_quality')
          .eq('user_id', userId)
          .gte('sleep_date', start.toIso8601String().substring(0, 10))
          .lte('sleep_date', end.toIso8601String().substring(0, 10))
          .order('sleep_date', ascending: false);

      if (rows.isEmpty) {
        return const _SleepMetrics(averageHours: 0, lastLabel: 'Sem registro', quality: 0);
      }

      var totalHours = 0.0;
      var qualityTotal = 0.0;
      var qualityCount = 0;

      for (final raw in rows) {
        final row = Map<String, dynamic>.from(raw as Map);
        final minutes = _toDouble(row['duration_minutes']) + _toDouble(row['total_sleep_minutes']);
        if (minutes > 0) totalHours += minutes / 60;
        final q = _toDouble(row['quality']) > 0 ? _toDouble(row['quality']) : _toDouble(row['sleep_quality']);
        if (q > 0) {
          qualityTotal += q;
          qualityCount += 1;
        }
      }

      final latest = Map<String, dynamic>.from(rows.first as Map);
      final latestDate = _parseDate(latest['sleep_date']);

      return _SleepMetrics(
        averageHours: totalHours / math.max(1, rows.length),
        lastLabel: '${latestDate.day.toString().padLeft(2, '0')}/${latestDate.month.toString().padLeft(2, '0')}',
        quality: qualityCount == 0 ? 0 : qualityTotal / qualityCount,
      );
    } catch (_) {
      return const _SleepMetrics(averageHours: 0, lastLabel: 'Sem registro', quality: 0);
    }
  }

  Future<_MacroMetrics> _loadMacroMetrics(String userId, DateTime start, DateTime end) async {
    final client = _client;
    if (client == null) return const _MacroMetrics(avgProtein: 0, avgCarbs: 0, avgFats: 0);

    try {
      final logs = await client
          .from('meal_logs')
          .select('id, meal_date, consumed_at, created_at')
          .eq('user_id', userId)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.add(const Duration(days: 1)).toIso8601String());

      if (logs.isEmpty) return const _MacroMetrics(avgProtein: 0, avgCarbs: 0, avgFats: 0);

      final ids = logs.map((row) => (row as Map)['id']).whereType<String>().toList(growable: false);
      if (ids.isEmpty) return const _MacroMetrics(avgProtein: 0, avgCarbs: 0, avgFats: 0);

      final items = await client
          .from('meal_items')
          .select('meal_log_id, protein_g, carbs_g, fats_g')
          .inFilter('meal_log_id', ids);

      var totalProtein = 0.0;
      var totalCarbs = 0.0;
      var totalFats = 0.0;

      for (final raw in items) {
        final row = Map<String, dynamic>.from(raw as Map);
        totalProtein += _toDouble(row['protein_g']);
        totalCarbs += _toDouble(row['carbs_g']);
        totalFats += _toDouble(row['fats_g']);
      }

      final days = math.max(1, end.difference(start).inDays + 1).toDouble();

      return _MacroMetrics(
        avgProtein: totalProtein / days,
        avgCarbs: totalCarbs / days,
        avgFats: totalFats / days,
      );
    } catch (_) {
      return const _MacroMetrics(avgProtein: 0, avgCarbs: 0, avgFats: 0);
    }
  }

  Future<Map<String, dynamic>> _loadBodyMeasures(String userId) async {
    final client = _client;
    if (client == null) return const {};

    try {
      final row = await client
          .from('body_measurements')
          .select('data, logged_at')
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return const {};
      final data = row['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return const {};
    } catch (_) {
      return const {};
    }
  }

  Future<double?> _loadTargetWeight(String userId) async {
    final client = _client;
    if (client == null) return null;

    try {
        final row = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;
        final target = _toDouble(row['target_weight_kg']) > 0
            ? _toDouble(row['target_weight_kg'])
            : _toDouble(row['desired_weight_kg']);
        if (target > 0) return target;
      return null;
    } catch (_) {
      // Backward-compat for environments that still have desired_weight_kg only.
      try {
        final legacy = await client
            .from('health_profiles')
            .select('desired_weight_kg')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (legacy == null) return null;
        final desired = _toDouble(legacy['desired_weight_kg']);
        if (desired > 0) return desired;
      } catch (_) {}
      return null;
    }
  }

  Future<double?> _loadTargetWeightFromPreferences(String userId) async {
    final client = _client;
    if (client == null) return null;
    try {
      final row = await client
          .from('user_preferences')
          .select('data')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (row == null) return null;

      final data = row['data'];
      final dataMap = data is Map<String, dynamic>
          ? data
          : (data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{});
      final onboarding = dataMap['onboarding'];
      final onboardingMap = onboarding is Map<String, dynamic>
          ? onboarding
          : (onboarding is Map ? Map<String, dynamic>.from(onboarding) : <String, dynamic>{});
      final body = onboardingMap['body'];
      final bodyMap = body is Map<String, dynamic>
          ? body
          : (body is Map ? Map<String, dynamic>.from(body) : <String, dynamic>{});

      return _nullablePositive(bodyMap['target_weight_kg']) ??
          _nullablePositive(bodyMap['target_weight']) ??
          _nullablePositive(bodyMap['desired_weight_kg']) ??
          _nullablePositive(bodyMap['targetWeightKg']) ??
          _nullablePositive(bodyMap['desiredWeightKg']);
    } catch (_) {
      return null;
    }
  }

  Future<_HealthProfileSnapshot> _loadHealthProfileSnapshot(String userId) async {
    final client = _client;
    if (client == null) return const _HealthProfileSnapshot();

    try {
      final row = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final oldest = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();
      Map<String, dynamic>? oldestWeightLog;
      Map<String, dynamic>? oldestGoalHistory;
      try {
        final log = await client
            .from('weight_logs')
            .select('weight_kg, logged_at, created_at')
            .eq('user_id', userId)
            .order('logged_at', ascending: true)
            .limit(1)
            .maybeSingle();
        if (log != null) {
          oldestWeightLog = Map<String, dynamic>.from(log as Map);
        }
      } catch (_) {}
      try {
        final goalRows = await client
            .from('goal_history')
            .select('previous_weight_kg, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: true)
            .limit(1);
        if (goalRows.isNotEmpty) {
          oldestGoalHistory = Map<String, dynamic>.from(goalRows.first as Map);
        }
      } catch (_) {}
      if (row == null) return const _HealthProfileSnapshot();

      final initialWeightKg = _nullablePositive(oldest?['initial_weight_kg']) ??
          _nullablePositive(row['initial_weight_kg']) ??
          _nullablePositive(oldestGoalHistory?['previous_weight_kg']) ??
          _nullablePositive(oldest?['weight_kg']) ??
          _nullablePositive(row['weight_kg']) ??
          _nullablePositive(oldestWeightLog?['weight_kg']);
      final currentWeightKg = _nullablePositive(row['current_weight_kg']) ?? initialWeightKg;
      final heightCm = _nullablePositive(row['height_cm']);
      final targetWeightKg = _nullablePositive(row['target_weight_kg']) ?? _nullablePositive(row['desired_weight_kg']);
      final createdAt = DateTime.tryParse(((oldest?['created_at'] ?? row['created_at']) ?? '').toString());

      return _HealthProfileSnapshot(
        initialWeightKg: initialWeightKg,
        currentWeightKg: currentWeightKg,
        heightCm: heightCm,
        targetWeightKg: targetWeightKg,
        createdAt: createdAt,
      );
    } catch (_) {
      return const _HealthProfileSnapshot();
    }
  }

  List<Map<String, String>> _buildInsights({
    required double hamvitScore,
    required double waterAverage,
    required double waterGoal,
    required double caloriesAverage,
    required double caloriesGoal,
    required double habitsConsistency,
    required double sleepAverage,
    required double activeMinutes,
  }) {
    final insights = <Map<String, String>>[];

    if (hamvitScore >= 75) {
      insights.add({
        'type': 'advance',
        'title': 'Avanço de constância',
        'body': 'Seu score médio está alto no período, mostrando boa regularidade.',
      });
    } else {
      insights.add({
        'type': 'attention',
        'title': 'Pontuar pequenas vitórias',
        'body': 'Seu score ainda pode subir com registros mais constantes durante a semana.',
      });
    }

    if (waterAverage < waterGoal * 0.8) {
      insights.add({
        'type': 'attention',
        'title': 'Hidratação em atenção',
        'body': 'A média de água ficou abaixo da meta. Tente reforçar lembretes em blocos do dia.',
      });
    }

    if (caloriesAverage > caloriesGoal * 1.15) {
      insights.add({
        'type': 'attention',
        'title': 'Calorias acima da meta',
        'body': 'A média calórica está acima do objetivo. Pequenos ajustes já geram impacto.',
      });
    }

    if (habitsConsistency >= 60) {
      insights.add({
        'type': 'advance',
        'title': 'Hábitos em evolução',
        'body': 'A adesão de hábitos está consistente e isso sustenta progresso no longo prazo.',
      });
    }

    if (sleepAverage > 0 && sleepAverage < 6.5) {
      insights.add({
        'type': 'attention',
        'title': 'Sono curto no período',
        'body': 'Seu tempo médio de sono ficou abaixo do ideal. Vale priorizar rotina noturna gradual.',
      });
    }

    if (activeMinutes >= 150) {
      insights.add({
        'type': 'advance',
        'title': 'Movimento ativo',
        'body': 'Você acumulou um bom volume de tempo ativo no período selecionado.',
      });
    }

    if (insights.isEmpty) {
      insights.add({
        'type': 'baseline',
        'title': 'Continue registrando',
        'body': 'Com mais dias registrados, os insights ficam ainda mais precisos para sua rotina.',
      });
    }

    return insights;
  }
}

class _ActivityMetrics {
  final double distanceKm;
  final double calories;
  final int count;

  const _ActivityMetrics({
    required this.distanceKm,
    required this.calories,
    required this.count,
  });
}

class _SleepMetrics {
  final double averageHours;
  final String lastLabel;
  final double quality;

  const _SleepMetrics({
    required this.averageHours,
    required this.lastLabel,
    required this.quality,
  });
}

class _MacroMetrics {
  final double avgProtein;
  final double avgCarbs;
  final double avgFats;

  const _MacroMetrics({
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFats,
  });
}

class _HealthProfileSnapshot {
  final double? initialWeightKg;
  final double? currentWeightKg;
  final double? heightCm;
  final double? targetWeightKg;
  final DateTime? createdAt;

  const _HealthProfileSnapshot({
    this.initialWeightKg,
    this.currentWeightKg,
    this.heightCm,
    this.targetWeightKg,
    this.createdAt,
  });
}
