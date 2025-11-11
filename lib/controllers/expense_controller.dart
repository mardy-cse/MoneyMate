import 'package:get/get.dart';
import '../models/expense.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';

class ExpenseController extends GetxController {
  // Observable list of expenses
  final RxList<Expense> expenses = <Expense>[].obs;

  // Observable total for today
  final RxDouble totalToday = 0.0.obs;

  // Observable totals for weekly and monthly
  final RxDouble totalWeekly = 0.0.obs;
  final RxDouble totalMonthly = 0.0.obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Firebase service - lazy getter
  FirebaseService? get _firebaseService {
    try {
      return Get.find<FirebaseService>();
    } catch (e) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchExpenses();
  }

  /// Fetch all expenses from database and update the list
  Future<void> fetchExpenses() async {
    try {
      isLoading.value = true;
      final fetchedExpenses = await DatabaseHelper().getExpenses();
      expenses.value = fetchedExpenses;
      _calculateTotals();
      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to fetch expenses: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Add a new expense to database and update the list
  Future<void> addExpense(Expense expense) async {
    try {
      final id = await DatabaseHelper().insertExpense(expense);

      // Create a new expense with the generated ID
      final newExpense = Expense(
        id: id,
        title: expense.title,
        amount: expense.amount,
        category: expense.category,
        date: expense.date,
        note: expense.note,
      );

      expenses.insert(0, newExpense); // Add to beginning of list
      _calculateTotals();

      // Auto sync to cloud if enabled (null-safe)
      _firebaseService?.autoSyncExpense(newExpense);

      // No snackbar here - let the screen handle UI feedback
    } catch (e) {
      // Just rethrow the error, let the screen handle it
      rethrow;
    }
  }

  /// Delete an expense from database and update the list
  Future<void> deleteExpense(int id) async {
    try {
      await DatabaseHelper().deleteExpense(id);
      expenses.removeWhere((expense) => expense.id == id);
      _calculateTotals();

      // Delete from cloud if synced (null-safe)
      _firebaseService?.deleteExpenseFromCloud(id);

      Get.snackbar(
        'Success',
        'Expense deleted successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete expense: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Update an expense in database and update the list
  Future<void> updateExpense(Expense expense) async {
    try {
      await DatabaseHelper().updateExpense(expense);

      // Find and update the expense in the list
      final index = expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        expenses[index] = expense;
        expenses.refresh(); // Notify observers
        _calculateTotals();
      }

      Get.snackbar(
        'Success',
        'Expense updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update expense: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Get today's expenses
  List<Expense> getTodayExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      // Only return actual expenses (positive amounts), not income (negative amounts)
      return expenseDate.isAtSameMomentAs(today) && expense.amount > 0;
    }).toList();
  }

  /// Get this week's expenses
  List<Expense> getWeeklyExpenses() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekStart = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return expenseDate.isAfter(weekStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Get this month's expenses
  List<Expense> getMonthlyExpenses() {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return expenseDate.isAfter(monthStart.subtract(const Duration(days: 1)));
    }).toList();
  }

  /// Get expenses by category
  List<Expense> getExpensesByCategory(String category) {
    return expenses.where((expense) => expense.category == category).toList();
  }

  /// Get expenses by date range
  List<Expense> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      return expenseDate.isAfter(start.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  /// Calculate today's, weekly, and monthly totals
  void _calculateTotals() {
    // Calculate today's total (only expenses, not income)
    final todayExpenses = getTodayExpenses();
    totalToday.value = todayExpenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    // Calculate weekly total (only expenses, not income)
    final weeklyExpenses = getWeeklyExpenses();
    totalWeekly.value = weeklyExpenses
        .where((e) => e.amount > 0)
        .fold(0.0, (sum, expense) => sum + expense.amount);

    // Calculate monthly total (only expenses, not income)
    final monthlyExpenses = getMonthlyExpenses();
    totalMonthly.value = monthlyExpenses
        .where((e) => e.amount > 0)
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get total expenses for all time
  double getTotalExpenses() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  /// Get category totals
  Map<String, double> getCategoryTotals() {
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }

  /// Clear all expenses (useful for testing)
  Future<void> clearAllExpenses() async {
    try {
      await DatabaseHelper().clearAllExpenses();
      expenses.clear();
      _calculateTotals();

      Get.snackbar(
        'Success',
        'All expenses cleared!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to clear expenses: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
