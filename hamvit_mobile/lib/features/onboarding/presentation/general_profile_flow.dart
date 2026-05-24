import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../shared/widgets/hamvit_onboarding_widgets.dart';
import '../providers/onboarding_profile_provider.dart';

class GeneralProfileFlow extends ConsumerStatefulWidget {
  final bool showAppBar;

  const GeneralProfileFlow({super.key, this.showAppBar = true});

  @override
  ConsumerState<GeneralProfileFlow> createState() => _GeneralProfileFlowState();
}

class _GeneralProfileFlowState extends ConsumerState<GeneralProfileFlow> {
  static const List<String> _goalOptions = [
    'Emagrecer',
    'Ganhar massa muscular',
    'Melhorar saúde',
    'Condicionamento fisico',
    'Manter peso',
    'Reeducacao alimentar',
  ];

  late final TextEditingController _objectiveCtrl;
  String? _selectedGoal;

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProfileProvider);
    _objectiveCtrl = TextEditingController(text: state.objective ?? '');
    final existing = state.objective?.trim();
    if (existing != null && _goalOptions.contains(existing)) {
      _selectedGoal = existing;
    }
  }

  @override
  void dispose() {
    _objectiveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProfileProvider);
    final notifier = ref.read(onboardingProfileProvider.notifier);

    return Scaffold(
      appBar: widget.showAppBar ? hamvitBackAppBar(context, title: 'Objetivo principal') : null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HamvitOnboardingStepper(
            currentStep: 1,
            totalSteps: 5,
            title: 'Objetivo principal',
            subtitle: 'Defina seu foco para personalizar metas e recomendações.',
            primaryLabel: 'Próximo',
            secondaryLabel: 'Depois',
            onPrimary: () async {
              final selected = _selectedGoal?.trim();
              if (selected == null || !_goalOptions.contains(selected)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selecione um objetivo da lista sugerida.')),
                );
                return;
              }

              await notifier.saveGeneralProfile(objective: selected);
              if (!context.mounted) return;
              context.go('/onboarding/activity');
            },
            onSecondary: () => context.go('/home'),
          ),
          const SizedBox(height: 12),
          Autocomplete<String>(
            initialValue: TextEditingValue(text: _objectiveCtrl.text),
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) return _goalOptions;
              return _goalOptions.where((item) => item.toLowerCase().contains(query));
            },
            onSelected: (selection) {
              _selectedGoal = selection;
              _objectiveCtrl.text = selection;
            },
            fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
              textEditingController.text = _objectiveCtrl.text;
              textEditingController.selection = TextSelection.fromPosition(
                TextPosition(offset: textEditingController.text.length),
              );

              textEditingController.addListener(() {
                final value = textEditingController.text.trim();
                _objectiveCtrl.text = value;
                if (!_goalOptions.contains(value)) {
                  _selectedGoal = null;
                }
              });

              return TextField(
                controller: textEditingController,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Objetivo',
                  hintText: 'Digite para filtrar e selecione uma opção',
                ),
              );
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
