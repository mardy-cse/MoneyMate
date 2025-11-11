# 🚨 URGENT FIX - Authentication Not Enabled

## Error: CONFIGURATION_NOT_FOUND

Your Firebase project has Authentication **NOT ENABLED**.

## 🔥 Fix This NOW (2 minutes):

### Step 1: Open Firebase Console
1. Go to: https://console.firebase.google.com/
2. Select project: **moneymate-56713**

### Step 2: Enable Authentication
1. Click **"Build"** in left sidebar
2. Click **"Authentication"**
3. Click **"Get started"** button (big blue button)
4. You'll see sign-in methods

### Step 3: Enable Email/Password
1. Click on **"Email/Password"** row (first one)
2. Click the **toggle switch** to ENABLE
3. Click **"Save"** button
4. ✅ Done!

### Step 4: Test Again
1. Go back to MoneyMate app
2. Try Sign Up again
3. It should work now! 🎉

---

## Visual Guide:

```
Firebase Console
├── Select Project: moneymate-56713
├── Left Menu → Build
├── Click: Authentication
├── Click: "Get started" (if first time)
└── Enable: Email/Password provider
    ├── Toggle: ON
    └── Save
```

---

## What You Should See:

**Before (Current):**
- Authentication page shows "Get started" button
- No sign-in methods enabled

**After (Fixed):**
- Email/Password provider shows "Enabled"
- Status: ✅ Active

---

## Still Not Working?

If still getting error after enabling:

1. **Wait 2-3 minutes** - Firebase needs time to propagate changes
2. **Restart the app** - Close and reopen MoneyMate
3. **Clear app data** (optional) - Settings → Apps → MoneyMate → Clear data

---

## Other Services Status:

✅ **Firebase Core:** Working  
✅ **Internet:** Connected  
⚠️ **Authentication:** NOT ENABLED (fix this!)  
✅ **Firestore:** Working  

---

**After enabling Authentication, your Sign Up will work perfectly!** 🚀

---

Need help? The exact error was:
```
firebase_auth/unknown
An internal error has occurred.
[ CONFIGURATION_NOT_FOUND ]
```

This specifically means: **Authentication service is not configured in Firebase Console.**
