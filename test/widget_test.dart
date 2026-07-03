import 'package:flutter_test/flutter_test.dart';
import 'package:budgetboss_app/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const BudgetBossApp());

    // Verify that Splash Screen is shown (contains BudgetBoss text)
    expect(find.text('BudgetBoss'), findsOneWidget);
  });
}
