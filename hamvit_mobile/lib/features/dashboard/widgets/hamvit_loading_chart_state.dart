import 'package:flutter/material.dart';

class HamvitLoadingChartState extends StatelessWidget {
  const HamvitLoadingChartState({super.key});

  @override
  Widget build(BuildContext context) {
    Widget skeleton(double height) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.25, end: 0.55),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        builder: (context, alpha, _) {
          return Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: alpha),
            ),
          );
        },
      );
    }

    return Column(
      children: [
        skeleton(68),
        const SizedBox(height: 10),
        skeleton(240),
        const SizedBox(height: 10),
        skeleton(240),
      ],
    );
  }
}
