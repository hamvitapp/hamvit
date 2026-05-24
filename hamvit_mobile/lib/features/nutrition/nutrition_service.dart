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

  Future<Map<String, dynamic>?> lookupBarcode(String barcode) async {
    final client = _client;
    if (client == null) return null;
    final result = await client.functions.invoke(
      'scanner',
      body: {'barcode': barcode},
    );
    if (result.data is Map<String, dynamic>) return result.data as Map<String, dynamic>;
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
    final objectPath = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await client.storage.from('food-photos').uploadBinary(
          objectPath,
          bytes,
          fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
        );

    final result = await client.functions.invoke(
      'food-photo',
      body: {
        'user_id': user.id,
        'storage_path': objectPath,
      },
    );
    if (result.data is Map<String, dynamic>) return result.data as Map<String, dynamic>;
    return null;
  }

  Future<List<Map<String, dynamic>>> getPremiumSuggestions({required String mealType}) async {
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
