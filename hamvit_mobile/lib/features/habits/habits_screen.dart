import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../home/providers/home_dashboard_provider.dart';
import 'habit_model.dart';
import 'habit_provider.dart';
import 'habit_repository.dart';
import 'habits_widgets.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  HabitTemplate? _selectedTemplate;

  Future<void> _openCreateHabitSheet(BuildContext context, WidgetRef ref, {HabitModel? habit}) async {
    final titleCtrl = TextEditingController(text: habit?.title ?? '');
    final descriptionCtrl = TextEditingController(text: habit?.description ?? '');
    final frequencyCtrl = TextEditingController(text: habit?.frequency ?? 'Diário');
    final reminderCtrl = TextEditingController();
    const categories = ['Saúde', 'Água', 'Sono', 'Movimento', 'Alimentação', 'Mente'];
    var selectedCategory = habit?.category ?? categories.first;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(habit == null ? 'Criar hábito' : 'Editar hábito', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Nome do hábito'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: categories
                          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setModalState(() => selectedCategory = value);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: frequencyCtrl,
                      decoration: const InputDecoration(labelText: 'Frequência'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reminderCtrl,
                      decoration: const InputDecoration(labelText: 'Lembrete opcional'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: descriptionCtrl,
                      decoration: const InputDecoration(labelText: 'Descrição opcional'),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final title = titleCtrl.text.trim();
                          if (title.isEmpty) return;

                          if (habit == null) {
                            await ref.read(habitsControllerProvider.notifier).createHabit(
                                  title: title,
                                  category: selectedCategory,
                                  frequency: frequencyCtrl.text.trim().isEmpty ? 'Diário' : frequencyCtrl.text.trim(),
                                  description: descriptionCtrl.text.trim(),
                                );
                          } else {
                            await ref.read(habitsControllerProvider.notifier).updateHabit(
                                  habit.copyWith(
                                    title: title,
                                    category: selectedCategory,
                                    frequency: frequencyCtrl.text.trim().isEmpty ? 'Diário' : frequencyCtrl.text.trim(),
                                    description: descriptionCtrl.text.trim(),
                                  ),
                                );
                          }

                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: Text(habit == null ? 'Criar hábito' : 'Salvar edição'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _useSelectedSuggestion() async {
    if (_selectedTemplate == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escolha uma sugestão primeiro.')),
      );
      return;
    }

    await ref.read(habitsControllerProvider.notifier).useTemplate(_selectedTemplate!);
    if (!mounted) return;
    setState(() {
      _selectedTemplate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitsControllerProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível carregar seus hábitos.'),
              const SizedBox(height: 8),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.read(habitsControllerProvider.notifier).load(),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(habitsControllerProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HamvitHabitSummaryCard(summary: state.summary),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: HamvitCreateHabitButton(
                  onTap: () => _openCreateHabitSheet(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.habits.isEmpty)
            HamvitHabitEmptyState(
              suggestions: HabitRepository.suggestedTemplates,
              selectedSuggestionTitle: _selectedTemplate?.title,
              onSelectSuggestion: (template) {
                setState(() {
                  if (_selectedTemplate?.title == template.title) {
                    _selectedTemplate = null;
                  } else {
                    _selectedTemplate = template;
                  }
                });
              },
              onUseSuggestion: _useSelectedSuggestion,
              isUseSuggestionEnabled: _selectedTemplate != null,
            )
          else
            ...state.habits.map(
              (habit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HamvitHabitCard(
                  habit: habit,
                  onToggle: (value) async {
                    try {
                      await ref
                          .read(habitsControllerProvider.notifier)
                          .toggleHabit(habit, value);
                      ref.invalidate(homeDashboardProvider);
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erro ao concluir hábito: $e')),
                      );
                    }
                  },
                  onEdit: () => _openCreateHabitSheet(context, ref, habit: habit),
                  onRemove: () => ref.read(habitsControllerProvider.notifier).removeHabit(habit),
                ),
              ),
            ),
          const SizedBox(height: 4),
          HamvitHabitWeeklyHistory(weeklyMap: state.weeklyCompletion),
          const SizedBox(height: 10),
          HamvitHabitStreakCard(
            currentStreak: state.summary.currentStreak,
            bestStreak: state.summary.bestStreak,
          ),
        ],
      ),
    );
  }
}
