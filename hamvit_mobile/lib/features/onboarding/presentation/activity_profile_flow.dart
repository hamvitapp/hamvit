import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../providers/onboarding_profile_provider.dart';

class ActivityProfileFlow extends ConsumerStatefulWidget {
  final bool showAppBar;

  const ActivityProfileFlow({super.key, this.showAppBar = true});

  @override
  ConsumerState<ActivityProfileFlow> createState() => _ActivityProfileFlowState();
}

class _ActivityProfileFlowState extends ConsumerState<ActivityProfileFlow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  String _activityLevel = 'moderada';

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProfileProvider);
    _weightCtrl = TextEditingController(text: state.weightKg?.toString() ?? '');
    _heightCtrl = TextEditingController(text: state.heightCm?.toString() ?? '');
    _activityLevel = state.activityLevel ?? 'moderada';
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProfileProvider);
    final notifier = ref.read(onboardingProfileProvider.notifier);

    return Scaffold(
      appBar: widget.showAppBar ? hamvitBackAppBar(context, title: 'Atividade Física') : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HamvitOnboardingStepper(
            currentStep: 2,
            totalSteps: 5,
            title: 'Dados para cálculos mais precisos',
            subtitle: 'Peso, altura e nivel de atividade melhoram calorias e metas.',
            primaryLabel: 'Proximo',
            secondaryLabel: 'Depois',
            onPrimary: () async {
              final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
              final height = int.tryParse(_heightCtrl.text.trim());
              if (weight == null || height == null) return;

              await notifier.saveActivityProfile(
                weightKg: weight,
                heightCm: height,
                activityLevel: _activityLevel,
              );

              if (!context.mounted) return;
              context.go('/onboarding/food');
            },
            onSecondary: () => context.go('/home'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _weightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Peso (kg)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _heightCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Altura (cm)'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _activityLevel,
            decoration: const InputDecoration(labelText: 'Nivel de atividade'),
            items: const [
              DropdownMenuItem(value: 'sedentaria', child: Text('Sedentaria')),
              DropdownMenuItem(value: 'leve', child: Text('Leve')),
              DropdownMenuItem(value: 'moderada', child: Text('Moderada')),
              DropdownMenuItem(value: 'alta', child: Text('Alta')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _activityLevel = value);
              }
            },
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(state.errorMessage!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
      ),
    );
  }
}
