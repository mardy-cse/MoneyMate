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
  static const int _databaseVersion = 4; // Incremented for imagePath column
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
        voiceNotePath TEXT,
        imagePath TEXT
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
      try {
        await db.execute('''
          ALTER TABLE $_tableName ADD COLUMN voiceNotePath TEXT
        ''');
      } catch (e) {
        // Column may already exist, ignore error
        print('voiceNotePath column might already exist: $e');
      }
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          ALTER TABLE $_tableName ADD COLUMN imagePath TEXT
        ''');
      } catch (e) {
        // Column may already exist, ignore error
        print('imagePath column might already exist: $e');
      }
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

  // Add dummy expenses for testing (temporary method)
  Future<void> insertDummyExpenses() async {
    final now = DateTime.now();

    final dummyExpenses = [
      // Today's expenses (20 items)
      Expense(
        title: 'Morning Coffee',
        amount: 150.0,
        category: 'Food',
        date: DateTime(now.year, now.month, now.day, 7, 30),
        note: 'Starbucks cappuccino',
      ),
      Expense(
        title: 'Breakfast at Cafe',
        amount: 250.0,
        category: 'Food',
        date: DateTime(now.year, now.month, now.day, 8, 15),
        note: 'Egg sandwich and juice',
      ),
      Expense(
        title: 'Uber to Office',
        amount: 120.0,
        category: 'Transport',
        date: DateTime(now.year, now.month, now.day, 9, 0),
        note: 'Morning commute',
      ),
      Expense(
        title: 'Parking Fee',
        amount: 50.0,
        category: 'Transport',
        date: DateTime(now.year, now.month, now.day, 9, 30),
        note: 'Office parking',
      ),
      Expense(
        title: 'Lunch with Team',
        amount: 450.0,
        category: 'Food',
        date: DateTime(now.year, now.month, now.day, 13, 0),
        note: 'Team lunch at restaurant',
      ),
      Expense(
        title: 'Coffee Break',
        amount: 100.0,
        category: 'Food',
        date: DateTime(now.year, now.month, now.day, 15, 30),
        note: 'Afternoon coffee',
      ),
      Expense(
        title: 'Office Supplies',
        amount: 300.0,
        category: 'Shopping',
        date: DateTime(now.year, now.month, now.day, 16, 0),
        note: 'Notebooks and pens',
      ),
      Expense(
        title: 'Internet Recharge',
        amount: 299.0,
        category: 'Bills',
        date: DateTime(now.year, now.month, now.day, 16, 45),
        note: 'Mobile data pack',
      ),
      Expense(
        title: 'Gym Session',
        amount: 200.0,
        category: 'Healthcare',
        date: DateTime(now.year, now.month, now.day, 18, 0),
        note: 'Evening workout',
      ),
      Expense(
        title: 'Snacks Shopping',
        amount: 180.0,
        category: 'Shopping',
        date: DateTime(now.year, now.month, now.day, 18, 30),
        note: 'Chips and drinks',
      ),
      Expense(
        title: 'Auto Rickshaw',
        amount: 60.0,
        category: 'Transport',
        date: DateTime(now.year, now.month, now.day, 19, 0),
        note: 'Gym to home',
      ),
      Expense(
        title: 'Dinner Order',
        amount: 550.0,
        category: 'Food',
        date: DateTime(now.year, now.month, now.day, 20, 30),
        note: 'Food panda order',
      ),
      Expense(
        title: 'Movie Streaming',
        amount: 199.0,
        category: 'Entertainment',
        date: DateTime(now.year, now.month, now.day, 21, 0),
        note: 'Netflix subscription',
      ),
      Expense(
        title: 'Online Book',
        amount: 350.0,
        category: 'Education',
        date: DateTime(now.year, now.month, now.day, 21, 30),
        note: 'Programming ebook',
      ),
      Expense(
        title: 'Medicine',
        amount: 250.0,
        category: 'Healthcare',
        date: DateTime(now.year, now.month, now.day, 10, 0),
        note: 'Headache tablets',
      ),
      Expense(
        title: 'Tea & Biscuits',
        amount: 80.0,
        category: 'Food',
        date: DateTime(now.year, now.month, now.day, 11, 0),
        note: 'Morning snack',
      ),
      Expense(
        title: 'Newspaper',
        amount: 20.0,
        category: 'Shopping',
        date: DateTime(now.year, now.month, now.day, 7, 0),
        note: 'Daily newspaper',
      ),
      Expense(
        title: 'Water Bill',
        amount: 180.0,
        category: 'Bills',
        date: DateTime(now.year, now.month, now.day, 12, 0),
        note: 'Monthly water bill',
      ),
      Expense(
        title: 'Barber Shop',
        amount: 150.0,
        category: 'Healthcare',
        date: DateTime(now.year, now.month, now.day, 17, 0),
        note: 'Haircut',
      ),
      Expense(
        title: 'Ice Cream',
        amount: 120.0,
        category: 'Food',
        date: DateTime(now.year, now.month, now.day, 22, 0),
        note: 'Dessert after dinner',
      ),

      // Previous days expenses
      Expense(
        title: 'Electricity Bill Payment',
        amount: 1500.0,
        category: 'Bills',
        date: now.subtract(const Duration(days: 1)),
        note: 'Monthly electricity bill',
      ),
      Expense(
        title: 'Movie Tickets',
        amount: 600.0,
        category: 'Entertainment',
        date: now.subtract(const Duration(days: 1, hours: 5)),
        note: 'Cinema with family',
      ),
      Expense(
        title: 'Grocery Shopping',
        amount: 3500.0,
        category: 'Shopping',
        date: now.subtract(const Duration(days: 2)),
        note: 'Weekly groceries',
      ),
      Expense(
        title: 'Gym Membership',
        amount: 1200.0,
        category: 'Healthcare',
        date: now.subtract(const Duration(days: 2, hours: 3)),
        note: 'Monthly gym fee',
      ),
      Expense(
        title: 'Online Course Fee',
        amount: 2000.0,
        category: 'Education',
        date: now.subtract(const Duration(days: 3)),
        note: 'Flutter development course',
      ),
      Expense(
        title: 'Dinner at Hotel',
        amount: 850.0,
        category: 'Food',
        date: now.subtract(const Duration(days: 3, hours: 8)),
        note: 'Anniversary dinner',
      ),
      Expense(
        title: 'Bus Fare',
        amount: 50.0,
        category: 'Transport',
        date: now.subtract(const Duration(days: 4)),
        note: 'Local bus travel',
      ),
      Expense(
        title: 'Mobile Recharge',
        amount: 299.0,
        category: 'Bills',
        date: now.subtract(const Duration(days: 4, hours: 6)),
        note: 'Prepaid mobile plan',
      ),
      Expense(
        title: 'Medicine Purchase',
        amount: 450.0,
        category: 'Healthcare',
        date: now.subtract(const Duration(days: 5)),
        note: 'Pharmacy bills',
      ),
      Expense(
        title: 'Pizza Party',
        amount: 1200.0,
        category: 'Food',
        date: now.subtract(const Duration(days: 5, hours: 4)),
        note: 'Friends gathering',
      ),
      Expense(
        title: 'Petrol Refill',
        amount: 1000.0,
        category: 'Transport',
        date: now.subtract(const Duration(days: 6)),
        note: 'Full tank petrol',
      ),
      Expense(
        title: 'Internet Bill',
        amount: 800.0,
        category: 'Bills',
        date: now.subtract(const Duration(days: 6, hours: 7)),
        note: 'Broadband monthly fee',
      ),
      Expense(
        title: 'New Shoes',
        amount: 2500.0,
        category: 'Shopping',
        date: now.subtract(const Duration(days: 7)),
        note: 'Nike running shoes',
      ),
      Expense(
        title: 'Concert Tickets',
        amount: 1500.0,
        category: 'Entertainment',
        date: now.subtract(const Duration(days: 7, hours: 5)),
        note: 'Music concert',
      ),
      Expense(
        title: 'Book Purchase',
        amount: 600.0,
        category: 'Education',
        date: now.subtract(const Duration(days: 8)),
        note: 'Programming books',
      ),
      Expense(
        title: 'Doctor Consultation',
        amount: 800.0,
        category: 'Healthcare',
        date: now.subtract(const Duration(days: 8, hours: 3)),
        note: 'Regular checkup',
      ),
      Expense(
        title: 'Restaurant Snacks',
        amount: 350.0,
        category: 'Food',
        date: now.subtract(const Duration(days: 9)),
        note: 'Evening tea and snacks',
      ),
    ];

    for (var expense in dummyExpenses) {
      await insertExpense(expense);
    }
  }
}
