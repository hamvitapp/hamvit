import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/hamvit_back_app_bar.dart';
import '../../../theme/hamvit_colors.dart';
import '../../../theme/hamvit_theme.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/recipe_step.dart';
import '../recipe_provider.dart';
import '../recipe_repository.dart';

class RecipeDetailsScreen extends ConsumerStatefulWidget {
  final String recipeId;
  final bool isPremium;
  final Recipe? initialRecipe;

  const RecipeDetailsScreen({
    super.key,
    required this.recipeId,
    required this.isPremium,
    this.initialRecipe,
  });

  @override
  ConsumerState<RecipeDetailsScreen> createState() => _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState extends ConsumerState<RecipeDetailsScreen> {
  double _servings = 1.0;
  bool _isFavorite = false;
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeByIdProvider(widget.recipeId));
    final ingredientsAsync = ref.watch(recipeIngredientsProvider(widget.recipeId));
    final stepsAsync = ref.watch(recipeStepsProvider(widget.recipeId));
    final tagsAsync = ref.watch(recipeTagsProvider(widget.recipeId));

    return Scaffold(
      body: recipeAsync.when(
        loading: () => const Scaffold(
          appBar: _RecipeAppBar(title: 'Carregando...'),
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          appBar: _RecipeAppBar(title: 'Erro'),
          body: Center(child: Text('Erro ao carregar receita: $err')),
        ),
        data: (recipe) {
          if (recipe == null) {
            return const Scaffold(
              appBar: _RecipeAppBar(title: 'Receita não encontrada'),
              body: Center(child: Text('Receita não encontrada.')),
            );
          }

          return Scaffold(
            body: CustomScrollView(
              slivers: [
                // ── Header com imagem ──
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: HamvitColors.surface,
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildRecipeHeader(recipe),
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_outline,
                        color: _isFavorite ? Colors.red : Colors.white70,
                      ),
                      onPressed: () => _toggleFavorite(recipe.id),
                    ),
                  ],
                ),

                // ── Corpo ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // Nome e descrição
                        Text(
                          recipe.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        if (recipe.description != null && recipe.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            recipe.description!,
                            style: TextStyle(
                              fontSize: 15,
                              color: HamvitColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        // Chips de categoria, tempo, dificuldade
                        _buildInfoChips(recipe),

                        const SizedBox(height: 16),

                        // Tags
                        tagsAsync.when(
                          data: (tags) => tags.isNotEmpty
                              ? _buildTagsRow(tags)
                              : const SizedBox.shrink(),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 20),

                        // ── Macros e barra visual ──
                        _buildMacroSection(recipe),
                        const SizedBox(height: 8),
                        _buildMacroBar(recipe),

                        const SizedBox(height: 24),

                        // ── Ajuste de porção ──
                        _buildServingAdjuster(),

                        const SizedBox(height: 24),

                        // ── Botão principal: Registrar refeição ──
                        _buildRegisterButton(recipe),

                        const SizedBox(height: 24),

                        // ── Ingredientes ──
                        _buildSectionTitle('Ingredientes'),
                        const SizedBox(height: 12),
                        ingredientsAsync.when(
                          data: (ingredients) => ingredients.isNotEmpty
                              ? _buildIngredientsList(ingredients)
                              : const Text('Ingredientes não disponíveis.'),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Erro ao carregar ingredientes.'),
                        ),

                        const SizedBox(height: 24),

                        // ── Modo de preparo ──
                        _buildSectionTitle('Modo de preparo'),
                        const SizedBox(height: 12),
                        stepsAsync.when(
                          data: (steps) => steps.isNotEmpty
                              ? _buildStepsList(steps)
                              : const Text('Instruções não disponíveis.'),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, __) => const Text('Erro ao carregar instruções.'),
                        ),

                        const SizedBox(height: 32),

                        // ── Botões secundários ──
                        _buildSecondaryActions(recipe),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Header com gradiente placeholder ──
  Widget _buildRecipeHeader(Recipe recipe) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCategoryColor(recipe.category).withValues(alpha: 0.8),
            _getCategoryColor(recipe.category).withValues(alpha: 0.4),
            HamvitColors.surface,
          ],
        ),
      ),
      alignment: Alignment.bottomLeft,
      padding: const EdgeInsets.only(left: 20, bottom: 16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getCategoryIcon(recipe.category),
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getCategoryLabel(recipe.category),
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${recipe.prepTimeMinutes ?? 0} min • ${recipe.difficulty ?? 'facil'}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Info chips ──
  Widget _buildInfoChips(Recipe recipe) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(Icons.access_time_rounded, '${recipe.prepTimeMinutes ?? 0} min'),
        _chip(Icons.restaurant_rounded, '${recipe.servings ?? 1} porçõe${(recipe.servings ?? 1) > 1 ? 's' : 's'}'),
        _chip(
          Icons.local_fire_department_rounded,
          '${recipe.caloriesKcal?.round() ?? 0} kcal',
        ),
        _chip(
          Icons.fitness_center_rounded,
          '${recipe.proteinG?.round() ?? 0}g prot',
        ),
        if (recipe.difficulty != null)
          _chip(Icons.speed_rounded, _getDifficultyLabel(recipe.difficulty!)),
      ],
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: HamvitColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: HamvitColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: HamvitColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Tags row ──
  Widget _buildTagsRow(List<String> tags) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: tags.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: HamvitColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HamvitColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: HamvitColors.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Macros ──
  Widget _buildMacroSection(Recipe recipe) {
    final calories = (recipe.caloriesKcal ?? 0) * _servings;
    final protein = (recipe.proteinG ?? 0) * _servings;
    final carbs = (recipe.carbsG ?? 0) * _servings;
    final fat = (recipe.fatG ?? 0) * _servings;

    return Card(
      elevation: 0,
      color: HamvitColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Informação nutricional',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                Text(
                  '${calories.round()} kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: HamvitColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _macroItem('Proteínas', '${protein.round()}g', HamvitColors.proteinColor),
                const SizedBox(width: 8),
                _macroItem('Carboidratos', '${carbs.round()}g', HamvitColors.carbsColor),
                const SizedBox(width: 8),
                _macroItem('Gorduras', '${fat.round()}g', HamvitColors.fatColor),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: HamvitColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barra visual de macros ──
  Widget _buildMacroBar(Recipe recipe) {
    final protein = (recipe.proteinG ?? 0) * _servings;
    final carbs = (recipe.carbsG ?? 0) * _servings;
    final fat = (recipe.fatG ?? 0) * _servings;
    final total = protein + carbs + fat;
    if (total <= 0) return const SizedBox.shrink();

    final pPct = (protein / total * 100).clamp(5, 100);
    final cPct = (carbs / total * 100).clamp(5, 100);
    final fPct = (fat / total * 100).clamp(5, 100);
    final remaining = (pPct + cPct + fPct);
    final adjust = remaining > 100 ? 100 / remaining : 1.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Flexible(
              flex: (pPct * adjust).round(),
              child: Container(color: HamvitColors.proteinColor),
            ),
            Flexible(
              flex: (cPct * adjust).round(),
              child: Container(color: HamvitColors.carbsColor),
            ),
            Flexible(
              flex: (fPct * adjust).round(),
              child: Container(color: HamvitColors.fatColor),
            ),
          ],
        ),
      ),
    );
  }

  // ── Ajuste de porção ──
  Widget _buildServingAdjuster() {
    return Card(
      elevation: 0,
      color: HamvitColors.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.scale_rounded, size: 20, color: HamvitColors.primary),
            const SizedBox(width: 8),
            const Text(
              'Porções',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const Spacer(),
            _servingButton(Icons.remove_circle_outline, () {
              if (_servings > 0.5) setState(() => _servings -= 0.5);
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _servings == 0.5
                    ? '½'
                    : _servings == _servings.roundToDouble()
                        ? '${_servings.round()}'
                        : _servings.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
            _servingButton(Icons.add_circle_outline, () {
              if (_servings < 4.0) setState(() => _servings += 0.5);
            }),
          ],
        ),
      ),
    );
  }

  Widget _servingButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 28,
      color: HamvitColors.primary,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
    );
  }

  // ── Botão registrar refeição ──
  Widget _buildRegisterButton(Recipe recipe) {
    final calories = (recipe.caloriesKcal ?? 0) * _servings;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _isRegistering ? null : () => _confirmRegistration(recipe),
        icon: _isRegistering
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_circle_rounded),
        label: Text(
          'Registrar refeição • ${calories.round()} kcal',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  // ── Confirmação de consumo ──
  Future<void> _confirmRegistration(Recipe recipe) async {
    final calories = (recipe.caloriesKcal ?? 0) * _servings;
    final protein = (recipe.proteinG ?? 0) * _servings;
    final carbs = (recipe.carbsG ?? 0) * _servings;
    final fat = (recipe.fatG ?? 0) * _servings;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Você consumiu esta refeição?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(recipe.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _confirmMacro('Calorias', '${calories.round()}', 'kcal'),
                const SizedBox(width: 12),
                _confirmMacro('Proteína', '${protein.round()}', 'g'),
                const SizedBox(width: 12),
                _confirmMacro('Carbo', '${carbs.round()}', 'g'),
                const SizedBox(width: 12),
                _confirmMacro('Gordura', '${fat.round()}', 'g'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_servings == 0.5 ? '½' : _servings.round()} porção${_servings > 1 ? 'ões' : ''}',
              style: TextStyle(color: HamvitColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Registrar refeição'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _registerMeal(recipe);
    }
  }

  Future<void> _registerMeal(Recipe recipe) async {
    setState(() => _isRegistering = true);
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final mealType = recipe.category ?? 'lanche';

      await repo.registerConsumption(
        recipeId: recipe.id,
        mealType: mealType,
        servings: _servings,
      );

      if (!mounted) return;

      // Invalidate providers to refresh dashboard, home, etc.
      ref.invalidate(recipeByIdProvider(widget.recipeId));
      ref.invalidate(smartRecommendationsProvider(null));
      ref.invalidate(mealHistoryProvider);
      ref.invalidate(allRecipesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${recipe.name} registrada com sucesso!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao registrar: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  Widget _confirmMacro(String label, String value, String unit) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        Text(label, style: TextStyle(fontSize: 10, color: HamvitColors.textSecondary)),
      ],
    );
  }

  // ── Ingredientes ──
  Widget _buildIngredientsList(List<RecipeIngredient> ingredients) {
    return Column(
      children: ingredients.map((ing) {
        final qty = ing.quantity ?? 0;
        final displayQty = qty * _servings;
        final qtyStr = (displayQty == displayQty.roundToDouble())
            ? '${displayQty.round()}'
            : displayQty.toStringAsFixed(1);
        final label = ing.portionLabel ?? '';
        final desc = [if (qty > 0) qtyStr, if (label.isNotEmpty) label]
            .join(' ');

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: HamvitColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ing.ingredientText ?? 'Ingrediente',
                  style: const TextStyle(fontSize: 14, height: 1.3),
                ),
              ),
              if (desc.isNotEmpty)
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: HamvitColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Passos ──
  Widget _buildStepsList(List<RecipeStep> steps) {
    return Column(
      children: steps.map((step) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: HamvitColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${step.stepOrder}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  step.instruction,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: HamvitColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Ações secundárias ──
  Widget _buildSecondaryActions(Recipe recipe) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _toggleFavorite(recipe.id),
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_outline,
              size: 18,
              color: _isFavorite ? Colors.red : null,
            ),
            label: Text(_isFavorite ? 'Favoritado' : 'Favoritar'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _rejectRecipe(recipe.id),
            icon: const Icon(Icons.thumb_down_outlined, size: 18),
            label: const Text('Não gostei'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _replaceRecipe(recipe),
            icon: const Icon(Icons.swap_horiz_rounded, size: 18),
            label: const Text('Trocar'),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Ações ──
  Future<void> _toggleFavorite(String recipeId) async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final isFav = await repo.toggleFavorite(recipeId);
      setState(() => _isFavorite = isFav);
      ref.invalidate(favoriteRecipesProvider);
    } catch (_) {}
  }

  Future<void> _rejectRecipe(String recipeId) async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      await repo.rejectRecipe(recipeId, reason: 'user_rejected');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Receita removida das sugestões.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (_) {}
  }

  Future<void> _replaceRecipe(Recipe recipe) async {
    try {
      final repo = ref.read(recipeRepositoryProvider);
      final suggestions = await repo.getSmartRecommendations(
        mealType: recipe.category,
        limit: 3,
      );

      if (!mounted || suggestions.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nenhuma alternativa disponível no momento.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final selected = await showDialog<Recipe>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Escolha uma alternativa'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          children: suggestions.map((s) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s),
              child: ListTile(
                dense: true,
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${s.caloriesKcal?.round() ?? 0} kcal • ${s.proteinG?.round() ?? 0}g prot'),
              ),
            );
          }).toList(),
        ),
      );

      if (selected != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(
              recipeId: selected.id,
              isPremium: widget.isPremium,
            ),
          ),
        );
      }
    } catch (_) {}
  }

  // ── Section title ──
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
    );
  }

  // ── Helpers ──
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'cafe_da_manha':
        return const Color(0xFFFF9A76);
      case 'almoco':
        return const Color(0xFF6BCB77);
      case 'jantar':
        return const Color(0xFF4D96FF);
      case 'lanche':
        return const Color(0xFFFFD93D);
      case 'ceia':
        return const Color(0xFF6C63FF);
      default:
        return HamvitColors.primary;
    }
  }

  IconData _getCategoryIcon(String? category) {
    switch (category) {
      case 'cafe_da_manha':
        return Icons.wb_sunny_rounded;
      case 'almoco':
        return Icons.restaurant_rounded;
      case 'jantar':
        return Icons.nightlight_round;
      case 'lanche':
        return Icons.cookie_rounded;
      case 'ceia':
        return Icons.bedtime_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }

  String _getCategoryLabel(String? category) {
    switch (category) {
      case 'cafe_da_manha':
        return 'Café da manhã';
      case 'almoco':
        return 'Almoço';
      case 'jantar':
        return 'Jantar';
      case 'lanche':
        return 'Lanche';
      case 'ceia':
        return 'Ceia';
      default:
        return 'Refeição';
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'facil':
        return 'Fácil';
      case 'medio':
        return 'Médio';
      case 'dificil':
        return 'Difícil';
      default:
        return difficulty;
    }
  }
}

class _RecipeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _RecipeAppBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}