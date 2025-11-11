import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class FirebaseDebugScreen extends StatefulWidget {
  const FirebaseDebugScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseDebugScreen> createState() => _FirebaseDebugScreenState();
}

class _FirebaseDebugScreenState extends State<FirebaseDebugScreen> {
  String _firebaseStatus = 'Checking...';
  String _authStatus = 'Checking...';
  String _firestoreStatus = 'Checking...';
  String _internetStatus = 'Checking...';

  @override
  void initState() {
    super.initState();
    _checkFirebaseSetup();
  }

  Future<void> _checkFirebaseSetup() async {
    // Check Firebase Core
    try {
      final app = Firebase.app();
      setState(() {
        _firebaseStatus =
            '✅ Firebase initialized\nProject: ${app.options.projectId}\nApp ID: ${app.options.appId}';
      });
    } catch (e) {
      setState(() {
        _firebaseStatus = '❌ Firebase NOT initialized\nError: $e';
      });
    }

    // Check Internet
    try {
      final connectivity = await Connectivity().checkConnectivity();
      setState(() {
        _internetStatus = connectivity.first == ConnectivityResult.none
            ? '❌ No internet connection'
            : '✅ Internet connected (${connectivity.first.name})';
      });
    } catch (e) {
      setState(() {
        _internetStatus = '❌ Error checking connection: $e';
      });
    }

    // Check Firebase Auth
    try {
      final auth = FirebaseAuth.instance;
      setState(() {
        _authStatus =
            '✅ Firebase Auth available\nCurrent user: ${auth.currentUser?.email ?? 'Not signed in'}';
      });

      // Try a test operation
      try {
        await auth.fetchSignInMethodsForEmail('test@example.com');
        setState(() {
          _authStatus += '\n✅ Auth service responding';
        });
      } catch (e) {
        if (e.toString().contains('not-enabled') ||
            e.toString().contains('api-not-enabled')) {
          setState(() {
            _authStatus +=
                '\n❌ Authentication NOT ENABLED in Firebase Console!';
          });
        } else {
          setState(() {
            _authStatus +=
                '\n✅ Auth service OK (${e.toString().split(':').first})';
          });
        }
      }
    } catch (e) {
      setState(() {
        _authStatus = '❌ Firebase Auth error: $e';
      });
    }

    // Check Firestore
    try {
      final firestore = FirebaseFirestore.instance;

      // Try to read from Firestore
      try {
        await firestore
            .collection('_test_collection_')
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 5));

        setState(() {
          _firestoreStatus = '✅ Firestore connected and accessible';
        });
      } catch (e) {
        if (e.toString().contains('not-enabled') ||
            e.toString().contains('api-not-enabled') ||
            e.toString().contains('PERMISSION_DENIED')) {
          setState(() {
            _firestoreStatus =
                '❌ Firestore NOT ENABLED in Firebase Console!\n'
                'Or security rules are blocking access.\n'
                'Error: $e';
          });
        } else {
          setState(() {
            _firestoreStatus =
                '⚠️ Firestore accessible but returned error:\n$e';
          });
        }
      }
    } catch (e) {
      setState(() {
        _firestoreStatus = '❌ Firestore error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Debug Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _firebaseStatus = 'Checking...';
                _authStatus = 'Checking...';
                _firestoreStatus = 'Checking...';
                _internetStatus = 'Checking...';
              });
              _checkFirebaseSetup();
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildInfoCard(
            'Firebase Core',
            _firebaseStatus,
            Icons.local_fire_department,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Internet Connection',
            _internetStatus,
            Icons.wifi,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Firebase Authentication',
            _authStatus,
            Icons.lock,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Cloud Firestore',
            _firestoreStatus,
            Icons.cloud,
            Colors.purple,
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          // Action buttons
          const Text(
            'Quick Actions:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text('Setup Instructions'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'To enable Firebase services:\n\n'
                      '1. Go to Firebase Console:\n'
                      '   https://console.firebase.google.com/\n\n'
                      '2. Select your project: moneymate-56713\n\n'
                      '3. Enable Authentication:\n'
                      '   • Go to Build → Authentication\n'
                      '   • Click "Get Started"\n'
                      '   • Enable "Email/Password" provider\n\n'
                      '4. Enable Firestore:\n'
                      '   • Go to Build → Firestore Database\n'
                      '   • Click "Create Database"\n'
                      '   • Select "Test mode"\n'
                      '   • Choose location (asia-south1)\n\n'
                      '5. Set Security Rules:\n'
                      '   • Go to Rules tab in Firestore\n'
                      '   • Paste the rules from QUICK_FIREBASE_SETUP.md\n'
                      '   • Click Publish\n\n'
                      '6. Restart the app and test again!',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.help_outline),
            label: const Text('How to Fix Issues'),
          ),

          const SizedBox(height: 8),

          OutlinedButton.icon(
            onPressed: () {
              // Copy all debug info to clipboard
              final debugInfo =
                  '''
Firebase Debug Information:
--------------------------

Firebase Core:
$_firebaseStatus

Internet Connection:
$_internetStatus

Firebase Authentication:
$_authStatus

Cloud Firestore:
$_firestoreStatus

--------------------------
App: MoneyMate
Package: com.example.money_mate
Date: ${DateTime.now()}
''';

              Get.snackbar(
                'Debug Info',
                'Debug information prepared',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
                messageText: Text(
                  debugInfo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                duration: const Duration(seconds: 10),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Debug Info'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String info, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.1),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                info,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
