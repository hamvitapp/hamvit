import 'package:flutter_riverpod/flutter_riverpod.dart';

class ActivityLiveData {
  final double distanceKm;
  final int activeMinutes;
  final int caloriesKcal;

  const ActivityLiveData({
    required this.distanceKm,
    required this.activeMinutes,
    required this.caloriesKcal,
  });
}

// provider criado dinamicamente em outro arquivo para evitar dependencias
// circulares no import
// provider criado dinamicamente em outro arquivo para evitar dependencias
// circulares no import

final activityLiveStateProvider = StateProvider<ActivityLiveData?>((ref) => null);
