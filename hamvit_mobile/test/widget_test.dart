import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hamvit_mobile/main.dart';

void main() {
  testWidgets('App opens', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: HamvitApp()));
    expect(find.byType(HamvitApp), findsOneWidget);
  });
}
