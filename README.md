# MomentCue Mobile

A modern, privacy-first, offline-first mobile app for micro-health check-ins.

## Overview

MomentCue helps users with micro-health check-ins including water intake, posture breaks, eye breaks, medications, breathing exercises, and micro-exercises. It features extremely flexible scheduling, reliable notifications, low-friction interactions, and a delightful user experience while maintaining complete privacy and offline functionality.

## Key Features

- **Privacy-First**: All data stored locally by default, with optional encrypted backup
- **Offline-First**: Core functionality works without internet connection
- **Flexible Scheduling**: Support for one-time, recurring (RFC5545 RRULE), and custom sequence schedules
- **Reliable Notifications**: Native notifications with timezone awareness and device restart handling
- **One-Tap Actions**: Complete tasks directly from notifications and widgets
- **Modern UI**: Clean interface with subtle animations and accessibility support
- **Cross-Platform**: Single codebase for iOS and Android using Flutter

## Technical Stack

- **Framework**: Flutter (stable channel)
- **State Management**: Provider
- **Local Storage**: Hive with optional encryption
- **Notifications**: flutter_local_notifications
- **Recurrence**: RFC5545 RRULE support
- **Timezone**: timezone + flutter_native_timezone
- **Security**: Platform keychain/keystore for encryption keys

## Architecture

### Layers
- **Presentation**: Flutter UI screens and widgets
- **Domain**: Check models and schedule domain logic
- **Services**: Storage, Schedule, Notification, Time, Backup, and Widget services
- **Background**: Boot receivers and notification reconciliation

### Core Models
- **Check**: Represents a health check-in with schedule, analytics, and configuration
- **Schedule**: Handles various scheduling types (one-time, preset, RRULE, sequence)
- **Analytics**: Tracks completion rates, streaks, and response times

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── check.dart
│   ├── schedule.dart
│   └── analytics.dart
├── services/                 # Business logic services
│   ├── storage_service.dart
│   ├── schedule_service.dart
│   ├── notification_service.dart
│   ├── time_service.dart
│   ├── backup_service.dart
│   └── widget_bridge.dart
├── screens/                  # UI screens
│   ├── home/
│   ├── check/
│   ├── analytics/
│   ├── settings/
│   └── onboarding/
├── widgets/                  # Reusable UI components
├── utils/                    # Utility functions
├── l10n/                     # Localization files
└── generated/                # Generated code
```

## Getting Started

### Prerequisites

1. **Flutter SDK**: Install Flutter 3.10.0 or higher
2. **Development Environment**: Android Studio, VS Code, or your preferred IDE
3. **Platform SDKs**: 
   - Android SDK (API level 21+)
   - Xcode (for iOS development)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/yourusername/momentcue-mobile.git
   cd momentcue-mobile
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate code** (after making model changes):
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

### Development Setup

1. **Enable developer options** on your Android device or start an emulator
2. **For iOS**: Open `ios/Runner.xcworkspace` in Xcode and configure signing
3. **Permissions**: The app requires notification permissions for core functionality

## Building for Release

### Android

1. **Generate keystore** (first time):
   ```bash
   keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Build release APK**:
   ```bash
   flutter build apk --release
   ```

3. **Build App Bundle** (for Play Store):
   ```bash
   flutter build appbundle --release
   ```

### iOS

1. **Build for iOS**:
   ```bash
   flutter build ios --release
   ```

2. **Archive in Xcode** for App Store submission

## Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test/
```

## Localization

The app supports multiple languages. To add a new language:

1. Create `lib/l10n/app_[locale].arb` file
2. Run `flutter gen-l10n` to generate localization code
3. Update `lib/l10n/l10n.dart` to include the new locale

Currently supported languages:
- English (en) - Default
- Spanish (es)
- German (de)
- French (fr)

## Privacy & Security

- **Local Storage**: All data stored locally using Hive with optional AES encryption
- **Secure Keys**: Encryption keys stored in platform keychain/keystore
- **No Telemetry**: No analytics or tracking by default
- **Backup**: User-controlled encrypted backup to user's own cloud storage

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development Phases

### Phase 1-4 (MVP Core)
- [x] Project setup and architecture
- [ ] Core data models and storage
- [ ] Timezone and recurrence engine
- [ ] Notification service
- [ ] Basic UI screens

### Phase 5-6
- [ ] Native widgets (Android AppWidget, iOS WidgetKit)
- [ ] Backup/restore functionality

### Phase 7-8
- [ ] Comprehensive testing
- [ ] CI/CD pipeline
- [ ] Store publishing preparation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, please open an issue on GitHub or contact [your-email@domain.com].

## Acknowledgments

- Flutter team for the excellent cross-platform framework
- Open source community for the various packages used
- Users who provide feedback and contributions
