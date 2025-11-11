import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService extends GetxController {
  static LanguageService get instance => Get.find<LanguageService>();

  // Observable language
  final selectedLanguage = 'en'.obs;
  final selectedLocale = const Locale('en', 'US').obs;

  // Available languages
  final List<Map<String, dynamic>> languages = [
    {
      'code': 'en',
      'name': 'English',
      'flag': '🇬🇧',
      'locale': const Locale('en', 'US'),
    },
    {
      'code': 'bn',
      'name': 'বাংলা',
      'flag': '🇧🇩',
      'locale': const Locale('bn', 'BD'),
    },
    {
      'code': 'hi',
      'name': 'हिन्दी',
      'flag': '🇮🇳',
      'locale': const Locale('hi', 'IN'),
    },
    {
      'code': 'ar',
      'name': 'العربية',
      'flag': '🇸🇦',
      'locale': const Locale('ar', 'SA'),
    },
    {
      'code': 'es',
      'name': 'Español',
      'flag': '🇪🇸',
      'locale': const Locale('es', 'ES'),
    },
    {
      'code': 'fr',
      'name': 'Français',
      'flag': '🇫🇷',
      'locale': const Locale('fr', 'FR'),
    },
    {
      'code': 'de',
      'name': 'Deutsch',
      'flag': '🇩🇪',
      'locale': const Locale('de', 'DE'),
    },
    {
      'code': 'zh',
      'name': '中文',
      'flag': '🇨🇳',
      'locale': const Locale('zh', 'CN'),
    },
  ];

  @override
  void onInit() {
    super.onInit();
    loadLanguage();
  }

  // Load saved language from SharedPreferences
  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('selected_language') ?? 'en';
    selectedLanguage.value = savedLanguage;

    final language = languages.firstWhere(
      (lang) => lang['code'] == savedLanguage,
      orElse: () => languages[0],
    );
    selectedLocale.value = language['locale'] as Locale;

    // Update GetX locale
    Get.updateLocale(selectedLocale.value);
  }

  // Save language to SharedPreferences
  Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', languageCode);

    final language = languages.firstWhere(
      (lang) => lang['code'] == languageCode,
      orElse: () => languages[0],
    );

    selectedLanguage.value = languageCode;
    selectedLocale.value = language['locale'] as Locale;

    // Update GetX locale
    Get.updateLocale(selectedLocale.value);

    // Notify GetBuilder listeners
    update();
  } // Get language name by code

  String getLanguageName(String code) {
    final language = languages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => languages[0],
    );
    return language['name'] as String;
  }

  // Get language flag by code
  String getLanguageFlag(String code) {
    final language = languages.firstWhere(
      (lang) => lang['code'] == code,
      orElse: () => languages[0],
    );
    return language['flag'] as String;
  }

  // Get all language codes
  List<String> getLanguageCodes() {
    return languages.map((lang) => lang['code'] as String).toList();
  }
}
