# Points & Gamification System Guide

## Overview
The Money Mate app now includes a points-based gamification system to incentivize user engagement and reward signup. Users earn points through signup and daily usage, with premium features unlocked after completing signup.

## Points Earning System

### 1. Signup Bonus: 50 Points (One-Time)
- **When**: Awarded immediately after successful user registration
- **How**: Automatically triggered in `auth_screen.dart` after signup completion
- **Notification**: Amber-colored snackbar with celebration emoji 🎉
- **Message**: "You earned 50 points! Debt Tracker & Cloud Sync unlocked!"

### 2. Daily Login Bonus: 10 Points
- **When**: Awarded once per calendar day on app launch
- **How**: Automatically checked in `home_screen.dart` initState
- **Tracking**: Uses last login date comparison (stored in SharedPreferences)
- **Notification**: Green snackbar with sparkle emoji ✨
- **Message**: "You earned 10 points for logging in today! Total: X points"

## Premium Features (Signup Required)

### Locked Features
The following features are locked until the user completes signup:

1. **Debt/Loan Tracker** (`debt_screen.dart`)
   - Shows premium lock screen with amber lock icon
   - Message: "Sign up to unlock Debt/Loan Tracker and get 50 bonus points!"
   - Button: "Sign Up Now" (navigates to auth screen)

2. **Cloud Backup & Sync** (`cloud_sync_screen.dart`)
   - Shows premium lock screen after user signs in but hasn't completed signup bonus
   - Message: "Complete signup to unlock Cloud Backup & Sync and get 50 bonus points!"
   - Button: "Sign Up Now" (navigates to auth screen)

### Unlock Mechanism
- Check: `PointsService().hasCompletedSignup()`
- Returns: `true` if user has received signup bonus, `false` otherwise
- Implementation: `FutureBuilder` wrapping the main content in both locked screens

## Technical Implementation

### Points Service (`lib/services/points_service.dart`)

#### Storage Keys (SharedPreferences)
- `total_points`: Total accumulated points (int)
- `last_login_date`: Last login date in yyyy-MM-dd format (String)
- `signup_bonus_received`: Boolean flag indicating signup completion (bool)

#### Core Methods

```dart
// Get current total points
Future<int> getTotalPoints()

// Add points to user's account
Future<Map<String, dynamic>> addPoints(int points)

// Award one-time signup bonus (50 points)
Future<Map<String, dynamic>> giveSignupBonus()

// Check and award daily login bonus (10 points)
Future<Map<String, dynamic>> checkDailyLogin()

// Check if user has completed signup (for premium features)
Future<bool> hasCompletedSignup()

// Reset points (testing/debugging only)
Future<void> resetPoints()
```

#### Return Values
All point-awarding methods return a Map with:
```dart
{
  'success': true/false,
  'pointsEarned': int (0 if already received),
  'totalPoints': int (current total),
  'message': String (user-friendly message)
}
```

## User Flow

### New User Journey
1. **Opens app** → Home screen loads (no points yet, premium features locked)
2. **Clicks "Sign In / Sign Up"** in drawer → Auth screen opens
3. **Completes signup form** → Account created
4. **Receives 50 points** → Success snackbar + Signup bonus notification
5. **Navigates to profile** → Auth screen removed from stack
6. **Premium features unlocked** → Can now access Debt Tracker & Cloud Sync
7. **Next day login** → Receives 10 daily points automatically

### Returning User Journey
1. **Opens app** → Daily login check runs in background
2. **If new day** → Green snackbar: "You earned 10 points for logging in today!"
3. **If same day** → No notification (already received today's bonus)
4. **Access premium features** → Full functionality available

## UI/UX Elements

### Signup Bonus Notification
- **Color**: Amber background (Colors.amber)
- **Duration**: 3 seconds
- **Title**: "🎉 Signup Bonus!"
- **Message**: "You earned 50 points! Debt Tracker & Cloud Sync unlocked!"

### Daily Login Notification
- **Color**: Green background (Colors.green)
- **Duration**: 2 seconds
- **Title**: "✨ Daily Bonus!"
- **Message**: "You earned 10 points for logging in today! Total: X points"

### Premium Lock Screen
- **Icon**: Amber lock outline (Icons.lock_outline, size 80)
- **Title**: "Premium Feature"
- **Message**: Feature-specific unlock instructions
- **Button**: "Sign Up Now" (amber, white text)

## Future Enhancement Ideas

### Potential Features
1. **Points Display**: Badge in AppBar or drawer showing total points
2. **Rewards Shop**: Exchange points for app themes, premium features, etc.
3. **Leaderboard**: Compare points with other users (if multiplayer)
4. **Achievements**: Unlock badges for milestones (100 points, 7-day streak, etc.)
5. **Streak Tracking**: Bonus multiplier for consecutive daily logins
6. **Point Decay**: Points expire if user is inactive for X days
7. **Point Gifting**: Share points with friends/family

### Recommended Next Steps
1. Add visible points counter in UI (drawer header or AppBar badge)
2. Create points history screen showing all earned points
3. Add streak tracking for daily logins (2x points on 7-day streak)
4. Create achievement system with milestone rewards

## Testing Checklist

### Signup Flow
- [ ] New user signup awards 50 points
- [ ] Signup bonus only awarded once (not on subsequent logins)
- [ ] Premium features unlock after signup
- [ ] Navigation works correctly (no back to auth screen)

### Daily Login Flow
- [ ] First login of the day awards 10 points
- [ ] Multiple logins on same day don't award extra points
- [ ] Date comparison works correctly across midnight boundary
- [ ] Total points update correctly

### Premium Feature Locks
- [ ] Debt Tracker shows lock screen before signup
- [ ] Cloud Sync shows lock screen after signin but before signup bonus
- [ ] Both features unlock after signup completion
- [ ] "Sign Up Now" button navigates to auth screen

### Edge Cases
- [ ] User signs out and signs back in (points persist)
- [ ] User uninstalls and reinstalls app (points reset - expected)
- [ ] Multiple rapid logins don't duplicate points
- [ ] Points service handles SharedPreferences errors gracefully

## Troubleshooting

### Issue: Points not awarded
- **Check**: SharedPreferences initialization
- **Fix**: Ensure `await SharedPreferences.getInstance()` succeeds

### Issue: Daily bonus awarded multiple times per day
- **Check**: `last_login_date` storage
- **Fix**: Verify date format is consistent (yyyy-MM-dd)

### Issue: Premium features remain locked after signup
- **Check**: `signup_bonus_received` flag in SharedPreferences
- **Fix**: Call `giveSignupBonus()` manually or reset and re-signup

### Issue: Navigation broken after signup
- **Check**: Using `Get.offNamed()` instead of `Get.toNamed()`
- **Fix**: Ensure auth screen uses `Get.offNamed('/profile')` to clear stack

## Code Locations

- **Points Service**: `lib/services/points_service.dart`
- **Auth Screen** (signup bonus): `lib/screens/auth_screen.dart` (lines 139-157)
- **Home Screen** (daily login): `lib/screens/home_screen.dart` (lines 57-76)
- **Debt Screen** (premium lock): `lib/screens/debt_screen.dart` (lines 130-196)
- **Cloud Sync Screen** (premium lock): `lib/screens/cloud_sync_screen.dart` (lines 149-253)

## Support & Maintenance

For any issues or questions about the points system:
1. Check this guide first
2. Review the code in `points_service.dart`
3. Test with `PointsService().resetPoints()` for debugging
4. Verify SharedPreferences values using device inspector

---

**Last Updated**: 2024
**Version**: 1.0
**Status**: Fully Implemented ✅
