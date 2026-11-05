import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/expense_repository.dart';
import 'providers/expense_provider.dart';
import 'screens/expense_form_screen.dart';
import 'screens/expense_list_screen.dart';
import 'screens/expense_summary_screen.dart';
import 'screens/budget_progress_screen.dart';

void main() {
  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key, this.repository});

  final ExpenseRepository? repository;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ExpenseProvider(repository: repository)..loadExpenses(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Expense Tracker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const ExpenseHomePage(),
      ),
    );
  }
}

class ExpenseHomePage extends StatefulWidget {
  const ExpenseHomePage({super.key});

  @override
  State<ExpenseHomePage> createState() => _ExpenseHomePageState();
}

class _ExpenseHomePageState extends State<ExpenseHomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    ExpenseListScreen(),
    ExpenseFormScreen(),
    ExpenseSummaryScreen(),
    BudgetProgressScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.black54,
        selectedIconTheme: const IconThemeData(color: Colors.black87),
        unselectedIconTheme: const IconThemeData(color: Colors.black54),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Expenses'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Summary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
        ],
      ),
    );
  }
}
