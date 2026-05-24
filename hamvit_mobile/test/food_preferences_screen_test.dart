import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:hamvit_mobile/features/meal_recommendations/meal_recommendations_page.dart';
import 'package:hamvit_mobile/features/nutrition/preferences/food_preferences_controller.dart';
import 'package:hamvit_mobile/features/nutrition/preferences/food_preferences_model.dart';
import 'package:hamvit_mobile/features/nutrition/preferences/food_preferences_screen.dart';

class _FakeFoodPreferencesController extends StateNotifier<FoodPreferencesState>
    implements FoodPreferencesController {
  _FakeFoodPreferencesController({
    required bool isPremium,
    required FoodPreferencesModel model,
  }) : super(
          FoodPreferencesState(
            isLoading: false,
            isPremium: isPremium,
            model: model,
          ),
        );

  @override
  Future<void> load() async {}

  @override
  Future<void> save() async {
    state = state.copyWith(saved: true, isSaving: false, clearError: true);
  }

  @override
  void resetSavedFlag() {
    state = state.copyWith(saved: false);
  }

  @override
  void addCustomRestriction(String value) {}

  @override
  void addDislikedFood(String value) {}

  @override
  void addFavoriteFood(String value) {}

  @override
  void removeDislikedFood(String value) {}

  @override
  void removeFavoriteFood(String value) {}

  @override
  void removeRestriction(String value) {}

  @override
  void setCookingFrequency(String value) {}

  @override
  void setLunchboxHabit(String value) {}

  @override
  void setMealTime({required String meal, required String time}) {}

  @override
  void setMealsPerDay(int? value) {}

  @override
  void setPrepTimePreference(String value) {}

  @override
  void toggleEatingStyle(String option) {}

  @override
  void toggleFoodGoal(String option) {}

  @override
  void toggleRestriction(String option) {}

  @override
  void toggleSuggestionStyle(String option) {}

  @override
  void toggleUsualMeal(String meal) {}
}

void main() {
  FoodPreferencesModel sampleModel() => const FoodPreferencesModel(
        eatingStyles: ['Caseiro', 'Alto em proteína'],
        restrictions: ['Lactose'],
        dislikedFoods: ['brócolis'],
        favoriteFoods: ['arroz', 'feijão'],
        mealsPerDay: 4,
        cookingFrequency: 'Às vezes',
        prepTimePreference: '15–30 min',
        lunchboxHabit: 'Sim',
        foodGoals: ['Comer melhor'],
        usualMeals: ['Almoço', 'Jantar'],
        mealTimes: {'Almoço': '12:30', 'Jantar': '19:30'},
        suggestionStyle: ['Mais rápidas'],
      );

  testWidgets('Fluxo Free salva e retorna com snackbar', (tester) async {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/prefs'),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/prefs', builder: (context, state) => const FoodPreferencesScreen()),
        GoRoute(path: '/premium', builder: (context, state) => const Scaffold(body: Text('Premium'))),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodPreferencesControllerProvider.overrideWith(
            (ref) => _FakeFoodPreferencesController(
              isPremium: false,
              model: sampleModel(),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Preferências Alimentares'), findsOneWidget);
    expect(find.text('Premium desbloqueia sugestões inteligentes.'), findsOneWidget);

    await tester.tap(find.text('Salvar preferências'));
    await tester.pumpAndSettle();

    expect(find.text('Preferências salvas com sucesso.'), findsOneWidget);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('Premium exibe selo ativo e sem card de upsell final', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foodPreferencesControllerProvider.overrideWith(
            (ref) => _FakeFoodPreferencesController(
              isPremium: true,
              model: sampleModel(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: FoodPreferencesScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Sugestões personalizadas ativas.'), findsOneWidget);
    expect(find.text('Conhecer Premium'), findsNothing);
  });

  testWidgets('Sugestões inteligentes: Free bloqueado e Premium liberado', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MealRecommendationsPage(isPremium: false)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Conhecer Premium'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MealRecommendationsPage(isPremium: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sugestões Premium'), findsOneWidget);
    expect(find.text('Adicionar ao diário'), findsWidgets);
  });
}
