import 'package:flutter/material.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../theme/hamvit_colors.dart';

class HamvitSettingsScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const HamvitSettingsScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HamvitColors.primaryDark,
      appBar: hamvitBackAppBar(context, title: title),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          children: [
            if (subtitle != null) ...[
              HamvitSettingsInfoCard(
                icon: Icons.info_outline,
                title: title,
                description: subtitle!,
              ),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class HamvitSettingsSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;

  const HamvitSettingsSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HamvitColors.darkCard.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: HamvitColors.darkText,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HamvitColors.darkTextMuted,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class HamvitSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HamvitSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 2),
        leading: Icon(icon, color: HamvitColors.accentCyan),
        title: Text(
          title,
          style: const TextStyle(
            color: HamvitColors.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: const TextStyle(color: HamvitColors.darkTextMuted),
              ),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: HamvitColors.darkTextMuted),
        onTap: onTap,
      ),
    );
  }
}

class HamvitSettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const HamvitSettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      secondary: Icon(icon, color: HamvitColors.accentCyan),
      title: Text(
        title,
        style: const TextStyle(
          color: HamvitColors.darkText,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: const TextStyle(color: HamvitColors.darkTextMuted),
            ),
      value: value,
      activeThumbColor: HamvitColors.accentCyan,
      activeTrackColor: HamvitColors.accentBlue.withValues(alpha: 0.5),
      onChanged: onChanged,
    );
  }
}

class HamvitSettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isLoading;
  final VoidCallback? onTap;

  const HamvitSettingsActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.isLoading = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HamvitSettingsTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right, color: HamvitColors.darkTextMuted),
      onTap: isLoading ? null : onTap,
    );
  }
}

class HamvitSettingsInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const HamvitSettingsInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            HamvitColors.primaryNavy.withValues(alpha: 0.92),
            HamvitColors.darkCard.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HamvitColors.accentCyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: HamvitColors.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HamvitColors.darkTextMuted,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HamvitDangerZoneCard extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> actions;

  const HamvitDangerZoneCard({
    super.key,
    required this.title,
    required this.description,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HamvitColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HamvitColors.danger.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: HamvitColors.danger.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HamvitColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HamvitColors.darkTextMuted,
                ),
          ),
          const SizedBox(height: 8),
          ...actions,
        ],
      ),
    );
  }
}
