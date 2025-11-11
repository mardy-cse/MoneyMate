# 💾 Data Recovery Guide - MoneyMate

## 🔄 App Uninstall করার পর Data Recovery

### ✅ **Steps to Recover Your Data:**

1. **MoneyMate Install করুন** (নতুন phone বা reinstall করার পর)

2. **App Open করুন**

3. **Drawer Menu (☰) → Cloud Backup & Sync**

4. **Sign In** করুন:
   - আগের account এর email দিন
   - Password দিন
   - Sign In click করুন

5. **Dialog দেখাবে:** "Restore Data?"
   - **Sync Now** (Recommended): Cloud এর সাথে merge করবে
   - **Download**: শুধু cloud data নিবে
   - **Skip**: পরে করবেন

6. ✅ **সব data ফিরে পাবেন!**

---

## 📱 **Different Scenarios:**

### Scenario 1: নতুন Phone
```
Old Phone → Upload to Cloud
New Phone → Sign In → Download/Sync
✅ All data recovered!
```

### Scenario 2: App Uninstall করেছেন
```
Before Uninstall → Data in Cloud (if synced)
After Reinstall → Sign In → Download/Sync
✅ All data recovered!
```

### Scenario 3: Phone হারিয়ে গেছে
```
Old Phone → Data in Cloud (if auto-sync was ON)
New Phone → Install App → Sign In → Download
✅ All data recovered!
```

### Scenario 4: Multiple Devices
```
Device A → Add expenses → Auto Sync
Device B → Sign In → Sync Now
✅ Both devices have same data!
```

---

## 🎯 **Important Tips:**

### ✅ **Always Keep Auto Sync ON:**
- Settings তে Auto Sync toggle ON রাখুন
- প্রতিটা expense automatically cloud এ যাবে
- Manual sync করতে হবে না

### ✅ **Regular Backup:**
- সপ্তাহে একবার "Upload to Cloud" করুন
- নিশ্চিত হোন যে সব data synced আছে

### ✅ **Before Uninstalling:**
- Drawer → Cloud Backup & Sync
- "Upload to Cloud" click করুন
- Success message দেখুন
- তারপর uninstall করুন
- ✅ Data safe থাকবে!

---

## ⚠️ **Data Loss Prevention:**

### যেসব ক্ষেত্রে data হারাতে পারেন:

❌ **Auto Sync OFF + Never uploaded**
- Local database এ আছে
- Cloud এ নেই
- App uninstall করলে হারিয়ে যাবে

❌ **Never Signed In/Signed Up**
- Cloud sync কখনো করেননি
- Data শুধু local phone এ
- Phone নষ্ট হলে data চলে যাবে

✅ **Solution:**
- এখনই Sign Up করুন
- Auto Sync ON করুন
- একবার "Upload to Cloud" করুন
- ✅ Permanently safe!

---

## 🔐 **Security:**

### ✅ **Your Data is Safe:**
- End-to-end encryption by Firebase
- শুধু আপনিই access করতে পারবেন
- অন্য কেউ দেখতে পারবে না
- Password secure ভাবে stored

### ✅ **Privacy:**
- আপনার email/password দিয়ে login করতে হবে
- Wrong password = No access
- Multi-device support with same account

---

## 📊 **What Gets Synced:**

### ✅ Synced to Cloud:
- ✅ Expense title
- ✅ Amount
- ✅ Category
- ✅ Date
- ✅ Note
- ✅ Budget settings
- ✅ Saving goals

### ⚠️ NOT Synced (Yet):
- ⚠️ Voice recordings (file path only)
- ⚠️ Receipt images (file path only)
- ⚠️ App settings/preferences

**Note:** Media files থাকে local phone এ। Future update এ Firebase Storage ব্যবহার করে upload করা হবে।

---

## 🆘 **Troubleshooting:**

### Problem: Sign In করার পর data দেখছি না
**Solution:**
1. "Sync Now" বা "Download from Cloud" click করুন
2. Wait করুন success message এর জন্য
3. Home screen check করুন
4. ✅ Data এসে গেছে!

### Problem: "No data in cloud" দেখাচ্ছে
**Reason:** আগে কখনো upload করেননি
**Solution:**
1. Old phone/backup থাকলে সেখান থেকে upload করুন
2. নাহলে নতুন করে data entry করুন

### Problem: Auto Sync কাজ করছে না
**Solution:**
1. Cloud Sync screen এ যান
2. Auto Sync toggle check করুন
3. Internet connection check করুন
4. Sign In করা আছে কিনা check করুন

---

## 🎉 **Best Practice:**

```
Day 1:
✅ Sign Up with your email
✅ Enable Auto Sync
✅ Upload existing data (if any)

Daily:
✅ Auto Sync ON রাখুন
✅ Add expenses normally
✅ Automatically synced in background

Weekly:
✅ Check "Cloud Storage Stats"
✅ Verify total expenses count
✅ Manual "Sync Now" একবার

Before Important Events:
✅ Phone change করার আগে
✅ Phone repair দেওয়ার আগে
✅ App uninstall করার আগে
→ "Upload to Cloud" করুন!
```

---

## 📞 **Still Need Help?**

1. **Firebase Debug Screen** check করুন:
   - Cloud Sync → 🐛 Debug icon
   - সব status দেখুন

2. **Check Firebase Console:**
   - https://console.firebase.google.com/
   - Project: moneymate-56713
   - Firestore → users → your data

3. **Common Issues:**
   - No internet → Connect WiFi/Data
   - Wrong password → Reset password
   - Account not found → Sign Up first

---

**Remember:** Cloud Sync enable করলে আপনার financial data সবসময় safe থাকবে, কোনো device issue হলেও! 💪

---

**MoneyMate Team**  
Version: 1.0.0 - Cloud Edition  
Last Updated: November 12, 2025
