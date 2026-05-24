import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/hamvit_time_input.dart';

import '../../../theme/hamvit_colors.dart';
import 'food_preferences_controller.dart';
import 'food_preferences_widgets.dart';

class FoodPreferencesScreen extends ConsumerStatefulWidget {
  const FoodPreferencesScreen({super.key});

  @override
  ConsumerState<FoodPreferencesScreen> createState() =>
      _FoodPreferencesScreenState();
}

class _FoodPreferencesScreenState extends ConsumerState<FoodPreferencesScreen> {
  final _restrictionCtrl = TextEditingController();
  final _dislikedCtrl = TextEditingController();
  final _favoriteCtrl = TextEditingController();

  static const _eatingStyles = [
    'Caseiro',
    'EconÃ´mico',
    'RÃ¡pido',
    'Marmita',
    'Low carb',
    'Vegetariano',
    'Vegano',
    'FlexÃ­vel',
    'Alto em proteÃ­na',
    'Simples do dia a dia',
    'Sem frituras',
    'Pouco aÃ§Ãºcar',
  ];

  static const _restrictionOptions = [
    'Lactose',
    'GlÃºten',
    'Amendoim',
    'Frutos do mar',
    'Ovo',
    'Soja',
    'AÃ§Ãºcar',
    'Castanhas',
    'Leite',
    'Nenhuma restriÃ§Ã£o',
  ];

  static const _foodGoals = [
    'Emagrecer com saciedade',
    'Comer melhor',
    'Controlar calorias',
    'Aumentar proteÃ­na',
    'Reduzir aÃ§Ãºcar',
    'Melhorar rotina',
    'Reduzir ultraprocessados',
    'Ter praticidade',
  ];

  static const _usualMeals = [
    'CafÃ© da manhÃ£',
    'Lanche da manhÃ£',
    'AlmoÃ§o',
    'Lanche da tarde',
    'Jantar',
    'Ceia',
  ];

  static const _suggestionStyle = [
    'Mais econÃ´micas',
    'Mais rÃ¡pidas',
    'Mais variadas',
    'Mais simples',
    'Mais proteicas',
  ];

  @override
  void dispose() {
    _restrictionCtrl.dispose();
    _dislikedCtrl.dispose();
    _favoriteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(foodPreferencesControllerProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PreferÃªncias salvas com sucesso.')),
        );
        ref.read(foodPreferencesControllerProvider.notifier).resetSavedFlag();
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/home');
        }
      }

      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });

    final state = ref.watch(foodPreferencesControllerProvider);
    final controller = ref.read(foodPreferencesControllerProvider.notifier);
    final model = state.model;

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: HamvitColors.primaryDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sectionsFilled = [
      model.eatingStyles.isNotEmpty,
      model.restrictions.isNotEmpty,
      model.dislikedFoods.isNotEmpty,
      model.favoriteFoods.isNotEmpty,
      model.mealsPerDay != null ||
          model.cookingFrequency != null ||
          model.prepTimePreference != null ||
          model.lunchboxHabit != null,
      model.foodGoals.isNotEmpty,
      model.usualMeals.isNotEmpty,
      model.suggestionStyle.isNotEmpty,
    ].where((item) => item).length;

    return Scaffold(
      backgroundColor: HamvitColors.primaryDark,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: HamvitColors.darkText),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PreferÃªncias Alimentares',
                          style: TextStyle(
                              color: HamvitColors.darkText,
                              fontSize: 21,
                              fontWeight: FontWeight.w800),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Personalize sua alimentaÃ§Ã£o para sugestÃµes mais inteligentes.',
                          style: TextStyle(color: HamvitColors.darkTextMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                children: [
                  _buildValueCard(state.isPremium),
                  const SizedBox(height: 10),
                  HamvitFoodPreferencesSummary(sectionsFilled: sectionsFilled),
                  const SizedBox(height: 12),
                  HamvitPreferenceSection(
                    title: '1. Estilo alimentar',
                    subtitle: 'Selecione o que melhor descreve seu dia a dia.',
                    child: HamvitPreferenceChipGroup(
                      options: _eatingStyles,
                      selected: model.eatingStyles.toSet(),
                      onToggle: controller.toggleEatingStyle,
                    ),
                  ),
                  HamvitPreferenceSection(
                    title: '2. RestriÃ§Ãµes e alergias',
                    subtitle: 'Inclua restriÃ§Ãµes para sugestÃµes mais seguras.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HamvitPreferenceChipGroup(
                          options: _restrictionOptions,
                          selected: model.restrictions.toSet(),
                          onToggle: controller.toggleRestriction,
                        ),
                        const SizedBox(height: 10),
                        HamvitFoodSearchInput(
                          hintText: 'Adicionar restriÃ§Ã£o personalizada',
                          controller: _restrictionCtrl,
                          onAdd: () {
                            controller
                                .addCustomRestriction(_restrictionCtrl.text);
                            _restrictionCtrl.clear();
                          },
                        ),
                        if (model.restrictions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final item in model.restrictions)
                                InputChip(
                                  label: Text(item,
                                      style: const TextStyle(
                                          color: HamvitColors.darkText)),
                                  onDeleted: () =>
                                      controller.removeRestriction(item),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.06),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  HamvitPreferenceSection(
                    title: '3. Alimentos que nÃ£o gosta',
                    subtitle: 'Adicionar alimento que deseja evitar.',
                    child: Column(
                      children: [
                        HamvitFoodSearchInput(
                          hintText: 'Ex.: brÃ³colis, peixe, frango, ovo, leite',
                          controller: _dislikedCtrl,
                          onAdd: () {
                            controller.addDislikedFood(_dislikedCtrl.text);
                            _dislikedCtrl.clear();
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final item in model.dislikedFoods)
                                InputChip(
                                  label: Text(item,
                                      style: const TextStyle(
                                          color: HamvitColors.darkText)),
                                  onDeleted: () =>
                                      controller.removeDislikedFood(item),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.06),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  HamvitPreferenceSection(
                    title: '4. Alimentos favoritos',
                    subtitle: 'Adicionar alimento favorito.',
                    child: Column(
                      children: [
                        HamvitFoodSearchInput(
                          hintText: 'Ex.: arroz, feijÃ£o, frango, banana, aveia',
                          controller: _favoriteCtrl,
                          onAdd: () {
                            controller.addFavoriteFood(_favoriteCtrl.text);
                            _favoriteCtrl.clear();
                          },
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final item in model.favoriteFoods)
                                InputChip(
                                  label: Text(item,
                                      style: const TextStyle(
                                          color: HamvitColors.darkText)),
                                  onDeleted: () =>
                                      controller.removeFavoriteFood(item),
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.06),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  HamvitPreferenceSection(
                    title: '5. Rotina alimentar',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HamvitMealRoutineSelector(
                          title: 'Quantas refeiÃ§Ãµes costuma fazer por dia?',
                          options: const ['2', '3', '4', '5', '6+'],
                          selected: model.mealsPerDay == null
                              ? null
                              : (model.mealsPerDay! >= 6
                                  ? '6+'
                                  : '${model.mealsPerDay}'),
                          onSelected: (value) => controller.setMealsPerDay(
                              value == '6+' ? 6 : int.tryParse(value)),
                        ),
                        const SizedBox(height: 12),
                        HamvitMealRoutineSelector(
                          title: 'Costuma cozinhar?',
                          options: const ['Sim', 'Ã€s vezes', 'Quase nunca'],
                          selected: model.cookingFrequency,
                          onSelected: controller.setCookingFrequency,
                        ),
                        const SizedBox(height: 12),
                        HamvitMealRoutineSelector(
                          title: 'Tempo disponÃ­vel para preparar comida',
                          options: const [
                            'AtÃ© 10 min',
                            '15â€“30 min',
                            'Mais de 30 min'
                          ],
                          selected: model.prepTimePreference,
                          onSelected: controller.setPrepTimePreference,
                        ),
                        const SizedBox(height: 12),
                        HamvitMealRoutineSelector(
                          title: 'Costuma levar marmita?',
                          options: const ['Sim', 'NÃ£o', 'Ã€s vezes'],
                          selected: model.lunchboxHabit,
                          onSelected: controller.setLunchboxHabit,
                        ),
                      ],
                    ),
                  ),
                  HamvitPreferenceSection(
                    title: '6. Objetivo alimentar',
                    child: HamvitPreferenceChipGroup(
                      options: _foodGoals,
                      selected: model.foodGoals.toSet(),
                      onToggle: controller.toggleFoodGoal,
                    ),
                  ),
                  HamvitPreferenceSection(
                    title: '7. HorÃ¡rios / refeiÃ§Ãµes',
                    subtitle:
                        'Marque as refeiÃ§Ãµes que costuma fazer e, se quiser, o horÃ¡rio aproximado.',
                    child: Column(
                      children: [
                        HamvitPreferenceChipGroup(
                          options: _usualMeals,
                          selected: model.usualMeals.toSet(),
                          onToggle: controller.toggleUsualMeal,
                        ),
                        const SizedBox(height: 10),
                        for (final meal in model.usualMeals)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 140,
                                  child: Text(meal,
                                      style: const TextStyle(
                                          color: HamvitColors.darkTextMuted)),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    style: const TextStyle(
                                        color: HamvitColors.darkText),
                                    initialValue: model.mealTimes[meal] ?? '',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      HamvitTimeMaskFormatter(),
                                    ],
                                    maxLength: 5,
                                    buildCounter: (
                                      BuildContext context, {
                                      required int currentLength,
                                      required bool isFocused,
                                      required int? maxLength,
                                    }) {
                                      return const SizedBox.shrink();
                                    },
                                    decoration: const InputDecoration(
                                      hintText:
                                          'HorÃ¡rio aproximado (ex.: 07:30)',
                                      hintStyle: TextStyle(
                                          color: HamvitColors.darkTextMuted),
                                    ),
                                    onChanged: (value) =>
                                        controller.setMealTime(
                                      meal: meal,
                                      time: value,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  HamvitPreferenceSection(
                    title: '8. OrÃ§amento / praticidade',
                    subtitle: 'Como prefere suas sugestÃµes?',
                    child: HamvitPreferenceChipGroup(
                      options: _suggestionStyle,
                      selected: model.suggestionStyle.toSet(),
                      onToggle: controller.toggleSuggestionStyle,
                    ),
                  ),
                  HamvitPremiumFoodSuggestionsCard(
                    isPremium: state.isPremium,
                    onKnowPremium: () => context.go('/premium'),
                    onContinueFree: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('PreferÃªncias serÃ£o salvas no plano Free.')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          color: HamvitColors.primaryDark,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: state.isSaving
                      ? null
                      : () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home');
                          }
                        },
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: state.isSaving ? null : controller.save,
                  child: Text(
                      state.isSaving ? 'Salvando...' : 'Salvar preferÃªncias'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueCard(bool isPremium) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF0E304F), Color(0xFF124661)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suas escolhas ajudam o HAMVIT a sugerir melhor.',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Com essas informaÃ§Ãµes, o app entende sua rotina, preferÃªncias e restriÃ§Ãµes para montar sugestÃµes mais prÃ³ximas do seu dia a dia.',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isPremium
                    ? HamvitColors.accentMint.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isPremium
                    ? 'SugestÃµes personalizadas ativas.'
                    : 'Premium desbloqueia sugestÃµes inteligentes.',
                style: TextStyle(
                  color: isPremium ? HamvitColors.accentMint : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

