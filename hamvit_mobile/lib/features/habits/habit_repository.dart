import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/hamvit_date_utils.dart';
import '../../core/supabase_provider.dart';
import '../auth/providers/auth_provider.dart';
import 'habit_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  return HabitRepository(
    client: client,
    userId: ref.watch(currentUserProvider)?.id,
  );
});

class HabitRepository {
  final SupabaseClient client;
  final String? userId;

  HabitRepository({required this.client, required this.userId});

  static const suggestedTemplates = <HabitTemplate>[
    HabitTemplate(
      title: 'Beber água',
      category: 'Água',
      description: 'Registrar consumo ao longo do dia.',
      frequency: 'Diário',
    ),
    HabitTemplate(
      title: 'Caminhar 20 minutos',
      category: 'Movimento',
      description: 'Movimento leve para manter consistência.',
      frequency: 'Diário',
    ),
    HabitTemplate(
      title: 'Dormir melhor',
      category: 'Sono',
      description: 'Criar rotina para deitar mais cedo.',
      frequency: 'Diário',
    ),
    HabitTemplate(
      title: 'Comer com atenção',
      category: 'Alimentação',
      description: 'Fazer refeições com presença e sem pressa.',
      frequency: 'Diário',
    ),
    HabitTemplate(
      title: 'Registrar alimentação',
      category: 'Saúde',
      description: 'Registrar ao menos uma refeição no dia.',
      frequency: 'Diário',
    ),
  ];

  Future<List<HabitModel>> fetchHabits() async {
    final uid = userId;
    if (uid == null) return const [];

    final rows = await client
        .from('user_habits')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    final habits = rows.map((item) => HabitModel.fromMap(Map<String, dynamic>.from(item))).toList();

    final doneIds = await _fetchCompletedHabitIdsForToday(uid);
    return habits
        .where((habit) => habit.active)
        .map((habit) => habit.copyWith(doneToday: doneIds.contains(habit.id)))
        .toList();
  }

  Future<Set<String>> _fetchCompletedHabitIdsForToday(String uid) async {
    final today = HamvitDateUtils.toIsoDate(DateTime.now());

    try {
      final rows = await client
          .from('habit_logs')
          .select('habit_id, completed')
          .eq('user_id', uid)
          .eq('log_date', today)
          .eq('completed', true);

      return rows.map((item) => (item['habit_id'] ?? '').toString()).where((id) => id.isNotEmpty).toSet();
    } catch (_) {
      final start = DateTime.now();
      final dayStart = DateTime(start.year, start.month, start.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final rows = await client
          .from('habit_logs')
          .select('user_habit_id, done, logged_at')
          .eq('done', true)
          .gte('logged_at', dayStart.toIso8601String())
          .lt('logged_at', dayEnd.toIso8601String());

      return rows.map((item) => (item['user_habit_id'] ?? '').toString()).where((id) => id.isNotEmpty).toSet();
    }
  }

  Future<HabitModel> createHabit({
    required String title,
    required String description,
    required String category,
    required String frequency,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception('Usuário não autenticado');

    try {
      final row = await client
          .from('user_habits')
          .insert({
            'user_id': uid,
            'title': title,
            'description': description,
            'category': category,
            'frequency': frequency,
            'target_value': 1,
            'target_unit': 'vez',
            'active': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('*')
          .single();

      return HabitModel.fromMap(Map<String, dynamic>.from(row));
    } catch (_) {
      final row = await client
          .from('user_habits')
          .insert({
            'user_id': uid,
            'name': title,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*')
          .single();

      return HabitModel.fromMap(Map<String, dynamic>.from(row)).copyWith(
        description: description,
        category: category,
        frequency: frequency,
      );
    }
  }

  Future<void> updateHabit(HabitModel habit) async {
    try {
      await client.from('user_habits').update({
        'title': habit.title,
        'description': habit.description,
        'category': habit.category,
        'frequency': habit.frequency,
        'active': habit.active,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', habit.id);
    } catch (_) {
      await client.from('user_habits').update({'name': habit.title}).eq('id', habit.id);
    }
  }

  Future<void> removeHabit(String habitId) async {
    try {
      await client
          .from('user_habits')
          .update({'active': false, 'updated_at': DateTime.now().toIso8601String()}).eq('id', habitId);
    } catch (_) {
      await client.from('user_habits').delete().eq('id', habitId);
    }
  }

  Future<void> setHabitDoneToday({required String habitId, required bool completed}) async {
    final uid = userId;
    if (uid == null) return;

    final today = HamvitDateUtils.toIsoDate(DateTime.now());

    var saved = false;

    // Contrato atual (RCP): user_id + habit_id + log_date + completed
    try {
      final existing = await client
          .from('habit_logs')
          .select('id')
          .eq('user_id', uid)
          .eq('habit_id', habitId)
          .eq('log_date', today)
          .limit(1);

      if (existing.isEmpty) {
        await client.from('habit_logs').insert({
          'user_id': uid,
          'habit_id': habitId,
          'log_date': today,
          'completed': completed,
        });
      } else {
        await client.from('habit_logs').update({
          'completed': completed,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing.first['id']);
      }
      saved = true;
    } catch (_) {}

    // Contrato legado: user_habit_id + logged_at + done
    if (!saved) {
      final start = DateTime.now();
      final dayStart = DateTime(start.year, start.month, start.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      try {
        final existing = await client
            .from('habit_logs')
            .select('id')
            .eq('user_habit_id', habitId)
            .gte('logged_at', dayStart.toIso8601String())
            .lt('logged_at', dayEnd.toIso8601String())
            .limit(1);

        if (existing.isEmpty) {
          await client.from('habit_logs').insert({
            'user_id': uid,
            'user_habit_id': habitId,
            'logged_at': DateTime.now().toIso8601String(),
            'done': completed,
          });
        } else {
          await client.from('habit_logs').update({
            'done': completed,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', existing.first['id']);
        }
        saved = true;
      } catch (_) {}
    }

    if (!saved) {
      throw Exception('Falha ao salvar conclusão do hábito.');
    }

    await _upsertStreak(uid, completed);
  }

  Future<void> _upsertStreak(String uid, bool completed) async {
    final rows = await client
        .from('user_streaks')
        .select('*')
        .eq('user_id', uid)
        .eq('streak_type', 'habits')
        .limit(1);

    if (rows.isEmpty) {
      await client.from('user_streaks').insert({
        'user_id': uid,
        'streak_type': 'habits',
        'current_count': completed ? 1 : 0,
        'best_count': completed ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      });
      return;
    }

    final current = Map<String, dynamic>.from(rows.first);
    final currentCount = (current['current_count'] as num?)?.toInt() ?? 0;
    final bestCount = (current['best_count'] as num?)?.toInt() ?? currentCount;
    final updatedCurrent = completed ? currentCount + 1 : (currentCount > 0 ? currentCount - 1 : 0);
    final updatedBest = updatedCurrent > bestCount ? updatedCurrent : bestCount;

    await client.from('user_streaks').update({
      'current_count': updatedCurrent,
      'best_count': updatedBest,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', current['id']);
  }

  Future<Map<String, bool>> fetchWeeklyCompletionMap(List<HabitModel> habits) async {
    final uid = userId;
    if (uid == null || habits.isEmpty) return const {};

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    final map = <String, bool>{};

    for (var i = 0; i < 7; i++) {
      final day = start.add(Duration(days: i));
      final key = HamvitDateUtils.toIsoDate(day);
      map[key] = false;
    }

    try {
      final rows = await client
          .from('habit_logs')
          .select('log_date, completed')
          .eq('user_id', uid)
          .gte('log_date', HamvitDateUtils.toIsoDate(start))
          .eq('completed', true);

      for (final item in rows) {
        final key = (item['log_date'] ?? '').toString();
        if (map.containsKey(key)) {
          map[key] = true;
        }
      }
      return map;
    } catch (_) {
      return map;
    }
  }

  Future<HabitsDailySummary> fetchSummary(List<HabitModel> habits) async {
    final done = habits.where((habit) => habit.doneToday).length;
    final total = habits.length;

    var currentStreak = 0;
    var bestStreak = 0;
    final uid = userId;
    if (uid != null) {
      try {
        final rows = await client
            .from('user_streaks')
            .select('current_count, best_count')
            .eq('user_id', uid)
            .eq('streak_type', 'habits')
            .limit(1);
        if (rows.isNotEmpty) {
          currentStreak = (rows.first['current_count'] as num?)?.toInt() ?? 0;
          bestStreak = (rows.first['best_count'] as num?)?.toInt() ?? currentStreak;
        }
      } catch (_) {}
    }

    return HabitsDailySummary(
      total: total,
      completed: done,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }
}
