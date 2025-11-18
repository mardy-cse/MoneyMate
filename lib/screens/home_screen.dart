import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../controllers/expense_controller.dart';
import '../controllers/personalization_controller.dart';
import '../controllers/premium_controller.dart';
import '../controllers/points_controller.dart';
import '../services/currency_service.dart';
import '../services/database_helper.dart';
import '../services/firebase_service.dart';
import '../services/points_service.dart';
import '../widgets/custom_search_bar.dart';
import 'budget_screen.dart';
import 'expense_detail_screen.dart';
import 'cloud_sync_screen.dart';
import 'auth_screen.dart';
import 'notification_screen.dart';
import 'debt_screen.dart';

// Budget Alert Model
class BudgetAlert {
  final String title;
  final double percentage;
  final double spent;
  final double budget;
  final IconData icon;

  BudgetAlert({
    required this.title,
    required this.percentage,
    required this.spent,
    required this.budget,
    required this.icon,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // GlobalKey to access Scaffold state
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Budget alerts
  List<BudgetAlert> _budgetAlerts = [];
  Set<String> _readNotifications = {};

  // Controllers
  final premiumController = Get.find<PremiumController>();
  final pointsController = Get.find<PointsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBudgetAlerts();
    _checkDailyLogin();
    _loadPremiumStatus();
    _setupAuthListener();
    _syncPendingPoints(); // NEW: Sync any pending offline points
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed, refresh points
      pointsController.refreshPoints();
    }
  }

  void _setupAuthListener() {
    // Listen to auth state changes to update premium status
    final firebaseService = Get.find<FirebaseService>();
    ever(firebaseService.currentUser, (_) {
      _loadPremiumStatus();
      _syncPendingPoints(); // Sync when auth state changes
      pointsController.refreshPoints(); // Refresh points display
    });
  }

  Future<void> _syncPendingPoints() async {
    // Sync any points that were earned offline
    try {
      final pointsService = PointsService();
      await pointsService.syncPendingPoints();
    } catch (e) {
      print('Error syncing pending points: $e');
    }
  }

  Future<void> _loadPremiumStatus() async {
    await premiumController.refreshPremiumStatus();
  }

  Future<void> _checkDailyLogin() async {
    final pointsService = PointsService();
    final result = await pointsService.checkDailyLogin();

    if (result['success'] && result['pointsEarned'] > 0) {
      // Delay to avoid overlapping with other notifications
      await Future.delayed(const Duration(milliseconds: 800));
      Get.snackbar(
        '✨ Daily Bonus!',
        'You earned ${result['pointsEarned']} points for logging in today! Total: ${result['totalPoints']} points',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      pointsController
          .refreshPoints(); // Refresh points display after daily bonus
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBudgetAlerts() async {
    // Load read notifications
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('read_notifications') ?? [];
    _readNotifications = readList.toSet();

    final alerts = await _calculateBudgetAlerts();
    setState(() {
      _budgetAlerts = alerts;
    });
  }

  int get _unreadAlertCount {
    // Generate unique IDs for alerts to match with read notifications
    int unreadCount = 0;
    for (final alert in _budgetAlerts) {
      String id = '';
      if (alert.percentage >= 100) {
        id =
            '${alert.title.contains('Daily')
                ? 'daily'
                : alert.title.contains('Weekly')
                ? 'weekly'
                : 'monthly'}_100';
      } else if (alert.percentage >= 75) {
        id =
            '${alert.title.contains('Daily')
                ? 'daily'
                : alert.title.contains('Weekly')
                ? 'weekly'
                : 'monthly'}_75';
      } else if (alert.percentage >= 50) {
        id =
            '${alert.title.contains('Daily')
                ? 'daily'
                : alert.title.contains('Weekly')
                ? 'weekly'
                : 'monthly'}_50';
      } else if (alert.percentage >= 25) {
        id =
            '${alert.title.contains('Daily')
                ? 'daily'
                : alert.title.contains('Weekly')
                ? 'weekly'
                : 'monthly'}_25';
      }
      if (!_readNotifications.contains(id)) {
        unreadCount++;
      }
    }
    return unreadCount;
  }

  Future<List<BudgetAlert>> _calculateBudgetAlerts() async {
    final alerts = <BudgetAlert>[];

    try {
      final prefs = await SharedPreferences.getInstance();
      final expenses = await DatabaseHelper().getExpenses();
      final now = DateTime.now();

      // Daily Budget
      final dailyBudget = prefs.getDouble('daily_budget') ?? 0.0;
      if (dailyBudget > 0) {
        final todayStart = DateTime(now.year, now.month, now.day);
        final dailySpent = expenses
            .where((e) {
              final expenseDate = DateTime(
                e.date.year,
                e.date.month,
                e.date.day,
              );
              return expenseDate.isAtSameMomentAs(todayStart) && e.amount > 0;
            })
            .fold(0.0, (sum, e) => sum + e.amount);

        final dailyPercent = (dailySpent / dailyBudget * 100);
        if (dailyPercent >= 25) {
          alerts.add(
            BudgetAlert(
              title: 'Daily Budget',
              percentage: dailyPercent,
              spent: dailySpent,
              budget: dailyBudget,
              icon: Icons.today,
            ),
          );
        }
      }

      // Weekly Budget
      final weeklyBudget = prefs.getDouble('weekly_budget') ?? 0.0;
      if (weeklyBudget > 0) {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final weekStart = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final weeklySpent = expenses
            .where((e) {
              final expenseDate = DateTime(
                e.date.year,
                e.date.month,
                e.date.day,
              );
              return expenseDate.isAfter(
                    weekStart.subtract(const Duration(days: 1)),
                  ) &&
                  e.amount > 0;
            })
            .fold(0.0, (sum, e) => sum + e.amount);

        final weeklyPercent = (weeklySpent / weeklyBudget * 100);
        if (weeklyPercent >= 25) {
          alerts.add(
            BudgetAlert(
              title: 'Weekly Budget',
              percentage: weeklyPercent,
              spent: weeklySpent,
              budget: weeklyBudget,
              icon: Icons.calendar_view_week,
            ),
          );
        }
      }

      // Monthly Budget
      final monthlyBudget = prefs.getDouble('monthly_budget') ?? 0.0;
      if (monthlyBudget > 0) {
        final monthStart = DateTime(now.year, now.month, 1);
        final monthlySpent = expenses
            .where((e) {
              final expenseDate = DateTime(
                e.date.year,
                e.date.month,
                e.date.day,
              );
              return expenseDate.isAfter(
                    monthStart.subtract(const Duration(days: 1)),
                  ) &&
                  e.amount > 0;
            })
            .fold(0.0, (sum, e) => sum + e.amount);

        final monthlyPercent = (monthlySpent / monthlyBudget * 100);
        if (monthlyPercent >= 25) {
          alerts.add(
            BudgetAlert(
              title: 'Monthly Budget',
              percentage: monthlyPercent,
              spent: monthlySpent,
              budget: monthlyBudget,
              icon: Icons.calendar_month,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error calculating budget alerts: $e');
    }

    return alerts;
  }

  String _formatCurrency(double amount) {
    final currencyService = CurrencyService.instance;
    return currencyService.formatCurrency(amount);
  }

  String _getCategoryName(String category) {
    // Return translated category name
    return category.tr;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt_long;
      case 'entertainment':
        return Icons.movie;
      case 'shopping':
        return Icons.shopping_bag;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Colors.orange;
      case 'transport':
        return Colors.blue;
      case 'bills':
        return Colors.red;
      case 'entertainment':
        return Colors.purple;
      case 'shopping':
        return Colors.pink;
      case 'healthcare':
        return Colors.green;
      case 'education':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the ExpenseController instance
    final ExpenseController controller = Get.find<ExpenseController>();
    final personalizationController = Get.find<PersonalizationController>();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('app_name'.tr),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Points Badge (show always - works offline and for guests)
          Obx(() {
            final points = pointsController.totalPoints.value;

            // Only show if user has points (earned through usage)
            if (points == 0) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  // Navigate to profile (or show login prompt if not signed in)
                  final firebaseService = Get.find<FirebaseService>();
                  final user = firebaseService.currentUser.value;
                  if (user != null) {
                    Get.toNamed('/profile');
                  } else {
                    Get.snackbar(
                      'Sign In Required',
                      'Sign in to redeem your $points points for premium features',
                      backgroundColor: Colors.orange,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 3),
                      mainButton: TextButton(
                        onPressed: () {
                          Get.back(); // Close snackbar
                          Get.toNamed('/auth');
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade600,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, size: 18, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '$points',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          // Budget Notification Icon
          IconButton(
            onPressed: () {
              // Navigate to Notification Screen and reload alerts when returning
              Get.to(() => const NotificationScreen())?.then((_) {
                _loadBudgetAlerts();
              });
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined, size: 24),
                if (_unreadAlertCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _budgetAlerts.any((a) => a.percentage >= 100)
                            ? Colors.red
                            : _budgetAlerts.any((a) => a.percentage >= 75)
                            ? Colors.orange
                            : Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$_unreadAlertCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Budget Notifications',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [
                                Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.5),
                                Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.4),
                              ]
                            : [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // User Profile Section
                        Obx(() {
                          final hasImage = personalizationController
                              .profileImagePath
                              .value
                              .isNotEmpty;

                          return InkWell(
                            onTap: () {
                              Get.toNamed('/profile');
                            },
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: hasImage
                                        ? Image.file(
                                            File(
                                              personalizationController
                                                  .profileImagePath
                                                  .value,
                                            ),
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Center(
                                                    child: Text(
                                                      personalizationController
                                                          .getUserInitials(),
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(
                                                          context,
                                                        ).colorScheme.primary,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : Center(
                                            child: Text(
                                              personalizationController
                                                  .getUserInitials(),
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        personalizationController
                                                .userName
                                                .value
                                                .isNotEmpty
                                            ? personalizationController
                                                  .userName
                                                  .value
                                            : 'Guest User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        personalizationController
                                                .userEmail
                                                .value
                                                .isNotEmpty
                                            ? personalizationController
                                                  .userEmail
                                                  .value
                                            : 'Tap to set up profile',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        // App Info
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'app_name'.tr,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'app_tagline'.tr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    final firebaseService = Get.find<FirebaseService>();
                    final user = firebaseService.currentUser.value;
                    return ListTile(
                      leading: Icon(
                        user == null ? Icons.login : Icons.account_circle,
                        color: user == null ? Colors.amber : Colors.blue,
                      ),
                      title: Text(
                        user == null ? 'Sign In / Sign Up' : 'Account',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: user == null ? Colors.amber : Colors.blue,
                        ),
                      ),
                      subtitle: Text(
                        user == null
                            ? 'Get 50 points on signup!'
                            : user.email ?? 'View account',
                      ),
                      trailing: user == null
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : null,
                      onTap: () async {
                        if (user == null) {
                          // Not signed in - go to Auth screen for sign in/up
                          await Get.to(() => const AuthScreen());
                        } else {
                          // Signed in - go to Profile Settings
                          await Get.toNamed('/profile');
                        }
                        // Keep drawer open after returning
                        Future.delayed(const Duration(milliseconds: 100), () {
                          if (_scaffoldKey.currentState?.isDrawerOpen ==
                              false) {
                            _scaffoldKey.currentState?.openDrawer();
                          }
                        });
                      },
                    );
                  }),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.calendar_month),
                    title: Text('summary'.tr),
                    subtitle: Text('view_summary'.tr),
                    onTap: () async {
                      await Get.toNamed('/monthly-summary');
                      // Keep drawer open after returning
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (_scaffoldKey.currentState?.isDrawerOpen == false) {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.bar_chart),
                    title: Text('analytics'.tr),
                    subtitle: Text('view_spending_analytics'.tr),
                    onTap: () async {
                      await Get.toNamed('/analytics');
                      // Keep drawer open after returning
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (_scaffoldKey.currentState?.isDrawerOpen == false) {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text('history'.tr),
                    subtitle: Text('view_expense_income_history'.tr),
                    onTap: () async {
                      await Get.toNamed('/history');
                      // Keep drawer open after returning
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (_scaffoldKey.currentState?.isDrawerOpen == false) {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet),
                    title: Text('budgets_goals'.tr),
                    subtitle: Text('manage_budgets_savings'.tr),
                    onTap: () async {
                      await Get.to(() => const BudgetScreen());
                      // Keep drawer open after returning
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (_scaffoldKey.currentState?.isDrawerOpen == false) {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      });
                    },
                  ),
                  const Divider(),
                  // Debt/Loan Tracker (Premium Feature)
                  Obx(() {
                    final firebaseService = Get.find<FirebaseService>();
                    final user = firebaseService.currentUser.value;
                    final isPremium = premiumController.isPremium.value;
                    final isEnabled = user != null && isPremium;

                    return ListTile(
                      leading: Icon(
                        Icons.account_balance,
                        color: isEnabled ? null : Colors.grey,
                      ),
                      title: Row(
                        children: [
                          Text(
                            'Debt/Loan Tracker',
                            style: TextStyle(
                              color: isEnabled ? null : Colors.grey,
                            ),
                          ),
                          if (!isEnabled) const SizedBox(width: 8),
                          if (!isEnabled)
                            Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                        ],
                      ),
                      subtitle: Text(
                        isEnabled
                            ? 'Track money lent & borrowed'
                            : user == null
                            ? 'Sign in required'
                            : 'Premium feature - 250 points',
                        style: TextStyle(color: isEnabled ? null : Colors.grey),
                      ),
                      enabled: isEnabled,
                      onTap: isEnabled
                          ? () async {
                              await Get.to(() => const DebtScreen());
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (_scaffoldKey.currentState?.isDrawerOpen ==
                                      false) {
                                    _scaffoldKey.currentState?.openDrawer();
                                  }
                                },
                              );
                            }
                          : () {
                              Get.snackbar(
                                user == null
                                    ? 'Sign In Required'
                                    : 'Premium Feature',
                                user == null
                                    ? 'Please sign in to access premium features'
                                    : 'Collect 250 points to unlock this feature',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                            },
                    );
                  }),
                  // Cloud Backup & Sync (Premium Feature)
                  Obx(() {
                    final firebaseService = Get.find<FirebaseService>();
                    final user = firebaseService.currentUser.value;
                    final isPremium = premiumController.isPremium.value;
                    final isEnabled = user != null && isPremium;

                    return ListTile(
                      leading: Icon(
                        Icons.cloud,
                        color: isEnabled ? null : Colors.grey,
                      ),
                      title: Row(
                        children: [
                          Text(
                            'Cloud Backup & Sync',
                            style: TextStyle(
                              color: isEnabled ? null : Colors.grey,
                            ),
                          ),
                          if (!isEnabled) const SizedBox(width: 8),
                          if (!isEnabled)
                            Icon(
                              Icons.lock,
                              size: 16,
                              color: Colors.amber.shade700,
                            ),
                        ],
                      ),
                      subtitle: Text(
                        isEnabled
                            ? 'Backup and sync your data'
                            : user == null
                            ? 'Sign in required'
                            : 'Premium feature - 250 points',
                        style: TextStyle(color: isEnabled ? null : Colors.grey),
                      ),
                      enabled: isEnabled,
                      onTap: isEnabled
                          ? () async {
                              await Get.to(() => const CloudSyncScreen());
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  if (_scaffoldKey.currentState?.isDrawerOpen ==
                                      false) {
                                    _scaffoldKey.currentState?.openDrawer();
                                  }
                                },
                              );
                            }
                          : () {
                              Get.snackbar(
                                user == null
                                    ? 'Sign In Required'
                                    : 'Premium Feature',
                                user == null
                                    ? 'Please sign in to access premium features'
                                    : 'Collect 250 points to unlock this feature',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                              );
                            },
                    );
                  }),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: Text('settings'.tr),
                    subtitle: Text('app_settings_budget'.tr),
                    onTap: () async {
                      await Get.toNamed('/settings');
                      controller.fetchExpenses();
                      // Keep drawer open after returning
                      Future.delayed(const Duration(milliseconds: 100), () {
                        if (_scaffoldKey.currentState?.isDrawerOpen == false) {
                          _scaffoldKey.currentState?.openDrawer();
                        }
                      });
                    },
                  ),
                  const Divider(),
                  // Sign Out option (only show when user is signed in)
                  Obx(() {
                    final firebaseService = Get.find<FirebaseService>();
                    final user = firebaseService.currentUser.value;
                    if (user != null) {
                      return ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text(
                          'Sign Out',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: const Text('Sign out from your account'),
                        onTap: () async {
                          // Show confirmation dialog
                          final confirm = await Get.dialog<bool>(
                            AlertDialog(
                              title: const Text('Sign Out'),
                              content: const Text(
                                'Are you sure you want to sign out?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(result: false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Get.back(result: true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await firebaseService.signOut();
                              Get.back(); // Close drawer
                              Get.snackbar(
                                'Success',
                                'Signed out successfully',
                                backgroundColor: Colors.green,
                                colorText: Colors.white,
                              );
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'Failed to sign out: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                              );
                            }
                          }
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  }),
                ],
              ),
            ),
            // Version at bottom - outside ListView
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get today's expenses reactively
        final todayExpenses = controller.getTodayExpenses();

        // Filter expenses based on search query
        final filteredExpenses = todayExpenses.where((expense) {
          if (_searchQuery.isEmpty) return true;

          final query = _searchQuery.toLowerCase();
          return expense.title.toLowerCase().contains(query) ||
              expense.category.toLowerCase().contains(query) ||
              (expense.note?.toLowerCase().contains(query) ?? false) ||
              expense.amount.toString().contains(query);
        }).toList();

        final todayTotal = controller.totalToday.value;

        return Column(
          children: [
            // Today's Total Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: Theme.of(context).brightness == Brightness.dark
                      ? [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.5),
                          Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.4),
                        ]
                      : [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(context).colorScheme.secondary,
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'todays_expenses'.tr,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(todayTotal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            if (todayExpenses.isNotEmpty)
              CustomSearchBar(
                controller: _searchController,
                hintText: 'Search expenses...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            if (todayExpenses.isNotEmpty) const SizedBox(height: 16),

            // Expenses List
            Expanded(
              child: filteredExpenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'no_expenses_today'.tr
                                : 'No expenses found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchQuery.isEmpty
                                ? 'tap_to_add_first_expense'.tr
                                : 'Try different search terms',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense = filteredExpenses[index];
                        return Dismissible(
                          key: Key(expense.id.toString()),
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text('delete_expense'.tr),
                                  content: Text(
                                    'Are you sure you want to delete "${expense.title}"?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: Text('cancel'.tr),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: Text('delete'.tr),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) async {
                            await controller.deleteExpense(expense.id!);
                          },
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              onTap: () {
                                Get.to(
                                  () => ExpenseDetailScreen(expense: expense),
                                  transition: Transition.rightToLeft,
                                );
                              },
                              leading: CircleAvatar(
                                backgroundColor: _getCategoryColor(
                                  expense.category,
                                ).withOpacity(0.2),
                                child: Icon(
                                  _getCategoryIcon(expense.category),
                                  color: _getCategoryColor(expense.category),
                                ),
                              ),
                              title: Text(
                                expense.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getCategoryName(expense.category),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat(
                                          'h:mm a',
                                        ).format(expense.date),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (expense.note != null &&
                                      expense.note!.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.note,
                                          size: 14,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            expense.note!,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (expense.voiceNotePath != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.mic,
                                          size: 14,
                                          color: Colors.blue[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'voice_note_attached'.tr,
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (expense.imagePath != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.photo,
                                          size: 14,
                                          color: Colors.green[700],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'image_attached'.tr,
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.touch_app,
                                        size: 12,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'tap_for_details'.tr,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Text(
                                _formatCurrency(expense.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-expense'),
        tooltip: 'add_expense'.tr,
        child: const Icon(Icons.add),
      ),
    );
  }
}
