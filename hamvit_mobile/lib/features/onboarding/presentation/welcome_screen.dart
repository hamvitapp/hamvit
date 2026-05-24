import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../providers/onboarding_profile_provider.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(onboardingProfileProvider);
    final notifier = ref.read(onboardingProfileProvider.notifier);

    return Scaffold(
      appBar: hamvitBackAppBar(context, title: 'Bem-vindo ao HAMVIT'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 120,
            child: Image.asset('assets/branding/inicio.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 12),
          Text('HAMVIT', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text('Evolua no seu ritmo com foco em saúde real.'),
          const SizedBox(height: 14),
          const Text('Vamos personalizar sua experiencia.'),
          const SizedBox(height: 14),
          const HamvitFeatureUnlockCard(
            title: 'Onboarding contextual',
            benefits: [
              'Metas mais precisas',
              'Sugestões inteligentes ao seu perfil',
              'Coleta progressiva, sem formulario gigante',
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              await notifier.markWelcomeSeen();
              if (!context.mounted) return;
              context.go('/onboarding/general');
            },
            child: const Text('Comecar'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: profile.isSaving
                ? null
                : () async {
                    await notifier.markWelcomeSeen();
                    if (!context.mounted) return;
                    context.go('/home');
                  },
            child: const Text('Pular por agora'),
          ),
        ],
      ),
    );
  }
}
