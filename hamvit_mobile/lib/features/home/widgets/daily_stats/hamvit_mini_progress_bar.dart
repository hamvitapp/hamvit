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

    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          color: Colors.white.withValues(alpha: 0.08),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 850),
              curve: Curves.easeOutCubic,
              builder: (context, animated, child) {
                return FractionallySizedBox(
                  widthFactor: animated,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient ?? const [HamvitColors.accentCyan, HamvitColors.accentBlue],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
