import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/body_data_page.dart';
import '../../../shared/widgets/hamvit_components.dart';
import 'general_profile_flow.dart';
import '../providers/onboarding_profile_provider.dart';

class ObjectivesSummaryScreen extends ConsumerWidget {
  const ObjectivesSummaryScreen({super.key});

  Widget _rowItem({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProfileProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        HamvitCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Minhas escolhas e valores', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _rowItem(label: 'Objetivo', value: state.objective ?? 'Não preenchido'),
              _rowItem(label: 'Peso', value: state.weightKg != null ? '${state.weightKg} kg' : 'Não preenchido'),
              _rowItem(label: 'Altura', value: state.heightCm != null ? '${state.heightCm} cm' : 'Não preenchido'),
              _rowItem(label: 'Atividade', value: state.activityLevel ?? 'Não preenchido'),
              _rowItem(
                label: 'Alimentação',
                value: state.foodPreferences.isEmpty ? 'Não preenchido' : state.foodPreferences.join(', '),
              ),
              _rowItem(
                label: 'Restrições',
                value: state.foodRestrictions.isEmpty ? 'Não preenchido' : state.foodRestrictions.join(', '),
              ),
              _rowItem(
                label: 'Sono',
                value: state.sleepHours != null ? '${state.sleepHours} h/noite' : 'Não preenchido',
              ),
              _rowItem(
                label: 'Hidratação',
                value: state.hydrationGoalMl != null ? '${state.hydrationGoalMl} ml/dia' : 'Não preenchido',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const GeneralProfileFlow()),
                        );
                      },
                      child: const Text('Editar objetivo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BodyDataPage()),
                        );
                      },
                      child: const Text('Editar dados'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
