import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import 'settings_provider.dart';

class AccessibilityPreferencesNotifier extends AsyncNotifier<AccessibilitySettingsData> {
  late final SettingsRepository _repo;

  @override
  Future<AccessibilitySettingsData> build() async {
    _repo = ref.read(settingsRepositoryProvider);
    return _repo.loadAccessibilitySettings();
  }

  Future<void> save(AccessibilitySettingsData data) async {
    final previous = state.valueOrNull;
    state = AsyncData(data);
    try {
      await _repo.saveAccessibilitySettings(data);
    } catch (e, st) {
      state = AsyncError(e, st);
      if (previous != null) {
        state = AsyncData(previous);
      }
      rethrow;
    }
  }
}

final accessibilityPreferencesProvider =
    AsyncNotifierProvider<AccessibilityPreferencesNotifier, AccessibilitySettingsData>(
  AccessibilityPreferencesNotifier.new,
);
