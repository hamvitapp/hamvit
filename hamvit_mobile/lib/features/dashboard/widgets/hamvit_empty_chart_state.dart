import 'package:flutter/material.dart';

import '../../../theme/hamvit_colors.dart';

class HamvitEmptyChartState extends StatelessWidget {
  final String message;

  const HamvitEmptyChartState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: HamvitColors.darkTextMuted,
              ),
        ),
      ),
    );
  }
}
