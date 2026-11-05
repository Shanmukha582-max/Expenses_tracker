import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import 'expense_detail_screen.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(provider.errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: provider.loadExpenses,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.expenses.isEmpty) {
      return const Center(
        child: Text('No expenses yet. Add your first expense.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: provider.expenses.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, index) {
        final expense = provider.expenses[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.deepPurple.shade50,
            child: Icon(
              _categoryIcon(expense.category),
              color: Colors.deepPurple,
            ),
          ),
          title: Text(expense.title),
          subtitle: Text(
            '${expense.category} • ${DateFormat.yMMMd().format(expense.date)}',
          ),
          trailing: Text(
            '-₹${expense.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ExpenseDetailScreen(expense: expense),
              ),
            );
          },
        );
      },
    );
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.fastfood;
      case 'shopping':
        return Icons.shopping_bag;
      case 'travel':
        return Icons.flight;
      case 'health':
        return Icons.medical_services;
      case 'rent':
        return Icons.home;
      case 'utilities':
        return Icons.electrical_services;
      default:
        return Icons.receipt_long;
    }
  }
}
