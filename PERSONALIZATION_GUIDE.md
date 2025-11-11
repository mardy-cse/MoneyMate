# 🎨 MoneyMate Personalization Features

## Overview
MoneyMate now includes comprehensive personalization features that allow users to customize their app experience. All settings persist across app restarts using local storage.

---

## 🌟 Features Implemented

### 1. **Theme Customization** 🌓
- **Dark Mode Toggle**
  - Switch between light and dark themes
  - Instant UI updates using GetX reactive programming
  - Preference saved in SharedPreferences
  
- **Color Customization** 🎨
  - 8 predefined color options:
    - Green (default)
    - Blue
    - Orange
    - Purple
    - Pink
    - Cyan
    - Deep Orange
    - Blue Grey
  
  - Visual color picker with animated selection
  - Selected color applies throughout the entire app
  - Color preference persists across sessions

### 2. **User Profile** 👤
- **Profile Information**
  - Full name
  - Email address
  - Profile picture (placeholder with initials)
  - Email validation
  
- **Profile Display**
  - User avatar with initials in navigation drawer
  - Gradient avatar background matching theme color
  - Profile status indicator (complete/incomplete)
  - Quick access from home screen drawer

- **Currency Display**
  - Shows preferred currency from Settings
  - Quick link to change currency in Settings

### 3. **Language Selection** 🌍
- **Supported Languages**
  - English (United States) 🇺🇸
  - Bangla (Bangladesh) 🇧🇩
  
- **Implementation**
  - Radio button selection in Theme Customization screen
  - Instant language switching using GetX
  - Full app translation support
  - Language preference saved locally

### 4. **Smooth UI/UX** ⚡
- **Reactive Updates**
  - All changes reflect instantly across the app
  - GetX Obx widgets for reactive UI
  - No need to restart app
  
- **Modern Design**
  - Material 3 design principles
  - Gradient backgrounds and shadows
  - Smooth animations
  - Consistent card styling

---

## 📂 File Structure

```
lib/
├── controllers/
│   └── personalization_controller.dart   # Main controller for all personalization logic
├── screens/
│   ├── profile_screen.dart               # User profile management
│   ├── theme_customization_screen.dart   # Theme & color customization
│   └── home_screen.dart                  # Updated with profile display
├── services/
│   └── translations.dart                 # Language translations (already existed)
└── main.dart                             # Updated with PersonalizationController
```

---

## 🎯 How to Use

### For Users:

#### **Access Personalization**
1. Open the app
2. Tap the hamburger menu (☰) in the top-left
3. Choose:
   - **"My Profile"** - to set up your profile
   - **"Theme & Colors"** - to customize appearance

#### **Change Theme**
1. Go to **Settings** → **Theme & Colors**
2. Toggle the **Dark Mode** switch
3. See instant change!

#### **Change Color**
1. Go to **Settings** → **Theme & Colors**
2. Scroll to **"Primary Color"** section
3. Tap on any color circle or chip
4. Color applies instantly throughout the app

#### **Change Language**
1. Go to **Settings** → **Theme & Colors**
2. Scroll to **"Language"** section
3. Select English or বাংলা
4. App language changes immediately

#### **Set Up Profile**
1. Go to **Settings** → **My Profile**
2. Enter your name and email
3. Tap **"Save Profile"**
4. Your profile appears in the navigation drawer

#### **Reset Theme**
1. Go to **Theme & Colors**
2. Tap the reset icon (⟳) in the top-right
3. Confirm reset
4. Theme returns to default (Green + Light mode)

---

## 🔧 Technical Details

### **PersonalizationController**

#### Observable Variables:
```dart
final isDarkMode = false.obs;              // Dark mode state
final selectedColorIndex = 0.obs;          // Selected color index (0-7)
final userName = ''.obs;                   // User's name
final userEmail = ''.obs;                  // User's email
final profileImagePath = ''.obs;           // Profile image path
final selectedLanguage = 'en'.obs;         // Language code
```

#### Key Methods:
- `toggleDarkMode(bool value)` - Switch theme mode
- `changeColor(int index)` - Change primary color
- `changeLanguage(String code)` - Change app language
- `saveProfile({name, email, imagePath})` - Save user profile
- `resetToDefaults()` - Reset all theme settings
- `getThemeData()` - Generate current ThemeData
- `getUserInitials()` - Get user initials for avatar

### **State Management**
- Uses **GetX** for reactive state management
- **Obx()** widgets automatically rebuild when observables change
- Changes persist using **SharedPreferences**

### **Data Persistence**
All preferences are saved in SharedPreferences with these keys:
- `dark_mode` - Boolean for dark mode state
- `color_index` - Integer for selected color (0-7)
- `user_name` - String for user's name
- `user_email` - String for user's email
- `profile_image` - String for profile image path
- `app_language` - String for language code ('en' or 'bn')

### **Theme Generation**
The `getThemeData()` method dynamically generates Material 3 themes based on:
- Selected color (primary color)
- Dark/Light mode preference
- Consistent styling (card radius, button shapes, input decoration)

### **Language Integration**
- Integrates with existing `AppTranslations` class
- Uses GetX `Get.updateLocale()` for instant switching
- Full support for English and Bangla
- Easy to add more languages

---

## 🎨 Color Palette

| Color Name | Hex Code | Visual |
|-----------|----------|--------|
| Green | `#4CAF50` | 🟢 Default |
| Blue | `#2196F3` | 🔵 |
| Orange | `#FF9800` | 🟠 |
| Purple | `#9C27B0` | 🟣 |
| Pink | `#E91E63` | 🩷 |
| Cyan | `#00BCD4` | 🔷 |
| Deep Orange | `#FF5722` | 🟧 |
| Blue Grey | `#607D8B` | ⬜ |

---

## 🚀 Future Enhancements

### Potential additions:
1. **Profile Picture Upload**
   - Camera integration
   - Gallery picker
   - Image cropping

2. **More Languages**
   - Hindi
   - Spanish
   - French
   - Arabic

3. **Font Size Options**
   - Small
   - Medium (default)
   - Large
   - Extra Large

4. **Custom Color Picker**
   - Allow users to choose any color
   - Color wheel or RGB sliders

5. **Theme Presets**
   - Pre-designed themes
   - Seasonal themes
   - High contrast mode

6. **Backup & Sync**
   - Cloud backup of preferences
   - Sync across devices

---

## 📱 Screenshots Flow

### Navigation:
```
Home Screen (Drawer)
├── My Profile → Profile Screen
│   ├── Edit Name
│   ├── Edit Email
│   └── View Currency
│
├── Theme & Colors → Theme Customization Screen
│   ├── Dark Mode Toggle
│   ├── Color Palette Selector
│   ├── Language Selection
│   ├── Preview Section
│   └── Reset Button
│
└── Settings → Settings Screen
    └── Personalization Section
        ├── My Profile
        └── Theme & Colors
```

---

## ✅ Testing Checklist

- [x] Dark mode toggles correctly
- [x] Light mode toggles correctly
- [x] All 8 colors work properly
- [x] Selected color persists after app restart
- [x] Dark mode preference persists after app restart
- [x] Profile saves correctly
- [x] Profile displays in drawer
- [x] User initials show correctly
- [x] Language switches instantly
- [x] Language preference persists
- [x] English translations work
- [x] Bangla translations work
- [x] Reset theme works
- [x] Theme applies to all screens
- [x] Navigation works correctly
- [x] Profile validation works
- [x] Email validation works

---

## 🐛 Known Issues
- Profile picture upload not yet implemented (shows initials only)
- Image upload feature shows "Coming soon" message

---

## 📝 Notes for Developers

### Adding a New Color:
1. Add color to `colorPalette` list in PersonalizationController
2. Add color name to `colorNames` list
3. Index automatically handled

### Adding a New Language:
1. Add translations to `AppTranslations` in `translations.dart`
2. Add language option in Theme Customization screen
3. Update `changeLanguage()` method locale mapping

### Modifying Theme:
1. Edit `getThemeData()` method in PersonalizationController
2. Add/modify theme properties as needed
3. Theme automatically applies to all screens

---

## 📞 Support
For issues or questions about personalization features, please check:
1. This documentation
2. Controller comments in code
3. GetX documentation: https://pub.dev/packages/get

---

**Version:** 1.0.0  
**Last Updated:** November 11, 2025  
**Author:** MoneyMate Development Team
