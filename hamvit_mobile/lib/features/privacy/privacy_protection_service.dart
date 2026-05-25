import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/data/settings_repository.dart';
import '../settings/providers/settings_provider.dart';
import 'screenshot_protection_service.dart';

final screenshotProtectionServiceProvider =
    Provider<ScreenshotProtectionService>((ref) {
  return ScreenshotProtectionService();
});

final privacyProtectionServiceProvider =
    ChangeNotifierProvider<PrivacyProtectionService>((ref) {
  final service = PrivacyProtectionService(
    ref: ref,
    screenshotProtectionService: ref.read(screenshotProtectionServiceProvider),
  );
  return service;
});

class PrivacyProtectionService extends ChangeNotifier
    with WidgetsBindingObserver {
  PrivacyProtectionService({
    required Ref ref,
    required ScreenshotProtectionService screenshotProtectionService,
  })  : _ref = ref,
        _screenshotProtectionService = screenshotProtectionService;

  final Ref _ref;
  final ScreenshotProtectionService _screenshotProtectionService;

  bool _initialized = false;
  bool _isAppObscured = false;
  bool _isSecureEnabled = false;
  int _protectedScreenCount = 0;
  int _screenshotEventTick = 0;
  StreamSubscription<String>? _screenshotSubscription;

  PrivacyProtectionSettingsData _settings =
      PrivacyProtectionSettingsData.defaults;

  bool get initialized => _initialized;
  bool get isAppObscured => _isAppObscured;
  bool get isProtectedScreenActive => _protectedScreenCount > 0;
  int get screenshotEventTick => _screenshotEventTick;
  PrivacyProtectionSettingsData get settings => _settings;

  bool get showLifecycleBlur =>
      _settings.appBlurEnabled && _isAppObscured;

  bool get isScreenshotBlockingActive =>
      _settings.screenshotProtectionEnabled && _protectedScreenCount > 0;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    WidgetsBinding.instance.addObserver(this);

    try {
      _settings = await _ref
          .read(settingsRepositoryProvider)
          .loadPrivacyProtectionSettings();
    } catch (_) {
      _settings = PrivacyProtectionSettingsData.defaults;
    }

    _screenshotSubscription =
        _screenshotProtectionService.screenshotEvents().listen((_) {
      _screenshotEventTick += 1;
      notifyListeners();
    });

    await _syncAndroidSecureFlag();
    notifyListeners();
  }

  Future<void> updateSettings(PrivacyProtectionSettingsData next) async {
    _settings = next;
    notifyListeners();

    await _syncAndroidSecureFlag();

    try {
      await _ref
          .read(settingsRepositoryProvider)
          .savePrivacyProtectionSettings(next);
    } catch (_) {
      // Persistência é best-effort; proteção local continua ativa na sessão.
    }
  }

  Future<void> enterProtectedScreen() async {
    _protectedScreenCount += 1;
    await _syncAndroidSecureFlag();
    notifyListeners();
  }

  Future<void> leaveProtectedScreen() async {
    if (_protectedScreenCount > 0) {
      _protectedScreenCount -= 1;
    }
    await _syncAndroidSecureFlag();
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final shouldObscure =
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached;

    if (_isAppObscured != shouldObscure) {
      _isAppObscured = shouldObscure;
      notifyListeners();
    }

    _syncAndroidSecureFlag();
  }

  Future<void> _syncAndroidSecureFlag() async {
    final shouldEnable =
        (_settings.screenshotProtectionEnabled && _protectedScreenCount > 0) ||
        (_settings.hideRecentAppsPreview && _isAppObscured);

    if (shouldEnable == _isSecureEnabled) return;

    _isSecureEnabled = shouldEnable;
    await _screenshotProtectionService.setSecureMode(enabled: shouldEnable);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _screenshotSubscription?.cancel();
    _screenshotProtectionService.setSecureMode(enabled: false);
    super.dispose();
  }
}
