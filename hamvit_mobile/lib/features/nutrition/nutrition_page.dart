import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';
import '../../features/onboarding/providers/onboarding_profile_provider.dart';
import '../privacy/app_blur_overlay.dart';
import '../home/providers/home_dashboard_provider.dart';
import '../meal_recommendations/meal_recommendations_page.dart';
import '../../shared/widgets/hamvit_module_widgets.dart';
import '../../shared/widgets/hamvit_onboarding_widgets.dart';
import 'nutrition_service.dart';

class NutritionPage extends ConsumerStatefulWidget {
  final bool isPremium;
  const NutritionPage({super.key, required this.isPremium});

  @override
  ConsumerState<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends ConsumerState<NutritionPage> {
  final barcodeCtrl = TextEditingController();
  final _picker = ImagePicker();
  final List<String> _recentMeals = const [
    'Ontem • Jantar: frango grelhado com arroz integral',
    'Ontem • Almoço: salada + feijão + filé',
    'Sex • Café: iogurte, banana e aveia',
  ];

  Map<String, dynamic>? barcodeResult;
  Map<String, dynamic>? photoAnalysis;
  bool isAnalyzingPhoto = false;
  bool _loadingMeals = false;
  List<Map<String, dynamic>> _todayMeals = const [];

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
      setState(() => _todayMeals = meals);
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
    final caloriesCtrl = TextEditingController(text: '350');
    var selectedMealType = 'almoco';

    final payload = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registrar refeição'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedMealType,
                items: _mealTypeOptions
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['value'],
                        child: Text(item['label']!),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) selectedMealType = value;
                },
                decoration:
                    const InputDecoration(labelText: 'Tipo da refeição'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: caloriesCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Calorias (kcal)',
                  hintText: 'Ex.: 350',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(caloriesCtrl.text.trim());
                if (value == null || value <= 0) return;
                Navigator.of(context).pop({
                  'meal_type': selectedMealType,
                  'calories': value,
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );

    if (payload == null) return;

    try {
      final service = ref.read(nutritionServiceProvider);
      final saved = await service.registerMeal(
        mealType: payload['meal_type'] as String,
        calories: payload['calories'] as int,
      );
      final optimistic = {
        'meal_type': (saved['meal_type'] ?? payload['meal_type']).toString(),
        'calories': (saved['calories'] as int?) ?? (payload['calories'] as int),
      };
      if (mounted) {
        setState(() {
          _todayMeals = [..._todayMeals, optimistic];
        });
      }
      await _loadTodayMeals();
      ref.invalidate(homeDashboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refeição registrada com sucesso.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao registrar refeição: $error')),
      );
    }
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
    final progress =
        calorieGoal <= 0 ? 0.0 : (consumed / calorieGoal).clamp(0.0, 1.0);

    return HamvitProtectedScreenWrapper(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
        const HamvitSectionHeader(
          title: 'Diário alimentar',
          subtitle:
              'Registre refeições e acompanhe calorias e macronutrientes do dia.',
        ),
        const SizedBox(height: 12),
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
          subtitle: '$consumed kcal consumidas de $calorieGoal kcal',
          progress: progress,
        ),
        const SizedBox(height: 8),
        const Row(
          children: [
            Expanded(
                child: HamvitMetricCard(
                    label: 'Proteínas',
                    value: '96 g',
                    icon: Icons.fitness_center)),
            SizedBox(width: 8),
            Expanded(
                child: HamvitMetricCard(
                    label: 'Carboidratos', value: '140 g', icon: Icons.grain)),
            SizedBox(width: 8),
            Expanded(
                child: HamvitMetricCard(
                    label: 'Gorduras', value: '42 g', icon: Icons.opacity)),
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
          fallback: const PremiumTeaserCard(feature: HamvitFeature.foodPhotoAi),
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
                                      setState(() => isAnalyzingPhoto = false);
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
                                      setState(() => isAnalyzingPhoto = false);
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
                    body: MealRecommendationsPage(isPremium: widget.isPremium),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        HamvitHistoryCard(
          title: 'Histórico recente',
          items: _recentMeals,
          icon: Icons.history,
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
