import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/hamvit_date_utils.dart';
import '../../shared/widgets/hamvit_date_field.dart';
import '../../shared/widgets/hamvit_module_widgets.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';

class BodyDataPage extends ConsumerStatefulWidget {
  const BodyDataPage({super.key});

  @override
  ConsumerState<BodyDataPage> createState() => _BodyDataPageState();
}

class _BodyDataPageState extends ConsumerState<BodyDataPage> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _targetWeightCtrl;
  late final TextEditingController _birthDateCtrl;
  String? _birthDateIso;
  String _biologicalSex = 'não informado';

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProfileProvider);
    _weightCtrl = TextEditingController(text: state.weightKg?.toString() ?? '');
    _heightCtrl = TextEditingController(text: state.heightCm?.toString() ?? '');
    _targetWeightCtrl = TextEditingController(text: state.targetWeightKg?.toString() ?? '');
    _birthDateCtrl = TextEditingController(text: HamvitDateUtils.formatIsoToBr(state.birthDateIso) ?? '');
    _birthDateIso = state.birthDateIso;
    _biologicalSex = state.biologicalSex ?? 'não informado';
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  String? _validateWeight(double value) {
    if (value < 30 || value > 300) {
      return 'Peso fora do intervalo esperado (30 a 300 kg).';
    }
    return null;
  }

  String? _validateHeight(int value) {
    if (value < 120 || value > 230) {
      return 'Altura fora do intervalo esperado (120 a 230 cm).';
    }
    return null;
  }

  Future<void> _save() async {
    final notifier = ref.read(onboardingProfileProvider.notifier);
    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final height = int.tryParse(_heightCtrl.text.trim());
    final targetWeight = double.tryParse(_targetWeightCtrl.text.replaceAll(',', '.'));

    if (weight == null || height == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha peso e altura com valores válidos.')),
      );
      return;
    }

    final weightValidation = _validateWeight(weight);
    final heightValidation = _validateHeight(height);
    if (weightValidation != null || heightValidation != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(weightValidation ?? heightValidation!)),
      );
      return;
    }

    await notifier.saveBodyData(
      weightKg: weight,
      heightCm: height,
      targetWeightKg: targetWeight,
      birthDateIso: _birthDateIso,
      biologicalSex: _biologicalSex,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Dados corporais atualizados.')),
    );
  }

  void _showCalculationInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como calculamos suas metas'),
        content: const Text(
          'Usamos uma estimativa inicial com base em peso, altura, idade, sexo biológico, nível de atividade e objetivo. '
          'A meta calórica parte da TMB (Mifflin-St Jeor), passa pelo gasto diário estimado e aplica déficit seguro quando o objetivo é emagrecimento. '
          'A meta de água usa 35 ml/kg como referência inicial. Esses valores são estimativas e podem variar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProfileProvider);
    final targets = state.calculatedTargets;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Dados corporais', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        const Text('Edite peso, altura e dados base usados nas estimativas do app.'),
        const SizedBox(height: 12),
        TextField(
          controller: _weightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Peso atual (kg)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _heightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Altura (cm)'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _targetWeightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Peso desejado (kg)'),
        ),
        const SizedBox(height: 10),
        HamvitDateField(
          controller: _birthDateCtrl,
          label: 'Data de nascimento',
          lastDate: DateTime.now(),
          onIsoChanged: (iso) => _birthDateIso = iso,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _biologicalSex,
          decoration: const InputDecoration(labelText: 'Sexo biológico'),
          items: const [
            DropdownMenuItem(value: 'não informado', child: Text('Não informado')),
            DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
            DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
            DropdownMenuItem(value: 'intersexo', child: Text('Intersexo')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _biologicalSex = value);
            }
          },
        ),
        const SizedBox(height: 12),
        HamvitModuleSummaryCard(
          title: 'Meta calórica estimada',
          description: targets == null
              ? 'Preencha peso, altura e data de nascimento para calcular sua meta inicial segura.'
              : 'TMB estimada: ${targets.bmr.toStringAsFixed(0)} kcal\n'
                    'Gasto diário estimado: ${targets.tdee.toStringAsFixed(0)} kcal\n'
                    'Meta diária sugerida: ${targets.caloriesKcal} kcal\n'
                    'Déficit aplicado: ${targets.deficitPercent}% (${targets.deficitKcal} kcal)\n'
                    'Proteína estimada: ${targets.proteinG} g\n'
                    'Meta de água estimada: ${targets.waterMl} ml\n\n'
                    'Estimativa ajustável conforme evolução.',
          action: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FilledButton.icon(
                onPressed: state.isSaving
                    ? null
                    : () async {
                        await ref.read(onboardingProfileProvider.notifier).recalculateGoals();
                      },
                icon: const Icon(Icons.refresh),
                label: const Text('Recalcular metas'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _showCalculationInfo,
                icon: const Icon(Icons.info_outline),
                label: const Text('Entender cálculo'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ajustes avançados podem ser feitos depois com orientação profissional.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton(
          onPressed: state.isSaving ? null : _save,
          child: Text(state.isSaving ? 'Salvando...' : 'Salvar dados corporais'),
        ),
      ],
    );
  }
}
