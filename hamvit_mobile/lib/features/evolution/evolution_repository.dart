import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_provider.dart';
import '../auth/providers/auth_provider.dart';
import 'domain/bmi_calculator.dart';
import 'evolution_models.dart';

final evolutionRepositoryProvider = Provider<EvolutionRepository>((ref) {
  final client = ref.watch(supabaseClientProvider) ?? Supabase.instance.client;
  return EvolutionRepository(client: client, userId: ref.watch(currentUserProvider)?.id);
});

class EvolutionRepository {
  final SupabaseClient client;
  final String? userId;

  EvolutionRepository({required this.client, required this.userId});

  Future<EvolutionDashboardData> loadDashboard() async {
    final uid = userId;
    if (uid == null) {
      throw Exception('Usuario nao autenticado');
    }

    final profile = await _fetchHealthProfile(uid);
    final prefTarget = await _fetchTargetWeightFromPreferences(uid);
    final goalHistoryTarget = await _fetchTargetWeightFromGoalHistory(uid);
    final resolvedTarget = profile.targetWeightKg ?? prefTarget ?? goalHistoryTarget;
    final weights = await _fetchWeightLogs(uid, profileHeightCm: profile.heightCm);
    final enrichedWeights = [...weights];
    if (profile.initialWeightKg != null && profile.initialWeightKg! > 0) {
      final firstLog = enrichedWeights.isEmpty
          ? null
          : (enrichedWeights..sort((a, b) => a.loggedAt.compareTo(b.loggedAt))).first;
      final needsSeed = firstLog == null ||
          firstLog.weightKg != profile.initialWeightKg ||
          (profile.createdAt != null && profile.createdAt!.isBefore(firstLog.loggedAt));
      if (needsSeed) {
        enrichedWeights.add(
          WeightLogEntry(
            id: 'seed_initial_weight',
            weightKg: profile.initialWeightKg!,
            bmi: BmiCalculator.calculate(
              weightKg: profile.initialWeightKg!,
              heightCm: profile.heightCm,
            ),
            loggedAt: profile.createdAt ?? DateTime.now(),
            notes: 'Peso inicial',
          ),
        );
      }
    }
    final measurements = await _fetchMeasurements(uid);
    final photos = await _fetchPhotos(uid);

    return EvolutionDashboardData(
      measurements: measurements,
      photos: photos,
      weightLogs: enrichedWeights,
      profileWeightKg: profile.currentWeightKg,
      profileHeightCm: profile.heightCm,
      targetWeightKg: resolvedTarget,
    );
  }

  Future<double?> _fetchTargetWeightFromPreferences(String uid) async {
    try {
      final rows = await client
          .from('user_preferences')
          .select('data')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      final row = Map<String, dynamic>.from(rows.first as Map);
      final data = row['data'] is Map
          ? Map<String, dynamic>.from(row['data'] as Map)
          : <String, dynamic>{};
      final onboarding = data['onboarding'] is Map
          ? Map<String, dynamic>.from(data['onboarding'] as Map)
          : <String, dynamic>{};
      final body = onboarding['body'] is Map
          ? Map<String, dynamic>.from(onboarding['body'] as Map)
          : <String, dynamic>{};
      return _toDouble(body['target_weight_kg']) ??
          _toDouble(body['target_weight']) ??
          _toDouble(body['goal_weight_kg']);
    } catch (_) {
      return null;
    }
  }

  Future<double?> _fetchTargetWeightFromGoalHistory(String uid) async {
    try {
      final rows = await client
          .from('goal_history')
          .select('target_weight_kg')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);
      if (rows.isEmpty) return null;
      final row = Map<String, dynamic>.from(rows.first as Map);
      return _toDouble(row['target_weight_kg']);
    } catch (_) {
      return null;
    }
  }

  Future<void> addWeightLog({
    required double weightKg,
    required DateTime loggedAt,
    required String? notes,
    required int? heightCm,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception('Usuario nao autenticado');

    final bmi = BmiCalculator.calculate(weightKg: weightKg, heightCm: heightCm);

    try {
      await client.from('weight_logs').insert({
        'user_id': uid,
        'weight_kg': weightKg,
        'bmi': bmi,
        'logged_at': loggedAt.toIso8601String(),
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      await client.from('weight_logs').insert({
        'user_id': uid,
        'weight_kg': weightKg,
        'logged_at': loggedAt.toIso8601String(),
      });
    }

    try {
      await client
          .from('health_profiles')
          .update({'current_weight_kg': weightKg})
          .eq('user_id', uid);
    } catch (_) {
      // Preserve initial weight immutability on legacy schemas.
    }
  }

  Future<void> addBodyMeasurement({
    required DateTime measuredAt,
    double? waistCm,
    double? abdomenCm,
    double? chestCm,
    double? armCm,
    double? thighCm,
    double? hipCm,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception('Usuario nao autenticado');

    final payload = {
      'waist_cm': waistCm,
      'abdomen_cm': abdomenCm,
      'chest_cm': chestCm,
      'arm_cm': armCm,
      'thigh_cm': thighCm,
      'hip_cm': hipCm,
    };

    try {
      await client.from('body_measurements').insert({
        'user_id': uid,
        'measured_at': measuredAt.toIso8601String(),
        ...payload,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      await client.from('body_measurements').insert({
        'user_id': uid,
        'logged_at': measuredAt.toIso8601String(),
        'data': payload,
      });
    }
  }

  Future<void> addProgressPhoto({
    required String imageUrl,
    required DateTime takenAt,
    String? notes,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception('Usuario nao autenticado');

    try {
      await client.from('progress_photos').insert({
        'user_id': uid,
        'image_url': imageUrl,
        'taken_at': takenAt.toIso8601String(),
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      await client.from('body_photos').insert({
        'user_id': uid,
        'storage_path': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<_HealthProfileData> _fetchHealthProfile(String uid) async {
    try {
      final rows = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);
      final rowsAsc = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: true)
          .limit(200);
      List<dynamic> weightRowsAsc = const [];
      try {
        weightRowsAsc = await client
            .from('weight_logs')
            .select('weight_kg, logged_at, created_at')
            .eq('user_id', uid)
            .order('logged_at', ascending: true)
            .limit(200);
      } catch (_) {
        weightRowsAsc = const [];
      }
      final row = rows.isNotEmpty ? Map<String, dynamic>.from(rows.first as Map) : null;
      final oldest = rowsAsc.isNotEmpty ? Map<String, dynamic>.from(rowsAsc.first as Map) : null;
      final oldestWeightLog =
          weightRowsAsc.isNotEmpty ? Map<String, dynamic>.from(weightRowsAsc.first as Map) : null;
      Map<String, dynamic>? oldestGoalHistory;
      try {
        final goalRows = await client
            .from('goal_history')
            .select('previous_weight_kg, created_at')
            .eq('user_id', uid)
            .order('created_at', ascending: true)
            .limit(1);
        if (goalRows.isNotEmpty) {
          oldestGoalHistory = Map<String, dynamic>.from(goalRows.first as Map);
        }
      } catch (_) {}
        final targetWeight = _toDouble(row?['target_weight_kg']) ??
            _toDouble(row?['desired_weight_kg']);
      final initialWeight = _toDouble(oldest?['initial_weight_kg']) ??
          _toDouble(row?['initial_weight_kg']) ??
          _toDouble(oldestGoalHistory?['previous_weight_kg']) ??
          _toDouble(oldest?['weight_kg']) ??
          _toDouble(row?['weight_kg']) ??
          _toDouble(oldestWeightLog?['weight_kg']);
      debugPrint(
        '[EVOLUTION_LOAD] initial=$initialWeight current=${_toDouble(row?['current_weight_kg']) ?? _toDouble(row?['weight_kg'])}',
      );
      return _HealthProfileData(
        initialWeightKg: initialWeight,
        currentWeightKg: _toDouble(row?['current_weight_kg']) ?? _toDouble(row?['weight_kg']),
        heightCm: _toInt(row?['height_cm']),
        targetWeightKg: targetWeight,
        createdAt: DateTime.tryParse((oldest?['created_at'] ?? row?['created_at'] ?? '').toString()),
      );
    } catch (_) {
      final rows = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);
      final rowsAsc = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: true)
          .limit(200);
      List<dynamic> weightRowsAsc = const [];
      try {
        weightRowsAsc = await client
            .from('weight_logs')
            .select('weight_kg, logged_at, created_at')
            .eq('user_id', uid)
            .order('logged_at', ascending: true)
            .limit(200);
      } catch (_) {
        weightRowsAsc = const [];
      }
      final row = rows.isNotEmpty ? Map<String, dynamic>.from(rows.first as Map) : null;
      final oldest = rowsAsc.isNotEmpty ? Map<String, dynamic>.from(rowsAsc.first as Map) : null;
      final oldestWeightLog =
          weightRowsAsc.isNotEmpty ? Map<String, dynamic>.from(weightRowsAsc.first as Map) : null;
      Map<String, dynamic>? oldestGoalHistory;
      try {
        final goalRows = await client
            .from('goal_history')
            .select('previous_weight_kg, created_at')
            .eq('user_id', uid)
            .order('created_at', ascending: true)
            .limit(1);
        if (goalRows.isNotEmpty) {
          oldestGoalHistory = Map<String, dynamic>.from(goalRows.first as Map);
        }
      } catch (_) {}
        final targetWeight = _toDouble(row?['target_weight_kg']) ??
            _toDouble(row?['desired_weight_kg']);
      final initialWeight = _toDouble(oldest?['initial_weight_kg']) ??
          _toDouble(row?['initial_weight_kg']) ??
          _toDouble(oldestGoalHistory?['previous_weight_kg']) ??
          _toDouble(oldest?['weight_kg']) ??
          _toDouble(row?['weight_kg']) ??
          _toDouble(oldestWeightLog?['weight_kg']);
      return _HealthProfileData(
        initialWeightKg: initialWeight,
        currentWeightKg: _toDouble(row?['current_weight_kg']) ?? _toDouble(row?['weight_kg']),
        heightCm: _toInt(row?['height_cm']),
        targetWeightKg: targetWeight,
        createdAt: DateTime.tryParse((oldest?['created_at'] ?? row?['created_at'] ?? '').toString()),
      );
    }
  }

  Future<List<WeightLogEntry>> _fetchWeightLogs(String uid, {required int? profileHeightCm}) async {
    try {
      final rows = await client
          .from('weight_logs')
          .select('id, weight_kg, bmi, logged_at, notes')
          .eq('user_id', uid)
          .order('logged_at', ascending: false)
          .limit(500);

      return rows.map((row) {
        final weight = _toDouble(row['weight_kg']) ?? 0;
        final bmi = _toDouble(row['bmi']) ?? BmiCalculator.calculate(weightKg: weight, heightCm: profileHeightCm);
        return WeightLogEntry(
          id: row['id'].toString(),
          weightKg: weight,
          bmi: bmi,
          loggedAt: DateTime.tryParse((row['logged_at'] ?? '').toString()) ?? DateTime.now(),
          notes: row['notes']?.toString(),
        );
      }).toList();
    } catch (_) {
      final rows = await client
          .from('weight_logs')
          .select('id, weight_kg, logged_at')
          .eq('user_id', uid)
          .order('logged_at', ascending: false)
          .limit(500);

      return rows.map((row) {
        final weight = _toDouble(row['weight_kg']) ?? 0;
        return WeightLogEntry(
          id: row['id'].toString(),
          weightKg: weight,
          bmi: BmiCalculator.calculate(weightKg: weight, heightCm: profileHeightCm),
          loggedAt: DateTime.tryParse((row['logged_at'] ?? '').toString()) ?? DateTime.now(),
          notes: null,
        );
      }).toList();
    }
  }

  Future<List<BodyMeasurementEntry>> _fetchMeasurements(String uid) async {
    try {
      final rows = await client
          .from('body_measurements')
          .select('id, measured_at, waist_cm, abdomen_cm, chest_cm, arm_cm, thigh_cm, hip_cm')
          .eq('user_id', uid)
          .order('measured_at', ascending: false)
          .limit(300);

      return rows
          .map(
            (row) => BodyMeasurementEntry(
              id: row['id'].toString(),
              measuredAt: DateTime.tryParse((row['measured_at'] ?? '').toString()) ?? DateTime.now(),
              waistCm: _toDouble(row['waist_cm']),
              abdomenCm: _toDouble(row['abdomen_cm']),
              chestCm: _toDouble(row['chest_cm']),
              armCm: _toDouble(row['arm_cm']),
              thighCm: _toDouble(row['thigh_cm']),
              hipCm: _toDouble(row['hip_cm']),
            ),
          )
          .toList();
    } catch (_) {
      final rows = await client
          .from('body_measurements')
          .select('id, data, logged_at')
          .eq('user_id', uid)
          .order('logged_at', ascending: false)
          .limit(300);

      return rows
          .map(
            (row) {
              final data = row['data'] is Map ? Map<String, dynamic>.from(row['data']) : <String, dynamic>{};
              return BodyMeasurementEntry(
                id: row['id'].toString(),
                measuredAt: DateTime.tryParse((row['logged_at'] ?? '').toString()) ?? DateTime.now(),
                waistCm: _toDouble(data['waist_cm']),
                abdomenCm: _toDouble(data['abdomen_cm']),
                chestCm: _toDouble(data['chest_cm']),
                armCm: _toDouble(data['arm_cm']),
                thighCm: _toDouble(data['thigh_cm']),
                hipCm: _toDouble(data['hip_cm']),
              );
            },
          )
          .toList();
    }
  }

  Future<List<ProgressPhotoEntry>> _fetchPhotos(String uid) async {
    try {
      final rows = await client
          .from('progress_photos')
          .select('id, image_url, taken_at, notes')
          .eq('user_id', uid)
          .order('taken_at', ascending: false)
          .limit(200);

      return rows
          .map(
            (row) => ProgressPhotoEntry(
              id: row['id'].toString(),
              imageUrl: (row['image_url'] ?? '').toString(),
              takenAt: DateTime.tryParse((row['taken_at'] ?? '').toString()) ?? DateTime.now(),
              notes: row['notes']?.toString(),
            ),
          )
          .toList();
    } catch (_) {
      final rows = await client
          .from('body_photos')
          .select('id, storage_path, created_at')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(200);

      return rows
          .map(
            (row) => ProgressPhotoEntry(
              id: row['id'].toString(),
              imageUrl: (row['storage_path'] ?? '').toString(),
              takenAt: DateTime.tryParse((row['created_at'] ?? '').toString()) ?? DateTime.now(),
              notes: null,
            ),
          )
          .toList();
    }
  }

  double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}

class _HealthProfileData {
  final double? initialWeightKg;
  final double? currentWeightKg;
  final int? heightCm;
  final double? targetWeightKg;
  final DateTime? createdAt;

  const _HealthProfileData({
    required this.initialWeightKg,
    required this.currentWeightKg,
    required this.heightCm,
    required this.targetWeightKg,
    required this.createdAt,
  });
}
