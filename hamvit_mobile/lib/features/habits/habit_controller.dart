import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'habit_model.dart';
import 'habit_repository.dart';

class HabitsState {
  final bool isLoading;
  final List<HabitModel> habits;
  final HabitsDailySummary summary;
  final Map<String, bool> weeklyCompletion;
  final String? error;

  const HabitsState({
    this.isLoading = false,
    this.habits = const [],
    this.summary = const HabitsDailySummary(total: 0, completed: 0, currentStreak: 0, bestStreak: 0),
    this.weeklyCompletion = const {},
    this.error,
  });

  HabitsState copyWith({
    bool? isLoading,
    List<HabitModel>? habits,
    HabitsDailySummary? summary,
    Map<String, bool>? weeklyCompletion,
    String? error,
  }) {
    return HabitsState(
      isLoading: isLoading ?? this.isLoading,
      habits: habits ?? this.habits,
      summary: summary ?? this.summary,
      weeklyCompletion: weeklyCompletion ?? this.weeklyCompletion,
      error: error,
    );
  }
}

class HabitsController extends StateNotifier<HabitsState> {
  final HabitRepository repository;

  HabitsController({required this.repository}) : super(const HabitsState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final habits = await repository.fetchHabits();
      final summary = await repository.fetchSummary(habits);
      final weekly = await repository.fetchWeeklyCompletionMap(habits);
      state = state.copyWith(isLoading: false, habits: habits, summary: summary, weeklyCompletion: weekly, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> createHabit({
    required String title,
    required String category,
    required String frequency,
    required String description,
  }) async {
    await repository.createHabit(
      title: title,
      description: description,
      category: category,
      frequency: frequency,
    );
    await load();
  }

  Future<void> useTemplate(HabitTemplate template) async {
    await createHabit(
      title: template.title,
      category: template.category,
      frequency: template.frequency,
      description: template.description,
    );
  }

  Future<void> updateHabit(HabitModel habit) async {
    await repository.updateHabit(habit);
    await load();
  }

  Future<void> removeHabit(HabitModel habit) async {
    await repository.removeHabit(habit.id);
    await load();
  }

  Future<void> toggleHabit(HabitModel habit, bool completed) async {
    await repository.setHabitDoneToday(habitId: habit.id, completed: completed);
    await load();
  }
}
