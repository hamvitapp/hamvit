import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../providers/onboarding_profile_provider.dart';

class HydrationFlow extends ConsumerStatefulWidget {
  final bool showAppBar;

  const HydrationFlow({super.key, this.showAppBar = true});

  @override
  ConsumerState<HydrationFlow> createState() => _HydrationFlowState();
}

class _HydrationFlowState extends ConsumerState<HydrationFlow> {
  late final TextEditingController _hydrationCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProfileProvider);
    _hydrationCtrl = TextEditingController(text: state.hydrationGoalMl?.toString() ?? '2200');
  }

  @override
  void dispose() {
    _hydrationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProfileProvider.notifier);

    return Scaffold(
      appBar: widget.showAppBar ? hamvitBackAppBar(context, title: 'Hidratação') : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HamvitOnboardingStepper(
            currentStep: 5,
            totalSteps: 5,
            title: 'Hidratação diária',
            subtitle: 'Meta opcional para acompanhar seu ritmo.',
            primaryLabel: 'Salvar',
            secondaryLabel: 'Depois',
            onPrimary: () async {
              final ml = int.tryParse(_hydrationCtrl.text.trim());
              if (ml == null) return;
              await notifier.saveHydrationProfile(mlTarget: ml);
              if (!context.mounted) return;
              context.go('/home');
            },
            onSecondary: () => context.go('/home'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _hydrationCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Meta diária de água (ml)'),
          ),
        ],
      ),
    );
  }
}
