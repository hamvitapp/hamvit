import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/hamvit_colors.dart';
import '../auth/providers/auth_provider.dart';
import 'biometric_auth_service.dart';
import 'biometric_settings_provider.dart';

class HamvitBiometricLockScreen extends ConsumerStatefulWidget {
  final VoidCallback? onUnlocked;

  const HamvitBiometricLockScreen({
    super.key,
    this.onUnlocked,
  });

  @override
  ConsumerState<HamvitBiometricLockScreen> createState() =>
      _HamvitBiometricLockScreenState();
}

class _HamvitBiometricLockScreenState
    extends ConsumerState<HamvitBiometricLockScreen> {
  bool _busy = false;
  String? _message;

  Future<void> _unlock() async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _message = null;
    });

    final result = await ref.read(biometricAuthServiceProvider).authenticate(
          reason: 'Desbloqueie com biometria',
        );

    if (!mounted) return;

    if (result.success) {
      await ref.read(biometricAppLockControllerProvider).markUnlocked();
      widget.onUnlocked?.call();
      setState(() {
        _busy = false;
      });
      return;
    }

    setState(() {
      _busy = false;
      _message = result.message ?? 'Biometria não reconhecida.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _message ?? 'Tente novamente ou entre com sua senha.',
        ),
      ),
    );
  }

  Future<void> _usePasswordFallback() async {
    await ref.read(authStateProvider.notifier).logout();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: HamvitColors.primaryDark,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      HamvitColors.accentBlue,
                      HamvitColors.accentCyan,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HamvitColors.accentBlue.withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.fingerprint,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'HAMVIT',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desbloqueie com biometria',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              if (_message != null) ...[
                const SizedBox(height: 8),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _unlock,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open_outlined),
                  label: Text(_busy ? 'Validando...' : 'Usar biometria'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _usePasswordFallback,
                child: const Text('Usar senha'),
              ),
              const SizedBox(height: 4),
              Text(
                'Tente novamente ou entre com sua senha.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HamvitBiometricAppLockOverlay extends ConsumerStatefulWidget {
  final Widget child;

  const HamvitBiometricAppLockOverlay({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<HamvitBiometricAppLockOverlay> createState() =>
      _HamvitBiometricAppLockOverlayState();
}

class _HamvitBiometricAppLockOverlayState
    extends ConsumerState<HamvitBiometricAppLockOverlay> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(biometricAppLockControllerProvider).ensureInitialized();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(biometricAppLockControllerProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (controller.shouldShowLock)
          const Positioned.fill(
            child: HamvitBiometricLockScreen(),
          ),
      ],
    );
  }
}
