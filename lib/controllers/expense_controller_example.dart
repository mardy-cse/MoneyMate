// Example: How to use ExpenseController in your screens
//
// This file demonstrates how to use the ExpenseController
// with GetX for state management in MoneyMate screens.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';

// Example 1: Using the controller in a StatelessWidget
class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the controller instance
    final ExpenseController controller = Get.find<ExpenseController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Example Screen')),
      body: Column(
        children: [
          // Example: Display today's total (reactive)
          Obx(
            () => Text(
              'Today\'s Total: \$${controller.totalToday.value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 24),
            ),
          ),

          // Example: Display expense count (reactive)
          Obx(() => Text('Total Expenses: ${controller.expenses.length}')),

          // Example: Display list of today's expenses (reactive)
          Expanded(
            child: Obx(() {
              final todayExpenses = controller.getTodayExpenses();

              if (todayExpenses.isEmpty) {
                return const Center(child: Text('No expenses today'));
              }

              return ListView.builder(
                itemCount: todayExpenses.length,
                itemBuilder: (context, index) {
                  final expense = todayExpenses[index];
                  return ListTile(
                    title: Text(expense.title),
                    subtitle: Text(expense.category),
                    trailing: Text('\$${expense.amount.toStringAsFixed(2)}'),
                  );
                },
              );
            }),
          ),

          // Example: Button to add expense
          ElevatedButton(
            onPressed: () {
              final newExpense = Expense(
                title: 'Lunch',
                amount: 12.50,
                category: 'Food',
                date: DateTime.now(),
                note: 'Quick lunch',
              );
              controller.addExpense(newExpense);
            },
            child: const Text('Add Sample Expense'),
          ),

          // Example: Button to refresh data
          ElevatedButton(
            onPressed: () => controller.fetchExpenses(),
            child: const Text('Refresh Expenses'),
          ),
        ],
      ),
    );
  }
}

// Example 2: Using the controller in a StatefulWidget
class AnotherExampleScreen extends StatefulWidget {
  const AnotherExampleScreen({super.key});

  @override
  State<AnotherExampleScreen> createState() => _AnotherExampleScreenState();
}

class _AnotherExampleScreenState extends State<AnotherExampleScreen> {
  late ExpenseController controller;

  @override
  void initState() {
    super.initState();
    // Get the controller instance
    controller = Get.find<ExpenseController>();
    // Optionally fetch fresh data
    controller.fetchExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Another Example')),
      body: Column(
        children: [
          // Display weekly total
          Obx(
            () => Text(
              'Weekly Total: \$${controller.totalWeekly.value.toStringAsFixed(2)}',
            ),
          ),

          // Display monthly total
          Obx(
            () => Text(
              'Monthly Total: \$${controller.totalMonthly.value.toStringAsFixed(2)}',
            ),
          ),

          // Show loading state
          Obx(
            () => controller.isLoading.value
                ? const CircularProgressIndicator()
                : const Text('Data loaded'),
          ),

          // Example: Delete an expense
          Expanded(
            child: Obx(
              () => ListView.builder(
                itemCount: controller.expenses.length,
                itemBuilder: (context, index) {
                  final expense = controller.expenses[index];
                  return ListTile(
                    title: Text(expense.title),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        // Delete expense
                        if (expense.id != null) {
                          controller.deleteExpense(expense.id!);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Example 3: Common GetX patterns

void exampleUsagePatterns() {
  // Get controller instance
  final controller = Get.find<ExpenseController>();

  // 1. Fetch all expenses
  controller.fetchExpenses();

  // 2. Add a new expense
  final expense = Expense(
    title: 'Coffee',
    amount: 4.50,
    category: 'Food',
    date: DateTime.now(),
  );
  controller.addExpense(expense);

  // 3. Update an expense
  final updatedExpense = Expense(
    id: 1,
    title: 'Updated Coffee',
    amount: 5.00,
    category: 'Food',
    date: DateTime.now(),
  );
  controller.updateExpense(updatedExpense);

  // 4. Delete an expense
  controller.deleteExpense(1);

  // 5. Get today's expenses
  final todayExpenses = controller.getTodayExpenses();

  // 6. Get weekly expenses
  final weeklyExpenses = controller.getWeeklyExpenses();

  // 7. Get monthly expenses
  final monthlyExpenses = controller.getMonthlyExpenses();

  // 8. Get expenses by category
  final foodExpenses = controller.getExpensesByCategory('Food');

  // 9. Get expenses by date range
  final rangeExpenses = controller.getExpensesByDateRange(
    DateTime(2025, 11, 1),
    DateTime(2025, 11, 10),
  );

  // 10. Get category totals
  final categoryTotals = controller.getCategoryTotals();

  // 11. Get total expenses
  final totalExpenses = controller.getTotalExpenses();

  // 12. Access reactive values
  print('Today Total: ${controller.totalToday.value}');
  print('Weekly Total: ${controller.totalWeekly.value}');
  print('Monthly Total: ${controller.totalMonthly.value}');
  print('Total Expenses Count: ${controller.expenses.length}');
}

// Example 4: Using Obx for reactive UI updates

class ReactiveExampleWidget extends StatelessWidget {
  const ReactiveExampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpenseController>();

    return Column(
      children: [
        // Obx automatically rebuilds when totalToday changes
        Obx(() => Text('\$${controller.totalToday.value.toStringAsFixed(2)}')),

        // Obx automatically rebuilds when expenses list changes
        Obx(() => Text('${controller.expenses.length} expenses')),

        // Obx with conditional rendering
        Obx(
          () => controller.isLoading.value
              ? const CircularProgressIndicator()
              : const Icon(Icons.check),
        ),

        // GetX can also be used instead of Obx
        GetX<ExpenseController>(
          builder: (controller) => Text(
            'Weekly: \$${controller.totalWeekly.value.toStringAsFixed(2)}',
          ),
        ),
      ],
    );
  }
}
