import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';
import 'firebase_debug_screen.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({Key? key}) : super(key: key);

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen>
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
        duration: const Duration(seconds: 3),
      );

      // Auto sync after login
      _handleSync();
    } else {
      // Show detailed error
      Get.dialog(
        AlertDialog(
          title: const Text('Sign In Error'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? 'Unknown error occurred'),
                if (result['errorCode'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text('Error Code: ${result['errorCode']}'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('OK')),
          ],
        ),
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
      Get.snackbar(
        'Success',
        result['message'],
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Switch to sign in tab
      _tabController.animateTo(0);

      // Auto upload after signup
      _handleUpload();
    } else {
      // Show detailed error in dialog for debugging
      Get.dialog(
        AlertDialog(
          title: const Text('Sign Up Error'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result['message'] ?? 'Unknown error occurred'),
                if (result['errorCode'] != null) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Error Code:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Text(
                    result['errorCode'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                if (result['errorDetails'] != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Technical Details:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result['errorDetails'],
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Common Solutions:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Check your internet connection\n'
                  '• Verify Firebase is enabled in Console\n'
                  '• Check if Authentication is enabled\n'
                  '• Make sure google-services.json is correct',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Get.back(), child: const Text('Close')),
            ElevatedButton(
              onPressed: () {
                Get.back();
                // Copy error to clipboard (optional)
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleSync() async {
    final result = await _firebaseService.syncData();

    if (result['success']) {
      Get.snackbar(
        'Success',
        '${result['message']}\nUploaded: ${result['uploaded']}, Downloaded: ${result['downloaded']}',
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
      );
    }
  }

  Future<void> _handleUpload() async {
    final result = await _firebaseService.uploadToCloud();

    if (result['success']) {
      Get.snackbar(
        'Success',
        '${result['message']}\n${result['count']} expenses uploaded',
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
  }

  Future<void> _handleDownload() async {
    // Show confirmation dialog
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Download from Cloud'),
        content: const Text(
          'This will replace all local data with cloud data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Download'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _firebaseService.downloadFromCloud();

    if (result['success']) {
      Get.snackbar(
        'Success',
        '${result['message']}\n${result['count']} expenses downloaded',
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
  }

  Future<void> _handleSignOut() async {
    await _firebaseService.signOut();
    Get.snackbar(
      'Success',
      'Signed out successfully',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Backup & Sync'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Firebase Debug Info',
            onPressed: () {
              Get.to(() => const FirebaseDebugScreen());
            },
          ),
        ],
      ),
      body: Obx(() {
        final user = _firebaseService.currentUser.value;

        if (user == null) {
          // Show login/signup screen
          return Column(
            children: [
              Container(
                color: Theme.of(context).primaryColor,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  indicatorColor: Colors.white,
                  tabs: const [
                    Tab(text: 'Sign In'),
                    Tab(text: 'Sign Up'),
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
          );
        } else {
          // Show sync options
          return _buildSyncOptions(user);
        }
      }),
    );
  }

  Widget _buildSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.cloud, size: 80, color: Theme.of(context).primaryColor),
          const SizedBox(height: 20),
          const Text(
            'Sign in to sync your data',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
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

  Widget _buildSyncOptions(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 32, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Obx(
                    () => Text(
                      'Last Sync: ${_firebaseService.lastSyncTime.value.isEmpty ? "Never" : _firebaseService.lastSyncTime.value.split('.')[0]}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Auto sync toggle
          Card(
            child: SwitchListTile(
              title: const Text('Auto Sync'),
              subtitle: const Text(
                'Automatically sync when you add/edit expenses',
              ),
              value: _firebaseService.autoSyncEnabled.value,
              onChanged: (value) {
                _firebaseService.autoSyncEnabled.value = value;
              },
            ),
          ),
          const SizedBox(height: 20),

          // Sync actions
          const Text(
            'Sync Actions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Obx(
            () => _SyncButton(
              icon: Icons.sync,
              title: 'Sync Now',
              subtitle: 'Two-way sync between local and cloud',
              onPressed: _firebaseService.isSyncing.value ? null : _handleSync,
              color: Colors.blue,
            ),
          ),

          Obx(
            () => _SyncButton(
              icon: Icons.cloud_upload,
              title: 'Upload to Cloud',
              subtitle: 'Upload all local data to cloud',
              onPressed: _firebaseService.isSyncing.value
                  ? null
                  : _handleUpload,
              color: Colors.green,
            ),
          ),

          Obx(
            () => _SyncButton(
              icon: Icons.cloud_download,
              title: 'Download from Cloud',
              subtitle: 'Replace local data with cloud data',
              onPressed: _firebaseService.isSyncing.value
                  ? null
                  : _handleDownload,
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 20),

          // Cloud stats
          FutureBuilder<Map<String, dynamic>>(
            future: _firebaseService.getCloudStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final stats = snapshot.data!;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cloud Storage Stats',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Expenses:'),
                          Text(
                            '${stats['totalExpenses']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Last Cloud Sync:'),
                          Flexible(
                            child: Text(
                              stats['lastSync'].toString().split('.')[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // Sign out button
          OutlinedButton.icon(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Colors.red),
            ),
          ),

          const SizedBox(height: 20),

          // Syncing indicator
          Obx(
            () => _firebaseService.isSyncing.value
                ? const Card(
                    color: Colors.blue,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Syncing...',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Reset Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your email to receive password reset link'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final result = await _firebaseService.resetPassword(
                emailController.text.trim(),
              );

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
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _SyncButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;
  final Color color;

  const _SyncButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onPressed,
        enabled: onPressed != null,
      ),
    );
  }
}
