import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';

class SecurityController extends GetxController {
  // Observable variables
  final RxBool isSecurityEnabled = false.obs;
  final RxString securityType = 'pin'.obs; // 'pin' or 'pattern'
  final RxBool isBiometricEnabled = false.obs;
  final RxBool isBiometricAvailable = false.obs;
  final RxBool isLocked = true.obs;
  final RxInt autoLockDuration = 0.obs; // 0 = immediate, 1 = 1 min, 5 = 5 min

  // Private variables
  String _storedPin = '';
  String _storedPattern = '';
  final LocalAuthentication _localAuth = LocalAuthentication();
  DateTime? _lastActiveTime;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _checkBiometricAvailability();
  }

  // Load security settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isSecurityEnabled.value = prefs.getBool('security_enabled') ?? false;
      securityType.value = prefs.getString('security_type') ?? 'pin';
      isBiometricEnabled.value = prefs.getBool('biometric_enabled') ?? false;
      autoLockDuration.value = prefs.getInt('auto_lock_duration') ?? 0;
      _storedPin = prefs.getString('security_pin') ?? '';
      _storedPattern = prefs.getString('security_pattern') ?? '';

      // If security is enabled, lock the app initially
      if (isSecurityEnabled.value) {
        isLocked.value = true;
      } else {
        isLocked.value = false;
      }
    } catch (e) {
      print('Error loading security settings: $e');
    }
  }

  // Check if biometric authentication is available
  Future<void> _checkBiometricAvailability() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      isBiometricAvailable.value = canAuthenticate;
    } catch (e) {
      print('Error checking biometric availability: $e');
      isBiometricAvailable.value = false;
    }
  }

  // Enable security with PIN
  Future<bool> enablePinSecurity(String pin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('security_enabled', true);
      await prefs.setString('security_type', 'pin');
      await prefs.setString('security_pin', pin);

      isSecurityEnabled.value = true;
      securityType.value = 'pin';
      _storedPin = pin;
      isLocked.value = false; // Unlock after setting up

      return true;
    } catch (e) {
      print('Error enabling PIN security: $e');
      return false;
    }
  }

  // Enable security with Pattern
  Future<bool> enablePatternSecurity(String pattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('security_enabled', true);
      await prefs.setString('security_type', 'pattern');
      await prefs.setString('security_pattern', pattern);

      isSecurityEnabled.value = true;
      securityType.value = 'pattern';
      _storedPattern = pattern;
      isLocked.value = false; // Unlock after setting up

      return true;
    } catch (e) {
      print('Error enabling Pattern security: $e');
      return false;
    }
  }

  // Disable security
  Future<bool> disableSecurity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('security_enabled', false);
      await prefs.remove('security_pin');
      await prefs.remove('security_pattern');

      isSecurityEnabled.value = false;
      _storedPin = '';
      _storedPattern = '';
      isLocked.value = false;

      return true;
    } catch (e) {
      print('Error disabling security: $e');
      return false;
    }
  }

  // Verify PIN
  bool verifyPin(String pin) {
    if (pin == _storedPin) {
      isLocked.value = false;
      _updateLastActiveTime();
      return true;
    }
    return false;
  }

  // Verify Pattern
  bool verifyPattern(String pattern) {
    if (pattern == _storedPattern) {
      isLocked.value = false;
      _updateLastActiveTime();
      return true;
    }
    return false;
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    if (oldPin != _storedPin) {
      return false;
    }
    return await enablePinSecurity(newPin);
  }

  // Change Pattern
  Future<bool> changePattern(String oldPattern, String newPattern) async {
    if (oldPattern != _storedPattern) {
      return false;
    }
    return await enablePatternSecurity(newPattern);
  }

  // Toggle biometric authentication
  Future<bool> toggleBiometric(bool enable) async {
    try {
      if (enable && !isBiometricAvailable.value) {
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', enable);
      isBiometricEnabled.value = enable;

      return true;
    } catch (e) {
      print('Error toggling biometric: $e');
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometrics() async {
    try {
      if (!isBiometricAvailable.value || !isBiometricEnabled.value) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock Money Mate',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (didAuthenticate) {
        isLocked.value = false;
        _updateLastActiveTime();
      }

      return didAuthenticate;
    } catch (e) {
      print('Error authenticating with biometrics: $e');
      return false;
    }
  }

  // Set auto-lock duration
  Future<void> setAutoLockDuration(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auto_lock_duration', minutes);
      autoLockDuration.value = minutes;
    } catch (e) {
      print('Error setting auto-lock duration: $e');
    }
  }

  // Update last active time
  void _updateLastActiveTime() {
    _lastActiveTime = DateTime.now();
  }

  // Check if app should be locked based on auto-lock duration
  void checkAutoLock() {
    if (!isSecurityEnabled.value || autoLockDuration.value == 0) {
      return;
    }

    if (_lastActiveTime != null) {
      final difference = DateTime.now().difference(_lastActiveTime!);
      if (difference.inMinutes >= autoLockDuration.value) {
        lockApp();
      }
    }
  }

  // Lock the app
  void lockApp() {
    if (isSecurityEnabled.value) {
      isLocked.value = true;
    }
  }

  // Unlock the app
  void unlockApp() {
    isLocked.value = false;
    _updateLastActiveTime();
  }

  // Get stored PIN (for verification only)
  String getStoredPin() => _storedPin;

  // Get stored Pattern (for verification only)
  String getStoredPattern() => _storedPattern;

  // Check if security is properly set up
  bool isSecuritySetup() {
    if (!isSecurityEnabled.value) return false;
    if (securityType.value == 'pin' && _storedPin.isEmpty) return false;
    if (securityType.value == 'pattern' && _storedPattern.isEmpty) return false;
    return true;
  }
}
