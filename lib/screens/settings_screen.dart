import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/currency_service.dart';
import '../services/language_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _isLoading = true;

  static const String _notificationsKey = 'notifications_enabled';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(_notificationsKey) ?? false;

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
                          const Divider(height: 1),
                          ListTile(
                            leading: Icon(
                              Icons.security,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: const Text('Security & Privacy'),
                            subtitle: const Text('PIN, Pattern & Biometric'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => Get.toNamed('/security-settings'),
                          ),
                        ],
                      ),
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
