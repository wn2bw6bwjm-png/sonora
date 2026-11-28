# SONORA Build Instructions

This document provides comprehensive instructions for building SONORA locally and via CI/CD.

## Prerequisites

### Development Environment
- **Flutter**: 3.50.0 (stable channel)
- **Dart**: 3.14.0
- **Android SDK**: API 34+ (for Android builds)
- **Xcode**: 16.0+ (for iOS builds, macOS only)
- **Git**: Latest

### Verify Installation
```bash
flutter doctor -v
flutter --version
# Should show: Flutter 3.50.0 • channel stable
```

## Local Development Build

### Get Dependencies
```bash
flutter pub get
```

### Run on Device/Emulator
```bash
# Android
flutter run -d <device-id>

# iOS (macOS only)
flutter run -d <device-id>

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# macOS (macOS only)
flutter run -d macos

# Linux
flutter run -d linux
```

## Android Builds

### Debug APK
```bash
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Release AAB (for Play Store)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Signed Release Build (requires keystore)
```bash
# Configure android/key.properties (see CI_CD_SECRETS.md)
flutter build apk --release
flutter build appbundle --release
```

### Install on Device
```bash
# Debug
adb install build/app/outputs/flutter-apk/app-debug.apk

# Release
adb install build/app/outputs/flutter-apk/app-release.apk
```

## iOS Builds (macOS Only)

### Debug Build
```bash
flutter build ios --debug --no-codesign
```

### Release Build (Unsigned - Free Apple Account)
```bash
flutter build ios --release --no-codesign
# Output: build/ios/iphoneos/Runner.app
```

### Create Unsigned IPA
```bash
mkdir -p Payload
cp -r build/ios/iphoneos/Runner.app Payload/
zip -r SONORA-unsigned.ipa Payload/
```

### Signed Build (Apple Developer Program Required)
```bash
# Requires certificates and provisioning profile
flutter build ios --release
# Then use Xcode to archive and export:
# Product → Archive → Distribute App → App Store Connect
```

### Install on Device
```bash
# Via Xcode: Connect device, select in Xcode, click Run
# Via command line (requires ios-deploy):
ios-deploy --bundle build/ios/iphoneos/Runner.app
```

## Cross-Platform Build Matrix

| Platform | Command | Output | Install Method |
|----------|---------|--------|----------------|
| Android Debug | `flutter build apk --debug` | `.apk` | `adb install` |
| Android Release | `flutter build apk --release` | `.apk` | `adb install` / File transfer |
| Android Play Store | `flutter build appbundle --release` | `.aab` | Play Console upload |
| iOS Debug | `flutter build ios --debug` | `.app` | Xcode / ios-deploy |
| iOS Release | `flutter build ios --release` | `.app` | Xcode Archive |
| iOS IPA (unsigned) | Manual zip | `.ipa` | AltStore / Sideloadly |
| iOS IPA (signed) | Xcode Archive | `.ipa` | TestFlight / App Store |
| Web | `flutter build web` | `/build/web` | Static hosting |
| Windows | `flutter build windows` | `/build/windows` | `.exe` installer |
| macOS | `flutter build macos` | `/build/macos` | `.dmg` / `.app` |
| Linux | `flutter build linux` | `/build/linux` | `.tar.gz` / AppImage |

## CI/CD Pipeline (GitHub Actions)

### Automatic Builds
The following workflows run automatically:

| Workflow | Trigger | Artifacts |
|----------|---------|-----------|
| Checks | Push/PR | Coverage report |
| Android | Push/PR + tags | APK, AAB |
| iOS | Push/PR + tags | IPA (unsigned/signed) |
| Release | Tags (v*) | All artifacts + GitHub Release |

### Manual Trigger
```bash
# Trigger workflow manually via GitHub UI or:
gh workflow run android.yml
gh workflow run ios.yml
gh workflow run release.yml
```

### Download Artifacts
```bash
# List recent runs
gh run list --workflow=android.yml

# Download artifacts from specific run
gh run download <run-id> --name SONORA-Android-APK
gh run download <run-id> --name SONORA-Android-AAB
gh run download <run-id> --name SONORA-iOS-IPA-Unsigned
```

## Required Secrets for CI/CD

See `CI_CD_SECRETS.md` for complete documentation.

### Quick Setup
1. Go to GitHub repo → Settings → Secrets and variables → Actions
2. Add Android secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`
3. Add iOS secrets: `IOS_CERTIFICATE_P12`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE`

## Version Management

### Version Format
Follow Semantic Versioning: `MAJOR.MINOR.PATCH` (e.g., `1.0.0`)

### Incrementing Version
Update in `pubspec.yaml`:
```yaml
version: 1.0.0+1
# Format: version: <version>+<build_number>
```

### Creating Release
```bash
# Tag the release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0

# This triggers the release workflow automatically
```

## Troubleshooting

### Common Issues

#### "flutter pub get" fails
```bash
# Clear cache and retry
flutter clean
flutter pub cache repair
flutter pub get
```

#### Android Build Fails
```bash
# Clean and rebuild
cd android
./gradlew clean
cd ..
flutter clean
flutter build apk --release
```

#### iOS Build Fails
```bash
# Clean and rebuild
cd ios
xcodebuild clean -workspace Runner.xcworkspace -scheme Runner
cd ..
flutter clean
flutter build ios --release
```

#### CocoaPods Issues
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Performance Tips
```bash
# Analyze APK size
flutter build apk --analyze-size

# Profile build
flutter build apk --profile
```

## Installation Instructions for Users

### Android
1. Download `SONORA-Android-APK` from GitHub Releases
2. Enable "Install from unknown sources" in Settings
3. Open the APK file and install
4. Grant storage permission for local music import

### iOS (Unsigned IPA)
1. Download `SONORA-iOS-IPA-Unsigned` from GitHub Releases
2. Install via **AltStore** (recommended):
   - Install AltStore on computer
   - Connect iPhone via USB
   - Install AltStore on iPhone
   - Open AltStore → My Apps → + → Select IPA
3. Or use **Sideloadly** (Windows/macOS):
   - Download Sideloadly
   - Connect iPhone
   - Drag IPA to Sideloadly → Start
4. Trust developer in Settings → General → VPN & Device Management

### iOS (Signed IPA - TestFlight/App Store)
1. Join TestFlight beta (link from developer)
2. Or download from App Store when published

## Architecture Notes

### Supported Formats
- **Audio**: MP3, M4A, AAC, WAV, FLAC, OGG, Opus, WMA
- **Images**: JPEG, PNG, WebP (for album art)

### Minimum OS Versions
- **Android**: API 21 (Android 5.0 Lollipop)
- **iOS**: iOS 13.0+

### Permissions
- **Android**: READ_MEDIA_AUDIO (API 33+), READ_EXTERNAL_STORAGE (API 32-), INTERNET
- **iOS**: Media Library access (for local files), Network

## Support

For build issues:
1. Check `flutter doctor -v`
2. Review GitHub Actions logs
3. Consult `CI_CD_SECRETS.md` for signing issues
4. Open GitHub Issue with build logs