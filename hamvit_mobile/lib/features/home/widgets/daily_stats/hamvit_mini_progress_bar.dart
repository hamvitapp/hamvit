import 'package:flutter/material.dart';

import '../../../../theme/hamvit_colors.dart';

class HamvitMiniProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final List<Color>? gradient;

  const HamvitMiniProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);
    final hasProgress = progress > 0;
    final visibleProgress = hasProgress ? progress : 0.0;

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          color: Colors.white.withValues(alpha: 0.12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final minVisiblePx = hasProgress ? 8.0 : 0.0;
              final minVisibleFactor = constraints.maxWidth == 0
                  ? 0.0
                  : (minVisiblePx / constraints.maxWidth).clamp(0.0, 1.0);

              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: visibleProgress),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, animated, child) {
                  final widthFactor = animated > 0
                      ? animated.clamp(minVisibleFactor, 1.0)
                      : 0.0;

                  return Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: widthFactor,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradient ??
                                const [
                                  HamvitColors.accentBlue,
                                  HamvitColors.accentCyan,
                                ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
