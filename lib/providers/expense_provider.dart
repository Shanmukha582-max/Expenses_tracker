import 'package:flutter/foundation.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final List<Expense> _expenses = [];
  int _nextId = 1; // temporary, replaced by the database id later
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
    // TODO (hour 1-3): _expenses
    //   ..clear()
    //   ..addAll(await DbHelper.instance.getAllExpenses());
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    // TODO (hour 1-3): final id = await DbHelper.instance.insert(expense);
    final id = _nextId++;
    _expenses.add(expense.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    // TODO (hour 1-3): await DbHelper.instance.update(expense);
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) return;
    _expenses[index] = expense;
    notifyListeners();
  }

  Future<void> deleteExpense(int id) async {
    // TODO (hour 1-3): await DbHelper.instance.delete(id);
    _expenses.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  // ---------- Temporary: dummy data for testing UI ----------

  void loadDummyData() {
    if (_expenses.isNotEmpty) return;
    final now = DateTime.now();
    _expenses.addAll([
      Expense(id: _nextId++, amount: 250, category: 'Food', date: now, note: 'Lunch'),
      Expense(id: _nextId++, amount: 80, category: 'Transport', date: now.subtract(const Duration(days: 1)), note: 'Auto'),
      Expense(id: _nextId++, amount: 1200, category: 'Bills', date: now.subtract(const Duration(days: 2)), note: 'Electricity'),
    ]);
    notifyListeners();
  }
} 
