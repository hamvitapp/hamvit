import 'package:supabase_flutter/supabase_flutter.dart';

import 'activity_models.dart';

class ActivityRepository {
  final SupabaseClient _client;

  ActivityRepository(this._client);

  Future<String?> createSession({
    required String userId,
    required String activityType,
    required String activityEnvironment,
    required String trackingMode,
    required DateTime startedAt,
  }) async {
    try {
      final row = await _client
          .from('activity_sessions')
          .insert({
            'user_id': userId,
            'activity_type': activityType,
            'activity_environment': activityEnvironment,
            'tracking_mode': trackingMode,
            'started_at': startedAt.toIso8601String(),
          })
          .select('id')
          .single();
      return row['id']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> finalizeSession({
    required String sessionId,
    required Map<String, dynamic> payload,
  }) async {
    await _client.from('activity_sessions').update(payload).eq('id', sessionId);
  }

  Future<void> saveRoutePoints({
    required String sessionId,
    required String userId,
    required List<ActivityRoutePoint> points,
  }) async {
    if (points.isEmpty) return;
    final rows = points
        .map((p) => p.toInsertJson(sessionId: sessionId, userId: userId))
        .toList(growable: false);
    try {
      await _client.from('activity_route_points').insert(rows);
    } catch (_) {
      // tabela pode ainda não existir no ambiente; sessão continua salva
    }
  }

  Future<List<ActivityRoutePoint>> loadRoutePoints(String sessionId) async {
    try {
      final rows = await _client
          .from('activity_route_points')
          .select(
              'latitude, longitude, altitude, accuracy, speed_mps, heading, recorded_at, point_order')
          .eq('activity_session_id', sessionId)
          .order('point_order', ascending: true);
      return rows
          .map<ActivityRoutePoint>((r) => ActivityRoutePoint(
                latitude: (r['latitude'] as num).toDouble(),
                longitude: (r['longitude'] as num).toDouble(),
                altitude: (r['altitude'] as num?)?.toDouble(),
                accuracy: (r['accuracy'] as num?)?.toDouble(),
                speedMps: (r['speed_mps'] as num?)?.toDouble(),
                heading: (r['heading'] as num?)?.toDouble(),
                recordedAt: DateTime.tryParse((r['recorded_at'] ?? '').toString()) ??
                    DateTime.now(),
                pointOrder: (r['point_order'] as num?)?.toInt() ?? 0,
              ))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}

