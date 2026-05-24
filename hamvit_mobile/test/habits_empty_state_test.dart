import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hamvit_mobile/features/habits/habit_model.dart';
import 'package:hamvit_mobile/features/habits/habits_widgets.dart';

class _EmptyStateHarness extends StatefulWidget {
  const _EmptyStateHarness();

  @override
  State<_EmptyStateHarness> createState() => _EmptyStateHarnessState();
}

class _EmptyStateHarnessState extends State<_EmptyStateHarness> {
  String? selected;
  int useSuggestionCalls = 0;

  final suggestions = const [
    HabitTemplate(
      title: 'Beber água',
      category: 'Água',
      description: 'Registrar consumo ao longo do dia.',
      frequency: 'Diário',
    ),
    HabitTemplate(
      title: 'Caminhar 20 minutos',
      category: 'Movimento',
      description: 'Movimento leve para manter consistência.',
      frequency: 'Diário',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton(
              onPressed: () {},
              child: const Text('Criar hábito'),
            ),
            const SizedBox(height: 12),
            HamvitHabitEmptyState(
              suggestions: suggestions,
              selectedSuggestionTitle: selected,
              onSelectSuggestion: (template) {
                setState(() {
                  selected = selected == template.title ? null : template.title;
                });
              },
              onUseSuggestion: () {
                setState(() {
                  useSuggestionCalls += 1;
                });
              },
              isUseSuggestionEnabled: selected != null,
            ),
            Text('calls:$useSuggestionCalls'),
          ],
        ),
      ),
    );
  }
}

void main() {
  testWidgets('mantem apenas um botao Criar hábito no layout principal', (tester) async {
    await tester.pumpWidget(const _EmptyStateHarness());

    expect(find.text('Criar hábito'), findsOneWidget);
    expect(find.text('Usar sugestão'), findsOneWidget);
  });

  testWidgets('Usar sugestão inicia desabilitado e habilita ao selecionar chip', (tester) async {
    await tester.pumpWidget(const _EmptyStateHarness());

    final before = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Usar sugestão'));
    expect(before.onPressed, isNull);

    await tester.tap(find.text('Beber água'));
    await tester.pumpAndSettle();

    final after = tester.widget<OutlinedButton>(find.widgetWithText(OutlinedButton, 'Usar sugestão'));
    expect(after.onPressed, isNotNull);

    await tester.tap(find.text('Usar sugestão'));
    await tester.pumpAndSettle();

    expect(find.text('calls:1'), findsOneWidget);
  });
}
