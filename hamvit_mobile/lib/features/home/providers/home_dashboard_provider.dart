import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/home_dashboard_repository.dart';
import '../domain/home_dashboard_model.dart';

final homeDashboardProvider = FutureProvider<HomeDashboardModel>((ref) async {
  final repository = ref.watch(homeDashboardRepositoryProvider);
  return repository.fetchToday();
});

final homeDashboardActionsProvider = Provider<HomeDashboardActions>((ref) {
  final repository = ref.watch(homeDashboardRepositoryProvider);
  return HomeDashboardActions(repository);
});

class HomeDashboardActions {
  HomeDashboardActions(this._repository);

  final HomeDashboardRepository _repository;

  Future<void> quickAddWater({int amountMl = 200}) =>
      _repository.quickAddWater(amountMl: amountMl);

  Future<void> quickAddMeal(int calories, {String mealType = 'lanche'}) =>
      _repository.quickAddMeal(calories: calories, mealType: mealType);

  void reflectMealCaloriesLocally(int calories) =>
      _repository.reflectMealCaloriesLocally(calories);

  Future<bool> quickCompleteHabit() => _repository.quickCompleteOneHabit();

  Future<void> quickStartWalk() => _repository.quickStartWalk();
}
