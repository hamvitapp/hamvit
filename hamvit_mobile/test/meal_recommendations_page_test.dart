import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamvit_mobile/features/meal_recommendations/meal_recommendations_page.dart';

void main() {
  testWidgets('Free user sees premium teaser', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MealRecommendationsPage(isPremium: false)));
    expect(find.textContaining('Sugestoes automaticas sao exclusivas do Premium.'), findsOneWidget);
  });

  testWidgets('Premium user sees suggestion cards', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MealRecommendationsPage(isPremium: true)));
    expect(find.text('Sugestoes Premium'), findsOneWidget);
    expect(find.text('Omelete proteico com tomate'), findsOneWidget);
    expect(find.text('Frango com arroz integral'), findsOneWidget);
    expect(find.text('Iogurte com aveia e frutas'), findsOneWidget);
  });
}

