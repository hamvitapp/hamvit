import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/recipe.dart';
import 'models/recipe_ingredient.dart';
import 'models/recipe_step.dart';
import 'recipe_repository.dart';

// ──────────────────────────────────────────────
// RECIPES PROVIDERS
// ──────────────────────────────────────────────

final allRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchRecipes();
});

final premiumRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchRecipes(premiumOnly: true);
});

final freeRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchRecipes(premiumOnly: false);
});

final recipeByIdProvider = FutureProvider.family<Recipe?, String>((ref, id) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchRecipeById(id);
});

final recipeIngredientsProvider = FutureProvider.family<List<RecipeIngredient>, String>((ref, recipeId) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchIngredients(recipeId);
});

final recipeStepsProvider = FutureProvider.family<List<RecipeStep>, String>((ref, recipeId) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchSteps(recipeId);
});

final recipeTagsProvider = FutureProvider.family<List<String>, String>((ref, recipeId) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchTags(recipeId);
});

// ──────────────────────────────────────────────
// SMART RECOMMENDATIONS
// ──────────────────────────────────────────────

final smartRecommendationsProvider = FutureProvider.family<List<Recipe>, String?>((ref, mealType) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.getSmartRecommendations(mealType: mealType, limit: 6);
});

// ──────────────────────────────────────────────
// FAVORITES
// ──────────────────────────────────────────────

final favoriteRecipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchFavorites();
});

// ──────────────────────────────────────────────
// MEAL HISTORY
// ──────────────────────────────────────────────

final mealHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(recipeRepositoryProvider);
  return repo.fetchMealHistory(days: 7);
});