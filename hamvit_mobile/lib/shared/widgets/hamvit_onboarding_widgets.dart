import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/hamvit_colors.dart';

class HamvitProgressRing extends StatelessWidget {
  final int percent;
  final double size;

  const HamvitProgressRing({
    super.key,
    required this.percent,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    final value = (percent.clamp(0, 100)) / 100;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.16),
            valueColor: const AlwaysStoppedAnimation<Color>(HamvitColors.accentCyan),
          ),
          Text('${percent.clamp(0, 100)}%', style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class HamvitOnboardingStepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String title;
  final String subtitle;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  const HamvitOnboardingStepper({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onPrimary,
    required this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep / totalSteps).clamp(0, 1).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Passo $currentStep de $totalSteps', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitContextualCTA extends StatelessWidget {
  final String title;
  final String subtitle;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback? onSecondary;

  const HamvitContextualCTA({
    super.key,
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel = 'Agora não',
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(onPressed: onSecondary, child: Text(secondaryLabel)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitSoftGateCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  const HamvitSoftGateCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return HamvitContextualCTA(
      title: title,
      subtitle: subtitle,
      primaryLabel: buttonLabel,
      onPrimary: onTap,
          secondaryLabel: 'Agora não',
      onSecondary: () {},
    );
  }
}

class HamvitFeatureUnlockCard extends StatelessWidget {
  final String title;
  final List<String> benefits;

  const HamvitFeatureUnlockCard({
    super.key,
    required this.title,
    required this.benefits,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final benefit in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: HamvitColors.accentGreen),
                    const SizedBox(width: 8),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class HamvitProfileCompletionCard extends StatelessWidget {
  final int percent;
  final VoidCallback onContinue;

  const HamvitProfileCompletionCard({
    super.key,
    required this.percent,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            HamvitProgressRing(percent: percent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Seu perfil está $percent% completo.', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  const Text('Complete seu perfil para liberar metas e recomendações personalizadas.'),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: onContinue, child: const Text('Continuar')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitPremiumPreviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onKnowPremium;

  const HamvitPremiumPreviewCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onKnowPremium,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    height: 90,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          HamvitColors.primaryNavy.withValues(alpha: 0.85),
                          HamvitColors.primaryDark.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text('Preview inteligente', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(color: Colors.black.withValues(alpha: 0.15)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(subtitle),
            const SizedBox(height: 8),
            const Text('Premium Vitalício'),
            const Text('Sem mensalidade'),
            const Text('Sem anuncios'),
            const Text('Sem anúncios'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onKnowPremium,
                    child: const Text('Conhecer Premium'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('Agora não'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void openOnboardingFlow(BuildContext context, String route) {
  context.go(route);
}
