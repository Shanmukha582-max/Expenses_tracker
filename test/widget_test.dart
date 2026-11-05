import 'package:expenses_tracker/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays the expense tracker navigation', (tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());
    await tester.pumpAndSettle();

    expect(find.text('Expense Tracker'), findsOneWidget);
    expect(find.text('Expenses'), findsOneWidget);
    expect(find.text('Add'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
  });
}
