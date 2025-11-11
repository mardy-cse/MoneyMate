# Firebase Setup Guide for MoneyMate

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project"
3. Enter project name: **MoneyMate**
4. Click Continue
5. Disable Google Analytics (optional)
6. Click "Create Project"
7. Wait for project creation (takes 1-2 minutes)

---

## Step 2: Register Android App

1. In Firebase Console, click "Add app" → Select **Android** icon
2. Enter package name: `com.example.money_mate` 
   (Find this in `android/app/build.gradle.kts` → `namespace`)
3. Enter app nickname (optional): **MoneyMate Android**
4. Leave SHA-1 empty for now (not needed for basic features)
5. Click "Register app"
6. **Download `google-services.json`**
7. Place this file in: `android/app/google-services.json`
8. Click "Next" → "Next" → "Continue to console"

---

## Step 3: Configure Android Build Files

### 3.1 Update `android/build.gradle.kts`

Open `android/build.gradle.kts` and add Google Services plugin:

```kotlin
plugins {
    id("com.android.application") version "8.1.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.20" apply false
    id("com.google.gms.google-services") version "4.4.0" apply false  // ADD THIS LINE
}
```

### 3.2 Update `android/app/build.gradle.kts`

Open `android/app/build.gradle.kts` and add at the bottom:

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")  // ADD THIS LINE
}

// ... rest of the file

dependencies {
    // ... existing dependencies
}

// ADD THIS AT THE VERY BOTTOM
apply(plugin = "com.google.gms.google-services")
```

---

## Step 4: Enable Firebase Services

### 4.1 Enable Authentication

1. In Firebase Console → Left menu → **Build** → **Authentication**
2. Click "Get started"
3. Click on **Email/Password** provider
4. Toggle "Enable"
5. Click "Save"

### 4.2 Enable Firestore Database

1. In Firebase Console → Left menu → **Build** → **Firestore Database**
2. Click "Create database"
3. Select **Start in test mode** (we'll secure it later)
4. Choose location: `asia-south1 (Mumbai)` or closest to you
5. Click "Enable"

### 4.3 Configure Firestore Security Rules

After database is created:
1. Go to "Rules" tab
2. Replace with these rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // User's expenses collection
      match /expenses/{expenseId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. Click "Publish"

---

## Step 5: iOS Setup (Optional - if you want iOS support)

1. In Firebase Console, click "Add app" → Select **iOS** icon
2. Enter iOS bundle ID: `com.example.moneyMate`
3. Download `GoogleService-Info.plist`
4. Place in: `ios/Runner/GoogleService-Info.plist`
5. Open `ios/Runner.xcworkspace` in Xcode
6. Right-click "Runner" → Add Files → Add `GoogleService-Info.plist`
7. Make sure "Copy items if needed" is checked

---

## Step 6: Test the Setup

### Run these commands:

```bash
# Clean the project
flutter clean

# Get packages
flutter pub get

# For Android
flutter run

# For iOS (Mac only)
cd ios
pod install
cd ..
flutter run
```

---

## Step 7: Verify Firebase Connection

1. Run the app
2. Open drawer menu
3. Tap "Cloud Backup & Sync"
4. Try to sign up with email/password
5. If successful, check Firebase Console:
   - Authentication → Users (should show new user)
   - Firestore Database → users collection (should have user document)

---

## Troubleshooting

### Error: "No Firebase App '[DEFAULT]' has been created"

**Solution:**
- Make sure `google-services.json` is in `android/app/` folder
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### Error: "FirebaseException: PERMISSION_DENIED"

**Solution:**
- Check Firestore security rules
- Make sure you're signed in before syncing
- Rules should allow authenticated users

### Error: "MissingPluginException"

**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

---

## Security Best Practices

### Production Firestore Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Users collection
    match /users/{userId} {
      allow read, write: if isOwner(userId);
      
      // User's expenses
      match /expenses/{expenseId} {
        allow read, write: if isOwner(userId);
      }
    }
  }
}
```

---

## Features Implemented ✅

1. **Email/Password Authentication**
   - Sign up with name, email, password
   - Sign in
   - Sign out
   - Forgot password (email reset link)

2. **Cloud Backup**
   - Upload all local data to cloud
   - Download cloud data to local
   - Two-way sync (merge local + cloud)

3. **Auto Sync**
   - Automatically sync when adding expense (if enabled)
   - Automatically sync when deleting expense
   - Toggle auto-sync on/off

4. **Cloud Stats**
   - View total expenses in cloud
   - View last sync time
   - Connection status check

5. **Offline Support**
   - Works offline (local SQLite)
   - Auto-syncs when internet returns
   - Shows internet status

---

## Next Steps (Premium Features)

- [ ] Google Sign-In
- [ ] Apple Sign-In
- [ ] Real-time sync (listen to cloud changes)
- [ ] Multi-device conflict resolution
- [ ] Backup scheduling
- [ ] Export cloud data
- [ ] Family sharing (multiple users)

---

## Support

If you face any issues:
1. Check Firebase Console logs
2. Check Flutter console for errors
3. Verify `google-services.json` is correct
4. Make sure package name matches
5. Clean and rebuild project

---

**Author:** MoneyMate Team  
**Version:** 1.0.0  
**Last Updated:** November 12, 2025
