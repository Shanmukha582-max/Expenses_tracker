import 'package:flutter/foundation.dart';

import '../database/db_helper.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({DbHelper? dbHelper})
    : _dbHelper = dbHelper ?? DbHelper.instance;

  final DbHelper _dbHelper;
  final List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  // ---------- Read-only state for B and C ----------

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// All expenses, newest first.
  List<Expense> get expenses {
    final sorted = [..._expenses];
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return List.unmodifiable(sorted);
  }

  bool get isEmpty => _expenses.isEmpty;

  /// Total of all expenses.
  double get totalSpent => _expenses.fold(0.0, (sum, e) => sum + e.amount);

  /// Total per category. Every category is present, even if 0.
  Map<String, double> get totalsByCategory {
    final totals = {for (final c in Expense.categories) c: 0.0};
    for (final e in _expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }

    return totals;
  }

  Map<String, double> get categoryTotals => totalsByCategory;

  Future<void> loadExpensesIfRequested(bool shouldLoad) async {
    if (shouldLoad) await loadExpenses();
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
    _errorMessage = null;
    notifyListeners();
    try {
      final expenses = await _dbHelper.getAllExpenses();
      _expenses
        ..clear()
        ..addAll(expenses);
    } catch (error) {
      _errorMessage = 'Unable to load expenses: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    try {
      final id = await _dbHelper.insert(expense);
      _expenses.add(expense.copyWith(id: id));
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Unable to add expense: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      await _dbHelper.update(expense);
      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index == -1) return;
      _expenses[index] = expense;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Unable to update expense: $error';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _dbHelper.delete(id);
      _expenses.removeWhere((e) => e.id == id);
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Unable to delete expense: $error';
      notifyListeners();
      rethrow;
    }
  }
}
