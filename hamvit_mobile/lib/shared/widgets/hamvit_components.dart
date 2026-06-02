import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';

import '../../theme/hamvit_colors.dart';

class HamvitHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const HamvitHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class HamvitExpandableMenuItem extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpansionChanged;
  const HamvitExpandableMenuItem({
    super.key,
    required this.title,
    this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ExpansionTile(
        key: ValueKey('${title}_$initiallyExpanded'),
        initiallyExpanded: initiallyExpanded,
        onExpansionChanged: onExpansionChanged,
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        collapsedIconColor: HamvitColors.darkTextMuted,
        iconColor: HamvitColors.accentCyan,
        leading: icon == null ? null : Icon(icon, color: HamvitColors.accentBlue),
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        children: children,
      ),
    );
  }
}

class HamvitMenuTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? assetPath;
  final VoidCallback? onTap;
  const HamvitMenuTile({super.key, required this.title, this.subtitle, this.icon, this.assetPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: assetPath != null
            ? SizedBox(width: 22, height: 22, child: Image.asset(assetPath!, fit: BoxFit.contain))
            : (icon == null ? null : Icon(icon, color: HamvitColors.accentBlue)),
        title: Text(title, style: const TextStyle(color: HamvitColors.darkText)),
        subtitle: subtitle == null ? null : Text(subtitle!, style: const TextStyle(color: HamvitColors.darkTextMuted)),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right, color: HamvitColors.darkTextMuted),
      ),
    );
  }
}

class HamvitIconCard extends StatelessWidget {
  final IconData? icon;
  final String? assetPath;
  final String label;
  final String? subtitle;
  const HamvitIconCard({super.key, this.icon, this.assetPath, required this.label, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final leading = assetPath != null
        ? SizedBox(width: 28, height: 28, child: Image.asset(assetPath!, fit: BoxFit.contain))
        : Icon(icon ?? Icons.radio_button_checked, color: HamvitColors.accentBlue);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: HamvitColors.primaryDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Center(child: leading),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null) Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final bool obscureText;
  const HamvitTextField({
    super.key,
    this.controller,
    required this.label,
    this.keyboardType,
    this.prefixIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onTap: () {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      },
      decoration: InputDecoration(labelText: label, prefixIcon: prefixIcon),
    );
  }
}

class HamvitSearchSelect extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  const HamvitSearchSelect({super.key, required this.label, this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: const Icon(Icons.keyboard_arrow_down),
      ),
    );
  }
}

class HamvitButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const HamvitButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}

class HamvitCard extends StatelessWidget {
  final Widget child;
  const HamvitCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class HamvitBottomSheet extends StatelessWidget {
  final Widget child;
  const HamvitBottomSheet({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: HamvitColors.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class HamvitLoading extends StatelessWidget {
  const HamvitLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}


class HamvitBlockingLoadingOverlay extends StatelessWidget {
  final String message;
  const HamvitBlockingLoadingOverlay({
    super.key,
    this.message = 'Carregando seus dados...',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AbsorbPointer(
        absorbing: true,
        child: Stack(
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.5, sigmaY: 5.5),
              child: Container(color: Colors.black.withValues(alpha: 0.36)),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: HamvitColors.primaryNavy.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2.8),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: HamvitColors.darkText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class HamvitEmptyState extends StatelessWidget {
  final String message;
  const HamvitEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class HamvitOfflineBanner extends StatelessWidget {
  const HamvitOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: HamvitColors.warning.withValues(alpha: 0.15),
      padding: const EdgeInsets.all(10),
      child: const Text('Sem internet: o app continuará registrando localmente e sincronizará depois.'),
    );
  }
}

class HamvitErrorState extends StatelessWidget {
  final String message;
  const HamvitErrorState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: HamvitColors.danger)),
      ),
    );
  }
}

