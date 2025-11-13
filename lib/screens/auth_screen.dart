import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../services/points_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();
  late TabController _tabController;

  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();

  bool _signInPasswordVisible = false;
  bool _signUpPasswordVisible = false;
  bool _signUpConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (_signInEmailController.text.isEmpty ||
        _signInPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final result = await _firebaseService.signIn(
      email: _signInEmailController.text.trim(),
      password: _signInPasswordController.text,
    );

    if (result['success']) {
      Get.snackbar(
        'Success',
        result['message'],
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );

      // Replace auth screen with profile screen
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offNamed('/profile');
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Sign in failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _handleSignUp() async {
    if (_signUpNameController.text.isEmpty ||
        _signUpEmailController.text.isEmpty ||
        _signUpPasswordController.text.isEmpty ||
        _signUpConfirmPasswordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_signUpPasswordController.text !=
        _signUpConfirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    if (_signUpPasswordController.text.length < 6) {
      Get.snackbar(
        'Error',
        'Password must be at least 6 characters',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final result = await _firebaseService.signUp(
      email: _signUpEmailController.text.trim(),
      password: _signUpPasswordController.text,
      name: _signUpNameController.text.trim(),
    );

    if (result['success']) {
      // Clear the form fields
      _signUpNameController.clear();
      _signUpEmailController.clear();
      _signUpPasswordController.clear();
      _signUpConfirmPasswordController.clear();

      // Refresh the currentUser to ensure profile is populated
      await Future.delayed(const Duration(milliseconds: 500));

      // Give signup bonus points
      final pointsService = PointsService();
      final bonusResult = await pointsService.giveSignupBonus();

      Get.snackbar(
        'Success',
        result['message'],
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );

      // Show signup bonus notification
      if (bonusResult['success']) {
        await Future.delayed(const Duration(milliseconds: 500));
        Get.snackbar(
          '🎉 Signup Bonus!',
          'You earned ${bonusResult['pointsEarned']} points! Collect 250 points to unlock Premium Features.',
          backgroundColor: Colors.amber,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
        );
      }

      // Replace auth screen with profile screen
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offNamed('/profile');
    } else {
      Get.snackbar(
        'Error',
        result['message'] ?? 'Sign up failed',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Please enter your email',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              final result = await _firebaseService.resetPassword(
                emailController.text.trim(),
              );

              Get.back();

              if (result['success']) {
                Get.snackbar(
                  'Success',
                  result['message'],
                  backgroundColor: Colors.green,
                  colorText: Colors.white,
                );
              } else {
                Get.snackbar(
                  'Error',
                  result['message'],
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
              }
            },
            child: const Text('Send Reset Link'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tabController.index == 0
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            color: _tabController.index == 0
                                ? Colors.white
                                : Colors.black54,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sign In',
                            style: TextStyle(
                              color: _tabController.index == 0
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: _tabController.index == 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _tabController.index == 1
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward,
                            color: _tabController.index == 1
                                ? Colors.white
                                : Colors.black54,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sign Up',
                            style: TextStyle(
                              color: _tabController.index == 1
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: _tabController.index == 1
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildSignInTab(), _buildSignUpTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Icon(
            Icons.account_circle,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome Back!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _signInEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signInPasswordController,
            obscureText: !_signInPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _signInPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _signInPasswordVisible = !_signInPasswordVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPasswordDialog,
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => ElevatedButton(
              onPressed: _firebaseService.isLoading.value
                  ? null
                  : _handleSignIn,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _firebaseService.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(
            Icons.person_add,
            size: 80,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            'Create an account',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _signUpNameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpPasswordController,
            obscureText: !_signUpPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _signUpPasswordVisible = !_signUpPasswordVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _signUpConfirmPasswordController,
            obscureText: !_signUpConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _signUpConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _signUpConfirmPasswordVisible =
                        !_signUpConfirmPasswordVisible;
                  });
                },
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Obx(
            () => ElevatedButton(
              onPressed: _firebaseService.isLoading.value
                  ? null
                  : _handleSignUp,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _firebaseService.isLoading.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
