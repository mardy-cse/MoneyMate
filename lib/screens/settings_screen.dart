import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import '../services/language_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _weeklyBudgetController = TextEditingController();
  final _monthlyBudgetController = TextEditingController();

  bool _notificationsEnabled = false;
  bool _isLoading = true;

  double _weeklyBudget = 0.0;
  double _monthlyBudget = 0.0;
  double _weeklySpent = 0.0;
  double _monthlySpent = 0.0;

  static const String _weeklyBudgetKey = 'weekly_budget';
  static const String _monthlyBudgetKey = 'monthly_budget';
  static const String _notificationsKey = 'notifications_enabled';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _weeklyBudgetController.dispose();
    _monthlyBudgetController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load budgets
      _weeklyBudget = prefs.getDouble(_weeklyBudgetKey) ?? 0.0;
      _monthlyBudget = prefs.getDouble(_monthlyBudgetKey) ?? 0.0;
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? false;

      // Set controllers
      _weeklyBudgetController.text = _weeklyBudget > 0
          ? _weeklyBudget.toString()
          : '';
      _monthlyBudgetController.text = _monthlyBudget > 0
          ? _monthlyBudget.toString()
          : '';

      // Calculate spending
      await _calculateSpending();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _calculateSpending() async {
    try {
      final expenses = await DatabaseHelper().getExpenses();
      final now = DateTime.now();

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
            );
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
            );
          })
          .fold(0.0, (sum, expense) => sum + expense.amount);

      setState(() {});
    } catch (e) {
      debugPrint('Error calculating spending: $e');
    }
  }

  Future<void> _saveBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Parse and save weekly budget
      final weeklyValue =
          double.tryParse(_weeklyBudgetController.text.trim()) ?? 0.0;
      await prefs.setDouble(_weeklyBudgetKey, weeklyValue);

      // Parse and save monthly budget
      final monthlyValue =
          double.tryParse(_monthlyBudgetController.text.trim()) ?? 0.0;
      await prefs.setDouble(_monthlyBudgetKey, monthlyValue);

      setState(() {
        _weeklyBudget = weeklyValue;
        _monthlyBudget = monthlyValue;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Budgets saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving budgets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, value);

      setState(() {
        _notificationsEnabled = value;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Notifications enabled' : 'Notifications disabled',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    final currencyService = CurrencyService.instance;
    return currencyService.formatCurrency(amount);
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

  Widget _buildBudgetCard({
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
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 12,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              const SizedBox(height: 12),

              // Stats
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GetBuilder<LanguageService>(builder: (_) => Text('settings'.tr)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSettings,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personalization Section
                    const Text(
                      'Personalization',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(
                              Icons.person,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('My Profile'),
                            subtitle: const Text(
                              'Manage your personal information',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => Get.toNamed('/profile'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.palette,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Theme & Colors'),
                            subtitle: const Text('Customize app appearance'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => Get.toNamed('/theme-customization'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Budget Status Section
                    const Text(
                      'Budget Status',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildBudgetCard(
                      title: 'Weekly Budget',
                      period: 'this week',
                      budget: _weeklyBudget,
                      spent: _weeklySpent,
                      icon: Icons.calendar_view_week,
                    ),

                    const SizedBox(height: 16),

                    _buildBudgetCard(
                      title: 'Monthly Budget',
                      period: 'this month',
                      budget: _monthlyBudget,
                      spent: _monthlySpent,
                      icon: Icons.calendar_month,
                    ),

                    const SizedBox(height: 32),

                    // Language & Currency Section
                    Text(
                      'currency'.tr,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          // Language Selection - COMMENTED OUT TEMPORARILY
                          /* 
                          ListTile(
                            leading: Icon(
                              Icons.language,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text('language'.tr),
                            subtitle: Obx(() {
                              final languageService = LanguageService.instance;
                              return Text(
                                languageService.getLanguageName(
                                  languageService.selectedLanguage.value,
                                ),
                              );
                            }),
                            trailing: Obx(() {
                              final languageService = LanguageService.instance;
                              return DropdownButton<String>(
                                value: languageService.selectedLanguage.value,
                                underline: const SizedBox(),
                                items: languageService.getLanguageCodes().map((
                                  code,
                                ) {
                                  return DropdownMenuItem(
                                    value: code,
                                    child: Row(
                                      children: [
                                        Text(
                                          languageService.getLanguageFlag(code),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          languageService.getLanguageName(code),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    languageService.saveLanguage(value);
                                  }
                                },
                              );
                            }),
                          ),
                          const Divider(height: 1),
                          */
                          // Currency Selection
                          ListTile(
                            leading: Obx(() {
                              final currencyService = CurrencyService.instance;
                              return Text(
                                currencyService.selectedCurrencySymbol.value,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              );
                            }),
                            title: Text('currency'.tr),
                            subtitle: Obx(() {
                              final currencyService = CurrencyService.instance;
                              return Text(
                                currencyService.getCurrencyName(
                                  currencyService.selectedCurrency.value,
                                ),
                              );
                            }),
                            trailing: Obx(() {
                              final currencyService = CurrencyService.instance;
                              return DropdownButton<String>(
                                value: currencyService.selectedCurrency.value,
                                underline: const SizedBox(),
                                items: currencyService.getCurrencyCodes().map((
                                  code,
                                ) {
                                  return DropdownMenuItem(
                                    value: code,
                                    child: Row(
                                      children: [
                                        Text(
                                          currencyService
                                                  .currencies[code]?['symbol'] ??
                                              '',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(code),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  if (value != null) {
                                    await currencyService.saveCurrency(value);
                                    // Reload settings to update displayed amounts
                                    _loadSettings();
                                  }
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Budget Settings Section
                    const Text(
                      'Set Budgets',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
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
                              onPressed: _saveBudgets,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Save Budgets',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Notifications Section
                    const Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Budget Limit Notifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _notificationsEnabled
                              ? 'You\'ll be notified when approaching budget limits'
                              : 'Enable to receive budget alerts',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        secondary: Icon(
                          _notificationsEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
