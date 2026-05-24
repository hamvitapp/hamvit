import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/premium/premium_access_matrix.dart';
import '../../core/premium/premium_widgets.dart';

class MealRecommendationsPage extends StatefulWidget {
  final bool isPremium;
  const MealRecommendationsPage({super.key, required this.isPremium});

  @override
  State<MealRecommendationsPage> createState() => _MealRecommendationsPageState();
}

class _MealRecommendationsPageState extends State<MealRecommendationsPage> {
  final List<Map<String, dynamic>> _suggestions = [
    {
      'name': 'Omelete proteico com tomate',
      'mealType': 'Cafe da manha',
      'calories': 438,
      'protein': 37,
      'carbs': 40,
      'fat': 14,
      'prep': 25,
      'status': 'new',
    },
    {
      'name': 'Frango com arroz integral',
      'mealType': 'Almoco',
      'calories': 396,
      'protein': 34,
      'carbs': 42,
      'fat': 9,
      'prep': 20,
      'status': 'new',
    },
    {
      'name': 'Iogurte com aveia e frutas',
      'mealType': 'Lanche',
      'calories': 270,
      'protein': 18,
      'carbs': 31,
      'fat': 7,
      'prep': 8,
      'status': 'new',
    },
  ];

  void _updateStatus(int index, String status) {
    setState(() {
      _suggestions[index]['status'] = status;
    });
  }

  void _replaceSuggestion(int index) {
    final original = _suggestions[index];
    setState(() {
      _suggestions[index] = {
        ...original,
        'name': '${original['name']} (alternativa)',
        'calories': (original['calories'] as int) - 30,
        'status': 'new',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumFeatureGate(
      feature: HamvitFeature.nutritionSmartRecommendations,
      isPremium: widget.isPremium,
      fallback: PremiumTeaserCard(
        feature: HamvitFeature.nutritionSmartRecommendations,
        onTap: () => context.go('/premium'),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Card(
            child: ListTile(
              title: Text('Sugestões Premium'),
              subtitle: Text('Com base nas metas restantes do dia e refeicao atual.'),
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < _suggestions.length; i++) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _suggestions[i]['name'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(_suggestions[i]['mealType'] as String),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_suggestions[i]['calories']} kcal  |  P ${_suggestions[i]['protein']}g  |  C ${_suggestions[i]['carbs']}g  |  G ${_suggestions[i]['fat']}g',
                    ),
                    Text('Tempo: ${_suggestions[i]['prep']} min'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton(
                          onPressed: () => _updateStatus(i, 'added'),
                          child: const Text('Adicionar ao diário'),
                        ),
                        OutlinedButton(
                          onPressed: () => _updateStatus(i, 'liked'),
                          child: const Text('Favoritar'),
                        ),
                        OutlinedButton(
                          onPressed: () => _updateStatus(i, 'rejected'),
                          child: const Text('Não gostei'),
                        ),
                        TextButton(
                          onPressed: () => _replaceSuggestion(i),
                          child: const Text('Trocar receita'),
                        ),
                      ],
                    ),
                    if ((_suggestions[i]['status'] as String) != 'new') ...[
                      const SizedBox(height: 6),
                      Text('Status: ${_suggestions[i]['status']}'),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
