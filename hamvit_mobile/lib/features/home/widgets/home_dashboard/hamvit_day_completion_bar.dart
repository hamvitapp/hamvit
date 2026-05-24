import 'package:flutter/material.dart';

import '../../../../theme/hamvit_colors.dart';

class HamvitDayCompletionBar extends StatelessWidget {
  final int percent;

  const HamvitDayCompletionBar({super.key, required this.percent});

  @override
  Widget build(BuildContext context) {
    final normalized = (percent / 100).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seu dia está $percent% concluído.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HamvitColors.darkText,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 8,
            color: Colors.white.withValues(alpha: 0.08),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: normalized),
              duration: const Duration(milliseconds: 950),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            HamvitColors.accentMint,
                            HamvitColors.accentCyan,
                            HamvitColors.accentBlue,
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
