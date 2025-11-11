import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/flutter_screen_lock.dart';
import 'package:get/get.dart';
import '../controllers/security_controller.dart';

class SecuritySettingsScreen extends StatelessWidget {
  const SecuritySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final securityController = Get.find<SecurityController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('security_settings'.tr),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Obx(
        () => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Security Status Card
            _buildSecurityStatusCard(context, securityController),
            const SizedBox(height: 20),

            // Enable/Disable Security
            if (!securityController.isSecurityEnabled.value)
              _buildEnableSecuritySection(context, securityController)
            else
              _buildSecurityOptionsSection(context, securityController),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityStatusCard(
    BuildContext context,
    SecurityController controller,
  ) {
    final isEnabled = controller.isSecurityEnabled.value;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              isEnabled ? Icons.lock : Icons.lock_open,
              size: 64,
              color: isEnabled ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 12),
            Text(
              isEnabled ? 'security_enabled'.tr : 'security_disabled'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isEnabled
                  ? 'your_app_is_protected'.tr
                  : 'enable_security_to_protect'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableSecuritySection(
    BuildContext context,
    SecurityController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'choose_security_type'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.pin, size: 32),
          title: Text('pin_lock'.tr),
          subtitle: Text('use_4_6_digit_pin'.tr),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _setupPinLock(context, controller),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: const Icon(Icons.pattern, size: 32),
          title: Text('pattern_lock'.tr),
          subtitle: Text('draw_pattern_to_unlock'.tr),
          trailing: const Icon(Icons.arrow_forward_ios),
          onTap: () => _setupPatternLock(context, controller),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityOptionsSection(
    BuildContext context,
    SecurityController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Security Type
        Text(
          'current_security'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListTile(
          leading: Icon(
            controller.securityType.value == 'pin' ? Icons.pin : Icons.pattern,
            size: 32,
          ),
          title: Text(
            controller.securityType.value == 'pin'
                ? 'pin_lock'.tr
                : 'pattern_lock'.tr,
          ),
          subtitle: Text('tap_to_change'.tr),
          trailing: const Icon(Icons.edit),
          onTap: () => _changeSecurityMethod(context, controller),
          tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 24),

        // Biometric Authentication
        if (controller.isBiometricAvailable.value) ...[
          Text(
            'biometric_authentication'.tr,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint, size: 32),
            title: Text('use_biometric'.tr),
            subtitle: Text('fingerprint_face_id'.tr),
            value: controller.isBiometricEnabled.value,
            onChanged: (value) async {
              final success = await controller.toggleBiometric(value);
              if (success) {
                Get.snackbar(
                  'success'.tr,
                  value ? 'biometric_enabled'.tr : 'biometric_disabled'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              }
            },
            tileColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Auto-Lock Duration
        Text(
          'auto_lock'.tr,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'auto_lock_duration'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                RadioListTile<int>(
                  title: Text('immediately'.tr),
                  value: 0,
                  groupValue: controller.autoLockDuration.value,
                  onChanged: (value) => controller.setAutoLockDuration(value!),
                ),
                RadioListTile<int>(
                  title: Text('after_1_minute'.tr),
                  value: 1,
                  groupValue: controller.autoLockDuration.value,
                  onChanged: (value) => controller.setAutoLockDuration(value!),
                ),
                RadioListTile<int>(
                  title: Text('after_5_minutes'.tr),
                  value: 5,
                  groupValue: controller.autoLockDuration.value,
                  onChanged: (value) => controller.setAutoLockDuration(value!),
                ),
                RadioListTile<int>(
                  title: Text('after_15_minutes'.tr),
                  value: 15,
                  groupValue: controller.autoLockDuration.value,
                  onChanged: (value) => controller.setAutoLockDuration(value!),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Disable Security
        Center(
          child: ElevatedButton.icon(
            onPressed: () => _disableSecurity(context, controller),
            icon: const Icon(Icons.lock_open),
            label: Text('disable_security'.tr),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  void _setupPinLock(BuildContext context, SecurityController controller) {
    screenLockCreate(
      context: context,
      onConfirmed: (pin) async {
        final success = await controller.enablePinSecurity(pin);
        if (success) {
          Navigator.of(context).pop();
          Get.snackbar(
            'success'.tr,
            'pin_security_enabled'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      },
      digits: 6,
      footer: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('cancel'.tr),
      ),
    );
  }

  void _setupPatternLock(BuildContext context, SecurityController controller) {
    screenLockCreate(
      context: context,
      onConfirmed: (pattern) async {
        final success = await controller.enablePatternSecurity(pattern);
        if (success) {
          Navigator.of(context).pop();
          Get.snackbar(
            'success'.tr,
            'pattern_security_enabled'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        }
      },
      footer: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text('cancel'.tr),
      ),
    );
  }

  void _changeSecurityMethod(
    BuildContext context,
    SecurityController controller,
  ) {
    // First verify current security
    if (controller.securityType.value == 'pin') {
      screenLock(
        context: context,
        correctString: controller.getStoredPin(),
        onUnlocked: () {
          Navigator.of(context).pop();
          _showChangeSecurityOptions(context, controller);
        },
      );
    } else {
      screenLock(
        context: context,
        correctString: controller.getStoredPattern(),
        onUnlocked: () {
          Navigator.of(context).pop();
          _showChangeSecurityOptions(context, controller);
        },
      );
    }
  }

  void _showChangeSecurityOptions(
    BuildContext context,
    SecurityController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('change_security_method'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pin),
              title: Text('change_to_pin'.tr),
              onTap: () {
                Navigator.pop(context);
                _changeToPin(context, controller);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pattern),
              title: Text('change_to_pattern'.tr),
              onTap: () {
                Navigator.pop(context);
                _changeToPattern(context, controller);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
        ],
      ),
    );
  }

  void _changeToPin(BuildContext context, SecurityController controller) {
    bool isProcessing = false;

    screenLockCreate(
      context: context,
      title: Text('set_new_pin'.tr),
      confirmTitle: Text('confirm_new_pin'.tr),
      onConfirmed: (pin) async {
        if (isProcessing) return; // Prevent multiple calls
        isProcessing = true;

        // Save the new PIN
        final success = await controller.enablePinSecurity(pin);

        // Use GetX navigation to go back
        Get.back(); // Close the dialog

        // Small delay
        await Future.delayed(const Duration(milliseconds: 100));

        // Show message
        if (success) {
          Get.snackbar(
            'success'.tr,
            'pin_changed_successfully'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          );
        }
      },
      digits: 6,
      footer: TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
    );
  }

  void _changeToPattern(BuildContext context, SecurityController controller) {
    bool isProcessing = false;

    screenLockCreate(
      context: context,
      title: Text('draw_new_pattern'.tr),
      confirmTitle: Text('confirm_new_pattern'.tr),
      onConfirmed: (pattern) async {
        if (isProcessing) return; // Prevent multiple calls
        isProcessing = true;

        // Save the new pattern
        final success = await controller.enablePatternSecurity(pattern);

        // Use GetX navigation to go back
        Get.back(); // Close the dialog

        // Small delay
        await Future.delayed(const Duration(milliseconds: 100));

        // Show message
        if (success) {
          Get.snackbar(
            'success'.tr,
            'pattern_changed_successfully'.tr,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(16),
          );
        }
      },
      footer: TextButton(onPressed: () => Get.back(), child: Text('cancel'.tr)),
    );
  }

  void _disableSecurity(BuildContext context, SecurityController controller) {
    // First verify current security
    if (controller.securityType.value == 'pin') {
      screenLock(
        context: context,
        correctString: controller.getStoredPin(),
        onUnlocked: () async {
          Navigator.of(context).pop();
          final success = await controller.disableSecurity();
          if (success) {
            Get.snackbar(
              'success'.tr,
              'security_disabled_successfully'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        },
      );
    } else {
      screenLock(
        context: context,
        correctString: controller.getStoredPattern(),
        onUnlocked: () async {
          Navigator.of(context).pop();
          final success = await controller.disableSecurity();
          if (success) {
            Get.snackbar(
              'success'.tr,
              'security_disabled_successfully'.tr,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
            );
          }
        },
      );
    }
  }
}
