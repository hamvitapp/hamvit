import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/premium/premium_access_matrix.dart';
import '../../../core/premium/premium_widgets.dart';
import '../../../theme/hamvit_colors.dart';
import '../models/recipe.dart';
import '../recipe_provider.dart';
import '../recipe_repository.dart';
import 'recipe_details_screen.dart';

class PremiumSuggestionsScreen extends ConsumerWidget {
  final bool isPremium;

  const PremiumSuggestionsScreen({super.key, required this.isPremium});

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
      child: _PremiumSuggestionsBody(isPremium: isPremium),
    );
  }
}

class _PremiumSuggestionsBody extends ConsumerStatefulWidget {
  final bool isPremium;
  const _PremiumSuggestionsBody({required this.isPremium});

  @override
  ConsumerState<_PremiumSuggestionsBody> createState() => _PremiumSuggestionsBodyState();
}

class _PremiumSuggestionsBodyState extends ConsumerState<_PremiumSuggestionsBody> {
  String? _selectedMealType;

  final _mealTypeOptions = <String, String>{
    'cafe_da_manha': 'Café da manhã',
    'almoco': 'Almoço',
    'jantar': 'Jantar',
    'lanche': 'Lanche',
    'ceia': 'Ceia',
  };

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
                  'Sugestões Inteligentes',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                SizedBox(height: 4),
                Text(
                  'Recomendações personalizadas com base nas suas metas, preferências e refeições do dia.',
                  style: TextStyle(color: HamvitColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── Filtro por tipo de refeição ──
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _mealTypeChip(null, 'Todas'),
              ..._mealTypeOptions.entries.map((e) => _mealTypeChip(e.key, e.value)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Macros do dia (placeholder - ao registrar, Home/Dashboard atualiza) ──
        _buildDailySummary(),
        const SizedBox(height: 20),

        // ── Sugestões ──
        const Text(
          'Recomendações para você',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),

        suggestionsAsync.when(
          data: (recipes) {
            if (recipes.isEmpty) {
              return _buildEmptyState();
            }
            return Column(
              children: recipes.map((recipe) => _buildSuggestionCard(recipe)).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: LinearProgressIndicator(),
          ),
          error: (err, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Erro ao carregar sugestões: $err'),
            ),
          ),
        ),

        const SizedBox(height: 28),

        // ── Favoritos ──
        const Text(
          'Suas receitas favoritas',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),

        favoritesAsync.when(
          data: (favorites) {
            if (favorites.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Nenhuma receita favoritada ainda.',
                  style: TextStyle(color: HamvitColors.textSecondary),
                ),
              );
            }
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _buildFavoriteCard(favorites[index]),
              ),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 28),

        // ── Histórico recente ──
        const Text(
          'Histórico de refeições',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        const SizedBox(height: 12),

        historyAsync.when(
          data: (meals) {
            if (meals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Nenhuma refeição registrada nos últimos dias.',
                  style: TextStyle(color: HamvitColors.textSecondary),
                ),
              );
            }
            return Column(
              children: meals.take(10).map((meal) => _buildHistoryTile(meal)).toList(),
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _mealTypeChip(String? value, String label) {
    final selected = _selectedMealType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedMealType = value),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        selectedColor: HamvitColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: selected ? Colors.white : HamvitColors.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildDailySummary() {
    return Card(
      elevation: 0,
      color: HamvitColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up_rounded, size: 18, color: HamvitColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Com base no seu dia',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: HamvitColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'As sugestões consideram suas metas, calorias restantes e preferências alimentares.',
              style: TextStyle(fontSize: 12, color: HamvitColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Recipe recipe) {
    final calories = recipe.caloriesKcal?.round() ?? 0;
    final protein = recipe.proteinG?.round() ?? 0;
    final carbs = recipe.carbsG?.round() ?? 0;
    final fat = recipe.fatG?.round() ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: HamvitColors.lineSoft.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openRecipeDetails(recipe.id),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row superior: nome + favorito
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Placeholder visual
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(recipe.category),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getCategoryIcon(recipe.category),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          if (recipe.matchReason != null && recipe.matchReason!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                recipe.matchReason!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: HamvitColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (recipe.premiumOnly)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HamvitColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: HamvitColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Tags
                if (recipe.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: recipe.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: HamvitColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 10,
                            color: HamvitColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                ],

                // Macros
                Row(
                  children: [
                    _macroChip('$calories kcal', HamvitColors.primary),
                    const SizedBox(width: 6),
                    _macroChip('P $protein g', HamvitColors.proteinColor),
                    const SizedBox(width: 6),
                    _macroChip('C $carbs g', HamvitColors.carbsColor),
                    const SizedBox(width: 6),
                    _macroChip('G $fat g', HamvitColors.fatColor),
                  ],
                ),
                const SizedBox(height: 10),

                // Tempo de preparo + dificuldade
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: HamvitColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${recipe.prepTimeMinutes ?? 0} min',
                      style: TextStyle(fontSize: 12, color: HamvitColors.textSecondary),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.speed_rounded, size: 14, color: HamvitColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      _getDifficultyLabel(recipe.difficulty),
                      style: TextStyle(fontSize: 12, color: HamvitColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Botões de ação (diferente dos secundários)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _openRecipeDetails(recipe.id),
                        icon: const Icon(Icons.add_circle_rounded, size: 18),
                        label: const Text('Ver receita'),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _rejectRecipe(recipe.id),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Não'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Widget _macroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Recipe recipe) {
    return SizedBox(
      width: 200,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: HamvitColors.lineSoft.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openRecipeDetails(recipe.id),
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
                        color: _getCategoryColor(recipe.category),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getCategoryIcon(recipe.category), color: Colors.white, size: 18),
                    ),
                    const Spacer(),
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  recipe.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${recipe.caloriesKcal?.round() ?? 0} kcal',
                  style: TextStyle(fontSize: 11, color: HamvitColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> meal) {
    final mealType = meal['meal_type']?.toString() ?? '';
    final recipeName = meal['recipe_name']?.toString() ?? 'Refeição manual';
    final calories = (meal['total_calories_kcal'] as num?)?.toInt() ?? 0;
    final protein = (meal['total_protein_g'] as num?)?.toInt() ?? 0;
    final consumedAt = meal['consumed_at']?.toString() ?? '';
    final dateStr = consumedAt.length >= 16
        ? consumedAt.substring(8, 10) + '/' + consumedAt.substring(5, 7) + ' ' + consumedAt.substring(11, 16)
        : '';

    return Card(
      elevation: 0,
      color: HamvitColors.surfaceVariant,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        dense: true,
        leading: Icon(_mealTypeIcon(mealType), size: 20, color: HamvitColors.primary),
        title: Text(recipeName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(
          '$dateStr • ${_mealTypeLabel(mealType)}',
          style: TextStyle(fontSize: 11, color: HamvitColors.textSecondary),
        ),
        trailing: Text(
          '$calories kcal • $protein g prot',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: HamvitColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 48, color: HamvitColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'Complete seu perfil alimentar para receber sugestões mais inteligentes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: HamvitColors.textSecondary),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pushNamed('/nutrition/preferences'),
              child: const Text('Configurar preferências'),
            ),
          ],
        ),
      ),
    );
  }

  void _openRecipeDetails(String recipeId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailsScreen(
          recipeId: recipeId,
          isPremium: widget.isPremium,
        ),
      ),
    );
  }

  Future<void> _rejectRecipe(String recipeId) async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      await repo.rejectRecipe(recipeId, reason: 'user_rejected');
      ref.invalidate(smartRecommendationsProvider(_selectedMealType));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receita removida das sugestões.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {}
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'cafe_da_manha': return const Color(0xFFFF9A76);
      case 'almoco': return const Color(0xFF6BCB77);
      case 'jantar': return const Color(0xFF4D96FF);
      case 'lanche': return const Color(0xFFFFD93D);
      case 'ceia': return const Color(0xFF6C63FF);
      default: return HamvitColors.primary;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'cafe_da_manha': return Icons.wb_sunny_rounded;
      case 'almoco': return Icons.restaurant_rounded;
      case 'jantar': return Icons.nightlight_round;
      case 'lanche': return Icons.cookie_rounded;
      case 'ceia': return Icons.bedtime_rounded;
      default: return Icons.restaurant_menu_rounded;
    }
  }

  IconData _mealTypeIcon(String type) {
    switch (type) {
      case 'cafe_da_manha': return Icons.wb_sunny_rounded;
      case 'almoco': return Icons.restaurant_rounded;
      case 'jantar': return Icons.nightlight_round;
      case 'lanche': return Icons.cookie_rounded;
      case 'ceia': return Icons.bedtime_rounded;
      default: return Icons.restaurant_menu_rounded;
    }
  }

  String _mealTypeLabel(String type) {
    switch (type) {
      case 'cafe_da_manha': return 'Café da manhã';
      case 'almoco': return 'Almoço';
      case 'jantar': return 'Jantar';
      case 'lanche': return 'Lanche';
      case 'ceia': return 'Ceia';
      default: return type;
    }
  }

  String _getDifficultyLabel(String? difficulty) {
    switch (difficulty) {
      case 'facil': return 'Fácil';
      case 'medio': return 'Médio';
      case 'dificil': return 'Difícil';
      default: return '—';
    }
  }
}