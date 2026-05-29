import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/onboarding/providers/onboarding_profile_provider.dart';

class ActivityPreferencesScreen extends ConsumerStatefulWidget {
  const ActivityPreferencesScreen({super.key});

  @override
  ConsumerState<ActivityPreferencesScreen> createState() => _ActivityPreferencesScreenState();
}

class _ActivityPreferencesScreenState extends ConsumerState<ActivityPreferencesScreen> {
  late String _activityLevel;
  final _limitationsCtrl = TextEditingController();
  late String _preference;
  final Set<String> _days = {};
  final _minutesCtrl = TextEditingController();

  static const _levels = ['sedentaria', 'leve', 'moderada', 'alta'];
  static const _preferences = ['caminhada', 'corrida', 'treino em casa'];
  static const _weekDays = ['seg', 'ter', 'qua', 'qui', 'sex', 'sab', 'dom'];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingProfileProvider);
    final prefs = state.activityPreferences;
    _activityLevel = state.activityLevel ?? (prefs['activity_level']?.toString() ?? 'moderada');
    _preference = prefs['training_preference']?.toString() ?? 'caminhada';
    _limitationsCtrl.text = prefs['limitations']?.toString() ?? '';
    _minutesCtrl.text = prefs['available_minutes']?.toString() ?? '';
    final rawDays = prefs['available_days'];
    if (rawDays is List) {
      _days.addAll(rawDays.map((e) => e.toString()));
    }
  }

  @override
  void dispose() {
    _limitationsCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(onboardingProfileProvider.notifier);
    final currentState = ref.read(onboardingProfileProvider);

    final weight = currentState.weightKg ?? 70;
    final height = currentState.heightCm ?? 170;
    final availableMinutes = int.tryParse(_minutesCtrl.text.trim());

    await notifier.saveActivityProfile(
      weightKg: weight,
      heightCm: height,
      activityLevel: _activityLevel,
    );

    await notifier.saveActivityPreferences(
      activityLevel: _activityLevel,
      limitations: _limitationsCtrl.text.trim().isEmpty ? null : _limitationsCtrl.text.trim(),
      trainingPreference: _preference,
      availableDays: _days.toList(),
      availableMinutes: availableMinutes,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Preferencias de atividade salvas.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProfileProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        DropdownButtonFormField<String>(
          initialValue: _activityLevel,
          decoration: const InputDecoration(labelText: 'Nivel de atividade'),
          items: _levels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _activityLevel = value);
          },
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _limitationsCtrl,
          decoration: const InputDecoration(
            labelText: 'Limitacoes leves',
            hintText: 'Opcional',
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _preference,
          decoration: const InputDecoration(labelText: 'Preferencia principal'),
          items: _preferences.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (value) {
            if (value != null) setState(() => _preference = value);
          },
        ),
        const SizedBox(height: 8),
        Text('Dias disponiveis', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _weekDays
              .map(
                (d) => FilterChip(
                  label: Text(d.toUpperCase()),
                  selected: _days.contains(d),
                  onSelected: (_) {
                    setState(() {
                      if (_days.contains(d)) {
                        _days.remove(d);
                      } else {
                        _days.add(d);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _minutesCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Tempo disponivel (minutos)'),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: state.isSaving ? null : _save,
          child: Text(state.isSaving ? 'Salvando...' : 'Salvar'),
        ),
      ],
    );
  }
}
