import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/expense.dart';
import 'database_helper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class FirebaseService extends GetxService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  final Rx<User?> currentUser = Rx<User?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isSyncing = false.obs;
  final RxBool autoSyncEnabled = true.obs;
  final RxString lastSyncTime = ''.obs;

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      currentUser.value = user;
    });
  }

  // Check internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.first != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // Sign up with email and password
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      isLoading.value = true;

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      // Create user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(name);

      // Create user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSync': FieldValue.serverTimestamp(),
      });

      isLoading.value = false;
      return {'success': true, 'message': 'Account created successfully'};
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = 'An error occurred';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak (minimum 6 characters)';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for this email';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid';
      } else {
        // Show detailed error for debugging
        message = 'Firebase Auth Error: ${e.code}\n${e.message}';
      }
      return {'success': false, 'message': message, 'errorCode': e.code};
    } catch (e) {
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'errorDetails': e.toString(),
      };
    }
  }

  // Sign in with email and password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      await _auth.signInWithEmailAndPassword(email: email, password: password);

      isLoading.value = false;
      return {'success': true, 'message': 'Signed in successfully'};
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found for this email';
      } else if (e.code == 'wrong-password') {
        message = 'Wrong password provided';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid';
      } else if (e.code == 'user-disabled') {
        message = 'This user account has been disabled';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      isLoading.value = false;
      return {'success': false, 'message': e.toString()};
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      isLoading.value = true;

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      await _auth.sendPasswordResetEmail(email: email);

      isLoading.value = false;
      return {'success': true, 'message': 'Password reset email sent'};
    } on FirebaseAuthException catch (e) {
      isLoading.value = false;
      String message = 'An error occurred';
      if (e.code == 'user-not-found') {
        message = 'No user found for this email';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is invalid';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      isLoading.value = false;
      return {'success': false, 'message': e.toString()};
    }
  }

  // Upload local data to cloud
  Future<Map<String, dynamic>> uploadToCloud() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'success': false, 'message': 'Please sign in first'};
      }

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      isSyncing.value = true;

      // Get all local expenses
      final expenses = await _dbHelper.getExpenses();

      // Upload each expense
      final batch = _firestore.batch();
      for (var expense in expenses) {
        final docRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .doc(expense.id.toString());

        batch.set(docRef, expense.toMap(), SetOptions(merge: true));
      }

      await batch.commit();

      // Update last sync time
      await _firestore.collection('users').doc(user.uid).update({
        'lastSync': FieldValue.serverTimestamp(),
      });

      lastSyncTime.value = DateTime.now().toString();
      isSyncing.value = false;

      return {
        'success': true,
        'message': 'Data uploaded successfully',
        'count': expenses.length,
      };
    } catch (e) {
      isSyncing.value = false;
      return {'success': false, 'message': e.toString()};
    }
  }

  // Download cloud data to local
  Future<Map<String, dynamic>> downloadFromCloud() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'success': false, 'message': 'Please sign in first'};
      }

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      isSyncing.value = true;

      // Get all cloud expenses
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .get();

      // Clear local database
      // await _dbHelper.clearAllData(); // Optional: only if full restore

      // Insert cloud expenses to local
      int count = 0;
      for (var doc in snapshot.docs) {
        final expense = Expense.fromMap(doc.data());
        await _dbHelper.insertExpense(expense);
        count++;
      }

      lastSyncTime.value = DateTime.now().toString();
      isSyncing.value = false;

      return {
        'success': true,
        'message': 'Data downloaded successfully',
        'count': count,
      };
    } catch (e) {
      isSyncing.value = false;
      return {'success': false, 'message': e.toString()};
    }
  }

  // Sync data (two-way sync)
  Future<Map<String, dynamic>> syncData() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'success': false, 'message': 'Please sign in first'};
      }

      // Check internet
      if (!await hasInternetConnection()) {
        return {'success': false, 'message': 'No internet connection'};
      }

      isSyncing.value = true;

      // Get local expenses
      final localExpenses = await _dbHelper.getExpenses();

      // Get cloud expenses
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .get();

      // Create maps for easier comparison
      final localMap = {for (var e in localExpenses) e.id: e};
      final cloudMap = {
        for (var doc in snapshot.docs)
          int.parse(doc.id): Expense.fromMap(doc.data()),
      };

      int uploaded = 0;
      int downloaded = 0;

      // Upload local expenses not in cloud
      final batch = _firestore.batch();
      for (var expense in localExpenses) {
        if (!cloudMap.containsKey(expense.id)) {
          final docRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('expenses')
              .doc(expense.id.toString());
          batch.set(docRef, expense.toMap());
          uploaded++;
        }
      }
      await batch.commit();

      // Download cloud expenses not in local
      for (var cloudExpense in cloudMap.values) {
        if (!localMap.containsKey(cloudExpense.id)) {
          await _dbHelper.insertExpense(cloudExpense);
          downloaded++;
        }
      }

      // Update last sync time
      await _firestore.collection('users').doc(user.uid).update({
        'lastSync': FieldValue.serverTimestamp(),
      });

      lastSyncTime.value = DateTime.now().toString();
      isSyncing.value = false;

      return {
        'success': true,
        'message': 'Data synced successfully',
        'uploaded': uploaded,
        'downloaded': downloaded,
      };
    } catch (e) {
      isSyncing.value = false;
      return {'success': false, 'message': e.toString()};
    }
  }

  // Auto sync when expense is added/updated
  Future<void> autoSyncExpense(Expense expense) async {
    if (!autoSyncEnabled.value || currentUser.value == null) return;
    if (!await hasInternetConnection()) return;

    try {
      final user = currentUser.value!;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expense.id.toString())
          .set(expense.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Auto sync failed: $e');
    }
  }

  // Delete expense from cloud
  Future<void> deleteExpenseFromCloud(int expenseId) async {
    if (currentUser.value == null) return;
    if (!await hasInternetConnection()) return;

    try {
      final user = currentUser.value!;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .doc(expenseId.toString())
          .delete();
    } catch (e) {
      print('Delete from cloud failed: $e');
    }
  }

  // Get cloud storage stats
  Future<Map<String, dynamic>> getCloudStats() async {
    try {
      final user = currentUser.value;
      if (user == null) {
        return {'totalExpenses': 0, 'lastSync': 'Never'};
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .get();

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final lastSync = userDoc.data()?['lastSync'];

      return {
        'totalExpenses': snapshot.docs.length,
        'lastSync': lastSync != null
            ? (lastSync as Timestamp).toDate().toString()
            : 'Never',
      };
    } catch (e) {
      return {'totalExpenses': 0, 'lastSync': 'Error'};
    }
  }
}
