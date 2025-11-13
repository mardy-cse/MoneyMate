class UserPoints {
  int totalPoints;
  int dailyStreak;
  DateTime? lastLoginDate;
  bool isPremium;
  DateTime? premiumExpiryDate;

  UserPoints({
    this.totalPoints = 0,
    this.dailyStreak = 0,
    this.lastLoginDate,
    this.isPremium = false,
    this.premiumExpiryDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalPoints': totalPoints,
      'dailyStreak': dailyStreak,
      'lastLoginDate': lastLoginDate?.toIso8601String(),
      'isPremium': isPremium ? 1 : 0,
      'premiumExpiryDate': premiumExpiryDate?.toIso8601String(),
    };
  }

  factory UserPoints.fromMap(Map<String, dynamic> map) {
    return UserPoints(
      totalPoints: map['totalPoints'] ?? 0,
      dailyStreak: map['dailyStreak'] ?? 0,
      lastLoginDate: map['lastLoginDate'] != null
          ? DateTime.parse(map['lastLoginDate'])
          : null,
      isPremium: (map['isPremium'] == 1) == true,
      premiumExpiryDate: map['premiumExpiryDate'] != null
          ? DateTime.parse(map['premiumExpiryDate'])
          : null,
    );
  }

  // Check if premium is still active
  bool get isActivePremium {
    if (!isPremium) return false;
    if (premiumExpiryDate == null) return false;
    return DateTime.now().isBefore(premiumExpiryDate!);
  }
}

// Constants
class PointsConfig {
  static const int dailyLoginPoints = 10; // Changed from 5 to 10
  static const int signupBonusPoints = 50; // New: signup bonus
  static const int premiumUnlockCost = 250;
  static const int premiumDurationDays = 30;
}
