import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:get/get.dart';
import '../controllers/security_controller.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _hasShownLock = false;

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
    screenLock(
      context: context,
      correctString: controller.getStoredPattern(),
      canCancel: false,
      onUnlocked: _onUnlocked,
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
