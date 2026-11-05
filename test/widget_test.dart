import 'package:expenses_tracker/data/expense_repository.dart';
import 'package:expenses_tracker/main.dart';
import 'package:expenses_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'displays the expense tracker home page',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ExpenseTrackerApp(repository: _FakeExpenseRepository()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Expense Tracker'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Summary'), findsOneWidget);
    },
  );

  testWidgets(
    'adds an expense and includes it in the summary',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        ExpenseTrackerApp(repository: _FakeExpenseRepository()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Lunch');
      await tester.enterText(find.byType(TextFormField).at(1), '12.50');
      await tester.ensureVisible(find.text('Save Expense'));
      await tester.tap(find.text('Save Expense'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Summary'));
      await tester.pumpAndSettle();

      expect(find.text('₹12.50'), findsNWidgets(2));
    },
  );

  testWidgets(
    'shows updated expense details after editing',
    (WidgetTester tester) async {
      final repository = _FakeExpenseRepository();
      await repository.insertExpense(_sampleExpense());
      await tester.pumpWidget(ExpenseTrackerApp(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), '20.00');
      await tester.ensureVisible(find.text('Update Expense'));
      await tester.tap(find.text('Update Expense'));
      await tester.pumpAndSettle();

      expect(find.text('₹20.00'), findsOneWidget);
    },
  );

  testWidgets(
    'deletes an expense from the list',
    (WidgetTester tester) async {
      final repository = _FakeExpenseRepository();
      await repository.insertExpense(_sampleExpense());
      await tester.pumpWidget(ExpenseTrackerApp(repository: repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lunch'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text('No expenses yet. Add your first expense.'), findsOneWidget);
    },
  );
}

Expense _sampleExpense() => Expense(
      title: 'Lunch',
      amount: 12.5,
      category: 'Food',
      date: DateTime(2026, 1, 2),
    );

class _FakeExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];
  int _nextId = 1;

  @override
  Future<int> insertExpense(Expense expense) async {
    final id = _nextId++;
    _expenses.add(expense.copyWith(id: id));
    return id;
  }

  @override
  Future<List<Expense>> getExpenses() async {
    return List<Expense>.of(_expenses)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<int> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index < 0) {
      return 0;
    }

    _expenses[index] = expense;
    return 1;
  }

  @override
  Future<int> deleteExpense(int id) async {
    final initialLength = _expenses.length;
    _expenses.removeWhere((expense) => expense.id == id);
    return initialLength - _expenses.length;
  }
}
