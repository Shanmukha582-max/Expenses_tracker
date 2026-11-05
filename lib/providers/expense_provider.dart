import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../data/expense_repository.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  ExpenseProvider({ExpenseRepository? repository})
      : _repository = repository ?? DatabaseHelper.instance;

  final ExpenseRepository _repository;

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Expense> get expenses => List.unmodifiable(_expenses);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  double get totalSpent => _expenses.fold(0.0, (sum, expense) => sum + expense.amount);

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (final expense in _expenses) {
      totals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }

    return totals;
  }

  Future<void> loadExpenses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _expenses = await _repository.getExpenses();
    } catch (error) {
      _errorMessage = 'Unable to load expenses: $error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense(Expense expense) async {
    await _repository.insertExpense(expense);
    await loadExpenses();
    _throwIfLoadFailed();
  }

  Future<void> updateExpense(Expense expense) async {
    if (expense.id == null) {
      return;
    }

    await _repository.updateExpense(expense);
    await loadExpenses();
    _throwIfLoadFailed();
  }

  Future<void> deleteExpense(int id) async {
    await _repository.deleteExpense(id);
    await loadExpenses();
    _throwIfLoadFailed();
  }

  void _throwIfLoadFailed() {
    final error = _errorMessage;
    if (error != null) {
      throw Exception(error);
    }
  }
}
