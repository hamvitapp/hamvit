import 'package:flutter/material.dart';

import '../../../theme/hamvit_colors.dart';

class HamvitPreferenceSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const HamvitPreferenceSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: HamvitColors.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                color: HamvitColors.darkText,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(color: HamvitColors.darkTextMuted),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class HamvitPreferenceChipGroup extends StatelessWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const HamvitPreferenceChipGroup({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          FilterChip(
            selected: selected.contains(option),
            selectedColor: HamvitColors.accentCyan.withValues(alpha: 0.22),
            checkmarkColor: HamvitColors.accentMint,
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            label: Text(option,
                style: const TextStyle(color: HamvitColors.darkText)),
            onSelected: (_) => onToggle(option),
          ),
      ],
    );
  }
}

class HamvitFoodSearchInput extends StatelessWidget {
  final String hintText;
  final TextEditingController controller;
  final VoidCallback onAdd;

  const HamvitFoodSearchInput({
    super.key,
    required this.hintText,
    required this.controller,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: HamvitColors.darkText),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(color: HamvitColors.darkTextMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: HamvitColors.accentCyan),
              ),
            ),
            onSubmitted: (_) => onAdd(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 132,
          child: FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text(
              'Adicionar',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
      ],
    );
  }
}

class HamvitMealRoutineSelector extends StatelessWidget {
  final String title;
  final List<String> options;
  final String? selected;
  final ValueChanged<String> onSelected;

  const HamvitMealRoutineSelector({
    super.key,
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: HamvitColors.darkText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              ChoiceChip(
                selected: selected == option,
                selectedColor: HamvitColors.accentMint.withValues(alpha: 0.22),
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                label: Text(option,
                    style: const TextStyle(color: HamvitColors.darkText)),
                onSelected: (_) => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}

class HamvitFoodPreferencesSummary extends StatelessWidget {
  final int sectionsFilled;
  final int totalSections;

  const HamvitFoodPreferencesSummary({
    super.key,
    required this.sectionsFilled,
    this.totalSections = 8,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSections == 0
        ? 0.0
        : (sectionsFilled / totalSections).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F3150), Color(0xFF125261)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$sectionsFilled de $totalSections seções preenchidas',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.16),
              valueColor: const AlwaysStoppedAnimation(HamvitColors.accentMint),
            ),
          ),
        ],
      ),
    );
  }
}

class HamvitPremiumFoodSuggestionsCard extends StatelessWidget {
  final bool isPremium;
  final VoidCallback? onKnowPremium;
  final VoidCallback? onContinueFree;

  const HamvitPremiumFoodSuggestionsCard({
    super.key,
    required this.isPremium,
    this.onKnowPremium,
    this.onContinueFree,
  });

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: HamvitColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: HamvitColors.accentMint.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Icon(Icons.auto_awesome, color: HamvitColors.accentMint),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Suas sugest�es inteligentes usar�o estas prefer�ncias.',
                style: TextStyle(
                    color: HamvitColors.darkText, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF173B57), Color(0xFF1A4C6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desbloqueie sugest�es inteligentes.',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Com o Premium Vital�cio, o HAMVIT usa suas prefer�ncias para sugerir receitas, montar refei��es do dia e ajudar voc� a bater suas metas com mais facilidade.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text('� Receitas saud�veis sugeridas',
              style: TextStyle(color: Colors.white70)),
          const Text('� Montagem autom�tica do dia',
              style: TextStyle(color: Colors.white70)),
          const Text('� Substitui��es inteligentes',
              style: TextStyle(color: Colors.white70)),
          const Text('� Relat�rios avan�ados',
              style: TextStyle(color: Colors.white70)),
          const Text('� Sem an�ncios', style: TextStyle(color: Colors.white70)),
          const Text('� Sem mensalidade',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onKnowPremium,
                  child: const Text('Conhecer Premium'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onContinueFree,
                  child: const Text('Continuar no Free'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
