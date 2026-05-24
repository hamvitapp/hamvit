import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../providers/onboarding_profile_provider.dart';

class SleepFlow extends ConsumerStatefulWidget {
  final bool showAppBar;

  const SleepFlow({super.key, this.showAppBar = true});

  @override
  ConsumerState<SleepFlow> createState() => _SleepFlowState();
}

class _SleepFlowState extends ConsumerState<SleepFlow> {
  late final TextEditingController _sleepCtrl;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProfileProvider);
    _sleepCtrl = TextEditingController(text: state.sleepHours?.toString() ?? '8');
  }

  @override
  void dispose() {
    _sleepCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingProfileProvider.notifier);

    return Scaffold(
      appBar: widget.showAppBar ? hamvitBackAppBar(context, title: 'Sono') : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HamvitOnboardingStepper(
            currentStep: 4,
            totalSteps: 5,
            title: 'Meta de sono',
            subtitle: 'Pode ajustar depois sem travar navegação.',
            primaryLabel: 'Salvar',
            secondaryLabel: 'Depois',
            onPrimary: () async {
              final hours = double.tryParse(_sleepCtrl.text.replaceAll(',', '.'));
              if (hours == null) return;
              await notifier.saveSleepProfile(hoursTarget: hours);
              if (!context.mounted) return;
              context.go('/home');
            },
            onSecondary: () => context.go('/home'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _sleepCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Horas de sono por noite'),
          ),
        ],
      ),
    );
  }
}
