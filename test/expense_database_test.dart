import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:expenses_tracker/database/db_helper.dart';
import 'package:expenses_tracker/models/expense.dart';
import 'package:expenses_tracker/providers/expense_provider.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  test('supports insert, read, update, and delete', () async {
    await databaseFactoryFfi.deleteDatabase(
      join(await databaseFactoryFfi.getDatabasesPath(), 'crud_test.db'),
    );
    final db = DbHelper(
      factory: databaseFactoryFfi,
      databaseName: 'crud_test.db',
    );
    final provider = ExpenseProvider(dbHelper: db);
    final original = Expense(
      amount: 1250000000000.75,
      category: 'Bills',
      date: DateTime(2026, 1, 2),
      note: 'Large value',
    );

    await provider.addExpense(original);
    final saved = provider.expenses.single;
    expect(saved.id, isNotNull);
    expect(saved.amount, original.amount);

    await provider.updateExpense(saved.copyWith(note: 'Updated'));
    expect(provider.getById(saved.id!)!.note, 'Updated');

    final reloaded = ExpenseProvider(dbHelper: db);
    await reloaded.loadExpenses();
    expect(reloaded.expenses.single.note, 'Updated');

    await reloaded.deleteExpense(saved.id!);
    expect(reloaded.expenses, isEmpty);
    await db.close();
  });

  test('loads many rows and calculates category totals', () async {
    await databaseFactoryFfi.deleteDatabase(
      join(await databaseFactoryFfi.getDatabasesPath(), 'many_rows_test.db'),
    );
    final db = DbHelper(
      factory: databaseFactoryFfi,
      databaseName: 'many_rows_test.db',
    );
    final provider = ExpenseProvider(dbHelper: db);
    for (var index = 0; index < 250; index++) {
      await provider.addExpense(
        Expense(
          amount: index + 1,
          category: index.isEven ? 'Food' : 'Transport',
          date: DateTime(2026, 1, 1).add(Duration(minutes: index)),
        ),
      );
    }

    final reloaded = ExpenseProvider(dbHelper: db);
    await reloaded.loadExpenses();
    expect(reloaded.expenses, hasLength(250));
    expect(reloaded.totalsByCategory['Food'], 15625);
    expect(reloaded.totalsByCategory['Transport'], 15750);
    await db.close();
  });
}
