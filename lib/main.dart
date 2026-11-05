import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/expense.dart';
import 'providers/expense_provider.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key, this.loadData = true});

  final bool loadData;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: ExpenseHomePage(loadData: loadData),
      ),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key, required this.loadData});

  final bool loadData;

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  @override
  void initState() {
    super.initState();
    if (widget.loadData) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ExpenseProvider>().loadExpenses(),
      );
    }
  }

  Future<void> _addExpense() async {
    final expense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ExpenseForm(),
    );
    if (expense != null && mounted) {
      await context.read<ExpenseProvider>().addExpense(expense);
    }
  }

  Future<void> _editExpense(Expense existing) async {
    final expense = await showModalBottomSheet<Expense>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ExpenseForm(initialExpense: existing),
    );
    if (expense != null && mounted) {
      await context.read<ExpenseProvider>().updateExpense(expense);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: provider.loadExpenses,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Welcome back!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _currency(provider.totalSpent),
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
                const SizedBox(height: 24),
                const Text(
                  'Category totals',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: provider.totalsByCategory.entries
                      .map(
                        (entry) => Chip(
                          label: Text(
                            '${entry.key}: ${_currency(entry.value)}',
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (provider.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No expenses yet. Add one to begin.'),
                    ),
                  )
                else
                  ...provider.expenses.map(
                    (expense) => Dismissible(
                      key: ValueKey(expense.id),
                      background: Container(color: Colors.red),
                      onDismissed: (_) => provider.deleteExpense(expense.id!),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(_iconFor(expense.category)),
                        ),
                        title: Text(expense.category),
                        subtitle: Text(
                          '${expense.note.isEmpty ? 'No note' : expense.note} • '
                          '${_date(expense.date)}',
                        ),
                        onTap: () => _editExpense(expense),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currency(expense.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit expense',
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editExpense(expense),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ExpenseForm extends StatefulWidget {
  const _ExpenseForm({this.initialExpense});

  final Expense? initialExpense;

  @override
  State<_ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<_ExpenseForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _category = Expense.categories.first;

  @override
  void initState() {
    super.initState();
    final expense = widget.initialExpense;
    if (expense != null) {
      _amountController.text = expense.amount.toString();
      _noteController.text = expense.note;
      _category = expense.category;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Expense(
        id: widget.initialExpense?.id,
        amount: double.parse(_amountController.text.trim()),
        category: _category,
        date: widget.initialExpense?.date ?? DateTime.now(),
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                return amount == null || amount <= 0
                    ? 'Enter a positive amount'
                    : null;
              },
            ),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: Expense.categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save expense')),
          ],
        ),
      ),
    );
  }
}

String _currency(double value) => '₹${value.toStringAsFixed(2)}';

String _date(DateTime date) => '${date.day}/${date.month}/${date.year}';

IconData _iconFor(String category) {
  return switch (category) {
    'Food' => Icons.restaurant,
    'Transport' => Icons.directions_car,
    'Shopping' => Icons.shopping_bag,
    'Bills' => Icons.receipt_long,
    _ => Icons.more_horiz,
  };
}
