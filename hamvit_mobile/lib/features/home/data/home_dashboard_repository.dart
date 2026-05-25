import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hamvit_date_utils.dart';
import '../../../core/supabase_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/home_dashboard_model.dart';

final homeDashboardRepositoryProvider =
    Provider<HomeDashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  return HomeDashboardRepository(
    client: client,
    userId: ref.watch(currentUserProvider)?.id,
  );
});

class HomeDashboardRepository {
  HomeDashboardRepository({required this.client, required this.userId});

  final SupabaseClient client;
  final String? userId;

  static HomeDashboardModel? _inMemoryCache;

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.round();
    if (value is String) {
      final normalized = value.replaceAll(',', '.').trim();
      final parsed = double.tryParse(normalized);
      return parsed?.round() ?? 0;
    }
    return 0;
  }

  int _minutesFromSeconds(int seconds) {
    if (seconds <= 0) return 0;
    return math.max(1, (seconds / 60).ceil());
  }

  Future<HomeDashboardModel> fetchToday() async {
    final uid = userId;
    if (uid == null) {
      throw Exception('Usuario nao autenticado');
    }

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final isoDate = HamvitDateUtils.toIsoDate(dayStart);

    try {
      final hydration = await _fetchHydration(uid, dayStart, dayEnd, isoDate);
      final nutrition = await _fetchNutrition(uid, dayStart, dayEnd, isoDate);
      final habits = await _fetchHabits(uid, dayStart, dayEnd, isoDate);
      final activity = await _fetchActivity(uid, dayStart, dayEnd, isoDate);
      final sleep = await _fetchSleep(uid);
      final trend = await _fetchWeeklyTrend(uid);

      final scoreData = _computeScore(
        waterMl: hydration.waterMl,
        waterGoalMl: hydration.waterGoalMl,
        calories: nutrition.calories,
        caloriesGoal: nutrition.caloriesGoal,
        habitsDone: habits.done,
        habitsTotal: habits.total,
        distanceKm: activity.distanceKm,
        activeMinutes: activity.activeMinutes,
        sleepHours: sleep,
      );

      final effectiveTrend = trend.isEmpty
          ? List<double>.filled(7, scoreData.score.toDouble())
          : trend;

      final model = HomeDashboardModel(
        referenceDate: dayStart,
        waterMl: hydration.waterMl,
        waterGoalMl: hydration.waterGoalMl,
        calories: nutrition.calories,
        caloriesGoal: nutrition.caloriesGoal,
        habitsDone: habits.done,
        habitsTotal: habits.total,
        stepsToday: activity.stepsToday,
        distanceKm: activity.distanceKm,
        activeMinutes: activity.activeMinutes,
        activityCaloriesKcal: activity.caloriesKcal,
        sleepHours: sleep,
        score: scoreData.score,
        dayCompletionPercent: scoreData.dayCompletionPercent,
        statusText: scoreData.status,
        primaryInsight: _buildPrimaryInsight(
          hydrationProgress:
              _safeProgress(hydration.waterMl, hydration.waterGoalMl),
          caloriesProgress: nutrition.caloriesGoal == null
              ? null
              : _safeProgress(nutrition.calories, nutrition.caloriesGoal!),
          habitsProgress: habits.total > 0 ? habits.done / habits.total : null,
          activityProgress:
              _activityProgress(activity.distanceKm, activity.activeMinutes),
        ),
        secondaryInsight:
            _buildSecondaryInsight(habits.done, habits.total, sleep),
        trend: effectiveTrend,
      );

      _inMemoryCache = model;
      return model;
    } catch (error) {
      if (_inMemoryCache != null) {
        return _inMemoryCache!.copyWith(
          isOffline: true,
          warningMessage:
              'Exibindo ultimo dashboard salvo. Falha ao sincronizar dados reais.',
        );
      }
      rethrow;
    }
  }

  Future<void> quickAddWater({int amountMl = 200}) async {
    final uid = userId;
    if (uid == null) throw Exception('Usuario nao autenticado');

    final now = DateTime.now();
    final isoDate = HamvitDateUtils.toIsoDate(now);
    final nowIso = now.toIso8601String();

    try {
      await client.from('hydration_logs').insert({
        'user_id': uid,
        'log_date': isoDate,
        'amount_ml': amountMl,
        'logged_at': nowIso,
      });
      return;
    } catch (_) {
      try {
        await client.from('hydration_logs').insert({
          'user_id': uid,
          'ml': amountMl,
          'logged_at': nowIso,
        });
        return;
      } catch (_) {
        await client.from('hydration_logs').insert({
          'user_id': uid,
          'amount_ml': amountMl,
          'logged_at': nowIso,
        });
      }
    }
  }

  Future<void> quickAddMeal({required int calories}) async {
    final uid = userId;
    if (uid == null) throw Exception('Usuario nao autenticado');

    final now = DateTime.now();
    final isoDate = HamvitDateUtils.toIsoDate(now);

    try {
      final meal = await client
          .from('meal_logs')
          .insert({
            'user_id': uid,
            'meal_type': 'lanche',
            'meal_date': isoDate,
            'total_calories_kcal': calories,
            'created_at': now.toIso8601String(),
          })
          .select('id')
          .single();

      await client.from('meal_items').insert({
        'meal_log_id': meal['id'],
        'calories': calories,
      });
      return;
    } catch (_) {
      final meal = await client
          .from('meal_logs')
          .insert({
            'user_id': uid,
            'meal_type': 'lanche',
            'consumed_at': now.toIso8601String(),
            'created_at': now.toIso8601String(),
          })
          .select('id')
          .single();

      await client.from('meal_items').insert({
        'meal_log_id': meal['id'],
        'calories': calories,
      });
    }
  }

  Future<bool> quickCompleteOneHabit() async {
    final uid = userId;
    if (uid == null) throw Exception('Usuario nao autenticado');

    final today = HamvitDateUtils.toIsoDate(DateTime.now());

    final habits = await client
        .from('user_habits')
        .select('id')
        .eq('user_id', uid)
        .eq('active', true)
        .order('created_at');

    if (habits.isEmpty) return false;

    for (final row in habits) {
      final habitId = row['id'].toString();
      try {
        final existing = await client
            .from('habit_logs')
            .select('id, completed')
            .eq('user_id', uid)
            .eq('habit_id', habitId)
            .eq('log_date', today)
            .limit(1);

        if (existing.isEmpty) {
          await client.from('habit_logs').insert({
            'user_id': uid,
            'habit_id': habitId,
            'log_date': today,
            'completed': true,
            'sync_status': 'pending',
            'client_uuid': '${uid}_${habitId}_$today',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          return true;
        }

        if (existing.first['completed'] != true) {
          await client.from('habit_logs').update({
            'completed': true,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existing.first['id']);
          return true;
        }
      } catch (_) {
        continue;
      }
    }

    return false;
  }

  Future<void> quickStartWalk() async {
    final uid = userId;
    if (uid == null) throw Exception('Usuario nao autenticado');

    final now = DateTime.now();

    await client.from('activity_sessions').insert({
      'user_id': uid,
      'activity_type': 'caminhada',
      'started_at': now.toIso8601String(),
      'created_at': now.toIso8601String(),
    });
  }

  Future<_HydrationData> _fetchHydration(
    String uid,
    DateTime dayStart,
    DateTime dayEnd,
    String isoDate,
  ) async {
    final hydrationCandidates = <int>[];

    try {
      final logs = await client
          .from('hydration_logs')
          .select('amount_ml')
          .eq('user_id', uid)
          .eq('log_date', isoDate);
      hydrationCandidates.add(
        logs.fold<int>(
            0, (acc, row) => acc + ((row['amount_ml'] as num?)?.toInt() ?? 0)),
      );
    } catch (_) {}

    try {
      final logs = await client
          .from('hydration_logs')
          .select('ml')
          .eq('user_id', uid)
          .gte('logged_at', dayStart.toIso8601String())
          .lt('logged_at', dayEnd.toIso8601String());
      hydrationCandidates.add(
        logs.fold<int>(
            0, (acc, row) => acc + ((row['ml'] as num?)?.toInt() ?? 0)),
      );
    } catch (_) {}

    try {
      final logs = await client
          .from('hydration_logs')
          .select('amount_ml')
          .eq('user_id', uid)
          .gte('logged_at', dayStart.toIso8601String())
          .lt('logged_at', dayEnd.toIso8601String());
      hydrationCandidates.add(
        logs.fold<int>(
            0, (acc, row) => acc + ((row['amount_ml'] as num?)?.toInt() ?? 0)),
      );
    } catch (_) {}

    final waterMl =
        hydrationCandidates.isEmpty ? 0 : hydrationCandidates.reduce(math.max);

    int waterGoalMl = 2500;
    try {
      final row = await client
          .from('daily_nutrition_targets')
          .select('water_ml')
          .eq('user_id', uid)
          .eq('target_date', isoDate)
          .maybeSingle();
      waterGoalMl = ((row?['water_ml'] as num?)?.toInt()) ?? waterGoalMl;
    } catch (_) {}

    if (waterGoalMl <= 0) {
      try {
        final profile = await client
            .from('health_profiles')
            .select('current_weight_kg, weight_kg')
            .eq('user_id', uid)
            .maybeSingle();
        final weight = ((profile?['current_weight_kg'] as num?) ??
                (profile?['weight_kg'] as num?))
            ?.toDouble();
        if (weight != null && weight > 0) {
          waterGoalMl = (weight * 35).round();
        }
      } catch (_) {}
    }

    return _HydrationData(
        waterMl: waterMl, waterGoalMl: waterGoalMl.clamp(1500, 5000));
  }

  Future<_NutritionData> _fetchNutrition(
    String uid,
    DateTime dayStart,
    DateTime dayEnd,
    String isoDate,
  ) async {
    int calories = 0;

    final mealIds = <String>[];
    try {
      final mealLogsByDate = await client
          .from('meal_logs')
          .select('id, total_calories_kcal')
          .eq('user_id', uid)
          .eq('meal_date', isoDate);

      for (final row in mealLogsByDate) {
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty) {
          mealIds.add(id);
        }
        calories += _toInt(row['total_calories_kcal']);
      }
    } catch (_) {}

    try {
      final mealLogsByConsumedAt = await client
          .from('meal_logs')
          .select('id')
          .eq('user_id', uid)
          .gte('consumed_at', dayStart.toIso8601String())
          .lt('consumed_at', dayEnd.toIso8601String());
      for (final row in mealLogsByConsumedAt) {
        final id = row['id']?.toString();
        if (id != null && id.isNotEmpty && !mealIds.contains(id)) {
          mealIds.add(id);
        }
      }
    } catch (_) {}

    if (mealIds.isNotEmpty) {
      final items = await client
          .from('meal_items')
          .select('calories')
          .inFilter('meal_log_id', mealIds);
      final fromItems =
          items.fold<int>(0, (acc, row) => acc + _toInt(row['calories']));
      if (fromItems > calories) {
        calories = fromItems;
      }
    }

    int? caloriesGoal;
    try {
      final row = await client
          .from('daily_nutrition_targets')
          .select('calories_kcal')
          .eq('user_id', uid)
          .eq('target_date', isoDate)
          .maybeSingle();
      caloriesGoal = (row?['calories_kcal'] as num?)?.round();
    } catch (_) {
      try {
        final row = await client
            .from('daily_nutrition_targets')
            .select('calories')
            .eq('user_id', uid)
            .eq('target_date', isoDate)
            .maybeSingle();
        caloriesGoal = (row?['calories'] as num?)?.round();
      } catch (_) {}
    }

    return _NutritionData(calories: calories, caloriesGoal: caloriesGoal);
  }

  Future<_HabitsData> _fetchHabits(
    String uid,
    DateTime dayStart,
    DateTime dayEnd,
    String isoDate,
  ) async {
    int total = 0;
    int done = 0;

    final habits = await client
        .from('user_habits')
        .select('id')
        .eq('user_id', uid)
        .eq('active', true);
    total = habits.length;

    final completedIds = <String>{};
    try {
      final completed = await client
          .from('habit_logs')
          .select('habit_id')
          .eq('user_id', uid)
          .eq('log_date', isoDate)
          .eq('completed', true);
      completedIds.addAll(completed
          .map((row) => (row['habit_id'] ?? '').toString())
          .where((id) => id.isNotEmpty));
    } catch (_) {}

    try {
      final completedLegacy = await client
          .from('habit_logs')
          .select('user_habit_id')
          .eq('user_id', uid)
          .eq('done', true)
          .gte('logged_at', dayStart.toIso8601String())
          .lt('logged_at', dayEnd.toIso8601String());
      completedIds.addAll(completedLegacy
          .map((row) => (row['user_habit_id'] ?? '').toString())
          .where((id) => id.isNotEmpty));
    } catch (_) {}

    done = completedIds.length;

    if (done > total && total > 0) {
      done = total;
    }

    return _HabitsData(done: done, total: total);
  }

  Future<_ActivityData> _fetchActivity(
    String uid,
    DateTime dayStart,
    DateTime dayEnd,
    String isoDate,
  ) async {
    try {
      final sessions = await client
          .from('activity_sessions')
          .select(
              'distance_meters, manual_distance_meters, duration_seconds, started_at, finished_at, steps_count, estimated_calories_kcal')
          .eq('user_id', uid)
          .gte('started_at', dayStart.toIso8601String())
          .lt('started_at', dayEnd.toIso8601String());

      var distanceMeters = 0.0;
      var activeMinutes = 0;
      var stepsToday = 0;
      var caloriesKcal = 0;

      for (final row in sessions) {
        final distanceGps = (row['distance_meters'] as num?)?.toDouble() ?? 0;
        final distanceManual =
            (row['manual_distance_meters'] as num?)?.toDouble() ?? 0;
        distanceMeters += distanceGps > 0 ? distanceGps : distanceManual;
        stepsToday += (row['steps_count'] as num?)?.toInt() ?? 0;
        caloriesKcal += (row['estimated_calories_kcal'] as num?)?.round() ?? 0;

        final durationSeconds = (row['duration_seconds'] as num?)?.toInt();
        if (durationSeconds != null) {
          activeMinutes += _minutesFromSeconds(durationSeconds);
          continue;
        }

        final startedAt =
            DateTime.tryParse((row['started_at'] ?? '').toString());
        final finishedAt =
            DateTime.tryParse((row['finished_at'] ?? '').toString());
        if (startedAt != null &&
            finishedAt != null &&
            finishedAt.isAfter(startedAt)) {
          activeMinutes +=
              _minutesFromSeconds(finishedAt.difference(startedAt).inSeconds);
        }
      }

      return _ActivityData(
          distanceKm: distanceMeters / 1000,
          activeMinutes: activeMinutes,
          stepsToday: stepsToday == 0 ? null : stepsToday,
          caloriesKcal: caloriesKcal);
    } catch (_) {
      final sessions = await client
          .from('activity_sessions')
          .select('distance_m, started_at, ended_at')
          .eq('user_id', uid)
          .gte('started_at', dayStart.toIso8601String())
          .lt('started_at', dayEnd.toIso8601String());

      var distanceKm = 0.0;
      var activeMinutes = 0;
      const caloriesKcal = 0;

      for (final row in sessions) {
        distanceKm += ((row['distance_m'] as num?)?.toDouble() ?? 0) / 1000;
        final startedAt =
            DateTime.tryParse((row['started_at'] ?? '').toString());
        final endedAt = DateTime.tryParse((row['ended_at'] ?? '').toString());
        if (startedAt != null &&
            endedAt != null &&
            endedAt.isAfter(startedAt)) {
          activeMinutes +=
              _minutesFromSeconds(endedAt.difference(startedAt).inSeconds);
        }
      }

      return _ActivityData(
          distanceKm: distanceKm,
          activeMinutes: activeMinutes,
          stepsToday: null,
          caloriesKcal: caloriesKcal);
    }
  }

  Future<double?> _fetchSleep(String uid) async {
    try {
      final row = await client
          .from('sleep_logs')
          .select('duration_minutes')
          .eq('user_id', uid)
          .order('sleep_date', ascending: false)
          .limit(1)
          .maybeSingle();
      final minutes = (row?['duration_minutes'] as num?)?.toDouble();
      if (minutes == null) return null;
      return (minutes / 60).clamp(0, 24);
    } catch (_) {
      try {
        final row = await client
            .from('sleep_logs')
            .select('total_sleep_minutes')
            .eq('user_id', uid)
            .order('sleep_date', ascending: false)
            .limit(1)
            .maybeSingle();
        final minutes = (row?['total_sleep_minutes'] as num?)?.toDouble();
        if (minutes == null) return null;
        return (minutes / 60).clamp(0, 24);
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<double>> _fetchWeeklyTrend(String uid) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));

    try {
      final rows = await client
          .from('home_daily_summaries')
          .select('summary_date, daily_score_percent')
          .eq('user_id', uid)
          .gte('summary_date', HamvitDateUtils.toIsoDate(start))
          .order('summary_date');

      if (rows.isNotEmpty) {
        return rows
            .map<double>((row) =>
                ((row['daily_score_percent'] as num?)?.toDouble() ?? 0)
                    .clamp(0, 100))
            .toList();
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('home_daily_summaries')
          .select('summary_date, daily_score')
          .eq('user_id', uid)
          .gte('summary_date', HamvitDateUtils.toIsoDate(start))
          .order('summary_date');

      if (rows.isNotEmpty) {
        return rows
            .map<double>((row) =>
                ((row['daily_score'] as num?)?.toDouble() ?? 0).clamp(0, 100))
            .toList();
      }
    } catch (_) {}

    // fallback real: compute score from raw daily logs to avoid mock trend.
    final dayMap = <String, _TrendDayData>{
      for (var i = 0; i < 7; i++)
        HamvitDateUtils.toIsoDate(start.add(Duration(days: i))):
            const _TrendDayData()
    };

    try {
      final hydration = await client
          .from('hydration_logs')
          .select('log_date, amount_ml, ml, logged_at')
          .eq('user_id', uid)
          .gte('logged_at', start.toIso8601String())
          .lt('logged_at', now.add(const Duration(days: 1)).toIso8601String());

      for (final row in hydration) {
        final key = (row['log_date'] ?? '').toString().isNotEmpty
            ? (row['log_date'] ?? '').toString()
            : HamvitDateUtils.toIsoDate(
                DateTime.tryParse((row['logged_at'] ?? '').toString()) ?? now);
        final current = dayMap[key] ?? const _TrendDayData();
        dayMap[key] = current.copyWith(
          waterMl: current.waterMl + _toInt(row['amount_ml']) + _toInt(row['ml']),
        );
      }
    } catch (_) {}

    try {
      final meals = await client
          .from('meal_logs')
          .select('meal_date, consumed_at, total_calories_kcal')
          .eq('user_id', uid)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', now.add(const Duration(days: 1)).toIso8601String());
      for (final row in meals) {
        final dateRaw = (row['meal_date'] ?? '').toString();
        final key = dateRaw.isNotEmpty
            ? dateRaw
            : HamvitDateUtils.toIsoDate(
                DateTime.tryParse((row['consumed_at'] ?? '').toString()) ?? now);
        final current = dayMap[key] ?? const _TrendDayData();
        dayMap[key] = current.copyWith(
          calories: current.calories + _toInt(row['total_calories_kcal']),
        );
      }
    } catch (_) {}

    try {
      final habits = await client
          .from('habit_logs')
          .select('log_date, logged_at, completed, done')
          .eq('user_id', uid)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', now.add(const Duration(days: 1)).toIso8601String());

      for (final row in habits) {
        final completed = row['completed'] == true || row['done'] == true;
        if (!completed) continue;
        final dateRaw = (row['log_date'] ?? '').toString();
        final key = dateRaw.isNotEmpty
            ? dateRaw
            : HamvitDateUtils.toIsoDate(
                DateTime.tryParse((row['logged_at'] ?? '').toString()) ?? now);
        final current = dayMap[key] ?? const _TrendDayData();
        dayMap[key] = current.copyWith(habitsDone: current.habitsDone + 1);
      }
    } catch (_) {}

    try {
      final activity = await client
          .from('activity_sessions')
          .select('started_at, duration_seconds, finished_at, ended_at')
          .eq('user_id', uid)
          .gte('started_at', start.toIso8601String())
          .lt('started_at', now.add(const Duration(days: 1)).toIso8601String());

      for (final row in activity) {
        final startedAt =
            DateTime.tryParse((row['started_at'] ?? '').toString());
        if (startedAt == null) continue;
        final key = HamvitDateUtils.toIsoDate(startedAt);
        final current = dayMap[key] ?? const _TrendDayData();

        var activeMinutes = _minutesFromSeconds(_toInt(row['duration_seconds']));
        if (activeMinutes <= 0) {
          final endedAt =
              DateTime.tryParse((row['finished_at'] ?? '').toString()) ??
                  DateTime.tryParse((row['ended_at'] ?? '').toString());
          if (endedAt != null && endedAt.isAfter(startedAt)) {
            activeMinutes =
                _minutesFromSeconds(endedAt.difference(startedAt).inSeconds);
          }
        }

        dayMap[key] = current.copyWith(
          activeMinutes: current.activeMinutes + activeMinutes,
        );
      }
    } catch (_) {}

    try {
      final sleepRows = await client
          .from('sleep_logs')
          .select('sleep_date, duration_minutes, total_sleep_minutes')
          .eq('user_id', uid)
          .gte('sleep_date', HamvitDateUtils.toIsoDate(start))
          .lte('sleep_date', HamvitDateUtils.toIsoDate(now));

      for (final row in sleepRows) {
        final key = (row['sleep_date'] ?? '').toString();
        if (key.isEmpty) continue;
        final current = dayMap[key] ?? const _TrendDayData();
        final hours = (_toInt(row['duration_minutes']) +
                _toInt(row['total_sleep_minutes'])) /
            60.0;
        dayMap[key] = current.copyWith(sleepHours: hours);
      }
    } catch (_) {}

    return dayMap.entries.map((entry) {
      final day = entry.value;
      var score = 0.0;
      var weight = 0.0;

      score += _safeProgress(day.waterMl, 2500) * 0.25;
      weight += 0.25;

      if (day.calories > 0) {
        score += _safeProgress(day.calories, 2000) * 0.25;
        weight += 0.25;
      }

      score += (day.habitsDone / 3).clamp(0.0, 1.0) * 0.2;
      weight += 0.2;

      score += (day.activeMinutes / 30).clamp(0.0, 1.0) * 0.2;
      weight += 0.2;

      if (day.sleepHours > 0) {
        score += (day.sleepHours / 8).clamp(0.0, 1.0) * 0.1;
        weight += 0.1;
      }

      final normalized = weight > 0 ? score / weight : 0.0;
      return (normalized * 100).clamp(0.0, 100.0);
    }).toList(growable: false);
  }

  _ScoreData _computeScore({
    required int waterMl,
    required int waterGoalMl,
    required int calories,
    required int? caloriesGoal,
    required int habitsDone,
    required int habitsTotal,
    required double distanceKm,
    required int activeMinutes,
    required double? sleepHours,
  }) {
    var weightedSum = 0.0;
    var availableWeight = 0.0;

    const waterWeight = 0.25;
    final waterProgress = _safeProgress(waterMl, waterGoalMl);
    weightedSum += waterProgress * waterWeight;
    availableWeight += waterWeight;

    const habitsWeight = 0.25;
    if (habitsTotal > 0) {
      final habitsProgress = (habitsDone / habitsTotal).clamp(0.0, 1.0);
      weightedSum += habitsProgress * habitsWeight;
      availableWeight += habitsWeight;
    }

    const caloriesWeight = 0.25;
    if (caloriesGoal != null && caloriesGoal > 0) {
      final caloriesProgress = _safeProgress(calories, caloriesGoal);
      weightedSum += caloriesProgress * caloriesWeight;
      availableWeight += caloriesWeight;
    }

    const activityWeight = 0.15;
    final activityProgress = _activityProgress(distanceKm, activeMinutes);
    weightedSum += activityProgress * activityWeight;
    availableWeight += activityWeight;

    const sleepWeight = 0.10;
    if (sleepHours != null && sleepHours > 0) {
      final sleepProgress = (sleepHours / 8).clamp(0.0, 1.0);
      weightedSum += sleepProgress * sleepWeight;
      availableWeight += sleepWeight;
    }

    final normalized =
        availableWeight > 0 ? (weightedSum / availableWeight) : 0.0;
    final score = (normalized * 100).round().clamp(0, 100);

    final status = switch (score) {
      >= 85 => 'Ritmo excelente. Continue nesse nivel de consistencia.',
      >= 70 => 'Boa consistencia hoje. Falta pouco para bater as metas.',
      >= 50 => 'Dia em progresso. Complete mais um modulo para subir o score.',
      _ => 'Comece por uma acao rapida para destravar seu score de hoje.',
    };

    final dayCompletionPercent = score.clamp(0, 100);

    return _ScoreData(
      score: score,
      dayCompletionPercent: dayCompletionPercent,
      status: status,
    );
  }

  String _buildPrimaryInsight({
    required double hydrationProgress,
    required double? caloriesProgress,
    required double? habitsProgress,
    required double activityProgress,
  }) {
    if (hydrationProgress < 0.35) {
      return 'Sua hidratacao ainda esta baixa. Um registro de agua agora melhora seu dia.';
    }
    if ((habitsProgress ?? 0) < 0.4) {
      return 'Concluir um habito agora aumenta rapidamente seu score diario.';
    }
    if (caloriesProgress == null) {
      return 'Defina sua meta calorica para deixar o dashboard ainda mais preciso.';
    }
    if (activityProgress < 0.3) {
      return 'Uma caminhada curta hoje melhora sua consistencia de atividade.';
    }
    return 'Seu dia esta equilibrado entre agua, alimentacao, habitos e atividade.';
  }

  String? _buildSecondaryInsight(
      int habitsDone, int habitsTotal, double? sleepHours) {
    if (habitsTotal == 0) {
      return 'Crie seu primeiro habito para acompanhar sua consistencia diaria.';
    }
    if ((sleepHours ?? 0) == 0) {
      return 'Registre seu sono para completar a analise diaria com dados reais.';
    }
    if ((sleepHours ?? 0) < 7) {
      return 'Sono abaixo de 7h pode reduzir desempenho e recuperacao.';
    }
    if (habitsDone >= habitsTotal && habitsTotal > 0) {
      return 'Todos os habitos do dia foram concluidos. Excelente constancia.';
    }
    return null;
  }

  double _safeProgress(int value, int target) {
    if (target <= 0) return 0;
    return (value / target).clamp(0.0, 1.0);
  }

  double _activityProgress(double distanceKm, int activeMinutes) {
    final byDistance = (distanceKm / 3).clamp(0.0, 1.0);
    final byMinutes = (activeMinutes / 30).clamp(0.0, 1.0);
    return math.max(byDistance, byMinutes);
  }
}

class _HydrationData {
  final int waterMl;
  final int waterGoalMl;

  const _HydrationData({required this.waterMl, required this.waterGoalMl});
}

class _NutritionData {
  final int calories;
  final int? caloriesGoal;

  const _NutritionData({required this.calories, required this.caloriesGoal});
}

class _HabitsData {
  final int done;
  final int total;

  const _HabitsData({required this.done, required this.total});
}

class _ActivityData {
  final double distanceKm;
  final int activeMinutes;
  final int? stepsToday;
  final int caloriesKcal;

  const _ActivityData(
      {required this.distanceKm,
      required this.activeMinutes,
      required this.stepsToday,
      required this.caloriesKcal});
}

class _ScoreData {
  final int score;
  final int dayCompletionPercent;
  final String status;

  const _ScoreData(
      {required this.score,
      required this.dayCompletionPercent,
      required this.status});
}

class _TrendDayData {
  final int waterMl;
  final int calories;
  final int habitsDone;
  final int activeMinutes;
  final double sleepHours;

  const _TrendDayData({
    this.waterMl = 0,
    this.calories = 0,
    this.habitsDone = 0,
    this.activeMinutes = 0,
    this.sleepHours = 0,
  });

  _TrendDayData copyWith({
    int? waterMl,
    int? calories,
    int? habitsDone,
    int? activeMinutes,
    double? sleepHours,
  }) {
    return _TrendDayData(
      waterMl: waterMl ?? this.waterMl,
      calories: calories ?? this.calories,
      habitsDone: habitsDone ?? this.habitsDone,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      sleepHours: sleepHours ?? this.sleepHours,
    );
  }
}
