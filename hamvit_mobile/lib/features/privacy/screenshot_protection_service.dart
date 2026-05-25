import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class ScreenshotProtectionService {
  static const MethodChannel _methodChannel =
      MethodChannel('hamvit/privacy_protection');
  static const EventChannel _eventChannel =
      EventChannel('hamvit/privacy_events');

  Stream<String>? _cachedEvents;

  Future<void> setSecureMode({required bool enabled}) async {
    if (!Platform.isAndroid) return;

    try {
      await _methodChannel.invokeMethod<void>('setSecure', {
        'enabled': enabled,
      });
    } catch (_) {
      // Fallback silencioso: o app continua funcionando mesmo sem suporte nativo.
    }
  }

  Stream<String> screenshotEvents() {
    if (!Platform.isIOS) return const Stream<String>.empty();

    _cachedEvents ??= _eventChannel
        .receiveBroadcastStream()
        .where((event) => event is String)
        .cast<String>()
        .handleError((_) {})
        .asBroadcastStream();

    return _cachedEvents!;
  }
}
