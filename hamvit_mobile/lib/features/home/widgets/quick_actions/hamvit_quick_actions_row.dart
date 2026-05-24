import 'package:flutter/material.dart';

import '../../../../theme/hamvit_colors.dart';

class HamvitQuickActionsRow extends StatelessWidget {
  final VoidCallback onWater;
  final VoidCallback onMeal;
  final VoidCallback onWalk;
  final VoidCallback onHabit;

  const HamvitQuickActionsRow({
    super.key,
    required this.onWater,
    required this.onMeal,
    required this.onWalk,
    required this.onHabit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _QuickActionChip(icon: Icons.water_drop_outlined, label: 'Registrar água', onTap: onWater),
          _QuickActionChip(icon: Icons.restaurant_menu_outlined, label: 'Registrar refeição', onTap: onMeal),
          _QuickActionChip(icon: Icons.directions_walk_outlined, label: 'Iniciar caminhada', onTap: onWalk),
          _QuickActionChip(icon: Icons.checklist_rounded, label: 'Registrar hábito', onTap: onHabit),
        ],
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: HamvitColors.darkCard.withValues(alpha: 0.85),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: HamvitColors.accentCyan),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: HamvitColors.darkText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
