import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
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
      version: 3,
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
    await db.execute('''
      CREATE TABLE profile(
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL,
        email TEXT NOT NULL
      )
    ''');
    await db.insert('profile', {'id': 1, 'name': '', 'email': ''});
  }

  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      await _migrateToCurrentSchema(db);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE profile(
          id INTEGER PRIMARY KEY CHECK (id = 1),
          name TEXT NOT NULL,
          email TEXT NOT NULL
        )
      ''');
      await db.insert('profile', {'id': 1, 'name': '', 'email': ''});
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

  Future<Map<String, String>> getProfile() async {
    final db = await database;
    final rows = await db.query('profile', where: 'id = 1');
    if (rows.isEmpty) return {'name': '', 'email': ''};
    return {
      'name': rows.first['name'] as String,
      'email': rows.first['email'] as String,
    };
  }

  Future<void> saveProfile({
    required String name,
    required String email,
  }) async {
    final db = await database;
    await db.insert('profile', {
      'id': 1,
      'name': name,
      'email': email,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<File> exportBackup() async {
    final db = await database;
    final directory = await getApplicationDocumentsDirectory();
    final file = File(join(directory.path, 'expenses_backup.json'));
    final backup = {
      'version': 1,
      'expenses': await db.query('expenses'),
      'profile': await db.query('profile'),
    };
    return file..writeAsStringSync(jsonEncode(backup));
  }

  Future<void> restoreBackup() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(join(directory.path, 'expenses_backup.json'));
    if (!file.existsSync()) {
      throw StateError('No backup file found on this device.');
    }
    final backup =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final expenses = (backup['expenses'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final profiles = (backup['profile'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final db = await database;
    await db.transaction((transaction) async {
      await transaction.delete('expenses');
      await transaction.delete('profile');
      for (final expense in expenses) {
        await transaction.insert('expenses', expense);
      }
      for (final profile in profiles) {
        await transaction.insert('profile', profile);
      }
      if (profiles.isEmpty) {
        await transaction.insert('profile', {'id': 1, 'name': '', 'email': ''});
      }
    });
  }
}
