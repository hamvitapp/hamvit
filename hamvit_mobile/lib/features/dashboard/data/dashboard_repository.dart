import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/hamvit_date_utils.dart';
import '../../../core/supabase_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../domain/dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  return DashboardRepository(
    client: client,
    userId: ref.watch(currentUserProvider)?.id,
  );
});

class DashboardRepository {
  DashboardRepository({required this.client, required this.userId});

  final SupabaseClient client;
  final String? userId;

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(',', '.').trim());
      return parsed?.round() ?? 0;
    }
    return 0;
  }

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _parseDateOnly(String value) {
    final parts = value.split('-');
    if (parts.length < 3) return DateTime.now();
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final day = int.tryParse(parts[2]) ?? DateTime.now().day;
    return DateTime(year, month, day);
  }

  String _key(DateTime day) => HamvitDateUtils.toIsoDate(day);

  Future<DateTime> _findFirstDataDate(String uid) async {
    final candidates = <DateTime>[];

    Future<void> addCandidate(Future<dynamic> Function() loader, DateTime Function(Map<String, dynamic>) mapper) async {
      try {
        final row = await loader();
        if (row is Map<String, dynamic>) {
          candidates.add(_startOfDay(mapper(row)));
        }
      } catch (_) {}
    }

    await addCandidate(
      () => client
          .from('hydration_logs')
          .select('log_date')
          .eq('user_id', uid)
          .order('log_date', ascending: true)
          .limit(1)
          .maybeSingle(),
      (row) => _parseDateOnly((row['log_date'] ?? '').toString()),
    );

    await addCandidate(
      () => client
          .from('meal_logs')
          .select('meal_date, consumed_at, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle(),
      (row) {
        final mealDate = row['meal_date']?.toString();
        if (mealDate != null && mealDate.isNotEmpty) {
          return _parseDateOnly(mealDate);
        }
        final consumedAt = DateTime.tryParse((row['consumed_at'] ?? '').toString());
        if (consumedAt != null) return consumedAt;
        final createdAt = DateTime.tryParse((row['created_at'] ?? '').toString());
        return createdAt ?? DateTime.now();
      },
    );

    await addCandidate(
      () => client
          .from('habit_logs')
          .select('log_date, logged_at, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle(),
      (row) {
        final logDate = row['log_date']?.toString();
        if (logDate != null && logDate.isNotEmpty) return _parseDateOnly(logDate);
        final loggedAt = DateTime.tryParse((row['logged_at'] ?? '').toString());
        if (loggedAt != null) return loggedAt;
        final createdAt = DateTime.tryParse((row['created_at'] ?? '').toString());
        return createdAt ?? DateTime.now();
      },
    );

    await addCandidate(
      () => client
          .from('activity_sessions')
          .select('started_at')
          .eq('user_id', uid)
          .order('started_at', ascending: true)
          .limit(1)
          .maybeSingle(),
      (row) => DateTime.tryParse((row['started_at'] ?? '').toString()) ?? DateTime.now(),
    );

    await addCandidate(
      () => client
          .from('sleep_logs')
          .select('sleep_date, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle(),
      (row) {
        final sleepDate = row['sleep_date']?.toString();
        if (sleepDate != null && sleepDate.isNotEmpty) return _parseDateOnly(sleepDate);
        final createdAt = DateTime.tryParse((row['created_at'] ?? '').toString());
        return createdAt ?? DateTime.now();
      },
    );

    if (candidates.isEmpty) {
      return _startOfDay(DateTime.now()).subtract(const Duration(days: 6));
    }

    candidates.sort((a, b) => a.compareTo(b));
    return candidates.first;
  }

  Future<DashboardChartsData> fetchCharts(DashboardRange range) async {
    final uid = userId;
    if (uid == null) {
      throw Exception('Usuario nao autenticado');
    }

    final now = _startOfDay(DateTime.now());
    final rangeDays = range.days;
    final start = rangeDays != null
        ? now.subtract(Duration(days: rangeDays - 1))
        : await _findFirstDataDate(uid);
    final end = now.add(const Duration(days: 1));

    final dayKeys = <String>[];
    final dayList = <DateTime>[];
    for (var cursor = start; !cursor.isAfter(now); cursor = cursor.add(const Duration(days: 1))) {
      dayList.add(cursor);
      dayKeys.add(_key(cursor));
    }

    final waterByDay = <String, double>{};
    final caloriesByDay = <String, double>{};
    final habitsByDay = <String, double>{};
    final activityByDay = <String, double>{};
    final sleepByDay = <String, double>{};

    try {
      final rows = await client
          .from('hydration_logs')
          .select('log_date, amount_ml, ml, logged_at')
          .eq('user_id', uid)
          .gte('logged_at', start.toIso8601String())
          .lt('logged_at', end.toIso8601String());

      for (final row in rows) {
        final logDate = row['log_date']?.toString();
        final date = (logDate != null && logDate.isNotEmpty)
            ? _parseDateOnly(logDate)
            : (DateTime.tryParse((row['logged_at'] ?? '').toString()) ?? now);
        final key = _key(date);
        final value = _toInt(row['amount_ml']) + _toInt(row['ml']);
        waterByDay[key] = (waterByDay[key] ?? 0) + value.toDouble();
      }
    } catch (_) {}

    final mealIdsByDay = <String, String>{};
    try {
      final rows = await client
          .from('meal_logs')
          .select('id, meal_date, consumed_at, total_calories_kcal')
          .eq('user_id', uid)
          .gte('created_at', start.toIso8601String())
          .lt('created_at', end.toIso8601String());

      for (final row in rows) {
        final id = row['id']?.toString();
        final mealDate = row['meal_date']?.toString();
        final date = (mealDate != null && mealDate.isNotEmpty)
            ? _parseDateOnly(mealDate)
            : (DateTime.tryParse((row['consumed_at'] ?? '').toString()) ?? now);
        final key = _key(date);
        if (id != null && id.isNotEmpty) {
          mealIdsByDay[id] = key;
        }
        caloriesByDay[key] = (caloriesByDay[key] ?? 0) + _toInt(row['total_calories_kcal']).toDouble();
      }
    } catch (_) {}

    if (mealIdsByDay.isNotEmpty) {
      try {
        final ids = mealIdsByDay.keys.toList();
        final items = await client
            .from('meal_items')
            .select('meal_log_id, calories')
            .inFilter('meal_log_id', ids);

        final itemsByDay = <String, double>{};
        for (final row in items) {
          final mealId = row['meal_log_id']?.toString();
          if (mealId == null || mealId.isEmpty) continue;
          final dayKey = mealIdsByDay[mealId];
          if (dayKey == null) continue;
          itemsByDay[dayKey] = (itemsByDay[dayKey] ?? 0) + _toInt(row['calories']).toDouble();
        }

        itemsByDay.forEach((key, itemCalories) {
          if (itemCalories > (caloriesByDay[key] ?? 0)) {
            caloriesByDay[key] = itemCalories;
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
          .lt('created_at', end.toIso8601String());

      for (final row in rows) {
        final completed = row['completed'] == true || row['done'] == true;
        if (!completed) continue;
        final logDate = row['log_date']?.toString();
        final date = (logDate != null && logDate.isNotEmpty)
            ? _parseDateOnly(logDate)
            : (DateTime.tryParse((row['logged_at'] ?? '').toString()) ?? now);
        final key = _key(date);
        habitsByDay[key] = (habitsByDay[key] ?? 0) + 1;
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('activity_sessions')
          .select('started_at, finished_at, ended_at, duration_seconds')
          .eq('user_id', uid)
          .gte('started_at', start.toIso8601String())
          .lt('started_at', end.toIso8601String());

      for (final row in rows) {
        final startedAt = DateTime.tryParse((row['started_at'] ?? '').toString());
        if (startedAt == null) continue;
        final key = _key(startedAt);

        var minutes = _toInt(row['duration_seconds']) / 60.0;
        if (minutes <= 0) {
          final finishedAt = DateTime.tryParse((row['finished_at'] ?? '').toString()) ??
              DateTime.tryParse((row['ended_at'] ?? '').toString());
          if (finishedAt != null && finishedAt.isAfter(startedAt)) {
            minutes = finishedAt.difference(startedAt).inMinutes.toDouble();
          }
        }

        activityByDay[key] = (activityByDay[key] ?? 0) + math.max(0, minutes);
      }
    } catch (_) {}

    try {
      final rows = await client
          .from('sleep_logs')
          .select('sleep_date, duration_minutes, total_sleep_minutes')
          .eq('user_id', uid)
          .gte('sleep_date', _key(start))
          .lte('sleep_date', _key(now));

      for (final row in rows) {
        final sleepDate = row['sleep_date']?.toString();
        if (sleepDate == null || sleepDate.isEmpty) continue;
        final key = sleepDate;
        final minutes = _toInt(row['duration_minutes']) + _toInt(row['total_sleep_minutes']);
        if (minutes <= 0) continue;
        sleepByDay[key] = (sleepByDay[key] ?? 0) + (minutes / 60.0);
      }
    } catch (_) {}

    var cumulativeSleep = 0.0;
    final waterSeries = <DashboardSeriesPoint>[];
    final caloriesSeries = <DashboardSeriesPoint>[];
    final habitsSeries = <DashboardSeriesPoint>[];
    final activitySeries = <DashboardSeriesPoint>[];
    final sleepAccumSeries = <DashboardSeriesPoint>[];

    for (final day in dayList) {
      final key = _key(day);
      final water = waterByDay[key] ?? 0;
      final calories = caloriesByDay[key] ?? 0;
      final habits = habitsByDay[key] ?? 0;
      final activity = activityByDay[key] ?? 0;
      final sleep = sleepByDay[key] ?? 0;
      cumulativeSleep += sleep;

      waterSeries.add(DashboardSeriesPoint(date: day, value: water));
      caloriesSeries.add(DashboardSeriesPoint(date: day, value: calories));
      habitsSeries.add(DashboardSeriesPoint(date: day, value: habits));
      activitySeries.add(DashboardSeriesPoint(date: day, value: activity));
      sleepAccumSeries.add(DashboardSeriesPoint(date: day, value: cumulativeSleep));
    }

    return DashboardChartsData(
      waterMl: waterSeries,
      caloriesKcal: caloriesSeries,
      habitsDone: habitsSeries,
      activityMinutes: activitySeries,
      sleepAccumulatedHours: sleepAccumSeries,
    );
  }
}
