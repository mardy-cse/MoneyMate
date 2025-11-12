import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/budget.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import '../controllers/expense_controller.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final controller = Get.find<ExpenseController>();
  List<Budget> budgets = [];
  List<SavingGoal> goals = [];
  bool isLoading = true;

  // Daily, Weekly, Monthly budgets
  final _dailyBudgetController = TextEditingController();
  final _weeklyBudgetController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();

  double _dailyBudget = 0.0;
  double _weeklyBudget = 0.0;
  double _monthlyBudget = 0.0;
  double _dailySpent = 0.0;
  double _weeklySpent = 0.0;
  double _monthlySpent = 0.0;

  static const String _dailyBudgetKey = 'daily_budget';
  static const String _weeklyBudgetKey = 'weekly_budget';
  static const String _monthlyBudgetKey = 'monthly_budget';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dailyBudgetController.dispose();
    _weeklyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load daily, weekly, monthly budgets
      _dailyBudget = prefs.getDouble(_dailyBudgetKey) ?? 0.0;
      _weeklyBudget = prefs.getDouble(_weeklyBudgetKey) ?? 0.0;
      _monthlyBudget = prefs.getDouble(_monthlyBudgetKey) ?? 0.0;

      // Set controllers
      _dailyBudgetController.text = _dailyBudget > 0
          ? _dailyBudget.toString()
          : '';
      _weeklyBudgetController.text = _weeklyBudget > 0
          ? _weeklyBudget.toString()
          : '';
      _monthlyBudgetController.text = _monthlyBudget > 0
          ? _monthlyBudget.toString()
          : '';

      // Calculate spending
      await _calculateSpending();

      final loadedBudgets = await DatabaseHelper().getBudgets();
      final loadedGoals = await DatabaseHelper().getGoals();
      setState(() {
        budgets = loadedBudgets;
        goals = loadedGoals;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      Get.snackbar('Error', 'Failed to load data: $e');
    }
  }

  String _formatCurrency(double amount) {
    final currencyService = CurrencyService.instance;
    return currencyService.formatCurrency(amount);
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 70) return Colors.green;
    if (percentage < 90) return Colors.orange;
    return Colors.red;
  }

  // Calculate daily, weekly, monthly spending
  Future<void> _calculateSpending() async {
    try {
      final expenses = await DatabaseHelper().getExpenses();
      final now = DateTime.now();

      // Calculate daily spending (today)
      final todayStart = DateTime(now.year, now.month, now.day);

      _dailySpent = expenses
          .where((expense) {
            final expenseDate = DateTime(
              expense.date.year,
              expense.date.month,
              expense.date.day,
            );
            return expenseDate.isAtSameMomentAs(todayStart) &&
                expense.amount > 0;
          })
          .fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate weekly spending (this week)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final weekStart = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      _weeklySpent = expenses
          .where((expense) {
            final expenseDate = DateTime(
              expense.date.year,
              expense.date.month,
              expense.date.day,
            );
            return expenseDate.isAfter(
                  weekStart.subtract(const Duration(days: 1)),
                ) &&
                expense.amount > 0;
          })
          .fold(0.0, (sum, expense) => sum + expense.amount);

      // Calculate monthly spending (this month)
      final monthStart = DateTime(now.year, now.month, 1);

      _monthlySpent = expenses
          .where((expense) {
            final expenseDate = DateTime(
              expense.date.year,
              expense.date.month,
              expense.date.day,
            );
            return expenseDate.isAfter(
                  monthStart.subtract(const Duration(days: 1)),
                ) &&
                expense.amount > 0;
          })
          .fold(0.0, (sum, expense) => sum + expense.amount);

      setState(() {});
    } catch (e) {
      debugPrint('Error calculating spending: $e');
    }
  }

  Future<void> _savePeriodBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Parse and save daily budget
      final dailyValue =
          double.tryParse(_dailyBudgetController.text.trim()) ?? 0.0;
      await prefs.setDouble(_dailyBudgetKey, dailyValue);

      // Parse and save weekly budget
      final weeklyValue =
          double.tryParse(_weeklyBudgetController.text.trim()) ?? 0.0;
      await prefs.setDouble(_weeklyBudgetKey, weeklyValue);

      // Parse and save monthly budget
      final monthlyValue =
          double.tryParse(_monthlyBudgetController.text.trim()) ?? 0.0;
      await prefs.setDouble(_monthlyBudgetKey, monthlyValue);

      setState(() {
        _dailyBudget = dailyValue;
        _weeklyBudget = weeklyValue;
        _monthlyBudget = monthlyValue;
      });

      // Sync to Firebase
      await _syncPeriodBudgetsToFirebase(
        dailyValue,
        weeklyValue,
        monthlyValue,
      );

      Get.snackbar(
        'Success',
        'Budgets saved successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error saving budgets: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Sync period budgets to Firebase
  Future<void> _syncPeriodBudgetsToFirebase(
    double daily,
    double weekly,
    double monthly,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('period_budgets')
            .doc('current')
            .set({
          'daily_budget': daily,
          'weekly_budget': weekly,
          'monthly_budget': monthly,
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error syncing period budgets to Firebase: $e');
    }
  }

  double _getPercentage(double spent, double budget) {
    if (budget <= 0) return 0;
    return (spent / budget * 100).clamp(0, 100);
  }

  Color _getStatusColor(double spent, double budget) {
    if (budget <= 0) return Colors.grey;
    final percentage = spent / budget;
    if (percentage >= 1.0) return Colors.red;
    if (percentage >= 0.8) return Colors.orange;
    return Colors.green;
  }

  // Calculate spending for a category
  Future<double> _getCategorySpending(String category, String period) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    if (period == 'weekly') {
      // Calculate weekly spending (this week)
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      startDate = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
    } else {
      // Monthly (default)
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    final expenses = await DatabaseHelper().getExpensesByDateRange(
      startDate,
      endDate,
    );

    // Debug: Print all expenses
    debugPrint('=== Budget Category: $category, Period: $period ===');
    debugPrint('Date Range: $startDate to $endDate');
    debugPrint('Total expenses count: ${expenses.length}');

    for (var expense in expenses) {
      debugPrint(
        'Expense: ${expense.title}, Category: ${expense.category}, Amount: ${expense.amount}, Date: ${expense.date}',
      );
    }

    if (category == 'Overall') {
      // Only sum expenses (positive amounts), not income
      final total = expenses
          .where((e) => e.amount > 0)
          .fold<double>(0.0, (sum, expense) => sum + expense.amount);
      debugPrint('Overall spending: $total');
      return total;
    }

    // Only sum expenses (positive amounts) for the category
    // Use case-insensitive comparison
    final categoryLower = category.toLowerCase();
    final filteredExpenses = expenses.where((e) {
      final match = e.category.toLowerCase() == categoryLower && e.amount > 0;
      if (match) {
        debugPrint('Matched expense: ${e.title}, ${e.category}, ${e.amount}');
      }
      return match;
    });

    final total = filteredExpenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    debugPrint('$category spending: $total');
    return total;
  }

  void _showAddBudgetDialog() {
    final amountController = TextEditingController();
    String selectedCategory = 'Overall';
    String selectedPeriod = 'monthly';

    final categories = [
      'Overall',
      'Food',
      'Transport',
      'Bills',
      'Entertainment',
      'Shopping',
      'Healthcare',
      'Education',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Budget'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'amount'.tr,
                  border: const OutlineInputBorder(),
                  prefixIcon: Obx(() {
                    final currencyService = CurrencyService.instance;
                    return Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        currencyService.selectedCurrencySymbol.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedPeriod,
                decoration: const InputDecoration(
                  labelText: 'Period',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                ],
                onChanged: (value) {
                  selectedPeriod = value!;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (amountController.text.isEmpty) {
                Get.snackbar('Error', 'Please enter an amount');
                return;
              }

              final budget = Budget(
                category: selectedCategory,
                amount: double.parse(amountController.text),
                period: selectedPeriod,
                createdAt: DateTime.now(),
              );

              await DatabaseHelper().insertBudget(budget);
              Navigator.pop(context);
              _loadData();

              Get.snackbar(
                'Success',
                'Budget added successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final currentAmountController = TextEditingController(text: '0');
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 30));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Saving Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., Save for new phone',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(
                    labelText: 'target_amount'.tr,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.flag),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: currentAmountController,
                  decoration: InputDecoration(
                    labelText: 'current_savings'.tr,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d+\.?\d{0,2}'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Deadline'),
                  subtitle: Text(
                    DateFormat('MMM d, yyyy').format(selectedDeadline),
                  ),
                  trailing: const Icon(Icons.edit),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedDeadline = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    amountController.text.isEmpty) {
                  Get.snackbar('Error', 'Please fill all required fields');
                  return;
                }

                final goal = SavingGoal(
                  title: titleController.text,
                  targetAmount: double.parse(amountController.text),
                  currentAmount: double.parse(currentAmountController.text),
                  deadline: selectedDeadline,
                  createdAt: DateTime.now(),
                );

                await DatabaseHelper().insertGoal(goal);
                Navigator.pop(context);
                _loadData();

                Get.snackbar(
                  'Success',
                  'Goal added successfully',
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodBudgetCard({
    required String title,
    required String period,
    required double budget,
    required double spent,
    required IconData icon,
  }) {
    final percentage = _getPercentage(spent, budget);
    final statusColor = _getStatusColor(spent, budget);
    final remaining = budget - spent;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: statusColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (budget > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spent',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(spent),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Budget',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(budget),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Remaining',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(remaining),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: remaining >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${percentage.toStringAsFixed(1)}% of budget used',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Text(
                'No budget set for $period',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    return FutureBuilder<double>(
      future: _getCategorySpending(budget.category, budget.period),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            child: Container(
              height: 150,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
          );
        }

        final spending = snapshot.data!;
        final percentage = (spending / budget.amount * 100).clamp(0.0, 100.0);
        final remaining = budget.amount - spending;
        final color = _getProgressColor(percentage);

        // Check if budget exceeded 90%
        if (percentage >= 90 && percentage < 100) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Get.snackbar(
                '⚠️ Budget Alert',
                '${budget.category} budget is ${percentage.toStringAsFixed(0)}% used!',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
                duration: const Duration(seconds: 3),
              );
            }
          });
        }

        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.category,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              budget.period == 'monthly' ? 'Monthly' : 'Weekly',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Budget'),
                            content: const Text(
                              'Are you sure you want to delete this budget?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await DatabaseHelper().deleteBudget(budget.id!);
                          _loadData();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Spent',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatCurrency(spending),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Budget',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          _formatCurrency(budget.amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${percentage.toStringAsFixed(1)}% used',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      remaining >= 0
                          ? 'Remaining: ${_formatCurrency(remaining)}'
                          : 'Over by: ${_formatCurrency(remaining.abs())}',
                      style: TextStyle(
                        fontSize: 12,
                        color: remaining >= 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoalCard(SavingGoal goal) {
    final progress = goal.getProgress();
    final weeklySavings = goal.getWeeklySavingsRequired();
    final daysLeft = goal.deadline.difference(DateTime.now()).inDays;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.savings, color: Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Due: ${DateFormat('MMM d, yyyy').format(goal.deadline)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'update',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 20),
                          SizedBox(width: 8),
                          Text('Update Progress'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Goal'),
                          content: const Text(
                            'Are you sure you want to delete this goal?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await DatabaseHelper().deleteGoal(goal.id!);
                        _loadData();
                      }
                    } else if (value == 'update') {
                      _showUpdateGoalDialog(goal);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatCurrency(goal.currentAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Text(
                      _formatCurrency(goal.targetAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save per week',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        _formatCurrency(weeklySavings),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Days left',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      Text(
                        '$daysLeft days',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: daysLeft < 30 ? Colors.red : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateGoalDialog(SavingGoal goal) {
    final currentAmountController = TextEditingController(
      text: goal.currentAmount.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Progress'),
        content: TextField(
          controller: currentAmountController,
          decoration: InputDecoration(
            labelText: 'current_amount'.tr,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.account_balance_wallet),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedGoal = SavingGoal(
                id: goal.id,
                title: goal.title,
                targetAmount: goal.targetAmount,
                currentAmount: double.parse(currentAmountController.text),
                deadline: goal.deadline,
                createdAt: goal.createdAt,
              );

              await DatabaseHelper().updateGoal(updatedGoal);
              Navigator.pop(context);
              _loadData();

              Get.snackbar(
                'Success',
                'Goal updated successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets & Goals'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Budgets Section (Daily, Weekly, Monthly)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Period Budgets',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Budget Status Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildPeriodBudgetCard(
                            title: 'Daily Budget',
                            period: 'today',
                            budget: _dailyBudget,
                            spent: _dailySpent,
                            icon: Icons.today,
                          ),
                          const SizedBox(height: 12),
                          _buildPeriodBudgetCard(
                            title: 'Weekly Budget',
                            period: 'this week',
                            budget: _weeklyBudget,
                            spent: _weeklySpent,
                            icon: Icons.calendar_view_week,
                          ),
                          const SizedBox(height: 12),
                          _buildPeriodBudgetCard(
                            title: 'Monthly Budget',
                            period: 'this month',
                            budget: _monthlyBudget,
                            spent: _monthlySpent,
                            icon: Icons.calendar_month,
                          ),
                        ],
                      ),
                    ),

                    // Set Period Budgets Input Section
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Set Period Budgets',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Daily Budget Input
                              TextField(
                                controller: _dailyBudgetController,
                                decoration: InputDecoration(
                                  labelText: 'Daily Budget',
                                  hintText: 'Enter daily budget',
                                  prefixIcon: Obx(() {
                                    final currencyService =
                                        CurrencyService.instance;
                                    return Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        currencyService
                                            .selectedCurrencySymbol
                                            .value,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Weekly Budget Input
                              TextField(
                                controller: _weeklyBudgetController,
                                decoration: InputDecoration(
                                  labelText: 'Weekly Budget',
                                  hintText: 'Enter weekly budget',
                                  prefixIcon: Obx(() {
                                    final currencyService =
                                        CurrencyService.instance;
                                    return Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        currencyService
                                            .selectedCurrencySymbol
                                            .value,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Monthly Budget Input
                              TextField(
                                controller: _monthlyBudgetController,
                                decoration: InputDecoration(
                                  labelText: 'Monthly Budget',
                                  hintText: 'Enter monthly budget',
                                  prefixIcon: Obx(() {
                                    final currencyService =
                                        CurrencyService.instance;
                                    return Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Text(
                                        currencyService
                                            .selectedCurrencySymbol
                                            .value,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }),
                                  border: const OutlineInputBorder(),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d+\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Save Button
                              ElevatedButton(
                                onPressed: _savePeriodBudgets,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Save Period Budgets',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Divider(thickness: 2),
                    const SizedBox(height: 8),

                    // ==================== Category Budgets Section (COMMENTED) ====================
                    /*
                    // Category Budgets Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Category Budgets',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddBudgetDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (budgets.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No budgets set',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...budgets.map((budget) => _buildBudgetCard(budget)),

                    const SizedBox(height: 24),
                    const Divider(),
                    */
                    // ==================== End of Category Budgets Section ====================

                    // Goals Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.savings,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Saving Goals',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _showAddGoalDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (goals.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.savings_outlined,
                                size: 80,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No saving goals yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...goals.map((goal) => _buildGoalCard(goal)),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}
