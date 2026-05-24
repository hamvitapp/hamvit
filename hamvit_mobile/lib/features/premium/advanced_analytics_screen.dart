import 'package:flutter/material.dart';

import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';
import '../../shared/widgets/hamvit_components.dart';

class AdvancedAnalyticsScreen extends StatelessWidget {
  final bool isPremium;
  const AdvancedAnalyticsScreen({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context) {
    return PremiumFeatureGate(
      feature: HamvitFeature.analyticsAdvanced,
      isPremium: isPremium,
      fallback: const PremiumTeaserCard(feature: HamvitFeature.analyticsAdvanced),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HamvitHeader(title: 'Analytics avançado', subtitle: 'Disponível para Premium.'),
          SizedBox(height: 12),
          HamvitIconCard(assetPath: 'assets/icons/relatorios.png', label: 'Tendências de aderência'),
          SizedBox(height: 8),
          HamvitIconCard(assetPath: 'assets/icons/progresso.png', label: 'Correlações entre hábitos e resultados'),
        ],
      ),
    );
  }
}
