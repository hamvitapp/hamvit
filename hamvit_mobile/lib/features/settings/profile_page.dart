import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../onboarding/providers/onboarding_profile_provider.dart';
import '../../shared/widgets/hamvit_components.dart';

class ProfilePage extends ConsumerWidget {
  final String? name;
  final bool isPremium;
  final VoidCallback onLogout;

  const ProfilePage({super.key, this.name, required this.isPremium, required this.onLogout});

  Widget _profileItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool completed,
    required String route,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(completed ? 'Completo' : 'Pendente'),
      trailing: OutlinedButton(
        onPressed: () => context.go(route),
        child: const Text('Editar'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingProfileProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HamvitCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name ?? 'Usuário HAMVIT', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(isPremium ? 'Premium Vitalício' : 'Plano Free', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 10),
        HamvitCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Completar Perfil', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              _profileItem(
                context: context,
                icon: Icons.flag_outlined,
                title: 'Objetivo',
                completed: onboarding.hasObjective,
                route: '/onboarding/general',
              ),
              _profileItem(
                context: context,
                icon: Icons.monitor_weight_outlined,
                title: 'Peso',
                completed: onboarding.hasWeight,
                route: '/onboarding/activity',
              ),
              _profileItem(
                context: context,
                icon: Icons.height,
                title: 'Altura',
                completed: onboarding.hasHeight,
                route: '/onboarding/activity',
              ),
              _profileItem(
                context: context,
                icon: Icons.directions_run,
                title: 'Atividade',
                completed: onboarding.hasActivity,
                route: '/onboarding/activity',
              ),
              _profileItem(
                context: context,
                icon: Icons.restaurant_menu,
                title: 'Alimentação',
                completed: onboarding.hasFoodPreferences && onboarding.hasFoodRestrictions,
                route: '/onboarding/food',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const HamvitIconCard(
          assetPath: 'assets/icons/sono.png',
          label: 'Privacidade e segurança',
          subtitle: 'Dados pessoais protegidos por regras de acesso (RLS).',
        ),
        const SizedBox(height: 10),
        HamvitButton(label: 'Sair', onPressed: onLogout),
      ],
    );
  }
}
