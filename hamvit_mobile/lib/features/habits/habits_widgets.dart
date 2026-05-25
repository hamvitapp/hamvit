import 'package:flutter/material.dart';

import '../../core/hamvit_date_utils.dart';
import '../../theme/hamvit_colors.dart';
import 'habit_model.dart';

class HamvitHabitSummaryCard extends StatelessWidget {
  final HabitsDailySummary summary;

  const HamvitHabitSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0E2C47), Color(0xFF0F3B4F), Color(0xFF166065)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hábitos de hoje', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              '${summary.completed} de ${summary.total} hábitos concluídos hoje',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: summary.progress,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: const AlwaysStoppedAnimation<Color>(HamvitColors.accentMint),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(summary.progress * 100).round()}% concluído',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            const Text('Pequenos passos também contam.', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class HamvitHabitCard extends StatelessWidget {
  final HabitModel habit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const HamvitHabitCard({
    super.key,
    required this.habit,
    required this.onToggle,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final done = habit.doneToday;

    return Card(
      color: const Color(0xFF102840),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: HamvitColors.accentCyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle_outline_rounded, color: HamvitColors.accentMint),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(habit.title, style: const TextStyle(color: HamvitColors.darkText, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(habit.description, style: const TextStyle(color: HamvitColors.darkTextMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Categoria: ${habit.category}'),
                _chip('Frequência: ${habit.frequency}'),
                _chip(done ? 'Concluído hoje' : 'Pendente hoje'),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => onToggle(!done),
                    icon: Icon(done ? Icons.undo : Icons.check),
                    label: Text(done ? 'Desfazer' : 'Concluir'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined, color: Colors.white70)),
                IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline, color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: const TextStyle(color: HamvitColors.darkTextMuted, fontSize: 12)),
    );
  }
}

class HamvitCreateHabitButton extends StatelessWidget {
  final VoidCallback onTap;

  const HamvitCreateHabitButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add_circle_outline),
      label: const Text('Criar hábito'),
    );
  }
}

class HamvitHabitWeeklyHistory extends StatelessWidget {
  final Map<String, bool> weeklyMap;

  const HamvitHabitWeeklyHistory({super.key, required this.weeklyMap});

  @override
  Widget build(BuildContext context) {
    final ordered = weeklyMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    return Card(
      color: const Color(0xFF102840),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Esta semana', style: TextStyle(color: HamvitColors.darkText, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final item in ordered)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          Text(
                            HamvitDateUtils.formatIsoToBr(item.key)?.substring(0, 2) ?? '--',
                            style: const TextStyle(color: HamvitColors.darkTextMuted, fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 34,
                            decoration: BoxDecoration(
                              color: item.value ? HamvitColors.accentMint : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Icon(
                                item.value ? Icons.check_rounded : Icons.remove,
                                color: item.value ? HamvitColors.primaryDark : HamvitColors.darkTextMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HamvitHabitStreakCard extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;

  const HamvitHabitStreakCard({super.key, required this.currentStreak, required this.bestStreak});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF102840),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Frequência', style: TextStyle(color: HamvitColors.darkText, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Frequência atual: $currentStreak dias', style: const TextStyle(color: HamvitColors.darkText)),
            Text('Melhor frequência: $bestStreak dias', style: const TextStyle(color: HamvitColors.darkText)),
            const SizedBox(height: 6),
            const Text('Continue no seu ritmo.', style: TextStyle(color: HamvitColors.darkTextMuted)),
          ],
        ),
      ),
    );
  }
}

class HamvitHabitEmptyState extends StatelessWidget {
  final List<HabitTemplate> suggestions;
  final String? selectedSuggestionTitle;
  final ValueChanged<HabitTemplate> onSelectSuggestion;
  final VoidCallback onUseSuggestion;
  final bool isUseSuggestionEnabled;

  const HamvitHabitEmptyState({
    super.key,
    required this.suggestions,
    required this.selectedSuggestionTitle,
    required this.onSelectSuggestion,
    required this.onUseSuggestion,
    required this.isUseSuggestionEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF102840),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Comece com pequenos hábitos.', style: TextStyle(color: HamvitColors.darkText, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Escolha um hábito simples para acompanhar hoje.', style: TextStyle(color: HamvitColors.darkTextMuted)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: suggestions
                  .map(
                    (template) => _SuggestionChip(
                      label: template.title,
                      isSelected: selectedSuggestionTitle == template.title,
                      onTap: () => onSelectSuggestion(template),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isUseSuggestionEnabled ? onUseSuggestion : null,
                child: const Text('Usar sugestão'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? HamvitColors.accentMint.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? HamvitColors.accentMint.withValues(alpha: 0.75)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? HamvitColors.darkText : HamvitColors.darkTextMuted,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
