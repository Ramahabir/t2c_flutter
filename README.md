# Trash2Cash Mobile App

A Flutter mobile application for the Trash2Cash smart recycling system.

## Features

- **QR Code Login**: Instant authentication by scanning station QR codes
- **Dashboard**: View points, transaction history, and recycling impact
- **Transaction History**: Track all deposits and redemptions
- **Points Redemption**: Convert points to cash, bank transfers, or vouchers
- **Real-time Updates**: WebSocket support for live balance updates
- **Offline Support**: Session persistence and local storage

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Physical device or emulator for testing

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Configuration

Before using the app, configure the server URL in the app settings:

- Default: `http://192.168.1.100:8080`
- Can be changed in Dashboard → Settings menu

### API Endpoints

The app expects the following backend endpoints:

- `POST /api/auth/qr-login` - QR code authentication
- `GET /api/user/profile` - Get user profile
- `GET /api/transactions` - Get transaction history
- `GET /api/user/stats` - Get user statistics
- `POST /api/redemption/redeem` - Redeem points
- `GET /api/redemption/options` - Get redemption options
- `POST /api/auth/logout` - Logout
- `GET /api/health` - Health check
- `WS /ws` - WebSocket connection for real-time updates

### Project Structure

```
lib/
├── main.dart                           # App entry point
├── models/                             # Data models
│   ├── user.dart
│   ├── transaction.dart
│   └── redemption_request.dart
├── services/                           # Business logic services
│   ├── api_service.dart
│   └── auth_service.dart
├── providers/                          # State management
│   └── app_state_provider.dart
└── screens/                            # UI screens
    ├── dashboard_screen.dart
    ├── qr_scanner_screen.dart
    ├── transaction_history_screen.dart
    └── redemption_screen.dart
```

## Building for Production

### Android

```bash
flutter build apk --release
```

### iOS

```bash
flutter build ios --release
```

## Permissions

The app requires the following permissions:

- **Camera**: For QR code scanning
- **Internet**: For API communication
- **Storage**: For session persistence

## Future Enhancements

- Maps integration for nearby recycling stations
- Push notifications for rewards and updates
- Leaderboards and gamification
- RFID/NFC support for contactless deposits
- Social sharing features
- Multi-language support
- Dark mode

## License

Copyright © 2025 Trash2Cash. All rights reserved.

