import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/error_codes.dart' as local_auth_error;
import 'package:local_auth/local_auth.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

class BiometricAuthResult {
  final bool success;
  final String? message;

  const BiometricAuthResult({
    required this.success,
    this.message,
  });
}

class BiometricAuthService {
  final LocalAuthentication _localAuth;

  BiometricAuthService({LocalAuthentication? localAuth})
      : _localAuth = localAuth ?? LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final supported = await _localAuth.isDeviceSupported();
      final canCheck = await _localAuth.canCheckBiometrics;
      final types = await _localAuth.getAvailableBiometrics();
      return supported && canCheck && types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return _localAuth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  Future<BiometricAuthResult> authenticate({
    required String reason,
    bool biometricOnly = true,
  }) async {
    try {
      final allowed = await _localAuth.authenticate(
        localizedReason: reason,
        authMessages: const [],
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
          useErrorDialogs: false,
          sensitiveTransaction: true,
        ),
      );

      if (allowed) {
        return const BiometricAuthResult(success: true);
      }

      return const BiometricAuthResult(
        success: false,
        message: 'Biometria não reconhecida.',
      );
    } on PlatformException catch (e) {
      if (e.code == local_auth_error.notAvailable) {
        return const BiometricAuthResult(
          success: false,
          message: 'Biometria não disponível neste dispositivo.',
        );
      }

      if (e.code == local_auth_error.notEnrolled) {
        return const BiometricAuthResult(
          success: false,
          message: 'Nenhuma biometria cadastrada no dispositivo.',
        );
      }

      if (e.code == local_auth_error.lockedOut ||
          e.code == local_auth_error.permanentlyLockedOut) {
        return const BiometricAuthResult(
          success: false,
          message: 'Biometria temporariamente bloqueada. Tente novamente ou entre com sua senha.',
        );
      }

      return BiometricAuthResult(
        success: false,
        message: e.message ?? 'Falha ao validar biometria.',
      );
    } catch (_) {
      return const BiometricAuthResult(
        success: false,
        message: 'Falha ao validar biometria.',
      );
    }
  }
}
