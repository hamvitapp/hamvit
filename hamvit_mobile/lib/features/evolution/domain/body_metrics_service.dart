import '../evolution_models.dart';

class BodyMetricsDelta {
  final String label;
  final double? first;
  final double? latest;

  const BodyMetricsDelta({required this.label, required this.first, required this.latest});

  double? get change {
    if (first == null || latest == null) return null;
    return latest! - first!;
  }
}

class BodyMetricsService {
  static List<BodyMetricsDelta> computeDeltas(List<BodyMeasurementEntry> entries) {
    if (entries.isEmpty) return const [];

    final sorted = [...entries]..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
    final first = sorted.first;
    final latest = sorted.last;

    return [
      BodyMetricsDelta(label: 'Cintura', first: first.waistCm, latest: latest.waistCm),
      BodyMetricsDelta(label: 'Abdomen', first: first.abdomenCm, latest: latest.abdomenCm),
      BodyMetricsDelta(label: 'Peito', first: first.chestCm, latest: latest.chestCm),
      BodyMetricsDelta(label: 'Braco', first: first.armCm, latest: latest.armCm),
      BodyMetricsDelta(label: 'Coxa', first: first.thighCm, latest: latest.thighCm),
      BodyMetricsDelta(label: 'Quadril', first: first.hipCm, latest: latest.hipCm),
    ];
  }
}