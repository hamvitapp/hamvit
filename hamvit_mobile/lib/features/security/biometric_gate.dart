import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/providers/auth_provider.dart';
import 'biometric_auth_service.dart';
import 'biometric_lock_screen.dart';
import 'biometric_settings_provider.dart';

class HamvitBiometricGate extends ConsumerStatefulWidget {
  final Widget child;
  final String reason;

  const HamvitBiometricGate({
    super.key,
    required this.child,
    this.reason = 'Confirme sua biometria para continuar.',
  });

  @override
  ConsumerState<HamvitBiometricGate> createState() => _HamvitBiometricGateState();
}

class _HamvitBiometricGateState extends ConsumerState<HamvitBiometricGate> {
  bool _loading = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_checkAccess);
  }

  Future<void> _checkAccess() async {
    final shouldProtect = ref.read(biometricSensitiveScreensEnabledProvider);
    final unlockEnabled = ref.read(biometricEnabledProvider);

    if (!shouldProtect || !unlockEnabled) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _allowed = true;
      });
      return;
    }

    final available = await ref.read(biometricAuthServiceProvider).isAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _allowed = true;
      });
      return;
    }

    final result = await ref.read(biometricAuthServiceProvider).authenticate(
          reason: widget.reason,
        );

    if (!mounted) return;

    if (result.success) {
      await ref.read(biometricAppLockControllerProvider).markUnlocked();
      setState(() {
        _loading = false;
        _allowed = true;
      });
      return;
    }

    setState(() {
      _loading = false;
      _allowed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_allowed) {
      return widget.child;
    }

    return HamvitBiometricLockScreen(
      onUnlocked: () {
        if (!mounted) return;
        setState(() {
          _allowed = true;
        });
      },
    );
  }
}

Future<bool> requireBiometricForAction(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) async {
  final unlockEnabled = ref.read(biometricEnabledProvider);
  final protectSensitive = ref.read(biometricSensitiveScreensEnabledProvider);

  if (!unlockEnabled || !protectSensitive) return true;

  final available = await ref.read(biometricAuthServiceProvider).isAvailable();
  if (!available) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometria não disponível neste dispositivo.'),
        ),
      );
    }
    return true;
  }

  final result = await ref.read(biometricAuthServiceProvider).authenticate(
        reason: reason,
      );

  if (result.success) {
    await ref.read(biometricAppLockControllerProvider).markUnlocked();
    return true;
  }

  if (!context.mounted) return false;

  final usePassword = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Biometria não reconhecida.'),
      content: const Text('Tente novamente ou entre com sua senha.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Tentar novamente'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Usar senha'),
        ),
      ],
    ),
  );

  if (usePassword == true) {
    await ref.read(authStateProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }

  return false;
}
