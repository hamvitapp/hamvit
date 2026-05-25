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
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final fillWidth = constraints.maxWidth * progress;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    width: fillWidth,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradient ??
                            const [
                              HamvitColors.accentBlue,
                              HamvitColors.accentCyan,
                            ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
