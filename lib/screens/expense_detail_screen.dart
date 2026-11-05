import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';
import 'expense_form_screen.dart';

class ExpenseDetailScreen extends StatelessWidget {
  const ExpenseDetailScreen({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final currentExpense = provider.expenses.firstWhere(
      (item) => item.id == expense.id,
      orElse: () => expense,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Edit Expense')),
                    body: ExpenseFormScreen(expense: currentExpense),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final id = currentExpense.id;
              if (id != null) {
                try {
                  await provider.deleteExpense(id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                } on Exception catch (error) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to delete expense: $error'),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentExpense.title,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Amount',
              value: '₹${currentExpense.amount.toStringAsFixed(2)}',
            ),
            _InfoRow(label: 'Category', value: currentExpense.category),
            _InfoRow(
              label: 'Date',
              value: DateFormat.yMMMd().format(currentExpense.date),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              currentExpense.notes.isEmpty
                  ? 'No additional notes provided.'
                  : currentExpense.notes,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
