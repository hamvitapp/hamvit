import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/hamvit_module_widgets.dart';
import '../home/providers/home_dashboard_provider.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';

class HydrationPage extends ConsumerStatefulWidget {
  const HydrationPage({super.key});

  @override
  ConsumerState<HydrationPage> createState() => _HydrationPageState();
}

class _HydrationPageState extends ConsumerState<HydrationPage> {
  final List<String> _todayHistory = [];
  final List<String> _weekHistory = const [
    'Seg: 1800 ml',
    'Ter: 2200 ml',
    'Qua: 2100 ml',
    'Qui: 1900 ml',
    'Sex: 2300 ml',
    'Sab: 2000 ml',
    'Dom: 1750 ml',
  ];

  Future<void> _addWater(int ml) async {
    try {
      await ref.read(homeDashboardActionsProvider).quickAddWater(amountMl: ml);
      ref.invalidate(homeDashboardProvider);
      await ref.read(homeDashboardProvider.future);
      if (!mounted) return;
      setState(() {
        _todayHistory.insert(0, '+$ml ml • ${TimeOfDay.now().format(context)}');
        if (_todayHistory.length > 8) {
          _todayHistory.removeLast();
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$ml ml registrados com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao registrar agua: $error')),
      );
    }
  }

  Future<void> _editGoalAdvanced(int currentGoal) async {
    final ctrl = TextEditingController(text: currentGoal.toString());
    final notifier = ref.read(onboardingProfileProvider.notifier);

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajuste avançado da meta de água'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Meta (ml/dia) • limite 1200 a 6000'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final value = int.tryParse(ctrl.text.trim());
              if (value == null) return;
              await notifier.saveHydrationAdvancedGoal(mlTarget: value);
              if (!mounted) return;
              ref.invalidate(homeDashboardProvider);
              Navigator.of(this.context).pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(onboardingProfileProvider);
    final dashboardAsync = ref.watch(homeDashboardProvider);
    final calculatedGoal = onboarding.calculatedTargets?.waterMl;
    final fallbackGoal = calculatedGoal ?? onboarding.hydrationGoalMl ?? 2200;

    final consumedMl =
        dashboardAsync.maybeWhen(data: (data) => data.waterMl, orElse: () => 0);
    final goal = dashboardAsync.maybeWhen(
        data: (data) => data.waterGoalMl, orElse: () => fallbackGoal);
    final safeGoal = goal <= 0 ? fallbackGoal : goal;
    final progress = (consumedMl / safeGoal).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (false) const HamvitSectionHeader(
          title: 'Hidratação',
          subtitle:
              'Acompanhe consumo diário, meta calculada por peso e histórico de água.',
        ),
        if (false) const SizedBox(height: 12),
        HamvitProgressCard(
          title: 'Meta diária de água',
          subtitle: '$consumedMl ml consumidos de $safeGoal ml',
          progress: progress,
        ),
        const SizedBox(height: 8),
        HamvitMetricCard(
          label: 'Percentual atingido',
          value: '${(progress * 100).round()}%',
          icon: Icons.local_drink_outlined,
          helper: 'Meta sugerida com base no seu peso corporal (35 ml/kg/dia).',
        ),
        const SizedBox(height: 8),
        const HamvitModuleSummaryCard(
          title: 'Como definimos sua meta',
          description:
              'Usamos 35 ml por kg de peso corporal como referência inicial. Você pode fazer ajuste avançado depois, se necessário.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _addWater(200),
                child: const Text('+200 ml'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _addWater(300),
                child: const Text('+300 ml'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _addWater(500),
                child: const Text('+500 ml'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => _editGoalAdvanced(safeGoal),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Ajustes avançados'),
          ),
        ),
        const SizedBox(height: 8),
        HamvitHistoryCard(
          title: 'Histórico do dia',
          items: _todayHistory,
          icon: Icons.today_outlined,
        ),
        const SizedBox(height: 8),
        HamvitHistoryCard(
          title: 'Histórico semanal',
          items: _weekHistory,
          icon: Icons.calendar_view_week,
        ),
      ],
    );
  }
}
