import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class BudgetProgressScreen extends StatefulWidget {
  const BudgetProgressScreen({super.key});

  @override
  State<BudgetProgressScreen> createState() => _BudgetProgressScreenState();
}

class _BudgetProgressScreenState extends State<BudgetProgressScreen> {
  double _budget = 50000;

  Future<void> _editBudget() async {
    final controller = TextEditingController(text: _budget.toStringAsFixed(2));
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set budget'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Budget',
            prefixText: '₹ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final budget = double.tryParse(controller.text.trim());
              if (budget != null && budget > 0) Navigator.pop(context, budget);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value != null) setState(() => _budget = value);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final spent = provider.totalSpent;
    final remaining = _budget - spent;
    final progress = (spent / _budget).clamp(0.0, 1.0);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Budget Progress',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monthly budget',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit budget',
                      onPressed: _editBudget,
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${spent.toStringAsFixed(2)} spent of '
                  '₹${_budget.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 14,
                  color: spent > _budget ? Colors.red : Colors.deepPurple,
                  backgroundColor: Colors.deepPurple.shade100,
                ),
                const SizedBox(height: 12),
                Text(
                  remaining >= 0
                      ? '₹${remaining.toStringAsFixed(2)} remaining'
                      : '₹${(-remaining).toStringAsFixed(2)} over budget',
                  style: TextStyle(
                    color: remaining >= 0 ? Colors.green : Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
