import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_provider.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? objective;
  final double? weightKg;
  final int? heightCm;
  final String? activityLevel;
  final List<String> foodPreferences;
  final List<String> foodRestrictions;
  final double? sleepHours;
  final int? hydrationGoalMl;
  final bool welcomeSeen;
  final String? errorMessage;

  const OnboardingProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.objective,
    this.weightKg,
    this.heightCm,
    this.activityLevel,
    this.foodPreferences = const [],
    this.foodRestrictions = const [],
    this.sleepHours,
    this.hydrationGoalMl,
    this.welcomeSeen = false,
    this.errorMessage,
  });

  OnboardingProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? objective,
    double? weightKg,
    int? heightCm,
    String? activityLevel,
    List<String>? foodPreferences,
    List<String>? foodRestrictions,
    double? sleepHours,
    int? hydrationGoalMl,
    bool? welcomeSeen,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OnboardingProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      objective: objective ?? this.objective,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      activityLevel: activityLevel ?? this.activityLevel,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      foodRestrictions: foodRestrictions ?? this.foodRestrictions,
      sleepHours: sleepHours ?? this.sleepHours,
      hydrationGoalMl: hydrationGoalMl ?? this.hydrationGoalMl,
      welcomeSeen: welcomeSeen ?? this.welcomeSeen,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get hasObjective => (objective ?? '').trim().isNotEmpty;
  bool get hasWeight => (weightKg ?? 0) > 0;
  bool get hasHeight => (heightCm ?? 0) > 0;
  bool get hasActivity => (activityLevel ?? '').trim().isNotEmpty;
  bool get hasFoodPreferences => foodPreferences.isNotEmpty;
  bool get hasFoodRestrictions => foodRestrictions.isNotEmpty;

  bool get essentialCompleted => hasObjective && hasWeight && hasHeight && hasActivity;

  int get completionPercent {
    var points = 0;
    if (hasObjective) points += 15;
    if (hasWeight) points += 15;
    if (hasHeight) points += 15;
    if (hasActivity) points += 15;
    if (hasFoodPreferences) points += 10;
    if (hasFoodRestrictions) points += 10;
    if ((sleepHours ?? 0) > 0) points += 10;
    if ((hydrationGoalMl ?? 0) > 0) points += 10;
    return points;
  }

  bool get needsNutritionSoftGate => !(hasObjective && hasFoodPreferences && hasFoodRestrictions);
  bool get needsActivitySoftGate => !(hasWeight && hasHeight && hasActivity);
}

final onboardingProfileProvider = StateNotifierProvider<OnboardingProfileNotifier, OnboardingProfileState>((ref) {
  final user = ref.watch(currentUserProvider);
  return OnboardingProfileNotifier(
    client: ref.watch(supabaseClientProvider),
    userId: user?.id,
  );
});

class OnboardingProfileNotifier extends StateNotifier<OnboardingProfileState> {
  final SupabaseClient? _client;
  final String? _userId;

  OnboardingProfileNotifier({
    required SupabaseClient? client,
    required String? userId,
  })  : _client = client,
        _userId = userId,
        super(const OnboardingProfileState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    final uid = _userId;
    final client = _client;

    if (uid == null || client == null) {
      state = const OnboardingProfileState(isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final healthRows = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);

      final prefRows = await client
          .from('user_preferences')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);

      final health = healthRows.isNotEmpty ? Map<String, dynamic>.from(healthRows.first as Map) : <String, dynamic>{};
      final prefsRow = prefRows.isNotEmpty ? Map<String, dynamic>.from(prefRows.first as Map) : <String, dynamic>{};
      final prefs = prefsRow['data'] is Map<String, dynamic>
          ? (prefsRow['data'] as Map<String, dynamic>)
          : Map<String, dynamic>.from((prefsRow['data'] as Map?) ?? {});

      final onboarding = _mapFromDynamic(prefs['onboarding']);
      final food = _mapFromDynamic(onboarding['food']);
      final sleep = _mapFromDynamic(onboarding['sleep']);
      final hydration = _mapFromDynamic(onboarding['hydration']);

      state = OnboardingProfileState(
        isLoading: false,
        objective: _asString(onboarding['objective']),
        weightKg: _asDouble(health['weight_kg']),
        heightCm: _asInt(health['height_cm']),
        activityLevel: _asString(onboarding['activity_level']),
        foodPreferences: _asStringList(food['preferences']),
        foodRestrictions: _asStringList(food['restrictions']),
        sleepHours: _asDouble(sleep['hours_target']),
        hydrationGoalMl: _asInt(hydration['ml_target']),
        welcomeSeen: _asBool(onboarding['welcome_seen']),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> markWelcomeSeen() async {
    await _savePreferencesPatch((onboarding) {
      onboarding['welcome_seen'] = true;
    });
    state = state.copyWith(welcomeSeen: true);
  }

  Future<void> saveGeneralProfile({required String objective}) async {
    final trimmed = objective.trim();
    await _savePreferencesPatch((onboarding) {
      onboarding['objective'] = trimmed;
      onboarding['flows'] = {
        ..._mapFromDynamic(onboarding['flows']),
        'general': true,
      };
    });
    state = state.copyWith(objective: trimmed);
    await _syncEssentialCompletion();
  }

  Future<void> saveActivityProfile({
    required double weightKg,
    required int heightCm,
    required String activityLevel,
  }) async {
    final uid = _userId;
    final client = _client;
    if (uid == null || client == null) return;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final rows = await client
          .from('health_profiles')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);

      if (rows.isNotEmpty) {
        final existing = Map<String, dynamic>.from(rows.first as Map);
        await client.from('health_profiles').update({
          'weight_kg': weightKg,
          'height_cm': heightCm,
        }).eq('id', existing['id']);
      } else {
        await client.from('health_profiles').insert({
          'user_id': uid,
          'weight_kg': weightKg,
          'height_cm': heightCm,
        });
      }

      await _savePreferencesPatch((onboarding) {
        onboarding['activity_level'] = activityLevel.trim();
        onboarding['flows'] = {
          ..._mapFromDynamic(onboarding['flows']),
          'activity': true,
        };
      });

      state = state.copyWith(
        isSaving: false,
        weightKg: weightKg,
        heightCm: heightCm,
        activityLevel: activityLevel.trim(),
      );

      await _syncEssentialCompletion();
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  Future<void> saveFoodPreferences({
    required List<String> preferences,
    required List<String> restrictions,
  }) async {
    await _savePreferencesPatch((onboarding) {
      onboarding['food'] = {
        'preferences': preferences,
        'restrictions': restrictions,
      };
      onboarding['flows'] = {
        ..._mapFromDynamic(onboarding['flows']),
        'food': true,
      };
    });

    state = state.copyWith(
      foodPreferences: preferences,
      foodRestrictions: restrictions,
    );
  }

  Future<void> saveSleepProfile({required double hoursTarget}) async {
    await _savePreferencesPatch((onboarding) {
      onboarding['sleep'] = {'hours_target': hoursTarget};
      onboarding['flows'] = {
        ..._mapFromDynamic(onboarding['flows']),
        'sleep': true,
      };
    });

    state = state.copyWith(sleepHours: hoursTarget);
  }

  Future<void> saveHydrationProfile({required int mlTarget}) async {
    await _savePreferencesPatch((onboarding) {
      onboarding['hydration'] = {'ml_target': mlTarget};
      onboarding['flows'] = {
        ..._mapFromDynamic(onboarding['flows']),
        'hydration': true,
      };
    });

    state = state.copyWith(hydrationGoalMl: mlTarget);
  }

  Future<void> _syncEssentialCompletion() async {
    final uid = _userId;
    final client = _client;
    if (uid == null || client == null) return;

    final isComplete = state.essentialCompleted;
    await client.from('profiles').update({'onboarding_completed': isComplete}).eq('id', uid);
  }

  Future<void> _savePreferencesPatch(void Function(Map<String, dynamic> onboarding) patch) async {
    final uid = _userId;
    final client = _client;
    if (uid == null || client == null) return;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final prefRows = await client
          .from('user_preferences')
          .select('*')
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(1);

      if (prefRows.isNotEmpty) {
        final current = Map<String, dynamic>.from(prefRows.first as Map);
        final data = _mapFromDynamic(current['data']);
        final onboarding = _mapFromDynamic(data['onboarding']);
        patch(onboarding);
        data['onboarding'] = onboarding;
        await client.from('user_preferences').update({'data': data}).eq('id', current['id']);
      } else {
        final onboarding = <String, dynamic>{};
        patch(onboarding);
        await client.from('user_preferences').insert({
          'user_id': uid,
          'data': {
            'onboarding': onboarding,
          },
        });
      }

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: e.toString());
    }
  }

  static Map<String, dynamic> _mapFromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return Map<String, dynamic>.from(value);
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  static List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
    }
    return const [];
  }
}
