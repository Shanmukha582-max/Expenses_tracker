import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.expenses.isEmpty) {
      return const Center(
        child: Text('No expenses yet. Add your first expense.'),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.loadExpenses,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.expenses.length,
        separatorBuilder: (_, _) => const Divider(),
        itemBuilder: (context, index) {
          final expense = provider.expenses[index];
          return ListTile(
            leading: CircleAvatar(child: Icon(_iconFor(expense.category))),
            title: Text(expense.category),
            subtitle: Text(
              '${expense.note.isEmpty ? 'No note' : expense.note} • '
              '${expense.date.day}/${expense.date.month}/${expense.date.year}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('₹${expense.amount.toStringAsFixed(2)}'),
                IconButton(
                  tooltip: 'Edit expense',
                  icon: const Icon(Icons.edit),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ExpenseFormScreen(expense: expense),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete expense',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => provider.deleteExpense(expense.id!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String category) {
    return switch (category) {
      'Food' => Icons.restaurant,
      'Transport' => Icons.directions_car,
      'Shopping' => Icons.shopping_bag,
      'Bills' => Icons.receipt_long,
      _ => Icons.more_horiz,
    };
  }
}
