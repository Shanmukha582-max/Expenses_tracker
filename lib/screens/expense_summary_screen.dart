import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';

class ExpenseSummaryScreen extends StatelessWidget {
  const ExpenseSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final totals = provider.totalsByCategory.entries
        .where((entry) => entry.value > 0)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Summary',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        Card(
          color: Colors.deepPurple,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total spent',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${provider.totalSpent.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (totals.isEmpty)
          const Center(child: Text('No spending totals yet.'))
        else
          ...totals.map(
            (entry) => ListTile(
              leading: const Icon(Icons.pie_chart, color: Colors.deepPurple),
              title: Text(entry.key),
              trailing: Text('₹${entry.value.toStringAsFixed(2)}'),
            ),
          ),
      ],
    );
  }
}
