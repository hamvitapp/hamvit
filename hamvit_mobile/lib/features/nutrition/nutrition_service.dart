import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_provider.dart';

final nutritionServiceProvider = Provider<NutritionService>((ref) {
  return NutritionService(ref.watch(supabaseClientProvider));
});

class NutritionService {
  final SupabaseClient? _client;
  NutritionService(this._client);

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

  Future<Map<String, dynamic>> registerMeal({
    required String mealType,
    required int calories,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponível');
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final now = DateTime.now();
    final localDate = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final meal = await client
        .from('meal_logs')
        .insert({
          'user_id': user.id,
          'meal_type': mealType,
          'meal_date': localDate,
          'consumed_at': now.toIso8601String(),
          'created_at': now.toIso8601String(),
        })
        .select('id, meal_type')
        .single();

    await client.from('meal_items').insert({
      'meal_log_id': meal['id'],
      'calories': calories,
    });

    return {
      'meal_id': meal['id'],
      'meal_type': (meal['meal_type'] ?? mealType).toString(),
      'calories': calories,
    };
  }

  Future<List<Map<String, dynamic>>> fetchTodayMeals() async {
    final client = _client;
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final logs = await client
        .from('meal_logs')
        .select('id, meal_type, consumed_at')
        .eq('user_id', user.id)
        .gte('consumed_at', dayStart.toIso8601String())
        .lt('consumed_at', dayEnd.toIso8601String())
        .order('consumed_at');

    final ids = logs
        .map((e) => e['id']?.toString())
        .whereType<String>()
        .toList(growable: false);

    final caloriesByMeal = <String, int>{};
    if (ids.isNotEmpty) {
      final items = await client
          .from('meal_items')
          .select('meal_log_id, calories')
          .inFilter('meal_log_id', ids);

      for (final row in items) {
        final mealId = row['meal_log_id']?.toString();
        if (mealId == null) continue;
        caloriesByMeal[mealId] =
            (caloriesByMeal[mealId] ?? 0) + _toInt(row['calories']);
      }
    }

    return logs.map<Map<String, dynamic>>((row) {
      final id = row['id']?.toString() ?? '';
      return {
        'meal_type': (row['meal_type'] ?? 'lanche').toString(),
        'calories': caloriesByMeal[id] ?? 0,
      };
    }).toList(growable: false);
  }

  Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    final client = _client;
    if (client == null) return null;
    final result = await client.functions.invoke(
      'scanner',
      body: {'barcode': barcode},
    );
    if (result.data is Map<String, dynamic>)
      return result.data as Map<String, dynamic>;
    return null;
  }

  Future<Map<String, dynamic>?> analyzeFoodPhoto({
    required String filePath,
    required bool isPremium,
  }) async {
    final client = _client;
    if (client == null) return null;
    final user = client.auth.currentUser;
    if (user == null) return null;

    if (!isPremium) {
      return {'allowed': false, 'reason': 'premium_required'};
    }

    final bytes = await File(filePath).readAsBytes();
    final objectPath =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage.from('food-photos').uploadBinary(
          objectPath,
          bytes,
          fileOptions:
              const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );

    final result = await client.functions.invoke(
      'food-photo',
      body: {
        'user_id': user.id,
        'storage_path': objectPath,
      },
    );
    if (result.data is Map<String, dynamic>)
      return result.data as Map<String, dynamic>;
    return null;
  }

  Future<List<Map<String, dynamic>>> getPremiumSuggestions(
      {required String mealType}) async {
    final client = _client;
    if (client == null) return const [];
    final user = client.auth.currentUser;
    if (user == null) return const [];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rows = await client
        .from('user_meal_plan_suggestions')
        .select('*, recipes(name, prep_time_min), reason')
        .eq('user_id', user.id)
        .eq('suggestion_date', today)
        .eq('meal_type', mealType)
        .order('score', ascending: false)
        .limit(5);
    return List<Map<String, dynamic>>.from(rows);
  }
}
