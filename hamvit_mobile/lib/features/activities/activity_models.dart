import 'package:latlong2/latlong.dart';

class ActivityRoutePoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final double? speedMps;
  final double? heading;
  final DateTime recordedAt;
  final int pointOrder;

  const ActivityRoutePoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.speedMps,
    this.heading,
    required this.recordedAt,
    required this.pointOrder,
  });

  LatLng toLatLng() => LatLng(latitude, longitude);

  Map<String, dynamic> toInsertJson({
    required String sessionId,
    required String userId,
  }) {
    return {
      'activity_session_id': sessionId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed_mps': speedMps,
      'heading': heading,
      'recorded_at': recordedAt.toIso8601String(),
      'point_order': pointOrder,
    };
  }
}

