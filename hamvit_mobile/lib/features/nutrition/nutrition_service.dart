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
    final localDate =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
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

  Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    final client = _client;
    if (client == null) return const [];
    var request = client
        .from('foods')
        .select('id, name, calories, protein_g, carbs_g, fats_g, source');
    final normalized = query.trim();
    if (normalized.isNotEmpty) {
      request = request.ilike('name', '%$normalized%');
    }
    final rows = await request.order('name').limit(30);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> registerDetailedMeal({
    required String mealType,
    required List<Map<String, dynamic>> items,
  }) async {
    final client = _client;
    if (client == null) throw Exception('Supabase indisponível');
    if (client.auth.currentUser == null) {
      throw Exception('Usuário não autenticado');
    }

    final now = DateTime.now();
    final mealId = await client.rpc(
      'register_manual_meal',
      params: {
        'p_meal_type': mealType,
        'p_consumed_at': now.toIso8601String(),
        'p_items': items
            .map((item) => {
                  'food_id': item['food_id'],
                  'grams': item['grams'],
                  'quantity': item['quantity'] ?? item['grams'],
                  'portion_label': item['portion_label'] ?? 'gramas',
                })
            .toList(growable: false),
      },
    );

    return {
      'meal_id': mealId.toString(),
      'meal_type': mealType,
      'calories': _sum(items, 'calories'),
      'protein_g': _sum(items, 'protein_g'),
      'carbs_g': _sum(items, 'carbs_g'),
      'fat_g': _sum(items, 'fat_g'),
    };
  }

  int _sum(List<Map<String, dynamic>> items, String key) {
    return items.fold<int>(0, (total, item) => total + _toInt(item[key]));
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
        .select(
            'id, meal_type, consumed_at, total_calories_kcal, total_protein_g, total_carbs_g, total_fat_g')
        .eq('user_id', user.id)
        .gte('consumed_at', dayStart.toIso8601String())
        .lt('consumed_at', dayEnd.toIso8601String())
        .order('consumed_at');

    final ids = logs
        .map((e) => e['id']?.toString())
        .whereType<String>()
        .toList(growable: false);

    final itemsByMeal = <String, Map<String, int>>{};
    if (ids.isNotEmpty) {
      final items = await client
          .from('meal_items')
          .select('meal_log_id, calories, protein_g, carbs_g, fats_g')
          .inFilter('meal_log_id', ids);

      for (final row in items) {
        final mealId = row['meal_log_id']?.toString();
        if (mealId == null) continue;
        final totals = itemsByMeal.putIfAbsent(
          mealId,
          () => {'calories': 0, 'protein_g': 0, 'carbs_g': 0, 'fat_g': 0},
        );
        totals['calories'] = totals['calories']! + _toInt(row['calories']);
        totals['protein_g'] = totals['protein_g']! + _toInt(row['protein_g']);
        totals['carbs_g'] = totals['carbs_g']! + _toInt(row['carbs_g']);
        totals['fat_g'] = totals['fat_g']! + _toInt(row['fats_g']);
      }
    }

    return logs.map<Map<String, dynamic>>((row) {
      final id = row['id']?.toString() ?? '';
      final itemTotals = itemsByMeal[id] ?? const <String, int>{};
      return {
        'meal_type': (row['meal_type'] ?? 'lanche').toString(),
        'calories': _toInt(row['total_calories_kcal']) > 0
            ? _toInt(row['total_calories_kcal'])
            : (itemTotals['calories'] ?? 0),
        'protein_g': _toInt(row['total_protein_g']) > 0
            ? _toInt(row['total_protein_g'])
            : (itemTotals['protein_g'] ?? 0),
        'carbs_g': _toInt(row['total_carbs_g']) > 0
            ? _toInt(row['total_carbs_g'])
            : (itemTotals['carbs_g'] ?? 0),
        'fat_g': _toInt(row['total_fat_g']) > 0
            ? _toInt(row['total_fat_g'])
            : (itemTotals['fat_g'] ?? 0),
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
