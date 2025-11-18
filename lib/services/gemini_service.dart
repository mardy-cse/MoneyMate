import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:get/get.dart';
import '../controllers/expense_controller.dart';

/// Google Gemini AI Service for Intelligent Financial Assistant
/// Free tier: 15 requests per minute, 1500 requests per day
class GeminiService {
  // Singleton pattern
  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  // Gemini API Key - REMOVED FOR SECURITY
  // Get your free API key from: https://aistudio.google.com/app/apikey
  // Store it in a secure location (NOT in code!)
  static String? _apiKey;

  GenerativeModel? _model;
  bool _isInitialized = false;

  /// Set API Key securely (call this before initialize)
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  /// Initialize Gemini AI
  void initialize() {
    if (_isInitialized) return;
    if (_apiKey == null || _apiKey!.isEmpty) {
      print('❌ Gemini API Key not set! Call setApiKey() first.');
      return;
    }

    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash', // Latest stable free model
        apiKey: _apiKey!,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 1024,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(
            HarmCategory.sexuallyExplicit,
            HarmBlockThreshold.medium,
          ),
          SafetySetting(
            HarmCategory.dangerousContent,
            HarmBlockThreshold.medium,
          ),
        ],
      );
      _isInitialized = true;
      print('✅ Gemini AI initialized successfully');
    } catch (e) {
      print('❌ Gemini AI initialization failed: $e');
      _isInitialized = false;
    }
  }

  /// Check if API key is configured
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  /// Generate AI response for financial query
  Future<String> generateResponse(String userQuery) async {
    if (!isConfigured) {
      return '⚠️ Gemini API key not configured. Please add your API key in gemini_service.dart\n\n'
          'Get free API key from: https://makersuite.google.com/app/apikey';
    }

    if (!_isInitialized) {
      initialize();
    }

    if (_model == null) {
      return '❌ AI service unavailable. Please check your internet connection.';
    }

    try {
      // Get expense data context
      final expenseContext = await _buildExpenseContext();

      // Build prompt with context
      final prompt = _buildPrompt(userQuery, expenseContext);

      // Generate response
      final response = await _model!.generateContent([Content.text(prompt)]);

      if (response.text == null || response.text!.isEmpty) {
        return '❌ Could not generate response. Please try again.';
      }

      return response.text!;
    } catch (e) {
      print('Gemini API Error: $e');
      return '❌ Error: ${e.toString()}\n\nPlease check:\n'
          '• Internet connection\n'
          '• API key validity\n'
          '• Daily request limit (1500/day)';
    }
  }

  /// Build expense data context for AI
  Future<String> _buildExpenseContext() async {
    try {
      final expenseController = Get.find<ExpenseController>();
      final expenses = expenseController.expenses;

      if (expenses.isEmpty) {
        return 'No expense data available.';
      }

      // Get today's expenses
      final now = DateTime.now();
      final todayExpenses = expenses
          .where(
            (e) =>
                e.date.year == now.year &&
                e.date.month == now.month &&
                e.date.day == now.day,
          )
          .toList();

      // Get yesterday's expenses
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayExpenses = expenses
          .where(
            (e) =>
                e.date.year == yesterday.year &&
                e.date.month == yesterday.month &&
                e.date.day == yesterday.day,
          )
          .toList();

      // Get this week's expenses
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekExpenses = expenses
          .where((e) => e.date.isAfter(weekStart) && e.date.isBefore(now))
          .toList();

      // Get this month's expenses
      final monthExpenses = expenses
          .where((e) => e.date.year == now.year && e.date.month == now.month)
          .toList();

      // Calculate totals
      final todayTotal = todayExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount.abs(),
      );
      final yesterdayTotal = yesterdayExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount.abs(),
      );
      final weekTotal = weekExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount.abs(),
      );
      final monthTotal = monthExpenses.fold<double>(
        0,
        (sum, e) => sum + e.amount.abs(),
      );

      // Category breakdown (this month)
      final categoryTotals = <String, double>{};
      for (var expense in monthExpenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0) + expense.amount.abs();
      }

      // Build context
      final context = StringBuffer();
      context.writeln('EXPENSE DATA CONTEXT:');
      context.writeln('Currency: Bangladeshi Taka (৳)');
      context.writeln('');
      context.writeln('TODAY (${_formatDate(now)}):');
      context.writeln('  Total: ৳${todayTotal.toStringAsFixed(2)}');
      context.writeln('  Transactions: ${todayExpenses.length}');
      context.writeln('');
      context.writeln('YESTERDAY (${_formatDate(yesterday)}):');
      context.writeln('  Total: ৳${yesterdayTotal.toStringAsFixed(2)}');
      context.writeln('  Transactions: ${yesterdayExpenses.length}');
      context.writeln('');
      context.writeln('THIS WEEK:');
      context.writeln('  Total: ৳${weekTotal.toStringAsFixed(2)}');
      context.writeln('  Transactions: ${weekExpenses.length}');
      context.writeln('');
      context.writeln('THIS MONTH:');
      context.writeln('  Total: ৳${monthTotal.toStringAsFixed(2)}');
      context.writeln('  Transactions: ${monthExpenses.length}');
      context.writeln(
        '  Daily Average: ৳${(monthTotal / now.day).toStringAsFixed(2)}',
      );
      context.writeln('');
      context.writeln('CATEGORY BREAKDOWN (THIS MONTH):');
      final sortedCategories = categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (var i = 0; i < sortedCategories.length && i < 5; i++) {
        final entry = sortedCategories[i];
        final percentage = (entry.value / monthTotal * 100).toStringAsFixed(1);
        context.writeln(
          '  ${entry.key}: ৳${entry.value.toStringAsFixed(2)} ($percentage%)',
        );
      }
      context.writeln('');
      context.writeln('RECENT EXPENSES (Last 5):');
      for (var i = 0; i < expenses.length && i < 5; i++) {
        final expense = expenses[i];
        context.writeln(
          '  - ${expense.title}: ৳${expense.amount.abs().toStringAsFixed(2)} (${expense.category}) - ${_formatDate(expense.date)}',
        );
      }

      return context.toString();
    } catch (e) {
      return 'Error loading expense data: $e';
    }
  }

  /// Build AI prompt with context
  String _buildPrompt(String userQuery, String expenseContext) {
    return '''
You are a professional financial assistant for MoneyMate app. You help users understand and manage their expenses.

INSTRUCTIONS:
1. Answer in a friendly, conversational tone
2. Use emojis appropriately (💰 📊 💡 ⚠️ ✅ etc.)
3. Support both Bangla and English languages
4. Provide actionable insights and recommendations
5. Format numbers with ৳ symbol and 2 decimal places
6. Keep responses concise (max 300 words)
7. If asked about specific dates/periods, use the data from context
8. Give practical financial advice when relevant

$expenseContext

USER QUERY: $userQuery

RESPONSE (format nicely with emojis and bullet points):
''';
  }

  /// Format date helper
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Test API connection
  Future<bool> testConnection() async {
    if (!isConfigured) return false;

    try {
      initialize();
      final response = await _model?.generateContent([
        Content.text('Say "Hello! Gemini AI is working!" in one line.'),
      ]);
      return response?.text != null && response!.text!.isNotEmpty;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
}
