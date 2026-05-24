class WeightLogEntry {
  final String id;
  final double weightKg;
  final double? bmi;
  final DateTime loggedAt;
  final String? notes;

  const WeightLogEntry({
    required this.id,
    required this.weightKg,
    required this.bmi,
    required this.loggedAt,
    required this.notes,
  });
}

class BodyMeasurementEntry {
  final String id;
  final DateTime measuredAt;
  final double? waistCm;
  final double? abdomenCm;
  final double? chestCm;
  final double? armCm;
  final double? thighCm;
  final double? hipCm;

  const BodyMeasurementEntry({
    required this.id,
    required this.measuredAt,
    required this.waistCm,
    required this.abdomenCm,
    required this.chestCm,
    required this.armCm,
    required this.thighCm,
    required this.hipCm,
  });
}

class ProgressPhotoEntry {
  final String id;
  final String imageUrl;
  final DateTime takenAt;
  final String? notes;

  const ProgressPhotoEntry({
    required this.id,
    required this.imageUrl,
    required this.takenAt,
    required this.notes,
  });
}

class EvolutionDashboardData {
  final List<WeightLogEntry> weightLogs;
  final List<BodyMeasurementEntry> measurements;
  final List<ProgressPhotoEntry> photos;
  final double? profileWeightKg;
  final int? profileHeightCm;
  final double? targetWeightKg;

  const EvolutionDashboardData({
    required this.weightLogs,
    required this.measurements,
    required this.photos,
    required this.profileWeightKg,
    required this.profileHeightCm,
    required this.targetWeightKg,
  });
}