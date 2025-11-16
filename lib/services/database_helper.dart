import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/debt.dart';

class DatabaseHelper {
  // Singleton pattern
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  // Database configuration
  static const String _databaseName = 'money_mate.db';
  static const int _databaseVersion = 5; // Incremented for debt tables
  static const String _tableName = 'expenses';
  static const String _budgetTable = 'budgets';
  static const String _goalsTable = 'saving_goals';
  static const String _debtTable = 'debts';
  static const String _debtPaymentTable = 'debt_payments';

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await _ensureTablesExist(); // Ensure all tables exist
    return _database!;
  }

  // Ensure debt tables exist (for existing installations)
  Future<void> _ensureTablesExist() async {
    if (_database == null) return;

    try {
      // Check if debts table exists
      final result = await _database!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$_debtTable'",
      );

      if (result.isEmpty) {
        // Create debt tables if they don't exist
        await _database!.execute('''
          CREATE TABLE $_debtTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            personName TEXT NOT NULL,
            amount REAL NOT NULL,
            paidAmount REAL NOT NULL DEFAULT 0,
            type TEXT NOT NULL,
            description TEXT,
            date TEXT NOT NULL,
            dueDate TEXT,
            phoneNumber TEXT,
            status TEXT NOT NULL DEFAULT 'pending',
            createdAt TEXT NOT NULL
          )
        ''');

        await _database!.execute('''
          CREATE TABLE $_debtPaymentTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            debtId INTEGER NOT NULL,
            amount REAL NOT NULL,
            paymentDate TEXT NOT NULL,
            note TEXT,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (debtId) REFERENCES $_debtTable (id) ON DELETE CASCADE
          )
        ''');

        print('Debt tables created successfully');
      }
    } catch (e) {
      print('Error ensuring tables exist: $e');
    }
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

    await db.execute('''
      CREATE TABLE $_debtTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        personName TEXT NOT NULL,
        amount REAL NOT NULL,
        paidAmount REAL NOT NULL DEFAULT 0,
        type TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        dueDate TEXT,
        phoneNumber TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_debtPaymentTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        debtId INTEGER NOT NULL,
        amount REAL NOT NULL,
        paymentDate TEXT NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (debtId) REFERENCES $_debtTable (id) ON DELETE CASCADE
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
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE $_debtTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          personName TEXT NOT NULL,
          amount REAL NOT NULL,
          paidAmount REAL NOT NULL DEFAULT 0,
          type TEXT NOT NULL,
          description TEXT,
          date TEXT NOT NULL,
          dueDate TEXT,
          phoneNumber TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          createdAt TEXT NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE $_debtPaymentTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          debtId INTEGER NOT NULL,
          amount REAL NOT NULL,
          paymentDate TEXT NOT NULL,
          note TEXT,
          createdAt TEXT NOT NULL,
          FOREIGN KEY (debtId) REFERENCES $_debtTable (id) ON DELETE CASCADE
        )
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

  // Clear all data (expenses, budgets, goals, debts, debt payments)
  // Called when user logs out to prevent data mixing between accounts
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_tableName); // Clear expenses
    await db.delete(_budgetTable); // Clear budgets
    await db.delete(_goalsTable); // Clear saving goals
    await db.delete(
      _debtPaymentTable,
    ); // Clear debt payments first (foreign key)
    await db.delete(_debtTable); // Clear debts
    print('All local data cleared');
  }

  // Check if there's any local data (for offline usage detection)
  Future<bool> hasLocalData() async {
    final db = await database;

    // Check expenses
    final expenseCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_tableName'),
        ) ??
        0;

    // Check budgets
    final budgetCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_budgetTable'),
        ) ??
        0;

    // Check goals
    final goalsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_goalsTable'),
        ) ??
        0;

    // Check debts
    final debtsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_debtTable'),
        ) ??
        0;

    return expenseCount > 0 ||
        budgetCount > 0 ||
        goalsCount > 0 ||
        debtsCount > 0;
  }

  // Get count of local data items
  Future<Map<String, int>> getLocalDataCount() async {
    final db = await database;

    return {
      'expenses':
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_tableName'),
          ) ??
          0,
      'budgets':
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_budgetTable'),
          ) ??
          0,
      'goals':
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_goalsTable'),
          ) ??
          0,
      'debts':
          Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_debtTable'),
          ) ??
          0,
    };
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
  // Insert a new saving goal
  Future<int> insertGoal(SavingGoal goal) async {
    final db = await database;
    final id = await db.insert(
      _goalsTable,
      goal.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sync to Firebase
    await _syncGoalToFirebase(goal.copyWith(id: id));

    return id;
  }

  // Sync goals from Firebase to local database
  Future<void> syncGoalsFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = await database;

      // Get all goals from Firebase
      final goalsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('saving_goals')
          .get();

      for (var doc in goalsSnapshot.docs) {
        final goalData = doc.data();
        final goal = SavingGoal.fromMap(goalData);

        // Insert or update in local database
        await db.insert(
          _goalsTable,
          goal.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      print('Goals synced from Firebase successfully');
    } catch (e) {
      print('Error syncing goals from Firebase: $e');
    }
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
    final result = await db.update(
      _goalsTable,
      goal.toMap(),
      where: 'id = ?',
      whereArgs: [goal.id],
    );

    // Sync to Firebase
    await _syncGoalToFirebase(goal);

    return result;
  }

  // Delete a saving goal
  Future<int> deleteGoal(int id) async {
    final db = await database;
    final result = await db.delete(
      _goalsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Delete from Firebase
    await _deleteGoalFromFirebase(id);

    return result;
  }

  // Sync goal to Firebase
  Future<void> _syncGoalToFirebase(SavingGoal goal) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saving_goals')
            .doc(goal.id.toString())
            .set(goal.toMap());
      }
    } catch (e) {
      print('Error syncing goal to Firebase: $e');
    }
  }

  // Delete goal from Firebase
  Future<void> _deleteGoalFromFirebase(int id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saving_goals')
            .doc(id.toString())
            .delete();
      }
    } catch (e) {
      print('Error deleting goal from Firebase: $e');
    }
  }

  // ==================== DEBT/LOAN OPERATIONS ====================

  // Sync debts from Firebase to local database
  Future<void> syncDebtsFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = await database;

      // Get all debts from Firebase
      final debtsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('debts')
          .get();

      for (var doc in debtsSnapshot.docs) {
        final debtData = doc.data();
        final debt = Debt.fromMap(debtData);

        // Insert or update in local database
        await db.insert(
          _debtTable,
          debt.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Sync payments for this debt
        final paymentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('debts')
            .doc(doc.id)
            .collection('payments')
            .get();

        for (var paymentDoc in paymentsSnapshot.docs) {
          final paymentData = paymentDoc.data();
          final payment = DebtPayment.fromMap(paymentData);

          await db.insert(
            _debtPaymentTable,
            payment.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      print('Debts synced from Firebase successfully');
    } catch (e) {
      print('Error syncing debts from Firebase: $e');
    }
  }

  // Insert a new debt
  Future<int> insertDebt(Debt debt) async {
    final db = await database;
    final id = await db.insert(
      _debtTable,
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sync to Firebase
    await _syncDebtToFirebase(debt.copyWith(id: id));

    return id;
  }

  // Get all debts
  Future<List<Debt>> getDebts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _debtTable,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Debt.fromMap(maps[i]);
    });
  }

  // Get debts by type ('lent' or 'borrowed')
  Future<List<Debt>> getDebtsByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _debtTable,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Debt.fromMap(maps[i]);
    });
  }

  // Get debts by status
  Future<List<Debt>> getDebtsByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _debtTable,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Debt.fromMap(maps[i]);
    });
  }

  // Get single debt by ID
  Future<Debt?> getDebt(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _debtTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Debt.fromMap(maps.first);
  }

  // Update a debt
  Future<int> updateDebt(Debt debt) async {
    final db = await database;
    final result = await db.update(
      _debtTable,
      debt.toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );

    // Sync to Firebase
    await _syncDebtToFirebase(debt);

    return result;
  }

  // Delete a debt
  Future<int> deleteDebt(int id) async {
    final db = await database;

    // Delete all payments for this debt first
    await db.delete(_debtPaymentTable, where: 'debtId = ?', whereArgs: [id]);

    // Delete the debt
    final result = await db.delete(
      _debtTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Delete from Firebase
    await _deleteDebtFromFirebase(id);

    return result;
  }

  // Insert a debt payment
  Future<int> insertDebtPayment(DebtPayment payment) async {
    final db = await database;
    final id = await db.insert(
      _debtPaymentTable,
      payment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Sync payment to Firebase
    await _syncDebtPaymentToFirebase(payment.copyWith(id: id));

    // Update debt's paidAmount and status
    final debt = await getDebt(payment.debtId);
    if (debt != null) {
      final newPaidAmount = debt.paidAmount + payment.amount;
      String newStatus = 'pending';

      if (newPaidAmount >= debt.amount) {
        newStatus = 'completed';
      } else if (newPaidAmount > 0) {
        newStatus = 'partial';
      }

      await updateDebt(
        debt.copyWith(paidAmount: newPaidAmount, status: newStatus),
      );
    }

    return id;
  }

  // Get all payments for a debt
  Future<List<DebtPayment>> getDebtPayments(int debtId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _debtPaymentTable,
      where: 'debtId = ?',
      whereArgs: [debtId],
      orderBy: 'paymentDate DESC',
    );

    return List.generate(maps.length, (i) {
      return DebtPayment.fromMap(maps[i]);
    });
  }

  // Delete a debt payment
  Future<int> deleteDebtPayment(int id, int debtId, double amount) async {
    final db = await database;

    // Delete the payment
    final result = await db.delete(
      _debtPaymentTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    // Delete from Firebase
    await _deleteDebtPaymentFromFirebase(id, debtId);

    // Update debt's paidAmount and status
    final debt = await getDebt(debtId);
    if (debt != null) {
      final newPaidAmount = (debt.paidAmount - amount).clamp(0.0, debt.amount);
      String newStatus = 'pending';

      if (newPaidAmount >= debt.amount) {
        newStatus = 'completed';
      } else if (newPaidAmount > 0) {
        newStatus = 'partial';
      }

      await updateDebt(
        debt.copyWith(paidAmount: newPaidAmount, status: newStatus),
      );
    }

    return result;
  }

  // Get total lent amount (pending + partial)
  Future<double> getTotalLentAmount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount - paidAmount) as total
      FROM $_debtTable
      WHERE type = 'lent' AND status != 'completed'
    ''');

    return (result.first['total'] as double?) ?? 0.0;
  }

  // Get total borrowed amount (pending + partial)
  Future<double> getTotalBorrowedAmount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount - paidAmount) as total
      FROM $_debtTable
      WHERE type = 'borrowed' AND status != 'completed'
    ''');

    return (result.first['total'] as double?) ?? 0.0;
  }

  // Sync debt to Firebase
  Future<void> _syncDebtToFirebase(Debt debt) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('debts')
            .doc(debt.id.toString())
            .set(debt.toMap());
      }
    } catch (e) {
      print('Error syncing debt to Firebase: $e');
    }
  }

  // Delete debt from Firebase
  Future<void> _deleteDebtFromFirebase(int id) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Delete all payments for this debt
        final paymentsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('debts')
            .doc(id.toString())
            .collection('payments')
            .get();

        for (var doc in paymentsSnapshot.docs) {
          await doc.reference.delete();
        }

        // Delete the debt
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('debts')
            .doc(id.toString())
            .delete();
      }
    } catch (e) {
      print('Error deleting debt from Firebase: $e');
    }
  }

  // Sync debt payment to Firebase
  Future<void> _syncDebtPaymentToFirebase(DebtPayment payment) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('debts')
            .doc(payment.debtId.toString())
            .collection('payments')
            .doc(payment.id.toString())
            .set(payment.toMap());
      }
    } catch (e) {
      print('Error syncing payment to Firebase: $e');
    }
  }

  // Delete debt payment from Firebase
  Future<void> _deleteDebtPaymentFromFirebase(int paymentId, int debtId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('debts')
            .doc(debtId.toString())
            .collection('payments')
            .doc(paymentId.toString())
            .delete();
      }
    } catch (e) {
      print('Error deleting payment from Firebase: $e');
    }
  }
}
