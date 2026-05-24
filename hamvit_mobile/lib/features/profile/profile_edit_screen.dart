import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase_provider.dart';
import '../../shared/widgets/hamvit_date_field.dart';
import '../auth/providers/auth_provider.dart';
import '../onboarding/providers/onboarding_profile_provider.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nameCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();

  String _sex = 'não informado';
  String _activityLevel = 'moderada';
  String? _birthIso;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    final onboarding = ref.read(onboardingProfileProvider);

    _nameCtrl.text = profile?.displayName ?? '';
    _birthIso = onboarding.birthDateIso;
    _birthCtrl.text = onboarding.birthDateIso == null ? '' : onboarding.birthDateIso!.split('-').reversed.join('/');
    _sex = onboarding.biologicalSex ?? 'não informado';
    _heightCtrl.text = onboarding.heightCm?.toString() ?? '';
    _weightCtrl.text = onboarding.weightKg?.toString() ?? '';
    _targetWeightCtrl.text = onboarding.targetWeightKg?.toString() ?? '';
    _activityLevel = onboarding.activityLevel ?? 'moderada';
    _objectiveCtrl.text = onboarding.objective ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _avatarCtrl.dispose();
    _birthCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    _objectiveCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    final client = ref.read(supabaseClientProvider);
    final notifier = ref.read(onboardingProfileProvider.notifier);

    final weight = double.tryParse(_weightCtrl.text.replaceAll(',', '.'));
    final height = int.tryParse(_heightCtrl.text.trim());
    final targetWeight = double.tryParse(_targetWeightCtrl.text.replaceAll(',', '.'));
    final objective = _objectiveCtrl.text.trim();

    if (weight == null || height == null || objective.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, objetivo, peso e altura com valores validos.')),
      );
      return;
    }

    if (client != null && user != null) {
      try {
        await client.from('profiles').update({
          'display_name': _nameCtrl.text.trim(),
          'full_name': _nameCtrl.text.trim(),
          'avatar_url': _avatarCtrl.text.trim().isEmpty ? null : _avatarCtrl.text.trim(),
        }).eq('id', user.id);
      } catch (_) {}
    }

    await notifier.saveGeneralProfile(objective: objective);
    await notifier.saveActivityPreferences(
      activityLevel: _activityLevel,
      limitations: null,
      trainingPreference: null,
      availableDays: const [],
      availableMinutes: null,
    );
    await notifier.saveBodyData(
      weightKg: weight,
      heightCm: height,
      targetWeightKg: targetWeight,
      birthDateIso: _birthIso,
      biologicalSex: _sex,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Perfil atualizado com sucesso.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProfileProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Editar perfil', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nome')),
        const SizedBox(height: 8),
        TextField(controller: _avatarCtrl, decoration: const InputDecoration(labelText: 'Avatar (URL opcional)')),
        const SizedBox(height: 8),
        HamvitDateField(
          label: 'Data de nascimento',
          controller: _birthCtrl,
          onIsoChanged: (iso) => _birthIso = iso,
          lastDate: DateTime.now(),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _sex,
          decoration: const InputDecoration(labelText: 'Sexo biologico'),
          items: const [
            DropdownMenuItem(value: 'não informado', child: Text('Nao informado')),
            DropdownMenuItem(value: 'feminino', child: Text('Feminino')),
            DropdownMenuItem(value: 'masculino', child: Text('Masculino')),
            DropdownMenuItem(value: 'intersexo', child: Text('Intersexo')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _sex = v);
          },
        ),
        const SizedBox(height: 8),
        TextField(controller: _heightCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Altura (cm)')),
        const SizedBox(height: 8),
        TextField(controller: _weightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso atual (kg)')),
        const SizedBox(height: 8),
        TextField(controller: _targetWeightCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso desejado (kg)')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _activityLevel,
          decoration: const InputDecoration(labelText: 'Nivel de atividade'),
          items: const [
            DropdownMenuItem(value: 'sedentaria', child: Text('Sedentaria')),
            DropdownMenuItem(value: 'leve', child: Text('Leve')),
            DropdownMenuItem(value: 'moderada', child: Text('Moderada')),
            DropdownMenuItem(value: 'alta', child: Text('Alta')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _activityLevel = v);
          },
        ),
        const SizedBox(height: 8),
        TextField(controller: _objectiveCtrl, decoration: const InputDecoration(labelText: 'Objetivo principal')),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: state.isSaving ? null : _save,
          child: Text(state.isSaving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
