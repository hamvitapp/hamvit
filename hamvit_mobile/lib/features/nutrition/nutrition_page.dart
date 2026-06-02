import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';
import '../../features/onboarding/providers/onboarding_profile_provider.dart';
import '../privacy/app_blur_overlay.dart';
import '../dashboard/domain/dashboard_metrics_service.dart';
import '../home/providers/home_dashboard_provider.dart';
import '../../shared/widgets/hamvit_module_widgets.dart';
import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import 'nutrition_service.dart';
import 'manual_meal_entry_screen.dart';
import 'recipe_provider.dart';
import 'recipe_repository.dart';
import 'screens/recipe_suggestions_screen.dart';
import 'screens/recipe_details_screen.dart';

class NutritionPage extends ConsumerStatefulWidget {
  final bool isPremium;
  const NutritionPage({super.key, required this.isPremium});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage> {
  final barcodeCtrl = TextEditingController();
  final _picker = ImagePicker();

  Map<String, dynamic>? barcodeResult;
  Map<String, dynamic>? photoAnalysis;
  bool isAnalyzingPhoto = false;
  bool _loadingMeals = false;
  List<Map<String, dynamic>> _todayMeals = const [];
  int _totalProtein = 0;
  int _totalCarbs = 0;
  int _totalFat = 0;
  int _optimisticCalories = 0;

  static const _mealTypeOptions = <Map<String, String>>[
    {'value': 'cafe_da_manha', 'label': 'Café da manhã'},
    {'value': 'lanche_manha', 'label': 'Lanche da manhã'},
    {'value': 'almoco', 'label': 'Almoço'},
    {'value': 'lanche_tarde', 'label': 'Lanche da tarde'},
    {'value': 'jantar', 'label': 'Jantar'},
    {'value': 'ceia', 'label': 'Ceia'},
    {'value': 'lanche', 'label': 'Lanche'},
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadTodayMeals);
  }

  @override
  void dispose() {
    barcodeCtrl.dispose();
    super.dispose();
  }

  String _mealTypeLabel(String value) {
    for (final item in _mealTypeOptions) {
      if (item['value'] == value) return item['label']!;
    }
    return value;
  }

  Future<void> _loadTodayMeals() async {
    final service = ref.read(nutritionServiceProvider);
    setState(() => _loadingMeals = true);
    try {
      final meals = await service.fetchTodayMeals();
      if (!mounted) return;
      int totalProt = 0, totalCarb = 0, totalF = 0;
      for (final m in meals) {
        totalProt += (m['protein_g'] as num?)?.toInt() ?? 0;
        totalCarb += (m['carbs_g'] as num?)?.toInt() ?? 0;
        totalF += (m['fat_g'] as num?)?.toInt() ?? 0;
      }
      setState(() {
        _todayMeals = meals;
        _totalProtein = totalProt;
        _totalCarbs = totalCarb;
        _totalFat = totalF;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao carregar refeições: $error')),
      );
    } finally {
      if (mounted) setState(() => _loadingMeals = false);
    }
  }

  Future<void> _registerMealQuickly() async {
    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        child: ManualMealEntryScreen(
          service: ref.read(nutritionServiceProvider),
        ),
      ),
    );

    if (payload == null) return;
    final calories = (payload['calories'] as num?)?.round() ?? 0;
    ref.read(homeDashboardActionsProvider).reflectMealCaloriesLocally(calories);
    ref.invalidate(homeDashboardProvider);
    ref.invalidate(dashboardSnapshotProvider);
    await _loadTodayMeals();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refeição registrada com sucesso.')),
    );
  }

  Widget _mealTile(String title, String subtitle, String kcal) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.restaurant_outlined),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(kcal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(nutritionServiceProvider);
    final onboarding = ref.watch(onboardingProfileProvider);
    final calorieGoal = onboarding.calorieGoal ?? 2100;
    final consumed = _todayMeals.fold<int>(
        0, (acc, item) => acc + ((item['calories'] as int?) ?? 0));
    final consumedWithOptimistic = consumed + _optimisticCalories;
    final progress = calorieGoal <= 0
        ? 0.0
        : (consumedWithOptimistic / calorieGoal).clamp(0.0, 1.0);

    return HamvitProtectedScreenWrapper(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (false)
            const HamvitSectionHeader(
              title: 'Diário alimentar',
              subtitle:
                  'Registre refeições e acompanhe calorias e macronutrientes do dia.',
            ),
          if (false) const SizedBox(height: 12),
          if (onboarding.needsNutritionSoftGate) ...[
            HamvitSoftGateCard(
              title: 'Complete suas preferências para melhorar suas sugestões.',
              subtitle:
                  'Isso ajuda a personalizar recomendações sem bloquear o uso do diário alimentar.',
              buttonLabel: 'Configurar alimentação',
              onTap: () => context.push('/nutrition/preferences'),
            ),
            const SizedBox(height: 10),
          ],
          HamvitProgressCard(
            title: 'Resumo calórico do dia',
            subtitle:
                '$consumedWithOptimistic kcal consumidas de $calorieGoal kcal',
            progress: progress,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: HamvitMetricCard(
                      label: 'Proteínas',
                      value: '${_totalProtein} g',
                      icon: Icons.fitness_center)),
              SizedBox(width: 8),
              Expanded(
                  child: HamvitMetricCard(
                      label: 'Carboidratos',
                      value: '${_totalCarbs} g',
                      icon: Icons.grain)),
              SizedBox(width: 8),
              Expanded(
                  child: HamvitMetricCard(
                      label: 'Gorduras',
                      value: '${_totalFat} g',
                      icon: Icons.opacity)),
            ],
          ),
          const SizedBox(height: 10),
          const HamvitSectionHeader(title: 'Refeições do dia'),
          const SizedBox(height: 8),
          if (_loadingMeals)
            const Padding(
              padding: EdgeInsets.all(12),
              child: LinearProgressIndicator(),
            )
          else if (_todayMeals.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Text('Nenhuma refeição registrada hoje.'),
            )
          else
            ..._todayMeals.map(
              (meal) => _mealTile(
                _mealTypeLabel((meal['meal_type'] ?? 'lanche').toString()),
                'Registro manual',
                '${meal['calories'] ?? 0} kcal',
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _registerMealQuickly,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Registrar refeição'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Scanner de código de barras'),
                  const SizedBox(height: 8),
                  TextField(
                      controller: barcodeCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Código de barras')),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final value = barcodeCtrl.text.trim();
                      if (value.isEmpty) return;
                      final data = await service.lookupBarcode(value);
                      if (!mounted) return;
                      setState(() => barcodeResult = data);
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scanner código de barras'),
                  ),
                  if (barcodeResult != null) ...[
                    const SizedBox(height: 8),
                    Text('Origem: ${barcodeResult!['source'] ?? 'n/d'}'),
                    Text(
                        'Resultado: ${barcodeResult!['data']?['barcode'] ?? barcodeResult!['data']?['code'] ?? 'sem dados'}'),
                  ],
                ],
              ),
            ),
          ),
          PremiumFeatureGate(
            feature: HamvitFeature.foodPhotoAi,
            isPremium: widget.isPremium,
            fallback:
                const PremiumTeaserCard(feature: HamvitFeature.foodPhotoAi),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('IA da comida (Premium)'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isAnalyzingPhoto
                                ? null
                                : () async {
                                    final image = await _picker.pickImage(
                                        source: ImageSource.camera,
                                        imageQuality: 75);
                                    if (image == null) return;
                                    setState(() => isAnalyzingPhoto = true);
                                    try {
                                      final analysis =
                                          await service.analyzeFoodPhoto(
                                              filePath: image.path,
                                              isPremium: widget.isPremium);
                                      if (!mounted) return;
                                      setState(() => photoAnalysis = analysis);
                                    } finally {
                                      if (mounted)
                                        setState(
                                            () => isAnalyzingPhoto = false);
                                    }
                                  },
                            child: const Text('Capturar foto'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isAnalyzingPhoto
                                ? null
                                : () async {
                                    final image = await _picker.pickImage(
                                        source: ImageSource.gallery,
                                        imageQuality: 75);
                                    if (image == null) return;
                                    setState(() => isAnalyzingPhoto = true);
                                    try {
                                      final analysis =
                                          await service.analyzeFoodPhoto(
                                              filePath: image.path,
                                              isPremium: widget.isPremium);
                                      if (!mounted) return;
                                      setState(() => photoAnalysis = analysis);
                                    } finally {
                                      if (mounted)
                                        setState(
                                            () => isAnalyzingPhoto = false);
                                    }
                                  },
                            child: const Text('Escolher foto'),
                          ),
                        ),
                      ],
                    ),
                    if (isAnalyzingPhoto)
                      const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator()),
                    if (photoAnalysis != null) ...[
                      const SizedBox(height: 8),
                      Text(
                          'Status: ${photoAnalysis!['allowed'] == true ? 'permitido' : (photoAnalysis!['reason'] ?? 'indefinido')}'),
                      Text(
                          'Resultado: ${photoAnalysis!['analysis']?['status'] ?? 'sem dados'}'),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: Text(widget.isPremium
                  ? 'Sugestões inteligentes ativas'
                  : 'Sugestões inteligentes (Premium)'),
              subtitle:
                  const Text('Recomendações automáticas e montagem do dia.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Sugestões Premium')),
                      body:
                          RecipeSuggestionsScreen(isPremium: widget.isPremium),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          HamvitModuleSummaryCard(
            title: 'Preferências alimentares',
            description: onboarding.foodPreferences.isEmpty
                ? 'Ainda não configuradas.'
                : 'Preferências: ${onboarding.foodPreferences.join(', ')}\nRestrições: ${onboarding.foodRestrictions.join(', ')}',
            action: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => context.push('/nutrition/preferences'),
                child: const Text('Editar preferências'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
