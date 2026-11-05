import 'package:expenses_tracker/data/expense_repository.dart';
import 'package:expenses_tracker/models/expense.dart';
import 'package:expenses_tracker/providers/expense_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'supports insert, read, update, and delete through the provider',
    () async {
      final repository = _MemoryExpenseRepository();
      final provider = ExpenseProvider(repository: repository);
      final original = Expense(
        title: 'Rent',
        amount: 1250,
        category: 'Bills',
        date: DateTime(2026, 1, 2),
        notes: 'Monthly payment',
      );

      await provider.addExpense(original);
      final saved = provider.expenses.single;
      expect(saved.id, isNotNull);

      await provider.updateExpense(saved.copyWith(notes: 'Updated'));
      expect(provider.expenses.single.notes, 'Updated');

      final reloaded = ExpenseProvider(repository: repository);
      await reloaded.loadExpenses();
      expect(reloaded.expenses.single.notes, 'Updated');

      await reloaded.deleteExpense(saved.id!);
      expect(reloaded.expenses, isEmpty);
    },
  );
}

class _MemoryExpenseRepository implements ExpenseRepository {
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
    if (index < 0) return 0;
    _expenses[index] = expense;
    return 1;
  }

  @override
  Future<int> deleteExpense(int id) async {
    final before = _expenses.length;
    _expenses.removeWhere((expense) => expense.id == id);
    return before - _expenses.length;
  }
}
