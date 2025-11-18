import 'package:get/get.dart';
import '../controllers/expense_controller.dart';
import '../models/expense.dart';
import 'gemini_service.dart';

/// AI-powered Financial Assistant Chatbot
/// Provides intelligent responses to user queries about expenses, budgets, and financial advice
class ChatbotService {
  // Singleton pattern
  static final ChatbotService _instance = ChatbotService._internal();
  factory ChatbotService() => _instance;
  ChatbotService._internal();

  // Get expense controller
  ExpenseController get _expenseController => Get.find<ExpenseController>();
  
  // Gemini AI service (public for status checking)
  final GeminiService geminiService = GeminiService();
  
  // AI mode toggle (true = Gemini AI, false = Rule-based)
  bool useAI = true; // Gemini 2.0 Flash enabled!

  /// Process user message and generate response
  Future<ChatMessage> processMessage(String userMessage) async {
    final message = userMessage.trim().toLowerCase();

    // Try Gemini AI first if enabled and configured
    if (useAI && geminiService.isConfigured) {
      try {
        final aiResponse = await geminiService.generateResponse(userMessage);
        return ChatMessage(
          text: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
          type: MessageType.general,
        );
      } catch (e) {
        print('Gemini AI error, falling back to rule-based: $e');
        // Fall back to rule-based if AI fails
      }
    }

    // Fallback to rule-based responses
    // Detect intent and generate appropriate response
    if (_isGreeting(message)) {
      return _generateGreeting();
    } else if (_isExpenseQuery(message)) {
      return await _handleExpenseQuery(message);
    } else if (_isCategoryQuery(message)) {
      return await _handleCategoryQuery(message);
    } else if (_isBudgetAdvice(message)) {
      return await _handleBudgetAdvice(message);
    } else if (_isSavingsTips(message)) {
      return _generateSavingsTips();
    } else if (_isSpendingPattern(message)) {
      return await _handleSpendingPattern(message);
    } else if (_isComparison(message)) {
      return await _handleComparison(message);
    } else if (_isHelp(message)) {
      return _generateHelp();
    } else {
      return _generateFallback(message);
    }
  }

  // Intent Detection Methods
  bool _isGreeting(String message) {
    final greetings = [
      'হাই', 'হ্যালো', 'হেলো', 'নমস্কার', 'আসসালামু আলাইকুম',
      'hi', 'hello', 'hey', 'good morning', 'good evening', 'good afternoon'
    ];
    return greetings.any((greeting) => message.contains(greeting));
  }

  bool _isExpenseQuery(String message) {
    final keywords = [
      'খরচ', 'ব্যয়', 'টাকা', 'কত', 'মোট', 'আজ', 'আজকের', 'today', 'total',
      'expense', 'spent', 'spending', 'cost', 'how much', 'কতো', 'এ মাসে',
      'এই মাসে', 'this month', 'this week', 'সপ্তাহে', 'গতকাল', 'গত কাল',
      'yesterday', 'last day', 'আগের দিন'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _isCategoryQuery(String message) {
    final categories = [
      'food', 'transport', 'bills', 'shopping', 'entertainment',
      'healthcare', 'education', 'খাবার', 'যাতায়াত', 'বিল', 'কেনাকাটা'
    ];
    return categories.any((category) => message.contains(category));
  }

  bool _isBudgetAdvice(String message) {
    final keywords = [
      'বাজেট', 'পরিকল্পনা', 'budget', 'plan', 'advice', 'suggest',
      'পরামর্শ', 'উপদেশ', 'কিভাবে', 'how to', 'should i'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _isSavingsTips(String message) {
    final keywords = [
      'সেভ', 'সঞ্চয়', 'বাঁচানো', 'save', 'saving', 'reduce', 'কমানো',
      'tips', 'টিপস'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _isSpendingPattern(String message) {
    final keywords = [
      'pattern', 'trend', 'ধরণ', 'প্যাটার্ন', 'analysis', 'বিশ্লেষণ',
      'habit', 'অভ্যাস'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _isComparison(String message) {
    final keywords = [
      'compare', 'comparison', 'তুলনা', 'গত মাস', 'last month',
      'previous', 'আগের', 'difference', 'পার্থক্য'
    ];
    return keywords.any((keyword) => message.contains(keyword));
  }

  bool _isHelp(String message) {
    final keywords = ['help', 'সাহায্য', 'কি করতে পারো', 'what can you do'];
    return keywords.any((keyword) => message.contains(keyword));
  }

  // Response Generation Methods

  ChatMessage _generateGreeting() {
    final responses = [
      'হাই! আমি আপনার Financial Assistant 🤖\nআপনার খরচ সম্পর্কে যেকোনো প্রশ্ন করুন!',
      'Hello! 👋 আমি আপনাকে financial advice দিতে পারি।\nকিছু জানতে চান?',
      'নমস্কার! 😊 আপনার expense analysis এ সাহায্য করতে পারি।',
    ];
    return ChatMessage(
      text: responses[DateTime.now().second % responses.length],
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.greeting,
    );
  }

  Future<ChatMessage> _handleExpenseQuery(String message) async {
    final expenses = _expenseController.expenses;

    if (expenses.isEmpty) {
      return ChatMessage(
        text: 'আপনার এখনো কোনো expense নেই। 📊\nপ্রথম expense add করুন!',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.info,
      );
    }

    // Detect time period
    String response = '';
    if (message.contains('গতকাল') || message.contains('গত কাল') || message.contains('yesterday')) {
      final yesterdayExpenses = _getYesterdayExpenses();
      final yesterdayTotal = yesterdayExpenses.fold<double>(
        0, (sum, expense) => sum + expense.amount.abs()
      );
      response = '📅 গতকালের খরচ:\n'
          '💰 Total: ৳${yesterdayTotal.toStringAsFixed(2)}\n'
          '📝 Expenses: ${yesterdayExpenses.length} টি\n\n'
          '${_getYesterdayBreakdown()}';
    } else if (message.contains('আজ') || message.contains('today')) {
      final todayTotal = _expenseController.totalToday.value;
      final todayCount = _getTodayExpenses().length;
      response = '📅 আজকের খরচ:\n'
          '💰 Total: ৳${todayTotal.toStringAsFixed(2)}\n'
          '📝 Expenses: $todayCount টি\n\n'
          '${_getTodayBreakdown()}';
    } else if (message.contains('সপ্তাহ') || message.contains('week')) {
      final weeklyTotal = _expenseController.totalWeekly.value;
      final weeklyCount = _getWeeklyExpenses().length;
      response = '📅 এই সপ্তাহের খরচ:\n'
          '💰 Total: ৳${weeklyTotal.toStringAsFixed(2)}\n'
          '📝 Expenses: $weeklyCount টি\n\n'
          '${_getWeeklyBreakdown()}';
    } else if (message.contains('মাস') || message.contains('month')) {
      final monthlyTotal = _expenseController.totalMonthly.value;
      final monthlyCount = _getMonthlyExpenses().length;
      final avgDaily = monthlyTotal / DateTime.now().day;
      response = '📅 এই মাসের খরচ:\n'
          '💰 Total: ৳${monthlyTotal.toStringAsFixed(2)}\n'
          '📝 Expenses: $monthlyCount টি\n'
          '📊 Daily Average: ৳${avgDaily.toStringAsFixed(2)}\n\n'
          '${_getMonthlyBreakdown()}';
    } else {
      // General expense info
      final totalAll = expenses.fold<double>(
        0, (sum, expense) => sum + expense.amount.abs()
      );
      response = '💼 Overall Summary:\n'
          '💰 Total Expenses: ৳${totalAll.toStringAsFixed(2)}\n'
          '📝 Total Transactions: ${expenses.length} টি\n'
          '📅 Since: ${_getOldestExpenseDate()}\n\n'
          'বিস্তারিত জানতে বলুন: "আজকের খরচ", "এই মাসের খরচ"';
    }

    return ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.expense,
    );
  }

  Future<ChatMessage> _handleCategoryQuery(String message) async {
    final expenses = _expenseController.expenses;

    if (expenses.isEmpty) {
      return ChatMessage(
        text: 'কোনো expense data নেই। 📊',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.info,
      );
    }

    // Detect which category
    String? category;
    if (message.contains('food') || message.contains('খাবার')) {
      category = 'food';
    } else if (message.contains('transport') || message.contains('যাতায়াত')) {
      category = 'transport';
    } else if (message.contains('bills') || message.contains('বিল')) {
      category = 'bills';
    } else if (message.contains('shopping') || message.contains('কেনাকাটা')) {
      category = 'shopping';
    }

    if (category != null) {
      final categoryExpenses = expenses.where((e) => 
        e.category.toLowerCase() == category!.toLowerCase()
      ).toList();
      
      final categoryTotal = categoryExpenses.fold<double>(
        0, (sum, expense) => sum + expense.amount.abs()
      );

      final monthlyExpenses = _getMonthlyExpenses();
      final monthlyCategoryTotal = monthlyExpenses
          .where((e) => e.category.toLowerCase() == category!.toLowerCase())
          .fold<double>(0, (sum, expense) => sum + expense.amount.abs());

      return ChatMessage(
        text: '🏷️ ${category.toUpperCase()} Category:\n\n'
            '💰 All Time: ৳${categoryTotal.toStringAsFixed(2)}\n'
            '📝 Transactions: ${categoryExpenses.length} টি\n'
            '📅 This Month: ৳${monthlyCategoryTotal.toStringAsFixed(2)}\n\n'
            '${_getRecentExpensesForCategory(category, 3)}',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.category,
      );
    }

    // General category breakdown
    final categoryTotals = _getCategoryTotals();
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String response = '📊 Category Breakdown (This Month):\n\n';
    for (var i = 0; i < topCategories.length && i < 5; i++) {
      final entry = topCategories[i];
      response += '${i + 1}. ${entry.key.toUpperCase()}: ৳${entry.value.toStringAsFixed(2)}\n';
    }

    return ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.category,
    );
  }

  Future<ChatMessage> _handleBudgetAdvice(String message) async {
    final monthlyTotal = _expenseController.totalMonthly.value;
    final avgDaily = monthlyTotal / DateTime.now().day;
    final projectedMonthly = avgDaily * 30;

    String advice = '💡 Budget Analysis & Advice:\n\n';
    advice += '📊 Current Status:\n';
    advice += '• Monthly spending: ৳${monthlyTotal.toStringAsFixed(2)}\n';
    advice += '• Daily average: ৳${avgDaily.toStringAsFixed(2)}\n';
    advice += '• Projected (30 days): ৳${projectedMonthly.toStringAsFixed(2)}\n\n';

    advice += '🎯 Recommendations:\n';

    // Analyze top spending categories
    final categoryTotals = _getCategoryTotals();
    final topCategory = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b);

    if (topCategory.value > monthlyTotal * 0.4) {
      advice += '⚠️ ${topCategory.key} তে খরচ অনেক বেশি (${((topCategory.value / monthlyTotal) * 100).toStringAsFixed(0)}%)!\n';
      advice += '   Try to reduce ${topCategory.key} expenses by 20%.\n\n';
    }

    if (avgDaily > 500) {
      advice += '💰 Daily average বেশি। Target করুন ৳400/day.\n';
    } else {
      advice += '✅ Daily spending ভালো আছে!\n';
    }

    advice += '\n📝 General Tips:\n';
    advice += '• 50-30-20 rule অনুসরণ করুন (needs-wants-savings)\n';
    advice += '• Track every expense daily\n';
    advice += '• Set monthly category limits\n';

    return ChatMessage(
      text: advice,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.advice,
    );
  }

  ChatMessage _generateSavingsTips() {
    final tips = [
      '💡 Savings Tips:\n\n'
          '1. 🏠 Cook at home - Save 40% on food expenses\n'
          '2. 🚌 Use public transport instead of taxi\n'
          '3. 💡 Track every small expense\n'
          '4. 🛍️ Avoid impulse shopping\n'
          '5. 📱 Cancel unused subscriptions\n\n'
          'Small changes = Big savings! 💰',
      
      '🌟 আজকের টিপস:\n\n'
          '💰 "একটি টাকা বাঁচানো = একটি টাকা আয়"\n\n'
          '• সকালে coffee shop এর বদলে ঘরে কফি (৳100/day saved)\n'
          '• Weekly grocery shopping list বানান\n'
          '• Discount & cashback offers ব্যবহার করুন\n'
          '• Emergency fund রাখুন (monthly expense এর 3x)\n\n'
          'Start today! 🚀',
      
      '📊 Smart Saving Strategy:\n\n'
          '1st Week: Track expenses only 📝\n'
          '2nd Week: Identify unnecessary spending 🔍\n'
          '3rd Week: Set category budgets 🎯\n'
          '4th Week: Review & adjust 📈\n\n'
          'Result: Save 15-20% monthly! 💪',
    ];

    return ChatMessage(
      text: tips[DateTime.now().second % tips.length],
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.tips,
    );
  }

  Future<ChatMessage> _handleSpendingPattern(String message) async {
    final monthlyExpenses = _getMonthlyExpenses();

    if (monthlyExpenses.isEmpty) {
      return ChatMessage(
        text: 'পর্যাপ্ত data নেই pattern analysis এর জন্য।',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.info,
      );
    }

    // Analyze by day of week
    final dayPattern = <int, double>{};
    for (var expense in monthlyExpenses) {
      final day = expense.date.weekday;
      dayPattern[day] = (dayPattern[day] ?? 0) + expense.amount.abs();
    }

    final sortedDays = dayPattern.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final maxDay = sortedDays.first;
    final minDay = sortedDays.last;

    String response = '📈 Spending Pattern Analysis:\n\n';
    response += '🔍 Weekly Pattern:\n';
    response += '• Highest: ${_getDayName(maxDay.key)} (৳${maxDay.value.toStringAsFixed(2)})\n';
    response += '• Lowest: ${_getDayName(minDay.key)} (৳${minDay.value.toStringAsFixed(2)})\n\n';

    // Time-based pattern
    final morning = monthlyExpenses.where((e) => e.date.hour < 12).length;
    final afternoon = monthlyExpenses.where((e) => e.date.hour >= 12 && e.date.hour < 18).length;
    final evening = monthlyExpenses.where((e) => e.date.hour >= 18).length;

    response += '⏰ Time Pattern:\n';
    response += '• Morning (6-12): $morning expenses\n';
    response += '• Afternoon (12-6): $afternoon expenses\n';
    response += '• Evening (6-12): $evening expenses\n\n';

    response += '💡 Insight:\n';
    if (maxDay.key == 5 || maxDay.key == 6) {
      response += 'Weekend এ খরচ বেশি! Plan করে খরচ করুন। 🎯';
    } else {
      response += 'Weekday এ spending সচেতন থাকুন। 📊';
    }

    return ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.analysis,
    );
  }

  Future<ChatMessage> _handleComparison(String message) async {
    final thisMonthExpenses = _getMonthlyExpenses();
    final lastMonthExpenses = _getLastMonthExpenses();

    if (lastMonthExpenses.isEmpty) {
      return ChatMessage(
        text: 'গত মাসের data নেই তুলনা করার জন্য। 📊',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.info,
      );
    }

    final thisMonthTotal = thisMonthExpenses.fold<double>(
      0, (sum, e) => sum + e.amount.abs()
    );
    final lastMonthTotal = lastMonthExpenses.fold<double>(
      0, (sum, e) => sum + e.amount.abs()
    );

    final difference = thisMonthTotal - lastMonthTotal;
    final percentChange = (difference / lastMonthTotal * 100);

    String response = '📊 Month-to-Month Comparison:\n\n';
    response += '📅 This Month: ৳${thisMonthTotal.toStringAsFixed(2)}\n';
    response += '📅 Last Month: ৳${lastMonthTotal.toStringAsFixed(2)}\n\n';
    response += '📈 Difference: ${difference >= 0 ? '+' : ''}৳${difference.toStringAsFixed(2)}\n';
    response += '📊 Change: ${percentChange >= 0 ? '+' : ''}${percentChange.toStringAsFixed(1)}%\n\n';

    if (difference > 0) {
      response += '⚠️ এই মাসে খরচ ${percentChange.toStringAsFixed(0)}% বেশি!\n';
      response += '💡 Try to reduce unnecessary expenses.';
    } else {
      response += '✅ Great! খরচ ${percentChange.abs().toStringAsFixed(0)}% কমেছে!\n';
      response += '🌟 Keep up the good work!';
    }

    return ChatMessage(
      text: response,
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.comparison,
    );
  }

  ChatMessage _generateHelp() {
    return ChatMessage(
      text: '🤖 আমি কি কি করতে পারি:\n\n'
          '💰 Expense Queries:\n'
          '• "আজকের খরচ কত?"\n'
          '• "গতকালের খরচ?"\n'
          '• "এই মাসের total expense?"\n'
          '• "সপ্তাহের খরচ দেখাও"\n\n'
          '🏷️ Category Analysis:\n'
          '• "Food category তে কত খরচ?"\n'
          '• "Top spending categories?"\n\n'
          '📈 Analysis:\n'
          '• "আমার spending pattern দেখাও"\n'
          '• "গত মাসের সাথে তুলনা করো"\n\n'
          '💡 Advice & Tips:\n'
          '• "Budget advice দাও"\n'
          '• "Savings tips দাও"\n\n'
          'যেকোনো প্রশ্ন করুন! 😊',
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.help,
    );
  }

  ChatMessage _generateFallback(String message) {
    final responses = [
      'দুঃখিত, আমি এটা বুঝতে পারিনি। 😅\n"help" লিখুন সব command দেখার জন্য।',
      'আমি এখনো শিখছি! 🤖\nঅন্য কিছু জিজ্ঞেস করুন বা "help" দেখুন।',
      'এই প্রশ্নটা আমি বুঝি না। 🤔\nTry: "আজকের খরচ?" বা "budget advice"',
    ];

    return ChatMessage(
      text: responses[DateTime.now().second % responses.length],
      isUser: false,
      timestamp: DateTime.now(),
      type: MessageType.fallback,
    );
  }

  // Helper Methods

  List<Expense> _getTodayExpenses() {
    final now = DateTime.now();
    return _expenseController.expenses.where((expense) {
      return expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day;
    }).toList();
  }

  List<Expense> _getYesterdayExpenses() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _expenseController.expenses.where((expense) {
      return expense.date.year == yesterday.year &&
          expense.date.month == yesterday.month &&
          expense.date.day == yesterday.day;
    }).toList();
  }

  List<Expense> _getWeeklyExpenses() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return _expenseController.expenses.where((expense) {
      return expense.date.isAfter(weekStart) && expense.date.isBefore(now);
    }).toList();
  }

  List<Expense> _getMonthlyExpenses() {
    final now = DateTime.now();
    return _expenseController.expenses.where((expense) {
      return expense.date.year == now.year && expense.date.month == now.month;
    }).toList();
  }

  List<Expense> _getLastMonthExpenses() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return _expenseController.expenses.where((expense) {
      return expense.date.year == lastMonth.year &&
          expense.date.month == lastMonth.month;
    }).toList();
  }

  String _getTodayBreakdown() {
    final expenses = _getTodayExpenses();
    if (expenses.isEmpty) return 'No expenses today.';

    final categories = <String, double>{};
    for (var expense in expenses) {
      categories[expense.category] = 
          (categories[expense.category] ?? 0) + expense.amount.abs();
    }

    String breakdown = 'Breakdown:\n';
    categories.forEach((category, amount) {
      breakdown += '• $category: ৳${amount.toStringAsFixed(2)}\n';
    });

    return breakdown;
  }

  String _getYesterdayBreakdown() {
    final expenses = _getYesterdayExpenses();
    if (expenses.isEmpty) return 'গতকাল কোনো expense নেই।';

    final categories = <String, double>{};
    for (var expense in expenses) {
      categories[expense.category] = 
          (categories[expense.category] ?? 0) + expense.amount.abs();
    }

    String breakdown = 'Breakdown:\n';
    categories.forEach((category, amount) {
      breakdown += '• $category: ৳${amount.toStringAsFixed(2)}\n';
    });

    return breakdown;
  }

  String _getWeeklyBreakdown() {
    final expenses = _getWeeklyExpenses();
    if (expenses.isEmpty) return 'No expenses this week.';

    final categories = <String, double>{};
    for (var expense in expenses) {
      categories[expense.category] = 
          (categories[expense.category] ?? 0) + expense.amount.abs();
    }

    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String breakdown = 'Top Categories:\n';
    for (var i = 0; i < sorted.length && i < 3; i++) {
      breakdown += '${i + 1}. ${sorted[i].key}: ৳${sorted[i].value.toStringAsFixed(2)}\n';
    }

    return breakdown;
  }

  String _getMonthlyBreakdown() {
    final expenses = _getMonthlyExpenses();
    if (expenses.isEmpty) return 'No expenses this month.';

    final categories = <String, double>{};
    for (var expense in expenses) {
      categories[expense.category] = 
          (categories[expense.category] ?? 0) + expense.amount.abs();
    }

    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    String breakdown = 'Top Categories:\n';
    for (var i = 0; i < sorted.length && i < 3; i++) {
      breakdown += '${i + 1}. ${sorted[i].key}: ৳${sorted[i].value.toStringAsFixed(2)}\n';
    }

    return breakdown;
  }

  Map<String, double> _getCategoryTotals() {
    final expenses = _getMonthlyExpenses();
    final categories = <String, double>{};

    for (var expense in expenses) {
      categories[expense.category] = 
          (categories[expense.category] ?? 0) + expense.amount.abs();
    }

    return categories;
  }

  String _getRecentExpensesForCategory(String category, int count) {
    final expenses = _expenseController.expenses
        .where((e) => e.category.toLowerCase() == category.toLowerCase())
        .take(count)
        .toList();

    if (expenses.isEmpty) return 'No recent expenses.';

    String result = 'Recent Expenses:\n';
    for (var expense in expenses) {
      result += '• ${expense.title}: ৳${expense.amount.abs().toStringAsFixed(2)} '
          '(${_formatDate(expense.date)})\n';
    }

    return result;
  }

  String _getOldestExpenseDate() {
    if (_expenseController.expenses.isEmpty) return 'N/A';

    final oldest = _expenseController.expenses.reduce((a, b) => 
        a.date.isBefore(b.date) ? a : b);

    return _formatDate(oldest.date);
  }

  String _getDayName(int day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[day - 1];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final MessageType type;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.type = MessageType.general,
  });
}

/// Message Types for styling
enum MessageType {
  greeting,
  expense,
  category,
  advice,
  tips,
  analysis,
  comparison,
  help,
  info,
  fallback,
  general,
}
