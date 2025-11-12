import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import '../services/currency_service.dart';
import 'budget_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<BudgetNotification> _notifications = [];
  Set<String> _readNotifications = {}; // Track read notification IDs
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReadNotifications();
    _loadNotifications();
  }

  Future<void> _loadReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final readList = prefs.getStringList('read_notifications') ?? [];
      setState(() {
        _readNotifications = Set.from(readList);
      });
    } catch (e) {
      debugPrint('Error loading read notifications: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      _readNotifications.add(notificationId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'read_notifications',
        _readNotifications.toList(),
      );
      setState(() {});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _clearAllReadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('read_notifications');
      setState(() {
        _readNotifications.clear();
      });
    } catch (e) {
      debugPrint('Error clearing read notifications: $e');
    }
  }

  int get _unreadCount {
    return _notifications
        .where((n) => !_readNotifications.contains(n.id))
        .length;
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    final notifications = await _calculateBudgetNotifications();

    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<List<BudgetNotification>> _calculateBudgetNotifications() async {
    final notifications = <BudgetNotification>[];

    try {
      final prefs = await SharedPreferences.getInstance();
      final expenses = await DatabaseHelper().getExpenses();
      final now = DateTime.now();

      // Daily Budget Notifications
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

        // Add notifications at 25%, 50%, 75%, 100%
        if (dailyPercent >= 100) {
          notifications.add(
            BudgetNotification(
              id: 'daily_100',
              title: 'Daily Budget Exceeded!',
              message:
                  'You have exceeded your daily budget by ${_formatCurrency(dailySpent - dailyBudget)}',
              percentage: dailyPercent,
              spent: dailySpent,
              budget: dailyBudget,
              type: 'daily',
              severity: NotificationSeverity.critical,
              icon: Icons.error,
              time: DateTime.now(),
            ),
          );
        } else if (dailyPercent >= 75) {
          notifications.add(
            BudgetNotification(
              id: 'daily_75',
              title: 'Daily Budget Alert',
              message:
                  'You have used ${dailyPercent.toStringAsFixed(0)}% of your daily budget',
              percentage: dailyPercent,
              spent: dailySpent,
              budget: dailyBudget,
              type: 'daily',
              severity: NotificationSeverity.high,
              icon: Icons.warning_amber,
              time: DateTime.now(),
            ),
          );
        } else if (dailyPercent >= 50) {
          notifications.add(
            BudgetNotification(
              id: 'daily_50',
              title: 'Daily Budget Warning',
              message:
                  'You have used ${dailyPercent.toStringAsFixed(0)}% of your daily budget',
              percentage: dailyPercent,
              spent: dailySpent,
              budget: dailyBudget,
              type: 'daily',
              severity: NotificationSeverity.medium,
              icon: Icons.info,
              time: DateTime.now(),
            ),
          );
        } else if (dailyPercent >= 25) {
          notifications.add(
            BudgetNotification(
              id: 'daily_25',
              title: 'Daily Budget Info',
              message:
                  'You have used ${dailyPercent.toStringAsFixed(0)}% of your daily budget',
              percentage: dailyPercent,
              spent: dailySpent,
              budget: dailyBudget,
              type: 'daily',
              severity: NotificationSeverity.low,
              icon: Icons.notifications,
              time: DateTime.now(),
            ),
          );
        }
      }

      // Weekly Budget Notifications
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

        if (weeklyPercent >= 100) {
          notifications.add(
            BudgetNotification(
              id: 'weekly_100',
              title: 'Weekly Budget Exceeded!',
              message:
                  'You have exceeded your weekly budget by ${_formatCurrency(weeklySpent - weeklyBudget)}',
              percentage: weeklyPercent,
              spent: weeklySpent,
              budget: weeklyBudget,
              type: 'weekly',
              severity: NotificationSeverity.critical,
              icon: Icons.error,
              time: DateTime.now(),
            ),
          );
        } else if (weeklyPercent >= 75) {
          notifications.add(
            BudgetNotification(
              id: 'weekly_75',
              title: 'Weekly Budget Alert',
              message:
                  'You have used ${weeklyPercent.toStringAsFixed(0)}% of your weekly budget',
              percentage: weeklyPercent,
              spent: weeklySpent,
              budget: weeklyBudget,
              type: 'weekly',
              severity: NotificationSeverity.high,
              icon: Icons.warning_amber,
              time: DateTime.now(),
            ),
          );
        } else if (weeklyPercent >= 50) {
          notifications.add(
            BudgetNotification(
              id: 'weekly_50',
              title: 'Weekly Budget Warning',
              message:
                  'You have used ${weeklyPercent.toStringAsFixed(0)}% of your weekly budget',
              percentage: weeklyPercent,
              spent: weeklySpent,
              budget: weeklyBudget,
              type: 'weekly',
              severity: NotificationSeverity.medium,
              icon: Icons.info,
              time: DateTime.now(),
            ),
          );
        } else if (weeklyPercent >= 25) {
          notifications.add(
            BudgetNotification(
              id: 'weekly_25',
              title: 'Weekly Budget Info',
              message:
                  'You have used ${weeklyPercent.toStringAsFixed(0)}% of your weekly budget',
              percentage: weeklyPercent,
              spent: weeklySpent,
              budget: weeklyBudget,
              type: 'weekly',
              severity: NotificationSeverity.low,
              icon: Icons.notifications,
              time: DateTime.now(),
            ),
          );
        }
      }

      // Monthly Budget Notifications
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

        if (monthlyPercent >= 100) {
          notifications.add(
            BudgetNotification(
              id: 'monthly_100',
              title: 'Monthly Budget Exceeded!',
              message:
                  'You have exceeded your monthly budget by ${_formatCurrency(monthlySpent - monthlyBudget)}',
              percentage: monthlyPercent,
              spent: monthlySpent,
              budget: monthlyBudget,
              type: 'monthly',
              severity: NotificationSeverity.critical,
              icon: Icons.error,
              time: DateTime.now(),
            ),
          );
        } else if (monthlyPercent >= 75) {
          notifications.add(
            BudgetNotification(
              id: 'monthly_75',
              title: 'Monthly Budget Alert',
              message:
                  'You have used ${monthlyPercent.toStringAsFixed(0)}% of your monthly budget',
              percentage: monthlyPercent,
              spent: monthlySpent,
              budget: monthlyBudget,
              type: 'monthly',
              severity: NotificationSeverity.high,
              icon: Icons.warning_amber,
              time: DateTime.now(),
            ),
          );
        } else if (monthlyPercent >= 50) {
          notifications.add(
            BudgetNotification(
              id: 'monthly_50',
              title: 'Monthly Budget Warning',
              message:
                  'You have used ${monthlyPercent.toStringAsFixed(0)}% of your monthly budget',
              percentage: monthlyPercent,
              spent: monthlySpent,
              budget: monthlyBudget,
              type: 'monthly',
              severity: NotificationSeverity.medium,
              icon: Icons.info,
              time: DateTime.now(),
            ),
          );
        } else if (monthlyPercent >= 25) {
          notifications.add(
            BudgetNotification(
              id: 'monthly_25',
              title: 'Monthly Budget Info',
              message:
                  'You have used ${monthlyPercent.toStringAsFixed(0)}% of your monthly budget',
              percentage: monthlyPercent,
              spent: monthlySpent,
              budget: monthlyBudget,
              type: 'monthly',
              severity: NotificationSeverity.low,
              icon: Icons.notifications,
              time: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error calculating notifications: $e');
    }

    // Sort by severity (critical first)
    notifications.sort((a, b) => b.severity.index.compareTo(a.severity.index));

    return notifications;
  }

  String _formatCurrency(double amount) {
    final currencyService = CurrencyService.instance;
    return currencyService.formatCurrency(amount);
  }

  Color _getSeverityColor(NotificationSeverity severity) {
    switch (severity) {
      case NotificationSeverity.critical:
        return Colors.red;
      case NotificationSeverity.high:
        return Colors.orange;
      case NotificationSeverity.medium:
        return Colors.amber;
      case NotificationSeverity.low:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'daily':
        return Icons.today;
      case 'weekly':
        return Icons.calendar_view_week;
      case 'monthly':
        return Icons.calendar_month;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _loadNotifications,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_off_outlined,
                            size: 100,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No Notifications',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'All your budgets are under control! 🎉',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () => Get.to(() => const BudgetScreen()),
                            icon: const Icon(Icons.account_balance_wallet),
                            label: const Text('Manage Budgets'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final color = _getSeverityColor(notification.severity);
                        final typeIcon = _getTypeIcon(notification.type);
                        final isRead = _readNotifications.contains(
                          notification.id,
                        );

                        return Opacity(
                          opacity: isRead ? 0.5 : 1.0,
                          child: Card(
                            elevation: 3,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: color.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                // Mark as read
                                _markAsRead(notification.id);
                                // Show detailed dialog
                                _showNotificationDetails(notification);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            notification.icon,
                                            color: color,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    typeIcon,
                                                    size: 16,
                                                    color: Colors.grey,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    notification.type
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                notification.title,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '${notification.percentage.toStringAsFixed(0)}%',
                                            style: TextStyle(
                                              color: color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      notification.message,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: (notification.percentage / 100)
                                            .clamp(0.0, 1.0),
                                        minHeight: 12,
                                        backgroundColor: Colors.grey[300],
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              color,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Spent',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              _formatCurrency(
                                                notification.spent,
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: color,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Budget',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              _formatCurrency(
                                                notification.budget,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'Remaining',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            Text(
                                              _formatCurrency(
                                                notification.budget -
                                                    notification.spent,
                                              ),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    notification.budget -
                                                            notification
                                                                .spent >=
                                                        0
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: _notifications.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => Get.to(() => const BudgetScreen()),
              icon: const Icon(Icons.settings),
              label: const Text('Manage Budgets'),
            )
          : null,
    );
  }

  void _showNotificationDetails(BudgetNotification notification) {
    final color = _getSeverityColor(notification.severity);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(notification.icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (notification.percentage / 100).clamp(0.0, 1.0),
                minHeight: 16,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Budget Type', notification.type.toUpperCase()),
            _buildDetailRow(
              'Percentage Used',
              '${notification.percentage.toStringAsFixed(1)}%',
            ),
            _buildDetailRow(
              'Amount Spent',
              _formatCurrency(notification.spent),
            ),
            _buildDetailRow(
              'Budget Amount',
              _formatCurrency(notification.budget),
            ),
            _buildDetailRow(
              'Remaining',
              _formatCurrency(notification.budget - notification.spent),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Get.to(() => const BudgetScreen());
            },
            child: const Text('Manage Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Notification Model
class BudgetNotification {
  final String id; // Unique identifier
  final String title;
  final String message;
  final double percentage;
  final double spent;
  final double budget;
  final String type; // 'daily', 'weekly', 'monthly'
  final NotificationSeverity severity;
  final IconData icon;
  final DateTime time;

  BudgetNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.percentage,
    required this.spent,
    required this.budget,
    required this.type,
    required this.severity,
    required this.icon,
    required this.time,
  });
}

enum NotificationSeverity {
  low, // 25-49%
  medium, // 50-74%
  high, // 75-99%
  critical, // 100%+
}
