import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../../onboarding/providers/onboarding_profile_provider.dart';
import 'food_preferences_model.dart';
import 'food_preferences_repository.dart';

class FoodPreferencesState {
  final bool isLoading;
  final bool isSaving;
  final bool isPremium;
  final FoodPreferencesModel model;
  final String? error;
  final bool saved;

  const FoodPreferencesState({
    this.isLoading = false,
    this.isSaving = false,
    this.isPremium = false,
    this.model = FoodPreferencesModel.empty,
    this.error,
    this.saved = false,
  });

  FoodPreferencesState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isPremium,
    FoodPreferencesModel? model,
    String? error,
    bool clearError = false,
    bool? saved,
  }) {
    return FoodPreferencesState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isPremium: isPremium ?? this.isPremium,
      model: model ?? this.model,
      error: clearError ? null : (error ?? this.error),
      saved: saved ?? this.saved,
    );
  }
}

final foodPreferencesControllerProvider = StateNotifierProvider<FoodPreferencesController, FoodPreferencesState>((ref) {
  return FoodPreferencesController(
    repository: ref.watch(foodPreferencesRepositoryProvider),
    isPremium: ref.watch(isPremiumProvider),
    saveLegacyFoodPreferences: (preferences, restrictions) {
      return ref.read(onboardingProfileProvider.notifier).saveFoodPreferences(
            preferences: preferences,
            restrictions: restrictions,
          );
    },
  );
});

class FoodPreferencesController extends StateNotifier<FoodPreferencesState> {
  final FoodPreferencesRepository _repository;
  final bool _isPremium;
  final Future<void> Function(List<String> preferences, List<String> restrictions) _saveLegacyFoodPreferences;

  FoodPreferencesController({
    required FoodPreferencesRepository repository,
    required bool isPremium,
    required Future<void> Function(List<String> preferences, List<String> restrictions) saveLegacyFoodPreferences,
  })  : _repository = repository,
        _isPremium = isPremium,
        _saveLegacyFoodPreferences = saveLegacyFoodPreferences,
        super(FoodPreferencesState(isLoading: true, isPremium: isPremium)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, saved: false);
    try {
      final model = await _repository.load();
      state = state.copyWith(
        isLoading: false,
        isPremium: _isPremium,
        model: model,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void toggleEatingStyle(String option) {
    _toggleListItem(state.model.eatingStyles, option, (next) => state.model.copyWith(eatingStyles: next));
  }

  void toggleRestriction(String option) {
    if (option == 'Nenhuma restrição') {
      if (state.model.restrictions.contains(option)) {
        state = state.copyWith(model: state.model.copyWith(restrictions: const []), saved: false);
      } else {
        state = state.copyWith(model: state.model.copyWith(restrictions: const ['Nenhuma restrição']), saved: false);
      }
      return;
    }

    final current = [...state.model.restrictions]..remove('Nenhuma restrição');
    _toggleListItem(current, option, (next) => state.model.copyWith(restrictions: next));
  }

  void addCustomRestriction(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;

    final current = [...state.model.restrictions]..remove('Nenhuma restrição');
    if (!current.contains(normalized)) current.add(normalized);
    state = state.copyWith(model: state.model.copyWith(restrictions: current), saved: false);
  }

  void removeRestriction(String value) {
    final current = [...state.model.restrictions]..remove(value);
    state = state.copyWith(model: state.model.copyWith(restrictions: current), saved: false);
  }

  void addDislikedFood(String value) {
    _addUniqueItem(state.model.dislikedFoods, value, (next) => state.model.copyWith(dislikedFoods: next));
  }

  void removeDislikedFood(String value) {
    final current = [...state.model.dislikedFoods]..remove(value);
    state = state.copyWith(model: state.model.copyWith(dislikedFoods: current), saved: false);
  }

  void addFavoriteFood(String value) {
    _addUniqueItem(state.model.favoriteFoods, value, (next) => state.model.copyWith(favoriteFoods: next));
  }

  void removeFavoriteFood(String value) {
    final current = [...state.model.favoriteFoods]..remove(value);
    state = state.copyWith(model: state.model.copyWith(favoriteFoods: current), saved: false);
  }

  void setMealsPerDay(int? value) {
    state = state.copyWith(model: state.model.copyWith(mealsPerDay: value), saved: false);
  }

  void setCookingFrequency(String value) {
    state = state.copyWith(model: state.model.copyWith(cookingFrequency: value), saved: false);
  }

  void setPrepTimePreference(String value) {
    state = state.copyWith(model: state.model.copyWith(prepTimePreference: value), saved: false);
  }

  void setLunchboxHabit(String value) {
    state = state.copyWith(model: state.model.copyWith(lunchboxHabit: value), saved: false);
  }

  void toggleFoodGoal(String option) {
    _toggleListItem(state.model.foodGoals, option, (next) => state.model.copyWith(foodGoals: next));
  }

  void toggleUsualMeal(String meal) {
    final current = [...state.model.usualMeals];
    final mealTimes = Map<String, String>.from(state.model.mealTimes);

    if (current.contains(meal)) {
      current.remove(meal);
      mealTimes.remove(meal);
    } else {
      current.add(meal);
    }

    state = state.copyWith(
      model: state.model.copyWith(usualMeals: current, mealTimes: mealTimes),
      saved: false,
    );
  }

  void setMealTime({required String meal, required String time}) {
    final normalized = time.trim();
    final mealTimes = Map<String, String>.from(state.model.mealTimes);

    if (normalized.isEmpty) {
      mealTimes.remove(meal);
    } else {
      mealTimes[meal] = normalized;
    }

    state = state.copyWith(model: state.model.copyWith(mealTimes: mealTimes), saved: false);
  }

  void toggleSuggestionStyle(String option) {
    _toggleListItem(state.model.suggestionStyle, option, (next) => state.model.copyWith(suggestionStyle: next));
  }

  Future<void> save() async {
    state = state.copyWith(isSaving: true, clearError: true, saved: false);

    try {
      await _repository.save(state.model);

      // Keep legacy onboarding gates coherent while the app migrates to dedicated food preferences.
      await _saveLegacyFoodPreferences(
        state.model.eatingStyles,
        state.model.restrictions.where((item) => item != 'Nenhuma restrição').toList(),
      );

      if (_isPremium) {
        await _repository.markPremiumRecommendationContext(state.model);
      }

      state = state.copyWith(isSaving: false, saved: true);
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  void resetSavedFlag() {
    if (!state.saved) return;
    state = state.copyWith(saved: false);
  }

  void _toggleListItem(
    List<String> source,
    String option,
    FoodPreferencesModel Function(List<String> next) mapper,
  ) {
    final current = [...source];
    if (current.contains(option)) {
      current.remove(option);
    } else {
      current.add(option);
    }

    state = state.copyWith(model: mapper(current), saved: false);
  }

  void _addUniqueItem(
    List<String> source,
    String value,
    FoodPreferencesModel Function(List<String> next) mapper,
  ) {
    final normalized = value.trim();
    if (normalized.isEmpty) return;

    final current = [...source];
    if (!current.contains(normalized)) {
      current.add(normalized);
      state = state.copyWith(model: mapper(current), saved: false);
    }
  }
}
