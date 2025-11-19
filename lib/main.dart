import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_expense_screen.dart';
import 'screens/income_history_screen.dart';
import 'screens/combined_history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/monthly_summary_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/theme_customization_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/security_settings_screen.dart';
import 'screens/chatbot_screen.dart';
import 'services/database_helper.dart';
import 'services/currency_service.dart';
import 'services/language_service.dart';
import 'services/translations.dart';
import 'services/firebase_service.dart';
import 'services/proactive_insights_service.dart';
import 'services/gemini_service.dart';
import 'config/api_keys.dart';
import 'controllers/expense_controller.dart';
import 'controllers/personalization_controller.dart';
import 'controllers/security_controller.dart';
import 'controllers/premium_controller.dart';
import 'controllers/points_controller.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (with error handling)
  try {
    await Firebase.initializeApp();

    // IMPORTANT: Ensure Firebase Auth persists user sessions
    // This prevents sign-out on app restart
    await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    print('✅ Firebase Auth persistence set to LOCAL');
  } catch (e) {
    print('Firebase initialization error: $e');
    // Continue without Firebase if initialization fails
  }

  // Initialize the database when the app starts
  await DatabaseHelper().database;

  // Initialize services and controllers
  Get.put(CurrencyService());
  Get.put(LanguageService());
  Get.put(PersonalizationController());
  Get.put(SecurityController());
  Get.put(PremiumController()); // Premium status controller
  Get.put(PointsController()); // Points controller

  // Initialize Firebase service only if Firebase is initialized
  try {
    Get.put(FirebaseService());
  } catch (e) {
    print('FirebaseService initialization error: $e');
    // Continue without FirebaseService
  }

  Get.put(ExpenseController()); // ExpenseController will work without Firebase

  // Initialize Gemini AI with API Key
  // API key is stored in lib/config/api_keys.dart (gitignored for security)
  try {
    final geminiService = GeminiService();
    geminiService.setApiKey(ApiKeys.geminiApiKey);
    geminiService.initialize();
    print('✅ Gemini AI initialized');
  } catch (e) {
    print('❌ Gemini AI error: $e');
  }

  // Initialize Proactive Insights Service
  try {
    final insightsService = ProactiveInsightsService();
    await insightsService.initialize();
    await insightsService.scheduleDailyMorningInsight();
    await insightsService.scheduleDailyEveningSummary();
    await insightsService.scheduleWeeklySummary();
    print('✅ Proactive Insights initialized');
  } catch (e) {
    print('❌ Proactive Insights error: $e');
  }

  runApp(const MoneyMateApp());
}

class MoneyMateApp extends StatefulWidget {
  const MoneyMateApp({super.key});

  @override
  State<MoneyMateApp> createState() => _MoneyMateAppState();
}

class _MoneyMateAppState extends State<MoneyMateApp>
    with WidgetsBindingObserver {
  final securityController = Get.find<SecurityController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App is going to background
      securityController.checkAutoLock();
    } else if (state == AppLifecycleState.resumed) {
      // App is coming to foreground
      if (securityController.isSecurityEnabled.value &&
          securityController.isLocked.value) {
        // Show lock screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.to(() => const LockScreen());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final personalizationController = Get.find<PersonalizationController>();

    return Obx(() {
      // Force rebuild when font changes by observing the value
      // ignore: unused_local_variable
      final fontIndex = personalizationController.selectedFontIndex.value;

      return GetMaterialApp(
        title: 'MoneyMate',
        debugShowCheckedModeBanner: false,
        translations: AppTranslations(),
        locale: personalizationController.currentLocale,
        fallbackLocale: const Locale('en', 'US'),
        theme: personalizationController.getThemeData(),
        darkTheme: personalizationController.getThemeData(),
        themeMode: personalizationController.isDarkMode.value
            ? ThemeMode.dark
            : ThemeMode.light,
        // Initial route - Start with splash screen
        initialRoute: '/',
        // Define named routes
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          GetPage(name: '/home', page: () => HomeScreen()),
          GetPage(name: '/add-expense', page: () => const AddExpenseScreen()),
          GetPage(name: '/history', page: () => const CombinedHistoryScreen()),
          GetPage(
            name: '/income-history',
            page: () => const IncomeHistoryScreen(),
          ),
          GetPage(name: '/analytics', page: () => const AnalyticsScreen()),
          GetPage(name: '/settings', page: () => const SettingsScreen()),
          GetPage(
            name: '/monthly-summary',
            page: () => const MonthlySummaryScreen(),
          ),
          GetPage(name: '/budget', page: () => const BudgetScreen()),
          GetPage(name: '/profile', page: () => const ProfileScreen()),
          GetPage(
            name: '/theme-customization',
            page: () => const ThemeCustomizationScreen(),
          ),
          GetPage(
            name: '/security-settings',
            page: () => const SecuritySettingsScreen(),
          ),
          GetPage(name: '/lock', page: () => const LockScreen()),
          GetPage(name: '/chatbot', page: () => const ChatbotScreen()),
        ],
      );
    });
  }
}
