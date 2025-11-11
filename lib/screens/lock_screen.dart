import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:get/get.dart';
import '../controllers/security_controller.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _hasShownLock = false;

  // Helper method to trigger vibration
  void _vibrate() {
    HapticFeedback.vibrate();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasShownLock) {
        _hasShownLock = true;
        _showLockScreen();
      }
    });
  }

  void _showLockScreen() {
    final securityController = Get.find<SecurityController>();

    if (securityController.securityType.value == 'pin') {
      _showPinLockScreen(securityController);
    } else {
      _showPatternLockScreen(securityController);
    }
  }

  void _onUnlocked() {
    final securityController = Get.find<SecurityController>();
    securityController.unlockApp();

    // Pop the dialog first
    Navigator.of(context).pop();

    // Then navigate to home
    Future.delayed(const Duration(milliseconds: 100), () {
      if (Get.currentRoute == '/lock') {
        // Coming from splash, replace with home
        Get.offAllNamed('/home');
      } else {
        // Coming from background, go back
        Get.back();
      }
    });
  }

  void _showPinLockScreen(SecurityController controller) {
    screenLock(
      context: context,
      correctString: controller.getStoredPin(),
      canCancel: false,
      onUnlocked: _onUnlocked,
      onError: (int retries) {
        // Vibrate on wrong PIN
        _vibrate();
      },
      footer: Column(
        children: [
          if (controller.isBiometricEnabled.value)
            TextButton.icon(
              onPressed: () async {
                final success = await controller.authenticateWithBiometrics();
                if (success) {
                  _onUnlocked();
                }
              },
              icon: const Icon(Icons.fingerprint, size: 32),
              label: Text('use_biometric'.tr),
            ),
          const SizedBox(height: 20),
          Text(
            'app_name'.tr,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showPatternLockScreen(SecurityController controller) {
    // Show pattern lock dialog with PatternLock widget
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'draw_pattern'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: PatternLock(
                      selectedColor: Theme.of(context).colorScheme.primary,
                      pointRadius: 8,
                      showInput: true,
                      dimension: 3,
                      relativePadding: 0.7,
                      selectThreshold: 25,
                      fillPoints: true,
                      onInputComplete: (List<int> input) {
                        final enteredPattern = input.join(',');
                        final storedPattern = controller.getStoredPattern();

                        if (enteredPattern == storedPattern) {
                          Navigator.of(dialogContext).pop();
                          _onUnlocked();
                        } else {
                          // Vibrate on wrong pattern
                          _vibrate();
                          // Show error
                          Get.snackbar(
                            'error'.tr,
                            'incorrect_pattern'.tr,
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.red.withOpacity(0.8),
                            colorText: Colors.white,
                            duration: const Duration(seconds: 2),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (controller.isBiometricEnabled.value)
                    TextButton.icon(
                      onPressed: () async {
                        final success = await controller
                            .authenticateWithBiometrics();
                        if (success) {
                          Navigator.of(dialogContext).pop();
                          _onUnlocked();
                        }
                      },
                      icon: const Icon(Icons.fingerprint, size: 32),
                      label: Text('use_biometric'.tr),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 100,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            Text(
              'app_locked'.tr,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
