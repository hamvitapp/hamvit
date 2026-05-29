import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/premium/premium_access_matrix.dart';
import '../../../core/premium/premium_widgets.dart';
import '../../../theme/hamvit_colors.dart';
import '../models/recipe.dart';
import '../recipe_provider.dart';
import '../recipe_repository.dart';
import 'recipe_details_screen.dart';

/// Legacy-compatible screen that replaces MealRecommendationsPage
/// Now powered by real smart recommendations engine
class RecipeSuggestionsScreen extends ConsumerWidget {
  final bool isPremium;

  const RecipeSuggestionsScreen({super.key, required this.isPremium});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumFeatureGate(
      feature: HamvitFeature.nutritionSmartRecommendations,
      isPremium: isPremium,
      fallback: Padding(
        padding: const EdgeInsets.all(16),
        child: PremiumTeaserCard(
          feature: HamvitFeature.nutritionSmartRecommendations,
          onTap: () => Navigator.of(context).pushNamed('/premium'),
        ),
      ),
      child: _RecipeSuggestionsBody(isPremium: isPremium),
    );
  }
}

class _RecipeSuggestionsBody extends ConsumerStatefulWidget {
  final bool isPremium;
  const _RecipeSuggestionsBody({required this.isPremium});

  @override
  ConsumerState<_RecipeSuggestionsBody> createState() => _RecipeSuggestionsBodyState();
}

class _RecipeSuggestionsBodyState extends ConsumerState<_RecipeSuggestionsBody> {
  String? _selectedMealType;

  @override
  Widget build(BuildContext context) {
    final suggestionsAsync = ref.watch(smartRecommendationsProvider(_selectedMealType));
    final favoritesAsync = ref.watch(favoriteRecipesProvider);
    final historyAsync = ref.watch(mealHistoryProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Header ──
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sugestões Premium',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                SizedBox(height: 4),
                Text(
                  'Com base nas suas metas e preferências.',
                  style: TextStyle(color: HamvitColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Filtro ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip(null, 'Todas'),
              _filterChip('cafe_da_manha', 'Café'),
              _filterChip('almoco', 'Almoço'),
              _filterChip('jantar', 'Jantar'),
              _filterChip('lanche', 'Lanche'),
              _filterChip('ceia', 'Ceia'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Sugestões ──
        const Text(
          'Sugestões inteligentes',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),

        suggestionsAsync.when(
          data: (recipes) {
            if (recipes.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, size: 40,
                          color: HamvitColors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      const Text(
                        'Complete seu perfil alimentar para receber sugestões mais inteligentes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: HamvitColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: recipes.map((r) => _suggestionCard(r)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erro: $err'),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Favoritos ──
        const Text(
          'Favoritos',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),
        favoritesAsync.when(
          data: (favs) {
            if (favs.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _favCard(favs[i]),
              ),
            );
          },
          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 24),

        // ── Histórico ──
        const Text(
          'Últimas refeições',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          data: (meals) {
            if (meals.isEmpty) {
              return Text(
                'Nenhuma refeição registrada.',
                style: TextStyle(color: HamvitColors.textSecondary),
              );
            }
            return Column(
              children: meals.take(5).map((m) => _historyTile(m)).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _filterChip(String? value, String label) {
    final selected = _selectedMealType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        onSelected: (_) => setState(() => _selectedMealType = value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        selectedColor: HamvitColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : null,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _suggestionCard(Recipe recipe) {
    final cals = recipe.caloriesKcal?.round() ?? 0;
    final prot = recipe.proteinG?.round() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: HamvitColors.lineSoft.withValues(alpha: 0.4)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetails(recipe.id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                    if (recipe.premiumOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HamvitColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Premium', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: HamvitColors.warning)),
                      ),
                  ],
                ),
                if (recipe.matchReason != null && recipe.matchReason!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(recipe.matchReason!, style: TextStyle(fontSize: 11, color: HamvitColors.primary)),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip('$cals kcal'),
                    const SizedBox(width: 6),
                    _chip('P $prot g'),
                    const SizedBox(width: 6),
                    _chip('${recipe.prepTimeMinutes ?? 0} min'),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openDetails(recipe.id),
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text('Ver receita', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () => _rejectRecipe(recipe.id),
                      child: const Icon(Icons.close_rounded, size: 16),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(8)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: HamvitColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: HamvitColors.textSecondary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _favCard(Recipe recipe) {
    return SizedBox(
      width: 160,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _openDetails(recipe.id),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.favorite, size: 16, color: Colors.red),
                const SizedBox(height: 6),
                Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                Text('${recipe.caloriesKcal?.round() ?? 0} kcal', style: TextStyle(fontSize: 10, color: HamvitColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> meal) {
    return Card(
      elevation: 0,
      color: HamvitColors.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Text(meal['recipe_name']?.toString() ?? (meal['meal_type']?.toString() ?? ''), style: const TextStyle(fontSize: 12)),
        trailing: Text('${(meal['total_calories_kcal'] as num?)?.toInt() ?? 0} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _openDetails(String id) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => RecipeDetailsScreen(recipeId: id, isPremium: widget.isPremium),
    ));
  }

  Future<void> _rejectRecipe(String recipeId) async {
    try {
      await ref.read(recipeRepositoryProvider).rejectRecipe(recipeId);
      ref.invalidate(smartRecommendationsProvider(_selectedMealType));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removido das sugestões.'), behavior: SnackBarBehavior.floating));
      }
    } catch (_) {}
  }
}