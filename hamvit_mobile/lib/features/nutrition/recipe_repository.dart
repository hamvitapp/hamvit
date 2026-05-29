import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_provider.dart';
import '../../core/hamvit_date_utils.dart';
import 'models/recipe.dart';
import 'models/recipe_ingredient.dart';
import 'models/recipe_step.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(supabaseClientProvider));
});

class RecipeRepository {
  final SupabaseClient? _client;

  RecipeRepository(this._client);

  SupabaseClient get _c {
    if (_client == null) throw Exception('Supabase indisponível');
    return _client!;
  }

  String? get _userId => _c.auth.currentUser?.id;

  // ──────────────────────────────────────────────
  // RECIPES CRUD
  // ──────────────────────────────────────────────

  Future<List<Recipe>> fetchRecipes({
    String? category,
    bool? premiumOnly,
    int? limit,
  }) async {
    final uid = _userId;
    if (uid == null) return [];

    var query = _c
        .from('recipes')
        .select('''
          *,
          is_favorited:user_favorite_recipes!left(user_id,recipe_id)
        ''');

    if (category != null) {
      query = query.eq('category', category);
    }

    if (premiumOnly != null) {
      query = query.eq('premium_only', premiumOnly);
    }

    final rows = await query
        .order('created_at', ascending: false)
        .limit(limit ?? 50);

    return rows.map<Recipe>((row) {
      final favs = row['is_favorited'] as List<dynamic>? ?? [];
      final isFav = favs.any((f) =>
          f is Map<String, dynamic> &&
          f['user_id']?.toString() == uid &&
          f['recipe_id']?.toString() == row['id']?.toString());
      return Recipe.fromJson({...row, 'is_favorited': isFav});
    }).toList();
  }

  Future<Recipe?> fetchRecipeById(String recipeId) async {
    final uid = _userId;
    final row = await _c
        .from('recipes')
        .select('''
          *,
          is_favorited:user_favorite_recipes!left(user_id,recipe_id)
        ''')
        .eq('id', recipeId)
        .maybeSingle();

    if (row == null) return null;

    final favs = row['is_favorited'] as List<dynamic>? ?? [];
    final isFav = favs.any((f) =>
        f is Map<String, dynamic> &&
        f['user_id']?.toString() == uid &&
        f['recipe_id']?.toString() == row['id']?.toString());

    return Recipe.fromJson({...row, 'is_favorited': isFav});
  }

  Future<List<RecipeIngredient>> fetchIngredients(String recipeId) async {
    final rows = await _c
        .from('recipe_ingredients')
        .select('*')
        .eq('recipe_id', recipeId)
        .order('step_order', ascending: true);

    return rows.map<RecipeIngredient>((r) => RecipeIngredient.fromJson(r)).toList();
  }

  Future<List<RecipeStep>> fetchSteps(String recipeId) async {
    final rows = await _c
        .from('recipe_steps')
        .select('*')
        .eq('recipe_id', recipeId)
        .order('step_order', ascending: true);

    return rows.map<RecipeStep>((r) => RecipeStep.fromJson(r)).toList();
  }

  Future<List<String>> fetchTags(String recipeId) async {
    final rows = await _c
        .from('recipe_tags_direct')
        .select('tag')
        .eq('recipe_id', recipeId);

    return rows.map<String>((r) => r['tag']?.toString() ?? '').where((t) => t.isNotEmpty).toList();
  }

  // ──────────────────────────────────────────────
  // SMART RECOMMENDATIONS
  // ──────────────────────────────────────────────

  Future<List<Recipe>> getSmartRecommendations({
    String? mealType,
    int? limit,
  }) async {
    final uid = _userId;
    if (uid == null) return [];

    final params = <String, dynamic>{
      'p_user_id': uid,
      if (mealType != null) 'p_meal_type': mealType,
      if (limit != null) 'p_limit': limit,
    };

    final result = await _c.rpc('get_smart_recipe_recommendations', params: params);

    if (result is List) {
      return result.map<Recipe>((r) => Recipe.fromJson(r as Map<String, dynamic>)).toList();
    }

    return [];
  }

  // ──────────────────────────────────────────────
  // REGISTER CONSUMPTION
  // ──────────────────────────────────────────────

  Future<String> registerConsumption({
    required String recipeId,
    required String mealType,
    double servings = 1.0,
  }) async {
    final uid = _userId;
    if (uid == null) throw Exception('Usuário não autenticado');

    final result = await _c.rpc('register_recipe_consumption', params: {
      'p_user_id': uid,
      'p_recipe_id': recipeId,
      'p_meal_type': mealType,
      'p_servings': servings,
      'p_consumed_at': DateTime.now().toIso8601String(),
    });

    return result?.toString() ?? '';
  }

  // ──────────────────────────────────────────────
  // FAVORITES
  // ──────────────────────────────────────────────

  Future<bool> toggleFavorite(String recipeId) async {
    final uid = _userId;
    if (uid == null) return false;

    try {
      final existing = await _c
          .from('user_favorite_recipes')
          .select('id')
          .eq('user_id', uid)
          .eq('recipe_id', recipeId)
          .maybeSingle();

      if (existing != null) {
        await _c
            .from('user_favorite_recipes')
            .delete()
            .eq('user_id', uid)
            .eq('recipe_id', recipeId);
        return false;
      } else {
        await _c.from('user_favorite_recipes').insert({
          'user_id': uid,
          'recipe_id': recipeId,
        });
        return true;
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<List<Recipe>> fetchFavorites() async {
    final uid = _userId;
    if (uid == null) return [];

    final rows = await _c
        .from('user_favorite_recipes')
        .select('recipe_id, recipes(*)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    return rows.map<Recipe>((row) {
      final recipeData = row['recipes'] as Map<String, dynamic>? ?? {};
      return Recipe.fromJson({...recipeData, 'is_favorited': true});
    }).toList();
  }

  bool isFavorited(String recipeId) => false; // Will be checked via fetchRecipeById

  // ──────────────────────────────────────────────
  // REJECTION
  // ──────────────────────────────────────────────

  Future<void> rejectRecipe(String recipeId, {String? reason}) async {
    final uid = _userId;
    if (uid == null) return;

    await _c.from('recipe_rejection_log').insert({
      'user_id': uid,
      'recipe_id': recipeId,
      'reason': reason ?? 'user_rejected',
    });
  }

  // ──────────────────────────────────────────────
  // MEAL HISTORY
  // ──────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> fetchMealHistory({int days = 7}) async {
    final uid = _userId;
    if (uid == null) return [];

    final startDate = DateTime.now().subtract(Duration(days: days));
    final dayStart = DateTime(startDate.year, startDate.month, startDate.day);

    final rows = await _c
        .from('meal_logs')
        .select('''
          id,
          meal_type,
          consumed_at,
          meal_date,
          total_calories_kcal,
          total_protein_g,
          total_carbs_g,
          total_fat_g,
          servings,
          recipe_id,
          recipes!left(name)
        ''')
        .eq('user_id', uid)
        .gte('consumed_at', dayStart.toIso8601String())
        .order('consumed_at', ascending: false);

    return rows.map<Map<String, dynamic>>((row) {
      final recipeData = row['recipes'] as Map<String, dynamic>?;
      return {
        ...row,
        'recipe_name': recipeData?['name']?.toString(),
      };
    }).toList();
  }
}