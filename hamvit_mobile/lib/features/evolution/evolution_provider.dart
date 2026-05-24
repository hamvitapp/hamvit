import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/providers/home_dashboard_provider.dart';
import 'evolution_models.dart';
import 'evolution_repository.dart';

final evolutionDashboardProvider = FutureProvider<EvolutionDashboardData>((ref) async {
  final repository = ref.watch(evolutionRepositoryProvider);
  return repository.loadDashboard();
});

final evolutionActionsProvider = Provider<EvolutionActions>((ref) {
  final repository = ref.watch(evolutionRepositoryProvider);
  return EvolutionActions(ref: ref, repository: repository);
});

class EvolutionActions {
  final Ref ref;
  final EvolutionRepository repository;

  EvolutionActions({required this.ref, required this.repository});

  Future<void> addWeight({
    required double weightKg,
    required DateTime loggedAt,
    String? notes,
    required int? heightCm,
  }) async {
    await repository.addWeightLog(
      weightKg: weightKg,
      loggedAt: loggedAt,
      notes: notes,
      heightCm: heightCm,
    );
    ref.invalidate(evolutionDashboardProvider);
    ref.invalidate(homeDashboardProvider);
  }

  Future<void> addMeasurement({
    required DateTime measuredAt,
    double? waistCm,
    double? abdomenCm,
    double? chestCm,
    double? armCm,
    double? thighCm,
    double? hipCm,
  }) async {
    await repository.addBodyMeasurement(
      measuredAt: measuredAt,
      waistCm: waistCm,
      abdomenCm: abdomenCm,
      chestCm: chestCm,
      armCm: armCm,
      thighCm: thighCm,
      hipCm: hipCm,
    );
    ref.invalidate(evolutionDashboardProvider);
  }

  Future<void> addPhoto({
    required String imageUrl,
    required DateTime takenAt,
    String? notes,
  }) async {
    await repository.addProgressPhoto(
      imageUrl: imageUrl,
      takenAt: takenAt,
      notes: notes,
    );
    ref.invalidate(evolutionDashboardProvider);
  }
}