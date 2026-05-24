import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../providers/onboarding_profile_provider.dart';

class FoodPreferencesFlow extends ConsumerStatefulWidget {
  final bool showAppBar;

  const FoodPreferencesFlow({super.key, this.showAppBar = true});

  @override
  ConsumerState<FoodPreferencesFlow> createState() => _FoodPreferencesFlowState();
}

class _FoodPreferencesFlowState extends ConsumerState<FoodPreferencesFlow> {
  final List<String> _allPreferences = const ['Caseiro', 'Low carb', 'Vegetariano', 'Rapido'];
  final List<String> _allRestrictions = const ['Lactose', 'Gluten', 'Acucar', 'Frutos do mar'];

  late Set<String> _preferences;
  late Set<String> _restrictions;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProfileProvider);
    _preferences = {...state.foodPreferences};
    _restrictions = {...state.foodRestrictions};
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProfileProvider.notifier);

    return Scaffold(
      appBar: widget.showAppBar ? hamvitBackAppBar(context, title: 'Alimentação') : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HamvitOnboardingStepper(
            currentStep: 3,
            totalSteps: 5,
            title: 'Preferências alimentares',
            subtitle: 'Assim suas sugestões ficam mais inteligentes.',
            primaryLabel: 'Salvar',
            secondaryLabel: 'Pular',
            onPrimary: () async {
              await notifier.saveFoodPreferences(
                preferences: _preferences.toList(),
                restrictions: _restrictions.toList(),
              );
              if (!context.mounted) return;
              context.go('/home');
            },
            onSecondary: () => context.go('/home'),
          ),
          const SizedBox(height: 12),
          Text('Preferências', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allPreferences
                .map(
                  (item) => FilterChip(
                    label: Text(item),
                    selected: _preferences.contains(item),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _preferences.add(item);
                        } else {
                          _preferences.remove(item);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Text('Restrições', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allRestrictions
                .map(
                  (item) => FilterChip(
                    label: Text(item),
                    selected: _restrictions.contains(item),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _restrictions.add(item);
                        } else {
                          _restrictions.remove(item);
                        }
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
