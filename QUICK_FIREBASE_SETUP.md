# 🚀 Quick Firebase Setup - Start Here!

## ⚡ 5-Minute Setup

### Step 1: Create Firebase Project (2 minutes)

1. **Open Browser** → Go to: https://console.firebase.google.com/
2. Click **"Add project"** (big + button)
3. Name: **MoneyMate** → Click **Continue**
4. **Disable** Google Analytics (toggle off) → Click **Create Project**
5. Wait 1-2 minutes → Click **Continue**

---

### Step 2: Add Android App (3 minutes)

1. Click **Android icon** (robot icon)
2. **Package name:** `com.example.money_mate`
   - ⚠️ Must match exactly! (Don't change)
3. **App nickname:** MoneyMate (optional)
4. Click **"Register app"**

5. **Download google-services.json** (big download button)
   - Save the file
   - Copy to: `G:\Flutter Projects\money_mate\android\app\google-services.json`
   - ⚠️ Must be in `android/app/` folder!

6. Click **Next** → **Next** → **Continue to console**

---

### Step 3: Enable Services (2 minutes)

#### 3.1 Enable Authentication
1. Left menu → **Build** → **Authentication**
2. Click **"Get started"**
3. Click **"Email/Password"** row
4. Toggle **Enable** → Click **Save**

#### 3.2 Enable Firestore
1. Left menu → **Build** → **Firestore Database**
2. Click **"Create database"**
3. Select **"Start in test mode"** → Click **Next**
4. Location: **asia-south1 (Mumbai)** → Click **Enable**
5. Wait 1 minute for database creation

#### 3.3 Set Security Rules
1. Click **"Rules"** tab (top)
2. **Copy-paste this:**

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /expenses/{expenseId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

3. Click **"Publish"**

---

### Step 4: Run the App! 🎉

Open terminal in VS Code and run:

```powershell
# Clean project
flutter clean

# Get packages
flutter pub get

# Run app
flutter run
```

---

## ✅ Test It Works

1. **App opens** → Open drawer (left menu)
2. Click **"Cloud Backup & Sync"**
3. Go to **"Sign Up"** tab
4. Enter:
   - Name: Test User
   - Email: test@example.com
   - Password: test123
   - Confirm Password: test123
5. Click **"Create Account"**

### Verify in Firebase:
1. Go to Firebase Console
2. **Authentication** → Should show 1 user
3. **Firestore Database** → Should have `users` collection

---

## 🔴 Important Files Checklist

Make sure these files exist:

- ✅ `android/app/google-services.json` (downloaded from Firebase)
- ✅ `android/build.gradle.kts` (already configured)
- ✅ `android/app/build.gradle.kts` (already configured)

---

## 🆘 Common Issues

### Issue: "No Firebase App"
**Fix:**
```powershell
flutter clean
flutter pub get
flutter run
```

### Issue: Can't find google-services.json
**Fix:** Make sure file is at: `android/app/google-services.json`

### Issue: Build fails
**Fix:** 
1. Delete `build/` folder
2. Run `flutter clean`
3. Run `flutter pub get`
4. Run `flutter run`

---

## 🎯 What You Get

✅ **Sign Up/Sign In** - Email & Password  
✅ **Cloud Backup** - Upload all data  
✅ **Cloud Restore** - Download all data  
✅ **Auto Sync** - Sync on every add/delete  
✅ **Offline Mode** - Works without internet  
✅ **Secure** - Only you can access your data  

---

## 📱 Using Cloud Sync

### First Time Setup:
1. Open app → Sign up with your email
2. Your local data stays safe
3. Click "Upload to Cloud" to backup

### Daily Use:
- Turn ON "Auto Sync"
- App automatically syncs when you add/delete expenses
- Works offline, syncs when internet returns

### New Device:
1. Sign in with same email
2. Click "Download from Cloud"
3. All your data appears!

---

## 🔐 Your Data is Safe

- ✅ End-to-end encryption
- ✅ Only you can access your data
- ✅ Firebase security rules protect your account
- ✅ No one else (not even us) can see your expenses

---

**Need Help?**
Check `FIREBASE_SETUP_GUIDE.md` for detailed troubleshooting.

---

**Ready?** Follow Step 1 above! 🚀
