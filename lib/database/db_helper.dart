import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';

class DbHelper {
  DbHelper({DatabaseFactory? factory, this.databaseName = 'expenses.db'})
      : _databaseFactory = factory;

  static final DbHelper instance = DbHelper();

  final DatabaseFactory? _databaseFactory;
  final String databaseName;
  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;

    final factory = _databaseFactory ?? databaseFactory;
    final databasesPath = await factory.getDatabasesPath();
    final database = await factory.openDatabase(
      join(databasesPath, databaseName),
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE expenses (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount REAL NOT NULL,
              category TEXT NOT NULL,
              date TEXT NOT NULL,
              note TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    _database = database;
    return database;
  }

  Future<int> insert(Expense expense) async {
    final db = await database;
    return db.insert('expenses', expense.toMap()..remove('id'));
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final rows = await db.query('expenses', orderBy: 'date DESC, id DESC');
    return rows.map(Expense.fromMap).toList(growable: false);
  }

  Future<int> update(Expense expense) async {
    final id = expense.id;
    if (id == null) {
      throw ArgumentError('An expense must have an id before it can be updated.');
    }
    final db = await database;
    return db.update(
      'expenses',
      expense.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    await database?.close();
  }
}
