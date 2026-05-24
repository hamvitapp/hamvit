import 'package:flutter_test/flutter_test.dart';

import 'package:hamvit_mobile/features/evolution/domain/bmi_calculator.dart';
import 'package:hamvit_mobile/features/evolution/domain/weight_progress_engine.dart';
import 'package:hamvit_mobile/features/evolution/evolution_models.dart';

void main() {
  test('bmi calculator computes expected value', () {
    final bmi = BmiCalculator.calculate(weightKg: 80, heightCm: 175);
    expect(bmi, isNotNull);
    expect(bmi!, closeTo(26.1, 0.2));
  });

  test('weight progress computes summary and percent', () {
    final logs = [
      WeightLogEntry(
        id: '1',
        weightKg: 95,
        bmi: null,
        loggedAt: DateTime(2026, 1, 1),
        notes: null,
      ),
      WeightLogEntry(
        id: '2',
        weightKg: 90,
        bmi: null,
        loggedAt: DateTime(2026, 2, 1),
        notes: null,
      ),
    ];

    final summary = WeightProgressEngine.build(
      logs: logs,
      fallbackCurrentWeight: null,
      targetWeight: 80,
    );

    expect(summary.initialWeightKg, 95);
    expect(summary.currentWeightKg, 90);
    expect(summary.progressPercent, closeTo(33.3, 1.0));
    expect(summary.daysSinceStart, 31);
  });
}
