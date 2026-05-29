import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../privacy/app_blur_overlay.dart';
import '../../theme/hamvit_colors.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';
import 'add_weight_screen.dart';
import 'body_measurements_screen.dart';
import 'domain/bmi_calculator.dart';
import 'domain/body_metrics_service.dart';
import 'domain/evolution_insights_engine.dart';
import 'domain/weight_progress_engine.dart';
import 'evolution_provider.dart';
import 'progress_photos_screen.dart';
import 'weight_history_screen.dart';
import 'widgets/evolution_widgets.dart';

enum _WeightRange { d7, d30, d90, y1, all }

class EvolutionScreen extends ConsumerStatefulWidget {
  const EvolutionScreen({super.key});

  @override
  ConsumerState<EvolutionScreen> createState() => _EvolutionScreenState();
}

class _EvolutionScreenState extends ConsumerState<EvolutionScreen> {
  _WeightRange _range = _WeightRange.d30;

  List<_WeightRange> get _ranges => _WeightRange.values;

  String _rangeLabel(_WeightRange range) {
    return switch (range) {
      _WeightRange.d7 => '7 dias',
      _WeightRange.d30 => '30 dias',
      _WeightRange.d90 => '90 dias',
      _WeightRange.y1 => '1 ano',
      _WeightRange.all => 'Tudo',
    };
  }

  DateTime _cutoffFor(_WeightRange range) {
    final now = DateTime.now();
    return switch (range) {
      _WeightRange.d7 => now.subtract(const Duration(days: 7)),
      _WeightRange.d30 => now.subtract(const Duration(days: 30)),
      _WeightRange.d90 => now.subtract(const Duration(days: 90)),
      _WeightRange.y1 => now.subtract(const Duration(days: 365)),
      _WeightRange.all => DateTime(2000),
    };
  }

  Future<void> _openAddWeight(int? heightCm) async {
    final actions = ref.read(evolutionActionsProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddWeightScreen(
        onSave: (payload) => actions.addWeight(
          weightKg: payload.weightKg,
          loggedAt: payload.loggedAt,
          notes: payload.notes,
          heightCm: heightCm,
        ),
      ),
    );
  }

  Future<void> _openMeasurements() async {
    final actions = ref.read(evolutionActionsProvider);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BodyMeasurementsScreen(
        onSave: (payload) => actions.addMeasurement(
          measuredAt: payload.measuredAt,
          waistCm: payload.waistCm,
          abdomenCm: payload.abdomenCm,
          chestCm: payload.chestCm,
          armCm: payload.armCm,
          thighCm: payload.thighCm,
          hipCm: payload.hipCm,
        ),
      ),
    );
  }

  Future<void> _openPhotos(List photos) async {
    final actions = ref.read(evolutionActionsProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProgressPhotosScreen(
          photos: photos.cast(),
          onAddPhoto: (path, notes) => actions.addPhoto(
            imageUrl: path,
            takenAt: DateTime.now(),
            notes: notes,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(evolutionDashboardProvider);

    return HamvitProtectedScreenWrapper(
      child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Falha ao carregar evolucao: $error'),
          ),
        ),
        data: (data) {
          final onboarding = ref.watch(onboardingProfileProvider);
          final allLogsAsc = [...data.weightLogs]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
          final cutoff = _cutoffFor(_range);
          final rangeLogs = _range == _WeightRange.all
              ? allLogsAsc
              : allLogsAsc.where((e) => !e.loggedAt.isBefore(cutoff)).toList();

          final effectiveTargetWeight =
              data.targetWeightKg ?? onboarding.targetWeightKg;

          final summary = WeightProgressEngine.build(
            logs: allLogsAsc,
            fallbackCurrentWeight: data.profileWeightKg,
            targetWeight: effectiveTargetWeight,
          );

          final initialBmi = allLogsAsc.isNotEmpty
              ? (allLogsAsc.first.bmi ?? BmiCalculator.calculate(weightKg: allLogsAsc.first.weightKg, heightCm: data.profileHeightCm))
              : null;
          final currentBmi = allLogsAsc.isNotEmpty
              ? (allLogsAsc.last.bmi ??
                  BmiCalculator.calculate(
                    weightKg: allLogsAsc.last.weightKg,
                    heightCm: data.profileHeightCm,
                  ))
              : BmiCalculator.calculate(
                  weightKg: data.profileWeightKg,
                  heightCm: data.profileHeightCm,
                );

          final insights = EvolutionInsightsEngine.build(
            summary: summary,
            registerCount: allLogsAsc.length,
            latestBmi: currentBmi,
          );

          final bodyDeltas = BodyMetricsService.computeDeltas(data.measurements);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
            Text(
              'Peso, medidas e consistencia com visao de longo prazo.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: HamvitColors.darkTextMuted),
            ),
            const SizedBox(height: 12),
            HamvitEvolutionSummaryCard(
              initialWeight: summary.initialWeightKg,
              currentWeight: summary.currentWeightKg,
              targetWeight: summary.targetWeightKg,
              progressPercent: summary.progressPercent,
              initialBmi: initialBmi,
              currentBmi: currentBmi,
              daysSinceStart: summary.daysSinceStart,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _ranges
                  .map(
                    (r) => ChoiceChip(
                      selected: _range == r,
                      label: Text(_rangeLabel(r)),
                      onSelected: (_) => setState(() => _range = r),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            HamvitWeightChart(logs: rangeLogs),
            HamvitBMIHistoryCard(
              initialBmi: initialBmi,
              currentBmi: currentBmi,
              classification: BmiCalculator.classify(currentBmi),
            ),
            HamvitGoalProgressCard(
              currentWeight: summary.currentWeightKg,
              targetWeight: summary.targetWeightKg,
              progressPercent: summary.progressPercent,
              healthyEstimate: WeightProgressEngine.healthyPaceEstimate(
                currentWeight: summary.currentWeightKg,
                targetWeight: summary.targetWeightKg,
              ),
            ),
            const SizedBox(height: 8),
            HamvitAddWeightButton(
              onPressed: () => _openAddWeight(data.profileHeightCm),
            ),
            const SizedBox(height: 8),
            HamvitBodyMeasurementsCard(
              deltas: bodyDeltas,
              totalEntries: data.measurements.length,
              onAdd: _openMeasurements,
            ),
            const SizedBox(height: 8),
            HamvitProgressPhotosCard(
              photos: data.photos,
              onOpen: () => _openPhotos(data.photos),
            ),
            const SizedBox(height: 8),
            HamvitWeightHistoryList(logs: allLogsAsc.reversed.toList()),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => WeightHistoryScreen(logs: allLogsAsc.reversed.toList())),
                  );
                },
                icon: const Icon(Icons.history),
                label: const Text('Abrir historico completo'),
              ),
            ),
            const SizedBox(height: 6),
            HamvitEvolutionInsightsCard(insights: insights),
            ],
          );
        },
      ),
    );
  }
}
