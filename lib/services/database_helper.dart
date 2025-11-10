import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/expense.dart';
import '../models/budget.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Database configuration
  static const String _databaseName = 'money_mate.db';
  static const int _databaseVersion = 3;
  static const String _tableName = 'expenses';
  static const String _budgetTable = 'budgets';
  static const String _goalsTable = 'saving_goals';

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize the database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT,
        voiceNotePath TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $_budgetTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        period TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_goalsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL DEFAULT 0,
        deadline TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Upgrade database
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $_budgetTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          period TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE $_goalsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          targetAmount REAL NOT NULL,
          currentAmount REAL NOT NULL DEFAULT 0,
          deadline TEXT NOT NULL,
          createdAt TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE $_tableName ADD COLUMN voiceNotePath TEXT
      ''');
    }
  }

  // Insert an expense into the database
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert(
      _tableName,
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all expenses from the database
  Future<List<Expense>> getExpenses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC', // Most recent first
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Update an existing expense
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      _tableName,
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense by id
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Optional: Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Optional: Get expenses within a date range
  Future<List<Expense>> getExpensesByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate.toIso8601String(), endDate.toIso8601String()],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Expense.fromMap(maps[i]);
    });
  }

  // Optional: Get total expenses
  Future<double> getTotalExpenses() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM $_tableName',
    );
    return result[0]['total'] as double? ?? 0.0;
  }

  // Optional: Clear all expenses (useful for testing)
  Future<void> clearAllExpenses() async {
    final db = await database;
    await db.delete(_tableName);
  }

  // Close the database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // ========== Budget Methods ==========

  // Insert a budget
  Future<int> insertBudget(Budget budget) async {
    final db = await database;
    return await db.insert(
      _budgetTable,
      budget.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all budgets
  Future<List<Budget>> getBudgets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _budgetTable,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Budget.fromMap(maps[i]);
    });
  }

  // Get budget by category
  Future<Budget?> getBudgetByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _budgetTable,
      where: 'category = ?',
      whereArgs: [category],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Budget.fromMap(maps.first);
  }

  // Update a budget
  Future<int> updateBudget(Budget budget) async {
    final db = await database;
    return await db.update(
      _budgetTable,
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  // Delete a budget
  Future<int> deleteBudget(int id) async {
    final db = await database;
    return await db.delete(_budgetTable, where: 'id = ?', whereArgs: [id]);
  }

  // ========== Saving Goals Methods ==========

  // Insert a saving goal
  Future<int> insertGoal(SavingGoal goal) async {
    final db = await database;
    return await db.insert(
      _goalsTable,
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all saving goals
  Future<List<SavingGoal>> getGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _goalsTable,
      orderBy: 'deadline ASC',
    );

    return List.generate(maps.length, (i) {
      return SavingGoal.fromMap(maps[i]);
    });
  }

  // Update a saving goal
  Future<int> updateGoal(SavingGoal goal) async {
    final db = await database;
    return await db.update(
      _goalsTable,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // Delete a saving goal
  Future<int> deleteGoal(int id) async {
    final db = await database;
    return await db.delete(_goalsTable, where: 'id = ?', whereArgs: [id]);
  }
}
