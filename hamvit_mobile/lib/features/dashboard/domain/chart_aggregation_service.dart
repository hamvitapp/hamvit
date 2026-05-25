import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hamvit_date_utils.dart';
import 'dashboard_metrics_service.dart';

class ChartAggregationResult {
  final DateTime start;
  final DateTime end;
  final List<DashboardPoint> water;
  final List<DashboardPoint> calories;
  final List<DashboardPoint> habits;
  final List<DashboardPoint> activity;
  final List<DashboardPoint> sleep;
  final List<DashboardPoint> weight;
  final List<DashboardPoint> bmi;
  final List<DashboardPoint> consistency;
  final double? waterGoal;
  final double? caloriesGoal;
  final double? habitsGoal;
  final double? activityGoal;
  final double? sleepGoal;
  final double? weightGoal;
  final double? bmiGoal;
  final double? consistencyGoal;
  final String waterSummary;
  final String caloriesSummary;
  final String habitsSummary;
  final String activitySummary;
  final String sleepSummary;
  final String weightSummary;
  final String bmiSummary;
  final String consistencySummary;

  const ChartAggregationResult({
    required this.start,
    required this.end,
    required this.water,
    required this.calories,
    required this.habits,
    required this.activity,
    required this.sleep,
    required this.weight,
    required this.bmi,
    required this.consistency,
    required this.waterGoal,
    required this.caloriesGoal,
    required this.habitsGoal,
    required this.activityGoal,
    required this.sleepGoal,
    required this.weightGoal,
    required this.bmiGoal,
    required this.consistencyGoal,
    required this.waterSummary,
    required this.caloriesSummary,
    required this.habitsSummary,
    required this.activitySummary,
    required this.sleepSummary,
    required this.weightSummary,
    required this.bmiSummary,
    required this.consistencySummary,
  });
}

class ChartAggregationService {
  ChartAggregationService({required this.client, required this.userId});

  final SupabaseClient client;
  final String? userId;

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  String _dayKey(DateTime date) => HamvitDateUtils.toIsoDate(_startOfDay(date));

  DateTime _parseDate(dynamic value) {
    if (value == null) return _startOfDay(DateTime.now());
    final text = value.toString();
    final parsed = DateTime.tryParse(text);
    if (parsed != null) return _startOfDay(parsed);
    final parts = text.split('-');
    if (parts.length >= 3) {
      final y = int.tryParse(parts[0]) ?? DateTime.now().year;
      final m = int.tryParse(parts[1]) ?? DateTime.now().month;
      final d = int.tryParse(parts[2]) ?? DateTime.now().day;
      return DateTime(y, m, d);
    }
    return _startOfDay(DateTime.now());
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
    }
    return 0;
  }

  Future<DateTime> _discoverStartDate(String uid) async {
    final candidates = <DateTime>[];

    Future<void> check(Future<dynamic> Function() loader, DateTime Function(Map<String, dynamic>) mapper) async {
      try {
        final row = await loader();
        if (row is Map<String, dynamic>) {
          candidates.add(_startOfDay(mapper(row)));
        }
      } catch (_) {}
    }

    await check(
      () => client.from('hydration_logs').select('log_date, logged_at').eq('user_id', uid).order('logged_at').limit(1).maybeSingle(),
      (r) {
        final logDate = r['log_date'];
        if (logDate != null) return _parseDate(logDate);
        return _parseDate(r['logged_at']);
      },
    );

    await check(
      () => client.from('meal_logs').select('meal_date, consumed_at, created_at').eq('user_id', uid).order('created_at').limit(1).maybeSingle(),
      (r) {
        final d = r['meal_date'] ?? r['consumed_at'] ?? r['created_at'];
        return _parseDate(d);
      },
    );

    await check(
      () => client.from('weight_logs').select('log_date, recorded_at, created_at').eq('user_id', uid).order('created_at').limit(1).maybeSingle(),
      (r) => _parseDate(r['log_date'] ?? r['recorded_at'] ?? r['created_at']),
    );

    if (candidates.isEmpty) {
      return _startOfDay(DateTime.now()).subtract(const Duration(days: 6));
    }

    candidates.sort((a, b) => a.compareTo(b));
    return candidates.first;
  }

  Future<ChartAggregationResult> aggregate(DashboardPeriod period) async {
    final uid = userId;
    if (uid == null) throw Exception('Usuario nao autenticado');

    final end = _startOfDay(DateTime.now());
    final start = period.days == null
        ? await _discoverStartDate(uid)
        : end.subtract(Duration(days: period.days! - 1));
    final endExclusive = end.add(const Duration(days: 1));

    final dates = <DateTime>[];
    for (var cursor = start; !cursor.isAfter(end); cursor = cursor.add(const Duration(days: 1))) {
      dates.add(cursor);
    }

    final waterByDay = <String, double>{};
    final caloriesByDay = <String, double>{};
    final habitsByDay = <String, double>{};
    final activityByDay = <String, double>{};
    final sleepByDay = <String, double>{};
    final weightByDay = <String, double>{};

    var waterGoal = 2500.0;
    var caloriesGoal = 2000.0;
    var habitsGoal = 3.0;
    const activityGoal = 30.0;
    const sleepGoal = 8.0;
    double? weightGoal;
    const bmiGoal = 24.9;
    const consistencyGoal = 70.0;

    try {
      final target = await client
          .from('daily_nutrition_targets')
          .select('water_ml, calories_kcal, target_date')
          .eq('user_id', uid)
          .order('target_date', ascending: false)
          .limit(1)
          .maybeSingle();
      if (target != null) {
        final w = _toDouble(target['water_ml']);
        final c = _toDouble(target['calories_kcal']);
        if (w > 0) waterGoal = w;
        if (c > 0) caloriesGoal = c;
      }
    } catch (_) {}

    try {
      final habits = await client
          .from('user_habits')
          .select('id')
          .eq('user_id', uid)
          .eq('active', true);
      final total = habits.length.toDouble();
      if (total > 0) habitsGoal = total;
    } catch (_) {}

    double heightMeters = 0;
    try {
      final profile = await client
          .from('health_profiles')
          .select('height_cm, target_weight_kg, desired_weight_kg')
          .eq('user_id', uid)
          .maybeSingle();
      if (profile != null) {
        final heightCm = _toDouble(profile['height_cm']);
        if (heightCm > 0) heightMeters = heightCm / 100;
        final goal = _toDouble(profile['target_weight_kg']);
        if (goal > 0) {
          weightGoal = goal;
        } else {
          final fallbackGoal = _toDouble(profile['desired_weight_kg']);
          if (fallbackGoal > 0) weightGoal = fallbackGoal;
        }
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('hydration_logs')
          .select('log_date, amount_ml, ml, logged_at')
          .eq('user_id', uid)
          .gte('logged_at', start.toIso8601String())
          .lt('logged_at', endExclusive.toIso8601String());
      for (final row in rows) {
        final day = _parseDate(row['log_date'] ?? row['logged_at']);
        final key = _dayKey(day);
        final value = _toDouble(row['amount_ml']) + _toDouble(row['ml']);
        waterByDay[key] = (waterByDay[key] ?? 0) + value;
      }
    } catch (_) {}

    final mealIdsByDay = <String, String>{};
    try {
      final rows = await client
          .from('meal_logs')
          .select('id, meal_date, consumed_at, created_at, total_calories_kcal')
          .eq('user_id', uid)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', endExclusive.toIso8601String());

      for (final row in rows) {
        final id = row['id']?.toString();
        final day = _parseDate(row['meal_date'] ?? row['consumed_at'] ?? row['created_at']);
        final key = _dayKey(day);
        if (id != null && id.isNotEmpty) mealIdsByDay[id] = key;
        caloriesByDay[key] = (caloriesByDay[key] ?? 0) + _toDouble(row['total_calories_kcal']);
      }
    } catch (_) {}

    if (mealIdsByDay.isNotEmpty) {
      try {
        final items = await client
            .from('meal_items')
            .select('meal_log_id, calories')
            .inFilter('meal_log_id', mealIdsByDay.keys.toList());
        final byDay = <String, double>{};
        for (final row in items) {
          final id = row['meal_log_id']?.toString();
          if (id == null) continue;
          final key = mealIdsByDay[id];
          if (key == null) continue;
          byDay[key] = (byDay[key] ?? 0) + _toDouble(row['calories']);
        }
        byDay.forEach((key, value) {
          if (value > (caloriesByDay[key] ?? 0)) {
            caloriesByDay[key] = value;
          }
        });
      } catch (_) {}
    }

    try {
      final rows = await client
          .from('habit_logs')
          .select('log_date, logged_at, completed, done')
          .eq('user_id', uid)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', endExclusive.toIso8601String());

      for (final row in rows) {
        final completed = row['completed'] == true || row['done'] == true;
        if (!completed) continue;
        final day = _parseDate(row['log_date'] ?? row['logged_at']);
        final key = _dayKey(day);
        habitsByDay[key] = (habitsByDay[key] ?? 0) + 1;
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('activity_sessions')
          .select('started_at, finished_at, ended_at, duration_seconds')
          .eq('user_id', uid)
          .gte('started_at', start.toIso8601String())
          .lt('started_at', endExclusive.toIso8601String());

      for (final row in rows) {
        final startedAt = DateTime.tryParse((row['started_at'] ?? '').toString());
        if (startedAt == null) continue;
        var minutes = _toDouble(row['duration_seconds']) / 60;
        if (minutes <= 0) {
          final finished = DateTime.tryParse((row['finished_at'] ?? '').toString()) ??
              DateTime.tryParse((row['ended_at'] ?? '').toString());
          if (finished != null && finished.isAfter(startedAt)) {
            minutes = finished.difference(startedAt).inMinutes.toDouble();
          }
        }
        final key = _dayKey(startedAt);
        activityByDay[key] = (activityByDay[key] ?? 0) + math.max(0, minutes);
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('sleep_logs')
          .select('sleep_date, duration_minutes, total_sleep_minutes')
          .eq('user_id', uid)
          .gte('sleep_date', _dayKey(start))
          .lte('sleep_date', _dayKey(end));

      for (final row in rows) {
        final day = _parseDate(row['sleep_date']);
        final key = _dayKey(day);
        final minutes = _toDouble(row['duration_minutes']) + _toDouble(row['total_sleep_minutes']);
        if (minutes <= 0) continue;
        sleepByDay[key] = (sleepByDay[key] ?? 0) + (minutes / 60);
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('weight_logs')
          .select('log_date, recorded_at, created_at, weight_kg, weight')
          .eq('user_id', uid)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', endExclusive.toIso8601String())
          .order('created_at');
      for (final row in rows) {
        final day = _parseDate(row['log_date'] ?? row['recorded_at'] ?? row['created_at']);
        final key = _dayKey(day);
        final weight = _toDouble(row['weight_kg']) > 0 ? _toDouble(row['weight_kg']) : _toDouble(row['weight']);
        if (weight > 0) weightByDay[key] = weight;
      }
    } catch (_) {
      try {
        final rows = await client
            .from('body_progress_logs')
            .select('log_date, created_at, weight_kg')
            .eq('user_id', uid)
            .gte('created_at', start.toIso8601String())
            .lt('created_at', endExclusive.toIso8601String())
            .order('created_at');
        for (final row in rows) {
          final day = _parseDate(row['log_date'] ?? row['created_at']);
          final key = _dayKey(day);
          final weight = _toDouble(row['weight_kg']);
          if (weight > 0) weightByDay[key] = weight;
        }
      } catch (_) {}
    }

    final water = <DashboardPoint>[];
    final calories = <DashboardPoint>[];
    final habits = <DashboardPoint>[];
    final activity = <DashboardPoint>[];
    final sleep = <DashboardPoint>[];
    final weight = <DashboardPoint>[];
    final bmi = <DashboardPoint>[];
    final consistency = <DashboardPoint>[];

    double totalWater = 0;
    double totalCalories = 0;
    double totalHabits = 0;
    double totalActivity = 0;
    double totalSleep = 0;
    var waterHits = 0;

    double? lastWeightValue;

    for (final day in dates) {
      final key = _dayKey(day);
      final w = waterByDay[key] ?? 0;
      final c = caloriesByDay[key] ?? 0;
      final h = habitsByDay[key] ?? 0;
      final a = activityByDay[key] ?? 0;
      final s = sleepByDay[key] ?? 0;

      totalWater += w;
      totalCalories += c;
      totalHabits += h;
      totalActivity += a;
      totalSleep += s;
      if (w >= waterGoal) waterHits++;

      water.add(DashboardPoint(date: day, value: w));
      calories.add(DashboardPoint(date: day, value: c));
      habits.add(DashboardPoint(date: day, value: h));
      activity.add(DashboardPoint(date: day, value: a));
      sleep.add(DashboardPoint(date: day, value: s));

      final maybeWeight = weightByDay[key];
      if (maybeWeight != null) {
        lastWeightValue = maybeWeight;
      }
      final currentWeight = maybeWeight ?? lastWeightValue;
      weight.add(DashboardPoint(date: day, value: currentWeight ?? 0));

      if (currentWeight != null && currentWeight > 0 && heightMeters > 0) {
        final bmiValue = currentWeight / (heightMeters * heightMeters);
        bmi.add(DashboardPoint(date: day, value: bmiValue));
      } else {
        bmi.add(DashboardPoint(date: day, value: 0));
      }

      var checks = 0;
      var hits = 0;
      checks++;
      if (w >= waterGoal) hits++;
      checks++;
      if (c > 0 && c <= caloriesGoal * 1.1) hits++;
      checks++;
      if (h >= math.max(1, habitsGoal * 0.6)) hits++;
      checks++;
      if (a >= activityGoal) hits++;
      checks++;
      if (s >= sleepGoal * 0.8) hits++;
      final consistencyValue = checks == 0 ? 0.0 : (hits / checks) * 100;
      consistency.add(DashboardPoint(date: day, value: consistencyValue));
    }

    final days = math.max(1, dates.length).toDouble();
    final waterAvg = totalWater / days;
    final caloriesAvg = totalCalories / days;
    final habitsAvg = totalHabits / days;
    final activityAvg = totalActivity / days;
    final sleepAvg = totalSleep / days;
    final consistencyAvg = consistency.isEmpty
        ? 0
        : consistency.map((e) => e.value).reduce((a, b) => a + b) / consistency.length;

    final weightValid = weight.where((p) => p.value > 0).toList();
    final bmiValid = bmi.where((p) => p.value > 0).toList();

    return ChartAggregationResult(
      start: start,
      end: end,
      water: water,
      calories: calories,
      habits: habits,
      activity: activity,
      sleep: sleep,
      weight: weight,
      bmi: bmi,
      consistency: consistency,
      waterGoal: waterGoal,
      caloriesGoal: caloriesGoal,
      habitsGoal: habitsGoal,
      activityGoal: activityGoal,
      sleepGoal: sleepGoal,
      weightGoal: weightGoal,
      bmiGoal: bmiGoal,
      consistencyGoal: consistencyGoal,
      waterSummary:
          'Média de ${waterAvg.toStringAsFixed(0)} ml/dia. Meta alcançada em $waterHits dias.',
      caloriesSummary: 'Média de ${caloriesAvg.toStringAsFixed(0)} kcal por dia.',
      habitsSummary: 'Média de ${habitsAvg.toStringAsFixed(1)} hábitos concluídos por dia.',
      activitySummary: 'Média de ${activityAvg.toStringAsFixed(0)} minutos ativos por dia.',
      sleepSummary: 'Média de ${sleepAvg.toStringAsFixed(1)} horas de sono por dia.',
      weightSummary: weightValid.length < 2
          ? 'Registre mais pesagens para ver tendência de evolução.'
          : 'Variação de ${(weightValid.last.value - weightValid.first.value).toStringAsFixed(1)} kg no período.',
      bmiSummary: bmiValid.isEmpty
          ? 'Sem dados suficientes para IMC no período.'
          : 'IMC médio de ${(bmiValid.map((e) => e.value).reduce((a, b) => a + b) / bmiValid.length).toStringAsFixed(1)}.',
      consistencySummary: 'Constância média de ${consistencyAvg.toStringAsFixed(0)}% no período.',
    );
  }
}
