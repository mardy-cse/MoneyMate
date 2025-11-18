import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class PersonalizationController extends GetxController {
  // Observable variables
  final isDarkMode = false.obs;
  final selectedColorIndex = 1.obs; // Default to Blue (index 1)
  final selectedFontIndex = 0.obs; // Default to System Default
  final userName = ''.obs;
  final userEmail = ''.obs;
  final profileImagePath = ''.obs;
  final selectedLanguage = 'en'.obs;

  // SharedPreferences keys
  static const String _darkModeKey = 'dark_mode';
  static const String _colorIndexKey = 'color_index';
  static const String _fontIndexKey = 'font_index';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _profileImageKey = 'profile_image';
  static const String _languageKey = 'app_language';

  // Predefined color palette - Modern soft pastel colors
  final List<Color> colorPalette = [
    const Color(0xFF4ECDC4), // Turquoise (Palette 17 - #4ECDC4)
    const Color(0xFFD4E845), // Light Lime (Palette 17 - #D4E845)
    const Color(0xFFFFC12F), // Soft Yellow (Palette 17 - #FFC12F)
    const Color(0xFFFF8B78), // Coral (Palette 17 - #FF8B78)
    const Color(0xFFCCADB9), // Soft Pink (Palette 17 - #CCADB9)
    const Color(0xFF00B4D8), // Bright Blue (Palette 15 - #00B4D8)
    const Color(0xFF0096A8), // Teal Blue (Palette 15 - #0096A8)
    const Color(0xFF90E0EF), // Sky Blue (Palette 15 - #90E0EF)
  ];

  final List<String> colorNames = [
    'Turquoise',
    'Lime',
    'Yellow',
    'Coral',
    'Pink',
    'Bright Blue',
    'Teal',
    'Sky Blue',
  ];

  // Font families
  final List<String> fontFamilies = [
    'System Default',
    'Roboto',
    'Poppins',
    'Lato',
    'Montserrat',
    'Open Sans',
    'Noto Sans', // Better multilingual support including Bangla
    'Ubuntu',
  ];

  final List<String> fontFamilyValues = [
    '', // System default (empty string)
    'Roboto',
    'Poppins',
    'Lato',
    'Montserrat',
    'OpenSans',
    'NotoSans',
    'Ubuntu',
  ];

  @override
  void onInit() {
    super.onInit();
    _loadPreferences();
  }

  // Load preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load theme mode
      isDarkMode.value = prefs.getBool(_darkModeKey) ?? false;

      // Load color preference
      selectedColorIndex.value = prefs.getInt(_colorIndexKey) ?? 0;

      // Load font preference
      selectedFontIndex.value = prefs.getInt(_fontIndexKey) ?? 0;

      // Load user profile
      userName.value = prefs.getString(_userNameKey) ?? '';
      userEmail.value = prefs.getString(_userEmailKey) ?? '';
      profileImagePath.value = prefs.getString(_profileImageKey) ?? '';

      // Load language preference
      selectedLanguage.value = prefs.getString(_languageKey) ?? 'en';

      // Update theme immediately
      updateTheme();
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  // Get current locale based on selected language
  Locale get currentLocale {
    if (selectedLanguage.value == 'bn') {
      return const Locale('bn', 'BD');
    }
    return const Locale('en', 'US');
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    try {
      selectedLanguage.value = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);

      // Update locale based on language code
      Locale newLocale;
      if (languageCode == 'bn') {
        newLocale = const Locale('bn', 'BD');
      } else {
        newLocale = const Locale('en', 'US');
      }

      Get.updateLocale(newLocale);

      Get.snackbar(
        'Success',
        'Language changed successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      debugPrint('Error changing language: $e');
    }
  }

  // Toggle dark mode
  Future<void> toggleDarkMode(bool value) async {
    try {
      isDarkMode.value = value;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, value);
      updateTheme();
    } catch (e) {
      debugPrint('Error toggling dark mode: $e');
    }
  }

  // Change primary color
  Future<void> changeColor(int index) async {
    try {
      if (index >= 0 && index < colorPalette.length) {
        selectedColorIndex.value = index;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_colorIndexKey, index);
        updateTheme();
      }
    } catch (e) {
      debugPrint('Error changing color: $e');
    }
  }

  // Change font family
  Future<void> changeFont(int index) async {
    try {
      if (index >= 0 && index < fontFamilies.length) {
        selectedFontIndex.value = index;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_fontIndexKey, index);
        updateTheme();

        // Show restart dialog
        Get.dialog(
          AlertDialog(
            title: const Text('Font Changed'),
            content: const Text(
              'Please restart the app to apply the new font throughout the entire app.',
            ),
            actions: [
              TextButton(onPressed: () => Get.back(), child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('Error changing font: $e');
    }
  }

  // Update theme in GetX
  void updateTheme() {
    Get.changeTheme(getThemeData());
    // Force rebuild all widgets
    Get.forceAppUpdate();
  }

  // Get current theme data
  ThemeData getThemeData() {
    final primaryColor = colorPalette[selectedColorIndex.value];
    final fontIndex = selectedFontIndex.value;

    // Get text theme based on selected font
    TextTheme? baseTextTheme;
    if (fontIndex > 0) {
      final fontFamily = fontFamilyValues[fontIndex];
      switch (fontFamily) {
        case 'Roboto':
          baseTextTheme = GoogleFonts.robotoTextTheme();
          break;
        case 'Poppins':
          baseTextTheme = GoogleFonts.poppinsTextTheme();
          break;
        case 'Lato':
          baseTextTheme = GoogleFonts.latoTextTheme();
          break;
        case 'Montserrat':
          baseTextTheme = GoogleFonts.montserratTextTheme();
          break;
        case 'OpenSans':
          baseTextTheme = GoogleFonts.openSansTextTheme();
          break;
        case 'NotoSans':
          baseTextTheme = GoogleFonts.notoSansTextTheme();
          break;
        case 'Ubuntu':
          baseTextTheme = GoogleFonts.ubuntuTextTheme();
          break;
      }
    }

    if (isDarkMode.value) {
      // Apply text theme for dark mode
      final baseTheme = ThemeData.dark();
      final darkTextTheme = baseTextTheme != null
          ? GoogleFonts.getTextTheme(
              fontFamilyValues[fontIndex],
              baseTheme.textTheme,
            )
          : baseTheme.textTheme;

      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.dark,
          surface: const Color(0xFF121212), // Darker background
          surfaceContainerHighest: const Color(0xFF1E1E1E), // Card background
        ),
        textTheme: darkTextTheme,
        primaryTextTheme: darkTextTheme,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          color: const Color(0xFF1E1E1E), // Darker card color
          shadowColor: Colors.black.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E), // Darker input field background
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade800),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          tileColor: Color(0xFF1E1E1E), // Darker ListTile background
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    } else {
      // Apply text theme for light mode
      final baseTheme = ThemeData.light();
      final lightTextTheme = baseTextTheme != null
          ? GoogleFonts.getTextTheme(
              fontFamilyValues[fontIndex],
              baseTheme.textTheme,
            )
          : baseTheme.textTheme;

      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryColor,
          brightness: Brightness.light,
        ),
        textTheme: lightTextTheme,
        primaryTextTheme: lightTextTheme,
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  // Save user profile
  Future<void> saveProfile({
    required String name,
    required String email,
    String? imagePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      userName.value = name;
      userEmail.value = email;

      await prefs.setString(_userNameKey, name);
      await prefs.setString(_userEmailKey, email);

      if (imagePath != null && imagePath.isNotEmpty) {
        profileImagePath.value = imagePath;
        await prefs.setString(_profileImageKey, imagePath);
      }

      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to save profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Update profile image only
  Future<void> updateProfileImage(String imagePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      profileImagePath.value = imagePath;
      await prefs.setString(_profileImageKey, imagePath);

      Get.snackbar(
        'Success',
        'Profile picture updated',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update profile picture: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Sync profile from Firebase user (silently without snackbar)
  Future<void> syncFromFirebaseUser({
    required String name,
    required String email,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Only update if the data is different
      if (userName.value != name || userEmail.value != email) {
        userName.value = name;
        userEmail.value = email;

        await prefs.setString(_userNameKey, name);
        await prefs.setString(_userEmailKey, email);

        debugPrint('Profile synced from Firebase: $name, $email');
      }
    } catch (e) {
      debugPrint('Error syncing profile from Firebase: $e');
    }
  }

  // Clear profile data on logout
  Future<void> clearFirebaseProfile() async {
    try {
      // Clear only Firebase-related data, keep local profile if exists
      // Or you can clear everything by uncommenting below:
      // final prefs = await SharedPreferences.getInstance();
      // userName.value = '';
      // userEmail.value = '';
      // await prefs.remove(_userNameKey);
      // await prefs.remove(_userEmailKey);

      debugPrint('Firebase profile cleared');
    } catch (e) {
      debugPrint('Error clearing Firebase profile: $e');
    }
  }

  // Get current primary color
  Color get primaryColor => colorPalette[selectedColorIndex.value];

  // Get current color name
  String get currentColorName => colorNames[selectedColorIndex.value];

  // Check if user profile is complete
  bool get isProfileComplete =>
      userName.value.isNotEmpty && userEmail.value.isNotEmpty;

  // Get user initials for avatar
  String getUserInitials() {
    if (userName.value.isEmpty) return 'U';
    final names = userName.value.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return userName.value[0].toUpperCase();
  }

  // Reset all personalization settings
  Future<void> resetToDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_darkModeKey);
      await prefs.remove(_colorIndexKey);

      isDarkMode.value = false;
      selectedColorIndex.value = 0;

      updateTheme();

      Get.snackbar(
        'Success',
        'Theme reset to defaults',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reset theme: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
