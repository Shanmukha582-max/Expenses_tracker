import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'expense_repository.dart';
import '../models/expense.dart';

class DatabaseHelper implements ExpenseRepository {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'expenses.db');

    return openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateToCurrentSchema(db);
    }
  }

  Future<void> _migrateToCurrentSchema(Database db) async {
    final columns = await db.rawQuery('PRAGMA table_info(expenses)');
    final names = columns.map((column) => column['name'] as String).toSet();
    if (names.contains('title') && names.contains('notes')) return;

    final legacyRows = await db.query('expenses');
    await db.transaction((transaction) async {
      await transaction.execute(
        'ALTER TABLE expenses RENAME TO expenses_legacy',
      );
      await transaction.execute('''
        CREATE TABLE expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          amount REAL NOT NULL,
          category TEXT NOT NULL,
          date TEXT NOT NULL,
          notes TEXT
        )
      ''');

      for (final row in legacyRows) {
        await transaction.insert('expenses', {
          'id': row['id'],
          'title': row['title'] ?? row['category'] ?? 'Expense',
          'amount': row['amount'],
          'category': row['category'] ?? 'Other',
          'date': row['date'],
          'notes': row['notes'] ?? row['note'] ?? '',
        });
      }

      await transaction.execute('DROP TABLE expenses_legacy');
    });
  }

  @override
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap());
  }

  @override
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'date DESC');

    return maps.map(Expense.fromMap).toList();
  }

  @override
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  @override
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getCategoryTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT category, SUM(amount) AS total
      FROM expenses
      GROUP BY category
      ORDER BY total DESC
    ''');

    final totals = <String, double>{};
    for (final row in result) {
      final key = row['category'] as String;
      totals[key] = (row['total'] as num).toDouble();
    }
    return totals;
  }
}
