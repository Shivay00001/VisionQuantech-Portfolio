# ⚡ Quick Commands Reference

## 🚀 Initial Setup

```bash
# Create project
flutter create edtech_platform
cd edtech_platform

# Install dependencies
flutter pub get

# Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure

# Seed database
dart scripts/seed_database.dart
```

---

## 🏃 Development

```bash
# Run on Web
flutter run -d chrome

# Run on Android
flutter run

# Run on Android with hot reload
flutter run --hot

# Clean build
flutter clean && flutter pub get
```

---

## 📦 Build Commands

### Android

```bash
# Generate keystore (one-time)
cd android
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
cd ..

# Build APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release

# Install on device
flutter install
```

### Web

```bash
# Build
flutter build web --release

# Deploy to Firebase
firebase login
firebase init hosting
firebase deploy --only hosting
```

---

## 🔥 Firebase Commands

```bash
# Login
firebase login

# Initialize
firebase init

# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage

# Deploy Hosting
firebase deploy --only hosting

# Deploy everything
firebase deploy

# View logs
firebase functions:log
```

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test

# Analyze code
flutter analyze

# Format code
dart format lib/
```

---

## 📱 Device Management

```bash
# List devices
flutter devices

# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>

# Check doctor
flutter doctor -v
```

---

## 🔧 Maintenance

```bash
# Update Flutter
flutter upgrade

# Update dependencies
flutter pub upgrade

# Clean build cache
flutter clean

# Repair pub cache
flutter pub cache repair

# Fix dependencies
flutter pub get --fix
```

---

## 📊 Analysis & Debugging

```bash
# Analyze code
flutter analyze

# Check outdated packages
flutter pub outdated

# Generate dependency graph
flutter pub deps

# Profile app
flutter run --profile

# Build size analysis
flutter build apk --analyze-size
```

---

## 🗂️ File Operations

```bash
# Create new page
touch lib/modules/new_module/new_page.dart

# Create new service
touch lib/services/new_service.dart

# Create new widget
touch lib/widgets/new_widget.dart
```

---

## 🎯 Production Checklist

```bash
# ✅ 1. Update version
# Edit pubspec.yaml: version: 1.0.1+2

# ✅ 2. Build release
flutter build apk --release

# ✅ 3. Test APK
flutter install --release

# ✅ 4. Deploy web
flutter build web --release
firebase deploy --only hosting

# ✅ 5. Tag release
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1
```

---

## 🐛 Troubleshooting Commands

```bash
# Firebase connection issues
flutterfire configure

# Gradle issues
cd android && ./gradlew clean
cd .. && flutter clean

# Pod issues (iOS/macOS)
cd ios && pod deintegrate && pod install
cd .. && flutter clean

# Cache issues
flutter pub cache repair

# Dependency conflicts
flutter pub get --fix
rm pubspec.lock && flutter pub get
```

---

## 📝 Git Commands

```bash
# Initial commit
git init
git add .
git commit -m "Initial commit: Production-grade EdTech platform"

# Create .gitignore
cat > .gitignore << EOF
# Flutter
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
.packages
.pub-cache/
.pub/
build/

# Firebase
**/firebase_options.dart
**/.firebase/

# Android
**/android/key.properties
**/android/upload-keystore.jks
**/android/.gradle/

# IDE
.idea/
.vscode/
*.iml
EOF

# Push to remote
git remote add origin <your-repo-url>
git push -u origin main
```

---

## 🔐 Security Commands

```bash
# Check for vulnerabilities
flutter pub outdated

# Update Firebase rules
firebase deploy --only firestore:rules,storage

# Audit dependencies
flutter pub outdated --mode=null-safety
```

---

## 📈 Performance Commands

```bash
# Profile mode
flutter run --profile

# Release mode
flutter run --release

# Build size analysis
flutter build apk --analyze-size
flutter build web --analyze-size

# Performance overlay
flutter run --profile --enable-software-rendering
```

---

## 🎨 Asset Commands

```bash
# Add image
cp image.png assets/images/

# Generate launcher icons
flutter pub run flutter_launcher_icons:main

# Generate splash screen
flutter pub run flutter_native_splash:create
```

---

## 📱 Play Store Release Checklist

```bash
# 1. Update version in pubspec.yaml
# version: 1.0.0+1

# 2. Build app bundle
flutter build appbundle --release

# 3. Locate bundle
# build/app/outputs/bundle/release/app-release.aab

# 4. Test bundle locally
bundletool build-apks --bundle=app-release.aab --output=app.apks
bundletool install-apks --apks=app.apks

# 5. Upload to Play Console
# Manual upload via https://play.google.com/console
```

---

## 🌐 Web Hosting Commands

```bash
# Build for web
flutter build web --release

# Test locally
cd build/web
python3 -m http.server 8000
# Open http://localhost:8000

# Deploy to Firebase Hosting
firebase deploy --only hosting

# Deploy with custom domain
firebase hosting:sites:create your-domain
firebase target:apply hosting production your-domain
firebase deploy --only hosting:production
```

---

## 💾 Backup Commands

```bash
# Backup Firestore
gcloud firestore export gs://your-bucket/backups

# Backup project
tar -czf edtech_backup_$(date +%Y%m%d).tar.gz \
  --exclude=build \
  --exclude=.dart_tool \
  --exclude=.git \
  .

# Restore from backup
tar -xzf edtech_backup_20240101.tar.gz
```

---

## 🎯 Quick Tips

```bash
# Hot reload: Press 'r'
# Hot restart: Press 'R'
# Quit: Press 'q'
# Help: Press 'h'

# Enable verbose logging
flutter run --verbose

# Run with specific device
flutter run -d chrome
flutter run -d emulator-5554

# Generate missing files
flutter create --platforms=android,ios,web .
```

---

**💡 Tip: Bookmark this file for quick reference during development!**