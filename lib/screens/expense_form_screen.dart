import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/expense.dart';
import '../providers/expense_provider.dart';

class ExpenseFormScreen extends StatefulWidget {
  const ExpenseFormScreen({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final expense = widget.expense!;
      _titleController.text = expense.title;
      _amountController.text = expense.amount.toString();
      _notesController.text = expense.notes;
      _selectedCategory = expense.category;
      _selectedDate = expense.date;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<ExpenseProvider>();
    final expense = Expense(
      id: widget.expense?.id,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _selectedCategory,
      date: _selectedDate,
      notes: _notesController.text.trim(),
    );

    try {
      if (widget.expense == null) {
        await provider.addExpense(expense);

        if (mounted) {
          _formKey.currentState!.reset();
          _titleController.clear();
          _amountController.clear();
          _notesController.clear();
          setState(() {
            _selectedCategory = 'Food';
            _selectedDate = DateTime.now();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expense saved successfully')),
          );
        }
        return;
      }

      await provider.updateExpense(expense);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save expense: $error')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final buttonText = widget.expense == null ? 'Save Expense' : 'Update Expense';
    final pageTitle = widget.expense == null ? 'Add Expense' : 'Edit Expense';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text(
              pageTitle,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an amount';
                }

                final parsed = double.tryParse(value.trim());
                if (parsed == null || parsed <= 0) {
                  return 'Amount must be greater than 0';
                }

                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                DropdownMenuItem(value: 'Rent', child: Text('Rent')),
                DropdownMenuItem(value: 'Health', child: Text('Health')),
                DropdownMenuItem(value: 'Utilities', child: Text('Utilities')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    const Icon(Icons.calendar_today),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save),
              label: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}
