import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../controllers/personalization_controller.dart';
import '../services/currency_service.dart';
import '../services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final personalizationController = Get.find<PersonalizationController>();
  final currencyService = Get.find<CurrencyService>();
  final ImagePicker _imagePicker = ImagePicker();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController.text = personalizationController.userName.value;
    _emailController.text = personalizationController.userEmail.value;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      personalizationController.saveProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
      );

      // Navigate back after saving
      Get.back();
    }
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Profile Picture',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Camera Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera to take a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            const SizedBox(height: 10),

            // Gallery Option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select an existing photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),

            // Remove Photo Option (if photo exists)
            if (personalizationController
                .profileImagePath
                .value
                .isNotEmpty) ...[
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
                title: const Text('Remove Photo'),
                subtitle: const Text('Use default avatar'),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
            ],

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        await personalizationController.updateProfileImage(pickedFile.path);
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _removePhoto() async {
    await personalizationController.updateProfileImage('');
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool currentPasswordVisible = false;
    bool newPasswordVisible = false;
    bool confirmPasswordVisible = false;

    // Check if user is logged in with Firebase
    FirebaseService? firebaseService;
    try {
      firebaseService = Get.find<FirebaseService>();
      if (firebaseService.currentUser.value == null) {
        Get.snackbar(
          'Error',
          'You need to be signed in with Firebase to change password',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Firebase authentication not available',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Password
                  TextField(
                    controller: currentPasswordController,
                    obscureText: !currentPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          currentPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            currentPasswordVisible = !currentPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New Password
                  TextField(
                    controller: newPasswordController,
                    obscureText: !newPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          newPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            newPasswordVisible = !newPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                      helperText: 'Minimum 6 characters',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !confirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          confirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            confirmPasswordVisible = !confirmPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  currentPasswordController.dispose();
                  newPasswordController.dispose();
                  confirmPasswordController.dispose();
                  Get.back();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate inputs
                  if (currentPasswordController.text.isEmpty) {
                    Get.snackbar(
                      'Error',
                      'Please enter your current password',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (newPasswordController.text.length < 6) {
                    Get.snackbar(
                      'Error',
                      'New password must be at least 6 characters',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (newPasswordController.text !=
                      confirmPasswordController.text) {
                    Get.snackbar(
                      'Error',
                      'New passwords do not match',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  if (currentPasswordController.text ==
                      newPasswordController.text) {
                    Get.snackbar(
                      'Error',
                      'New password must be different from current password',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                    );
                    return;
                  }

                  // Show loading dialog
                  Get.dialog(
                    const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Changing password...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    barrierDismissible: false,
                  );

                  // Change password
                  try {
                    final result = await firebaseService!.changePassword(
                      currentPassword: currentPasswordController.text,
                      newPassword: newPasswordController.text,
                    );

                    // Close loading dialog
                    Get.back();

                    // Close password dialog
                    Get.back();

                    // Dispose controllers
                    currentPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();

                    // Show result
                    if (result['success']) {
                      Get.snackbar(
                        'Success',
                        result['message'],
                        backgroundColor: Colors.green,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    } else {
                      Get.snackbar(
                        'Error',
                        result['message'],
                        backgroundColor: Colors.red,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 4),
                      );
                    }
                  } catch (e) {
                    // Close loading dialog
                    Get.back();

                    // Close password dialog
                    Get.back();

                    // Dispose controllers
                    currentPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();

                    // Show error
                    Get.snackbar(
                      'Error',
                      'Failed to change password: $e',
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      duration: const Duration(seconds: 4),
                    );
                  }
                },
                child: const Text('Change Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Profile Avatar
              Obx(() {
                final hasImage =
                    personalizationController.profileImagePath.value.isNotEmpty;

                return Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: hasImage
                            ? null
                            : LinearGradient(
                                colors: [
                                  personalizationController.primaryColor,
                                  personalizationController.primaryColor
                                      .withOpacity(0.7),
                                ],
                              ),
                        boxShadow: [
                          BoxShadow(
                            color: personalizationController.primaryColor
                                .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: hasImage
                            ? Image.file(
                                File(
                                  personalizationController
                                      .profileImagePath
                                      .value,
                                ),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          personalizationController
                                              .primaryColor,
                                          personalizationController.primaryColor
                                              .withOpacity(0.7),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        personalizationController
                                            .getUserInitials(),
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  personalizationController.getUserInitials(),
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 3,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20),
                          color: Colors.white,
                          onPressed: _showImageSourceDialog,
                        ),
                      ),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 32),

              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!GetUtils.isEmail(value.trim())) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Preferred Currency (Display Only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferred Currency',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Obx(() {
                            return Text(
                              '${currencyService.selectedCurrencySymbol.value} ${currencyService.getCurrencyName(currencyService.selectedCurrency.value)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.toNamed('/settings');
                      },
                      child: const Text('Change'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Change Password Button (Only for Firebase users)
              Obx(() {
                // Check if Firebase is available and user is logged in
                try {
                  final firebaseService = Get.find<FirebaseService>();
                  if (firebaseService.currentUser.value != null) {
                    return SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text(
                          'Change Password',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  // Firebase not available
                }
                return const SizedBox.shrink();
              }),

              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save),
                  label: const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Profile Stats Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profile Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Obx(() {
                        return Row(
                          children: [
                            Icon(
                              personalizationController.isProfileComplete
                                  ? Icons.check_circle
                                  : Icons.info,
                              color: personalizationController.isProfileComplete
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                personalizationController.isProfileComplete
                                    ? 'Your profile is complete!'
                                    : 'Complete your profile to get personalized experience',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
