# iOS Signing Limitations & Distribution Guide

This document explains the limitations of iOS app signing and distribution options for SONORA.

## Understanding iOS Code Signing

### The Core Issue
iOS requires **all apps to be code-signed** with a valid certificate from Apple before they can run on a device. Unlike Android, you cannot simply install an IPA file without proper signing.

## Distribution Options Comparison

| Method | Cost | Duration | Device Limit | Distribution | Best For |
|--------|------|----------|--------------|--------------|----------|
| **Xcode Free Provisioning** | Free | 7 days | 3 devices | Local install only | Personal testing |
| **Apple Developer Program** | $99/year | 1 year | 100 devices/year | TestFlight + App Store | Distribution |
| **Enterprise Program** | $299/year | 1 year | Unlimited | Internal only | Enterprise apps |
| **AltStore/Sideloadly** | Free* | 7 days (free) / 1 year (paid) | 3 / 100 | Self-distribution | Power users |

*AltStore free uses free provisioning (7 days). AltStore+ with paid account = 1 year.

## Free Apple Account Limitations

### What You CAN Do
- Build and run apps on your own devices (up to 3)
- Use Xcode to deploy directly via USB
- Install unsigned IPA via AltStore/Sideloadly (re-signs with free cert)
- Test all app features locally

### What You CANNOT Do
- Distribute IPA to other users (they can't install it)
- Publish to App Store or TestFlight
- Use push notifications, CloudKit, App Groups
- Run app on device for more than 7 days without re-signing
- Use automatic code signing in CI/CD for distribution

### 7-Day Expiration
With a free Apple account:
- Provisioning profile expires after **7 days**
- App stops launching on device
- Must reconnect to Xcode and rebuild/reinstall
- **AltStore automates this** by re-signing in background when iPhone is on same WiFi

## Recommended Distribution for SONORA

### Option 1: AltStore (Best for Free Accounts)
**Pros:**
- Automated re-signing every 7 days
- Works on Windows/macOS/Linux
- No Xcode needed on user's machine
- Can install multiple apps

**Cons:**
- Requires computer for initial setup
- iPhone must be on same WiFi as computer periodically
- 3 device limit

**Setup:**
1. Install AltServer on computer (Mac/Windows/Linux)
2. Connect iPhone via USB
3. Install AltStore on iPhone through AltServer
4. Download IPA → Open in AltStore → Install

### Option 2: Sideloadly (Good Alternative)
**Pros:**
- Works on Windows/macOS/Linux
- Simple drag-and-drop interface
- Can install multiple apps

**Cons:**
- Manual re-signing every 7 days (free)
- Requires Apple ID login
- Computer needed for each re-sign

### Option 3: Xcode Direct (Developers Only)
**Pros:**
- Official Apple tool
- Full debugging capabilities
- No third-party tools

**Cons:**
- Requires macOS
- Manual process
- Not for non-technical users

## For SONORA CI/CD (GitHub Actions)

### Current Setup (Free Account)
```yaml
# ios.yml - Builds unsigned IPA
flutter build ios --release --no-codesign
# Creates SONORA-unsigned.ipa
```

### For Signed Builds (Paid Account Required)
Add these secrets to GitHub:
```
IOS_CERTIFICATE_P12: <base64-encoded .p12>
IOS_CERTIFICATE_PASSWORD: <p12 password>
IOS_PROVISIONING_PROFILE: <base64-encoded .mobileprovision>
```

Then the workflow will:
1. Create temporary keychain
2. Import certificate and provisioning profile
3. Build signed IPA with `flutter build ios --release`
4. Export via `xcodebuild -exportArchive`

## User Installation Guide

### For SONORA Users (Free Account)

#### Method 1: AltStore (Recommended)
1. **On Computer:**
   - Download AltServer from altstore.io
   - Install and run (stays in menu bar/tray)
   
2. **On iPhone:**
   - Connect to computer via USB
   - Open Safari → altstore.io → Download AltStore
   - Install AltStore profile when prompted
   - Trust AltStore in Settings → General → VPN & Device Management
   
3. **Install SONORA:**
   - Download `SONORA-unsigned.ipa` from GitHub Releases
   - Open AltStore app on iPhone
   - Tap + (top left) → Select IPA file
   - Wait for installation

4. **Keep it Working:**
   - Keep AltServer running on computer
   - iPhone and computer on same WiFi weekly
   - AltStore auto-refreshes signatures

#### Method 2: Sideloadly
1. Download Sideloadly for your OS
2. Connect iPhone via USB
3. Enter Apple ID (used for signing)
4. Drag `SONORA-unsigned.ipa` to Sideloadly
5. Click Start → Enter device passcode if prompted
6. On iPhone: Settings → General → VPN & Device Management → Trust your Apple ID

### For SONORA Users (Paid Developer Account)
- **TestFlight**: Developer sends invite email
- **App Store**: Search "SONORA" (when published)
- **Direct IPA**: Install via Xcode or Apple Configurator 2

## Troubleshooting

### "Unable to Install" / "Invalid IPA"
- Ensure IPA downloaded completely (check file size)
- Try re-downloading from GitHub Releases
- Verify using Safari on iPhone (not third-party browser)

### "Untrusted Developer"
- Settings → General → VPN & Device Management
- Find your Apple ID / AltStore profile
- Tap "Trust"

### App Crashes on Launch
- Delete and reinstall
- Ensure iOS version ≥ 13.0
- Check GitHub Issues for known bugs

### "Provisioning Profile Expired" (AltStore)
- Connect iPhone to computer with AltServer running
- Open AltStore on iPhone
- Pull to refresh My Apps
- Re-install if needed

## Building for Distribution (Developers)

### Create Release IPA Locally (Paid Account)
```bash
# 1. Ensure certificates in keychain
# 2. Build
flutter build ios --release

# 2. Archive in Xcode
# Product → Archive → Distribute App → App Store Connect / Ad Hoc

# 3. Or command line:
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath ../build/Runner.xcarchive \
  archive

xcodebuild -exportArchive \
  -archivePath ../build/Runner.xcarchive \
  -exportPath ../build/ios/ipa \
  -exportOptionsPlist ExportOptions.plist
```

### ExportOptions.plist Template
```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>  <!-- or ad-hoc, enterprise, development -->
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

## FAQ

**Q: Can I just send the IPA file to friends?**
A: Only if they have a paid Apple Developer account and you add their device UDID to your provisioning profile (Ad Hoc). For free accounts, they must use AltStore/Sideloadly themselves.

**Q: Why does the IPA expire after 7 days?**
A: Apple's free provisioning profiles are designed for development testing only, not distribution.

**Q: Can SONORA be on the App Store?**
A: Yes, but requires $99/year Apple Developer Program enrollment and App Store review approval.

**Q: Does SONORA collect my Apple ID?**
A: No. AltStore/Sideloadly use your Apple ID locally only for signing. SONORA itself has no access to it.

**Q: Can I use my existing Apple ID for AltStore?**
A: Yes, but consider creating a separate Apple ID for sideloading to avoid 2FA prompts on main account.

## Summary

| Your Situation | Recommended Method |
|----------------|-------------------|
| Free Apple account, want to install yourself | AltStore |
| Free Apple account, Windows user | Sideloadly |
| Paid Developer account | TestFlight / App Store |
| Want to distribute to others | Paid account + TestFlight |
| CI/CD automation | Paid account + GitHub Actions secrets |

---

**Bottom Line**: For free distribution of SONORA, **AltStore is the best option** for users. It handles the 7-day re-signing automatically and provides a clean app-store-like experience.