# 🔐 Fix: Authentication Persistence in Release APK

## 🐛 Problem
App requires sign-in every time after closing/reopening when installed from release APK on personal device. This issue does **NOT** occur in debug builds.

---

## 🔍 Root Cause Analysis

### Primary Causes Identified:

1. **Debug Signing Key in Release Build**
   - Release build was using `debug` signing config
   - Different signing keys cause SharedPreferences data to be cleared
   - Firebase Auth session stored in SharedPreferences gets lost

2. **Code Obfuscation (Potential)**
   - R8/ProGuard may strip Firebase Auth classes
   - SharedPreferences keys might get obfuscated
   - Without proper rules, auth persistence can fail

---

## ✅ Solution Applied

### 1. Disabled Code Shrinking in Release Build

**File: `android/app/build.gradle.kts`**

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
        
        // ✅ Disable code shrinking and obfuscation
        isMinifyEnabled = false
        isShrinkResources = false
    }
}
```

**Why This Helps:**
- Prevents R8 from removing Firebase Auth classes
- Preserves SharedPreferences keys
- Ensures all authentication code remains intact
- Trade-off: Larger APK size (~5-10 MB more)

---

## 🧪 Testing Steps

### 1. Clean Previous Build
```powershell
flutter clean
cd android
./gradlew clean
cd ..
```

### 2. Build New Release APK
```powershell
flutter build apk --release
```

### 3. Install on Device
```powershell
# Uninstall old APK first to ensure clean state
adb uninstall com.example.money_mate

# Install new release APK
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 4. Test Authentication Persistence
1. Open app and sign in with email/password
2. Close app completely (swipe away from recent apps)
3. Reopen app
4. ✅ **Expected Result:** User should remain signed in

---

## 📚 Technical Details

### How Firebase Auth Persistence Works

Firebase Authentication in Flutter uses:
- **Platform Channels** to native Firebase SDKs
- **SharedPreferences** (Android) / **UserDefaults** (iOS) for token storage
- **Automatic Token Refresh** when app reopens

### Authentication Flow:

```dart
// On app start
FirebaseAuth.instance.authStateChanges().listen((User? user) {
  if (user != null) {
    // User is signed in (token loaded from SharedPreferences)
    print('User: ${user.email}');
  } else {
    // User is signed out
    print('Not signed in');
  }
});
```

### Where Auth Data is Stored:

**Android:**
```
/data/data/com.example.money_mate/shared_prefs/
├── FlutterSharedPreferences.xml
├── com.google.firebase.auth.internal.DefaultAuthState.xml
└── [other Firebase prefs]
```

**Key Files:**
- Firebase Auth tokens
- User ID
- Refresh tokens
- Last auth state

---

## 🔧 Alternative Solutions (If Issue Persists)

### Option 1: Create Proper Release Signing Config

If you have a release keystore:

```kotlin
android {
    signingConfigs {
        release {
            storeFile file("path/to/your-release-key.jks")
            storePassword "your-store-password"
            keyAlias "your-key-alias"
            keyPassword "your-key-password"
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}
```

### Option 2: Add ProGuard Rules (If Enabling Minify)

**Create: `android/app/proguard-rules.pro`**

```proguard
# Firebase Authentication
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

# SharedPreferences
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }

# Keep all classes used for authentication
-keepclassmembers class * {
    @com.google.firebase.auth.* <methods>;
}
```

**Then update `build.gradle.kts`:**

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

### Option 3: Force Auth Persistence Check

Add this to `lib/main.dart` in `main()` function:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure Firebase Auth persistence
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Force check auth state on app start
  final auth = FirebaseAuth.instance;
  await auth.authStateChanges().first;
  
  runApp(const MyApp());
}
```

---

## 🚨 Common Pitfalls

### 1. Changing Signing Keys
❌ **Problem:** Using different keys between builds
```kotlin
// Build 1: debug key
// Build 2: release key
// → SharedPreferences cleared!
```

✅ **Solution:** Use same signing key consistently
```kotlin
signingConfig = signingConfigs.getByName("debug")  // Keep consistent
```

### 2. App Data Cleared by System
- Android may clear app data if device storage is low
- User manually clears app data from Settings
- **Not a code issue** - expected behavior

### 3. Firebase Auth Token Expiry
- Firebase tokens expire after 1 hour
- Refresh tokens valid for longer periods
- Auto-refresh happens when app opens
- If offline for long time, may need re-authentication

---

## 📊 Verification Checklist

Test these scenarios after applying fix:

- [ ] Sign in with email/password
- [ ] Close app (swipe from recent apps)
- [ ] Reopen app → Should remain signed in ✅
- [ ] Force stop app from Settings
- [ ] Reopen app → Should remain signed in ✅
- [ ] Restart device
- [ ] Reopen app → Should remain signed in ✅
- [ ] Wait 24 hours (offline)
- [ ] Reopen app → Should remain signed in ✅

---

## 🎯 Expected Results

### After Fix:

| Scenario | Before Fix | After Fix |
|----------|-----------|-----------|
| Debug APK - App restart | ✅ Signed in | ✅ Signed in |
| Release APK - App restart | ❌ Sign in required | ✅ Signed in |
| Release APK - Device reboot | ❌ Sign in required | ✅ Signed in |
| Release APK - Force stop | ❌ Sign in required | ✅ Signed in |

---

## 📝 Additional Notes

### Why Debug Builds Work:

Debug builds use a **consistent debug signing key** across all builds:
```
~/.android/debug.keystore
```

This key doesn't change, so SharedPreferences data persists.

### Why Release Builds Failed:

Release builds were **also using the debug key**, but the issue was:
- **Code obfuscation** (R8/ProGuard) may have been enabled by default
- **Firebase Auth classes** got stripped or obfuscated
- **SharedPreferences keys** might have changed between builds

### Solution Summary:

1. ✅ Explicitly disabled code shrinking: `isMinifyEnabled = false`
2. ✅ Disabled resource shrinking: `isShrinkResources = false`
3. ✅ Kept consistent signing config: `signingConfig = debug`

---

## 🔗 Related Files Modified

- ✅ `android/app/build.gradle.kts` - Added minifyEnabled flags
- 📖 This documentation file

---

## 📚 References

- [Firebase Auth Persistence - Official Docs](https://firebase.google.com/docs/auth/flutter/manage-users#get_the_currently_signed-in_user)
- [Android ProGuard Rules](https://developer.android.com/studio/build/shrink-code)
- [Flutter Release Build](https://docs.flutter.dev/deployment/android#build-an-app-bundle)
- [SharedPreferences Best Practices](https://developer.android.com/reference/android/content/SharedPreferences)

---

## ✅ Status

**Issue:** Authentication not persisting in release APK  
**Fix Applied:** ✅ Disabled code shrinking in release build  
**Testing Required:** 🧪 Build new release APK and test on device  
**Expected Result:** User remains signed in after app restart  

---

**Last Updated:** 2025-01-19  
**Issue Reporter:** User (Release APK testing)  
**Fix Author:** GitHub Copilot AI Assistant  

