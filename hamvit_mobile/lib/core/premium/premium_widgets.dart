import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

import 'premium_access_matrix.dart';

class PremiumBadge extends StatelessWidget {
  final String label;
  const PremiumBadge({super.key, this.label = 'Premium Vitalício'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [Color(0xFF2ED573), Color(0xFF00B7D8)],
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class PremiumTeaserCard extends StatelessWidget {
  final HamvitFeature feature;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  const PremiumTeaserCard({super.key, required this.feature, this.onTap, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final access = PremiumAccessMatrix.of(feature);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PremiumBadge(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    access.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Container(
                    height: 84,
                    width: double.infinity,
                    color: const Color(0xFF0B1C31),
                    child: const Center(
                      child: Text(
                        'Preview inteligente',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(color: Colors.black.withValues(alpha: 0.16)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(access.teaser),
            const SizedBox(height: 8),
            const Text('Sem mensalidade â€¢ Sem anúncios â€¢ Evolua no seu ritmo.'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    child: const Text('Conhecer Premium'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss ?? () {},
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

class PremiumUpsellSheet extends StatelessWidget {
  final HamvitFeature feature;
  const PremiumUpsellSheet({super.key, required this.feature});

  @override
  Widget build(BuildContext context) {
    final access = PremiumAccessMatrix.of(feature);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const PremiumBadge(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(access.title, style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(access.premiumDescription),
            const SizedBox(height: 8),
            const Text('Premium Vitalício'),
            const Text('Sem mensalidade'),
            const Text('Sem anuncios'),
            const Text('Evolua no seu ritmo.'),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/premium');
                },
                child: const Text('Ver plano Premium'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumFeatureGate extends StatelessWidget {
  final HamvitFeature feature;
  final bool isPremium;
  final Widget child;
  final Widget? fallback;
  final bool showTeaser;

  const PremiumFeatureGate({
    super.key,
    required this.feature,
    required this.isPremium,
    required this.child,
    this.fallback,
    this.showTeaser = true,
  });

  @override
  Widget build(BuildContext context) {
    if (PremiumAccessMatrix.isAllowed(feature, isPremium: isPremium)) {
      return child;
    }

    if (fallback != null) return fallback!;

    if (!showTeaser) return const SizedBox.shrink();

    return PremiumTeaserCard(
      feature: feature,
      onTap: () {
        showModalBottomSheet(
          context: context,
          useSafeArea: true,
          builder: (_) => PremiumUpsellSheet(feature: feature),
        );
      },
    );
  }
}
