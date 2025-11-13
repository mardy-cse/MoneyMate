import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PointsService {
  static const String _totalPointsKey = 'total_points';
  static const String _lastLoginDateKey = 'last_login_date';
  static const String _signupBonusReceivedKey = 'signup_bonus_received';
  static const String _premiumUnlockedKey = 'premium_unlocked';
  static const String _premiumExpiryDateKey = 'premium_expiry_date';

  static const int signupBonusPoints = 50;
  static const int dailyLoginPoints = 10;
  static const int premiumUnlockCost = 250;
  static const int premiumDurationDays = 30;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user document reference
  DocumentReference? _getUserDoc() {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _firestore.collection('users').doc(user.uid);
  }

  // Get total points (from Firebase if signed in, otherwise SharedPreferences)
  Future<int> getTotalPoints() async {
    final userDoc = _getUserDoc();

    if (userDoc != null) {
      // User is signed in - get from Firebase
      try {
        final doc = await userDoc.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['points']?['total'] ?? 0;
        }
      } catch (e) {
        print('Error getting points from Firebase: $e');
      }
    }

    // Fallback to SharedPreferences (for offline or guest users)
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_totalPointsKey) ?? 0;
  }

  // Add points (saves to Firebase if signed in)
  Future<void> addPoints(int points) async {
    final currentPoints = await getTotalPoints();
    final newTotal = currentPoints + points;

    final userDoc = _getUserDoc();

    if (userDoc != null) {
      // User is signed in - save to Firebase
      try {
        await userDoc.set({
          'points': {
            'total': newTotal,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving points to Firebase: $e');
      }
    }

    // Also save to SharedPreferences as backup
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalPointsKey, newTotal);
  }

  // Give signup bonus (one-time)
  Future<Map<String, dynamic>> giveSignupBonus() async {
    final userDoc = _getUserDoc();
    bool hasReceivedBonus = false;

    if (userDoc != null) {
      // Check Firebase first
      try {
        final doc = await userDoc.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          hasReceivedBonus = data?['points']?['signupBonusReceived'] ?? false;
        }
      } catch (e) {
        print('Error checking signup bonus: $e');
      }
    } else {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      hasReceivedBonus = prefs.getBool(_signupBonusReceivedKey) ?? false;
    }

    if (hasReceivedBonus) {
      return {
        'success': false,
        'pointsEarned': 0,
        'totalPoints': await getTotalPoints(),
        'message': 'Signup bonus already received',
      };
    }

    await addPoints(signupBonusPoints);

    // Mark bonus as received
    if (userDoc != null) {
      try {
        await userDoc.set({
          'points': {'signupBonusReceived': true},
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error marking signup bonus: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_signupBonusReceivedKey, true);

    final totalPoints = await getTotalPoints();

    return {
      'success': true,
      'pointsEarned': signupBonusPoints,
      'totalPoints': totalPoints,
      'message': 'Congratulations! You earned $signupBonusPoints points!',
    };
  }

  // Check and give daily login bonus
  Future<Map<String, dynamic>> checkDailyLogin() async {
    final userDoc = _getUserDoc();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    String? lastLoginStr;

    if (userDoc != null) {
      // Check Firebase first
      try {
        final doc = await userDoc.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          final timestamp = data?['points']?['lastLoginDate'] as Timestamp?;
          if (timestamp != null) {
            lastLoginStr = timestamp.toDate().toIso8601String();
          }
        }
      } catch (e) {
        print('Error checking last login: $e');
      }
    } else {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      lastLoginStr = prefs.getString(_lastLoginDateKey);
    }

    if (lastLoginStr != null) {
      final lastLogin = DateTime.parse(lastLoginStr);
      final lastLoginDay = DateTime(
        lastLogin.year,
        lastLogin.month,
        lastLogin.day,
      );

      // If already logged in today, don't give points
      if (today == lastLoginDay) {
        final totalPoints = await getTotalPoints();
        return {
          'success': true,
          'isNewDay': false,
          'pointsEarned': 0,
          'totalPoints': totalPoints,
          'message': 'Already logged in today',
        };
      }
    }

    // New day - give points
    await addPoints(dailyLoginPoints);

    // Save last login date
    if (userDoc != null) {
      try {
        await userDoc.set({
          'points': {'lastLoginDate': Timestamp.fromDate(today)},
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving last login date: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginDateKey, today.toIso8601String());

    final totalPoints = await getTotalPoints();

    return {
      'success': true,
      'isNewDay': true,
      'pointsEarned': dailyLoginPoints,
      'totalPoints': totalPoints,
      'message': 'Daily login bonus: +$dailyLoginPoints points!',
    };
  }

  // Check if user has completed signup (has points)
  Future<bool> hasCompletedSignup() async {
    final userDoc = _getUserDoc();

    if (userDoc != null) {
      try {
        final doc = await userDoc.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          return data?['points']?['signupBonusReceived'] ?? false;
        }
      } catch (e) {
        print('Error checking signup: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_signupBonusReceivedKey) ?? false;
  }

  // Check if user can unlock premium (has enough points)
  Future<bool> canUnlockPremium() async {
    final points = await getTotalPoints();
    return points >= premiumUnlockCost;
  }

  // Check if premium is currently active (not expired)
  Future<bool> isPremiumUnlocked() async {
    final userDoc = _getUserDoc();
    DateTime? expiryDate;

    if (userDoc != null) {
      try {
        final doc = await userDoc.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          final timestamp = data?['points']?['premiumExpiryDate'] as Timestamp?;
          if (timestamp != null) {
            expiryDate = timestamp.toDate();
          }
        }
      } catch (e) {
        print('Error checking premium status: $e');
      }
    }

    if (expiryDate == null) {
      final prefs = await SharedPreferences.getInstance();
      final expiryStr = prefs.getString(_premiumExpiryDateKey);
      if (expiryStr != null) {
        expiryDate = DateTime.parse(expiryStr);
      }
    }

    if (expiryDate == null) return false;

    // Check if premium has expired
    final now = DateTime.now();
    return now.isBefore(expiryDate);
  }

  // Get remaining premium days
  Future<int> getRemainingPremiumDays() async {
    final userDoc = _getUserDoc();
    DateTime? expiryDate;

    if (userDoc != null) {
      try {
        final doc = await userDoc.get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>?;
          final timestamp = data?['points']?['premiumExpiryDate'] as Timestamp?;
          if (timestamp != null) {
            expiryDate = timestamp.toDate();
          }
        }
      } catch (e) {
        print('Error getting premium expiry: $e');
      }
    }

    if (expiryDate == null) {
      final prefs = await SharedPreferences.getInstance();
      final expiryStr = prefs.getString(_premiumExpiryDateKey);
      if (expiryStr != null) {
        expiryDate = DateTime.parse(expiryStr);
      }
    }

    if (expiryDate == null) return 0;

    final now = DateTime.now();
    if (now.isAfter(expiryDate)) return 0;

    return expiryDate.difference(now).inDays + 1;
  }

  // Redeem points to unlock premium for 30 days
  Future<Map<String, dynamic>> redeemPremium() async {
    final userDoc = _getUserDoc();
    final isUnlocked = await isPremiumUnlocked();

    if (isUnlocked) {
      final remainingDays = await getRemainingPremiumDays();
      return {
        'success': false,
        'message': 'Premium already active. $remainingDays days remaining.',
      };
    }

    final currentPoints = await getTotalPoints();
    if (currentPoints < premiumUnlockCost) {
      return {
        'success': false,
        'message':
            'Not enough points. Need ${premiumUnlockCost - currentPoints} more points.',
      };
    }

    // Calculate expiry date (30 days from now)
    final now = DateTime.now();
    final expiryDate = now.add(Duration(days: premiumDurationDays));

    // Reset points to 0 and set expiry date
    if (userDoc != null) {
      try {
        await userDoc.set({
          'points': {
            'total': 0,
            'premiumExpiryDate': Timestamp.fromDate(expiryDate),
            'lastRedeemedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error redeeming premium: $e');
        return {
          'success': false,
          'message': 'Failed to redeem premium. Please try again.',
        };
      }
    }

    // Also save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_totalPointsKey, 0);
    await prefs.setString(_premiumExpiryDateKey, expiryDate.toIso8601String());

    return {
      'success': true,
      'message': 'Premium unlocked for 30 days! Your points have been reset.',
      'remainingPoints': 0,
      'expiryDate': expiryDate,
    };
  }

  // Reset points (for testing)
  Future<void> resetPoints() async {
    final userDoc = _getUserDoc();

    if (userDoc != null) {
      try {
        await userDoc.set({
          'points': FieldValue.delete(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error resetting points in Firebase: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_totalPointsKey);
    await prefs.remove(_lastLoginDateKey);
    await prefs.remove(_signupBonusReceivedKey);
    await prefs.remove(_premiumUnlockedKey);
    await prefs.remove(_premiumExpiryDateKey);
  }
}
