import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/firebase_service.dart';
import '../controllers/expense_controller.dart';
import 'firebase_debug_screen.dart';

class CloudSyncScreen extends StatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  State<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends State<CloudSyncScreen> {
  final FirebaseService _firebaseService = Get.find<FirebaseService>();

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleSync() async {
    final result = await _firebaseService.syncData();

    if (result['success']) {
      // Refresh ExpenseController to show updated data
      try {
        final expenseController = Get.find<ExpenseController>();
        await expenseController.fetchExpenses();
      } catch (e) {
        print('Error refreshing expenses: $e');
      }

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
      // Refresh ExpenseController to show updated data
      try {
        final expenseController = Get.find<ExpenseController>();
        await expenseController.fetchExpenses();
      } catch (e) {
        print('Error refreshing expenses: $e');
      }

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
          // Show message to sign in from drawer
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 24),
                  const Text(
                    'Sign In Required',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please sign in from the drawer menu to access cloud backup & sync features.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          // Show sync options directly
          return _buildSyncOptions(user);
        }
      }),
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
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Auto Sync'),
                  subtitle: const Text(
                    'Automatically sync when you add/edit expenses',
                  ),
                  value: _firebaseService.autoSyncEnabled.value,
                  onChanged: (value) {
                    _firebaseService.autoSyncEnabled.value = value;
                  },
                ),
                const Divider(height: 1),
                Obx(
                  () => SwitchListTile(
                    title: const Text('Real-time Sync'),
                    subtitle: const Text(
                      'Automatically sync changes from other devices',
                    ),
                    value: _firebaseService.realtimeSyncEnabled.value,
                    onChanged: (value) {
                      _firebaseService.toggleRealtimeSync(value);

                      Get.snackbar(
                        value ? 'Enabled' : 'Disabled',
                        value
                            ? 'Real-time sync is now active. Changes from other devices will appear instantly.'
                            : 'Real-time sync is disabled. Use manual sync to update.',
                        backgroundColor: value ? Colors.green : Colors.orange,
                        colorText: Colors.white,
                        duration: const Duration(seconds: 3),
                      );
                    },
                  ),
                ),
              ],
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
