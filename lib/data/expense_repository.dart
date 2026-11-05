import '../models/expense.dart';

abstract interface class ExpenseRepository {
  Future<int> insertExpense(Expense expense);

  Future<List<Expense>> getExpenses();

  Future<int> updateExpense(Expense expense);

  Future<int> deleteExpense(int id);
}
