import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/hamvit_date_utils.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';
import '../../../shared/widgets/hamvit_module_widgets.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  String _orPending(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? 'Não preenchido' : trimmed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProfileProvider);
    final targets = state.calculatedTargets;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final weightDiff = targets?.weightDifferenceKg;
    final estimatedWeeks = targets?.estimatedWeeks;
    final lastUpdated = HamvitDateUtils.formatIsoToBr(state.goalsUpdatedAtIso);

    final dataRows = <MapEntry<String, String>>[
      MapEntry('Objetivo atual', _orPending(state.objective)),
      MapEntry('Peso atual', state.weightKg != null ? '${state.weightKg!.toStringAsFixed(1)} kg' : 'Não preenchido'),
      MapEntry('Peso desejado', state.targetWeightKg != null ? '${state.targetWeightKg!.toStringAsFixed(1)} kg' : 'Não preenchido'),
      MapEntry('Diferença', weightDiff == null ? 'Não disponível' : '${weightDiff.toStringAsFixed(1)} kg'),
      MapEntry(
        'Tempo saudável estimado',
        estimatedWeeks == null ? 'Não disponível' : 'Cerca de $estimatedWeeks semanas (0,5 kg/semana)',
      ),
      MapEntry('Altura', state.heightCm != null ? '${state.heightCm} cm' : 'Não preenchido'),
      MapEntry('Nível de atividade', _orPending(state.activityLevel)),
      MapEntry(
        'Preferência alimentar',
        state.foodPreferences.isEmpty ? 'Não preenchido' : state.foodPreferences.join(', '),
      ),
      MapEntry(
        'Restrições',
        state.foodRestrictions.isEmpty ? 'Não preenchido' : state.foodRestrictions.join(', '),
      ),
      MapEntry('Meta de sono', state.sleepHours != null ? '${state.sleepHours!.toStringAsFixed(1)} h/noite' : 'Não preenchido'),
      MapEntry('Meta de água estimada', targets != null ? '${targets.waterMl} ml/dia' : 'Não preenchido'),
      MapEntry('Meta calórica estimada', targets != null ? '${targets.caloriesKcal} kcal/dia' : 'Não preenchido'),
      MapEntry('Última atualização', lastUpdated ?? 'Não disponível'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                for (final row in dataRows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(row.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(child: Text(row.value)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (estimatedWeeks != null)
          const HamvitModuleSummaryCard(
            title: 'Estimativa de tempo saudável',
            description:
                'Estimativa saudável aproximada. O ritmo pode variar conforme rotina, adesão e acompanhamento profissional.',
          ),
        if (estimatedWeeks != null) const SizedBox(height: 10),
        HamvitEditGoalButton(
          label: 'Editar objetivo',
          onPressed: () => context.push('/profile/edit'),
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 8),
        HamvitEditGoalButton(
          label: 'Editar dados corporais',
          onPressed: () => context.push('/profile/body-data'),
          icon: Icons.monitor_weight_outlined,
        ),
        const SizedBox(height: 8),
        HamvitEditGoalButton(
          label: 'Editar alimentação',
          onPressed: () => context.push('/nutrition/preferences'),
          icon: Icons.restaurant_menu,
        ),
        const SizedBox(height: 8),
        HamvitEditGoalButton(
          label: 'Editar atividade',
          onPressed: () => context.push('/activities/preferences'),
          icon: Icons.directions_run,
        ),
        const SizedBox(height: 8),
        HamvitEditGoalButton(
          label: 'Editar sono',
          onPressed: () => context.push('/sleep/settings'),
          icon: Icons.nightlight_round,
        ),
        const SizedBox(height: 8),
        HamvitEditGoalButton(
          label: 'Editar hidratação',
          onPressed: () => context.push('/hydration/settings'),
          icon: Icons.local_drink_outlined,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () async {
            await ref.read(onboardingProfileProvider.notifier).recalculateGoals();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Recalcular metas'),
        ),
      ],
    );
  }
}
