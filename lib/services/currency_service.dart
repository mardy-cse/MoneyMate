import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService extends GetxController {
  static CurrencyService get instance => Get.find<CurrencyService>();

  // Observable currency
  final selectedCurrency = 'BDT'.obs;
  final selectedCurrencySymbol = '৳'.obs;

  // Available currencies with their symbols and exchange rates (to USD)
  final Map<String, Map<String, dynamic>> currencies = {
    'BDT': {
      'name': 'Bangladeshi Taka',
      'symbol': '৳',
      'rate': 110.0, // 1 USD = 110 BDT
    },
    'USD': {'name': 'US Dollar', 'symbol': '\$', 'rate': 1.0},
    'EUR': {'name': 'Euro', 'symbol': '€', 'rate': 0.92},
    'INR': {'name': 'Indian Rupee', 'symbol': '₹', 'rate': 83.0},
    'GBP': {'name': 'British Pound', 'symbol': '£', 'rate': 0.79},
    'JPY': {'name': 'Japanese Yen', 'symbol': '¥', 'rate': 149.0},
    'CNY': {'name': 'Chinese Yuan', 'symbol': '¥', 'rate': 7.24},
    'AUD': {'name': 'Australian Dollar', 'symbol': 'A\$', 'rate': 1.54},
  };

  @override
  void onInit() {
    super.onInit();
    loadCurrency();
  }

  // Load saved currency from SharedPreferences
  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString('selected_currency') ?? 'BDT';
    selectedCurrency.value = savedCurrency;
    selectedCurrencySymbol.value = currencies[savedCurrency]?['symbol'] ?? '৳';
  }

  // Save currency to SharedPreferences
  Future<void> saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency);
    selectedCurrency.value = currency;
    selectedCurrencySymbol.value = currencies[currency]?['symbol'] ?? '৳';
  }

  // Convert amount from one currency to another
  double convertAmount(double amount, String from, String to) {
    if (from == to) return amount;

    final fromRate = currencies[from]?['rate'] ?? 1.0;
    final toRate = currencies[to]?['rate'] ?? 1.0;

    // Convert to USD first, then to target currency
    final amountInUSD = amount / fromRate;
    final convertedAmount = amountInUSD * toRate;

    return convertedAmount;
  }

  // Format currency with symbol and locale
  String formatCurrency(double amount, {String? currency}) {
    final curr = currency ?? selectedCurrency.value;
    final symbol = currencies[curr]?['symbol'] ?? '৳';

    // Format with 2 decimal places and thousand separators
    final formatted = amount
        .toStringAsFixed(2)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );

    return '$symbol$formatted';
  }

  // Get currency name
  String getCurrencyName(String code) {
    return currencies[code]?['name'] ?? code;
  }

  // Get all currency codes
  List<String> getCurrencyCodes() {
    return currencies.keys.toList();
  }

  // Update exchange rates (for future API integration)
  Future<void> updateExchangeRates() async {
    // TODO: Integrate with live API like exchangerate.host
    // Example: https://api.exchangerate.host/latest?base=USD

    // For now, using static rates
    // In production, you would fetch from API:
    /*
    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate.host/latest?base=USD'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Update rates from API
      }
    } catch (e) {
      print('Failed to update exchange rates: $e');
    }
    */
  }
}
