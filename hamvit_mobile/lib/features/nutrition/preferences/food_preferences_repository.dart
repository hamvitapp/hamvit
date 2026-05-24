import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'food_preferences_model.dart';

final foodPreferencesRepositoryProvider = Provider<FoodPreferencesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  return FoodPreferencesRepository(
    client: client,
    userId: ref.watch(currentUserProvider)?.id,
  );
});

class FoodPreferencesRepository {
  final SupabaseClient client;
  final String? userId;

  FoodPreferencesRepository({required this.client, required this.userId});

  Future<FoodPreferencesModel> load() async {
    final uid = userId;
    if (uid == null) return FoodPreferencesModel.empty;

    try {
      final rows = await client
          .from('user_food_preferences')
          .select('*')
          .eq('user_id', uid)
          .order('updated_at', ascending: false)
          .limit(1);

      if (rows.isEmpty) {
        return await _loadLegacyFromUserPreferences(uid);
      }

      return FoodPreferencesModel.fromMap(Map<String, dynamic>.from(rows.first));
    } catch (_) {
      return await _loadLegacyFromUserPreferences(uid);
    }
  }

  Future<void> save(FoodPreferencesModel model) async {
    final uid = userId;
    if (uid == null) throw Exception('Usuário não autenticado');

    final payload = model.toDbMap(uid);

    try {
      await client.from('user_food_preferences').upsert(payload, onConflict: 'user_id');
    } catch (_) {
      // Ignore while migration is not yet applied in some environments.
    }

    await _saveLegacyOnboardingFood(
      uid: uid,
      preferences: model.eatingStyles,
      restrictions: model.restrictions.where((item) => item.toLowerCase() != 'nenhuma restrição').toList(),
    );
  }

  Future<void> markPremiumRecommendationContext(FoodPreferencesModel model) async {
    final uid = userId;
    if (uid == null) return;

    try {
      final current = await _loadCurrentUserPreferencesRow(uid);
      final data = Map<String, dynamic>.from((current?['data'] as Map?) ?? {});
      data['premium_food_context'] = {
        'updated_at': DateTime.now().toIso8601String(),
        'eating_styles': model.eatingStyles,
        'restrictions': model.restrictions,
        'goals': model.foodGoals,
        'suggestion_style': model.suggestionStyle,
      };

      if (current != null) {
        await client.from('user_preferences').update({'data': data}).eq('id', current['id']);
      } else {
        await client.from('user_preferences').insert({
          'user_id': uid,
          'data': data,
        });
      }
    } catch (_) {
      // Ignore non-critical sync metadata errors.
    }
  }

  Future<FoodPreferencesModel> _loadLegacyFromUserPreferences(String uid) async {
    final current = await _loadCurrentUserPreferencesRow(uid);
    if (current == null) return FoodPreferencesModel.empty;

    final data = Map<String, dynamic>.from((current['data'] as Map?) ?? {});
    final onboarding = _asMap(data['onboarding']);
    final food = _asMap(onboarding['food']);

    return FoodPreferencesModel(
      eatingStyles: _asStringList(food['preferences']),
      restrictions: _asStringList(food['restrictions']),
    );
  }

  Future<void> _saveLegacyOnboardingFood({
    required String uid,
    required List<String> preferences,
    required List<String> restrictions,
  }) async {
    try {
      final current = await _loadCurrentUserPreferencesRow(uid);
      final data = Map<String, dynamic>.from((current?['data'] as Map?) ?? {});
      final onboarding = _asMap(data['onboarding']);

      onboarding['food'] = {
        'preferences': preferences,
        'restrictions': restrictions,
      };

      final flows = _asMap(onboarding['flows']);
      flows['food'] = true;
      onboarding['flows'] = flows;
      data['onboarding'] = onboarding;

      if (current != null) {
        await client.from('user_preferences').update({'data': data}).eq('id', current['id']);
      } else {
        await client.from('user_preferences').insert({'user_id': uid, 'data': data});
      }
    } catch (_) {
      // Ignore legacy write errors.
    }
  }

  Future<Map<String, dynamic>?> _loadCurrentUserPreferencesRow(String uid) async {
    final rows = await client
        .from('user_preferences')
        .select('*')
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(1);

    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(rows.first as Map);
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
    }
    return const [];
  }
}
