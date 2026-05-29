import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/goals/goal_calculation_engine.dart';
import '../../../core/goals/nutrition_target_model.dart';
import '../../../core/hamvit_date_utils.dart';
import '../../../core/supabase_provider.dart';
import '../../auth/providers/auth_provider.dart';

class OnboardingProfileState {
  final bool isLoading;
  final bool isSaving;
  final String? objective;
  final double? weightKg;
  final int? heightCm;
  final String? activityLevel;
  final Map<String, dynamic> activityPreferences;
  final List<String> foodPreferences;
  final List<String> foodRestrictions;
  final double? sleepHours;
  final int? hydrationGoalMl;
  final double? targetWeightKg;
  final String? birthDateIso;
  final String? biologicalSex;
  final int? calorieGoal;
  final String? goalsUpdatedAtIso;
  final NutritionTargetModel? calculatedTargets;
  final bool welcomeSeen;
  final String? errorMessage;

  const OnboardingProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.objective,
    this.weightKg,
    this.heightCm,
    this.activityLevel,
    this.activityPreferences = const {},
    this.foodPreferences = const [],
    this.foodRestrictions = const [],
    this.sleepHours,
    this.hydrationGoalMl,
    this.targetWeightKg,
    this.birthDateIso,
    this.biologicalSex,
    this.calorieGoal,
    this.goalsUpdatedAtIso,
    this.calculatedTargets,
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
    Map<String, dynamic>? activityPreferences,
    List<String>? foodPreferences,
    List<String>? foodRestrictions,
    double? sleepHours,
    int? hydrationGoalMl,
    double? targetWeightKg,
    String? birthDateIso,
    String? biologicalSex,
    int? calorieGoal,
    String? goalsUpdatedAtIso,
    NutritionTargetModel? calculatedTargets,
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
      activityPreferences: activityPreferences ?? this.activityPreferences,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      foodRestrictions: foodRestrictions ?? this.foodRestrictions,
      sleepHours: sleepHours ?? this.sleepHours,
      hydrationGoalMl: hydrationGoalMl ?? this.hydrationGoalMl,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      birthDateIso: birthDateIso ?? this.birthDateIso,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      goalsUpdatedAtIso: goalsUpdatedAtIso ?? this.goalsUpdatedAtIso,
      calculatedTargets: calculatedTargets ?? this.calculatedTargets,
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
      final body = _mapFromDynamic(onboarding['body']);
      final activityPreferences = _mapFromDynamic(onboarding['activity_preferences']);

      state = OnboardingProfileState(
        isLoading: false,
        objective: _asString(onboarding['objective']),
        weightKg: _asDouble(health['current_weight_kg']) ?? _asDouble(health['weight_kg']),
        heightCm: _asInt(health['height_cm']),
        activityLevel: _asString(onboarding['activity_level']),
        activityPreferences: activityPreferences,
        foodPreferences: _asStringList(food['preferences']),
        foodRestrictions: _asStringList(food['restrictions']),
        sleepHours: _asDouble(sleep['hours_target']),
        hydrationGoalMl: _asInt(hydration['ml_target']),
        targetWeightKg: _asDouble(body['target_weight_kg']) ??
            _asDouble(health['target_weight_kg']) ??
            _asDouble(health['desired_weight_kg']) ??
            _asDouble(health['goal_weight_kg']),
        birthDateIso: _asString(body['birth_date']),
        biologicalSex: _asString(body['biological_sex']),
        calorieGoal: _asInt(onboarding['calorie_goal']),
        goalsUpdatedAtIso: _asString(onboarding['goals_updated_at']),
        welcomeSeen: _asBool(onboarding['welcome_seen']),
      );

      _recalculateTargetsInMemory();
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
    _recalculateTargetsInMemory();
    await _persistCalculatedTargets(source: 'system_calculated', userAdjusted: false);
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

      _recalculateTargetsInMemory();
      await _persistCalculatedTargets(source: 'system_calculated', userAdjusted: false);

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

  Future<void> saveActivityPreferences({
    required String activityLevel,
    String? limitations,
    String? trainingPreference,
    required List<String> availableDays,
    int? availableMinutes,
  }) async {
    final trimmedLevel = activityLevel.trim();
    await _savePreferencesPatch((onboarding) {
      onboarding['activity_level'] = trimmedLevel;
      onboarding['activity_preferences'] = {
        'activity_level': trimmedLevel,
        'limitations': limitations,
        'training_preference': trainingPreference,
        'available_days': availableDays,
        'available_minutes': availableMinutes,
      };
      onboarding['flows'] = {
        ..._mapFromDynamic(onboarding['flows']),
        'activity': true,
      };
    });

    state = state.copyWith(
      activityLevel: trimmedLevel,
      activityPreferences: {
        'activity_level': trimmedLevel,
        'limitations': limitations,
        'training_preference': trainingPreference,
        'available_days': availableDays,
        'available_minutes': availableMinutes,
      },
    );

    await _syncEssentialCompletion();
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

  Future<void> saveHydrationAdvancedGoal({required int mlTarget}) async {
    final normalized = mlTarget.clamp(1200, 6000);
    await _savePreferencesPatch((onboarding) {
      onboarding['hydration'] = {
        'ml_target': normalized,
        'source': 'user_advanced_adjusted',
      };
      onboarding['goals_updated_at'] = DateTime.now().toIso8601String();
      onboarding['flows'] = {
        ..._mapFromDynamic(onboarding['flows']),
        'hydration': true,
      };
    });

    state = state.copyWith(
      hydrationGoalMl: normalized,
      goalsUpdatedAtIso: DateTime.now().toIso8601String(),
    );

    await _persistCalculatedTargets(source: 'user_advanced_adjusted', userAdjusted: true);
  }

  Future<void> saveBodyData({
    required double weightKg,
    required int heightCm,
    double? targetWeightKg,
    String? birthDateIso,
    String? biologicalSex,
  }) async {
    final uid = _userId;
    final client = _client;

    await saveActivityProfile(
      weightKg: weightKg,
      heightCm: heightCm,
      activityLevel: state.activityLevel ?? 'moderada',
    );

    if (uid != null && client != null) {
      try {
        await client.from('health_profiles').update({
          'current_weight_kg': weightKg,
          'weight_kg': weightKg,
          'height_cm': heightCm,
          'target_weight_kg': targetWeightKg,
          'desired_weight_kg': targetWeightKg,
          'goal_weight_kg': targetWeightKg,
        }).eq('user_id', uid);
      } catch (_) {}
    }

    await _savePreferencesPatch((onboarding) {
      onboarding['body'] = {
        'target_weight_kg': targetWeightKg,
        'birth_date': birthDateIso,
        'biological_sex': biologicalSex,
      };
      onboarding['goals_updated_at'] = DateTime.now().toIso8601String();
    });

    state = state.copyWith(
      targetWeightKg: targetWeightKg,
      birthDateIso: birthDateIso,
      biologicalSex: biologicalSex,
      goalsUpdatedAtIso: DateTime.now().toIso8601String(),
    );

    _recalculateTargetsInMemory();
    await _persistCalculatedTargets(source: 'system_calculated', userAdjusted: false);
  }

  Future<void> recalculateGoals() async {
    _recalculateTargetsInMemory();
    await _persistCalculatedTargets(source: 'system_calculated', userAdjusted: false);
  }

  void _recalculateTargetsInMemory() {
    final age = _ageFromBirthDate(state.birthDateIso);
    final result = GoalCalculationEngine.calculate(
      GoalCalculationEngineInput(
        weightKg: state.weightKg,
        targetWeightKg: state.targetWeightKg,
        heightCm: state.heightCm,
        ageYears: age,
        biologicalSex: state.biologicalSex,
        activityLevel: state.activityLevel,
        objective: state.objective,
      ),
    );

    if (result == null) {
      state = state.copyWith(calculatedTargets: null);
      return;
    }

    state = state.copyWith(
      calculatedTargets: result,
      calorieGoal: result.caloriesKcal,
      hydrationGoalMl: result.waterMl,
    );
  }

  Future<void> _persistCalculatedTargets({
    required String source,
    required bool userAdjusted,
  }) async {
    final uid = _userId;
    final client = _client;
    final targets = state.calculatedTargets;
    if (uid == null || client == null || targets == null) return;

    final today = HamvitDateUtils.toIsoDate(DateTime.now());

    await _savePreferencesPatch((onboarding) {
      onboarding['calorie_goal'] = targets.caloriesKcal;
      onboarding['hydration'] = {
        'ml_target': targets.waterMl,
        'source': source,
      };
      onboarding['goals_updated_at'] = DateTime.now().toIso8601String();
      onboarding['targets_source'] = source;
      onboarding['targets_user_adjusted'] = userAdjusted;
    });

    state = state.copyWith(
      calorieGoal: targets.caloriesKcal,
      hydrationGoalMl: targets.waterMl,
      goalsUpdatedAtIso: DateTime.now().toIso8601String(),
    );

    try {
      await client.from('daily_nutrition_targets').upsert({
        'user_id': uid,
        'target_date': today,
        'calories_kcal': targets.caloriesKcal,
        'protein_g': targets.proteinG,
        'carbs_g': targets.carbsG,
        'fat_g': targets.fatG,
        'water_ml': targets.waterMl,
        'calculation_source': source,
        'calculated_at': DateTime.now().toIso8601String(),
        'user_adjusted': userAdjusted,
      });
    } catch (_) {
      // Ignore schema mismatch while migrations are not yet applied.
    }

    if (targets.estimatedWeeks != null && targets.weightDifferenceKg != null) {
      try {
        await client.from('goal_history').insert({
          'user_id': uid,
          'previous_weight_kg': state.weightKg,
          'target_weight_kg': state.targetWeightKg,
          'estimated_weeks': targets.estimatedWeeks,
          'calorie_target_kcal': targets.caloriesKcal,
          'water_target_ml': targets.waterMl,
          'source': source,
        });
      } catch (_) {
        // Ignore schema mismatch while migrations are not yet applied.
      }
    }
  }

  int? _ageFromBirthDate(String? isoDate) {
    if (isoDate == null || isoDate.trim().isEmpty) return null;
    final birth = HamvitDateUtils.tryParseIsoDate(isoDate);
    if (birth == null) return null;

    final now = DateTime.now();
    var age = now.year - birth.year;
    final hadBirthdayThisYear = (now.month > birth.month) || (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthdayThisYear) {
      age -= 1;
    }
    return age < 0 ? null : age;
  }

  Future<void> _syncEssentialCompletion() async {
    final uid = _userId;
    final client = _client;
    if (uid == null || client == null) return;

    final isComplete = state.essentialCompleted;
    final completionPercent = state.completionPercent;
    final step = _resolveOnboardingStep();
    try {
      await client.from('profiles').update({
        'onboarding_completed': isComplete,
        'onboarding_step': step,
        'profile_completion_percent': completionPercent,
      }).eq('id', uid);
    } catch (_) {
      await client.from('profiles').update({'onboarding_completed': isComplete}).eq('id', uid);
    }
  }

  int _resolveOnboardingStep() {
    if (state.hydrationGoalMl != null && state.hydrationGoalMl! > 0) return 7;
    if (state.sleepHours != null && state.sleepHours! > 0) return 6;
    if (state.hasFoodPreferences && state.hasFoodRestrictions) return 5;
    if (state.hasActivity) return 4;
    if (state.hasWeight && state.hasHeight) return 3;
    if (state.hasObjective) return 2;
    return 1;
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
