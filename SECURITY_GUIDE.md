# 🔐 Security Guide - MoneyMate

## ⚠️ IMPORTANT: API Key Security

**NEVER commit API keys, secrets, or credentials to GitHub!**

---

## 🚨 What Happened?

Your Gemini API key was accidentally committed to GitHub and detected by GitGuardian.

### Immediate Actions Required:

1. **Revoke the compromised API key IMMEDIATELY**
   - Go to: https://aistudio.google.com/app/apikey
   - Delete the old API key
   - Generate a new one

2. **Update your local code with the new key**
   - See instructions below

---

## 🔧 How to Securely Store API Keys

### Method 1: Local Configuration (Recommended for Development)

1. Create a new file `lib/config/api_keys.dart` (this file is gitignored):

```dart
class ApiKeys {
  static const String geminiApiKey = 'YOUR_NEW_API_KEY_HERE';
}
```

2. Update `main.dart`:

```dart
import 'config/api_keys.dart';

// In main() function:
final geminiService = GeminiService();
geminiService.setApiKey(ApiKeys.geminiApiKey);
geminiService.initialize();
```

3. Add to `.gitignore`:
```
lib/config/api_keys.dart
```

### Method 2: Environment Variables (Recommended for Production)

1. Install flutter_dotenv package:
```yaml
dependencies:
  flutter_dotenv: ^5.1.0
```

2. Create `.env` file in project root:
```
GEMINI_API_KEY=your_actual_api_key_here
```

3. Add `.env` to `.gitignore`:
```
.env
.env.local
```

4. Load in main.dart:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  
  final geminiService = GeminiService();
  geminiService.setApiKey(dotenv.env['GEMINI_API_KEY']!);
  geminiService.initialize();
}
```

---

## 📝 Current Setup

After this fix, the API key is **no longer hardcoded** in the codebase.

**To run the app:**

1. Get a new Gemini API key from: https://aistudio.google.com/app/apikey

2. Open `lib/main.dart` and replace:
   ```dart
   geminiService.setApiKey('YOUR_NEW_API_KEY_HERE');
   ```
   
   With your actual key:
   ```dart
   geminiService.setApiKey('AIzaSy...');
   ```

3. **DO NOT commit this change to Git!**

---

## 🛡️ Security Checklist

- [ ] Old API key revoked
- [ ] New API key generated
- [ ] API key stored securely (not in code)
- [ ] `.gitignore` updated
- [ ] No sensitive files in Git history
- [ ] API key usage monitored (check Google Cloud Console)

---

## 🔍 How to Remove Sensitive Data from Git History

If API keys are already committed:

```bash
# Install BFG Repo-Cleaner
# Then run:
bfg --replace-text passwords.txt

# OR use git filter-branch:
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch lib/services/gemini_service.dart" \
  --prune-empty --tag-name-filter cat -- --all

# Force push (⚠️ WARNING: This rewrites history!)
git push origin --force --all
```

**Better approach:** Create a new private repository and migrate clean code.

---

## 📚 Best Practices

1. **Never hardcode secrets** in source code
2. **Use .gitignore** for sensitive files
3. **Use environment variables** for configuration
4. **Enable 2FA** on GitHub and Google accounts
5. **Regularly rotate** API keys
6. **Monitor usage** of API keys
7. **Use secret scanning tools** (GitHub Advanced Security, GitGuardian)

---

## 🆘 Need Help?

- **Google AI Studio**: https://aistudio.google.com/
- **GitHub Security**: https://github.com/settings/security
- **GitGuardian Docs**: https://docs.gitguardian.com/

---

## ✅ After Fixing

Once you've:
1. ✅ Revoked the old API key
2. ✅ Generated a new one
3. ✅ Updated your local code
4. ✅ Committed these security improvements

Your app will work normally, but now it's **secure**! 🎉

---

**Remember:** Security is not a one-time task. Stay vigilant! 🛡️
