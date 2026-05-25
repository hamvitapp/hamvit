import 'package:flutter/material.dart';

import '../../../theme/hamvit_colors.dart';

class HamvitChartInsight extends StatelessWidget {
  final String text;

  const HamvitChartInsight({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: HamvitColors.primaryNavy.withValues(alpha: 0.58),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.auto_awesome_rounded,
              color: HamvitColors.accentMint,
              size: 15,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HamvitColors.darkText,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
