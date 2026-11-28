# GitHub Actions Secrets Configuration

This document describes the required secrets for SONORA CI/CD pipelines.

## Android Secrets

### Required for Signed Builds (Release Tags)

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `KEYSTORE_BASE64` | Base64-encoded keystore file (.jks or .keystore) | `base64 -w 0 your-release-key.jks` |
| `KEYSTORE_PASSWORD` | Keystore password | Your keystore password |
| `KEY_PASSWORD` | Key password | Your key password (may be same as keystore) |
| `KEY_ALIAS` | Key alias in keystore | Your key alias (e.g., `upload` or `release`) |

### Generating Keystore
```bash
keytool -genkey -v \
  -keystore release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload
```

### Configure Android Signing (android/key.properties)
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=keystore.jks
```

Add to `.gitignore`:
```
android/key.properties
android/keystore.jks
```

## iOS Secrets

### Required for Signed Builds (Release Tags)

| Secret Name | Description | How to Obtain |
|-------------|-------------|---------------|
| `IOS_CERTIFICATE_P12` | Base64-encoded .p12 certificate | `base64 -w 0 your-cert.p12` |
| `IOS_CERTIFICATE_PASSWORD` | Certificate password | Your .p12 password |
| `IOS_PROVISIONING_PROFILE` | Base64-encoded .mobileprovision | `base64 -w 0 your-profile.mobileprovision` |

### Generating Certificates
1. Create App ID in Apple Developer Console
2. Create Distribution Certificate
3. Create App Store Provisioning Profile
4. Export certificate as .p12 with password
5. Download provisioning profile

### Xcode Configuration
Add to `ios/Runner.xcodeproj/project.pbxproj` or use `ExportOptions.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>signingStyle</key>
    <string>manual</string>
    <key>signingCertificate</key>
    <string>Apple Distribution</string>
    <key>provisioningProfiles</key>
    <dict>
        <key>com.yourcompany.sonora</key>
        <string>Your Provisioning Profile Name</string>
    </dict>
</dict>
</plist>
```

## Adding Secrets to GitHub

1. Go to your repository on GitHub
2. Settings → Secrets and variables → Actions
3. Click "New repository secret"
4. Add each secret from the tables above

## Workflow Triggers

| Workflow | Trigger |
|----------|---------|
| `checks.yml` | Push/PR to main, master, develop |
| `android.yml` | Push/PR to main, master, develop + tags `v*` |
| `ios.yml` | Push/PR to main, master, develop + tags `v*` |
| `release.yml` | Push tags `v*` |

## Artifact Names

| Workflow | Artifact Name | Retention |
|----------|---------------|-----------|
| checks | coverage | 7 days |
| android (debug) | SONORA-Android-APK | 30 days |
| android (release) | SONORA-Android-AAB | 30 days |
| android (signed) | SONORA-Android-Signed | 90 days |
| iOS (unsigned) | SONORA-iOS-IPA-Unsigned | 30 days |
| iOS (signed) | SONORA-iOS-IPA-Signed | 90 days |

## iOS Build Limitations

### Free Apple Developer Account
- Can only build unsigned IPA
- Cannot distribute via App Store
- App expires after 7 days on device
- Requires Xcode re-signing every 7 days

### Paid Apple Developer Program ($99/year)
- Required for:
  - App Store distribution
  - TestFlight beta testing
  - Signed IPA with proper provisioning profile
  - Push notifications, CloudKit, etc.

### GitHub Actions macOS Runner
- Uses macOS-latest (currently macOS 14 with Xcode 16)
- Build time limit: 60 minutes (90 for signed)
- No physical device testing available

## Troubleshooting

### Android Build Fails
- Check keystore base64 encoding: `base64 -w 0 keystore.jks | head -c 100`
- Verify key.properties format
- Ensure flutter version matches (3.50.0)

### iOS Build Fails
- Certificate expired? Regenerate in Apple Developer Console
- Provisioning profile mismatch? Check Bundle Identifier matches
- Codesign error? Verify certificate imported to keychain correctly

### Release Not Created
- Tag must start with `v` (e.g., `v1.0.0`)
- Check `softprops/action-gh-release` permissions
- Verify `GITHUB_TOKEN` has write permissions