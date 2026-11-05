import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({DbHelper? dbHelper}) : _dbHelper = dbHelper ?? DbHelper.instance;

  final DbHelper _dbHelper;
  final List<Expense> _expenses = [];
  bool _isLoading = false;

  // ---------- Read-only state for B and C ----------

  bool get isLoading => _isLoading;

  /// All expenses, newest first.
  List<Expense> get expenses {
    final sorted = [..._expenses];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  bool get isEmpty => _expenses.isEmpty;

  /// Total of all expenses.
  double get totalSpent =>
      _expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Total per category. Every category is present, even if 0.
  Map<String, double> get totalsByCategory {
    final totals = {for (final c in Expense.categories) c: 0.0};
    for (final e in _expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Expense? getById(int id) {
    for (final e in _expenses) {
      if (e.id == id) return e;
    }
    return null;
  }

  // ---------- Actions for B ----------

  /// Call once at app start (main.dart).
  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();
    try {
      final expenses = await _dbHelper.getAllExpenses();
      _expenses
        ..clear()
        ..addAll(expenses);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    final id = await _dbHelper.insert(expense);
    _expenses.add(expense.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _dbHelper.update(expense);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) return;
    _expenses[index] = expense;
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    await _dbHelper.delete(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }
}
