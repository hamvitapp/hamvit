import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final weights = await _fetchWeightLogs(uid, profileHeightCm: profile.heightCm);
    final measurements = await _fetchMeasurements(uid);
    final photos = await _fetchPhotos(uid);

    return EvolutionDashboardData(
      weightLogs: weights,
      measurements: measurements,
      photos: photos,
      profileWeightKg: profile.weightKg,
      profileHeightCm: profile.heightCm,
      targetWeightKg: profile.targetWeightKg,
    );
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
      await client
          .from('health_profiles')
          .update({'weight_kg': weightKg})
          .eq('user_id', uid);
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
      final row = await client
          .from('health_profiles')
          .select('current_weight_kg, weight_kg, height_cm, target_weight_kg')
          .eq('user_id', uid)
          .maybeSingle();
      return _HealthProfileData(
        weightKg: _toDouble(row?['current_weight_kg']) ?? _toDouble(row?['weight_kg']),
        heightCm: _toInt(row?['height_cm']),
        targetWeightKg: _toDouble(row?['target_weight_kg']),
      );
    } catch (_) {
      final row = await client
          .from('health_profiles')
          .select('weight_kg, height_cm')
          .eq('user_id', uid)
          .maybeSingle();
      return _HealthProfileData(
        weightKg: _toDouble(row?['weight_kg']),
        heightCm: _toInt(row?['height_cm']),
        targetWeightKg: null,
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
  final double? weightKg;
  final int? heightCm;
  final double? targetWeightKg;

  const _HealthProfileData({
    required this.weightKg,
    required this.heightCm,
    required this.targetWeightKg,
  });
}