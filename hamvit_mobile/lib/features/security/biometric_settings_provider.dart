import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/domain/auth_state.dart';
import '../auth/providers/auth_provider.dart';
import '../settings/data/settings_repository.dart';
import '../settings/providers/settings_provider.dart';
import 'biometric_auth_service.dart';

const _lastBiometricUnlockAtKey = 'hamvit_last_biometric_unlock_at';
const _biometricLockTimeout = Duration(minutes: 5);

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.read(biometricAuthServiceProvider).isAvailable();
});

final biometricSettingsProvider =
    AsyncNotifierProvider<BiometricSettingsNotifier, BiometricSettingsData>(
  BiometricSettingsNotifier.new,
);

final biometricEnabledProvider = Provider<bool>((ref) {
  return ref.watch(biometricSettingsProvider).maybeWhen(
        data: (value) => value.biometricUnlockEnabled,
        orElse: () => false,
      );
});

final biometricSensitiveScreensEnabledProvider = Provider<bool>((ref) {
  return ref.watch(biometricSettingsProvider).maybeWhen(
        data: (value) => value.biometricSensitiveScreensEnabled,
        orElse: () => false,
      );
});

class BiometricSettingsNotifier extends AsyncNotifier<BiometricSettingsData> {
  late final SettingsRepository _repository;
  late final BiometricAuthService _authService;

  @override
  Future<BiometricSettingsData> build() async {
    _repository = ref.read(settingsRepositoryProvider);
    _authService = ref.read(biometricAuthServiceProvider);

    final loaded = await _repository.loadBiometricSettings();
    final available = await _authService.isAvailable();

    if (!available &&
        (loaded.biometricUnlockEnabled ||
            loaded.biometricSensitiveScreensEnabled)) {
      final disabled = loaded.copyWith(
        biometricUnlockEnabled: false,
        biometricSensitiveScreensEnabled: false,
      );
      await _repository.saveBiometricSettings(disabled);
      return disabled;
    }

    return loaded;
  }

  Future<void> setBiometricUnlockEnabled(bool enabled) async {
    final current = state.valueOrNull ?? BiometricSettingsData.defaults;

    if (enabled) {
      final available = await _authService.isAvailable();
      if (!available) {
        throw Exception('Biometria não disponível neste dispositivo.');
      }

      final auth = await _authService.authenticate(
        reason:
            'Confirme sua biometria para ativar o desbloqueio rápido do HAMVIT.',
      );
      if (!auth.success) {
        throw Exception(
          auth.message ??
              'Tente novamente ou entre com sua senha.',
        );
      }
    }

    final next = current.copyWith(
      biometricUnlockEnabled: enabled,
      biometricSensitiveScreensEnabled:
          enabled ? current.biometricSensitiveScreensEnabled : false,
    );

    state = AsyncData(next);
    await _repository.saveBiometricSettings(next);
  }

  Future<void> setSensitiveScreensEnabled(bool enabled) async {
    final current = state.valueOrNull ?? BiometricSettingsData.defaults;

    if (enabled) {
      final available = await _authService.isAvailable();
      if (!available) {
        throw Exception('Biometria não disponível neste dispositivo.');
      }
    }

    final next = current.copyWith(
      biometricSensitiveScreensEnabled: enabled,
      biometricUnlockEnabled: enabled ? true : current.biometricUnlockEnabled,
    );

    state = AsyncData(next);
    await _repository.saveBiometricSettings(next);
  }
}

final biometricAppLockControllerProvider =
    ChangeNotifierProvider<BiometricAppLockController>((ref) {
  final controller = BiometricAppLockController(ref);
  ref.onDispose(controller.disposeController);
  return controller;
});

class BiometricAppLockController extends ChangeNotifier
    with WidgetsBindingObserver {
  BiometricAppLockController(this._ref);

  final Ref _ref;

  bool _initialized = false;
  bool _locked = false;
  DateTime? _lastBiometricUnlockAt;
  DateTime? _backgroundAt;

  bool get locked => _locked;

  bool get shouldShowLock => _locked && _shouldGuardSession();

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastBiometricUnlockAtKey);
    if (millis != null) {
      _lastBiometricUnlockAt =
          DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true).toLocal();
    }

    if (_shouldGuardSession()) {
      _locked = true;
      notifyListeners();
    }

    _ref.listen<AuthStateModel>(authStateProvider, (_, __) {
      refreshGuardState();
    });
    _ref.listen<bool>(biometricEnabledProvider, (_, __) {
      refreshGuardState();
    });
  }

  void refreshGuardState() {
    final shouldGuard = _shouldGuardSession();
    if (!shouldGuard && _locked) {
      _locked = false;
      notifyListeners();
    }
  }

  Future<void> markUnlocked() async {
    _lastBiometricUnlockAt = DateTime.now();
    _locked = false;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastBiometricUnlockAtKey,
      _lastBiometricUnlockAt!.toUtc().millisecondsSinceEpoch,
    );

    final current = _ref.read(biometricSettingsProvider).valueOrNull;
    if (current != null) {
      try {
        await _ref.read(settingsRepositoryProvider).saveBiometricSettings(
              current.copyWith(lastBiometricUnlockAt: _lastBiometricUnlockAt),
            );
      } catch (_) {
        // Sincronização remota é best-effort; persistência local já foi aplicada.
      }
    }
  }

  Future<void> lockNow() async {
    _locked = true;
    notifyListeners();
  }

  bool _shouldGuardSession() {
    final authState = _ref.read(authStateProvider);
    final biometricEnabled = _ref.read(biometricEnabledProvider);

    return authState.status == AuthStatus.authenticated && biometricEnabled;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldGuardSession()) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundAt = DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    final now = DateTime.now();
    final elapsedSinceUnlock = _lastBiometricUnlockAt == null
        ? _biometricLockTimeout + const Duration(seconds: 1)
        : now.difference(_lastBiometricUnlockAt!);

    final elapsedInBackground = _backgroundAt == null
        ? Duration.zero
        : now.difference(_backgroundAt!);

    if (elapsedSinceUnlock > _biometricLockTimeout ||
        elapsedInBackground > _biometricLockTimeout) {
      _locked = true;
      notifyListeners();
    }
  }

  Future<void> resetLastUnlock() async {
    _lastBiometricUnlockAt = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastBiometricUnlockAtKey);
  }

  void disposeController() {
    WidgetsBinding.instance.removeObserver(this);
    dispose();
  }
}
