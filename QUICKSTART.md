# 🚀 Quick Start Guide - Trash2Cash Mobile App

## ⚡ Get Running in 5 Minutes

### Step 1: Install Dependencies (1 minute)
```bash
flutter pub get
```

### Step 2: Configure Server URL (30 seconds)
Edit `lib/services/api_service.dart` line 8:
```dart
static String _baseUrl = 'http://YOUR_SERVER_IP:8080';
```

### Step 3: Run the App (30 seconds)
```bash
flutter run
```

---

## 📱 First Time Setup

### On App Launch:
1. **Welcome Screen** appears
2. Tap **"Scan QR to Get Started"**
3. Point camera at QR code from Trash2Cash station
4. ✅ Logged in automatically!

### If No Station Available:
You can test with a mock QR code containing any string token (backend will validate).

---

## 🎯 App Features Overview

### 🏠 Dashboard
- View your **points balance** (top card)
- See your **recycling impact** (total recycled, CO₂ saved)
- Quick access to **Redeem** and **History**
- Recent transactions list

### 📊 Transaction History
- Filter by type (deposits/redemptions)
- Detailed transaction information
- Pull to refresh

### 💰 Redemption
- Multiple redemption methods:
  - 💵 Cash at station
  - 🏦 Bank transfer
  - 🎁 Gift vouchers
- Real-time balance check
- Minimum points validation

### ⚙️ Settings (Dashboard Menu)
- Change server URL
- Test connection
- Logout

---

## 🧪 Testing Without Hardware

### Mock Backend Setup:
Create a simple test server:

```bash
# Python mock server (save as test_server.py)
from flask import Flask, jsonify, request
app = Flask(__name__)

@app.route('/api/auth/qr-login', methods=['POST'])
def login():
    return jsonify({
        'sessionToken': 'test_token_123',
        'user': {
            'id': 'user_001',
            'name': 'Test User',
            'points': 1500
        }
    })

@app.route('/api/user/profile')
def profile():
    return jsonify({
        'id': 'user_001',
        'name': 'Test User',
        'points': 1500
    })

@app.route('/api/transactions')
def transactions():
    return jsonify({
        'transactions': [
            {
                'id': 'txn_1',
                'userId': 'user_001',
                'type': 'deposit',
                'amount': 100,
                'itemType': 'plastic',
                'timestamp': '2025-10-28T10:00:00Z',
                'status': 'completed'
            }
        ]
    })

@app.route('/api/user/stats')
def stats():
    return jsonify({
        'totalRecycled': 25.5,
        'totalTransactions': 15,
        'co2Saved': 12.3
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

Run: `python test_server.py`

Then update app to use `http://YOUR_COMPUTER_IP:8080`

---

## 📝 Common Tasks

### Change App Name:
1. `pubspec.yaml`: Change `name: flutter_application_1`
2. `AndroidManifest.xml`: Already set to "Trash2Cash"

### Change App Icon:
```bash
flutter pub add flutter_launcher_icons
```
Add icon configuration in `pubspec.yaml`

### Build Release APK:
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build for iOS:
```bash
flutter build ios --release
```

---

## 🐛 Troubleshooting

### Camera Not Working
- Check permissions in `AndroidManifest.xml`
- Run: `flutter clean && flutter pub get`
- Restart app

### "Connection Refused"
- Verify server is running
- Check IP address (use `ipconfig` on Windows)
- Ensure phone/emulator on same network
- Try with HTTP (not HTTPS) for local testing

### QR Scanner Errors
- Update `qr_code_scanner` if issues persist
- Test on physical device (emulators may have camera issues)

### Build Errors
```bash
flutter clean
flutter pub get
flutter run
```

---

## 🎨 Customization

### Change Theme Colors:
Edit `lib/main.dart` line 20:
```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: Colors.blue, // Change from Colors.green
),
```

### Modify Points-to-Cash Ratio:
Edit calculation in screens (search for `* 0.01`):
```dart
final cashValue = points * 0.02; // Change from 0.01
```

### Add Custom Redemption Options:
Edit `lib/services/api_service.dart` method `_getDefaultRedemptionOptions()`

---

## 📚 Resources

- **Flutter Docs**: https://docs.flutter.dev
- **QR Scanner Plugin**: https://pub.dev/packages/qr_code_scanner
- **Provider State Management**: https://pub.dev/packages/provider

---

## 🤝 Support

For issues or questions:
1. Check `CONFIGURATION.md` for detailed setup
2. Review API endpoints in backend
3. Check Flutter console for error messages

---

## ✅ Checklist Before Deployment

- [ ] Update server URL to production
- [ ] Enable HTTPS
- [ ] Add proper app icons
- [ ] Test on multiple devices
- [ ] Configure proper permissions
- [ ] Add error tracking (Sentry/Firebase)
- [ ] Set up analytics
- [ ] Create privacy policy
- [ ] Test offline behavior
- [ ] Optimize images/assets
- [ ] Sign APK/IPA for stores

---

**Happy Recycling! 🌱♻️**
