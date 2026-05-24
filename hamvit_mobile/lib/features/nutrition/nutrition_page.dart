import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';
import '../../features/onboarding/providers/onboarding_profile_provider.dart';
import '../meal_recommendations/meal_recommendations_page.dart';
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

  Map<String, dynamic>? barcodeResult;
  Map<String, dynamic>? photoAnalysis;
  bool isAnalyzingPhoto = false;

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(nutritionServiceProvider);
    final onboarding = ref.watch(onboardingProfileProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (onboarding.needsNutritionSoftGate) ...[
          HamvitSoftGateCard(
            title: 'Quer melhorar suas recomendações alimentares?',
            subtitle: 'Complete suas preferências para receber sugestões mais inteligentes.',
            buttonLabel: 'Configurar Alimentação',
            onTap: () => context.go('/onboarding/food'),
          ),
          const SizedBox(height: 10),
        ],
        const Card(child: ListTile(title: Text('Diário alimentar manual (Free/Premium)'))),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Scanner de código de barras (Free/Premium)'),
                const SizedBox(height: 8),
                TextField(controller: barcodeCtrl, decoration: const InputDecoration(labelText: 'Código de barras')),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () async {
                    final value = barcodeCtrl.text.trim();
                    if (value.isEmpty) return;
                    final data = await service.lookupBarcode(value);
                    if (!mounted) return;
                    setState(() => barcodeResult = data);
                  },
                  child: const Text('Consultar'),
                ),
                if (barcodeResult != null) ...[
                  const SizedBox(height: 8),
                  Text('Origem: ${barcodeResult!['source'] ?? 'n/d'}'),
                  Text('Resultado: ${barcodeResult!['data']?['barcode'] ?? barcodeResult!['data']?['code'] ?? 'sem dados'}'),
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
                  const Text('Foto da comida com IA (Premium)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isAnalyzingPhoto
                              ? null
                              : () async {
                                  final image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 75);
                                  if (image == null) return;
                                  setState(() => isAnalyzingPhoto = true);
                                  try {
                                    final analysis = await service.analyzeFoodPhoto(
                                      filePath: image.path,
                                      isPremium: widget.isPremium,
                                    );
                                    if (!mounted) return;
                                    setState(() => photoAnalysis = analysis);
                                  } finally {
                                    if (mounted) setState(() => isAnalyzingPhoto = false);
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
                                  final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
                                  if (image == null) return;
                                  setState(() => isAnalyzingPhoto = true);
                                  try {
                                    final analysis = await service.analyzeFoodPhoto(
                                      filePath: image.path,
                                      isPremium: widget.isPremium,
                                    );
                                    if (!mounted) return;
                                    setState(() => photoAnalysis = analysis);
                                  } finally {
                                    if (mounted) setState(() => isAnalyzingPhoto = false);
                                  }
                                },
                          child: const Text('Escolher foto'),
                        ),
                      ),
                    ],
                  ),
                  if (isAnalyzingPhoto) const Padding(padding: EdgeInsets.only(top: 8), child: LinearProgressIndicator()),
                  if (photoAnalysis != null) ...[
                    const SizedBox(height: 8),
                    Text('Status: ${photoAnalysis!['allowed'] == true ? 'permitido' : (photoAnalysis!['reason'] ?? 'indefinido')}'),
                    Text('Resultado: ${photoAnalysis!['analysis']?['status'] ?? 'sem dados'}'),
                  ],
                ],
              ),
            ),
          ),
        ),
        Card(
          child: ListTile(
            title: Text(widget.isPremium ? 'Sugestões Premium ativas' : 'Sugestões Premium bloqueadas para Free'),
            subtitle: const Text('Recomendações automáticas e montagem do dia.'),
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
      ],
    );
  }
}
