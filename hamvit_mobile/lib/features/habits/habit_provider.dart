import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'habit_controller.dart';
import 'habit_repository.dart';

final habitsControllerProvider = StateNotifierProvider<HabitsController, HabitsState>((ref) {
  return HabitsController(repository: ref.watch(habitRepositoryProvider));
});

final habitsCompletedRatioProvider = Provider<double>((ref) {
  final state = ref.watch(habitsControllerProvider);
  return state.summary.progress;
});

final habitsTodaySummaryLabelProvider = Provider<String>((ref) {
  final summary = ref.watch(habitsControllerProvider).summary;
  return '${summary.completed} de ${summary.total} hábitos concluídos hoje';
});
