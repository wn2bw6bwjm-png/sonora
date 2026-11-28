# SONORA Release Notes

## Version 1.0.0 - Initial Release

### 🎵 Overview
SONORA is a free, privacy-focused music application for Android and iOS that aggregates music from legal online sources and allows importing your own audio files.

### ✨ Key Features

#### 🎧 Music Sources
- **Audius** - Decentralized music streaming platform
- **iTunes Search API** - Track previews and metadata
- **Internet Archive** - Free music archive
- **Local Files** - Import your own MP3, M4A, FLAC, WAV, OGG, etc.

#### 🔍 Search & Discovery
- Cross-source search with deduplication
- Filter by source (Online/Local/All) and availability
- Search history persistence
- Personalized recommendations based on listening habits
- Genre browsing

#### 📚 Library Management
- **Favorites** - Heart tracks across all sources
- **Playlists** - Create, rename, reorder, delete with drag-and-drop
- **History** - Recently played (100 entries)
- **Albums** - Auto-grouped from favorites
- **Artists** - Auto-grouped from favorites
- **Local Music** - Dedicated section for imported files

#### ▶️ Playback
- Full-featured player with album art background
- Queue management (add, remove, reorder)
- Shuffle & Repeat (Off / One / All)
- Progress slider with time display
- Mini-player at bottom of all screens
- Background playback support
- Lock screen controls (via audio_service)

#### ⚙️ Settings & Privacy
- Dark theme (premium minimalist design)
- No accounts, no tracking, no ads
- Local-first data storage (Hive)
- Cache management
- Source enable/disable
- Export/reset data

### 🏗️ Technical Stack
- **Framework**: Flutter 3.50.0 / Dart 3.14.0
- **State Management**: Bloc (flutter_bloc)
- **Storage**: Hive (local, encrypted-ready)
- **Audio**: just_audio + audio_service
- **Networking**: Dio + http
- **Architecture**: Clean (domain/data/presentation)
- **CI/CD**: GitHub Actions (Android + iOS)

### 📱 Supported Platforms
- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 13.0+ (unsigned IPA for free accounts, signed for Developer Program)
- **Web**: Experimental (via `flutter build web`)

### 📦 Download
| Platform | File | Size |
|----------|------|------|
| Android (APK) | `SONORA-Android-APK` | ~25 MB |
| Android (AAB) | `SONORA-Android-AAB` | ~20 MB |
| iOS (Unsigned IPA) | `SONORA-iOS-IPA-Unsigned` | ~30 MB |
| iOS (Signed IPA) | `SONORA-iOS-IPA-Signed` | ~30 MB |

### 🔒 Privacy
- **No accounts required** - Works completely offline for local music
- **No analytics** - No Firebase, Google Analytics, or third-party trackers
- **No data collection** - Your music, playlists, and history stay on your device
- **Open source** - Full transparency

### 🐛 Known Limitations
1. **iOS Unsigned IPA** - Requires re-signing every 7 days (free Apple account limitation)
2. **Streaming Availability** - Some tracks only have 30-second previews (iTunes)
3. **No Offline Sync** - Online tracks require internet connection
4. **Metadata Editing** - Local file tags cannot be written back to source file yet
5. **Equalizer** - Not yet implemented

### 🚀 Upcoming in v1.1
- Equalizer with presets
- Lyrics support
- Sleep timer
- Crossfade between tracks
- Last.fm scrobbling (optional)
- Widget support (Android/iOS)
- CarPlay / Android Auto

### 📄 License
SONORA is released under the MIT License. See LICENSE file for details.

Third-party libraries used under their respective licenses (see `flutter pub deps` and Settings → Licenses).

### 🙏 Acknowledgments
- **Audius** for their open API
- **Internet Archive** for preserving free music
- **Apple** for iTunes Search API
- **Flutter Team** for the amazing framework
- **Open Source Community** for all the packages that make this possible

---

## Installation Quick Start

### Android
1. Download `app-release.apk` from GitHub Releases
2. Enable "Install unknown apps" for your browser/file manager
3. Open the APK and tap Install
4. Grant "Music and audio" permission when prompted

### iOS (Unsigned IPA - Free Apple Account)
1. Download `SONORA-unsigned.ipa` from GitHub Releases
2. **Option A - AltStore (Recommended):**
   - Install AltServer on Mac/Windows
   - Connect iPhone via USB
   - Install AltStore on iPhone
   - Open AltStore → My Apps → + → Select IPA
3. **Option B - Sideloadly:**
   - Download Sideloadly for your OS
   - Connect iPhone, enter Apple ID
   - Drag IPA to Sideloadly → Start
4. **Trust the developer:** Settings → General → VPN & Device Management → Trust

### iOS (Signed IPA - Apple Developer Program)
- Install via TestFlight invitation
- Or download from App Store (when published)

---

## Verification
All releases are built via GitHub Actions. Verify artifact integrity:
- Check SHA256 in release notes
- Builds are reproducible from tagged source

## Support
- **Issues**: GitHub Issues
- **Discussions**: GitHub Discussions
- **Security**: See SECURITY.md

Thank you for using SONORA! 🎶