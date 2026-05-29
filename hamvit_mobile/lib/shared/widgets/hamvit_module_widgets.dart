import 'package:flutter/material.dart';

import '../../theme/hamvit_colors.dart';

class HamvitSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const HamvitSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class HamvitMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String? helper;

  const HamvitMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: HamvitColors.accentBlue),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            if (helper != null) ...[
              const SizedBox(height: 4),
              Text(helper!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}

class HamvitProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress;

  const HamvitProgressCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final safeProgress = progress.clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: safeProgress),
            const SizedBox(height: 6),
            Text('${(safeProgress * 100).round()}% concluído'),
          ],
        ),
      ),
    );
  }
}

class HamvitHistoryCard extends StatelessWidget {
  final String title;
  final List<String> items;
  final IconData icon;

  const HamvitHistoryCard({
    super.key,
    required this.title,
    required this.items,
    this.icon = Icons.history,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: HamvitColors.accentBlue),
                const SizedBox(width: 6),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const Text('Sem histórico ainda.')
            else
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $item'),
                ),
          ],
        ),
      ),
    );
  }
}

class HamvitModuleSummaryCard extends StatelessWidget {
  final String title;
  final String description;
  final Widget? action;
  final Widget? titleTrailing;

  const HamvitModuleSummaryCard({
    super.key,
    required this.title,
    required this.description,
    this.action,
    this.titleTrailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: Theme.of(context).textTheme.titleMedium),
                ),
                if (titleTrailing != null) ...[
                  const SizedBox(width: 8),
                  titleTrailing!,
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(description),
            if (action != null) ...[
              const SizedBox(height: 10),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class HamvitEditGoalButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const HamvitEditGoalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.edit_outlined),
        label: Text(label),
      ),
    );
  }
}
