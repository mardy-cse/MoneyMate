import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/home_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/expense_history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/monthly_summary_screen.dart';
import 'services/database_helper.dart';
import 'controllers/expense_controller.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the database when the app starts
  await DatabaseHelper().database;

  // Initialize GetX controller
  Get.put(ExpenseController());

  runApp(const MoneyMateApp());
}

class MoneyMateApp extends StatelessWidget {
  const MoneyMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'MoneyMate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Initial route
      initialRoute: '/',
      // Define named routes
      getPages: [
        GetPage(name: '/', page: () => const HomeScreen()),
        GetPage(name: '/add-expense', page: () => const AddExpenseScreen()),
        GetPage(name: '/history', page: () => const ExpenseHistoryScreen()),
        GetPage(name: '/analytics', page: () => const AnalyticsScreen()),
        GetPage(name: '/settings', page: () => const SettingsScreen()),
        GetPage(
          name: '/monthly-summary',
          page: () => const MonthlySummaryScreen(),
        ),
      ],
      // Fallback route
      home: const HomeScreen(),
    );
  }
}
