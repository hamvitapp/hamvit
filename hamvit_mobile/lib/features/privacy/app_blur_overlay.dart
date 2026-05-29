import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/hamvit_colors.dart';
import 'privacy_protection_service.dart';

class HamvitAppBlurOverlay extends ConsumerWidget {
  final Widget child;

  const HamvitAppBlurOverlay({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(privacyProtectionServiceProvider);
    final visible = service.showLifecycleBlur;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          ignoring: !visible,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            opacity: visible ? 1 : 0,
            child: visible ? const HamvitPrivacyOverlay() : const SizedBox(),
          ),
        ),
      ],
    );
  }
}

class HamvitPrivacyOverlay extends StatelessWidget {
  const HamvitPrivacyOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.52),
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(color: Colors.black.withValues(alpha: 0.16)),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [HamvitColors.accentBlue, HamvitColors.accentCyan],
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 26,
                        color: HamvitColors.accentBlue.withValues(alpha: 0.36),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 14),
                Text(
                  'HAMVIT',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.3,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Proteção de privacidade ativa',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HamvitProtectedScreenWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final String message;
  final bool showHint;

  const HamvitProtectedScreenWrapper({
    super.key,
    required this.child,
    this.message = 'Capturas de tela desativadas nesta área por privacidade.',
    this.showHint = true,
  });

  @override
  ConsumerState<HamvitProtectedScreenWrapper> createState() =>
      _HamvitProtectedScreenWrapperState();
}

class _HamvitProtectedScreenWrapperState
    extends ConsumerState<HamvitProtectedScreenWrapper> {
  bool _hintShown = false;
  int _lastScreenshotTick = 0;
  late final PrivacyProtectionService _service;

  @override
  void initState() {
    super.initState();
    _service = ref.read(privacyProtectionServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _service.ensureInitialized();
      await _service.enterProtectedScreen();
      _lastScreenshotTick = _service.screenshotEventTick;
      _showProtectionHintIfNeeded();
    });
  }

  @override
  void dispose() {
    // Use stored service instance to avoid accessing `ref` after dispose.
    _service.leaveProtectedScreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(privacyProtectionServiceProvider);

    if (service.screenshotEventTick > _lastScreenshotTick) {
      _lastScreenshotTick = service.screenshotEventTick;
      _showHint(widget.message);
    }

    return widget.child;
  }

  void _showProtectionHintIfNeeded() {
    if (!widget.showHint || _hintShown) return;

    if (!_service.isScreenshotBlockingActive) return;

    _hintShown = true;
    _showHint(widget.message);
  }

  void _showHint(String text) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
      ),
    );
  }
}
