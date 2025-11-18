import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';

/// Proactive Insights Service
/// Provides daily/weekly notifications with spending insights
class ProactiveInsightsService {
  // Singleton pattern
  static final ProactiveInsightsService _instance =
      ProactiveInsightsService._internal();
  factory ProactiveInsightsService() => _instance;
  ProactiveInsightsService._internal();

  final ExpenseController _expenseController = Get.find<ExpenseController>();

  /// Initialize notifications
  Future<void> initialize() async {
    await AwesomeNotifications().initialize(null, [
      NotificationChannel(
        channelKey: 'proactive_insights',
        channelName: 'Proactive Insights',
        channelDescription: 'Daily and weekly spending insights',
        defaultColor: Get.theme.primaryColor,
        ledColor: Get.theme.primaryColor,
        importance: NotificationImportance.High,
        channelShowBadge: true,
      ),
      NotificationChannel(
        channelKey: 'budget_alerts',
        channelName: 'Budget Alerts',
        channelDescription: 'Budget limit warnings',
        defaultColor: Get.theme.colorScheme.error,
        ledColor: Get.theme.colorScheme.error,
        importance: NotificationImportance.Max,
        channelShowBadge: true,
      ),
    ]);

    // Request permission
    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  /// Schedule daily morning insight (9 AM)
  Future<void> scheduleDailyMorningInsight() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_insights_enabled') ?? true;

    if (!enabled) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'proactive_insights',
        title: '🌅 Good Morning!',
        body: await _generateMorningInsight(),
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Reminder,
      ),
      schedule: NotificationCalendar(
        hour: 9,
        minute: 0,
        second: 0,
        repeats: true,
      ),
    );
  }

  /// Schedule daily evening summary (8 PM)
  Future<void> scheduleDailyEveningSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('daily_insights_enabled') ?? true;

    if (!enabled) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 2,
        channelKey: 'proactive_insights',
        title: '📊 Today\'s Summary',
        body: await _generateEveningSummary(),
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Status,
      ),
      schedule: NotificationCalendar(
        hour: 20,
        minute: 0,
        second: 0,
        repeats: true,
      ),
    );
  }

  /// Schedule weekly summary (Sunday 10 AM)
  Future<void> scheduleWeeklySummary() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('weekly_insights_enabled') ?? true;

    if (!enabled) return;

    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 3,
        channelKey: 'proactive_insights',
        title: '📈 Weekly Financial Report',
        body: await _generateWeeklySummary(),
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Status,
      ),
      schedule: NotificationCalendar(
        weekday: DateTime.sunday,
        hour: 10,
        minute: 0,
        second: 0,
        repeats: true,
      ),
    );
  }

  /// Send instant insight notification
  Future<void> sendInstantInsight(String title, String message) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'proactive_insights',
        title: title,
        body: message,
        notificationLayout: NotificationLayout.BigText,
      ),
    );
  }

  /// Send budget alert
  Future<void> sendBudgetAlert(
    String category,
    double spent,
    double limit,
  ) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        channelKey: 'budget_alerts',
        title: '⚠️ Budget Alert!',
        body:
            '$category: ৳${spent.toStringAsFixed(0)} spent (Limit: ৳${limit.toStringAsFixed(0)})',
        notificationLayout: NotificationLayout.BigText,
        category: NotificationCategory.Alarm,
      ),
    );
  }

  /// Generate morning insight
  Future<String> _generateMorningInsight() async {
    final yesterday = _getYesterdayExpenses();
    final yesterdayTotal = yesterday.fold(0.0, (sum, e) => sum + e.amount);

    final thisMonth = _getMonthlyExpenses();
    final monthlyTotal = thisMonth.fold(0.0, (sum, e) => sum + e.amount);
    final dailyAverage = thisMonth.isEmpty
        ? 0.0
        : monthlyTotal / DateTime.now().day;

    if (yesterday.isEmpty) {
      return 'আজকের দিনটা শুরু করুন সাবধানে! গতকাল কোন খরচ record করা হয়নি। 💰';
    }

    final comparison = yesterdayTotal < dailyAverage ? 'কম' : 'বেশি';
    final emoji = yesterdayTotal < dailyAverage ? '👍' : '⚠️';

    return 'গতকাল আপনি ৳${yesterdayTotal.toStringAsFixed(0)} খরচ করেছেন। '
        'আপনার daily average (৳${dailyAverage.toStringAsFixed(0)}) এর চেয়ে $comparison! $emoji\n'
        'আজ smart spending করুন!';
  }

  /// Generate evening summary
  Future<String> _generateEveningSummary() async {
    final today = _getTodayExpenses();
    final todayTotal = today.fold(0.0, (sum, e) => sum + e.amount);

    if (today.isEmpty) {
      return 'আজ কোন খরচ track করা হয়নি। কিছু খরচ হয়েছে কি? 🤔';
    }

    final topCategory = _getTopCategory(today);
    final thisMonth = _getMonthlyExpenses();
    final monthlyTotal = thisMonth.fold(0.0, (sum, e) => sum + e.amount);
    final dailyAverage = thisMonth.isEmpty
        ? 0.0
        : monthlyTotal / DateTime.now().day;

    String message =
        'আজকের খরচ: ৳${todayTotal.toStringAsFixed(0)} (${today.length} transactions)\n';

    if (topCategory.isNotEmpty) {
      message += 'সবচেয়ে বেশি: $topCategory\n';
    }

    if (todayTotal > dailyAverage * 1.5) {
      message += '⚠️ আজ অনেক বেশি খরচ হয়েছে! কাল সাবধান থাকুন।';
    } else if (todayTotal < dailyAverage * 0.7) {
      message += '✅ দারুণ! আজ কম খরচ করেছেন!';
    } else {
      message += '👍 আজকের খরচ নিয়ন্ত্রণে আছে।';
    }

    return message;
  }

  /// Generate weekly summary
  Future<String> _generateWeeklySummary() async {
    final thisWeek = _getWeeklyExpenses();
    final weekTotal = thisWeek.fold(0.0, (sum, e) => sum + e.amount);

    if (thisWeek.isEmpty) {
      return 'এই সপ্তাহে কোন খরচ track করা হয়নি। 📝';
    }

    // Get last week data
    final lastWeekStart = DateTime.now().subtract(Duration(days: 14));
    final lastWeekEnd = DateTime.now().subtract(Duration(days: 7));
    final lastWeek = _expenseController.expenses.where((e) {
      return e.date.isAfter(lastWeekStart) && e.date.isBefore(lastWeekEnd);
    }).toList();
    final lastWeekTotal = lastWeek.fold(0.0, (sum, e) => sum + e.amount);

    String message = 'এই সপ্তাহে মোট খরচ: ৳${weekTotal.toStringAsFixed(0)}\n';
    message += 'Transactions: ${thisWeek.length}টি\n';

    if (lastWeek.isNotEmpty) {
      final diff = weekTotal - lastWeekTotal;
      final percent = (diff / lastWeekTotal * 100).abs();

      if (diff > 0) {
        message +=
            '📈 গত সপ্তাহের চেয়ে ৳${diff.toStringAsFixed(0)} (${percent.toStringAsFixed(0)}%) বেশি\n';
      } else if (diff < 0) {
        message +=
            '📉 গত সপ্তাহের চেয়ে ৳${diff.abs().toStringAsFixed(0)} (${percent.toStringAsFixed(0)}%) কম ✅\n';
      }
    }

    final topCategory = _getTopCategory(thisWeek);
    if (topCategory.isNotEmpty) {
      message += 'Top Category: $topCategory';
    }

    return message;
  }

  /// Check budget limits and send alerts
  Future<void> checkBudgetLimits() async {
    final prefs = await SharedPreferences.getInstance();
    final budgetAlertsEnabled = prefs.getBool('budget_alerts_enabled') ?? true;

    if (!budgetAlertsEnabled) return;

    // Check category budgets
    final monthlyExpenses = _getMonthlyExpenses();
    final categoryTotals = <String, double>{};

    for (var expense in monthlyExpenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    // Example budget limits (can be made configurable)
    final budgetLimits = {
      'food': 5000.0,
      'transport': 3000.0,
      'bills': 4000.0,
      'shopping': 3000.0,
      'entertainment': 2000.0,
    };

    for (var entry in categoryTotals.entries) {
      final category = entry.key.toLowerCase();
      final spent = entry.value;
      final limit = budgetLimits[category];

      if (limit != null && spent > limit * 0.9) {
        if (spent >= limit) {
          await sendBudgetAlert(entry.key.toUpperCase(), spent, limit);
        } else if (spent > limit * 0.9) {
          // 90% warning
          await sendInstantInsight(
            '⚠️ Budget Warning',
            '${entry.key.toUpperCase()} category তে ৳${spent.toStringAsFixed(0)} খরচ হয়েছে। '
                'Limit (৳${limit.toStringAsFixed(0)}) এর 90% crossed!',
          );
        }
      }
    }
  }

  /// Helper: Get today's expenses
  List<Expense> _getTodayExpenses() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _expenseController.expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return expenseDate.isAtSameMomentAs(today);
    }).toList();
  }

  /// Helper: Get yesterday's expenses
  List<Expense> _getYesterdayExpenses() {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    final yesterdayDate = DateTime(
      yesterday.year,
      yesterday.month,
      yesterday.day,
    );

    return _expenseController.expenses.where((expense) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      return expenseDate.isAtSameMomentAs(yesterdayDate);
    }).toList();
  }

  /// Helper: Get this week's expenses
  List<Expense> _getWeeklyExpenses() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    return _expenseController.expenses.where((expense) {
      return expense.date.isAfter(weekStartDate);
    }).toList();
  }

  /// Helper: Get this month's expenses
  List<Expense> _getMonthlyExpenses() {
    final now = DateTime.now();

    return _expenseController.expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();
  }

  /// Helper: Get top spending category
  String _getTopCategory(List<Expense> expenses) {
    if (expenses.isEmpty) return '';

    final categoryTotals = <String, double>{};
    for (var expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    var topCategory = '';
    var maxAmount = 0.0;

    categoryTotals.forEach((category, amount) {
      if (amount > maxAmount) {
        maxAmount = amount;
        topCategory = category;
      }
    });

    return topCategory.isEmpty
        ? ''
        : '$topCategory (৳${maxAmount.toStringAsFixed(0)})';
  }

  /// Enable/Disable daily insights
  Future<void> setDailyInsightsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('daily_insights_enabled', enabled);

    if (enabled) {
      await scheduleDailyMorningInsight();
      await scheduleDailyEveningSummary();
    } else {
      await AwesomeNotifications().cancel(1);
      await AwesomeNotifications().cancel(2);
    }
  }

  /// Enable/Disable weekly insights
  Future<void> setWeeklyInsightsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('weekly_insights_enabled', enabled);

    if (enabled) {
      await scheduleWeeklySummary();
    } else {
      await AwesomeNotifications().cancel(3);
    }
  }

  /// Enable/Disable budget alerts
  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('budget_alerts_enabled', enabled);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
